--- Unit tests for decoupled platform services, mock adapters, shop controller, and level flow.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_services.lua`

package.path = package.path .. ";./?.lua"

local ads_service = require("game.services.ads_service")
local mock_ads_adapter = require("game.services.mock_ads_adapter")
local iap_service = require("game.services.iap_service")
local mock_iap_adapter = require("game.services.mock_iap_adapter")
local shop_controller = require("game.services.shop_controller")
local level_flow = require("game.services.level_flow")
local ledger = require("game.economy.ledger")
local save_manager = require("game.persistence.save_manager")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Platform Services & Shop Controller Tests ---")

-- Test 1: Mock Ads Adapter & Service
local mock_ad = mock_ads_adapter.new(true)
local ads = ads_service.new(mock_ad)
assert_eq(ads:is_rewarded_ready(), true, "Rewarded ad is ready")

local rewarded_granted = false
ads:show_rewarded(function()
    rewarded_granted = true
end)
assert_eq(rewarded_granted, true, "Rewarded callback invoked on successful ad view")
assert_eq(mock_ad.rewarded_shown_count, 1, "Rewarded ad counter incremented")

-- Fail-open test
local mock_fail_ad = mock_ads_adapter.new(false)
local ads_fail = ads_service.new(mock_fail_ad)
local fail_error = nil
ads_fail:show_rewarded(nil, nil, function(err)
    fail_error = err
end)
assert_eq(fail_error, "SIMULATED_REWARDED_AD_ERROR", "Fail-open callback received simulated error")

-- Test 2: Mock IAP Adapter & Service
local mock_billing = mock_iap_adapter.new(true)
local iap = iap_service.new(mock_billing)
local catalog = iap:get_catalog()
assert_eq(#catalog, 5, "IAP catalog contains 5 registered SKUs")

local starter_pack = mock_billing:get_product("pack_starter")
assert_eq(starter_pack.price_usd, 1.99, "Starter pack price is $1.99")
assert_eq(starter_pack.contents.coins, 1000, "Starter pack includes 1000 coins")
assert_eq(starter_pack.contents.no_ads, true, "Starter pack includes No Ads")

-- Test 3: Shop Controller & Coin Booster Refills
local save_data = save_manager.create_default_state()
save_data.player.coins = 1200
local econ = ledger.new({
    balances = { stars = 0, coins = 1200, boosters = save_data.player.inventory },
    history = save_data.ledger_history
})

local shop = shop_controller.new(econ, iap, save_data)
local ok_refill = shop:buy_refill_with_coins("refill_hammer")
assert_eq(ok_refill, true, "Purchased 3 hammers for 600 coins")
assert_eq(ledger.get_balance(econ, "coins"), 600, "Remaining coins is 600")
assert_eq(ledger.get_balance(econ, "hammer"), 4, "Hammer count incremented to 4 (1 default + 3 refill)")

-- Insufficient funds for second refill
local ok_refill2, err_refill2 = shop:buy_refill_with_coins("refill_bomb")
assert_eq(ok_refill2, false, "Refill rejected when coins insufficient (needs 800, has 600)")
assert_eq(err_refill2, "INSUFFICIENT_COINS", "Error code matches INSUFFICIENT_COINS")

-- Test 4: Shop Controller IAP Fulfillment
local iap_success = false
shop:buy_iap_product("pack_starter", function(success, res)
    iap_success = success
end)
assert_eq(iap_success, true, "IAP Starter pack purchase fulfilled")
assert_eq(ledger.get_balance(econ, "coins"), 1600, "1000 coins credited from starter pack (600 + 1000 = 1600)")
assert_eq(ledger.get_balance(econ, "hammer"), 6, "2 hammers credited (4 + 2 = 6)")
assert_eq(ledger.get_balance(econ, "rocket"), 3, "2 rockets credited (1 + 2 = 3)")
assert_eq(save_data.player.no_ads, true, "No Ads permanent entitlement activated")

-- Test 5: Level Flow Continuations
local flow = level_flow.new(econ, ads, save_data, 1)
assert_eq(flow:can_afford_coin_continuation(), true, "Can afford 900-coin continuation with 1600 coins")

local dummy_tracker = { moves_remaining = 0, status = "LOST" }
local ok_cont, moves_added = flow:buy_extra_moves_with_coins(dummy_tracker)
assert_eq(ok_cont, true, "Coin continuation succeeded")
assert_eq(moves_added, 5, "+5 moves added to tracker")
assert_eq(dummy_tracker.moves_remaining, 5, "Tracker has 5 moves remaining")
assert_eq(dummy_tracker.status, "IN_PROGRESS", "Tracker status restored to IN_PROGRESS")
assert_eq(ledger.get_balance(econ, "coins"), 700, "900 coins deducted (1600 - 900 = 700)")

-- Rewarded Ad Continuation (Single use cap)
assert_eq(flow:can_use_ad_continuation(), true, "Ad continuation initially available")
local ad_granted = false
flow:watch_ad_for_extra_moves(dummy_tracker, function(success, added, reason)
    ad_granted = success
end)
assert_eq(ad_granted, true, "Ad continuation granted +3 moves")
assert_eq(dummy_tracker.moves_remaining, 8, "Tracker has 8 moves (5 + 3)")
assert_eq(flow:can_use_ad_continuation(), false, "Ad continuation no longer available for this attempt")

-- Re-attempting ad continuation is rejected
local second_ad = false
local second_reason = nil
flow:watch_ad_for_extra_moves(dummy_tracker, function(success, added, reason)
    second_ad = success
    second_reason = reason
end)
assert_eq(second_ad, false, "Second ad continuation rejected")
assert_eq(second_reason, "AD_CONTINUATION_EXHAUSTED", "Reason is AD_CONTINUATION_EXHAUSTED")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
