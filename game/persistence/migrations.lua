--- Versioned schema migration engine for save file backward compatibility.
-- Applies sequential schema upgrades from older versions to CURRENT_SCHEMA_VERSION.
-- @module migrations

local migrations = {}

migrations.CURRENT_SCHEMA_VERSION = 2

local migration_steps = {
    [1] = function(data)
        -- Baseline v1 format
        data.schema_version = 1
        data.player = data.player or {
            stars = 0,
            coins = 0,
            inventory = {}
        }
        data.progression = data.progression or {
            max_unlocked_level = 1,
            completed_levels = {}
        }
        data.village = data.village or {
            current_area = "hearthstone_courtyard",
            completed_tasks = {},
            chosen_styles = {}
        }
        return data
    end,
    [2] = function(data)
        -- Upgrade to v2: Add structured booster inventory and transaction history
        data.player.inventory = data.player.inventory or {}
        data.player.inventory.hammer = data.player.inventory.hammer or 0
        data.player.inventory.rocket = data.player.inventory.rocket or 0
        data.player.inventory.bomb = data.player.inventory.bomb or 0
        data.ledger_history = data.ledger_history or {}
        data.schema_version = 2
        return data
    end
}

--- Sequentially upgrades save data tables to match CURRENT_SCHEMA_VERSION.
-- @param save_data table The loaded raw save table.
-- @return table migrated_data Upgraded save table ready for runtime consumption.
-- @return boolean was_migrated True if at least one schema migration step was applied.
function migrations.migrate(save_data)
    assert(type(save_data) == "table", "Save data to migrate must be a table")

    local current_version = save_data.schema_version or 0
    local was_migrated = false

    for target_version = current_version + 1, migrations.CURRENT_SCHEMA_VERSION do
        local step_fn = migration_steps[target_version]
        if step_fn then
            save_data = step_fn(save_data)
            was_migrated = true
        end
    end

    save_data.schema_version = migrations.CURRENT_SCHEMA_VERSION
    return save_data, was_migrated
end

return migrations
