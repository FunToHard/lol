--- Unit tests for in-game tactical booster controller (Hammer, Row Cleaver Rocket, Bomb).
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_boosters.lua`

package.path = package.path .. ";./?.lua"

local booster_controller = require("game.render.booster_controller")
local ledger = require("game.economy.ledger")
local grid = require("game.board.grid")

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

print("--- Running In-Game Tactical Booster Controller Tests ---")

-- Test 1: Initialization & View Data
local econ = ledger.new({
    balances = {
        boosters = { hammer = 1, rocket = 2, bomb = 0 }
    }
})
local ctrl = booster_controller.new(econ)
local board = grid.create(8, 8)

local view = booster_controller.get_view_data(ctrl)
assert_eq(view.active_booster, nil, "No booster selected initially")
assert_false(view.is_targeting, "Not in targeting mode")
assert_eq(view.boosters.hammer.quantity, 1, "Hammer quantity is 1")
assert_true(view.boosters.hammer.can_select, "Can select hammer")
assert_eq(view.boosters.bomb.quantity, 0, "Bomb quantity is 0")
assert_false(view.boosters.bomb.can_select, "Cannot select bomb with 0 quantity")

-- Test 2: Selecting & Deselecting Boosters
local sel_ok, sel_res = booster_controller.select_booster(ctrl, "hammer")
assert_true(sel_ok, "Hammer selected successfully")
assert_eq(sel_res, "hammer", "Active booster is hammer")
assert_eq(ctrl.active_booster, "hammer", "Controller active_booster is hammer")
assert_true(booster_controller.get_view_data(ctrl).is_targeting, "In targeting mode")

-- Tapping same booster toggles it off
local desel_ok, desel_res = booster_controller.select_booster(ctrl, "hammer")
assert_true(desel_ok, "Hammer toggled off")
assert_eq(desel_res, nil, "Active booster cleared to nil")
assert_false(booster_controller.get_view_data(ctrl).is_targeting, "Targeting mode cleared")

-- Test 3: Insufficient Inventory Rejection
local bomb_ok, bomb_err = booster_controller.select_booster(ctrl, "bomb")
assert_false(bomb_ok, "Selecting bomb with 0 quantity rejected")
assert_eq(bomb_err, "INSUFFICIENT_INVENTORY", "Error code is INSUFFICIENT_INVENTORY")

-- Test 4: Invalid Booster Type
local inv_ok, inv_err = booster_controller.select_booster(ctrl, "invalid_item")
assert_false(inv_ok, "Invalid booster rejected")
assert_eq(inv_err, "INVALID_BOOSTER_TYPE", "Error code is INVALID_BOOSTER_TYPE")

-- Test 5: Hammer Deployment (Single Cell Target)
booster_controller.select_booster(ctrl, "hammer")
assert_true(booster_controller.can_use_on_cell(ctrl, board, 4, 5), "Can use hammer on valid cell (4, 5)")
assert_false(booster_controller.can_use_on_cell(ctrl, board, 0, 5), "Cannot use hammer out-of-bounds (0, 5)")
assert_false(booster_controller.can_use_on_cell(ctrl, board, 4, 9), "Cannot use hammer out-of-bounds (4, 9)")

local h_ok, h_res = booster_controller.apply_to_cell(ctrl, board, 4, 5, "op_test_hammer_1")
assert_true(h_ok, "Hammer applied successfully")
assert_eq(h_res.booster, "hammer", "Result specifies hammer")
assert_eq(#h_res.cells, 1, "Hammer affected exactly 1 cell")
assert_eq(h_res.cells[1].x, 4, "Affected cell X is 4")
assert_eq(h_res.cells[1].y, 5, "Affected cell Y is 5")
assert_eq(h_res.remaining_balance, 0, "Remaining hammer balance is 0")
assert_eq(ledger.get_balance(econ, "hammer"), 0, "Ledger balance updated to 0")
assert_eq(ctrl.active_booster, nil, "Active booster cleared after deployment")

-- Cannot use hammer again now that balance is 0
local h2_ok, h2_err = booster_controller.select_booster(ctrl, "hammer")
assert_false(h2_ok, "Cannot select hammer with 0 balance")

-- Test 6: Rocket Deployment (Full Row Cleaver)
booster_controller.select_booster(ctrl, "rocket")
local r_ok, r_res = booster_controller.apply_to_cell(ctrl, board, 3, 6, "op_test_rocket_1")
assert_true(r_ok, "Rocket applied successfully")
assert_eq(r_res.booster, "rocket", "Result specifies rocket")
assert_eq(#r_res.cells, 8, "Rocket affected entire 8-cell row")
for i, pt in ipairs(r_res.cells) do
    assert_eq(pt.y, 6, string.format("Row cell %d is at row 6", i))
    assert_eq(pt.x, i, string.format("Row cell %d has X coordinate %d", i, i))
end
assert_eq(ledger.get_balance(econ, "rocket"), 1, "Rocket balance deducted from 2 to 1")

-- Test 7: Bomb Deployment (3x3 Area Blast)
ledger.apply_transaction(econ, "op_grant_bomb", "bomb", 1, "test_grant")
booster_controller.select_booster(ctrl, "bomb")
local b_ok, b_res = booster_controller.apply_to_cell(ctrl, board, 4, 4, "op_test_bomb_1")
assert_true(b_ok, "Bomb applied successfully")
assert_eq(b_res.booster, "bomb", "Result specifies bomb")
assert_eq(#b_res.cells, 9, "Bomb in center affected exactly 3x3 = 9 cells")
assert_eq(ledger.get_balance(econ, "bomb"), 0, "Bomb balance deducted to 0")

-- Test 8: Bomb on Corner (Boundary Clamping)
ledger.apply_transaction(econ, "op_grant_bomb_2", "bomb", 1, "test_grant")
booster_controller.select_booster(ctrl, "bomb")
local bc_ok, bc_res = booster_controller.apply_to_cell(ctrl, board, 1, 1, "op_test_bomb_corner")
assert_true(bc_ok, "Bomb on corner applied")
assert_eq(#bc_res.cells, 4, "Bomb on corner (1,1) affected 2x2 = 4 cells within board bounds")

-- Test 9: Applying with No Active Booster
assert_false(booster_controller.apply_to_cell(ctrl, board, 2, 2), "apply_to_cell fails with no active booster")

-- Test 10: Cancel Selection
ledger.apply_transaction(econ, "op_grant_bomb_3", "bomb", 1, "test_grant")
booster_controller.select_booster(ctrl, "bomb")
assert_eq(ctrl.active_booster, "bomb", "Bomb selected")
booster_controller.cancel_selection(ctrl)
assert_eq(ctrl.active_booster, nil, "Targeting cancelled")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
