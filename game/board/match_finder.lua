--- Match detection algorithm for match-3, match-4, match-5, T/L-shapes, and 2x2 squares.
-- Validates player swaps and classifies match patterns into power-up creations.
local cell = require("game.board.cell")
local grid = require("game.board.grid")

local match_finder = {}

match_finder.PATTERN_MATCH_3 = "match_3"
match_finder.PATTERN_ROCKET_H = "rocket_h"
match_finder.PATTERN_ROCKET_V = "rocket_v"
match_finder.PATTERN_BOMB = "bomb"
match_finder.PATTERN_FIREFLY = "firefly"
match_finder.PATTERN_LANTERN = "lantern"

--- Scans the board for all horizontal color runs of 3 or more.
-- @param g table The grid instance.
-- @return table list of horizontal line tables: {tile_type, cells = {{x, y}, ...}}
local function find_horizontal_lines(g)
    local lines = {}
    for y = 1, g.height do
        local run_color = nil
        local run_cells = {}

        for x = 1, g.width do
            local c = grid.get(g, x, y)
            local matchable = c and cell.is_matchable(c)
            local current_color = matchable and c.tile_type or nil

            if current_color and current_color == run_color then
                table.insert(run_cells, {x = x, y = y})
            else
                if #run_cells >= 3 then
                    table.insert(lines, {tile_type = run_color, cells = run_cells, is_horizontal = true})
                end
                run_color = current_color
                run_cells = current_color and {{x = x, y = y}} or {}
            end
        end

        if #run_cells >= 3 then
            table.insert(lines, {tile_type = run_color, cells = run_cells, is_horizontal = true})
        end
    end
    return lines
end

--- Scans the board for all vertical color runs of 3 or more.
-- @param g table The grid instance.
-- @return table list of vertical line tables: {tile_type, cells = {{x, y}, ...}}
local function find_vertical_lines(g)
    local lines = {}
    for x = 1, g.width do
        local run_color = nil
        local run_cells = {}

        for y = 1, g.height do
            local c = grid.get(g, x, y)
            local matchable = c and cell.is_matchable(c)
            local current_color = matchable and c.tile_type or nil

            if current_color and current_color == run_color then
                table.insert(run_cells, {x = x, y = y})
            else
                if #run_cells >= 3 then
                    table.insert(lines, {tile_type = run_color, cells = run_cells, is_horizontal = false})
                end
                run_color = current_color
                run_cells = current_color and {{x = x, y = y}} or {}
            end
        end

        if #run_cells >= 3 then
            table.insert(lines, {tile_type = run_color, cells = run_cells, is_horizontal = false})
        end
    end
    return lines
end

--- Scans the board for all 2x2 square matches of identical color.
-- @param g table The grid instance.
-- @return table list of 2x2 square tables: {tile_type, cells = {{x, y}, ...}}
local function find_2x2_squares(g)
    local squares = {}
    for y = 1, g.height - 1 do
        for x = 1, g.width - 1 do
            local c1 = grid.get(g, x, y)
            local c2 = grid.get(g, x + 1, y)
            local c3 = grid.get(g, x, y + 1)
            local c4 = grid.get(g, x + 1, y + 1)

            if cell.is_matchable(c1) and cell.is_matchable(c2) and
               cell.is_matchable(c3) and cell.is_matchable(c4) then
                local col = c1.tile_type
                if c2.tile_type == col and c3.tile_type == col and c4.tile_type == col then
                    table.insert(squares, {
                        tile_type = col,
                        cells = {{x = x, y = y}, {x = x + 1, y = y}, {x = x, y = y + 1}, {x = x + 1, y = y + 1}}
                    })
                end
            end
        end
    end
    return squares
end

