--- Pure Lua scene and transition state machine controller.
-- Manages scene navigation between Map, Puzzle, and Village with history tracking and fade lifecycles.
-- @module scene_switcher

local scene_switcher = {}

-- Valid scene identifiers
scene_switcher.SCENES = {
    MAP = "map",
    PUZZLE = "puzzle",
    VILLAGE = "village"
}

-- Transition lifecycle states
scene_switcher.PHASES = {
    IDLE = "IDLE",
    FADING_OUT = "FADING_OUT",
    LOADING = "LOADING",
    FADING_IN = "FADING_IN"
}

-- Allowed scene transitions map
local ALLOWED_TRANSITIONS = {
    map = { puzzle = true, village = true },
    puzzle = { map = true, village = true, puzzle = true },
    village = { map = true, puzzle = true }
}

--- Checks whether a scene transition between two scene keys is permitted.
-- @param from_scene string Current scene key.
-- @param to_scene string Target scene key.
-- @return boolean allowed True if transition is valid.
function scene_switcher.is_valid_transition(from_scene, to_scene)
    if not from_scene or not to_scene then return false end
    if not ALLOWED_TRANSITIONS[from_scene] then return false end
    return ALLOWED_TRANSITIONS[from_scene][to_scene] == true
end

--- Creates a new scene switcher state instance.
-- @param initial_scene string|nil Starting scene key (default "map").
-- @param initial_params table|nil Optional startup parameters.
-- @return table state Initialized scene switcher state table.
function scene_switcher.new(initial_scene, initial_params)
    local start = initial_scene or scene_switcher.SCENES.MAP
    return {
        current_scene = start,
        previous_scene = nil,
        target_scene = nil,
        params = initial_params or {},
        phase = scene_switcher.PHASES.IDLE,
        history = {},
        fade_duration = 0.25,
        event_log = {}
    }
end

--- Initiates a scene transition to the target scene.
-- @param state table Scene switcher state instance.
-- @param target_scene string Target scene identifier.
-- @param params table|nil Optional scene parameter table (e.g. { level_id = 5 }).
-- @param is_back boolean|nil Optional flag indicating if this switch is a back navigation.
-- @return boolean success True if transition request was accepted.
-- @return string|nil error_code "ALREADY_TRANSITIONING" or "INVALID_TRANSITION".
function scene_switcher.request_switch(state, target_scene, params, is_back)
    if state.phase ~= scene_switcher.PHASES.IDLE then
        return false, "ALREADY_TRANSITIONING"
    end
    if not scene_switcher.is_valid_transition(state.current_scene, target_scene) then
        return false, "INVALID_TRANSITION"
    end

    state.target_scene = target_scene
    state.params = params or {}
    state.phase = scene_switcher.PHASES.FADING_OUT
    state.is_back = is_back == true

    table.insert(state.event_log, {
        event = "switch_started",
        from = state.current_scene,
        to = target_scene,
        params = state.params,
        is_back = state.is_back
    })
    return true, nil
end

--- Advances state when the fade-out screen covering animation completes.
-- @param state table Scene switcher state instance.
-- @return boolean success True if state advanced to LOADING.
function scene_switcher.on_fade_out_complete(state)
    if state.phase ~= scene_switcher.PHASES.FADING_OUT then return false end
    state.phase = scene_switcher.PHASES.LOADING
    table.insert(state.event_log, { event = "fade_out_completed", target = state.target_scene })
    return true
end

--- Advances state when the collection proxy finishes loading and enabling the target scene.
-- @param state table Scene switcher state instance.
-- @return boolean success True if state advanced to FADING_IN.
function scene_switcher.on_scene_loaded(state)
    if state.phase ~= scene_switcher.PHASES.LOADING then return false end
    state.phase = scene_switcher.PHASES.FADING_IN
    table.insert(state.event_log, { event = "scene_loaded", scene = state.target_scene })
    return true
end

--- Completes the transition lifecycle once the fade-in animation completes.
-- @param state table Scene switcher state instance.
-- @return string current_scene The newly active scene identifier.
function scene_switcher.on_fade_in_complete(state)
    if state.phase ~= scene_switcher.PHASES.FADING_IN then
        return state.current_scene
    end

    -- Update history stack only on forward navigation
    if not state.is_back then
        table.insert(state.history, state.current_scene)
    end
    state.is_back = false
    state.previous_scene = state.current_scene
    state.current_scene = state.target_scene
    state.target_scene = nil
    state.phase = scene_switcher.PHASES.IDLE

    table.insert(state.event_log, { event = "transition_completed", current = state.current_scene })
    return state.current_scene
end

--- Requests a transition back to the most recent previous scene on the history stack.
-- @param state table Scene switcher state instance.
-- @return boolean success True if back navigation was initiated.
function scene_switcher.go_back(state)
    if #state.history == 0 then
        -- Default back target is map
        if state.current_scene ~= scene_switcher.SCENES.MAP then
            return scene_switcher.request_switch(state, scene_switcher.SCENES.MAP, nil, true)
        end
        return false
    end
    local prev = table.remove(state.history)
    return scene_switcher.request_switch(state, prev, nil, true)
end

--- Returns a snapshot of the active switcher state.
-- @param state table Scene switcher state instance.
-- @return table snapshot State snapshot { current_scene, phase, is_transitioning, target_scene }.
function scene_switcher.get_state(state)
    return {
        current_scene = state.current_scene,
        previous_scene = state.previous_scene,
        target_scene = state.target_scene,
        phase = state.phase,
        is_transitioning = state.phase ~= scene_switcher.PHASES.IDLE,
        params = state.params
    }
end

return scene_switcher
