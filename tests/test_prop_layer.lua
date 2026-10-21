--- Unit tests for Diorama Prop Layer Controller and visual restoration.
-- Verifies prop coordinates, style tinting, completion tracking, and companion Pip state.
-- Usage: `lua tests/test_prop_layer.lua`

package.path = package.path .. ";./?.lua"

local prop_layer_controller = require("game.restoration.prop_layer_controller")
local companion = require("game.restoration.companion")

local total_tests = 0
local passed_tests = 0

--- Asserts equality between actual and expected values.
local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Diorama Prop Layer Tests ---")

-- 1. Initial Empty Courtyard State
local completed_tasks = {}
local chosen_styles = {}
local pip = companion.new("Pip")

local snapshot = prop_layer_controller.get_diorama_snapshot(completed_tasks, chosen_styles, pip)
assert_eq(snapshot.total_props, 12, "Exactly 12 restorative props in Area 1")
assert_eq(snapshot.restored_count, 0, "Initial restored count is 0")
assert_eq(snapshot.completion_percent, 0, "Initial completion is 0%")
assert_eq(snapshot.companion.state, "idle", "Pip starts in idle state")
assert_eq(snapshot.companion.pos.x, 440, "Pip X coordinate is 440")
assert_eq(snapshot.companion.pos.y, 520, "Pip Y coordinate is 520")

-- Verify prop unrestored states
for _, prop in ipairs(snapshot.props) do
    assert_eq(prop.is_restored, false, prop.prop_id .. " is initially unrestored")
end

-- 2. Restoring Props with Custom Styles
completed_tasks = {
    { task_id = "repair_stone_hearth", chosen_style = 2 },
    { task_id = "light_first_lantern", chosen_style = 3 }
}
chosen_styles = {
    ["repair_stone_hearth"] = 2,
    ["light_first_lantern"] = 3
}

snapshot = prop_layer_controller.get_diorama_snapshot(completed_tasks, chosen_styles, pip)
assert_eq(snapshot.restored_count, 2, "2 props are now restored")
assert_eq(snapshot.completion_percent, 16, "Completion percent is 16% (2/12)")

local hearth_prop = nil
local lantern_prop = nil
for _, prop in ipairs(snapshot.props) do
    if prop.task_id == "repair_stone_hearth" then
        hearth_prop = prop
    elseif prop.task_id == "light_first_lantern" then
        lantern_prop = prop
    end
end

assert_eq(hearth_prop ~= nil, true, "Hearth prop found in snapshot")
assert_eq(hearth_prop.is_restored, true, "Hearth prop is marked restored")
assert_eq(hearth_prop.style_idx, 2, "Hearth uses Style 2 (Mossy Stone)")
assert_eq(hearth_prop.tint.name, "Mossy Stone", "Hearth tinted with Mossy Stone")
assert_eq(hearth_prop.pos.x, 360, "Hearth centered at X=360")
assert_eq(hearth_prop.pos.y, 520, "Hearth Y coordinate is 520")

assert_eq(lantern_prop ~= nil, true, "Lantern prop found in snapshot")
assert_eq(lantern_prop.is_restored, true, "Lantern prop is marked restored")
assert_eq(lantern_prop.style_idx, 3, "Lantern uses Style 3 (Whimsical Crystal)")
assert_eq(lantern_prop.tint.name, "Whimsical Crystal", "Lantern tinted with Whimsical Crystal")

-- 3. Free Re-Styling Check
chosen_styles["repair_stone_hearth"] = 1 -- Switch to Rustic Cedar
snapshot = prop_layer_controller.get_diorama_snapshot(completed_tasks, chosen_styles, pip)
for _, prop in ipairs(snapshot.props) do
    if prop.task_id == "repair_stone_hearth" then
        assert_eq(prop.style_idx, 1, "Hearth style dynamically switched to 1")
        assert_eq(prop.tint.name, "Rustic Cedar", "Hearth tint switched to Rustic Cedar")
    end
end

-- 4. Companion Celebration Emote
companion.trigger_reaction(pip, "celebrate", 3.0)
snapshot = prop_layer_controller.get_diorama_snapshot(completed_tasks, chosen_styles, pip)
assert_eq(snapshot.companion.state, "celebrate", "Pip reflects celebrate reaction in snapshot")

-- 5. Full 100% Restoration
for _, prop_def in ipairs(prop_layer_controller.PROPS) do
    table.insert(completed_tasks, { task_id = prop_def.task_id, chosen_style = 1 })
end
snapshot = prop_layer_controller.get_diorama_snapshot(completed_tasks, chosen_styles, pip)
assert_eq(snapshot.restored_count, 12, "All 12 props are restored")
assert_eq(snapshot.completion_percent, 100, "Courtyard reaches 100% completion")

-- 6. Canonical Task Catalog 1:1 Cross-Validation
local task_catalog = require("game.restoration.task_catalog")
local catalog_tasks = task_catalog.get_tasks_for_area(task_catalog.AREA_1_ID)
assert_eq(#catalog_tasks, 12, "Task catalog contains 12 tasks for Area 1")

local prop_task_ids = {}
for _, p in ipairs(prop_layer_controller.PROPS) do
    prop_task_ids[p.task_id] = true
end

for _, task in ipairs(catalog_tasks) do
    assert_eq(prop_task_ids[task.id], true, "Prop exists for catalog task: " .. task.id)
end

-- 7. Nil Input Resilience
local nil_snapshot = prop_layer_controller.get_diorama_snapshot(nil, nil, nil)
assert_eq(nil_snapshot.total_props, 12, "Nil snapshot maintains total props count")
assert_eq(nil_snapshot.restored_count, 0, "Nil snapshot has 0 restored props")
assert_eq(nil_snapshot.companion.state, "idle", "Nil snapshot companion is idle")

print(string.format("All tests passed! (%d/%d assertions)\n", passed_tests, total_tests))
