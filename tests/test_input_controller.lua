--- Unit tests for touch input controller drag-and-swap and tap detection.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_input_controller.lua`

package.path = package.path .. ";./?.lua"

local board_view = require("game.render.board_view")
local input_controller = require("game.render.input_controller")

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

print("--- Running Touch Input Controller Tests ---")

local grid_w, grid_h = 8, 8
local state = input_controller.new()

-- Test 1: Touch down on cell (3, 3)
local px, py = board_view.grid_to_screen(3, 3, grid_w, grid_h)
local down_ev = input_controller.on_touch_down(state, px, py, grid_w, grid_h)
assert_true(down_ev ~= nil, "Touch down detected")
assert_eq(down_ev.action, "select", "Action is select")
assert_eq(down_ev.gx, 3, "Column is 3")
assert_eq(down_ev.gy, 3, "Row is 3")

-- Test 2: Drag Right past 22px threshold
local right_ev = input_controller.on_touch_move(state, px + 35, py, grid_w, grid_h)
assert_true(right_ev ~= nil, "Swipe commit triggered")
assert_eq(right_ev.action, "swap_commit", "Action is swap_commit")
assert_eq(right_ev.from.x, 3, "From col is 3")
assert_eq(right_ev.to.x, 4, "To col is 4")
assert_eq(right_ev.to.y, 3, "To row is 3")

-- Test 3: Tap Detection (Touch down, tiny move 5px, touch up)
input_controller.on_touch_down(state, px, py, grid_w, grid_h)
local tiny_move = input_controller.on_touch_move(state, px + 5, py, grid_w, grid_h)
assert_eq(tiny_move, nil, "Sub-threshold move does not commit swap")
local up_ev = input_controller.on_touch_up(state)
assert_true(up_ev ~= nil, "Touch up detected")
assert_eq(up_ev.action, "tap", "Action is direct tap")
assert_eq(up_ev.gx, 3, "Tapped col is 3")
assert_eq(up_ev.gy, 3, "Tapped row is 3")

-- Test 4: Vertical Swipe Upward (Screen dy > 0 -> Grid row - 1)
input_controller.on_touch_down(state, px, py, grid_w, grid_h)
local up_drag = input_controller.on_touch_move(state, px, py + 35, grid_w, grid_h)
assert_true(up_drag ~= nil, "Upward swipe committed")
assert_eq(up_drag.to.y, 2, "Moved to row 2 (upward)")

-- Test 5: Vertical Swipe Downward (Screen dy < 0 -> Grid row + 1)
input_controller.on_touch_down(state, px, py, grid_w, grid_h)
local down_drag = input_controller.on_touch_move(state, px, py - 35, grid_w, grid_h)
assert_true(down_drag ~= nil, "Downward swipe committed")
assert_eq(down_drag.to.y, 4, "Moved to row 4 (downward)")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
