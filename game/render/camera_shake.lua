--- Camera shake and haptic feedback module.
-- Generates decaying impulse offsets for screen-shake juice during bomb blasts and combos.
local camera_shake = {}

camera_shake.INTENSITY_LIGHT = 1.5   -- Rocket line blast
camera_shake.INTENSITY_MEDIUM = 3.5  -- Bomb explosion
camera_shake.INTENSITY_HEAVY = 6.5   -- Mega combo / Lantern fusion

--- Creates a new camera shake state instance.
-- @return table state The initialized shake state table.
function camera_shake.new()
    return {
        intensity = 0,
        duration = 0,
        elapsed = 0,
        offset_x = 0,
        offset_y = 0
    }
end

--- Triggers an impulse camera shake.
-- If a shake is already active, blends the stronger intensity.
-- @param state table Camera shake state table.
-- @param intensity number Peak pixel displacement.
-- @param duration number Total duration in seconds.
function camera_shake.trigger(state, intensity, duration)
    state.intensity = math.max(state.intensity, intensity or camera_shake.INTENSITY_MEDIUM)
    state.duration = math.max(state.duration, duration or 0.18)
    state.elapsed = 0
end

--- Advances the shake simulation by delta time and computes the current frame offset.
-- Uses damped harmonic oscillation with decaying amplitude.
-- @param state table Camera shake state table.
-- @param dt number Delta time in seconds.
-- @return number offset_x Current horizontal pixel displacement.
-- @return number offset_y Current vertical pixel displacement.
function camera_shake.update(state, dt)
    state.elapsed = state.elapsed + dt
    if state.elapsed >= state.duration or state.duration <= 0 then
        state.offset_x = 0
        state.offset_y = 0
        state.intensity = 0
        return 0, 0
    end

    local progress = state.elapsed / state.duration
    local decay = 1.0 - progress

    -- High frequency oscillation
    local angle = state.elapsed * 45.0
    local current_amp = state.intensity * decay

    state.offset_x = math.sin(angle) * current_amp
    state.offset_y = math.cos(angle * 1.3) * current_amp

    return state.offset_x, state.offset_y
end

return camera_shake
