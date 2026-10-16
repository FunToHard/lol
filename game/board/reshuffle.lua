--- Dead-board detection and automatic piece reshuffling engine.
-- Guarantees the board never gets permanently stuck without consuming player moves.
local cell = require("game.board.cell")
local grid = require("game.board.grid")
local match_finder = require("game.board.match_finder")
local prng = require("game.board.prng")

local reshuffle = {}

--- Scans the board to determine if at least one legal player move exists.
-- Checks all horizontal and vertical adjacent pairs.
-- @param g table The grid instance.
-- @return boolean has_moves True if a legal swap exists.
-- @return table|nil sample_move First discovered valid swap move {{x1, y1}, {x2, y2}}.
function reshuffle.has_legal_moves(g)
    for y = 1, g.height do
        for x = 1, g.width do
            local c = grid.get(g, x, y)
            if cell.is_swappable(c) then
                -- Check right neighbor
                if x < g.width then
                    local valid = match_finder.is_valid_swap(g, x, y, x + 1, y)
                    if valid then
                        return true, {from = {x = x, y = y}, to = {x = x + 1, y = y}}
                    end
                end
                -- Check down neighbor
                if y < g.height then
                    local valid = match_finder.is_valid_swap(g, x, y, x, y + 1)
                    if valid then
                        return true, {from = {x = x, y = y}, to = {x = x, y = y + 1}}
                    end
                end
            end
        end
    end
    return false, nil
end

--- Counts how many distinct legal swaps currently exist on the board.
-- Useful for difficulty balancing and solver heuristics.
-- @param g table The grid instance.
-- @return number count Total number of legal swap options.
function reshuffle.count_legal_moves(g)
    local count = 0
    for y = 1, g.height do
        for x = 1, g.width do
            local c = grid.get(g, x, y)
            if cell.is_swappable(c) then
                if x < g.width and match_finder.is_valid_swap(g, x, y, x + 1, y) then
                    count = count + 1
                end
                if y < g.height and match_finder.is_valid_swap(g, x, y, x, y + 1) then
                    count = count + 1
                end
            end
        end
    end
    return count
end

--- Re-arranges regular tiles on the board until at least one legal swap is created.
-- Leaves obstacles and power-ups in their current positions.
-- Guarantees the new configuration has NO immediate pre-existing 3-in-a-row matches.
-- @param g table The grid instance.
-- @param rng table Seeded PRNG instance.
-- @param max_attempts number|nil Maximum retry attempts (default 100).
-- @return boolean success True if a valid reshuffle was found.
-- @return table|nil swap_map Mapping of tile reallocations for visual animation.
function reshuffle.execute(g, rng, max_attempts)
    local limit = max_attempts or 100

    -- Collect all swappable cells and their current regular tiles
    local swappable_coords = {}
    local tile_pool = {}

    for y = 1, g.height do
        for x = 1, g.width do
            local c = grid.get(g, x, y)
            -- Only shuffle regular color tiles; preserve powerups and obstacles
            if c and c.is_enabled and c.tile_type and c.powerup_type == nil and c.obstacle == nil then
                table.insert(swappable_coords, {x = x, y = y})
                table.insert(tile_pool, c.tile_type)
            end
        end
    end

    if #swappable_coords < 3 then
        return false, nil
    end

    for _ = 1, limit do
        -- Fisher-Yates shuffle tile_pool using seeded PRNG
        for i = #tile_pool, 2, -1 do
            local j = prng.random_int(rng, 1, i)
            tile_pool[i], tile_pool[j] = tile_pool[j], tile_pool[i]
        end

        -- Temporarily assign shuffled tiles into the grid
        for i, pos in ipairs(swappable_coords) do
            grid.set_tile(g, pos.x, pos.y, tile_pool[i])
        end

        -- Verify conditions:
        -- 1. NO immediate pre-existing match-3
        local immediate_matches = match_finder.find_all_matches(g)
        if #immediate_matches == 0 then
            -- 2. At least 1 legal move must exist!
            local has_moves, sample = reshuffle.has_legal_moves(g)
            if has_moves then
                return true, {
                    moves_created = reshuffle.count_legal_moves(g),
                    sample_move = sample
                }
            end
        end
    end

    return false, nil
end

return reshuffle
