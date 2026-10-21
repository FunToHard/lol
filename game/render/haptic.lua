--- Decoupled haptic feedback controller for mobile tactile responses.
-- Safely invokes native vibration APIs when available or records events for headless verification.
-- @module haptic
local haptic = {}

--- Creates a new haptic controller state table.
-- @param enabled boolean|nil Whether haptic feedback is initially enabled (defaults to true).
-- @return table state Initialized haptic state instance.
function haptic.new(enabled)
    return {
        enabled = (enabled ~= false),
        last_event = nil,
        history = {}
    }
end

--- Enables or disables haptic vibrations.
-- @param state table The haptic state table.
-- @param enabled boolean Desired haptic activation flag.
function haptic.set_enabled(state, enabled)
    state.enabled = enabled
end

--- Dispatches a light haptic tick for tile swaps and UI selections.
-- @param state table The haptic state table.
-- @return boolean triggered True if haptic feedback was dispatched.
function haptic.tick(state)
    if not state.enabled then return false end
    state.last_event = "tick"
    state.history[#state.history + 1] = "tick"
    -- In Defold environment with vibrate extension:
    if pcall and vibrate and vibrate.trigger then
        pcall(vibrate.trigger, 15)
    end
    return true
end

--- Dispatches a medium haptic pulse for standard match-3 clears.
-- @param state table The haptic state table.
-- @return boolean triggered True if haptic feedback was dispatched.
function haptic.impact(state)
    if not state.enabled then return false end
    state.last_event = "impact"
    state.history[#state.history + 1] = "impact"
    if pcall and vibrate and vibrate.trigger then
        pcall(vibrate.trigger, 35)
    end
    return true
end

--- Dispatches a strong haptic burst for bombs, lanterns, and combo detonations.
-- @param state table The haptic state table.
-- @return boolean triggered True if haptic feedback was dispatched.
function haptic.heavy(state)
    if not state.enabled then return false end
    state.last_event = "heavy"
    state.history[#state.history + 1] = "heavy"
    if pcall and vibrate and vibrate.trigger then
        pcall(vibrate.trigger, 70)
    end
    return true
end

return haptic
