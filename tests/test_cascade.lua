--- Unit tests for gravity drop, spawner refill, and cascade resolution.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_cascade.lua`

package.path = package.path .. ";./?.lua"

local grid = require("game.board.grid")
local match_finder = require("game.board.match_finder")
local prng = require("game.board.prng")
local cascade = require("game.board.cascade")

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

print("--- Running Gravity & Cascade Tests ---")

-- Test 1: Clear matches and place powerup
local g1 = grid.create(5, 5)
for x = 1, 4 do
    grid.set_tile(g1, x, 5, "amber")
end
local matches1 = match_finder.find_all_matches(g1, {x = 2, y = 5})
local clear_event = cascade.apply_matches(g1, matches1)
assert_eq(#clear_event.powerups, 1, "Should spawn 1 powerup")
assert_eq(clear_event.powerups[1].powerup_type, "rocket_h", "Should be rocket_h")
assert_eq(grid.get(g1, 2, 5).powerup_type, "rocket_h", "Powerup placed at (2,5)")
assert_eq(grid.get(g1, 1, 5).tile_type, nil, "Cell (1,5) cleared")
assert_eq(grid.get(g1, 3, 5).tile_type, nil, "Cell (3,5) cleared")

-- Test 2: Gravity Drop
local g2 = grid.create(3, 5)
-- Place a tile at top (2,1) and leave (2,2) to (2,5) empty
grid.set_tile(g2, 2, 1, "sapphire")
local falls = cascade.apply_gravity(g2)
assert_eq(#falls, 1, "One piece fell")
assert_eq(falls[1].from.y, 1, "Fell from row 1")
assert_eq(falls[1].to.y, 5, "Fell down to bottom row 5")
assert_eq(grid.get(g2, 2, 5).tile_type, "sapphire", "Piece settled at (2,5)")
assert_eq(grid.get(g2, 2, 1).tile_type, nil, "Origin cell (2,1) is now empty")

-- Test 3: Spawner Refill
local g3 = grid.create(3, 3)
local rng3 = prng.new(42)
local colors = {"amber", "emerald", "sapphire"}
local spawns = cascade.refill_spawners(g3, rng3, colors)
assert_eq(#spawns, 9, "All 9 empty cells refilled")
for y = 1, 3 do
    for x = 1, 3 do
        local c = grid.get(g3, x, y)
        assert_true(c.tile_type ~= nil, string.format("Cell (%d,%d) is filled", x, y))
    end
end

-- Test 4: Determinism of Full Cascade
local function run_cascade_simulation(seed)
    local g = grid.create(4, 5)
    -- Fill bottom with a horizontal match-3
    grid.set_tile(g, 1, 5, "amber")
    grid.set_tile(g, 2, 5, "amber")
    grid.set_tile(g, 3, 5, "amber")
    grid.set_tile(g, 4, 5, "emerald")

    -- Fill upper rows with assorted colors
    for y = 1, 4 do
        for x = 1, 4 do
            grid.set_tile(g, x, y, (x % 2 == 0) and "emerald" or "sapphire")
        end
    end

    local rng = prng.new(seed)
    local initial_matches = match_finder.find_all_matches(g)
    local steps, waves = cascade.resolve(g, rng, {"amber", "emerald", "sapphire", "ruby"}, initial_matches)
    return g, steps, waves
end

local g_sim1, steps1, waves1 = run_cascade_simulation(9999)
local g_sim2, steps2, waves2 = run_cascade_simulation(9999)

assert_eq(waves1, waves2, "Wave counts must match deterministically")
assert_eq(#steps1, #steps2, "Step counts must match deterministically")

-- Verify every single cell on the board matches across both runs
for y = 1, 5 do
    for x = 1, 4 do
        local c1 = grid.get(g_sim1, x, y)
        local c2 = grid.get(g_sim2, x, y)
        assert_eq(c1.tile_type, c2.tile_type, string.format("Tile at (%d,%d) must be identical", x, y))
    end
end

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
