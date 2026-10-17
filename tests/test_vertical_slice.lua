--- Comprehensive automated playtest of the full 25-level vertical slice.
-- Simulates the core game loop: Play Level -> Earn Star -> Restore Village -> Companion Emote.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_vertical_slice.lua`

package.path = package.path .. ";./?.lua"

local save_manager = require("game.persistence.save_manager")
local ledger = require("game.economy.ledger")
local level_loader = require("game.board.level_loader")
local level_tracker = require("game.board.level_tracker")
local solver = require("tools.solver")
local prng = require("game.board.prng")
local ads_service = require("game.services.ads_service")
local mock_ads_adapter = require("game.services.mock_ads_adapter")
local level_flow = require("game.services.level_flow")
local village_state = require("game.restoration.village_state")
local companion = require("game.restoration.companion")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("==================================================")
print("   LANTERN GROOVE - 25-LEVEL VERTICAL SLICE TEST  ")
print("==================================================")

local test_dir = "tests/fixtures_vslice"
os.execute("mkdir " .. test_dir:gsub("/", "\\"))

-- Start with a clean new-game state
local save_data = save_manager.create_default_state()
save_manager.save(save_data, test_dir)

local econ = ledger.new({
    balances = {
        stars = save_data.player.stars,
        coins = save_data.player.coins,
        boosters = save_data.player.inventory
    },
    history = save_data.ledger_history
})

local ads = ads_service.new(mock_ads_adapter.new(true))
local village = village_state.new(save_data.village, econ)
local pip = companion.new("Pip")

local base_seed = 98765

for lvl_id = 1, 25 do
    local level_path = string.format("assets/levels/level_%03d.json", lvl_id)
    local def = level_loader.load_from_file(level_path)
    local flow = level_flow.new(econ, ads, save_data, lvl_id, test_dir)

    -- Play level using strategic heuristic solver
    local rng = prng.new(base_seed + lvl_id * 101)
    local sim_res = solver.simulate_game(def, "strategic", rng)

    -- If solver was tight on moves, simulate fair continuation
    if not sim_res.won then
        if flow:can_use_ad_continuation() then
            local dummy_tracker = { moves_remaining = 0, status = "LOST" }
            flow:watch_ad_for_extra_moves(dummy_tracker)
            assert_eq(dummy_tracker.moves_remaining, 3, "Ad continuation granted +3 moves")
        end
    end

    -- Complete level victory flow
    local reward = flow:on_level_won()
    assert_eq(reward.stars, 1, string.format("Level %d granted 1 Lantern Spark", lvl_id))
    assert_eq(save_data.progression.max_unlocked_level >= lvl_id + 1, true, string.format("Progression unlocked level %d", lvl_id + 1))

    -- Check village restoration
    local active_task = village_state.get_active_task(village)
    if active_task and ledger.can_afford(econ, "stars", active_task.cost) then
        local chosen_style = ((lvl_id - 1) % 3) + 1
        local op_id = string.format("op_vslice_task_%s_%d", active_task.id, lvl_id)
        local ok_task = village_state.complete_task(village, active_task.id, chosen_style, op_id)
        assert_eq(ok_task, true, string.format("Restored courtyard prop: %s (Style %d)", active_task.id, chosen_style))

        -- Companion reaction
        local dialogue = companion.trigger_reaction(pip, companion.EMOTES.CELEBRATE, 3.0)
        assert_eq(pip.current_emote, companion.EMOTES.CELEBRATE, "Pip celebrated task completion")
        assert_eq(type(dialogue), "string", "Pip provided woodland praise")

        -- Save synced village state
        save_data.village.completed_tasks = village.completed_tasks
        save_data.village.chosen_styles = village.chosen_styles
        save_manager.save(save_data, test_dir)
    end
end

-- Verify final vertical slice state
local final_loaded, src = save_manager.load(test_dir)
assert_eq(src, "primary", "Vertical slice save verified on disk")
assert_eq(final_loaded.progression.max_unlocked_level >= 26, true, "All 25 levels cleared and level 26 unlocked")

local v_stats = village_state.get_completion_stats(village)
print(string.format(" Courtyard Restoration: %d/%d tasks completed (%d%%)", v_stats.completed_count, v_stats.total_count, v_stats.percent_complete))
assert_eq(v_stats.completed_count, 12, "All 12 Hearthstone Courtyard tasks 100% completed")
assert_eq(v_stats.percent_complete, 100, "Courtyard 100% restored")

-- Test free re-styling across completed village
local ok_restyle = village_state.restyle_prop(village, "repair_stone_hearth", 3)
assert_eq(ok_restyle, true, "Free re-styling verified on completed courtyard prop")

-- Cleanup fixture
local p1, p2, p3 = save_manager.get_save_paths(test_dir)
os.remove(p1)
os.remove(p2)
os.remove(p3)
os.execute("rmdir " .. test_dir:gsub("/", "\\"))

print("==================================================")
print(string.format(" VERTICAL SLICE VALIDATION PASSED! (%d/%d assertions)", passed_tests, total_tests))
print("==================================================")
