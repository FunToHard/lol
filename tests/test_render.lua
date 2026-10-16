--- Unit tests for camera shake and adaptive audio pitch calculations.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_render.lua`

package.path = package.path .. ";./?.lua"

local camera_shake = require("game.render.camera_shake")
local audio_manager = require("game.render.audio_manager")

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

print("--- Running Camera Shake & Audio Manager Tests ---")

-- Test 1: Camera Shake Trigger & Decay
local shake = camera_shake.new()
camera_shake.trigger(shake, 4.0, 0.2)
local ox1, oy1 = camera_shake.update(shake, 0.05)
assert_true(ox1 ~= 0 or oy1 ~= 0, "Active shake produces displacement")

-- Advance past total duration
local ox_end, oy_end = camera_shake.update(shake, 0.25)
assert_eq(ox_end, 0, "Decayed shake returns 0 X offset")
assert_eq(oy_end, 0, "Decayed shake returns 0 Y offset")

-- Test 2: Audio Pentatonic Pitch Progression
local p1 = audio_manager.get_cascade_pitch(1)
local p2 = audio_manager.get_cascade_pitch(2)
local p3 = audio_manager.get_cascade_pitch(3)
local p6 = audio_manager.get_cascade_pitch(6)

assert_eq(p1, 1.0, "Cascade 1 is normal pitch (1.0)")
assert_true(p2 > p1, "Cascade 2 pitches upward")
assert_true(p3 > p2, "Cascade 3 pitches higher than 2")
assert_true(math.abs(p6 - 2.0) < 0.001, "Cascade 6 is exactly 1 octave (2.0x)")

-- Test 3: Audio Event Logging
local audio = audio_manager.new(false)
local ev = audio_manager.play_cascade(audio, 3)
assert_eq(ev.sound, "match", "Played match sound")
assert_eq(ev.pitch, p3, "Correct pitch assigned")
assert_eq(#audio.event_log, 1, "Recorded 1 audio event")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
