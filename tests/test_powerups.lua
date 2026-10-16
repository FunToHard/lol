--- Unit tests for standalone power-up detonations and combo fusion interaction matrix.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_powerups.lua`

package.path = package.path .. ";./?.lua"

local grid = require("game.board.grid")
local powerups = require("game.board.powerups")

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

print("--- Running Power-Up Activation & Combo Fusion Tests ---")

-- Helper: fills a grid with regular tiles
local function populate_grid(g, default_color)
    for y = 1, g.height do
        for x = 1, g.width do
            grid.set_tile(g, x, y, default_color or "amber")
        end
    end
end

-- Test 1: Single Horizontal Rocket
local g1 = grid.create(7, 7)
populate_grid(g1, "emerald")
grid.set_powerup(g1, 4, 4, "rocket_h")
local res1 = powerups.detonate_single(g1, 4, 4)
assert_eq(#res1.affected_cells, 7, "Horizontal rocket clears all 7 cells in row")
for x = 1, 7 do
    assert_eq(grid.get(g1, x, 4).tile_type, nil, string.format("Row cell (%d,4) should be cleared", x))
end

-- Test 2: Single Vertical Rocket
local g2 = grid.create(7, 7)
populate_grid(g2, "sapphire")
grid.set_powerup(g2, 3, 3, "rocket_v")
local res2 = powerups.detonate_single(g2, 3, 3)
assert_eq(#res2.affected_cells, 7, "Vertical rocket clears all 7 cells in column")
for y = 1, 7 do
    assert_eq(grid.get(g2, 3, y).tile_type, nil, string.format("Column cell (3,%d) should be cleared", y))
end

-- Test 3: Single Bomb (5x5 Area Blast)
local g3 = grid.create(8, 8)
populate_grid(g3, "ruby")
grid.set_powerup(g3, 4, 4, "bomb")
local res3 = powerups.detonate_single(g3, 4, 4)
assert_eq(#res3.affected_cells, 25, "5x5 Bomb clears 25 cells (radius 2)")
assert_eq(grid.get(g3, 4, 4).tile_type, nil, "Center cell cleared")
assert_eq(grid.get(g3, 2, 2).tile_type, nil, "Corner cell (2,2) cleared")

-- Test 4: Single Firefly Jar
local g4 = grid.create(6, 6)
populate_grid(g4, "amethyst")
grid.set_powerup(g4, 3, 3, "firefly")
local res4 = powerups.detonate_single(g4, 3, 3)
assert_true(#res4.affected_cells >= 5, "Firefly clears cross and target")

-- Test 5: Magic Lantern Color Clear
local g5 = grid.create(6, 6)
populate_grid(g5, "emerald")
-- Set 4 cells to ruby
grid.set_tile(g5, 1, 1, "ruby")
grid.set_tile(g5, 2, 2, "ruby")
grid.set_tile(g5, 3, 3, "ruby")
grid.set_tile(g5, 4, 4, "ruby")
grid.set_powerup(g5, 1, 2, "lantern")
-- Swap lantern at (1,2) with ruby at (1,1)
local res5 = powerups.detonate_lantern_color(g5, 1, 2, 1, 1)
assert_eq(res5.color, "ruby", "Targeted color was ruby")
assert_eq(#res5.affected_cells, 5, "Cleared all 4 ruby tiles + lantern origin cell")
assert_eq(grid.get(g5, 1, 1).tile_type, nil, "Ruby at (1,1) cleared")
assert_eq(grid.get(g5, 4, 4).tile_type, nil, "Ruby at (4,4) cleared")

-- Test 6: Combo Rocket + Rocket (Cross Blast)
local g6 = grid.create(7, 7)
populate_grid(g6, "amber")
grid.set_powerup(g6, 4, 4, "rocket_h")
grid.set_powerup(g6, 5, 4, "rocket_v")
local res6 = powerups.detonate_combo(g6, 4, 4, 5, 4)
assert_eq(res6.combo, "rocket_rocket", "Combo identified as rocket_rocket")
-- 7 row cells + 7 col cells - 1 intersection = 13 cells
assert_eq(#res6.affected_cells, 13, "Cross blast affects 13 cells")

-- Test 7: Combo Rocket + Bomb (3 Rows + 3 Columns Mega Cross)
local g7 = grid.create(9, 9)
populate_grid(g7, "emerald")
grid.set_powerup(g7, 5, 5, "rocket_h")
grid.set_powerup(g7, 5, 6, "bomb")
local res7 = powerups.detonate_combo(g7, 5, 5, 5, 6)
assert_eq(res7.combo, "rocket_bomb", "Combo identified as rocket_bomb")
assert_true(#res7.affected_cells > 25, "Mega cross blast clears wide swath")

-- Test 8: Combo Bomb + Bomb (Massive 7x7 Blast)
local g8 = grid.create(9, 9)
populate_grid(g8, "sapphire")
grid.set_powerup(g8, 5, 5, "bomb")
grid.set_powerup(g8, 5, 6, "bomb")
local res8 = powerups.detonate_combo(g8, 5, 5, 5, 6)
assert_eq(res8.combo, "bomb_bomb", "Combo identified as bomb_bomb")
assert_eq(#res8.affected_cells, 49, "7x7 area = 49 cells cleared")

-- Test 9: Combo Lantern + Lantern (Ultimate Board Wipe)
local g9 = grid.create(8, 8)
populate_grid(g9, "ruby")
grid.set_powerup(g9, 4, 4, "lantern")
grid.set_powerup(g9, 5, 4, "lantern")
local res9 = powerups.detonate_combo(g9, 4, 4, 5, 4)
assert_eq(res9.combo, "lantern_lantern", "Combo identified as lantern_lantern")
assert_eq(#res9.affected_cells, 64, "All 64 cells on 8x8 board cleared")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
