--- Unit tests for haptic feedback controller.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_haptic.lua`

package.path = package.path .. ";./?.lua"

local haptic = require("game.render.haptic")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Haptic Feedback Controller Tests ---")

-- Test 1: Enabled by default and registers events
local h = haptic.new()
assert_eq(h.enabled, true, "Haptic enabled by default")

local r1 = haptic.tick(h)
assert_eq(r1, true, "Tick dispatched")
assert_eq(h.last_event, "tick", "Last event is tick")
assert_eq(#h.history, 1, "One event in history")

local r2 = haptic.impact(h)
assert_eq(r2, true, "Impact dispatched")
assert_eq(h.last_event, "impact", "Last event is impact")
assert_eq(#h.history, 2, "Two events in history")

local r3 = haptic.heavy(h)
assert_eq(r3, true, "Heavy pulse dispatched")
assert_eq(h.last_event, "heavy", "Last event is heavy")
assert_eq(#h.history, 3, "Three events in history")

-- Test 2: Disabled haptics do not dispatch
haptic.set_enabled(h, false)
assert_eq(h.enabled, false, "Haptic set to disabled")
local r4 = haptic.tick(h)
assert_eq(r4, false, "Tick suppressed when disabled")
assert_eq(#h.history, 3, "History unchanged when disabled")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
