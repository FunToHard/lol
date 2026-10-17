--- View-model controller driving the In-Game Store / Shop GUI modal.
-- Bridges soft currency booster refills and IAP bundle purchases with reactive UI snapshots.
-- @module shop_ui_controller

local shop_controller = require("game.services.shop_controller")
local ledger = require("game.economy.ledger")
local save_manager = require("game.persistence.save_manager")
local iap_service = require("game.services.iap_service")
local mock_iap_adapter = require("game.services.mock_iap_adapter")

local shop_ui_controller = {}

--- Creates a new shop UI controller instance bound to the active player save state.
-- @param save_data table Active player save data table.
-- @param base_dir string|nil Optional persistence directory path.
-- @param mock_billing table|nil Optional custom IAP adapter instance for test mocks.
-- @return table ctrl Initialized shop UI controller state table.
function shop_ui_controller.new(save_data, base_dir, mock_billing)
    assert(type(save_data) == "table", "shop_ui_controller requires save data")

    -- Ensure required player data blocks exist
    if not save_data.player then
        save_data.player = { coins = 0, stars = 0, inventory = { hammer = 0, rocket = 0, bomb = 0 } }
    end
    if not save_data.player.inventory then
        save_data.player.inventory = { hammer = 0, rocket = 0, bomb = 0 }
    end

    local econ_ledger = ledger.new({
        balances = {
            stars = save_data.player.stars or 0,
            coins = save_data.player.coins or 0,
            boosters = save_data.player.inventory
        },
        history = save_data.ledger_history or {}
    })

    local billing_adapter = mock_billing or mock_iap_adapter.new(true)
    local iap_svc = iap_service.new(billing_adapter)
    local shop = shop_controller.new(econ_ledger, iap_svc, save_data, base_dir)

    return {
        save_data = save_data,
        base_dir = base_dir,
        ledger = econ_ledger,
        iap_service = iap_svc,
        shop = shop,
        is_open = false,
        active_tab = "boosters",
        status_message = nil,
        status_success = true,
        event_log = {}
    }
end

--- Opens the shop modal dialog, optionally switching to a target tab.
-- @param ctrl table Shop UI controller instance.
-- @param default_tab string|nil Initial tab ("boosters" or "packs", default "boosters").
function shop_ui_controller.open(ctrl, default_tab)
    ctrl.is_open = true
    ctrl.active_tab = default_tab or "boosters"
    ctrl.status_message = nil
    table.insert(ctrl.event_log, { event = "opened", tab = ctrl.active_tab })
end

--- Closes the shop modal dialog.
-- @param ctrl table Shop UI controller instance.
function shop_ui_controller.close(ctrl)
    ctrl.is_open = false
    ctrl.status_message = nil
    table.insert(ctrl.event_log, { event = "closed" })
end

--- Switches the active catalog display tab between booster refills and IAP packs.
-- @param ctrl table Shop UI controller instance.
-- @param tab string Target tab ("boosters" or "packs").
-- @return string tab Active tab after update.
function shop_ui_controller.set_tab(ctrl, tab)
    if tab == "packs" or tab == "boosters" then
        ctrl.active_tab = tab
    end
    ctrl.status_message = nil
    table.insert(ctrl.event_log, { event = "tab_switched", tab = ctrl.active_tab })
    return ctrl.active_tab
end

--- Purchases a booster refill using soft currency (coins).
-- @param ctrl table Shop UI controller instance.
-- @param refill_id string Refill identifier ("refill_hammer", "refill_rocket", "refill_bomb").
-- @return boolean success True if purchase was successfully fulfilled.
-- @return string|nil error_code Error string if failed.
function shop_ui_controller.buy_refill(ctrl, refill_id)
    local ok, err = ctrl.shop:buy_refill_with_coins(refill_id)
    if ok then
        ctrl.status_message = "Purchase successful!"
        ctrl.status_success = true
    else
        ctrl.status_message = (err == "INSUFFICIENT_COINS") and "Not enough coins!" or "Purchase failed"
        ctrl.status_success = false
    end
    table.insert(ctrl.event_log, { event = "buy_refill", refill_id = refill_id, success = ok, error = err })
    return ok, err
end

--- Purchases an IAP product using real money via the configured billing service.
-- @param ctrl table Shop UI controller instance.
-- @param product_id string Registered SKU product identifier.
-- @param on_complete function|nil Optional completion callback receiving `(success, error_or_receipt)`.
function shop_ui_controller.buy_iap(ctrl, product_id, on_complete)
    for _, p in ipairs(ctrl.iap_service:get_catalog()) do
        if p.id == product_id and (p.type == "non_consumable" or p.id == "no_ads" or p.id == "pack_starter") and ctrl.save_data.player.no_ads then
            ctrl.status_message = "Already owned!"
            ctrl.status_success = false
            if on_complete then
                on_complete(false, "ALREADY_OWNED")
            end
            return
        end
    end

    ctrl.shop:buy_iap_product(product_id, function(success, res)
        if success then
            ctrl.status_message = "Bundle unlocked!"
            ctrl.status_success = true
        else
            ctrl.status_message = "Transaction cancelled"
            ctrl.status_success = false
        end
        table.insert(ctrl.event_log, { event = "buy_iap", product_id = product_id, success = success })
        if on_complete then
            on_complete(success, res)
        end
    end)
end

--- Clears any active status notification banner.
-- @param ctrl table Shop UI controller instance.
function shop_ui_controller.clear_status(ctrl)
    ctrl.status_message = nil
end

--- Compiles a decoupled presentation snapshot for GUI view binding.
-- @param ctrl table Shop UI controller instance.
-- @return table view Presentation snapshot table.
function shop_ui_controller.get_view_data(ctrl)
    local coins = ledger.get_balance(ctrl.ledger, "coins")
    local hammer = ledger.get_balance(ctrl.ledger, "hammer")
    local rocket = ledger.get_balance(ctrl.ledger, "rocket")
    local bomb = ledger.get_balance(ctrl.ledger, "bomb")
    local no_ads = ctrl.save_data.player.no_ads == true

    local refill_catalog = {}
    for _, r in ipairs(shop_controller.get_coin_refills()) do
        table.insert(refill_catalog, {
            id = r.id,
            title = r.title,
            item = r.item,
            count = r.count,
            cost_coins = r.cost_coins,
            cost_text = tostring(r.cost_coins),
            can_afford = (coins >= r.cost_coins)
        })
    end

    local iap_catalog = {}
    for _, p in ipairs(ctrl.iap_service:get_catalog()) do
        local is_owned = (p.type == "non_consumable" or p.id == "no_ads" or p.id == "pack_starter") and no_ads
        table.insert(iap_catalog, {
            id = p.id,
            title = p.title,
            price_usd = p.price_usd,
            price_text = string.format("$%.2f", p.price_usd),
            type = p.type,
            contents = p.contents,
            is_owned = is_owned
        })
    end

    return {
        is_open = ctrl.is_open,
        active_tab = ctrl.active_tab,
        coins = coins,
        hammer = hammer,
        rocket = rocket,
        bomb = bomb,
        no_ads = no_ads,
        status_message = ctrl.status_message,
        status_success = ctrl.status_success,
        refill_catalog = refill_catalog,
        iap_catalog = iap_catalog
    }
end

return shop_ui_controller
