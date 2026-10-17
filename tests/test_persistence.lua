--- Unit tests for atomic persistence, corruption recovery, migrations, and cloud sync.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_persistence.lua`

package.path = package.path .. ";./?.lua"

local save_manager = require("game.persistence.save_manager")
local migrations = require("game.persistence.migrations")
local cloud_sync = require("game.persistence.cloud_sync")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Persistence, Recovery & Migration Tests ---")

local test_dir = "tests/fixtures_save"
os.execute("mkdir " .. test_dir:gsub("/", "\\"))

-- Clean up any residual test files
local p_save, p_tmp, p_bak = save_manager.get_save_paths(test_dir)
os.remove(p_save)
os.remove(p_tmp)
os.remove(p_bak)

-- Test 1: Atomic write and primary load
local initial = save_manager.create_default_state()
initial.player.coins = 500
initial.progression.max_unlocked_level = 5

local ok_save, err_save = save_manager.save(initial, test_dir)
assert_eq(ok_save, true, "Atomic save succeeded: " .. tostring(err_save))

local loaded, src = save_manager.load(test_dir)
assert_eq(src, "primary", "Loaded from primary save")
assert_eq(loaded.player.coins, 500, "Coins persisted accurately")
assert_eq(loaded.progression.max_unlocked_level, 5, "Progression level persisted")

-- Test 2: Backup creation on second save
initial.player.coins = 750
save_manager.save(initial, test_dir)

local bak_f = io.open(p_bak, "r")
assert_eq(bak_f ~= nil, true, "Backup file save.json.bak created")
if bak_f then bak_f:close() end

-- Test 3: Corruption Recovery Hierarchy (Primary corrupted -> Recovery from .bak)
-- Intentionally corrupt save.json with truncated garbage
local f_corrupt = io.open(p_save, "w")
f_corrupt:write("{ broken_json_truncated... ")
f_corrupt:close()

local recovered, rec_src = save_manager.load(test_dir)
assert_eq(rec_src, "backup", "Gracefully recovered from backup upon primary corruption")
assert_eq(recovered.player.coins, 500, "Backup data state accurately recovered")

-- Test 4: Both Primary and Backup corrupted -> Fallback to clean defaults (Never crash)
local f_corrupt1 = io.open(p_save, "w")
f_corrupt1:write("{ corrupted_primary_file... ")
f_corrupt1:close()

local f_corrupt2 = io.open(p_bak, "w")
f_corrupt2:write("{ corrupted_backup_file... ")
f_corrupt2:close()

local def_rec, def_src = save_manager.load(test_dir)
assert_eq(def_src, "defaults", "Fell back to defaults when both files corrupted")
assert_eq(def_rec.schema_version, migrations.CURRENT_SCHEMA_VERSION, "Default schema version matches")
assert_eq(def_rec.progression.max_unlocked_level, 1, "Default start level is 1")

-- Test 5: Versioned Schema Migration (v1 -> v2)
local v1_save = {
    schema_version = 1,
    player = { stars = 3, coins = 100, inventory = {} },
    progression = { max_unlocked_level = 4, completed_levels = { ["1"] = 3 } },
    village = { current_area = "hearthstone_courtyard", completed_tasks = {}, chosen_styles = {} }
}
local migrated, was_migrated = migrations.migrate(v1_save)
assert_eq(was_migrated, true, "Migration flag returned true")
assert_eq(migrated.schema_version, 2, "Schema version upgraded to 2")
assert_eq(migrated.player.inventory.hammer, 0, "Booster inventory initialized in v2")
assert_eq(migrated.player.inventory.rocket, 0, "Rocket inventory initialized in v2")
assert_eq(type(migrated.ledger_history), "table", "Ledger history initialized in v2")

-- Test 6: Cloud Save Reconciliation Matrix
local local_state = {
    schema_version = 2,
    player = { stars = 5, coins = 200, inventory = { hammer = 1, rocket = 0, bomb = 0 } },
    progression = { max_unlocked_level = 7, completed_levels = { ["1"] = 3, ["2"] = 2 } },
    village = {
        current_area = "hearthstone_courtyard",
        completed_tasks = { { task_id = "task_1", chosen_style = 1 } },
        chosen_styles = { task_1 = 1 }
    },
    ledger_history = { ["op_local_1"] = { delta = 1 } }
}

local cloud_state = {
    schema_version = 2,
    player = { stars = 3, coins = 350, inventory = { hammer = 2, rocket = 1, bomb = 0 } },
    progression = { max_unlocked_level = 9, completed_levels = { ["1"] = 3, ["2"] = 3, ["3"] = 2 } },
    village = {
        current_area = "hearthstone_courtyard",
        completed_tasks = { { task_id = "task_2", chosen_style = 2 } },
        chosen_styles = { task_2 = 2 }
    },
    ledger_history = { ["op_cloud_1"] = { delta = 2 } }
}

local resolved, had_conflicts = cloud_sync.reconcile(local_state, cloud_state)
assert_eq(had_conflicts, true, "Conflicts detected and reconciled")
assert_eq(resolved.progression.max_unlocked_level, 9, "Max unlocked level uses MAX(7, 9) = 9")
assert_eq(resolved.progression.completed_levels["2"], 3, "Level 2 star rating uses MAX(2, 3) = 3")
assert_eq(#resolved.village.completed_tasks, 2, "Village completed tasks uses set union (both task_1 and task_2)")
assert_eq(resolved.player.coins, 350, "Coins preserved via MAX(200, 350) = 350")
assert_eq(resolved.player.inventory.hammer, 2, "Hammers preserved via MAX(1, 2) = 2")
assert_eq(resolved.ledger_history["op_local_1"] ~= nil, true, "Local transaction preserved in ledger union")
assert_eq(resolved.ledger_history["op_cloud_1"] ~= nil, true, "Cloud transaction preserved in ledger union")

-- Cleanup fixture directory
os.remove(p_save)
os.remove(p_tmp)
os.remove(p_bak)
os.execute("rmdir " .. test_dir:gsub("/", "\\"))

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
