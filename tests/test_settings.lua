--- Unit tests for settings controller (SFX, Music, Haptic toggles, and atomic resets).
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_settings.lua`

package.path = package.path .. ";./?.lua"

local settings_controller = require("game.services.settings_controller")
local save_manager = require("game.persistence.save_manager")

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

print("--- Running Settings Controller Tests ---")

-- Test 1: Initialization with default settings
local save_data = save_manager.create_default_state()
local ctrl = settings_controller.new(save_data)

local view = settings_controller.get_view_data(ctrl)
assert_false(view.is_open, "Settings starts closed")
assert_false(view.confirming_reset, "Not confirming reset initially")
assert_true(view.sfx_enabled, "SFX enabled by default")
assert_true(view.music_enabled, "Music enabled by default")
assert_true(view.haptics_enabled, "Haptics enabled by default")
assert_true(#view.version_string > 0, "Version string present")

-- Test 2: Open and Close Modal
settings_controller.open(ctrl)
assert_true(settings_controller.get_view_data(ctrl).is_open, "Settings is open")
settings_controller.close(ctrl)
assert_false(settings_controller.get_view_data(ctrl).is_open, "Settings is closed")

-- Test 3: Audio & Haptic Toggles
local sfx_res = settings_controller.toggle_sfx(ctrl)
assert_false(sfx_res, "SFX toggled off")
assert_false(save_data.settings.sfx_enabled, "Saved settings reflects SFX off")
settings_controller.toggle_sfx(ctrl)
assert_true(save_data.settings.sfx_enabled, "SFX toggled back on")

local mus_res = settings_controller.toggle_music(ctrl)
assert_false(mus_res, "Music toggled off")
assert_false(save_data.settings.music_enabled, "Saved settings reflects Music off")

local hap_res = settings_controller.toggle_haptics(ctrl)
assert_false(hap_res, "Haptics toggled off")
assert_false(save_data.settings.haptics_enabled, "Saved settings reflects Haptics off")

-- Test 4: Reset Confirmation Flow
save_data.player.stars = 25
save_data.player.coins = 5000
save_data.progression.max_unlocked_level = 10

settings_controller.open(ctrl)
assert_false(settings_controller.confirm_reset_progress(ctrl), "Cannot confirm reset before requesting")

settings_controller.request_reset_progress(ctrl)
assert_true(settings_controller.get_view_data(ctrl).confirming_reset, "Confirming reset prompt active")

-- Cancel reset test
settings_controller.cancel_reset_progress(ctrl)
assert_false(settings_controller.get_view_data(ctrl).confirming_reset, "Reset cancelled")
assert_eq(save_data.player.stars, 25, "Stars unchanged after cancel")

-- Request again and confirm
settings_controller.request_reset_progress(ctrl)
local reset_ok = settings_controller.confirm_reset_progress(ctrl)
assert_true(reset_ok, "Reset executed successfully")
assert_eq(save_data.player.stars, 0, "Stars reset to default 0")
assert_eq(save_data.player.coins, 100, "Coins reset to default 100")
assert_eq(save_data.progression.max_unlocked_level, 1, "Level progression reset to level 1")

-- Settings preferences preserved across reset
assert_false(save_data.settings.music_enabled, "Music preference preserved")
assert_false(save_data.settings.haptics_enabled, "Haptics preference preserved")
assert_true(save_data.settings.sfx_enabled, "SFX preference preserved")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
