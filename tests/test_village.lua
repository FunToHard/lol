--- Unit tests for woodland village restoration metagame, 3-style selector, and companion.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_village.lua`

package.path = package.path .. ";./?.lua"

local task_catalog = require("game.restoration.task_catalog")
local village_state = require("game.restoration.village_state")
local companion = require("game.restoration.companion")
local ledger = require("game.economy.ledger")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Village Metagame & Companion Tests ---")

-- Test 1: Task Catalog verification for Area 1 (Hearthstone Courtyard)
local tasks = task_catalog.get_tasks_for_area(task_catalog.AREA_1_ID)
assert_eq(#tasks, 12, "Area 1 defines exactly 12 renovation tasks")

for i, t in ipairs(tasks) do
    assert_eq(type(t.id), "string", string.format("Task #%d has valid ID string", i))
    assert_eq(t.cost >= 1 and t.cost <= 3, true, string.format("Task #%d has reasonable star cost (1-3)", i))
    assert_eq(#t.styles, 3, string.format("Task #%d provides exactly 3 customization styles", i))
end

-- Test 2: Village State Initialization
local econ = ledger.new()
local vstate = village_state.new(nil, econ)

local active1 = village_state.get_active_task(vstate)
assert_eq(active1.id, "clear_ruined_leaves", "First task in sequence is clear_ruined_leaves")
assert_eq(village_state.can_complete_task(vstate, active1.id), false, "Cannot afford without stars")

-- Test 3: Star Spending & Task Completion
ledger.apply_transaction(econ, "op_test_stars", "stars", 5, "level_rewards")
assert_eq(village_state.can_complete_task(vstate, active1.id), true, "Can afford task with 5 stars")

local ok_task1, err_task1 = village_state.complete_task(vstate, active1.id, 2, "op_task_1")
assert_eq(ok_task1, true, "Completed task 1 successfully: " .. tostring(err_task1))
assert_eq(ledger.get_balance(econ, "stars"), 4, "1 star deducted from ledger (balance now 4)")
assert_eq(village_state.is_task_completed(vstate, "clear_ruined_leaves"), true, "Task 1 marked completed")
assert_eq(vstate.chosen_styles["clear_ruined_leaves"], 2, "Chosen style is 2 (Mossy Reed Rake)")

-- Sequence advances to task 2
local active2 = village_state.get_active_task(vstate)
assert_eq(active2.id, "repair_stone_hearth", "Sequence advanced to task 2 (repair_stone_hearth)")

-- Test 4: Free Re-styling Rule (Zero Currency Cost)
local stars_before = ledger.get_balance(econ, "stars")
local ok_restyle = village_state.restyle_prop(vstate, "clear_ruined_leaves", 3)
assert_eq(ok_restyle, true, "Re-styling completed successfully")
assert_eq(vstate.chosen_styles["clear_ruined_leaves"], 3, "Style changed to 3 (Whimsical Gust)")
assert_eq(ledger.get_balance(econ, "stars"), stars_before, "Free re-styling did not deduct any stars")

-- Test 5: Completion Stats Calculation
local stats = village_state.get_completion_stats(vstate)
assert_eq(stats.completed_count, 1, "1 task completed")
assert_eq(stats.total_count, 12, "12 total tasks")
assert_eq(stats.percent_complete, 8, "Completion percentage is 8%")

-- Test 6: Companion Controller & Emotes
local comp = companion.new("Pip")
assert_eq(comp.name, "Pip", "Companion name is Pip")
assert_eq(comp.current_emote, companion.EMOTES.IDLE, "Starts in IDLE emote")

local dialogue = companion.trigger_reaction(comp, companion.EMOTES.CELEBRATE, 2.0)
assert_eq(comp.current_emote, companion.EMOTES.CELEBRATE, "Emote transitioned to CELEBRATE")
assert_eq(type(dialogue), "string", "Celebration dialogue line returned")

companion.update(comp, 1.0)
assert_eq(comp.current_emote, companion.EMOTES.CELEBRATE, "Still celebrating after 1s")

companion.update(comp, 1.5)
assert_eq(comp.current_emote, companion.EMOTES.IDLE, "Reverted back to IDLE after timer expired")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
