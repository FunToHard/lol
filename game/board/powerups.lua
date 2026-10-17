--- Power-up activation engine and combo fusion interaction matrix.
-- Evaluates single detonations and dual-powerup combinations (Royal Match rules).
local cell = require("game.board.cell")
local grid = require("game.board.grid")

local powerups = {}

--- Generates a unique string hash key for coordinates.
-- @param x number Column index.
-- @param y number Row index.
-- @return string Coordinate key in format "x,y".
local function key(x, y)
    return x .. "," .. y
end

--- Gathers all cells in the specified horizontal row.
-- @param g table The grid instance.
-- @param y number Row index.
-- @return table Array of cell coordinates {x, y}.
local function get_row_cells(g, y)
    local cells = {}
    for x = 1, g.width do
        local c = grid.get(g, x, y)
        if c and c.is_enabled then
            table.insert(cells, {x = x, y = y})
        end
    end
    return cells
end

--- Gathers all cells in the specified vertical column.
-- @param g table The grid instance.
-- @param x number Column index.
-- @return table Array of cell coordinates {x, y}.
local function get_col_cells(g, x)
    local cells = {}
    for y = 1, g.height do
        local c = grid.get(g, x, y)
        if c and c.is_enabled then
            table.insert(cells, {x = x, y = y})
        end
    end
    return cells
end

--- Gathers cells in a square/circle radius around a center coordinate.
-- @param g table The grid instance.
-- @param cx number Center column.
-- @param cy number Center row.
-- @param radius number Distance radius in cells.
-- @return table Array of cell coordinates {x, y}.
local function get_area_cells(g, cx, cy, radius)
    local cells = {}
    for y = math.max(1, cy - radius), math.min(g.height, cy + radius) do
        for x = math.max(1, cx - radius), math.min(g.width, cx + radius) do
            local c = grid.get(g, x, y)
            if c and c.is_enabled then
                table.insert(cells, {x = x, y = y})
            end
        end
    end
    return cells
end

--- Finds all cells currently holding regular tiles matching the specified color.
-- @param g table The grid instance.
-- @param color string Tile color token.
-- @return table Array of cell coordinates {x, y}.
local function get_cells_by_color(g, color)
    local cells = {}
    for y = 1, g.height do
        for x = 1, g.width do
            local c = grid.get(g, x, y)
            if c and c.is_enabled and c.tile_type == color then
                table.insert(cells, {x = x, y = y})
            end
        end
    end
    return cells
end

--- Finds the most populous regular tile color currently on the board.
-- @param g table The grid instance.
-- @return string color Most common color token.
local function get_most_populous_color(g)
    local counts = {}
    local best_color = "amber"
    local best_count = -1

    for y = 1, g.height do
        for x = 1, g.width do
            local c = grid.get(g, x, y)
            if c and c.is_enabled and c.tile_type then
                counts[c.tile_type] = (counts[c.tile_type] or 0) + 1
                if counts[c.tile_type] > best_count then
                    best_count = counts[c.tile_type]
                    best_color = c.tile_type
                end
            end
        end
    end
    return best_color
end

