--- Unit tests for In-Game Store / Shop GUI Controller.
-- Verifies catalog presentation, coin refills, IAP fulfillment, tab switching, and error handling.
-- Usage: `lua tests/test_shop_ui.lua`

package.path = package.path .. ";./?.lua"

local shop_ui_controller = require("game.services.shop_ui_controller")
local mock_iap_adapter = require("game.services.mock_iap_adapter")
local save_manager = require("game.persistence.save_manager")
local ledger = require("game.economy.ledger")

local total_tests = 0
local passed_tests = 0

--- Asserts equality between actual and expected values.
local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Shop UI Controller Tests ---")

-- Setup fresh test save data
local save_data = save_manager.create_default_state()
save_data.player.coins = 1000
save_data.player.inventory.hammer = 1
save_data.player.inventory.rocket = 1
save_data.player.inventory.bomb = 0

local mock_billing = mock_iap_adapter.new(true)
local ctrl = shop_ui_controller.new(save_data, nil, mock_billing)

-- 1. Initial State & Catalogs
local view = shop_ui_controller.get_view_data(ctrl)
assert_eq(view.is_open, false, "Shop initially closed")
assert_eq(view.active_tab, "boosters", "Default tab is boosters")
assert_eq(view.coins, 1000, "Initial coins balance is 1000")
assert_eq(view.hammer, 1, "Initial hammer inventory is 1")
assert_eq(view.rocket, 1, "Initial rocket inventory is 1")
assert_eq(view.bomb, 0, "Initial bomb inventory is 0")
assert_eq(view.no_ads, false, "Initial no_ads entitlement is false")
assert_eq(#view.refill_catalog, 3, "3 coin refills in catalog")
assert_eq(#view.iap_catalog, 5, "5 IAP products in catalog")

-- 2. Open / Close & Tab Switching
shop_ui_controller.open(ctrl, "packs")
view = shop_ui_controller.get_view_data(ctrl)
assert_eq(view.is_open, true, "Shop is now open")
assert_eq(view.active_tab, "packs", "Active tab opened to packs")

shop_ui_controller.set_tab(ctrl, "boosters")
view = shop_ui_controller.get_view_data(ctrl)
assert_eq(view.active_tab, "boosters", "Tab switched to boosters")

-- 3. Coin Booster Refill Purchase
-- Hammer refill costs 600 coins, grants 3 hammers
assert_eq(view.refill_catalog[1].can_afford, true, "Player can afford 600-coin hammer refill")
local ok_refill, err_refill = shop_ui_controller.buy_refill(ctrl, "refill_hammer")
assert_eq(ok_refill, true, "Hammer refill purchase succeeded")
assert_eq(err_refill, nil, "No error on valid refill")

view = shop_ui_controller.get_view_data(ctrl)
assert_eq(view.coins, 400, "Coins balance reduced to 400 (1000 - 600)")
assert_eq(view.hammer, 4, "Hammers increased to 4 (1 + 3)")
assert_eq(view.status_message, "Purchase successful!", "Status shows success message")
assert_eq(view.status_success, true, "Status success flag is true")

-- 4. Insufficient Coins Handling
-- Rocket refill costs 700 coins, player only has 400
assert_eq(view.refill_catalog[2].can_afford, false, "Player cannot afford 700-coin rocket refill")
local ok_fail, err_fail = shop_ui_controller.buy_refill(ctrl, "refill_rocket")
assert_eq(ok_fail, false, "Rocket refill rejected due to low coins")
assert_eq(err_fail, "INSUFFICIENT_COINS", "Error code is INSUFFICIENT_COINS")

view = shop_ui_controller.get_view_data(ctrl)
assert_eq(view.status_message, "Not enough coins!", "Status shows insufficient coins warning")
assert_eq(view.status_success, false, "Status success flag is false")
assert_eq(view.coins, 400, "Coins balance remains untouched")
assert_eq(view.rocket, 1, "Rockets inventory remains untouched")

-- 5. Real-Money IAP Purchase Fulfillment
-- Buy Starter Pack: $1.99 -> 1000 coins, 2 hammers, 2 rockets, no_ads = true
local iap_callback_fired = false
shop_ui_controller.buy_iap(ctrl, "pack_starter", function(success, res)
    iap_callback_fired = true
end)
assert_eq(iap_callback_fired, true, "IAP completion callback fired")

view = shop_ui_controller.get_view_data(ctrl)
assert_eq(view.coins, 1400, "Coins increased to 1400 (400 + 1000)")
assert_eq(view.hammer, 6, "Hammers increased to 6 (4 + 2)")
assert_eq(view.rocket, 3, "Rockets increased to 3 (1 + 2)")
assert_eq(view.no_ads, true, "No Ads entitlement unlocked")
assert_eq(view.status_message, "Bundle unlocked!", "Status shows bundle unlocked")
assert_eq(view.status_success, true, "Status success flag is true")

-- 6. Owned Entitlement Flag in Catalog
view = shop_ui_controller.get_view_data(ctrl)
local no_ads_item = nil
local starter_item = nil
for _, item in ipairs(view.iap_catalog) do
    if item.id == "no_ads" then
        no_ads_item = item
    elseif item.id == "pack_starter" then
        starter_item = item
    end
end
assert_eq(no_ads_item ~= nil, true, "No Ads product found in catalog")
assert_eq(no_ads_item.is_owned, true, "No Ads product marked as owned")
assert_eq(starter_item ~= nil, true, "Starter pack found in catalog")
assert_eq(starter_item.is_owned, true, "Starter pack marked as owned")

-- Repurchase of owned item should fail
local repurchased = false
local repurchase_err = nil
shop_ui_controller.buy_iap(ctrl, "no_ads", function(success, err)
    repurchased = success
    repurchase_err = err
end)
assert_eq(repurchased, false, "Repurchase of owned entitlement rejected")
assert_eq(repurchase_err, "ALREADY_OWNED", "Error returned is ALREADY_OWNED")

-- 7. Close Dialog & Clear Status
shop_ui_controller.close(ctrl)
view = shop_ui_controller.get_view_data(ctrl)
assert_eq(view.is_open, false, "Shop dialog closed")
assert_eq(view.status_message, nil, "Status message cleared upon close")

print(string.format("All tests passed! (%d/%d assertions)\n", passed_tests, total_tests))
