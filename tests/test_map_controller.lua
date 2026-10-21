--- Unit tests for the 25-Level Winding Map Path Controller.
-- Verifies sinusoidal path geometry, level unlocking, star ratings, and touch scroll clamping.
-- Usage: `lua tests/test_map_controller.lua`

package.path = package.path .. ";./?.lua"

local map_controller = require("game.render.map_controller")
local save_manager = require("game.persistence.save_manager")

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

print("--- Running Map Path Controller Tests ---")

-- 1. Initial State with Level 1 Unlocked
local save_data = save_manager.create_default_state()
save_data.progression.max_unlocked_level = 1
save_data.player.stars = 0
save_data.player.coins = 150

local ctrl = map_controller.new(save_data)
local view = map_controller.get_view_data(ctrl)

assert_eq(#view.levels, 25, "Exactly 25 levels present on map path")
assert_eq(view.max_unlocked, 1, "Max unlocked level is 1")
assert_eq(view.stars, 0, "Initial stars balance is 0")
assert_eq(view.coins, 150, "Initial coins balance is 150")

-- Level 1 Unlocked and Current
assert_eq(view.levels[1].is_unlocked, true, "Level 1 is unlocked")
assert_eq(view.levels[1].is_current, true, "Level 1 is current target")
assert_eq(view.levels[1].is_completed, false, "Level 1 not yet completed")

-- Level 2 to 25 Locked
assert_eq(view.levels[2].is_unlocked, false, "Level 2 is locked")
assert_eq(view.levels[25].is_unlocked, false, "Level 25 is locked")

-- 2. Sinusoidal Geometry Verification
-- Level 1 at angle 0: sin(0) = 0 -> center_x = 360
assert_eq(view.levels[1].screen_x, 360, "Level 1 centered at x=360")
-- Check that subsequent levels oscillate around 360
local has_left = false
local has_right = false
for _, lvl in ipairs(view.levels) do
    if lvl.screen_x < 300 then has_left = true end
    if lvl.screen_x > 420 then has_right = true end
end
assert_eq(has_left, true, "Map path curves to the left")
assert_eq(has_right, true, "Map path curves to the right")

-- 3. Completed Levels and Star Ratings
save_data.progression.max_unlocked_level = 5
save_data.progression.completed_levels = {
    [1] = { completed = true, stars = 3, score = 4500 },
    [2] = { completed = true, stars = 2, score = 3200 },
    [3] = { completed = true, stars = 1, score = 2100 },
    [4] = { completed = true, stars = 3, score = 5100 }
}
save_data.player.stars = 9

local ctrl2 = map_controller.new(save_data)
local view2 = map_controller.get_view_data(ctrl2)

assert_eq(view2.max_unlocked, 5, "Level 5 is max unlocked")
assert_eq(view2.levels[1].is_completed, true, "Level 1 completed")
assert_eq(view2.levels[1].stars, 3, "Level 1 earned 3 stars")
assert_eq(view2.levels[1].stars_text, "***", "Level 1 star display is ***")

assert_eq(view2.levels[2].stars, 2, "Level 2 earned 2 stars")
assert_eq(view2.levels[2].stars_text, "**", "Level 2 star display is **")

assert_eq(view2.levels[3].stars, 1, "Level 3 earned 1 star")
assert_eq(view2.levels[3].stars_text, "*", "Level 3 star display is *")

assert_eq(view2.levels[5].is_current, true, "Level 5 is current target")
assert_eq(view2.levels[5].is_completed, false, "Level 5 is not completed")
assert_eq(view2.levels[6].is_unlocked, false, "Level 6 is locked")

-- 4. Touch Scroll & Clamping
local initial_scroll = ctrl2.scroll_y
assert_eq(initial_scroll <= ctrl2.max_scroll_y, true, "Scroll within upper bound")
assert_eq(initial_scroll >= ctrl2.min_scroll_y, true, "Scroll within lower bound")

-- Drag up (positive delta moves view down the mountain)
map_controller.scroll_by(ctrl2, 500)
assert_eq(ctrl2.scroll_y <= ctrl2.max_scroll_y, true, "Scroll clamped to max_scroll_y")

-- Drag down past bottom (large negative delta)
map_controller.scroll_by(ctrl2, -5000)
assert_eq(ctrl2.scroll_y, ctrl2.min_scroll_y, "Scroll clamped to min_scroll_y")

-- 5. Scroll to Specific Level
map_controller.scroll_to_level(ctrl2, 1)
assert_eq(ctrl2.scroll_y, 0, "Scrolled to level 1 sets scroll to 0 (top of map content)")

map_controller.scroll_to_level(ctrl2, 25)
assert_eq(ctrl2.scroll_y, ctrl2.min_scroll_y, "Scrolled to level 25 sets scroll to min bound")

-- 6. Visibility Clipping Verification
local visible_count = 0
for _, lvl in ipairs(map_controller.get_view_data(ctrl2).levels) do
    if lvl.is_visible then visible_count = visible_count + 1 end
end
assert_eq(visible_count > 0 and visible_count < 25, true, "Only subset of levels visible within screen bounds")

print(string.format("All tests passed! (%d/%d assertions)\n", passed_tests, total_tests))