--- Selects target coordinates for a firefly flight (picks random non-empty cell).
-- @param g table The grid instance.
-- @param exclude_set table Coordinates to avoid targeting.
-- @return table coordinate {x, y}.
local function find_firefly_target(g, exclude_set)
    local candidates = {}
    for y = 1, g.height do
        for x = 1, g.width do
            local k = key(x, y)
            if not exclude_set[k] then
                local c = grid.get(g, x, y)
                if c and c.is_enabled and (c.tile_type or c.powerup_type or c.obstacle) then
                    table.insert(candidates, {x = x, y = y})
                end
            end
        end
    end
    if #candidates > 0 then
        return candidates[math.random(#candidates)]
    end
    return {x = math.floor(g.width / 2), y = math.floor(g.height / 2)}
end

--- Evaluates the detonation of a single tapped power-up.
-- @param g table The grid instance.
-- @param x number Column index of the power-up.
-- @param y number Row index of the power-up.
-- @return table detonation_event List of destroyed cells and visual effect details.
function powerups.detonate_single(g, x, y)
    local c = grid.get(g, x, y)
    assert(c and c.powerup_type, "Cell does not contain a power-up")
    local p_type = c.powerup_type
    local affected = {}

    if p_type == "rocket_h" then
        affected = get_row_cells(g, y)
    elseif p_type == "rocket_v" then
        affected = get_col_cells(g, x)
    elseif p_type == "bomb" then
        affected = get_area_cells(g, x, y, 2)
    elseif p_type == "firefly" then
        -- 1-radius cross immediate, plus guided hit on target
        local local_cells = {{x = x, y = y}, {x = x + 1, y = y}, {x = x - 1, y = y}, {x = x, y = y + 1}, {x = x, y = y - 1}}
        for _, pos in ipairs(local_cells) do
            if grid.is_inside(g, pos.x, pos.y) then table.insert(affected, pos) end
        end
        local target = find_firefly_target(g, {[key(x, y)] = true})
        table.insert(affected, target)
    elseif p_type == "lantern" then
        local most_common = get_most_populous_color(g)
        affected = get_cells_by_color(g, most_common)
        table.insert(affected, {x = x, y = y})
    end

    -- Clear all affected cells from grid
    for _, pos in ipairs(affected) do
        local target_c = grid.get(g, pos.x, pos.y)
        if target_c then cell.clear_content(target_c) end
    end

    return {
        type = "single_detonation",
        powerup_type = p_type,
        origin = {x = x, y = y},
        affected_cells = affected,
        cleared_cells = affected
    }
end

--- Evaluates a swap between a Magic Lantern and a regular color tile.
-- Destroys all tiles of that swapped color across the entire board.
-- @param g table The grid instance.
-- @param lx number Lantern column.
-- @param ly number Lantern row.
-- @param tx number Target tile column.
-- @param ty number Target tile row.
-- @return table detonation_event Details of color clear.
function powerups.detonate_lantern_color(g, lx, ly, tx, ty)
    local target_cell = grid.get(g, tx, ty)
    local color = target_cell and target_cell.tile_type or "amber"
    local affected = get_cells_by_color(g, color)
    table.insert(affected, {x = lx, y = ly})

    for _, pos in ipairs(affected) do
        local c = grid.get(g, pos.x, pos.y)
        if c then cell.clear_content(c) end
    end

    return {
        type = "lantern_color_clear",
        color = color,
        origin = {x = lx, y = ly},
        affected_cells = affected,
        cleared_cells = affected
    }
end

--- Evaluates a combo fusion between two adjacent power-ups swapped together.
-- Implements the 10 combination matrix from game charter.
-- @param g table The grid instance.
-- @param x1 number Initiating power-up column.
-- @param y1 number Initiating power-up row.
-- @param x2 number Target power-up column.
-- @param y2 number Target power-up row.
-- @return table combo_event Details of the combined blast and affected cells.
function powerups.detonate_combo(g, x1, y1, x2, y2)
    local c1 = grid.get(g, x1, y1)
    local c2 = grid.get(g, x2, y2)
    assert(c1 and c2 and c1.powerup_type and c2.powerup_type, "Both cells must contain power-ups for combo")

    local p1 = c1.powerup_type
    local p2 = c2.powerup_type

    --- Checks if combo participants match two target power-up types in any order.
    -- @param t1 string First powerup type.
    -- @param t2 string Second powerup type.
    -- @return boolean True if types match.
    local function is_pair(t1, t2)
        return (p1 == t1 and p2 == t2) or (p1 == t2 and p2 == t1)
    end

    --- Tests if a power-up token is any variant of rocket.
    -- @param t string Powerup token.
    -- @return boolean True if horizontal or vertical rocket.
    local function is_rocket(t)
        return t == "rocket_h" or t == "rocket_v"
    end

    local affected = {}
    local combo_name = ""
    local set = {}

    --- Appends coordinates to the affected blast set without duplicates.
    -- @param cells table Array of coordinates {x, y}.
    local function add(cells)
        for _, pos in ipairs(cells) do
            local k = key(pos.x, pos.y)
            if not set[k] and grid.is_inside(g, pos.x, pos.y) then
                set[k] = true
                table.insert(affected, pos)
            end
        end
    end

    -- Fusion center is target cell (x2, y2)
    local cx, cy = x2, y2

    if is_rocket(p1) and is_rocket(p2) then
        combo_name = "rocket_rocket"
        add(get_row_cells(g, cy))
        add(get_col_cells(g, cx))

    elseif (is_rocket(p1) and p2 == "bomb") or (p1 == "bomb" and is_rocket(p2)) then
        combo_name = "rocket_bomb"
        -- 3 rows and 3 columns mega cross
        for dy = -1, 1 do add(get_row_cells(g, cy + dy)) end
        for dx = -1, 1 do add(get_col_cells(g, cx + dx)) end

    elseif (is_rocket(p1) and p2 == "firefly") or (p1 == "firefly" and is_rocket(p2)) then
        combo_name = "rocket_firefly"
        local target = find_firefly_target(g, {[key(x1, y1)] = true, [key(x2, y2)] = true})
        add(get_row_cells(g, target.y))
        add(get_col_cells(g, target.x))
        add({{x = x1, y = y1}, {x = x2, y = y2}})

    elseif p1 == "bomb" and p2 == "bomb" then
        combo_name = "bomb_bomb"
        add(get_area_cells(g, cx, cy, 3)) -- Massive 7x7 blast

    elseif (p1 == "bomb" and p2 == "firefly") or (p1 == "firefly" and p2 == "bomb") then
        combo_name = "bomb_firefly"
        local target = find_firefly_target(g, {[key(x1, y1)] = true, [key(x2, y2)] = true})
        add(get_area_cells(g, target.x, target.y, 2)) -- 5x5 blast at target
        add({{x = x1, y = y1}, {x = x2, y = y2}})

    elseif p1 == "firefly" and p2 == "firefly" then
        combo_name = "firefly_firefly"
        add({{x = x1, y = y1}, {x = x2, y = y2}})
        for _ = 1, 3 do
            local target = find_firefly_target(g, set)
            add(get_area_cells(g, target.x, target.y, 1))
        end

    elseif p1 == "lantern" and p2 == "lantern" then
        combo_name = "lantern_lantern"
        -- Ultimate board wipe: clears every active cell
        for y = 1, g.height do
            for x = 1, g.width do
                add({{x = x, y = y}})
            end
        end

    elseif p1 == "lantern" or p2 == "lantern" then
        local other_powerup = (p1 == "lantern") and p2 or p1
        combo_name = "lantern_" .. other_powerup
        local color = get_most_populous_color(g)
        local target_cells = get_cells_by_color(g, color)
        add({{x = x1, y = y1}, {x = x2, y = y2}})

        -- Converts all matching cells to the other powerup and detonates them
        for _, pos in ipairs(target_cells) do
            if is_rocket(other_powerup) then
                add(get_row_cells(g, pos.y))
                add(get_col_cells(g, pos.x))
            elseif other_powerup == "bomb" then
                add(get_area_cells(g, pos.x, pos.y, 2))
            elseif other_powerup == "firefly" then
                add(get_area_cells(g, pos.x, pos.y, 1))
            end
        end
    end

    -- Clear all affected cells from grid
    for _, pos in ipairs(affected) do
        local target_c = grid.get(g, pos.x, pos.y)
        if target_c then cell.clear_content(target_c) end
    end

    return {
        type = "combo_fusion",
        combo = combo_name,
        origin = {x = cx, y = cy},
        affected_cells = affected,
        cleared_cells = affected
    }
end

return powerups
