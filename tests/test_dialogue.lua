--- Unit tests for narrative lore catalog and NPC dialogue controller.
-- Usage: `lua tests/test_dialogue.lua`

package.path = package.path .. ";./?.lua"

local lore_catalog = require("game.restoration.lore_catalog")
local dialogue_controller = require("game.restoration.dialogue_controller")

local total_tests = 0
local passed_tests = 0

--- Asserts equality between actual and expected values.
-- @param actual any Evaluated test value.
-- @param expected any Desired reference value.
-- @param msg string Description of the assertion.
local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Lore Catalog & NPC Dialogue Tests ---")

-- 1. Narrative Backstory
assert_eq(type(lore_catalog.BACKSTORY.title), "string", "Backstory has title")
assert_eq(type(lore_catalog.BACKSTORY.summary), "string", "Backstory has summary")
assert_eq(string.find(lore_catalog.BACKSTORY.summary, "Lantern Keeper") ~= nil, true, "Backstory references Lantern Keeper")

-- 2. NPC Profiles & Avatars
local bramble = lore_catalog.get_npc("bramble")
assert_eq(bramble ~= nil, true, "Elder Bramble exists in catalog")
assert_eq(bramble.name, "Elder Bramble", "Bramble name verified")
assert_eq(bramble.avatar, "village_bramble", "Bramble avatar is village_bramble")

local pip = lore_catalog.get_npc("pip")
assert_eq(pip ~= nil, true, "Pip exists in catalog")
assert_eq(pip.name, "Pip", "Pip name verified")
assert_eq(pip.avatar, "village_pip", "Pip avatar is village_pip")

local maeve = lore_catalog.get_npc("maeve")
assert_eq(maeve ~= nil, true, "Maeve exists in catalog")
assert_eq(maeve.unlock_task, "rebuild_teahouse_kiosk", "Maeve unlocks at teahouse kiosk")

local rowan = lore_catalog.get_npc("rowan")
assert_eq(rowan ~= nil, true, "Rowan exists in catalog")
assert_eq(rowan.unlock_task, "rebuild_wooden_benches", "Rowan unlocks at wooden benches")

-- 3. NPC Unlock Conditions
local empty_tasks = {}
assert_eq(lore_catalog.is_npc_unlocked("bramble", empty_tasks), true, "Elder Bramble unlocked initially")
assert_eq(lore_catalog.is_npc_unlocked("pip", empty_tasks), true, "Pip unlocked initially")
assert_eq(lore_catalog.is_npc_unlocked("maeve", empty_tasks), false, "Maeve locked initially")
assert_eq(lore_catalog.is_npc_unlocked("rowan", empty_tasks), false, "Rowan locked initially")

local teahouse_done = { { task_id = "rebuild_teahouse_kiosk", chosen_style = 1 } }
assert_eq(lore_catalog.is_npc_unlocked("maeve", teahouse_done), true, "Maeve unlocked after teahouse built")

local bench_done = { { task_id = "rebuild_wooden_benches", chosen_style = 2 } }
assert_eq(lore_catalog.is_npc_unlocked("rowan", bench_done), true, "Rowan unlocked after benches built")

