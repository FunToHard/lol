--- Unit tests for in-game HUD overlay controller and view data formatting.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_hud.lua`

package.path = package.path .. ";./?.lua"

local hud_controller = require("game.render.hud_controller")

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

print("--- Running In-Game HUD Overlay Tests ---")

-- Test 1: Number formatting with commas
assert_eq(hud_controller.format_number(0), "0", "Format 0")
assert_eq(hud_controller.format_number(450), "450", "Format hundreds")
assert_eq(hud_controller.format_number(1250), "1,250", "Format thousands")
assert_eq(hud_controller.format_number(120500), "120,500", "Format hundred thousands")

-- Test 2: Goal sprite mapping
assert_eq(hud_controller.get_goal_sprite("collect_color", "ruby"), "piece_ruby", "Ruby sprite")
assert_eq(hud_controller.get_goal_sprite("clear_obstacle", "stone"), "obstacle_stone_1", "Stone obstacle sprite")
assert_eq(hud_controller.get_goal_sprite("drop_ingredient", "acorn"), "ingredient_acorn", "Acorn ingredient sprite")

-- Test 3: Initialization from level definition
local mock_level = {
    level_id = 5,
    moves = 20,
    goals = {
        { type = "collect_color", target = "emerald", count = 15 },
        { type = "clear_obstacle", target = "bramble", count = 6 }
    }
}

local hud = hud_controller.new(mock_level)
assert_eq(hud.level_id, 5, "Level ID initialized")
assert_eq(hud.moves_remaining, 20, "Moves initialized")
assert_eq(hud.score, 0, "Score starts at 0")
assert_eq(#hud.goals, 2, "Two goals initialized")
assert_eq(hud.goals[1].sprite_name, "piece_emerald", "First goal sprite is emerald")
assert_eq(hud.goals[2].sprite_name, "obstacle_bramble_1", "Second goal sprite is bramble")

-- Test 4: Move deduction and view data
hud_controller.set_moves(hud, 19)
local view = hud_controller.get_view_data(hud)
assert_eq(view.moves, 19, "Moves remaining updated")
assert_eq(view.moves_text, "19", "Moves formatted as text")

-- Test 5: Score accumulation
hud_controller.add_score(hud, 150)
hud_controller.add_score(hud, 900)
local view_score = hud_controller.get_view_data(hud)
assert_eq(view_score.score, 1050, "Score accumulated correctly")
assert_eq(view_score.score_text, "1,050", "Score formatted with comma")

-- Test 6: Goal progress tracking
local tracker_goals = {
    { type = "collect_color", target = "emerald", target_count = 15, current_count = 10, completed = false },
    { type = "clear_obstacle", target = "bramble", target_count = 6, current_count = 6, completed = true }
}
hud_controller.update_goals(hud, tracker_goals)
local view_goals = hud_controller.get_view_data(hud)
assert_eq(view_goals.goals[1].remaining, 5, "Emerald remaining count is 5")
assert_eq(view_goals.goals[1].count_text, "5", "Emerald display text is 5")
assert_eq(view_goals.goals[1].is_completed, false, "Emerald not completed")

assert_eq(view_goals.goals[2].remaining, 0, "Bramble remaining count is 0")
assert_eq(view_goals.goals[2].count_text, "V", "Bramble display text is completed checkmark")
assert_eq(view_goals.goals[2].is_completed, true, "Bramble completed")

-- Test 7: Pause toggle
assert_eq(hud.is_paused, false, "Initially unpaused")
hud_controller.toggle_pause(hud)
assert_eq(hud.is_paused, true, "Toggled to paused")
hud_controller.toggle_pause(hud, false)
assert_eq(hud.is_paused, false, "Explicitly unpaused")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
