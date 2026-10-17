--- Dialogue controller managing active NPC conversation flows and narrative presentation.
-- Handles line-by-line progression, character portraits, and UI snapshot compiling.
-- @module dialogue_controller

local lore_catalog = require("game.restoration.lore_catalog")

local dialogue_controller = {}

--- Creates a new dialogue controller state table.
-- @return table state Initialized dialogue controller state.
function dialogue_controller.new()
    return {
        is_active = false,
        active_npc_id = nil,
        active_conversation_id = nil,
        lines = {},
        current_index = 0,
        event_log = {}
    }
end

--- Starts a conversation flow or single idle line for a given NPC.
-- @param ctrl table Dialogue controller state.
-- @param npc_id string Unique NPC identifier.
-- @param conversation_id string|nil Optional scripted conversation key.
-- @param chatter_idx number|nil Optional index to pick deterministic chatter line.
-- @return boolean success True if dialogue was successfully started.
function dialogue_controller.start_dialogue(ctrl, npc_id, conversation_id, chatter_idx)
    local npc = lore_catalog.get_npc(npc_id)
    if not npc then return false end

    ctrl.active_npc_id = npc_id
    ctrl.active_conversation_id = conversation_id
    ctrl.lines = {}
    ctrl.current_index = 1

    if conversation_id then
        local conv = lore_catalog.get_conversation(conversation_id)
        if conv and conv.lines and #conv.lines > 0 then
            for _, l in ipairs(conv.lines) do
                table.insert(ctrl.lines, l)
            end
        end
    end

    -- If no scripted lines found, fall back to single idle chatter line
    if #ctrl.lines == 0 then
        local chatter = lore_catalog.get_idle_chatter(npc_id, chatter_idx or 1)
        table.insert(ctrl.lines, chatter)
    end

    ctrl.is_active = true
    table.insert(ctrl.event_log, { event = "dialogue_started", npc = npc_id, conv = conversation_id })
    return true
end

--- Advances the conversation to the next line or closes if at the end.
-- @param ctrl table Dialogue controller state.
-- @return boolean has_more True if more lines remain, false if dialogue finished.
function dialogue_controller.advance(ctrl)
    if not ctrl.is_active then return false end

    if ctrl.current_index < #ctrl.lines then
        ctrl.current_index = ctrl.current_index + 1
        table.insert(ctrl.event_log, { event = "dialogue_advanced", index = ctrl.current_index })
        return true
    else
        dialogue_controller.close(ctrl)
        return false
    end
end

--- Closes and dismisses the active dialogue.
-- @param ctrl table Dialogue controller state.
function dialogue_controller.close(ctrl)
    ctrl.is_active = false
    ctrl.active_npc_id = nil
    ctrl.active_conversation_id = nil
    ctrl.lines = {}
    ctrl.current_index = 0
    table.insert(ctrl.event_log, { event = "dialogue_closed" })
end

--- Compiles a presentation snapshot for Defold GUI node data binding.
-- @param ctrl table Dialogue controller state.
-- @return table view Formatted presentation snapshot.
function dialogue_controller.get_view_data(ctrl)
    if not ctrl.is_active or not ctrl.active_npc_id then
        return {
            is_active = false,
            speaker_name = "",
            speaker_title = "",
            avatar = "",
            text = "",
            line_index = 0,
            total_lines = 0,
            is_last_line = true
        }
    end

    local npc = lore_catalog.get_npc(ctrl.active_npc_id)
    local current_text = ctrl.lines[ctrl.current_index] or ""
    local is_last = (ctrl.current_index >= #ctrl.lines)

    return {
        is_active = true,
        speaker_name = npc and npc.name or "Guide",
        speaker_title = npc and npc.title or "",
        avatar = npc and npc.avatar or "cell_slot",
        text = current_text,
        line_index = ctrl.current_index,
        total_lines = #ctrl.lines,
        is_last_line = is_last
    }
end

return dialogue_controller
