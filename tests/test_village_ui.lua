--- Unit tests for village restoration UI controller (drawer, 3-style picker, star spending, and emotes).
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_village_ui.lua`

package.path = package.path .. ";./?.lua"

local village_controller = require("game.restoration.village_controller")
local village_state = require("game.restoration.village_state")
local companion = require("game.restoration.companion")
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

local function assert_true(condition, msg)
    assert_eq(condition, true, msg)
end

local function assert_false(condition, msg)
    assert_eq(condition, false, msg)
end

print("--- Running Village Restoration UI & 3-Style Picker Tests ---")

-- Test 1: Controller Initialization
local econ = ledger.new({ balances = { stars = 0, coins = 100 } })
local vstate = village_state.new(nil, econ)
local comp = companion.new("Pip")
local ctrl = village_controller.new(vstate, comp, econ)

local initial_view = village_controller.get_view_data(ctrl)
assert_eq(initial_view.stars, 0, "Initial stars balance is 0")
assert_true(initial_view.drawer_open, "Drawer starts open by default")
assert_false(initial_view.picker_open, "Picker starts closed")
assert_eq(initial_view.companion_emote, "idle", "Companion starts in idle emote")
assert_eq(initial_view.active_task.id, "clear_ruined_leaves", "First active task is clear_ruined_leaves")
assert_false(initial_view.active_task.can_afford, "Cannot afford active task with 0 stars")

-- Test 2: Drawer Toggling
local drawer_state = village_controller.toggle_drawer(ctrl)
assert_false(drawer_state, "Drawer toggled closed")
assert_false(village_controller.get_view_data(ctrl).drawer_open, "View reflects closed drawer")
village_controller.toggle_drawer(ctrl)
assert_true(village_controller.get_view_data(ctrl).drawer_open, "Drawer toggled open again")

-- Test 3: Unaffordable Task Picker Open Rejected
local open_ok, open_err = village_controller.open_picker(ctrl, "clear_ruined_leaves", "RESTORE")
assert_false(open_ok, "Cannot open restore picker without enough stars")
assert_eq(open_err, "INSUFFICIENT_STARS_OR_LOCKED", "Returns proper error code")

-- Test 4: Star Grant, Picker Open & Companion Curious Emote
ledger.apply_transaction(econ, "op_test_stars_ui", "stars", 3, "level_win")
local open_ok2, open_err2 = village_controller.open_picker(ctrl, "clear_ruined_leaves", "RESTORE")
assert_true(open_ok2, "Picker opens successfully after granting stars: " .. tostring(open_err2))
assert_true(ctrl.picker_open, "Picker state flag is true")

local picker_view = village_controller.get_view_data(ctrl)
assert_true(picker_view.picker_open, "View data indicates picker is open")
assert_eq(picker_view.companion_emote, "curious", "Companion emote switched to curious on picker open")
assert_eq(#picker_view.picker.styles, 3, "Picker provides exactly 3 aesthetic style options")

-- Test 5: Style Selection & Confirmation (Restore Mode)
village_controller.select_style(ctrl, 2)
assert_eq(ctrl.selected_style_idx, 2, "Selected style is 2 (River Reed Rake)")

local confirm_ok, confirm_res = village_controller.confirm_selection(ctrl, "op_ui_confirm_task_1")
assert_true(confirm_ok, "Task confirmed and completed")
assert_eq(confirm_res, "TASK_COMPLETED", "Result code is TASK_COMPLETED")
assert_false(ctrl.picker_open, "Picker closes automatically after confirmation")
assert_eq(ledger.get_balance(econ, "stars"), 2, "1 star deducted from ledger (3 - 1 = 2)")
assert_eq(vstate.chosen_styles["clear_ruined_leaves"], 2, "Chosen style recorded in village state")
assert_eq(comp.current_emote, "celebrate", "Companion celebrates after task completion")

-- Active task advances to task 2
local view_after_1 = village_controller.get_view_data(ctrl)
assert_eq(view_after_1.active_task.id, "repair_stone_hearth", "Sequence advanced to repair_stone_hearth")
assert_true(view_after_1.active_task.can_afford, "Can afford task 2 with remaining 2 stars")

-- Test 6: Free Re-styling (Zero-Cost Mode)
local open_restyle_ok = village_controller.open_picker(ctrl, "clear_ruined_leaves", "RESTYLE")
assert_true(open_restyle_ok, "Opened picker in RESTYLE mode")
assert_eq(ctrl.picker_mode, "RESTYLE", "Picker mode is RESTYLE")
assert_eq(ctrl.selected_style_idx, 2, "Defaults to previously chosen style 2")

village_controller.select_style(ctrl, 3)
assert_eq(ctrl.selected_style_idx, 3, "Selected style 3 (Breezy Feather Fan)")

local restyle_ok, restyle_res = village_controller.confirm_selection(ctrl)
assert_true(restyle_ok, "Re-style confirmed")
assert_eq(restyle_res, "PROP_RESTYLED", "Result code is PROP_RESTYLED")
assert_eq(ledger.get_balance(econ, "stars"), 2, "Stars balance untouched at 2 (zero currency cost)")
assert_eq(vstate.chosen_styles["clear_ruined_leaves"], 3, "Prop updated to style 3")
assert_eq(comp.current_emote, "happy", "Companion happy with re-styling")

-- Test 7: Cancel / Close Picker
village_controller.open_picker(ctrl, "repair_stone_hearth", "RESTORE")
assert_true(ctrl.picker_open, "Picker opened for task 2")
village_controller.close_picker(ctrl)
assert_false(ctrl.picker_open, "Picker closed without confirming")
assert_eq(ledger.get_balance(econ, "stars"), 2, "Stars untouched")

-- Test 8: Edge Cases & Input Validation
local confirm_fail_ok, confirm_fail_err = village_controller.confirm_selection(ctrl)
assert_false(confirm_fail_ok, "confirm_selection fails when picker is not open")
assert_eq(confirm_fail_err, "PICKER_NOT_OPEN", "Error code is PICKER_NOT_OPEN")

local bad_task_ok, bad_task_err = village_controller.open_picker(ctrl, "non_existent_task", "RESTORE")
assert_false(bad_task_ok, "open_picker fails for non-existent task")
assert_eq(bad_task_err, "TASK_NOT_FOUND", "Error code is TASK_NOT_FOUND")

village_controller.open_picker(ctrl, "repair_stone_hearth", "RESTORE")
assert_false(village_controller.select_style(ctrl, 0), "Style index 0 rejected")
assert_false(village_controller.select_style(ctrl, 4), "Style index 4 rejected")
assert_false(village_controller.select_style(ctrl, nil), "Nil style index rejected")
assert_true(village_controller.select_style(ctrl, 1), "Style index 1 accepted")
village_controller.close_picker(ctrl)

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
