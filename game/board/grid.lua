--- Grid matrix module managing 2D board coordinates, bounds, and spatial swaps.
-- Pure Lua with zero Defold engine dependencies.
local cell = require("game.board.cell")

local grid = {}

--- Creates a new 2D board grid with specified dimensions and optional shape mask.
-- @param width number Total number of columns.
-- @param height number Total number of rows.
-- @param mask table|nil Optional 2D array or string list where 1/true is active, 0/false is hole.
-- @return table grid_instance The initialized grid table containing matrix and dimensions.
function grid.create(width, height, mask)
    assert(width > 0 and height > 0, "Grid dimensions must be positive integers")
    local g = {
        width = width,
        height = height,
        cells = {}
    }

    for y = 1, height do
        g.cells[y] = {}
        for x = 1, width do
            local is_enabled = true
            if mask then
                if type(mask[y]) == "string" then
                    local char = mask[y]:sub(x, x)
                    is_enabled = (char == "1" or char == "x" or char == "X")
                elseif type(mask[y]) == "table" then
                    is_enabled = (mask[y][x] == 1 or mask[y][x] == true)
                end
            end
            g.cells[y][x] = cell.new(x, y, is_enabled)
        end
    end

    return g
end

--- Checks if given coordinates lie within the grid matrix boundaries.
-- @param g table The grid instance.
-- @param x number Column index (1-indexed).
-- @param y number Row index (1-indexed).
-- @return boolean is_inside True if coordinates are inside the grid dimensions.
function grid.is_inside(g, x, y)
    if not g or not x or not y then return false end
    return x >= 1 and x <= g.width and y >= 1 and y <= g.height
end

--- Retrieves the cell at the specified coordinates, or nil if out of bounds.
-- @param g table The grid instance.
-- @param x number Column index (1-indexed).
-- @param y number Row index (1-indexed).
-- @return table|nil cell_obj The cell instance or nil if out of bounds.
function grid.get(g, x, y)
    if not grid.is_inside(g, x, y) then
        return nil
    end
    return g.cells[y][x]
end

--- Checks if two coordinates are directly adjacent orthogonally (Manhattan distance == 1).
-- @param x1 number First column.
-- @param y1 number First row.
-- @param x2 number Second column.
-- @param y2 number Second row.
-- @return boolean is_adj True if adjacent horizontally or vertically, false for diagonals.
function grid.is_adjacent(x1, y1, x2, y2)
    local dx = math.abs(x1 - x2)
    local dy = math.abs(y1 - y2)
    return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)
end

--- Validates if a swap between two coordinates is permitted by spatial cell states.
-- Requires both cells to be inside, adjacent, enabled, and in IDLE state with content.
-- @param g table The grid instance.
-- @param x1 number Source column.
-- @param y1 number Source row.
-- @param x2 number Target column.
-- @param y2 number Target row.
-- @return boolean can_swap True if the swap interaction can initiate.
function grid.can_swap(g, x1, y1, x2, y2)
    if not grid.is_inside(g, x1, y1) or not grid.is_inside(g, x2, y2) then
        return false
    end
    if not grid.is_adjacent(x1, y1, x2, y2) then
        return false
    end
    local c1 = grid.get(g, x1, y1)
    local c2 = grid.get(g, x2, y2)
    return cell.is_swappable(c1) and cell.is_swappable(c2)
end

--- Swaps the tile and powerup contents between two cells.
-- @param g table The grid instance.
-- @param x1 number Source column.
-- @param y1 number Source row.
-- @param x2 number Target column.
-- @param y2 number Target row.
-- @return boolean success True if swap completed.
function grid.swap(g, x1, y1, x2, y2)
    local c1 = grid.get(g, x1, y1)
    local c2 = grid.get(g, x2, y2)
    if not c1 or not c2 then return false end

    local temp_tile = c1.tile_type
    local temp_powerup = c1.powerup_type

    c1.tile_type = c2.tile_type
    c1.powerup_type = c2.powerup_type

    c2.tile_type = temp_tile
    c2.powerup_type = temp_powerup

    return true
end

--- Sets tile type on a cell.
-- @param g table The grid instance.
-- @param x number Column index.
-- @param y number Row index.
-- @param tile_type string|nil Color token (e.g. 'amber', 'emerald') or nil.
function grid.set_tile(g, x, y, tile_type)
    local c = grid.get(g, x, y)
    if c and c.is_enabled then
        c.tile_type = tile_type
    end
end

--- Sets powerup type on a cell.
-- @param g table The grid instance.
-- @param x number Column index.
-- @param y number Row index.
-- @param powerup_type string|nil Powerup token (e.g. 'rocket_h', 'bomb') or nil.
function grid.set_powerup(g, x, y, powerup_type)
    local c = grid.get(g, x, y)
    if c and c.is_enabled then
        c.powerup_type = powerup_type
    end
end

--- Generates a compact text visualization of the current grid contents for debugging.
-- @param g table The grid instance.
-- @return string representation Multiline string showing piece initials.
function grid.to_debug_string(g)
    local rows = {}
    for y = 1, g.height do
        local chars = {}
        for x = 1, g.width do
            local c = g.cells[y][x]
            if not c.is_enabled then
                table.insert(chars, " # ")
            elseif c.powerup_type then
                table.insert(chars, " " .. c.powerup_type:sub(1, 1):upper() .. " ")
            elseif c.tile_type then
                table.insert(chars, " " .. c.tile_type:sub(1, 1) .. " ")
            else
                table.insert(chars, " . ")
            end
        end
        table.insert(rows, table.concat(chars, ""))
    end
    return table.concat(rows, "\n")
end

return grid
