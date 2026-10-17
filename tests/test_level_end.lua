--- Unit tests for level end controller (victory fanfare, star rating, and continuation purchases).
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_level_end.lua`

package.path = package.path .. ";./?.lua"

local level_end_controller = require("game.render.level_end_controller")
local ledger = require("game.economy.ledger")
local level_flow = require("game.services.level_flow")
local ads_service = require("game.services.ads_service")
local mock_ads_adapter = require("game.services.mock_ads_adapter")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

local function assert_true(condition, msg)
    assert_eq(condition, true, msg)
end

local function assert_false(condition, msg)
    assert_eq(condition, false, msg)
end

print("--- Running Level End Flow & Victory Fanfare Tests ---")

-- Test 1: Star Rating Calculations
assert_eq(level_end_controller.calculate_star_rating(0, 25), 1, "0 moves left = 1 star")
assert_eq(level_end_controller.calculate_star_rating(3, 25), 1, "12% moves left = 1 star")
assert_eq(level_end_controller.calculate_star_rating(5, 25), 2, "20% moves left = 2 stars")
assert_eq(level_end_controller.calculate_star_rating(8, 25), 2, "32% moves left = 2 stars")
assert_eq(level_end_controller.calculate_star_rating(10, 25), 3, "40% moves left = 3 stars")
assert_eq(level_end_controller.calculate_star_rating(15, 25), 3, "60% moves left = 3 stars")

-- Setup mock flow and save environment
local econ = ledger.new({ balances = { coins = 1000, stars = 2 } })
local ads = ads_service.new(mock_ads_adapter.new(true))
local save_data = {
    player = { coins = 1000, stars = 2 },
    progression = { completed_levels = {}, max_unlocked_level = 1 },
    created_at = 12345
}
local flow_inst = level_flow.new(econ, ads, save_data, 1)

local mock_tracker = {
    level_id = 1,
    moves_remaining = 12,
    total_moves = 25,
    status = "WON"
}

-- Test 2: Victory Modal Initialization & View Data
local end_ctrl = level_end_controller.new(1, mock_tracker, flow_inst)
local v_view = level_end_controller.show_victory(end_ctrl)
assert_eq(v_view.mode, "VICTORY", "Mode set to VICTORY")
assert_true(v_view.is_visible, "Modal is visible")
assert_eq(v_view.stars_awarded, 3, "Awarded 3 stars for 12/25 moves remaining")
assert_eq(v_view.coins_reward, 50, "Victory awards 50 coins")
assert_eq(v_view.stars_reward, 1, "Victory awards 1 star spark")

-- Test 3: Claiming Victory
local reward = level_end_controller.claim_victory(end_ctrl)
assert_eq(reward.stars, 1, "Granted 1 star")
assert_eq(reward.coins, 50, "Granted 50 coins")
assert_eq(reward.next_level, 2, "Next level is 2")
assert_eq(ledger.get_balance(econ, "stars"), 3, "Ledger stars balance updated to 3")
assert_eq(ledger.get_balance(econ, "coins"), 1050, "Ledger coins balance updated to 1050")
assert_true(end_ctrl.claimed, "Marked as claimed")

-- Re-claiming returns nil (idempotent)
assert_eq(level_end_controller.claim_victory(end_ctrl), nil, "Re-claiming does nothing")

-- Test 4: Defeat / Out of Moves Flow
local defeat_tracker = {
    level_id = 2,
    moves_remaining = 0,
    total_moves = 20,
    status = "LOST"
}
local defeat_flow = level_flow.new(econ, ads, save_data, 2)
local defeat_ctrl = level_end_controller.new(2, defeat_tracker, defeat_flow)
local d_view = level_end_controller.show_defeat(defeat_ctrl)

assert_eq(d_view.mode, "DEFEAT", "Mode is DEFEAT")
assert_true(d_view.is_visible, "Defeat modal visible")
assert_true(d_view.can_afford_coins, "Player has 1050 coins, can afford 900 continuation")
assert_true(d_view.can_watch_ad, "Rewarded ad continuation available")

-- Test 5: Buying +5 Moves with Coins
local buy_ok, buy_err = level_end_controller.buy_coin_continuation(defeat_ctrl)
assert_true(buy_ok, "Coin continuation purchase succeeded")
assert_eq(defeat_tracker.moves_remaining, 5, "Tracker granted +5 moves")
assert_eq(defeat_tracker.status, "IN_PROGRESS", "Tracker status restored to IN_PROGRESS")
assert_false(defeat_ctrl.is_visible, "Modal closed after continuation")
assert_eq(ledger.get_balance(econ, "coins"), 150, "Coins deducted by 900 (1050 - 900 = 150)")

-- Now player only has 150 coins, cannot afford another 900 coin continuation
local afford_now = defeat_flow:can_afford_coin_continuation()
assert_false(afford_now, "Cannot afford another 900 coin continuation")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
