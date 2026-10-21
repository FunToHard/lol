--- Unit tests for JSON parsing, level loading, and goal tracking.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_level_loader.lua`

package.path = package.path .. ";./?.lua"

local json = require("game.board.json")
local level_loader = require("game.board.level_loader")
local level_tracker = require("game.board.level_tracker")
local prng = require("game.board.prng")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Level Loader & Goal Tracker Tests ---")

-- Test 1: JSON serialization and parsing roundtrip
local sample = {
    version = 1,
    title = "Test Level",
    active = true,
    count = 42,
    colors = { "amber", "ruby" }
}
local enc = json.encode(sample)
local dec = json.decode(enc)
assert_eq(dec.version, 1, "Decoded version matches")
assert_eq(dec.title, "Test Level", "Decoded title matches")
assert_eq(dec.active, true, "Decoded boolean matches")
assert_eq(dec.count, 42, "Decoded number matches")
assert_eq(dec.colors[1], "amber", "Decoded array item 1 matches")
assert_eq(dec.colors[2], "ruby", "Decoded array item 2 matches")

-- Test 2: Schema validation
local valid_def = {
    version = 1,
    level_id = 1,
    moves = 20,
    grid = { width = 8, height = 8 },
    goals = { { type = "collect_color", target = "amber", count = 10 } }
}
local is_valid, err = level_loader.validate_schema(valid_def)
assert_eq(is_valid, true, "Valid definition passes schema check")

local invalid_def = {
    version = 1,
    -- Missing moves and goals
    grid = { width = 8, height = 8 }
}
local bad_valid, bad_err = level_loader.validate_schema(invalid_def)
assert_eq(bad_valid, false, "Invalid definition fails schema check")

-- Test 3: Goal Tracker progression and Win/Loss
local tracker = level_tracker.new(valid_def)
assert_eq(tracker.moves_remaining, 20, "Initial moves remaining is 20")
assert_eq(tracker.status, "IN_PROGRESS", "Initial status is IN_PROGRESS")

level_tracker.record_matches(tracker, { "amber", "amber", "ruby" })
assert_eq(tracker.goals[1].current_count, 2, "2 amber pieces counted toward goal")
assert_eq(tracker.status, "IN_PROGRESS", "Still in progress")

level_tracker.record_move(tracker)
assert_eq(tracker.moves_remaining, 19, "Moves remaining is 19 after one move")

-- Complete remaining 8 amber pieces
level_tracker.record_matches(tracker, { "amber", "amber", "amber", "amber", "amber", "amber", "amber", "amber" })
assert_eq(tracker.goals[1].current_count, 10, "Goal target count reached")
assert_eq(tracker.goals[1].completed, true, "Goal marked as completed")
assert_eq(tracker.status, "WON", "Level status transitioned to WON")
assert_eq(level_tracker.is_won(tracker), true, "is_won evaluates to true")

-- Test 4: Loss condition (moves depleted)
local loss_def = {
    version = 1,
    level_id = 2,
    moves = 2,
    grid = { width = 8, height = 8 },
    goals = { { type = "clear_obstacle", target = "bramble", count = 5 } }
}
local loss_tracker = level_tracker.new(loss_def)
level_tracker.record_move(loss_tracker)
level_tracker.record_move(loss_tracker)
assert_eq(loss_tracker.moves_remaining, 0, "Moves depleted to 0")
assert_eq(loss_tracker.status, "LOST", "Level status transitioned to LOST")
assert_eq(level_tracker.is_lost(loss_tracker), true, "is_lost evaluates to true")

-- Test 5: Setup Board with Active Mask and Obstacles
local masked_def = {
    version = 1,
    level_id = 3,
    moves = 25,
    grid = {
        width = 4,
        height = 4,
        active_cells = {
            "1111",
            "1001",
            "1001",
            "1111"
        }
    },
    obstacles = {
        { type = "bramble", layer = 1, x = 0, y = 0, is_one_indexed = false }
    },
    goals = { { type = "clear_obstacle", target = "bramble", count = 1 } }
}
local rng = prng.new(42)
local board = level_loader.setup_board(masked_def, rng)
local grid_mod = require("game.board.grid")
assert_eq(grid_mod.get(board, 2, 2).is_enabled, false, "Cell (2,2) disabled by active mask")
assert_eq(grid_mod.get(board, 3, 3).is_enabled, false, "Cell (3,3) disabled by active mask")
assert_eq(grid_mod.get(board, 1, 1).is_enabled, true, "Cell (1,1) enabled")
assert_eq(grid_mod.get(board, 1, 1).obstacle.type, "bramble", "Bramble obstacle placed at (1,1)")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
