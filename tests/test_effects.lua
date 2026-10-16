--- Unit tests for visual effects and animation curves.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_effects.lua`

package.path = package.path .. ";./?.lua"

local effects = require("game.render.effects")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

local function assert_near(actual, expected, tol, msg)
    total_tests = total_tests + 1
    if math.abs(actual - expected) > (tol or 0.001) then
        error(string.format("FAILED: %s | Expected ~%f, Got %f", tostring(msg), expected, actual))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Visual Effects & Juice Tests ---")

-- Test 1: Swap config
local swap_cfg = effects.get_swap_config()
assert_eq(swap_cfg.duration, 0.15, "Standard swap duration is 0.15s")
assert_eq(swap_cfg.easing, "EASING_OUTQUAD", "Easing is OUTQUAD")

-- Test 2: 80ms Squash & Stretch
local squash_cfg = effects.get_squash_and_stretch()
assert_eq(squash_cfg.duration, 0.08, "Squash and stretch duration is exactly 80ms (0.08s)")
assert_eq(squash_cfg.squash_scale.x, 1.15, "Horizontal squash expansion is 1.15")
assert_eq(squash_cfg.squash_scale.y, 0.85, "Vertical squash compression is 0.85")
assert_eq(squash_cfg.restore_scale.x, 1.0, "Restore scale X is 1.0")
assert_eq(squash_cfg.restore_scale.y, 1.0, "Restore scale Y is 1.0")

-- Test 3: Match burst config
local burst_cfg = effects.get_match_burst()
assert_eq(burst_cfg.duration, 0.15, "Burst duration is 0.15s")
assert_eq(burst_cfg.burst_scale.x, 1.25, "Burst scale expansion is 1.25")
assert_eq(burst_cfg.final_alpha, 0.0, "Final alpha fades to 0.0")

-- Test 4: Quadratic Bezier Curve Calculation
local p0 = { x = 0, y = 0 }
local p1 = { x = 50, y = 100 }
local p2 = { x = 100, y = 0 }

local x_start, y_start = effects.calculate_bezier_point(p0, p1, p2, 0.0)
assert_near(x_start, 0, 0.001, "Bezier at t=0 starts at p0.x")
assert_near(y_start, 0, 0.001, "Bezier at t=0 starts at p0.y")

local x_mid, y_mid = effects.calculate_bezier_point(p0, p1, p2, 0.5)
assert_near(x_mid, 50, 0.001, "Bezier at t=0.5 reaches midpoint X")
assert_near(y_mid, 50, 0.001, "Bezier at t=0.5 reaches midpoint Y")

local x_end, y_end = effects.calculate_bezier_point(p0, p1, p2, 1.0)
assert_near(x_end, 100, 0.001, "Bezier at t=1 ends at p2.x")
assert_near(y_end, 0, 0.001, "Bezier at t=1 ends at p2.y")

-- Test 5: Firefly Arc Generation
local waypoints = effects.generate_firefly_arc(100, 200, 400, 600, 10, 100)
assert_eq(#waypoints, 11, "Firefly arc contains 11 sample points (0 to 10)")
assert_near(waypoints[1].x, 100, 0.1, "First waypoint at origin X")
assert_near(waypoints[1].y, 200, 0.1, "First waypoint at origin Y")
assert_near(waypoints[#waypoints].x, 400, 0.1, "Last waypoint at target X")
assert_near(waypoints[#waypoints].y, 600, 0.1, "Last waypoint at target Y")

-- Test 6: Rocket Sweep Trajectories
local h_a, h_b = effects.generate_rocket_sweep(360, 640, "horizontal", 720)
assert_eq(h_a.x, 720, "Horizontal right terminal at 720")
assert_eq(h_a.y, 640, "Horizontal right terminal maintains Y")
assert_eq(h_b.x, 0, "Horizontal left terminal at 0")

local v_a, v_b = effects.generate_rocket_sweep(360, 640, "vertical", 1280)
assert_eq(v_a.y, 1280, "Vertical top terminal at 1280")
assert_eq(v_a.x, 360, "Vertical top terminal maintains X")
assert_eq(v_b.y, 0, "Vertical bottom terminal at 0")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
