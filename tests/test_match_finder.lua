--- Unit tests for match detection algorithms and legal swap validation.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_match_finder.lua`

package.path = package.path .. ";./?.lua"

local grid = require("game.board.grid")
local match_finder = require("game.board.match_finder")

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

print("--- Running Match Finder & Swap Validation Tests ---")

-- Test 1: Standard Horizontal Match-3
local g1 = grid.create(6, 6)
grid.set_tile(g1, 2, 2, "amber")
grid.set_tile(g1, 3, 2, "amber")
grid.set_tile(g1, 4, 2, "amber")

local matches1 = match_finder.find_all_matches(g1)
assert_eq(#matches1, 1, "Should find exactly 1 match")
assert_eq(matches1[1].pattern, match_finder.PATTERN_MATCH_3, "Pattern should be match_3")
assert_eq(matches1[1].tile_type, "amber", "Matched color should be amber")
assert_eq(#matches1[1].cells, 3, "Should have 3 cells")
assert_eq(matches1[1].created_powerup, nil, "Match-3 does not create a powerup")

-- Test 2: Horizontal Match-4 creates Rocket H
local g2 = grid.create(6, 6)
grid.set_tile(g2, 2, 3, "emerald")
grid.set_tile(g2, 3, 3, "emerald")
grid.set_tile(g2, 4, 3, "emerald")
grid.set_tile(g2, 5, 3, "emerald")

local matches2 = match_finder.find_all_matches(g2)
assert_eq(#matches2, 1, "Should find 1 match")
assert_eq(matches2[1].pattern, match_finder.PATTERN_ROCKET_H, "Pattern should be rocket_h")
assert_eq(matches2[1].created_powerup, "rocket_h", "Should create rocket_h")
assert_eq(#matches2[1].cells, 4, "Should contain 4 cells")

-- Test 3: Vertical Match-4 creates Rocket V
local g3 = grid.create(6, 6)
grid.set_tile(g3, 2, 1, "sapphire")
grid.set_tile(g3, 2, 2, "sapphire")
grid.set_tile(g3, 2, 3, "sapphire")
grid.set_tile(g3, 2, 4, "sapphire")

local matches3 = match_finder.find_all_matches(g3)
assert_eq(#matches3, 1, "Should find 1 vertical match")
assert_eq(matches3[1].pattern, match_finder.PATTERN_ROCKET_V, "Pattern should be rocket_v")
assert_eq(matches3[1].created_powerup, "rocket_v", "Should create rocket_v")

-- Test 4: Match-5 in line creates Magic Lantern
local g4 = grid.create(6, 6)
for x = 1, 5 do
    grid.set_tile(g4, x, 4, "ruby")
end

local matches4 = match_finder.find_all_matches(g4)
assert_eq(#matches4, 1, "Should find 1 match-5")
assert_eq(matches4[1].pattern, match_finder.PATTERN_LANTERN, "Pattern should be lantern")
assert_eq(matches4[1].created_powerup, "lantern", "Should create lantern")
assert_eq(#matches4[1].cells, 5, "Should have 5 cells")

-- Test 5: T-Shape Intersection creates Bomb
local g5 = grid.create(6, 6)
-- Horizontal: (2,3), (3,3), (4,3)
grid.set_tile(g5, 2, 3, "amethyst")
grid.set_tile(g5, 3, 3, "amethyst")
grid.set_tile(g5, 4, 3, "amethyst")
-- Vertical intersecting at (3,3): (3,1), (3,2), (3,3)
grid.set_tile(g5, 3, 1, "amethyst")
grid.set_tile(g5, 3, 2, "amethyst")

local matches5 = match_finder.find_all_matches(g5)
assert_eq(#matches5, 1, "T-shape should be merged into 1 Bomb match")
assert_eq(matches5[1].pattern, match_finder.PATTERN_BOMB, "Pattern should be bomb")
assert_eq(matches5[1].created_powerup, "bomb", "Should create bomb")
assert_eq(#matches5[1].cells, 5, "Total 5 unique cells in T-shape")
assert_eq(matches5[1].spawn_pos.x, 3, "Bomb spawns at intersection x=3")
assert_eq(matches5[1].spawn_pos.y, 3, "Bomb spawns at intersection y=3")

-- Test 6: 2x2 Square creates Firefly
local g6 = grid.create(6, 6)
grid.set_tile(g6, 2, 2, "emerald")
grid.set_tile(g6, 3, 2, "emerald")
grid.set_tile(g6, 2, 3, "emerald")
grid.set_tile(g6, 3, 3, "emerald")

local matches6 = match_finder.find_all_matches(g6)
assert_eq(#matches6, 1, "2x2 square should produce 1 match")
assert_eq(matches6[1].pattern, match_finder.PATTERN_FIREFLY, "Pattern should be firefly")
assert_eq(matches6[1].created_powerup, "firefly", "Should create firefly")

-- Test 7: Swap Validation
local g7 = grid.create(5, 5)
-- Setup: (1,1)=A, (2,1)=A, (3,1)=E, (4,1)=A
grid.set_tile(g7, 1, 1, "amber")
grid.set_tile(g7, 2, 1, "amber")
grid.set_tile(g7, 3, 1, "emerald")
grid.set_tile(g7, 4, 1, "amber")
-- Swapping (3,1) with (4,1) should produce match-3 of amber!
local valid1, res1, is_p1 = match_finder.is_valid_swap(g7, 3, 1, 4, 1)
assert_true(valid1, "Swapping (3,1) with (4,1) is valid")
assert_eq(#res1, 1, "Produces 1 match")
assert_false(is_p1, "Not a powerup activation")
-- Verify board was NOT modified by the speculative validation
assert_eq(grid.get(g7, 3, 1).tile_type, "emerald", "Cell (3,1) preserved")
assert_eq(grid.get(g7, 4, 1).tile_type, "amber", "Cell (4,1) preserved")

-- Invalid swap test
local valid2 = match_finder.is_valid_swap(g7, 1, 1, 2, 1)
assert_false(valid2, "Swapping two amber tiles with each other is invalid (no match change)")

-- Power-up swap is always valid (Royal Match rule)
grid.set_powerup(g7, 3, 1, "bomb")
local valid3, _, is_p3 = match_finder.is_valid_swap(g7, 3, 1, 4, 1)
assert_true(valid3, "Swapping any power-up is unconditionally valid")
assert_true(is_p3, "Flagged as powerup activation")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