-- 4. Multi-Line Scripted Conversations
local conv = lore_catalog.get_conversation("bramble_intro")
assert_eq(conv ~= nil, true, "Bramble intro conversation exists")
assert_eq(#conv.lines, 4, "Bramble intro has 4 lines")
assert_eq(conv.npc_id, "bramble", "Speaker is bramble")

-- 5. Idle Chatter Retrieval
local chat1 = lore_catalog.get_idle_chatter("bramble", 1)
assert_eq(type(chat1), "string", "Chatter line is a string")
local chat2 = lore_catalog.get_idle_chatter("pip", 2)
assert_eq(type(chat2), "string", "Pip chatter is a string")

-- 6. Dialogue Controller Flow
local ctrl = dialogue_controller.new()
assert_eq(ctrl.is_active, false, "Controller starts inactive")

-- Start multi-line conversation
local start_ok = dialogue_controller.start_dialogue(ctrl, "bramble", "bramble_intro")
assert_eq(start_ok, true, "Started Bramble intro dialogue")
assert_eq(ctrl.is_active, true, "Controller is now active")

local view1 = dialogue_controller.get_view_data(ctrl)
assert_eq(view1.is_active, true, "View data active flag is true")
assert_eq(view1.speaker_name, "Elder Bramble", "Speaker is Elder Bramble")
assert_eq(view1.avatar, "village_bramble", "Avatar is village_bramble")
assert_eq(view1.line_index, 1, "Currently on line 1")
assert_eq(view1.total_lines, 4, "Total 4 lines")
assert_eq(view1.is_last_line, false, "Not last line yet")

-- Advance to line 2
local adv1 = dialogue_controller.advance(ctrl)
assert_eq(adv1, true, "Advanced to next line")
local view2 = dialogue_controller.get_view_data(ctrl)
assert_eq(view2.line_index, 2, "Line index is 2")

-- Advance to line 3
dialogue_controller.advance(ctrl)
-- Advance to line 4 (last line)
dialogue_controller.advance(ctrl)
local view4 = dialogue_controller.get_view_data(ctrl)
assert_eq(view4.line_index, 4, "Line index is 4")
assert_eq(view4.is_last_line, true, "Line 4 is the last line")

-- Advance past last line closes dialogue
local adv_end = dialogue_controller.advance(ctrl)
assert_eq(adv_end, false, "Advancing past last line returns false")
assert_eq(ctrl.is_active, false, "Dialogue automatically closed")

-- 7. Idle Single-Line Chatter Flow
dialogue_controller.start_dialogue(ctrl, "pip", nil, 1)
assert_eq(ctrl.is_active, true, "Idle chatter started")
local pip_view = dialogue_controller.get_view_data(ctrl)
assert_eq(pip_view.speaker_name, "Pip", "Speaker is Pip")
assert_eq(pip_view.total_lines, 1, "Idle chatter has 1 line")
assert_eq(pip_view.is_last_line, true, "Single line is marked last line")
dialogue_controller.close(ctrl)
assert_eq(ctrl.is_active, false, "Manual close verified")

-- 8. Convenience Helper Functions
local conv_ok = dialogue_controller.start_conversation(ctrl, "pip_cheer")
assert_eq(conv_ok, true, "start_conversation succeeded")
assert_eq(ctrl.is_active, true, "Controller active after start_conversation")
assert_eq(ctrl.current_speaker, "pip", "current_speaker set to pip")
local cheer_view = dialogue_controller.get_view_data(ctrl)
assert_eq(cheer_view.avatar_texture, "village_pip", "avatar_texture matches avatar")
dialogue_controller.close(ctrl)

local idle_ok = dialogue_controller.start_idle_line(ctrl, "bramble", 2)
assert_eq(idle_ok, true, "start_idle_line succeeded")
assert_eq(ctrl.is_active, true, "Controller active after start_idle_line")
assert_eq(ctrl.current_speaker, "bramble", "current_speaker set to bramble")
dialogue_controller.close(ctrl)

local cust_ok = dialogue_controller.start_custom(ctrl, "bramble", "The mist is lifting!")
assert_eq(cust_ok, true, "start_custom succeeded")
assert_eq(ctrl.is_active, true, "Controller active after start_custom")
local cust_view = dialogue_controller.get_view_data(ctrl)
assert_eq(cust_view.text, "The mist is lifting!", "Custom text preserved in view")
assert_eq(cust_view.speaker_name, "Elder Bramble", "Custom speaker is Elder Bramble")
dialogue_controller.close(ctrl)

print(string.format("All tests passed! (%d/%d assertions)\n", passed_tests, total_tests))

