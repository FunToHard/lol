--- Unit tests for board grid matrix and spatial cell lifecycle states.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_grid.lua`

package.path = package.path .. ";./?.lua"

local cell = require("game.board.cell")
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

print("--- Running Board Grid & Cell Lifecycle Tests ---")

-- Test 1: Grid Creation and Bounds
local g = grid.create(8, 8)
assert_eq(g.width, 8, "Grid width should be 8")
assert_eq(g.height, 8, "Grid height should be 8")
assert_true(grid.is_inside(g, 1, 1), "Top-left is inside")
assert_true(grid.is_inside(g, 8, 8), "Bottom-right is inside")
assert_false(grid.is_inside(g, 0, 1), "Column 0 is outside")
assert_false(grid.is_inside(g, 1, 9), "Row 9 is outside")
assert_false(grid.is_inside(g, 9, 8), "Column 9 is outside")

-- Test 2: Adjacency (Orthogonal only, no diagonals)
assert_true(grid.is_adjacent(3, 3, 3, 4), "Adjacent vertically")
assert_true(grid.is_adjacent(3, 3, 4, 3), "Adjacent horizontally")
assert_false(grid.is_adjacent(3, 3, 4, 4), "Diagonals are not adjacent")
assert_false(grid.is_adjacent(3, 3, 3, 3), "Same cell is not adjacent")
assert_false(grid.is_adjacent(1, 1, 1, 3), "Distance 2 is not adjacent")

-- Test 3: Grid Masking (Holes)
local masked_grid = grid.create(3, 3, {
    "111",
    "101",
    "111"
})
assert_true(grid.get(masked_grid, 1, 1).is_enabled, "Cell 1,1 enabled")
assert_false(grid.get(masked_grid, 2, 2).is_enabled, "Center hole 2,2 disabled")
assert_eq(grid.get(masked_grid, 2, 2).state, cell.STATE_DISABLED, "Hole state is disabled")

-- Test 4: Tile Assignment and Swap Validity
grid.set_tile(g, 1, 1, "amber")
grid.set_tile(g, 1, 2, "emerald")
assert_true(grid.can_swap(g, 1, 1, 1, 2), "Adjacent idle tiles can be swapped")

-- Test 5: Spatial Concurrency (Royal Match Non-Blocking Cascades)
-- Column 5 has a falling piece
grid.set_tile(g, 5, 5, "ruby")
grid.set_tile(g, 5, 6, "sapphire")
local c55 = grid.get(g, 5, 5)
cell.set_state(c55, cell.STATE_FALLING)

-- Cell in column 5 cannot be swapped while falling
assert_false(grid.can_swap(g, 5, 5, 5, 6), "Falling cell in col 5 cannot be swapped")

-- CRITICAL TEST: Idle cells in Column 1 CAN STILL BE SWAPPED concurrently!
assert_true(grid.can_swap(g, 1, 1, 1, 2), "Columns 1 cells remain swappable while Col 5 falls")

-- Test 6: Swap Execution
assert_eq(grid.get(g, 1, 1).tile_type, "amber", "Initial 1,1 is amber")
assert_eq(grid.get(g, 1, 2).tile_type, "emerald", "Initial 1,2 is emerald")
local swapped = grid.swap(g, 1, 1, 1, 2)
assert_true(swapped, "Swap succeeded")
assert_eq(grid.get(g, 1, 1).tile_type, "emerald", "After swap 1,1 is emerald")
assert_eq(grid.get(g, 1, 2).tile_type, "amber", "After swap 1,2 is amber")

-- Test 7: Powerup Swappability
grid.set_powerup(g, 2, 2, "bomb")
grid.set_tile(g, 2, 3, "sapphire")
assert_true(grid.can_swap(g, 2, 2, 2, 3), "Powerup can swap with regular tile")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
