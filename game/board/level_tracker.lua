--- Pure Lua goal tracker and win/loss state evaluator for levels.
-- Monitors move limits, color collections, obstacle destructions, and ingredient drops.
-- @module level_tracker

local level_tracker = {}

--- Creates a new level tracker state instance from a level definition table.
-- @param level_def table The parsed level configuration table.
-- @return table state Initialized tracker state table.
function level_tracker.new(level_def)
    local goals = {}
    if level_def.goals then
        for i, g in ipairs(level_def.goals) do
            goals[i] = {
                type = g.type,
                target = g.target,
                target_count = g.count or 0,
                current_count = 0,
                completed = false
            }
        end
    end

    return {
        level_id = level_def.level_id or 1,
        moves_remaining = level_def.moves or 25,
        total_moves = level_def.moves or 25,
        goals = goals,
        status = "IN_PROGRESS"
    }
end

--- Decrements the remaining move counter by one and updates win/loss status.
-- @param state table Active tracker state table.
-- @return number moves_remaining Remaining move allowance.
function level_tracker.record_move(state)
    if state.status ~= "IN_PROGRESS" then return state.moves_remaining end
    state.moves_remaining = math.max(0, state.moves_remaining - 1)
    level_tracker.get_status(state)
    return state.moves_remaining
end

--- Records collected pieces from cleared matches toward collection goals.
-- @param state table Active tracker state table.
-- @param cleared_tiles table Array of cleared tile color strings (e.g. {"amber", "amber", "amber"}).
function level_tracker.record_matches(state, cleared_tiles)
    if not cleared_tiles then return end
    for _, tile_color in ipairs(cleared_tiles) do
        for _, g in ipairs(state.goals) do
            if g.type == "collect_color" and g.target == tile_color then
                g.current_count = math.min(g.target_count, g.current_count + 1)
                if g.current_count >= g.target_count then
                    g.completed = true
                end
            end
        end
    end
    level_tracker.get_status(state)
end

--- Records destroyed obstacles toward obstacle clearance goals.
-- @param state table Active tracker state table.
-- @param obs_type string Obstacle identifier (e.g. "bramble" or "stone").
-- @param count number|nil Number of destroyed obstacles (defaults to 1).
function level_tracker.record_obstacle_destroyed(state, obs_type, count)
    local n = count or 1
    for _, g in ipairs(state.goals) do
        if g.type == "clear_obstacle" and (g.target == obs_type or g.target == "any") then
            g.current_count = math.min(g.target_count, g.current_count + n)
            if g.current_count >= g.target_count then
                g.completed = true
            end
        end
    end
    level_tracker.get_status(state)
end

--- Records ingredients that fell to the bottom row and were collected.
-- @param state table Active tracker state table.
-- @param count number|nil Number of collected ingredients (defaults to 1).
function level_tracker.record_ingredient_collected(state, count)
    local n = count or 1
    for _, g in ipairs(state.goals) do
        if g.type == "drop_ingredient" then
            g.current_count = math.min(g.target_count, g.current_count + n)
            if g.current_count >= g.target_count then
                g.completed = true
            end
        end
    end
    level_tracker.get_status(state)
end

--- Checks if all goals for the level have been fully satisfied.
-- @param state table Active tracker state table.
-- @return boolean is_won True if all goals are completed.
function level_tracker.is_won(state)
    for _, g in ipairs(state.goals) do
        if not g.completed then
            return false
        end
    end
    return true
end

--- Checks if the level has been failed (out of moves with remaining incomplete goals).
-- @param state table Active tracker state table.
-- @return boolean is_lost True if moves depleted and goals remain incomplete.
function level_tracker.is_lost(state)
    if level_tracker.is_won(state) then return false end
    return state.moves_remaining <= 0
end

--- Evaluates and returns the current level lifecycle status.
-- @param state table Active tracker state table.
-- @return string status "IN_PROGRESS", "WON", or "LOST".
function level_tracker.get_status(state)
    if level_tracker.is_won(state) then
        state.status = "WON"
    elseif state.moves_remaining <= 0 then
        state.status = "LOST"
    else
        state.status = "IN_PROGRESS"
    end
    return state.status
end

--- Returns a formatted summary of goals for HUD and debugging.
-- @param state table Active tracker state table.
-- @return table summary List of goal progress tables { type, target, current, target_count, completed }.
function level_tracker.get_goals_summary(state)
    local summary = {}
    for i, g in ipairs(state.goals) do
        summary[i] = {
            type = g.type,
            target = g.target,
            current = g.current_count,
            target_count = g.target_count,
            completed = g.completed
        }
    end
    return summary
end

return level_tracker
