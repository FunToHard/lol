--- Cascade resolution engine managing gravity drop, column refills, and chain reactions.
-- Emits structured event logs for visual renderers and sound managers to animate.
local cell = require("game.board.cell")
local grid = require("game.board.grid")
local match_finder = require("game.board.match_finder")
local prng = require("game.board.prng")

local cascade = {}

--- Clears matched tiles and places newly created power-ups at their designated spawn positions.
-- @param g table The grid instance.
-- @param matches table Array of match results from match_finder.
-- @return table clear_event Structured event containing destroyed cells and powerups spawned.
function cascade.apply_matches(g, matches)
    local destroyed_cells = {}
    local spawned_powerups = {}
    local cleared_set = {}

    --- Generates a unique string hash key for coordinates.
    -- @param x number Column index.
    -- @param y number Row index.
    -- @return string Coordinate key in format "x,y".
    local function key(x, y)
        return x .. "," .. y
    end

    for _, m in ipairs(matches) do
        -- Check if this match creates a power-up
        local p_pos = m.spawn_pos
        local p_type = m.created_powerup

        for _, c_pos in ipairs(m.cells) do
            local k = key(c_pos.x, c_pos.y)
            if not cleared_set[k] then
                cleared_set[k] = true
                local c = grid.get(g, c_pos.x, c_pos.y)

                -- If this cell is the designated powerup spawn position, don't clear it completely
                if p_type and p_pos and c_pos.x == p_pos.x and c_pos.y == p_pos.y then
                    c.tile_type = nil
                    c.powerup_type = p_type
                    c.state = cell.STATE_IDLE
                    table.insert(spawned_powerups, {pos = {x = c_pos.x, y = c_pos.y}, powerup_type = p_type})
                else
                    cell.clear_content(c)
                    table.insert(destroyed_cells, {x = c_pos.x, y = c_pos.y, tile_type = m.tile_type})
                end
            end
        end
    end

    return {
        type = "clear",
        destroyed = destroyed_cells,
        powerups = spawned_powerups
    }
end

--- Simulates vertical gravity: pieces drop into empty cells below them.
-- Scans each column from bottom (height) upward to 1.
-- @param g table The grid instance.
-- @return table falls Array of move records: {{from = {x, y}, to = {x, y}, tile_type, powerup_type}, ...}
function cascade.apply_gravity(g)
    local falls = {}

    for x = 1, g.width do
        -- Scan from bottom row upward
        for y = g.height, 1, -1 do
            local target_cell = grid.get(g, x, y)
            if cell.can_fall_into(target_cell) then
                -- Look upward for the first available falling piece
                local source_y = nil
                for search_y = y - 1, 1, -1 do
                    local candidate = grid.get(g, x, search_y)
                    if candidate and candidate.is_enabled then
                        -- If a solid obstacle blocks this column, stop searching upward
                        if candidate.obstacle and candidate.obstacle.is_solid then
                            break
                        end
                        if candidate.tile_type ~= nil or candidate.powerup_type ~= nil then
                            source_y = search_y
                            break
                        end
                    end
                end

                if source_y then
                    local source_cell = grid.get(g, x, source_y)
                    target_cell.tile_type = source_cell.tile_type
                    target_cell.powerup_type = source_cell.powerup_type
                    target_cell.state = cell.STATE_IDLE

                    cell.clear_content(source_cell)

                    table.insert(falls, {
                        from = {x = x, y = source_y},
                        to = {x = x, y = y},
                        tile_type = target_cell.tile_type,
                        powerup_type = target_cell.powerup_type
                    })
                end
            end
        end
    end

    return falls
end

--- Refills empty top cells in each column from spawners using the seeded PRNG.
-- @param g table The grid instance.
-- @param rng table The seeded PRNG instance.
-- @param allowed_colors table Array of available color tokens (e.g. {'amber', 'emerald', ...}).
-- @return table spawns Array of spawn records: {{pos = {x, y}, tile_type}, ...}
function cascade.refill_spawners(g, rng, allowed_colors)
    assert(#allowed_colors > 0, "Allowed colors list must not be empty")
    local spawns = {}

    for x = 1, g.width do
        for y = g.height, 1, -1 do
            local c = grid.get(g, x, y)
            if cell.can_fall_into(c) then
                local chosen_color = prng.choice(rng, allowed_colors)
                c.tile_type = chosen_color
                c.state = cell.STATE_IDLE
                table.insert(spawns, {
                    pos = {x = x, y = y},
                    tile_type = chosen_color
                })
            end
        end
    end

    return spawns
end

--- Resolves full cascade chain reactions iteratively until the board completely settles.
-- Guarantees termination: max_cascades safeguard prevents infinite loops on bad level setups.
-- @param g table The grid instance.
-- @param rng table Seeded PRNG instance for refills.
-- @param allowed_colors table Array of color tokens.
-- @param initial_matches table Array of match results that triggered the cascade.
-- @param max_cascades number|nil Optional maximum cascade limit (default 50).
-- @return table steps Chronological log of all cascade steps for visual animation.
-- @return number total_cascades Total number of cascade waves settled.
function cascade.resolve(g, rng, allowed_colors, initial_matches, max_cascades)
    local limit = max_cascades or 50
    local steps = {}
    local current_matches = initial_matches
    local wave_count = 0

    while current_matches and #current_matches > 0 and wave_count < limit do
        wave_count = wave_count + 1

        -- Step 1: Clear matches and place created powerups
        local clear_event = cascade.apply_matches(g, current_matches)
        table.insert(steps, {wave = wave_count, event = clear_event})

        -- Step 2: Apply gravity drops
        local falls = cascade.apply_gravity(g)
        if #falls > 0 then
            table.insert(steps, {wave = wave_count, type = "falls", data = falls})
        end

        -- Step 3: Refill empty cells from top spawners
        local spawns = cascade.refill_spawners(g, rng, allowed_colors)
        if #spawns > 0 then
            table.insert(steps, {wave = wave_count, type = "spawns", data = spawns})
        end

        -- Step 4: Scan for secondary chain-reaction matches
        current_matches = match_finder.find_all_matches(g)
    end

    return steps, wave_count
end

return cascade
