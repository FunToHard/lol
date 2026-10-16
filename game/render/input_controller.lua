--- Touch input controller managing mobile screen drag-and-swap and tap detection.
-- Translates raw touch/pointer coordinates into discrete game actions (swap, tap).
local board_view = require("game.render.board_view")

local input_controller = {}

input_controller.SWIPE_THRESHOLD = 22 -- Minimum pixel drag distance to commit a swap

--- Creates a new input controller state instance.
-- @return table state_instance The initialized input state table.
function input_controller.new()
    return {
        is_active = false,
        start_px = 0,
        start_py = 0,
        start_gx = nil,
        start_gy = nil
    }
end

--- Handles touch press down event.
-- Identifies the touched grid cell and begins tracking drag vector.
-- @param state table Input controller state instance.
-- @param px number Screen touch X coordinate.
-- @param py number Screen touch Y coordinate.
-- @param grid_w number Total board columns.
-- @param grid_h number Total board rows.
-- @param custom_center_y number|nil Optional vertical center.
-- @return table|nil event Action record {action = 'select', gx, gy} or nil if touched outside.
function input_controller.on_touch_down(state, px, py, grid_w, grid_h, custom_center_y)
    local gx, gy = board_view.screen_to_grid(px, py, grid_w, grid_h, custom_center_y)
    if not gx then
        state.is_active = false
        return nil
    end

    state.is_active = true
    state.start_px = px
    state.start_py = py
    state.start_gx = gx
    state.start_gy = gy

    return {
        action = "select",
        gx = gx,
        gy = gy
    }
end

--- Handles touch move/drag event.
-- Evaluates drag distance; triggers a directional swap once swipe threshold is exceeded.
-- @param state table Input controller state instance.
-- @param px number Current screen X coordinate.
-- @param py number Current screen Y coordinate.
-- @param grid_w number Total board columns.
-- @param grid_h number Total board rows.
-- @return table|nil event Action record {action = 'swap_commit', from, to} or nil if below threshold.
function input_controller.on_touch_move(state, px, py, grid_w, grid_h)
    if not state.is_active then
        return nil
    end

    local dx = px - state.start_px
    local dy = py - state.start_py
    local dist_sq = dx * dx + dy * dy

    if dist_sq < (input_controller.SWIPE_THRESHOLD * input_controller.SWIPE_THRESHOLD) then
        return nil
    end

    -- Determine dominant swipe axis
    local target_gx = state.start_gx
    local target_gy = state.start_gy

    if math.abs(dx) >= math.abs(dy) then
        -- Horizontal swipe
        local step = (dx > 0) and 1 or -1
        target_gx = target_gx + step
    else
        -- Vertical swipe: In Defold, dy > 0 is upward on screen (gy - 1 in grid)
        local step = (dy > 0) and -1 or 1
        target_gy = target_gy + step
    end

    local commit_event = {
        action = "swap_commit",
        from = {x = state.start_gx, y = state.start_gy},
        to = {x = target_gx, y = target_gy}
    }

    -- Reset state so the swap commits exactly once per drag gesture
    state.is_active = false

    -- Check if target is inside board bounds
    if target_gx >= 1 and target_gx <= grid_w and target_gy >= 1 and target_gy <= grid_h then
        return commit_event
    end

    return nil
end

--- Handles touch release up event.
-- If released without exceeding swipe threshold, interprets gesture as a direct tap.
-- @param state table Input controller state instance.
-- @return table|nil event Action record {action = 'tap', gx, gy} or nil if inactive.
function input_controller.on_touch_up(state)
    if not state.is_active then
        return nil
    end

    local tap_event = {
        action = "tap",
        gx = state.start_gx,
        gy = state.start_gy
    }

    state.is_active = false
    return tap_event
end

return input_controller
