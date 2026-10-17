--- Companion character controller managing woodland guide emotes and reactions.
-- Orchestrates Pip the Owl and Bramble the Hedgehog dialogue cues and emotional states.
-- @module companion

local companion = {}

local COMPANION_EMOTES = {
    IDLE = "idle",
    CURIOUS = "curious",
    HAPPY = "happy",
    CELEBRATE = "celebrate"
}

companion.EMOTES = COMPANION_EMOTES

local DIALOGUE_LINES = {
    [COMPANION_EMOTES.IDLE] = {
        "Hoo-hoo! The village breeze feels crisp today.",
        "A peaceful day in Lantern Grove."
    },
    [COMPANION_EMOTES.CURIOUS] = {
        "What shall we restore next?",
        "Look at that old stone hearth... with a little care it would shine!"
    },
    [COMPANION_EMOTES.HAPPY] = {
        "Splendid work! The courtyard is coming alive!",
        "Warmth and light return to our grove."
    },
    [COMPANION_EMOTES.CELEBRATE] = {
        "Hooray! The lanterns are glowing brighter than ever!",
        "Incredible! A true master craftsman of the woodland!"
    }
}

--- Creates a new companion state instance.
-- @param name string|nil Companion character name (defaults to "Pip").
-- @return table state Initialized companion state table.
function companion.new(name)
    return {
        name = name or "Pip",
        current_emote = COMPANION_EMOTES.IDLE,
        emote_timer = 0,
        dialogue = DIALOGUE_LINES[COMPANION_EMOTES.IDLE][1]
    }
end

--- Triggers an emotional reaction and selects an appropriate woodland dialogue line.
-- @param state table Active companion state table.
-- @param emote_type string Desired emote ("idle", "curious", "happy", "celebrate").
-- @param duration number|nil Duration in seconds before transitioning back to idle (defaults to 3.0s).
-- @return string dialogue Accompanying dialogue line.
function companion.trigger_reaction(state, emote_type, duration)
    state.current_emote = emote_type or COMPANION_EMOTES.IDLE
    state.emote_timer = duration or 3.0

    local lines = DIALOGUE_LINES[state.current_emote] or DIALOGUE_LINES[COMPANION_EMOTES.IDLE]
    state.dialogue = lines[1]
    return state.dialogue
end

--- Updates the companion emote timer and automatically reverts to idle state upon expiration.
-- @param state table Active companion state table.
-- @param dt number Delta time in seconds since the previous frame.
-- @return string current_emote Active emote after time step.
function companion.update(state, dt)
    if state.emote_timer > 0 then
        state.emote_timer = state.emote_timer - dt
        if state.emote_timer <= 0 then
            state.emote_timer = 0
            state.current_emote = COMPANION_EMOTES.IDLE
            state.dialogue = DIALOGUE_LINES[COMPANION_EMOTES.IDLE][1]
        end
    end
    return state.current_emote
end

return companion
