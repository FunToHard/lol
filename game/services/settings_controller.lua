--- View-model controller managing game settings, audio/haptic toggles, and progress resets.
-- Decoupled pure Lua controller persisting preferences into player save data.
-- @module settings_controller

local save_manager = require("game.persistence.save_manager")

local settings_controller = {}

settings_controller.VERSION_STRING = "Lantern Grove v1.0.0"

--- Creates a new settings controller instance.
-- @param save_data table Active player save data table.
-- @return table ctrl Initialized settings controller state table.
function settings_controller.new(save_data)
    assert(type(save_data) == "table", "settings_controller requires save data table")

    -- Ensure settings block exists
    if not save_data.settings then
        save_data.settings = {
            sfx_enabled = true,
            music_enabled = true,
            haptics_enabled = true
        }
    end

    return {
        save_data = save_data,
        is_open = false,
        confirming_reset = false,
        event_log = {}
    }
end

--- Opens or shows the settings modal dialog.
-- @param ctrl table Settings controller state instance.
function settings_controller.open(ctrl)
    ctrl.is_open = true
    ctrl.confirming_reset = false
    table.insert(ctrl.event_log, { event = "opened" })
end

--- Closes the settings modal dialog.
-- @param ctrl table Settings controller state instance.
function settings_controller.close(ctrl)
    ctrl.is_open = false
    ctrl.confirming_reset = false
    table.insert(ctrl.event_log, { event = "closed" })
end

--- Toggles Sound Effects (SFX) between enabled and disabled states.
-- @param ctrl table Settings controller state instance.
-- @return boolean enabled Resulting SFX state.
function settings_controller.toggle_sfx(ctrl)
    local s = ctrl.save_data.settings
    s.sfx_enabled = not (s.sfx_enabled ~= false)
    table.insert(ctrl.event_log, { event = "toggle_sfx", value = s.sfx_enabled })
    return s.sfx_enabled
end

--- Toggles Background Music between enabled and disabled states.
-- @param ctrl table Settings controller state instance.
-- @return boolean enabled Resulting Music state.
function settings_controller.toggle_music(ctrl)
    local s = ctrl.save_data.settings
    s.music_enabled = not (s.music_enabled ~= false)
    table.insert(ctrl.event_log, { event = "toggle_music", value = s.music_enabled })
    return s.music_enabled
end

--- Toggles Mobile Tactile Haptics between enabled and disabled states.
-- @param ctrl table Settings controller state instance.
-- @return boolean enabled Resulting Haptics state.
function settings_controller.toggle_haptics(ctrl)
    local s = ctrl.save_data.settings
    s.haptics_enabled = not (s.haptics_enabled ~= false)
    table.insert(ctrl.event_log, { event = "toggle_haptics", value = s.haptics_enabled })
    return s.haptics_enabled
end

--- Requests confirmation to reset all player progress back to default.
-- @param ctrl table Settings controller state instance.
-- @return boolean confirming True if waiting for final confirmation.
function settings_controller.request_reset_progress(ctrl)
    ctrl.confirming_reset = true
    table.insert(ctrl.event_log, { event = "reset_requested" })
    return true
end

--- Confirms and executes atomic progress reset, restoring fresh save defaults while keeping settings.
-- @param ctrl table Settings controller state instance.
-- @return boolean success True if reset was executed.
function settings_controller.confirm_reset_progress(ctrl)
    if not ctrl.confirming_reset then
        return false
    end

    local current_settings = {
        sfx_enabled = ctrl.save_data.settings.sfx_enabled,
        music_enabled = ctrl.save_data.settings.music_enabled,
        haptics_enabled = ctrl.save_data.settings.haptics_enabled
    }

    local fresh_state = save_manager.create_default_state()
    fresh_state.settings = current_settings

    -- Overwrite active save data fields
    for k, _ in pairs(ctrl.save_data) do
        ctrl.save_data[k] = nil
    end
    for k, v in pairs(fresh_state) do
        ctrl.save_data[k] = v
    end

    ctrl.confirming_reset = false
    table.insert(ctrl.event_log, { event = "reset_confirmed" })
    return true
end

--- Cancels a pending reset confirmation prompt.
-- @param ctrl table Settings controller state instance.
function settings_controller.cancel_reset_progress(ctrl)
    ctrl.confirming_reset = false
    table.insert(ctrl.event_log, { event = "reset_cancelled" })
end

--- Compiles a presentation snapshot for GUI view binding.
-- @param ctrl table Settings controller state instance.
-- @return table view Presentation snapshot table.
function settings_controller.get_view_data(ctrl)
    local s = ctrl.save_data.settings
    return {
        is_open = ctrl.is_open,
        confirming_reset = ctrl.confirming_reset,
        sfx_enabled = (s.sfx_enabled ~= false),
        music_enabled = (s.music_enabled ~= false),
        haptics_enabled = (s.haptics_enabled ~= false),
        version_string = settings_controller.VERSION_STRING
    }
end

return settings_controller
