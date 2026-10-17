--- Master test runner executing all pure Lua board simulation unit tests.
-- Verifies determinism, replays, cascades, power-ups, and reshuffles.
-- Usage: `lua tests/run_all_tests.lua`

package.path = package.path .. ";./?.lua"

print("==================================================")
print("     LANTERN GROOVE - MASTER BOARD TEST SUITE     ")
print("==================================================")

local test_suites = {
    "tests/test_grid.lua",
    "tests/test_match_finder.lua",
    "tests/test_cascade.lua",
    "tests/test_powerups.lua",
    "tests/test_obstacles.lua",
    "tests/test_reshuffle.lua",
    "tests/test_board_view.lua",
    "tests/test_input_controller.lua",
    "tests/test_render.lua",
    "tests/test_hud.lua",
    "tests/test_boosters.lua",
    "tests/test_haptic.lua",
    "tests/test_effects.lua",
    "tests/test_level_loader.lua",
    "tests/test_solver.lua",
    "tests/test_batch_1_levels.lua",
    "tests/test_level_editor.lua",
    "tests/test_economy.lua",
    "tests/test_persistence.lua",
    "tests/test_village.lua",
    "tests/test_village_ui.lua",
    "tests/test_prop_layer.lua",
    "tests/test_services.lua",
    "tests/test_scene_switcher.lua",
    "tests/test_level_end.lua",
    "tests/test_settings.lua",
    "tests/test_shop_ui.lua",
    "tests/test_map_controller.lua",
    "tests/test_dialogue.lua",
    "tests/test_areas.lua",
    "tests/test_mobile_scaling.lua",
    "tests/test_vertical_slice.lua"
}

local start_time = os.clock()
local suites_passed = 0

for _, suite_path in ipairs(test_suites) do
    local f, err = loadfile(suite_path)
    if not f then
        error(string.format("Failed to load test suite %s: %s", suite_path, tostring(err)))
    end

    local status, run_err = pcall(f)
    if not status then
        error(string.format("Test suite %s FAILED:\n%s", suite_path, tostring(run_err)))
    end

    suites_passed = suites_passed + 1
    print(string.format(" [PASSED] %s", suite_path))
end

-- Comprehensive End-to-End Deterministic Session Simulation
print("\n--- Running End-to-End Deterministic Session Replay ---")
local grid = require("game.board.grid")
local match_finder = require("game.board.match_finder")
local cascade = require("game.board.cascade")
local prng = require("game.board.prng")
local reshuffle = require("game.board.reshuffle")

--- Simulates an end-to-end multi-turn puzzle level session deterministically.
-- @param seed number Initial integer seed.
-- @param turns number Number of simulated player moves to execute.
-- @return string final_board_state Representation for verification.
-- @return number total_matches_made Total match waves cleared.
local function simulate_game_session(seed, turns)
    local g = grid.create(8, 8)
    local rng = prng.new(seed)
    local colors = {"amber", "emerald", "sapphire", "ruby", "amethyst"}

    -- Initial board fill with dead-board safety
    cascade.refill_spawners(g, rng, colors)
    local initial_matches = match_finder.find_all_matches(g)
    if #initial_matches > 0 then
        cascade.resolve(g, rng, colors, initial_matches)
    end
    reshuffle.execute(g, rng)

    local total_cascades = 0

    for turn = 1, turns do
        local has_move, move = reshuffle.has_legal_moves(g)
        if not has_move then
            reshuffle.execute(g, rng)
            has_move, move = reshuffle.has_legal_moves(g)
        end

        if has_move and move then
            local valid, matches, is_powerup = match_finder.is_valid_swap(g, move.from.x, move.from.y, move.to.x, move.to.y)
            if valid then
                grid.swap(g, move.from.x, move.from.y, move.to.x, move.to.y)
                local steps, waves = cascade.resolve(g, rng, colors, matches or {})
                total_cascades = total_cascades + waves
            end
        end
    end

    return grid.to_debug_string(g), total_cascades
end

local board1, cascades1 = simulate_game_session(54321, 10)
local board2, cascades2 = simulate_game_session(54321, 10)

assert(cascades1 == cascades2, "Total cascades across 10 turns must be 100% deterministic")
assert(board1 == board2, "Final board state across 10 turns must be 100% identical")
print(string.format(" [PASSED] 10-turn replay simulation verified (cascades = %d)", cascades1))

local elapsed = os.clock() - start_time
print("==================================================")
print(string.format(" SUCCESS: All %d test suites passed in %.3fs", suites_passed, elapsed))
print("==================================================")
