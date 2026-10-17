--- In-game shop controller bridging IAP purchases and soft currency booster refills.
-- Idempotently credits player balances and updates persistent state.
-- @module shop_controller

local ledger = require("game.economy.ledger")
local save_manager = require("game.persistence.save_manager")

local shop_controller = {}

local COIN_REFILLS = {
    { id = "refill_hammer", item = "hammer", count = 3, cost_coins = 600, title = "3 Woodland Mallets" },
    { id = "refill_rocket", item = "rocket", count = 3, cost_coins = 700, title = "3 Directional Rockets" },
    { id = "refill_bomb",   item = "bomb",   count = 3, cost_coins = 800, title = "3 Firework Bombs" }
}

--- Creates a new shop controller instance.
-- @param econ_ledger table Economy ledger state table.
-- @param iap_svc table Configured IAP service instance.
-- @param save_data table Active player save data table.
-- @return table controller Initialized shop controller table.
function shop_controller.new(econ_ledger, iap_svc, save_data)
    assert(type(econ_ledger) == "table", "shop_controller requires an economy ledger")
    assert(type(iap_svc) == "table", "shop_controller requires an IAP service")
    assert(type(save_data) == "table", "shop_controller requires save data")

    local instance = {
        ledger = econ_ledger,
        iap_service = iap_svc,
        save_data = save_data
    }
    setmetatable(instance, { __index = shop_controller })
    return instance
end

--- Returns the catalog of available soft currency (coin) booster refills.
-- @return table refills List of booster refill descriptors.
function shop_controller.get_coin_refills()
    return COIN_REFILLS
end

--- Purchases a booster refill pack using soft currency (coins).
-- @param self table Shop controller instance.
-- @param refill_id string Refill identifier ("refill_hammer", "refill_rocket", "refill_bomb").
-- @return boolean success True if purchase succeeded and boosters were granted.
-- @return string|nil error_code "INSUFFICIENT_COINS", "INVALID_REFILL_ID", or nil.
function shop_controller.buy_refill_with_coins(self, refill_id)
    local target = nil
    for _, r in ipairs(COIN_REFILLS) do
        if r.id == refill_id then
            target = r
            break
        end
    end
    if not target then
        return false, "INVALID_REFILL_ID"
    end

    if not ledger.can_afford(self.ledger, "coins", target.cost_coins) then
        return false, "INSUFFICIENT_COINS"
    end

    local op_spend = "op_buy_refill_" .. refill_id .. "_" .. tostring(os.time())
    local ok_deduct = ledger.apply_transaction(self.ledger, op_spend, "coins", -target.cost_coins, "shop_refill:" .. refill_id)
    if not ok_deduct then
        return false, "INSUFFICIENT_COINS"
    end

    local op_grant = "op_grant_refill_" .. refill_id .. "_" .. tostring(os.time())
    ledger.apply_transaction(self.ledger, op_grant, target.item, target.count, "shop_refill_grant:" .. refill_id)

    -- Sync and persist state
    self.save_data.player.coins = ledger.get_balance(self.ledger, "coins")
    self.save_data.player.inventory[target.item] = ledger.get_balance(self.ledger, target.item)
    self.save_data.ledger_history = self.ledger.history
    save_manager.save(self.save_data)

    return true, nil
end

--- Initiates an IAP transaction for real money and credits all bundled items upon fulfillment.
-- @param self table Shop controller instance.
-- @param product_id string Registered IAP product identifier.
-- @param on_complete function Completion callback receiving `(success, error_or_receipt)`.
function shop_controller.buy_iap_product(self, product_id, on_complete)
    self.iap_service:purchase(product_id, function(product, receipt)
        local base_op = "op_iap_" .. receipt.order_id

        -- 1. Credit Coins
        if product.contents.coins and product.contents.coins > 0 then
            ledger.apply_transaction(self.ledger, base_op .. "_coins", "coins", product.contents.coins, "iap_coins:" .. product_id)
        end

        -- 2. Credit Boosters
        local booster_keys = { "hammer", "rocket", "bomb" }
        for _, b_key in ipairs(booster_keys) do
            if product.contents[b_key] and product.contents[b_key] > 0 then
                ledger.apply_transaction(self.ledger, base_op .. "_" .. b_key, b_key, product.contents[b_key], "iap_booster:" .. product_id)
            end
        end

        -- 3. Entitlements
        if product.contents.no_ads then
            self.save_data.player.no_ads = true
        end

        -- Sync and persist state
        self.save_data.player.coins = ledger.get_balance(self.ledger, "coins")
        for _, b_key in ipairs(booster_keys) do
            self.save_data.player.inventory[b_key] = ledger.get_balance(self.ledger, b_key)
        end
        self.save_data.ledger_history = self.ledger.history
        save_manager.save(self.save_data)

        if on_complete then
            on_complete(true, receipt)
        end
    end, function(err_msg)
        if on_complete then
            on_complete(false, err_msg)
        end
    end)
end

return shop_controller
