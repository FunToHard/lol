--- Unit tests for idempotent transaction ledger and economy balances.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_economy.lua`

package.path = package.path .. ";./?.lua"

local ledger = require("game.economy.ledger")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Economy & Ledger Tests ---")

-- Test 1: Initial state balances
local l = ledger.new()
assert_eq(ledger.get_balance(l, "stars"), 0, "Initial stars is 0")
assert_eq(ledger.get_balance(l, "coins"), 0, "Initial coins is 0")
assert_eq(ledger.get_balance(l, "hammer"), 0, "Initial hammer booster is 0")

-- Test 2: Granting currency
local ok1, b1 = ledger.apply_transaction(l, "op_reward_lvl1", "stars", 1, "level_1_victory")
assert_eq(ok1, true, "Star grant succeeded")
assert_eq(b1, 1, "Star balance is 1")
assert_eq(ledger.get_balance(l, "stars"), 1, "Queried star balance is 1")

-- Test 3: Idempotency guarantee (Duplicate op_id)
local ok2, b2, err2 = ledger.apply_transaction(l, "op_reward_lvl1", "stars", 1, "level_1_victory_retry")
assert_eq(ok2, true, "Duplicate op_id returns success")
assert_eq(b2, 1, "Balance not incremented a second time")
assert_eq(err2, "ALREADY_PROCESSED", "Error code matches ALREADY_PROCESSED")

-- Test 4: Spending currency
local ok3, b3 = ledger.apply_transaction(l, "op_spend_task1", "stars", -1, "village_task_1")
assert_eq(ok3, true, "Spending 1 star succeeded")
assert_eq(b3, 0, "Star balance depleted to 0")

-- Test 5: Insufficient funds protection
local ok4, b4, err4 = ledger.apply_transaction(l, "op_spend_overdraft", "stars", -1, "village_task_overdraft")
assert_eq(ok4, false, "Overdraft transaction rejected")
assert_eq(b4, 0, "Balance remained 0")
assert_eq(err4, "INSUFFICIENT_FUNDS", "Error code matches INSUFFICIENT_FUNDS")

-- Test 6: Booster item transactions
local ok5, b5 = ledger.apply_transaction(l, "op_grant_hammer", "hammer", 3, "shop_pack")
assert_eq(ok5, true, "Hammer grant succeeded")
assert_eq(b5, 3, "Hammer balance is 3")
assert_eq(ledger.can_afford(l, "hammer", 2), true, "Can afford 2 hammers")
assert_eq(ledger.can_afford(l, "hammer", 5), false, "Cannot afford 5 hammers")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
