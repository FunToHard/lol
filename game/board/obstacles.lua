--- Obstacle lifecycle and damage resolution engine.
-- Manages layered brambles, solid river stones, and falling collection ingredients.
local cell = require("game.board.cell")
local grid = require("game.board.grid")

local obstacles = {}

--- Generates a unique string hash key for coordinates.
-- @param x number Column index.
-- @param y number Row index.
-- @return string Coordinate key in format "x,y".
local function key(x, y)
    return x .. "," .. y
end

--- Creates a new obstacle definition table.
-- @param obs_type string Obstacle identifier ('bramble', 'stone', 'ingredient').
-- @param layer number Number of damage hits required (1 or 2).
-- @param is_solid boolean If true, prevents gravity drops passing through.
-- @return table obstacle_data Table containing obstacle properties.
function obstacles.create(obs_type, layer, is_solid)
    return {
        type = obs_type,
        layer = layer or 1,
        max_layer = layer or 1,
        is_solid = is_solid == true
    }
end

--- Applies damage to an obstacle on a cell.
-- @param c table The cell instance.
-- @param amount number|nil Amount of damage (default 1).
-- @return boolean was_damaged True if an obstacle took damage.
-- @return boolean was_destroyed True if the obstacle reached 0 layers and was removed.
function obstacles.damage_cell(c, amount)
    if not c or not c.obstacle then
        return false, false
    end

    local dmg = amount or 1
    local obs = c.obstacle
    obs.layer = obs.layer - dmg

    if obs.layer <= 0 then
        local destroyed_type = obs.type
        c.obstacle = nil
        return true, true, destroyed_type
    else
        -- Degrade solid state if cracked
        if obs.type == "stone" and obs.layer == 1 then
            obs.is_solid = false
        end
        return true, false, obs.type
    end
end

--- Scans cells orthogonally adjacent to cleared matches and damages neighboring obstacles.
-- In match-3, making a match next to a crate/bramble damages it by 1 layer.
-- @param g table The grid instance.
-- @param matches table Array of match results from match_finder.
-- @return table damaged_list Array of {x, y, type, destroyed = bool, remaining_layer = num}.
function obstacles.damage_adjacent(g, matches)
    local damaged = {}
    local damaged_set = {}
    local offsets = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}

    for _, m in ipairs(matches) do
        for _, pos in ipairs(m.cells) do
            for _, off in ipairs(offsets) do
                local nx, ny = pos.x + off[1], pos.y + off[2]
                local k = key(nx, ny)

                if not damaged_set[k] and grid.is_inside(g, nx, ny) then
                    local target_cell = grid.get(g, nx, ny)
                    if target_cell and target_cell.obstacle and target_cell.obstacle.type ~= "ingredient" then
                        damaged_set[k] = true
                        local was_dmg, was_dest, obs_type = obstacles.damage_cell(target_cell, 1)
                        if was_dmg then
                            table.insert(damaged, {
                                x = nx,
                                y = ny,
                                type = obs_type,
                                destroyed = was_dest,
                                remaining_layer = target_cell.obstacle and target_cell.obstacle.layer or 0
                            })
                        end
                    end
                end
            end
        end
    end

    return damaged
end

--- Applies direct blast damage to all obstacles within a power-up explosion footprint.
-- @param g table The grid instance.
-- @param affected_cells table Array of coordinates {x, y} hit by explosion.
-- @param damage_amount number|nil Blast damage value (default 1).
-- @return table damaged_list Array of {x, y, type, destroyed = bool, remaining_layer = num}.
function obstacles.damage_from_blast(g, affected_cells, damage_amount)
    local damaged = {}
    local dmg = damage_amount or 1
    local damaged_set = {}

    for _, pos in ipairs(affected_cells) do
        local k = key(pos.x, pos.y)
        if not damaged_set[k] and grid.is_inside(g, pos.x, pos.y) then
            local c = grid.get(g, pos.x, pos.y)
            if c and c.obstacle and c.obstacle.type ~= "ingredient" then
                damaged_set[k] = true
                local was_dmg, was_dest, obs_type = obstacles.damage_cell(c, dmg)
                if was_dmg then
                    table.insert(damaged, {
                        x = pos.x,
                        y = pos.y,
                        type = obs_type,
                        destroyed = was_dest,
                        remaining_layer = c.obstacle and c.obstacle.layer or 0
                    })
                end
            end
        end
    end

    return damaged
end

--- Checks the bottom-most row of the board for ingredients that have reached collection.
-- Removes collected ingredients from the board so goals can increment.
-- @param g table The grid instance.
-- @return table collected Array of {x, y, type}.
function obstacles.collect_bottom_ingredients(g)
    local collected = {}
    local bottom_y = g.height

    for x = 1, g.width do
        local c = grid.get(g, x, bottom_y)
        if c and c.obstacle and c.obstacle.type == "ingredient" then
            table.insert(collected, {
                x = x,
                y = bottom_y,
                type = c.obstacle.type
            })
            c.obstacle = nil
            c.state = cell.STATE_IDLE
        end
    end

    return collected
end

return obstacles
