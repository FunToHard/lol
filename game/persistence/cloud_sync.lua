--- Cloud save reconciliation and conflict resolution matrix.
-- Merges offline progress with cloud snapshots without data loss or progress reversion.
-- @module cloud_sync

local cloud_sync = {}

--- Reconciles local and cloud save data tables into a single resolved state.
-- Applies deterministic conflict resolution rules:
-- - Max Unlocked Level: MAX(local, cloud)
-- - Completed Levels: MAX score per level
-- - Village Restoration: Set union of completed tasks (never reverts restoration)
-- - Consumables & Ledger: Idempotent union of operation history and highest valid balance
-- @param local_data table Active local save state.
-- @param cloud_data table Inbound cloud save state snapshot.
-- @return table resolved_state Merged save data table.
-- @return boolean had_conflicts True if reconciliation merged differing data points.
function cloud_sync.reconcile(local_data, cloud_data)
    if not cloud_data then return local_data, false end
    if not local_data then return cloud_data, false end

    local had_conflicts = false
    local resolved = {}

    -- Schema version is maximum of the two
    resolved.schema_version = math.max(local_data.schema_version or 1, cloud_data.schema_version or 1)
    resolved.last_updated = os.time and os.time() or 0

    -- 1. Progression: Max level is always preserved
    local loc_prog = local_data.progression or {}
    local cld_prog = cloud_data.progression or {}
    local max_lvl_loc = loc_prog.max_unlocked_level or 1
    local max_lvl_cld = cld_prog.max_unlocked_level or 1

    if max_lvl_loc ~= max_lvl_cld then had_conflicts = true end
    local final_max_lvl = math.max(max_lvl_loc, max_lvl_cld)

    -- Union of completed levels and star ratings
    local final_completed = {}
    local loc_comp = loc_prog.completed_levels or {}
    local cld_comp = cld_prog.completed_levels or {}

    for lvl_str, stars in pairs(loc_comp) do
        final_completed[lvl_str] = stars
    end
    for lvl_str, stars in pairs(cld_comp) do
        if not final_completed[lvl_str] or stars > final_completed[lvl_str] then
            final_completed[lvl_str] = stars
            had_conflicts = true
        end
    end

    resolved.progression = {
        max_unlocked_level = final_max_lvl,
        completed_levels = final_completed
    }

    -- 2. Village Restoration: Set union of completed tasks
    local loc_vil = local_data.village or {}
    local cld_vil = cloud_data.village or {}
    local final_tasks = {}
    local task_seen = {}

    local loc_tasks = loc_vil.completed_tasks or {}
    for _, t in ipairs(loc_tasks) do
        task_seen[t.task_id] = true
        final_tasks[#final_tasks + 1] = t
    end

    local cld_tasks = cld_vil.completed_tasks or {}
    for _, t in ipairs(cld_tasks) do
        if not task_seen[t.task_id] then
            task_seen[t.task_id] = true
            final_tasks[#final_tasks + 1] = t
            had_conflicts = true
        end
    end

    -- Preserve chosen styles (local takes priority, or merge cloud)
    local final_styles = {}
    local cld_styles = cld_vil.chosen_styles or {}
    for k, v in pairs(cld_styles) do final_styles[k] = v end
    local loc_styles = loc_vil.chosen_styles or {}
    for k, v in pairs(loc_styles) do final_styles[k] = v end

    resolved.village = {
        current_area = loc_vil.current_area or cld_vil.current_area or "hearthstone_courtyard",
        completed_tasks = final_tasks,
        chosen_styles = final_styles
    }

    -- 3. Economy & Ledger: Union of transaction histories
    local loc_hist = local_data.ledger_history or {}
    local cld_hist = cloud_data.ledger_history or {}
    local final_hist = {}

    for op_id, record in pairs(cld_hist) do
        final_hist[op_id] = record
    end
    for op_id, record in pairs(loc_hist) do
        if not final_hist[op_id] then
            final_hist[op_id] = record
            had_conflicts = true
        end
    end
    resolved.ledger_history = final_hist

    -- Player balances: Max safe balance or latest state
    local loc_p = local_data.player or {}
    local cld_p = cloud_data.player or {}
    resolved.player = {
        stars = math.max(loc_p.stars or 0, cld_p.stars or 0),
        coins = math.max(loc_p.coins or 0, cld_p.coins or 0),
        inventory = {
            hammer = math.max((loc_p.inventory and loc_p.inventory.hammer) or 0, (cld_p.inventory and cld_p.inventory.hammer) or 0),
            rocket = math.max((loc_p.inventory and loc_p.inventory.rocket) or 0, (cld_p.inventory and cld_p.inventory.rocket) or 0),
            bomb = math.max((loc_p.inventory and loc_p.inventory.bomb) or 0, (cld_p.inventory and cld_p.inventory.bomb) or 0)
        }
    }

    return resolved, had_conflicts
end

return cloud_sync
