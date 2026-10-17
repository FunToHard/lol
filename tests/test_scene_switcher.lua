--- Unit tests for scene switcher state machine, validation, and transition lifecycle.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_scene_switcher.lua`

package.path = package.path .. ";./?.lua"

local scene_switcher = require("game.services.scene_switcher")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

local function assert_true(condition, msg)
    assert_eq(condition, true, msg)
end

local function assert_false(condition, msg)
    assert_eq(condition, false, msg)
end

print("--- Running Scene Switcher & Transition Manager Tests ---")

-- Test 1: Initial state
local switcher = scene_switcher.new("map")
assert_eq(switcher.current_scene, "map", "Initial scene is map")
assert_eq(switcher.phase, "IDLE", "Initial phase is IDLE")
assert_false(scene_switcher.get_state(switcher).is_transitioning, "Not transitioning initially")

-- Test 2: Transition validation rules
assert_true(scene_switcher.is_valid_transition("map", "puzzle"), "Map to puzzle allowed")
assert_true(scene_switcher.is_valid_transition("map", "village"), "Map to village allowed")
assert_true(scene_switcher.is_valid_transition("puzzle", "map"), "Puzzle to map allowed")
assert_true(scene_switcher.is_valid_transition("puzzle", "village"), "Puzzle to village allowed")
assert_true(scene_switcher.is_valid_transition("puzzle", "puzzle"), "Puzzle to puzzle (restart) allowed")
assert_true(scene_switcher.is_valid_transition("village", "map"), "Village to map allowed")
assert_true(scene_switcher.is_valid_transition("village", "puzzle"), "Village to puzzle allowed")
assert_false(scene_switcher.is_valid_transition("map", "invalid_scene"), "Unknown scene rejected")
assert_false(scene_switcher.is_valid_transition("invalid", "puzzle"), "Unknown source rejected")

-- Test 3: Full transition lifecycle (Map -> Puzzle)
local ok, err = scene_switcher.request_switch(switcher, "puzzle", { level_id = 3 })
assert_true(ok, "Transition request accepted")
assert_eq(switcher.phase, "FADING_OUT", "Phase is FADING_OUT")
assert_eq(switcher.target_scene, "puzzle", "Target scene is puzzle")
assert_eq(switcher.params.level_id, 3, "Param level_id preserved")
assert_true(scene_switcher.get_state(switcher).is_transitioning, "Reported as transitioning")

-- Cannot initiate another switch while busy
local busy_ok, busy_err = scene_switcher.request_switch(switcher, "village")
assert_false(busy_ok, "Cannot switch while transitioning")
assert_eq(busy_err, "ALREADY_TRANSITIONING", "Error code is ALREADY_TRANSITIONING")

-- Advance fade out
assert_true(scene_switcher.on_fade_out_complete(switcher), "Fade out completed")
assert_eq(switcher.phase, "LOADING", "Phase is LOADING")

-- Advance scene load
assert_true(scene_switcher.on_scene_loaded(switcher), "Scene loaded")
assert_eq(switcher.phase, "FADING_IN", "Phase is FADING_IN")

-- Complete fade in
local current = scene_switcher.on_fade_in_complete(switcher)
assert_eq(current, "puzzle", "Current scene is now puzzle")
assert_eq(switcher.phase, "IDLE", "Phase returned to IDLE")
assert_eq(switcher.previous_scene, "map", "Previous scene recorded as map")
assert_eq(#switcher.history, 1, "History has 1 entry")

-- Test 4: Transition Puzzle -> Village
local ok2 = scene_switcher.request_switch(switcher, "village")
assert_true(ok2, "Switch to village accepted")
scene_switcher.on_fade_out_complete(switcher)
scene_switcher.on_scene_loaded(switcher)
scene_switcher.on_fade_in_complete(switcher)
assert_eq(switcher.current_scene, "village", "In village scene")
assert_eq(#switcher.history, 2, "History has 2 entries")

-- Test 5: Back navigation
local back_ok = scene_switcher.go_back(switcher)
assert_true(back_ok, "Back navigation accepted")
assert_eq(switcher.target_scene, "puzzle", "Back target is puzzle")
scene_switcher.on_fade_out_complete(switcher)
scene_switcher.on_scene_loaded(switcher)
scene_switcher.on_fade_in_complete(switcher)
assert_eq(switcher.current_scene, "puzzle", "Navigated back to puzzle")

-- Back navigation again (returns to map)
local back_ok2 = scene_switcher.go_back(switcher)
assert_true(back_ok2, "Second back navigation accepted")
assert_eq(switcher.target_scene, "map", "Back target is map")
scene_switcher.on_fade_out_complete(switcher)
scene_switcher.on_scene_loaded(switcher)
scene_switcher.on_fade_in_complete(switcher)
assert_eq(switcher.current_scene, "map", "Navigated back to map")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
