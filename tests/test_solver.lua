--- Unit tests for headless Monte Carlo AI level solver.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_solver.lua`

package.path = package.path .. ";./?.lua"

local solver = require("tools.solver")
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

print("--- Running AI Level Solver Tests ---")

-- Test 1: Simple introductory level simulation
local intro_level = {
    version = 1,
    level_id = 1,
    difficulty = "intro",
    moves = 25,
    grid = { width = 8, height = 8 },
    goals = {
        { type = "collect_color", target = "amber", count = 10 }
    }
}

local rng = prng.new(777)
local res = solver.simulate_game(intro_level, "strategic", rng)
assert_eq(type(res.won), "boolean", "Result contains boolean won field")
assert_eq(type(res.remaining_moves), "number", "Result contains remaining_moves number")
assert_eq(res.won, true, "Strategic persona reliably clears simple intro level")

-- Test 2: Monte Carlo batch run
local mc = solver.run_monte_carlo(intro_level, 10, 123)
assert_eq(mc.runs, 10, "Monte Carlo executed 10 runs")
assert_eq(mc.wins >= 8, true, "Intro level win rate >= 80% on 10 runs")
assert_eq(type(mc.win_rate), "number", "Win rate is a number")
assert_eq(type(mc.avg_remaining_moves), "number", "Average remaining moves is a number")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
