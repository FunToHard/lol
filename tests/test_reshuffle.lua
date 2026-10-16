--- Unit tests for dead-board detection and automatic piece reshuffling.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_reshuffle.lua`

package.path = package.path .. ";./?.lua"

local grid = require("game.board.grid")
local prng = require("game.board.prng")
local reshuffle = require("game.board.reshuffle")
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

print("--- Running Dead-Board Detection & Reshuffle Tests ---")

-- Test 1: Normal board with legal moves
local g1 = grid.create(4, 4)
-- Set up a clear move: (1,1)=A, (2,1)=A, (3,1)=E, (4,1)=A
grid.set_tile(g1, 1, 1, "amber")
grid.set_tile(g1, 2, 1, "amber")
grid.set_tile(g1, 3, 1, "emerald")
grid.set_tile(g1, 4, 1, "amber")
-- Fill remainder with alternating colors
for y = 2, 4 do
    for x = 1, 4 do
        grid.set_tile(g1, x, y, (x % 2 == y % 2) and "sapphire" or "ruby")
    end
end

local has_moves1, sample1 = reshuffle.has_legal_moves(g1)
assert_true(has_moves1, "Board has legal moves")
assert_true(sample1 ~= nil, "Returned a sample move")

-- Test 2: Dead Board (No legal moves possible)
local g2 = grid.create(4, 4)
local dead_pattern = {
    {"amber", "emerald", "sapphire", "ruby"},
    {"sapphire", "ruby", "amber", "emerald"},
    {"emerald", "amber", "ruby", "sapphire"},
    {"ruby", "sapphire", "emerald", "amber"}
}
for y = 1, 4 do
    for x = 1, 4 do
        grid.set_tile(g2, x, y, dead_pattern[y][x])
    end
end

local has_moves2 = reshuffle.has_legal_moves(g2)
assert_false(has_moves2, "4-color pattern has 0 legal moves (Dead board)")
assert_eq(reshuffle.count_legal_moves(g2), 0, "Move count is 0")

-- Test 3: Reshuffle execution on a dead board
-- We need a board with enough pieces of varied colors to form a valid match
local g3 = grid.create(6, 6)
-- Populate with 3 of each color so matches are mathematically possible
local colors = {"amber", "emerald", "sapphire", "ruby"}
local idx = 1
for y = 1, 6 do
    for x = 1, 6 do
        grid.set_tile(g3, x, y, colors[((x + y * 2) % 4) + 1])
    end
end

-- Force dead-board state if any exist, or verify reshuffle reshuffles and leaves valid state
local rng = prng.new(12345)
local success, report = reshuffle.execute(g3, rng)
assert_true(success, "Reshuffle succeeded")
assert_true(report.moves_created >= 1, "Created at least 1 legal move")

-- Verify NO immediate 3-in-a-row matches exist on the reshuffled board
local post_matches = match_finder.find_all_matches(g3)
assert_eq(#post_matches, 0, "Reshuffled board has zero pre-existing matches")

-- Verify board now has legal moves
local post_has_moves, _ = reshuffle.has_legal_moves(g3)
assert_true(post_has_moves, "Post-reshuffle board is playable")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
