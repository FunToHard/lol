--- Visual effect parameters and animation curve calculators for board juice.
-- Provides deterministic tween configs, squash-and-stretch parameters, and flight paths.
-- @module effects
local effects = {}

--- Returns standard swap transition parameters.
-- @param duration number|nil Custom duration in seconds (defaults to 0.15s).
-- @return table config Swap animation parameters including duration and easing type.
function effects.get_swap_config(duration)
    return {
        duration = duration or 0.15,
        easing = "EASING_OUTQUAD"
    }
end

--- Returns the 80ms squash and stretch impact parameters for pieces landing after gravity drops.
-- Produces an instant horizontal expansion (1.15) and vertical squash (0.85) before restoring.
-- @return table config Squash and stretch config with duration, squash scale, and restore scale.
function effects.get_squash_and_stretch()
    return {
        duration = 0.08,
        squash_scale = { x = 1.15, y = 0.85, z = 1.0 },
        restore_scale = { x = 1.0, y = 1.0, z = 1.0 }
    }
end

--- Returns visual explosion and fade parameters for matched pieces.
-- @return table config Match burst parameters including duration, scale multiplier, and target alpha.
function effects.get_match_burst()
    return {
        duration = 0.15,
        burst_scale = { x = 1.25, y = 1.25, z = 1.0 },
        final_alpha = 0.0
    }
end

--- Returns parameters for invalid swap rejection tween (wiggle / bounce back).
-- @return table config Rejection animation config with duration and back-and-forth travel time.
function effects.get_rejection_config()
    return {
        duration = 0.18,
        half_duration = 0.09
    }
end

--- Evaluates a 2D quadratic Bezier curve point at parameter t in [0, 1].
-- @param p0 table Starting position { x = number, y = number }.
-- @param p1 table Control position { x = number, y = number }.
-- @param p2 table Target end position { x = number, y = number }.
-- @param t number Normalized time parameter in range [0, 1].
-- @return number x Interpolated X coordinate.
-- @return number y Interpolated Y coordinate.
function effects.calculate_bezier_point(p0, p1, p2, t)
    local inv_t = 1 - t
    local x = (inv_t * inv_t * p0.x) + (2 * inv_t * t * p1.x) + (t * t * p2.x)
    local y = (inv_t * inv_t * p0.y) + (2 * inv_t * t * p1.y) + (t * t * p2.y)
    return x, y
end

--- Generates a curved homing trajectory for the Firefly power-up toward an obstacle or goal.
-- Calculates an elevated arc control point perpendicular to the displacement vector.
-- @param start_x number Screen X coordinate of origin cell.
-- @param start_y number Screen Y coordinate of origin cell.
-- @param target_x number Screen X coordinate of destination target.
-- @param target_y number Screen Y coordinate of destination target.
-- @param steps number Number of discrete sample points along the flight path.
-- @param arc_height number|nil Perpendicular apex height in pixels (defaults to 120px).
-- @return table waypoints List of { x = number, y = number } coordinate pairs along the curve.
function effects.generate_firefly_arc(start_x, start_y, target_x, target_y, steps, arc_height)
    local h = arc_height or 120
    local mid_x = (start_x + target_x) * 0.5
    local mid_y = (start_y + target_y) * 0.5

    -- Normal vector perpendicular to the flight path
    local dx = target_x - start_x
    local dy = target_y - start_y
    local len = math.sqrt(dx * dx + dy * dy)
    local nx = 0
    local ny = 1
    if len > 0.0001 then
        nx = -dy / len
        ny = dx / len
    end

    -- Control point pushed outward along the normal
    local control = {
        x = mid_x + nx * h,
        y = mid_y + ny * h
    }

    local p0 = { x = start_x, y = start_y }
    local p2 = { x = target_x, y = target_y }
    local waypoints = {}
    local count = math.max(2, steps or 10)

    for i = 0, count do
        local t = i / count
        local px, py = effects.calculate_bezier_point(p0, control, p2, t)
        waypoints[#waypoints + 1] = { x = px, y = py }
    end

    return waypoints
end

--- Generates waypoints for a rocket's linear sweep across a board row or column.
-- @param origin_x number Screen X coordinate of the rocket.
-- @param origin_y number Screen Y coordinate of the rocket.
-- @param direction string Trajectory direction: "horizontal" or "vertical".
-- @param extent number Total screen pixel distance to travel in both directions.
-- @return table head_a Terminal coordinate { x, y } for the forward rocket head.
-- @return table head_b Terminal coordinate { x, y } for the backward rocket head.
function effects.generate_rocket_sweep(origin_x, origin_y, direction, extent)
    local half_dist = extent * 0.5
    if direction == "horizontal" then
        return { x = origin_x + half_dist, y = origin_y }, { x = origin_x - half_dist, y = origin_y }
    else
        return { x = origin_x, y = origin_y + half_dist }, { x = origin_x, y = origin_y - half_dist }
    end
end

return effects
