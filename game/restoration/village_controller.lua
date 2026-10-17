--- View-model controller governing the woodland village restoration UI, task drawer, and 3-style picker.
-- Decouples GUI presentation from village state simulation, star spending ledger, and companion emotes.
-- @module village_controller

local task_catalog = require("game.restoration.task_catalog")
local village_state = require("game.restoration.village_state")
local companion = require("game.restoration.companion")
local ledger = require("game.economy.ledger")

local village_controller = {}

--- Creates a new village UI controller instance.
-- @param vstate table Active village_state instance.
-- @param comp table Active companion instance.
-- @param econ table Active economy ledger instance.
-- @return table ctrl Initialized controller state table.
function village_controller.new(vstate, comp, econ)
    assert(type(vstate) == "table", "village_controller requires a village_state instance")
    assert(type(comp) == "table", "village_controller requires a companion instance")
    assert(type(econ) == "table", "village_controller requires an economy ledger instance")

    local ctrl = {
        village = vstate,
        companion = comp,
        ledger = econ,
        drawer_open = true,
        picker_open = false,
        picker_task_id = nil,
        picker_mode = "RESTORE", -- "RESTORE" or "RESTYLE"
        selected_style_idx = 1,
        event_log = {}
    }
    return ctrl
end

--- Toggles the task drawer between expanded and collapsed states.
-- @param ctrl table Controller state table.
-- @return boolean is_open Resulting drawer state.
function village_controller.toggle_drawer(ctrl)
    ctrl.drawer_open = not ctrl.drawer_open
    table.insert(ctrl.event_log, { event = "drawer_toggled", open = ctrl.drawer_open })
    return ctrl.drawer_open
end

--- Opens the 3-style visual picker modal for a specific task.
-- Validates task availability and star cost before opening in "RESTORE" mode.
-- @param ctrl table Controller state table.
-- @param task_id string Unique task identifier.
-- @param mode string|nil "RESTORE" (default) or "RESTYLE".
-- @return boolean success True if picker opened successfully.
-- @return string|nil error_code Error description if failed.
function village_controller.open_picker(ctrl, task_id, mode)
    local task = task_catalog.get_task(task_id)
    if not task then
        return false, "TASK_NOT_FOUND"
    end

    local op_mode = mode or "RESTORE"
    if op_mode == "RESTORE" then
        if not village_state.can_complete_task(ctrl.village, task_id) then
            return false, "INSUFFICIENT_STARS_OR_LOCKED"
        end
    end

    ctrl.picker_open = true
    ctrl.picker_task_id = task_id
    ctrl.picker_mode = op_mode

    -- Default to already chosen style or 1
    local current_choice = ctrl.village.chosen_styles[task_id] or 1
    ctrl.selected_style_idx = current_choice

    -- Companion gets curious when inspecting styles
    companion.trigger_reaction(ctrl.companion, "curious", 3.0)
    table.insert(ctrl.event_log, { event = "picker_opened", task_id = task_id, mode = op_mode })
    return true, nil
end

--- Selects an aesthetic style option (1, 2, or 3) within the open picker.
-- @param ctrl table Controller state table.
-- @param style_idx number Style index (1 to 3).
-- @return boolean success True if valid style index was selected.
function village_controller.select_style(ctrl, style_idx)
    if not ctrl.picker_open then return false end
    if type(style_idx) ~= "number" or style_idx < 1 or style_idx > 3 then
        return false
    end
    ctrl.selected_style_idx = style_idx
    table.insert(ctrl.event_log, { event = "style_selected", index = style_idx })
    return true
end

--- Confirms the chosen style, executes star spending or zero-cost restyle, and triggers companion celebration.
-- @param ctrl table Controller state table.
-- @param op_id string|nil Optional idempotency transaction ID.
-- @return boolean success True if task was completed or restyled.
-- @return string|nil result_or_err Result code or error reason.
function village_controller.confirm_selection(ctrl, op_id)
    if not ctrl.picker_open or not ctrl.picker_task_id then
        return false, "PICKER_NOT_OPEN"
    end

    local task_id = ctrl.picker_task_id
    local style_idx = ctrl.selected_style_idx

    if ctrl.picker_mode == "RESTORE" then
        local tx_id = op_id or ("op_task_" .. task_id .. "_" .. tostring(os.time and os.time() or 0))
        local ok, err = village_state.complete_task(ctrl.village, task_id, style_idx, tx_id)
        if not ok then
            return false, err or "COMPLETION_FAILED"
        end

        -- Companion celebrates restoration milestone
        companion.trigger_reaction(ctrl.companion, "celebrate", 4.0)
        ctrl.picker_open = false
        ctrl.picker_task_id = nil
        table.insert(ctrl.event_log, { event = "restoration_confirmed", task_id = task_id, style = style_idx })
        return true, "TASK_COMPLETED"
    elseif ctrl.picker_mode == "RESTYLE" then
        local ok = village_state.restyle_prop(ctrl.village, task_id, style_idx)
        if not ok then
            return false, "RESTYLE_FAILED"
        end

        -- Companion approves new look
        companion.trigger_reaction(ctrl.companion, "happy", 3.0)
        ctrl.picker_open = false
        ctrl.picker_task_id = nil
        table.insert(ctrl.event_log, { event = "restyle_confirmed", task_id = task_id, style = style_idx })
        return true, "PROP_RESTYLED"
    end

    return false, "UNKNOWN_MODE"
end

--- Closes the 3-style picker without applying changes.
-- @param ctrl table Controller state table.
function village_controller.close_picker(ctrl)
    ctrl.picker_open = false
    ctrl.picker_task_id = nil
    table.insert(ctrl.event_log, { event = "picker_closed" })
end

--- Compiles a presentation snapshot for Defold GUI node data binding.
-- @param ctrl table Controller state table.
-- @return table view Formatted presentation snapshot.
function village_controller.get_view_data(ctrl)
    local stars = ledger.get_balance(ctrl.ledger, "stars")
    local coins = ledger.get_balance(ctrl.ledger, "coins")
    local stats = village_state.get_completion_stats(ctrl.village)
    local active_task = village_state.get_active_task(ctrl.village)

    local active_data = nil
    if active_task then
        active_data = {
            id = active_task.id,
            title = active_task.title,
            cost = active_task.cost,
            can_afford = stars >= active_task.cost
        }
    end

    local picker_view = nil
    if ctrl.picker_open and ctrl.picker_task_id then
        local task = task_catalog.get_task(ctrl.picker_task_id)
        local styles_data = {}
        for i, s in ipairs(task.styles) do
            table.insert(styles_data, {
                index = i,
                id = s.id,
                name = s.name,
                is_selected = (i == ctrl.selected_style_idx),
                is_current = (ctrl.village.chosen_styles[task.id] == i)
            })
        end

        picker_view = {
            task_id = task.id,
            task_title = task.title,
            mode = ctrl.picker_mode,
            cost = (ctrl.picker_mode == "RESTORE" and task.cost or 0),
            styles = styles_data,
            selected_idx = ctrl.selected_style_idx
        }
    end

    return {
        stars = stars,
        coins = coins,
        area_id = ctrl.village.current_area,
        area_completed = stats.completed,
        area_total = stats.total,
        area_percent = stats.percent,
        drawer_open = ctrl.drawer_open,
        active_task = active_data,
        companion_name = ctrl.companion.name,
        companion_emote = ctrl.companion.current_emote,
        companion_dialogue = ctrl.companion.dialogue,
        picker_open = ctrl.picker_open,
        picker = picker_view
    }
end

return village_controller
