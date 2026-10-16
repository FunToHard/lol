--- Unit tests for obstacle layers, adjacent damage, blast damage, and ingredient collection.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_obstacles.lua`

package.path = package.path .. ";./?.lua"

local grid = require("game.board.grid")
local cell = require("game.board.cell")
local obstacles = require("game.board.obstacles")
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

print("--- Running Obstacle & Blocker Tests ---")

-- Test 1: Obstacle creation and direct damage
local c1 = cell.new(1, 1)
c1.obstacle = obstacles.create("bramble", 2, false)
assert_eq(c1.obstacle.layer, 2, "Initial layer is 2")

local dmg1, dest1 = obstacles.damage_cell(c1, 1)
assert_true(dmg1, "Took damage")
assert_false(dest1, "Not yet destroyed")
assert_eq(c1.obstacle.layer, 1, "Layer reduced to 1")

local dmg2, dest2 = obstacles.damage_cell(c1, 1)
assert_true(dmg2, "Took second damage")
assert_true(dest2, "Destroyed on reaching 0")
assert_eq(c1.obstacle, nil, "Obstacle cleared from cell")

-- Test 2: Adjacent match damage
local g2 = grid.create(5, 5)
-- Place 2-hit bramble at (2,3)
local target_c = grid.get(g2, 2, 3)
target_c.obstacle = obstacles.create("bramble", 2, false)

-- Make horizontal match-3 right next to it at row 2: (1,2), (2,2), (3,2)
grid.set_tile(g2, 1, 2, "amber")
grid.set_tile(g2, 2, 2, "amber")
grid.set_tile(g2, 3, 2, "amber")

local matches2 = match_finder.find_all_matches(g2)
local dmg_list = obstacles.damage_adjacent(g2, matches2)
assert_eq(#dmg_list, 1, "Bramble at (2,3) took adjacent damage")
assert_eq(dmg_list[1].x, 2, "Damaged x=2")
assert_eq(dmg_list[1].y, 3, "Damaged y=3")
assert_eq(dmg_list[1].remaining_layer, 1, "Bramble layer is now 1")

-- Test 3: Blast damage from power-up
local g3 = grid.create(5, 5)
grid.get(g3, 2, 2).obstacle = obstacles.create("stone", 2, true)
grid.get(g3, 4, 4).obstacle = obstacles.create("bramble", 1, false)

local bomb_blast = {
    {x = 2, y = 2}, {x = 3, y = 3}, {x = 4, y = 4}
}
local blast_dmg = obstacles.damage_from_blast(g3, bomb_blast, 1)
assert_eq(#blast_dmg, 2, "Both obstacles hit by blast")
assert_eq(grid.get(g3, 2, 2).obstacle.layer, 1, "Stone reduced to layer 1")
assert_eq(grid.get(g3, 4, 4).obstacle, nil, "Bramble destroyed by blast")

-- Test 4: Bottom row ingredient collection
local g4 = grid.create(4, 6)
-- Place an acorn ingredient at bottom row (3,6) and another at row (2,3)
grid.get(g4, 3, 6).obstacle = obstacles.create("ingredient", 1, false)
grid.get(g4, 2, 3).obstacle = obstacles.create("ingredient", 1, false)

local collected = obstacles.collect_bottom_ingredients(g4)
assert_eq(#collected, 1, "Only bottom row ingredient collected")
assert_eq(collected[1].x, 3, "Collected from column 3")
assert_eq(grid.get(g4, 3, 6).obstacle, nil, "Bottom cell cleared")
assert_true(grid.get(g4, 2, 3).obstacle ~= nil, "Mid-board ingredient remains")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
