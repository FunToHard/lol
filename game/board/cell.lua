--- Cell module representing a single coordinate slot on the match-3 board.
-- Manages individual cell states, tile contents, and spatial swap validity.
local cell = {}

cell.STATE_IDLE = "idle"
cell.STATE_SWAPPING = "swapping"
cell.STATE_MATCHED = "matched"
cell.STATE_FALLING = "falling"
cell.STATE_SPAWNING = "spawning"
cell.STATE_DISABLED = "disabled"

--- Creates a new cell instance at the given grid coordinates.
-- @param x number Column index (1-indexed).
-- @param y number Row index (1-indexed).
-- @param is_enabled boolean Optional flag if cell is active (default true).
-- @return table cell_instance The initialized cell data table.
function cell.new(x, y, is_enabled)
    local enabled = is_enabled ~= false
    return {
        x = x,
        y = y,
        state = enabled and cell.STATE_IDLE or cell.STATE_DISABLED,
        tile_type = nil,
        powerup_type = nil,
        obstacle = nil,
        is_enabled = enabled
    }
end

--- Checks if a cell is currently available for player interaction and swapping.
-- @param c table The cell instance to check.
-- @return boolean is_swappable True if cell is enabled, idle, and has content.
function cell.is_swappable(c)
    if not c or not c.is_enabled then
        return false
    end
    if c.state ~= cell.STATE_IDLE then
        return false
    end
    -- Cell must have either a regular tile or a powerup to be swappable
    return (c.tile_type ~= nil) or (c.powerup_type ~= nil)
end

--- Checks if a cell can participate in standard line match detection.
-- @param c table The cell instance to check.
-- @return boolean is_matchable True if cell has a regular color tile and is idle.
function cell.is_matchable(c)
    if not c or not c.is_enabled then
        return false
    end
    return c.state == cell.STATE_IDLE and c.tile_type ~= nil and c.obstacle == nil
end

--- Checks if a cell allows falling pieces to pass through or settle in it.
-- @param c table The cell instance to check.
-- @return boolean can_fall True if the cell is enabled and not blocked by a solid obstacle.
function cell.can_fall_into(c)
    if not c or not c.is_enabled then
        return false
    end
    if c.obstacle and c.obstacle.is_solid then
        return false
    end
    return c.tile_type == nil and c.powerup_type == nil and c.state == cell.STATE_IDLE
end

--- Updates the lifecycle state of a cell.
-- @param c table The cell instance to update.
-- @param new_state string One of cell.STATE_* constants.
function cell.set_state(c, new_state)
    assert(c ~= nil, "Cell must not be nil")
    assert(new_state ~= nil, "State must not be nil")
    c.state = new_state
end

--- Clears tile and powerup contents from a cell, leaving obstacles intact.
-- @param c table The cell instance to clear.
function cell.clear_content(c)
    if not c then return end
    c.tile_type = nil
    c.powerup_type = nil
    c.state = c.is_enabled and cell.STATE_IDLE or cell.STATE_DISABLED
end

return cell
