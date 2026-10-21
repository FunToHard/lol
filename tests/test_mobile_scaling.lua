--- Unit tests for Mobile/Tablet Aspect Ratio Scaling, Safe Margins, and Haptics/Audio.
-- Validates coordinate transforms across 16:9, 19.5:9, 20:9 phones and 4:3, 16:10 tablets.
-- Usage: `lua tests/test_mobile_scaling.lua`

package.path = package.path .. ";./?.lua"

local board_view = require("game.render.board_view")
local haptic = require("game.render.haptic")
local audio_manager = require("game.render.audio_manager")
local save_manager = require("game.persistence.save_manager")
local settings_controller = require("game.services.settings_controller")

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

print("--- Running Mobile/Tablet Scaling & Polish Tests ---")

-- 1. Standard Mobile (16:9 - 720x1280) Safe Margins
local origin_x, origin_y = board_view.get_board_origin(8, 8, 520)
-- Total grid width = 8 * 82 - 6 = 650
-- Left margin = (720 - 650) / 2 = 35 px
assert_eq(origin_x - (board_view.TILE_SIZE / 2), 35, "Horizontal safe margin on 720w is exactly 35px")

-- Bottom margin from origin_y (center_y = 520)
-- Board spans from y = 520 - (650/2) = 195 to y = 520 + (650/2) = 845
local board_bottom = origin_y - (board_view.TILE_SIZE / 2)
local board_top = board_bottom + (8 * board_view.CELL_PITCH - board_view.TILE_GAP)
assert_eq(board_bottom >= 180, true, "Board bottom leaves >=180px safe margin for Booster Dock (bottom = " .. board_bottom .. ")")
assert_eq(board_top <= 880, true, "Board top leaves >=400px safe margin for In-Game HUD (top = " .. board_top .. ")")

-- 2. Multi-Aspect Ratio Adaptations (Tall 19.5:9 Phone & 4:3 Tablet)
-- Tall phone (e.g. 720x1560): center_y can shift up to 600px, expanding bottom booster margin
local tall_origin_x, tall_origin_y = board_view.get_board_origin(8, 8, 600)
local tall_bottom = tall_origin_y - (board_view.TILE_SIZE / 2)
local tall_top = tall_bottom + (8 * board_view.CELL_PITCH - board_view.TILE_GAP)
assert_eq(tall_bottom >= 260, true, "Tall phone leaves extra booster room (bottom = " .. tall_bottom .. ")")
assert_eq(1560 - tall_top >= 500, true, "Tall phone leaves extensive HUD/notch room (top margin = " .. (1560 - tall_top) .. ")")

-- Tablet (e.g. 720x960 4:3): center_y shifted slightly lower to 480px
local tab_origin_x, tab_origin_y = board_view.get_board_origin(8, 8, 480)
local tab_bottom = tab_origin_y - (board_view.TILE_SIZE / 2)
local tab_top = tab_bottom + (8 * board_view.CELL_PITCH - board_view.TILE_GAP)
assert_eq(tab_bottom >= 150, true, "Tablet leaves sufficient booster room (bottom = " .. tab_bottom .. ")")
assert_eq(960 - tab_top >= 150, true, "Tablet leaves sufficient HUD room (top margin = " .. (960 - tab_top) .. ")")

-- 3. Cell Screen Coordinates & Hit-Testing Across Multiple Aspect Ratios
for gx = 1, 8 do
    for gy = 1, 8 do
        local px, py = board_view.grid_to_screen(gx, gy, 8, 8, 520)
        local test_gx, test_gy = board_view.screen_to_grid(px, py, 8, 8, 520)
        assert_eq(test_gx, gx, string.format("Roundtrip hit-test matches column %d", gx))
        assert_eq(test_gy, gy, string.format("Roundtrip hit-test matches row %d", gy))
    end
end

-- Touches outside board boundary safely return nil
local out_gx, out_gy = board_view.screen_to_grid(10, 10, 8, 8, 520)
assert_eq(out_gx, nil, "Touch on bottom-left screen margin rejected")
assert_eq(out_gy, nil, "Touch on bottom-left screen margin rejected")

local out_gx2, out_gy2 = board_view.screen_to_grid(360, 1100, 8, 8, 520)
assert_eq(out_gx2, nil, "Touch in top HUD area rejected by board")

-- 3. Haptic Feedback Settings Integration
local haptics_on = haptic.new(true)
assert_eq(haptic.tick(haptics_on), true, "Haptic tick fires when enabled")
assert_eq(haptic.impact(haptics_on), true, "Haptic impact fires when enabled")
assert_eq(haptic.heavy(haptics_on), true, "Haptic heavy fires when enabled")
assert_eq(#haptics_on.history, 3, "3 haptic events recorded")

local haptics_off = haptic.new(false)
assert_eq(haptic.tick(haptics_off), false, "Haptic tick suppressed when disabled")
assert_eq(haptic.impact(haptics_off), false, "Haptic impact suppressed when disabled")
assert_eq(haptic.heavy(haptics_off), false, "Haptic heavy suppressed when disabled")
assert_eq(#haptics_off.history, 0, "No haptic events recorded when disabled")

-- Test dynamic set_enabled toggle
haptic.set_enabled(haptics_off, true)
assert_eq(haptic.tick(haptics_off), true, "Haptic tick fires after set_enabled(true)")

-- 4. Audio Manager Mute State Integration
local audio_active = audio_manager.new(false, false)
local evt_sound = audio_manager.play(audio_active, "match", 1.0)
assert_eq(evt_sound.is_muted, false, "Sound plays unmuted when audio enabled")

local audio_muted = audio_manager.new(true, false)
local evt_muted = audio_manager.play(audio_muted, "match", 1.0)
assert_eq(evt_muted.is_muted, true, "Sound muted when audio disabled")

-- Test dynamic set_muted toggle
audio_manager.set_muted(audio_muted, false)
local evt_unmuted = audio_manager.play(audio_muted, "swap", 1.0)
assert_eq(evt_unmuted.is_muted, false, "Sound plays unmuted after set_muted(false)")

-- 5. Persistent Settings Toggle Roundtrip
local save_data = save_manager.create_default_state()
local settings_ctrl = settings_controller.new(save_data)

-- Toggle Haptics off
settings_controller.toggle_haptics(settings_ctrl)
local view = settings_controller.get_view_data(settings_ctrl)
assert_eq(view.haptics_enabled, false, "Haptics preference toggled to false")

local runtime_haptic = haptic.new(save_data.settings.haptics_enabled)
assert_eq(haptic.tick(runtime_haptic), false, "Runtime haptic respects persisted disabled setting")

-- Toggle SFX off
settings_controller.toggle_sfx(settings_ctrl)
view = settings_controller.get_view_data(settings_ctrl)
assert_eq(view.sfx_enabled, false, "SFX preference toggled to false")

local runtime_audio = audio_manager.new(save_data.settings.sfx_enabled == false, false)
local runtime_evt = audio_manager.play(runtime_audio, "swap", 1.0)
assert_eq(runtime_evt.is_muted, true, "Runtime audio respects persisted muted setting")

print(string.format("All tests passed! (%d/%d assertions)\n", passed_tests, total_tests))