--- Classifies a set of intersecting or standalone lines into match events and powerup creations.
-- @param h_lines table List of horizontal lines.
-- @param v_lines table List of vertical lines.
-- @param squares table List of 2x2 squares.
-- @param focal_point table|nil Target coordinate {x, y} if initiated by player swap.
-- @return table matched_groups Array of structured match results with powerup data.
local function resolve_match_patterns(h_lines, v_lines, squares, focal_point)
    local results = {}
    local cell_used = {}

    --- Generates a unique string hash key for 2D cell coordinates.
    -- @param x number Column index.
    -- @param y number Row index.
    -- @return string Coordinate key in format "x,y".
    local function key(x, y)
        return x .. "," .. y
    end

    -- 1. Check for T/L shapes (Intersections of H and V of identical color)
    local merged_intersections = {}
    for _, h in ipairs(h_lines) do
        for _, v in ipairs(v_lines) do
            if h.tile_type == v.tile_type then
                -- Check for intersection
                local inter_x, inter_y = nil, nil
                for _, hc in ipairs(h.cells) do
                    for _, vc in ipairs(v.cells) do
                        if hc.x == vc.x and hc.y == vc.y then
                            inter_x, inter_y = hc.x, hc.y
                            break
                        end
                    end
                    if inter_x then break end
                end

                if inter_x then
                    -- Union of cells
                    local combined = {}
                    local set = {}
                    for _, c in ipairs(h.cells) do
                        local k = key(c.x, c.y)
                        if not set[k] then set[k] = true; table.insert(combined, c) end
                    end
                    for _, c in ipairs(v.cells) do
                        local k = key(c.x, c.y)
                        if not set[k] then set[k] = true; table.insert(combined, c) end
                    end

                    table.insert(merged_intersections, {
                        tile_type = h.tile_type,
                        cells = combined,
                        pattern = match_finder.PATTERN_BOMB,
                        spawn_pos = (focal_point and set[key(focal_point.x, focal_point.y)]) and focal_point or {x = inter_x, y = inter_y},
                        h_ref = h,
                        v_ref = v
                    })
                end
            end
        end
    end

    -- Add bomb results and mark source lines
    local consumed_lines = {}
    for _, bomb in ipairs(merged_intersections) do
        if not consumed_lines[bomb.h_ref] and not consumed_lines[bomb.v_ref] then
            consumed_lines[bomb.h_ref] = true
            consumed_lines[bomb.v_ref] = true
            table.insert(results, {
                pattern = bomb.pattern,
                tile_type = bomb.tile_type,
                cells = bomb.cells,
                created_powerup = "bomb",
                spawn_pos = bomb.spawn_pos
            })
            for _, c in ipairs(bomb.cells) do cell_used[key(c.x, c.y)] = true end
        end
    end

    -- 2. Process remaining linear matches (H and V)
    local all_lines = {}
    for _, h in ipairs(h_lines) do if not consumed_lines[h] then table.insert(all_lines, h) end end
    for _, v in ipairs(v_lines) do if not consumed_lines[v] then table.insert(all_lines, v) end end

    for _, line in ipairs(all_lines) do
        local count = #line.cells
        local pattern = match_finder.PATTERN_MATCH_3
        local powerup = nil
        local spawn_pos = nil

        if count >= 5 then
            pattern = match_finder.PATTERN_LANTERN
            powerup = "lantern"
        elseif count == 4 then
            if line.is_horizontal then
                pattern = match_finder.PATTERN_ROCKET_H
                powerup = "rocket_h"
            else
                pattern = match_finder.PATTERN_ROCKET_V
                powerup = "rocket_v"
            end
        end

        if powerup then
            -- Position powerup at focal point if inside the line, else middle
            local has_focal = false
            if focal_point then
                for _, c in ipairs(line.cells) do
                    if c.x == focal_point.x and c.y == focal_point.y then
                        has_focal = true
                        break
                    end
                end
            end
            spawn_pos = has_focal and focal_point or line.cells[math.ceil(count / 2)]
        end

        table.insert(results, {
            pattern = pattern,
            tile_type = line.tile_type,
            cells = line.cells,
            created_powerup = powerup,
            spawn_pos = spawn_pos
        })
        for _, c in ipairs(line.cells) do cell_used[key(c.x, c.y)] = true end
    end

    -- 3. Process 2x2 squares
    for _, sq in ipairs(squares) do
        -- Only accept if cells aren't already absorbed into a bigger combo
        local overlaps = false
        for _, c in ipairs(sq.cells) do
            if cell_used[key(c.x, c.y)] then
                overlaps = true
                break
            end
        end

        if not overlaps then
            for _, c in ipairs(sq.cells) do cell_used[key(c.x, c.y)] = true end
            local spawn_pos = focal_point
            if not spawn_pos then
                spawn_pos = sq.cells[1]
            end
            table.insert(results, {
                pattern = match_finder.PATTERN_FIREFLY,
                tile_type = sq.tile_type,
                cells = sq.cells,
                created_powerup = "firefly",
                spawn_pos = spawn_pos
            })
        end
    end

    return results
end

--- Scans the entire board and returns all active matches.
-- @param g table The grid instance.
-- @param focal_point table|nil Optional {x, y} coordinate of the initiated swap.
-- @return table results List of all detected match groups.
function match_finder.find_all_matches(g, focal_point)
    local h_lines = find_horizontal_lines(g)
    local v_lines = find_vertical_lines(g)
    local squares = find_2x2_squares(g)
    return resolve_match_patterns(h_lines, v_lines, squares, focal_point)
end

--- Evaluates whether a swap between two adjacent cells produces a legal move.
-- In Royal Match:
-- 1. If either cell is a power-up, swap is ALWAYS legal!
-- 2. Otherwise, simulates the swap and checks if at least one match is produced.
-- Restores original grid state before returning.
-- @param g table The grid instance.
-- @param x1 number Initiating column.
-- @param y1 number Initiating row.
-- @param x2 number Target column.
-- @param y2 number Target row.
-- @return boolean is_valid True if swap produces matches or activates power-ups.
-- @return table|nil matches Array of match results or nil if invalid.
-- @return boolean is_powerup_activation True if this is a direct power-up swap.
function match_finder.is_valid_swap(g, x1, y1, x2, y2)
    if not grid.can_swap(g, x1, y1, x2, y2) then
        return false, nil, false
    end

    local c1 = grid.get(g, x1, y1)
    local c2 = grid.get(g, x2, y2)

    -- Rule: Any swap involving at least one power-up is unconditionally legal!
    if c1.powerup_type ~= nil or c2.powerup_type ~= nil then
        return true, nil, true
    end

    -- Speculatively execute the swap
    grid.swap(g, x1, y1, x2, y2)

    -- Check if matches result from this swap (focal point is the target coordinate)
    local matches = match_finder.find_all_matches(g, {x = x2, y = y2})

    -- Revert speculative swap
    grid.swap(g, x1, y1, x2, y2)

    if #matches > 0 then
        return true, matches, false
    end

    return false, nil, false
end

return match_finder
