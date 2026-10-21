--- Validation and automated difficulty verification suite for Batch 1 levels (1 to 25).
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_batch_1_levels.lua`

package.path = package.path .. ";./?.lua"

local level_loader = require("game.board.level_loader")
local solver = require("tools.solver")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Batch 1 Level Schema & Balancing Tests ---")

-- Test 1: Validate all 25 levels pass schema validation
for id = 1, 25 do
    local path = string.format("assets/levels/level_%03d.json", id)
    local def = level_loader.load_from_file(path)
    local ok, err = level_loader.validate_schema(def)
    assert_eq(ok, true, string.format("Level %03d schema valid: %s", id, tostring(err)))
    assert_eq(def.level_id, id, string.format("Level %03d has matching ID", id))
end

-- Test 2: Intro Tier Difficulty Verification (Level 1)
local l1 = level_loader.load_from_file("assets/levels/level_001.json")
local mc1 = solver.run_monte_carlo(l1, 15, 2026)
print(string.format(" Level 001 (Intro) Win Rate: %.1f%% (avg remaining moves: %.1f)", mc1.win_rate, mc1.avg_remaining_moves))
assert_eq(mc1.win_rate >= 85.0, true, "Level 1 meets Intro win rate target (>= 85%)")

-- Test 3: Flow Tier Difficulty Verification (Level 6)
local l6 = level_loader.load_from_file("assets/levels/level_006.json")
local mc6 = solver.run_monte_carlo(l6, 15, 3037)
print(string.format(" Level 006 (Flow) Win Rate: %.1f%% (avg remaining moves: %.1f)", mc6.win_rate, mc6.avg_remaining_moves))
assert_eq(mc6.win_rate >= 65.0, true, "Level 6 meets Flow win rate target (>= 65%)")

-- Test 4: Hard Tier Difficulty Verification (Level 16)
local l16 = level_loader.load_from_file("assets/levels/level_016.json")
local mc16 = solver.run_monte_carlo(l16, 15, 4048)
print(string.format(" Level 016 (Hard) Win Rate: %.1f%% (avg remaining moves: %.1f)", mc16.win_rate, mc16.avg_remaining_moves))
assert_eq(mc16.win_rate >= 40.0 and mc16.win_rate <= 90.0, true, "Level 16 falls into Hard difficulty window (40% - 90%)")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
