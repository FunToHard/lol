--- Adaptive audio manager for pentatonic cascade pitching and tactile SFX.
-- Pure Lua controller that calculates pitch offsets and dispatches audio events.
local audio_manager = {}

-- Pentatonic scale pitch semitone table: Root(0), 2nd(+2), 3rd(+4), 5th(+7), 6th(+9), Octave(+12)
local PENTATONIC_SCALE = {0, 2, 4, 7, 9, 12}

--- Creates a new audio manager state table.
-- @param is_muted boolean Optional mute flag (default false).
-- @param has_sound_components boolean|nil Optional flag indicating whether sound components exist (default false).
-- @return table state The initialized audio state table.
function audio_manager.new(is_muted, has_sound_components)
    return {
        is_muted = is_muted == true,
        has_sound_components = has_sound_components == true,
        last_played = nil,
        last_pitch = 1.0,
        event_log = {}
    }
end

--- Enables or disables dispatching to Defold sound components.
-- @param state table Audio manager state instance.
-- @param enabled boolean True to enable engine sound component dispatch, false to disable.
function audio_manager.set_sound_components_enabled(state, enabled)
    state.has_sound_components = enabled == true
end

--- Computes the playback pitch multiplier for a cascade wave along the pentatonic scale.
-- @param wave_number number Current cascade index (1-indexed).
-- @return number pitch Frequency multiplier (1.0 = normal, 2.0 = octave up).
function audio_manager.get_cascade_pitch(wave_number)
    local idx = math.min(#PENTATONIC_SCALE, math.max(1, wave_number or 1))
    local semitones = PENTATONIC_SCALE[idx]
    -- Frequency ratio formula: 2^(semitones / 12)
    return math.pow(2, semitones / 12)
end

--- Dispatches a sound event with specified pitch.
-- In Defold runtime, dispatches to `sound.play()` if sound components are enabled; in headless/test mode, logs event.
-- @param state table Audio manager state instance.
-- @param sound_name string Sound token ('match', 'swap', 'rocket', 'bomb', 'victory').
-- @param pitch number|nil Pitch multiplier (default 1.0).
-- @return table event Dispatched sound record {sound, pitch, muted}.
function audio_manager.play(state, sound_name, pitch)
    local p = pitch or 1.0
    local event = {
        sound = sound_name,
        pitch = p,
        is_muted = state.is_muted
    }

    state.last_played = sound_name
    state.last_pitch = p
    table.insert(state.event_log, event)

    -- In active Defold engine runtime, invoke sound message only if sound components are explicitly enabled
    if not state.is_muted and state.has_sound_components and _G.sound and _G.sound.play then
        pcall(_G.sound.play, "#sound_" .. sound_name, {speed = p})
    end

    return event
end

--- Plays a match sound pitched along the pentatonic scale for the current cascade wave.
-- @param state table Audio manager state instance.
-- @param wave_number number Cascade wave index.
-- @return table event Dispatched sound record.
function audio_manager.play_cascade(state, wave_number)
    local pitch = audio_manager.get_cascade_pitch(wave_number)
    return audio_manager.play(state, "match", pitch)
end

return audio_manager
