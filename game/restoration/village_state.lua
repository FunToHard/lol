--- Village state manager tracking renovation progress, task unlocks, and free re-styling.
-- Connects task completions directly with the star currency ledger.
-- @module village_state

local task_catalog = require("game.restoration.task_catalog")
local ledger = require("game.economy.ledger")

local village_state = {}

--- Creates a new village state instance backed by persistent data and an economy ledger.
-- @param saved_data table|nil Saved village block from the player save file.
-- @param econ_ledger table|nil Economy ledger state table.
-- @return table state Initialized village state table.
function village_state.new(saved_data, econ_ledger)
    local s = saved_data or {}
    local completed = {}
    local styles = {}

    if s.completed_tasks then
        for _, t in ipairs(s.completed_tasks) do
            completed[#completed + 1] = t
            if t.task_id and t.chosen_style then
                styles[t.task_id] = t.chosen_style
            end
        end
    end
    if s.chosen_styles then
        for k, v in pairs(s.chosen_styles) do
            styles[k] = v
        end
    end

    return {
        current_area = s.current_area or task_catalog.AREA_1_ID,
        completed_tasks = completed,
        chosen_styles = styles,
        ledger = econ_ledger or ledger.new()
    }
end

--- Checks if a specific task has already been completed.
-- @param state table Active village state table.
-- @param task_id string Unique task identifier.
-- @return boolean is_completed True if the task has been performed.
function village_state.is_task_completed(state, task_id)
    for _, t in ipairs(state.completed_tasks) do
        if t.task_id == task_id then
            return true
        end
    end
    return false
end

--- Returns the currently active (next available) task in the area sequence.
-- @param state table Active village state table.
-- @return table|nil active_task Next task to complete or nil if all area tasks are finished.
function village_state.get_active_task(state)
    local tasks = task_catalog.get_tasks_for_area(state.current_area)
    for _, t in ipairs(tasks) do
        if not village_state.is_task_completed(state, t.id) then
            return t
        end
    end
    return nil
end

--- Checks whether the player can currently afford and complete the specified task.
-- @param state table Active village state table.
-- @param task_id string Unique task identifier.
-- @return boolean can_complete True if the task is available and player has enough Stars.
function village_state.can_complete_task(state, task_id)
    local active = village_state.get_active_task(state)
    if not active or active.id ~= task_id then
        return false
    end
    return ledger.can_afford(state.ledger, "stars", active.cost)
end

--- Completes an active village task, deducts Stars via ledger, and saves chosen style.
-- @param state table Active village state table.
-- @param task_id string Unique task identifier.
-- @param chosen_style_idx number Selected aesthetic theme index (1, 2, or 3).
-- @param op_id string Unique transaction operation identifier for double-spend protection.
-- @return boolean success True if task was completed or already performed.
-- @return string|nil error_code "TASK_NOT_ACTIVE", "INSUFFICIENT_STARS", or "ALREADY_COMPLETED".
function village_state.complete_task(state, task_id, chosen_style_idx, op_id)
    if village_state.is_task_completed(state, task_id) then
        return true, "ALREADY_COMPLETED"
    end

    local active = village_state.get_active_task(state)
    if not active or active.id ~= task_id then
        return false, "TASK_NOT_ACTIVE"
    end

    local style_idx = math.max(1, math.min(3, chosen_style_idx or 1))

    -- Deduct Stars atomically via ledger
    local ok, _, err = ledger.apply_transaction(state.ledger, op_id, "stars", -active.cost, "village_task:" .. task_id)
    if not ok then
        return false, "INSUFFICIENT_STARS"
    end
    if err == "ALREADY_PROCESSED" then
        return false, "INVALID_TRANSACTION_ID"
    end

    table.insert(state.completed_tasks, {
        task_id = task_id,
        chosen_style = style_idx,
        timestamp = os.time and os.time() or 0
    })
    state.chosen_styles[task_id] = style_idx

    return true, nil
end

--- Switches the visual aesthetic theme of an already restored prop at zero currency cost.
-- @param state table Active village state table.
-- @param task_id string Unique task identifier of the previously restored prop.
-- @param new_style_idx number Desired style index (1, 2, or 3).
-- @return boolean success True if the prop was restyled.
function village_state.restyle_prop(state, task_id, new_style_idx)
    if not village_state.is_task_completed(state, task_id) then
        return false
    end
    local style_idx = math.max(1, math.min(3, new_style_idx or 1))
    state.chosen_styles[task_id] = style_idx

    for _, t in ipairs(state.completed_tasks) do
        if t.task_id == task_id then
            t.chosen_style = style_idx
            break
        end
    end
    return true
end

--- Returns completion statistics for the active village area.
-- @param state table Active village state table.
-- @return table stats Summary table { completed_count, total_count, percent_complete }.
function village_state.get_completion_stats(state)
    local tasks = task_catalog.get_tasks_for_area(state.current_area)
    local total = #tasks
    local count = 0
    for _, t in ipairs(tasks) do
        if village_state.is_task_completed(state, t.id) then
            count = count + 1
        end
    end
    local pct = (total > 0) and math.floor((count / total) * 100) or 0
    return {
        completed_count = count,
        total_count = total,
        percent_complete = pct
    }
end

return village_state
