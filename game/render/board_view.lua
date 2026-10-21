--- Board view module managing visual coordinate transformations and sprite mappings.
-- Converts between grid coordinates and 720x1280 mobile screen space.
local board_view = {}

-- Visual layout constants for 720x1280 mobile portrait display
board_view.SCREEN_WIDTH = 720
board_view.SCREEN_HEIGHT = 1280
board_view.TILE_SIZE = 76
board_view.TILE_GAP = 6
board_view.CELL_PITCH = board_view.TILE_SIZE + board_view.TILE_GAP -- 82px

-- Animation timing constants (Royal Match snappy pacing)
board_view.SWAP_DURATION = 0.16
board_view.FALL_SPEED = 1800 -- pixels per second
board_view.SQUASH_DURATION = 0.08
board_view.SQUASH_SCALE_X = 1.15
board_view.SQUASH_SCALE_Y = 0.85

--- Computes the origin (bottom-left) of the board grid in Defold screen space.
-- Centers the board horizontally and places it in the lower-mid playfield.
-- @param grid_width number Columns count.
-- @param grid_height number Rows count.
-- @param custom_center_y number|nil Optional vertical center (default 520).
-- @return number origin_x Pixel X of cell (1, height).
-- @return number origin_y Pixel Y of cell (1, height).
function board_view.get_board_origin(grid_width, grid_height, custom_center_y)
    local total_w = grid_width * board_view.CELL_PITCH - board_view.TILE_GAP
    local total_h = grid_height * board_view.CELL_PITCH - board_view.TILE_GAP
    local center_y = custom_center_y or 520

    local origin_x = (board_view.SCREEN_WIDTH - total_w) / 2 + (board_view.TILE_SIZE / 2)
    -- In Defold, (0,0) is bottom-left. Row 1 is top, row height is bottom.
    local origin_y = center_y - (total_h / 2) + (board_view.TILE_SIZE / 2)
    return origin_x, origin_y
end

--- Converts grid coordinates (col, row) into screen pixel coordinates (x, y).
-- Row 1 is the top row, Row `grid_height` is the bottom row.
-- @param gx number Column (1-indexed).
-- @param gy number Row (1-indexed).
-- @param grid_width number Total grid columns.
-- @param grid_height number Total grid rows.
-- @param custom_center_y number|nil Optional vertical center.
-- @return number screen_x Screen pixel coordinate X.
-- @return number screen_y Screen pixel coordinate Y.
function board_view.grid_to_screen(gx, gy, grid_width, grid_height, custom_center_y)
    local origin_x, origin_y = board_view.get_board_origin(grid_width, grid_height, custom_center_y)
    local px = origin_x + (gx - 1) * board_view.CELL_PITCH
    -- Invert Y so gy=1 is top, gy=height is bottom
    local py = origin_y + (grid_height - gy) * board_view.CELL_PITCH
    return px, py
end

--- Converts screen pixel coordinates (x, y) into grid coordinates (col, row).
-- Returns nil, nil if the touch falls outside active board bounds.
-- @param px number Touch screen X coordinate.
-- @param py number Touch screen Y coordinate.
-- @param grid_width number Total grid columns.
-- @param grid_height number Total grid rows.
-- @param custom_center_y number|nil Optional vertical center.
-- @return number|nil grid_x Column (1-indexed) or nil if out of bounds.
-- @return number|nil grid_y Row (1-indexed) or nil if out of bounds.
function board_view.screen_to_grid(px, py, grid_width, grid_height, custom_center_y)
    local origin_x, origin_y = board_view.get_board_origin(grid_width, grid_height, custom_center_y)
    local half_cell = board_view.CELL_PITCH / 2

    local rel_x = px - (origin_x - half_cell)
    local rel_y = py - (origin_y - half_cell)

    if rel_x < 0 or rel_y < 0 then
        return nil, nil
    end

    local gx = math.floor(rel_x / board_view.CELL_PITCH) + 1
    local gy_inverted = math.floor(rel_y / board_view.CELL_PITCH)
    local gy = grid_height - gy_inverted

    if gx >= 1 and gx <= grid_width and gy >= 1 and gy <= grid_height then
        return gx, gy
    end

    return nil, nil
end

--- Maps a piece or powerup token into its corresponding sprite frame name in game.atlas.
-- @param tile_type string|nil Color token ('amber', 'emerald', etc.).
-- @param powerup_type string|nil Powerup token ('rocket_h', 'bomb', etc.).
-- @param obstacle table|nil Obstacle state table.
-- @return string animation_id The frame name in game.atlas.
function board_view.get_sprite_name(tile_type, powerup_type, obstacle)
    if obstacle then
        if obstacle.type == "bramble" then
            return "obstacle_bramble_" .. tostring(math.max(1, obstacle.layer))
        elseif obstacle.type == "stone" then
            return "obstacle_stone_" .. tostring(math.max(1, obstacle.layer))
        elseif obstacle.type == "ingredient" then
            return "ingredient_acorn"
        end
    end

    if powerup_type then
        return "powerup_" .. powerup_type
    end

    if tile_type then
        return "piece_" .. tile_type
    end

    return "cell_slot"
end

return board_view
