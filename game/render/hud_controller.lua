--- Pure Lua view-model controller for the In-Game HUD Overlay.
-- Manages score accumulation, move capsule countdowns, goal progress, and pause states.
-- @module hud_controller

local hud_controller = {}

-- Standard sprite mapping from goal targets to atlas textures
local TARGET_SPRITE_MAP = {
    amber = "piece_amber",
    amethyst = "piece_amethyst",
    emerald = "piece_emerald",
    ruby = "piece_ruby",
    sapphire = "piece_sapphire",
    bramble = "obstacle_bramble_1",
    stone = "obstacle_stone_1",
    acorn = "ingredient_acorn"
}

--- Formats a numeric score with thousands separator commas.
-- @param value number Numeric value to format.
-- @return string formatted Formatted string (e.g. "12,500").
function hud_controller.format_number(value)
    local n = math.floor(value or 0)
    local s = tostring(n)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if formatted:sub(1, 1) == "," then
        formatted = formatted:sub(2)
    end
    return formatted
end

--- Resolves atlas sprite identifier for a goal definition.
-- @param goal_type string Goal classification ('collect_color', 'clear_obstacle', 'drop_ingredient').
-- @param target string Target identifier ('ruby', 'stone', 'acorn', etc.).
-- @return string sprite_name Atlas sprite image name.
function hud_controller.get_goal_sprite(goal_type, target)
    if goal_type == "drop_ingredient" then
        return TARGET_SPRITE_MAP[target] or "ingredient_acorn"
    elseif goal_type == "clear_obstacle" then
        return TARGET_SPRITE_MAP[target] or "obstacle_stone_1"
    else
        return TARGET_SPRITE_MAP[target] or "piece_amber"
    end
end

--- Creates a new HUD controller state instance.
-- @param level_def table|nil Optional level configuration table.
-- @return table state Initialized HUD controller state table.
function hud_controller.new(level_def)
    local def = level_def or {}
    local goals = {}

    if def.goals then
        for i, g in ipairs(def.goals) do
            goals[i] = {
                type = g.type,
                target = g.target,
                target_count = g.count or 0,
                current_count = 0,
                completed = false,
                sprite_name = hud_controller.get_goal_sprite(g.type, g.target)
            }
        end
    end

    return {
        level_id = def.level_id or 1,
        moves_remaining = def.moves or 25,
        total_moves = def.moves or 25,
        score = 0,
        displayed_score = 0,
        goals = goals,
        is_paused = false,
        event_log = {}
    }
end

--- Updates the remaining move count.
-- @param state table HUD controller state instance.
-- @param moves number Current remaining moves.
function hud_controller.set_moves(state, moves)
    state.moves_remaining = math.max(0, moves or 0)
    table.insert(state.event_log, { event = "moves_changed", moves = state.moves_remaining })
end

--- Adds points to the score total.
-- @param state table HUD controller state instance.
-- @param points number Points to add.
-- @return number new_score Updated total score.
function hud_controller.add_score(state, points)
    local pts = math.max(0, points or 0)
    state.score = state.score + pts
    table.insert(state.event_log, { event = "score_added", points = pts, total = state.score })
    return state.score
end

--- Updates goal progress counters based on level tracker state.
-- @param state table HUD controller state instance.
-- @param tracker_goals table Array of goal state tables from level_tracker.
function hud_controller.update_goals(state, tracker_goals)
    if not tracker_goals then return end
    for i, tg in ipairs(tracker_goals) do
        if state.goals[i] then
            state.goals[i].current_count = tg.current_count or 0
            state.goals[i].completed = tg.completed == true
        else
            state.goals[i] = {
                type = tg.type,
                target = tg.target,
                target_count = tg.target_count or 0,
                current_count = tg.current_count or 0,
                completed = tg.completed == true,
                sprite_name = hud_controller.get_goal_sprite(tg.type, tg.target)
            }
        end
    end
end

--- Toggles or sets the pause modal visibility state.
-- @param state table HUD controller state instance.
-- @param is_paused boolean|nil Optional explicit paused state (toggles if nil).
-- @return boolean is_paused Updated pause status.
function hud_controller.toggle_pause(state, is_paused)
    if is_paused ~= nil then
        state.is_paused = is_paused == true
    else
        state.is_paused = not state.is_paused
    end
    table.insert(state.event_log, { event = "pause_toggled", is_paused = state.is_paused })
    return state.is_paused
end

--- Extracts a presentation-ready snapshot for GUI view binding.
-- @param state table HUD controller state instance.
-- @return table view Formatted view table for Defold GUI nodes.
function hud_controller.get_view_data(state)
    local goals_view = {}
    for i, g in ipairs(state.goals) do
        local remaining = math.max(0, g.target_count - g.current_count)
        goals_view[i] = {
            id = i,
            sprite_name = g.sprite_name,
            target = g.target,
            target_count = g.target_count,
            current_count = g.current_count,
            remaining = remaining,
            count_text = g.completed and "V" or tostring(remaining),
            is_completed = g.completed
        }
    end

    return {
        level_id = state.level_id,
        moves = state.moves_remaining,
        moves_text = tostring(state.moves_remaining),
        score = state.score,
        score_text = hud_controller.format_number(state.score),
        is_paused = state.is_paused,
        goals = goals_view
    }
end

return hud_controller
