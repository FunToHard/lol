--- Headless Monte Carlo AI Level Solver for Match-3 balancing and difficulty verification.
-- Simulates games across Casual, Goal-Oriented, and Strategic player heuristics.
-- @module solver

local grid = require("game.board.grid")
local match_finder = require("game.board.match_finder")
local cascade = require("game.board.cascade")
local powerups = require("game.board.powerups")
local obstacles = require("game.board.obstacles")
local reshuffle = require("game.board.reshuffle")
local prng = require("game.board.prng")
local cell = require("game.board.cell")
local level_loader = require("game.board.level_loader")
local level_tracker = require("game.board.level_tracker")

local solver = {}

local DEFAULT_COLORS = { "amber", "amethyst", "emerald", "ruby", "sapphire" }

--- Finds all legally swappable coordinate pairs on the current board.
-- @param board table Active board grid.
-- @return table moves Array of valid move descriptors { from = {x, y}, to = {x, y}, matches = table, is_powerup = boolean }.
function solver.find_all_legal_moves(board)
    local moves = {}
    local seen = {}

    local function move_key(x1, y1, x2, y2)
        if x1 > x2 or (x1 == x2 and y1 > y2) then
            x1, y1, x2, y2 = x2, y2, x1, y1
        end
        return string.format("%d,%d-%d,%d", x1, y1, x2, y2)
    end

    local deltas = { { 1, 0 }, { 0, 1 } }
    for y = 1, board.height do
        for x = 1, board.width do
            for _, d in ipairs(deltas) do
                local nx = x + d[1]
                local ny = y + d[2]
                if grid.is_inside(board, nx, ny) then
                    local k = move_key(x, y, nx, ny)
                    if not seen[k] then
                        seen[k] = true
                        local valid, matches, is_powerup = match_finder.is_valid_swap(board, x, y, nx, ny)
                        if valid then
                            moves[#moves + 1] = {
                                from = { x = x, y = y },
                                to = { x = nx, y = ny },
                                matches = matches or {},
                                is_powerup = (is_powerup == true)
                            }
                        end
                    end
                end
            end
        end
    end
    return moves
end

--- Scores a proposed move based on the simulated player persona heuristic.
-- @param move table Move descriptor.
-- @param board table Active board grid.
-- @param tracker table Level tracker instance holding goals.
-- @param persona string "casual", "goal_oriented", or "strategic".
-- @return number score Heuristic score for ranking move desirability.
function solver.score_move(move, board, tracker, persona)
    local score = 0
    local fx, fy = move.from.x, move.from.y
    local tx, ty = move.to.x, move.to.y

    if persona == "casual" then
        -- Casual player favors matches toward the bottom of the board
        score = (fy + ty) * 10
        if #move.matches > 0 then score = score + #move.matches[1].cells end
        return score
    end

    -- Base preference for lower board positions (encourages natural cascades)
    score = (fy + ty) * 2

    local c_from = grid.get(board, fx, fy)
    local c_to = grid.get(board, tx, ty)

    -- Powerup combo bonus
    if move.is_powerup then
        score = score + 80
        if c_from and c_from.powerup_type and c_to and c_to.powerup_type then
            score = score + 120 -- Combo fusion is highest priority
        end
    end

    -- Evaluate matches created
    for _, m in ipairs(move.matches) do
        local cell_count = #m.cells
        -- Value creating special power-up tiles
        if cell_count >= 5 then score = score + (persona == "strategic" and 100 or 75) end
        if cell_count == 4 then score = score + (persona == "strategic" and 50 or 40) end
        if m.pattern == "t_shape" or m.pattern == "l_shape" then score = score + (persona == "strategic" and 60 or 45) end

        -- Check goal color collection
        if m.tile_type then
            for _, g in ipairs(tracker.goals) do
                if g.type == "collect_color" and g.target == m.tile_type and not g.completed then
                    score = score + 40 * #m.cells
                end
            end
        end

        -- Check adjacent obstacle damage
        for _, pos in ipairs(m.cells) do
            local adj_deltas = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }
            for _, ad in ipairs(adj_deltas) do
                local ax = pos.x + ad[1]
                local ay = pos.y + ad[2]
                local ac = grid.get(board, ax, ay)
                if ac and ac.obstacle then
                    for _, g in ipairs(tracker.goals) do
                        if g.type == "clear_obstacle" and not g.completed then
                            score = score + 50
                        end
                    end
                end
            end
        end
    end

    return score
end

