--- Unit tests for board view coordinate transformations and sprite mappings.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_board_view.lua`

package.path = package.path .. ";./?.lua"

local board_view = require("game.render.board_view")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Board View & Coordinate Transform Tests ---")

-- Test 1: Round-trip Coordinate Conversion for an 8x8 Grid
local grid_w, grid_h = 8, 8
for gy = 1, grid_h do
    for gx = 1, grid_w do
        local px, py = board_view.grid_to_screen(gx, gy, grid_w, grid_h)
        local out_gx, out_gy = board_view.screen_to_grid(px, py, grid_w, grid_h)
        assert_eq(out_gx, gx, string.format("Round-trip X matches for (%d,%d)", gx, gy))
        assert_eq(out_gy, gy, string.format("Round-trip Y matches for (%d,%d)", gx, gy))
    end
end

-- Test 2: Out of Bounds Touch Points
local out_x1, out_y1 = board_view.screen_to_grid(10, 10, grid_w, grid_h)
assert_eq(out_x1, nil, "Far bottom-left touch returns nil")

local out_x2, out_y2 = board_view.screen_to_grid(700, 1200, grid_w, grid_h)
assert_eq(out_x2, nil, "Far top-right touch returns nil")

-- Test 3: Sprite Name Mappings
assert_eq(board_view.get_sprite_name("amber", nil, nil), "piece_amber", "Amber tile sprite")
assert_eq(board_view.get_sprite_name("sapphire", nil, nil), "piece_sapphire", "Sapphire tile sprite")
assert_eq(board_view.get_sprite_name(nil, "rocket_h", nil), "powerup_rocket_h", "Horizontal rocket sprite")
assert_eq(board_view.get_sprite_name(nil, "bomb", nil), "powerup_bomb", "Bomb sprite")
assert_eq(board_view.get_sprite_name(nil, "firefly", nil), "powerup_firefly", "Firefly sprite")
assert_eq(board_view.get_sprite_name(nil, "lantern", nil), "powerup_lantern", "Magic lantern sprite")
assert_eq(board_view.get_sprite_name(nil, nil, {type = "bramble", layer = 2}), "obstacle_bramble_2", "Bramble layer 2 sprite")
assert_eq(board_view.get_sprite_name(nil, nil, {type = "stone", layer = 1}), "obstacle_stone_1", "Stone layer 1 sprite")
assert_eq(board_view.get_sprite_name(nil, nil, {type = "ingredient"}), "ingredient_acorn", "Acorn ingredient sprite")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