--- Simulates a single complete playthrough of a level.
-- @param level_def table Parsed level definition.
-- @param persona string Player persona name ("casual", "goal_oriented", "strategic").
-- @param rng table Seeded PRNG instance.
-- @return table result Outcome details { won = boolean, remaining_moves = number, turns = number, reshuffles = number }.
function solver.simulate_game(level_def, persona, rng)
    local board = level_loader.setup_board(level_def, rng)
    local tracker = level_tracker.new(level_def)
    local turns = 0
    local reshuffles = 0

    while tracker.status == "IN_PROGRESS" do
        local moves = solver.find_all_legal_moves(board)

        -- If no legal moves, reshuffle board
        if #moves == 0 then
            reshuffles = reshuffles + 1
            reshuffle.execute(board, rng, 50)
            moves = solver.find_all_legal_moves(board)
            if #moves == 0 then
                -- Deadlock cannot be resolved
                break
            end
        end

        -- Select best move among candidates with tie-breaking
        local candidates = {}
        local best_score = -999999
        for _, m in ipairs(moves) do
            local s = solver.score_move(m, board, tracker, persona)
            if s > best_score then
                best_score = s
                candidates = { m }
            elseif s == best_score then
                candidates[#candidates + 1] = m
            end
        end

        local best_move = candidates[prng.random_int(rng, 1, #candidates)]

        -- Execute move
        turns = turns + 1
        level_tracker.record_move(tracker)

        if best_move.is_powerup then
            local c1 = grid.get(board, best_move.from.x, best_move.from.y)
            local c2 = grid.get(board, best_move.to.x, best_move.to.y)
            local blast = nil
            if c1 and c1.powerup_type and c2 and c2.powerup_type then
                blast = powerups.detonate_combo(board, best_move.from.x, best_move.from.y, best_move.to.x, best_move.to.y)
            elseif c1 and c1.powerup_type then
                blast = powerups.detonate_single(board, best_move.from.x, best_move.from.y)
            elseif c2 and c2.powerup_type then
                blast = powerups.detonate_single(board, best_move.to.x, best_move.to.y)
            end

            if blast and blast.cleared_cells then
                local damaged = obstacles.damage_from_blast(board, blast.cleared_cells)
                if damaged and #damaged > 0 then
                    for _, obs_info in ipairs(damaged) do
                        if obs_info.destroyed then
                            level_tracker.record_obstacle_destroyed(tracker, obs_info.type or "bramble", 1)
                        end
                    end
                end

                local cleared_colors = {}
                for _, pos in ipairs(blast.cleared_cells) do
                    local c = grid.get(board, pos.x, pos.y)
                    if c and c.tile_type then
                        cleared_colors[#cleared_colors + 1] = c.tile_type
                    end
                    cell.clear_content(c)
                end
                level_tracker.record_matches(tracker, cleared_colors)

                cascade.apply_gravity(board)
                cascade.refill_spawners(board, rng, DEFAULT_COLORS)
            end
        else
            grid.swap(board, best_move.from.x, best_move.from.y, best_move.to.x, best_move.to.y)
        end

        -- Cascade resolution loop
        local loop_guard = 0
        while loop_guard < 15 do
            loop_guard = loop_guard + 1
            local matches = match_finder.find_all_matches(board)
            if #matches == 0 then break end

            -- Record collected colors
            local cleared_colors = {}
            for _, m in ipairs(matches) do
                if m.tile_type then
                    for _ = 1, #m.cells do
                        cleared_colors[#cleared_colors + 1] = m.tile_type
                    end
                end
            end
            level_tracker.record_matches(tracker, cleared_colors)

            -- Damage adjacent obstacles
            local damaged = obstacles.damage_adjacent(board, matches)
            if damaged and #damaged > 0 then
                for _, obs_info in ipairs(damaged) do
                    if obs_info.destroyed then
                        level_tracker.record_obstacle_destroyed(tracker, obs_info.type or "bramble", 1)
                    end
                end
            end

            -- Apply matches & spawn powerups
            cascade.apply_matches(board, matches)

            -- Gravity & refills
            cascade.apply_gravity(board)
            cascade.refill_spawners(board, rng, DEFAULT_COLORS)

            -- Collect ingredients that reached bottom
            local ingredients = obstacles.collect_bottom_ingredients(board)
            if ingredients and #ingredients > 0 then
                level_tracker.record_ingredient_collected(tracker, #ingredients)
                cascade.apply_gravity(board)
                cascade.refill_spawners(board, rng, DEFAULT_COLORS)
            end

            if tracker.status == "WON" then break end
        end

        level_tracker.get_status(tracker)
    end

    return {
        won = (tracker.status == "WON"),
        remaining_moves = tracker.moves_remaining,
        turns = turns,
        reshuffles = reshuffles
    }
end

--- Runs a Monte Carlo simulation batch across multiple seeds and personas.
-- @param level_def table Parsed level definition.
-- @param runs number Total number of simulation runs.
-- @param base_seed number|nil Initial random seed (defaults to 1000).
-- @return table metrics Summary statistics { win_rate, avg_remaining_moves, wins, losses, reshuffles }.
function solver.run_monte_carlo(level_def, runs, base_seed)
    local seed = base_seed or 1000
    local wins = 0
    local total_remaining = 0
    local total_reshuffles = 0
    local personas = { "casual", "goal_oriented", "strategic" }

    for i = 1, runs do
        local persona = personas[((i - 1) % #personas) + 1]
        local rng = prng.new(seed + i * 37)
        local res = solver.simulate_game(level_def, persona, rng)
        if res.won then
            wins = wins + 1
            total_remaining = total_remaining + res.remaining_moves
        end
        total_reshuffles = total_reshuffles + res.reshuffles
    end

    local win_rate = (wins / runs) * 100
    local avg_remaining = (wins > 0) and (total_remaining / wins) or 0

    return {
        runs = runs,
        wins = wins,
        losses = runs - wins,
        win_rate = win_rate,
        avg_remaining_moves = avg_remaining,
        total_reshuffles = total_reshuffles
    }
end

return solver
