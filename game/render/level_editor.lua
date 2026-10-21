--- In-engine developer level editor controller for painting, playtesting, and JSON export.
-- Manages palette brush state, grid painting, seed locking, and schema-compliant JSON generation.
-- @module level_editor

local json = require("game.board.json")
local level_loader = require("game.board.level_loader")

local level_editor = {}

local PALETTE = {
    "amber", "emerald", "sapphire", "ruby", "amethyst",
    "bramble_1", "bramble_2", "stone", "ingredient",
    "disabled", "empty"
}

--- Creates a new level editor state table initialized with default dimensions.
-- @param width number|nil Grid width (defaults to 8).
-- @param height number|nil Grid height (defaults to 8).
-- @return table state Initialized level editor state table.
function level_editor.new(width, height)
    local w = width or 8
    local h = height or 8
    local grid_cells = {}
    for y = 1, h do
        grid_cells[y] = {}
        for x = 1, w do
            grid_cells[y][x] = {
                active = true,
                tile_type = "amber",
                obstacle = nil
            }
        end
    end

    return {
        is_active = false,
        width = w,
        height = h,
        current_brush = "amber",
        palette = PALETTE,
        cells = grid_cells,
        level_id = 999,
        difficulty = "custom",
        moves = 25,
        goals = {
            { type = "collect_color", target = "amber", count = 15 }
        },
        locked_seed = nil
    }
end

--- Toggles the developer editor overlay visibility.
-- @param state table The editor state table.
-- @return boolean is_active Current visibility flag after toggle.
function level_editor.toggle(state)
    state.is_active = not state.is_active
    return state.is_active
end

--- Selects an active painting brush from the palette.
-- @param state table The editor state table.
-- @param brush_name string Name of the brush tool.
-- @return boolean success True if the brush exists and was selected.
function level_editor.select_brush(state, brush_name)
    for _, b in ipairs(state.palette) do
        if b == brush_name then
            state.current_brush = brush_name
            return true
        end
    end
    return false
end

--- Paints the specified grid cell using the active brush tool.
-- @param state table The editor state table.
-- @param x number Grid column (1-indexed).
-- @param y number Grid row (1-indexed).
function level_editor.paint_cell(state, x, y)
    if x < 1 or x > state.width or y < 1 or y > state.height then return end
    local c = state.cells[y][x]
    local b = state.current_brush

    if b == "disabled" then
        c.active = false
        c.tile_type = nil
        c.obstacle = nil
    elseif b == "empty" then
        c.active = true
        c.tile_type = nil
        c.obstacle = nil
    elseif b == "bramble_1" then
        c.active = true
        c.obstacle = { type = "bramble", layer = 1 }
    elseif b == "bramble_2" then
        c.active = true
        c.obstacle = { type = "bramble", layer = 2 }
    elseif b == "stone" then
        c.active = true
        c.obstacle = { type = "stone", layer = 1 }
    elseif b == "ingredient" then
        c.active = true
        c.obstacle = { type = "ingredient", layer = 1 }
    else
        -- Regular colored tile
        c.active = true
        c.tile_type = b
        c.obstacle = nil
    end
end

--- Sets or unlocks a deterministic RNG seed for editor playtesting.
-- @param state table The editor state table.
-- @param seed number|nil Seed integer or nil to unlock.
function level_editor.set_locked_seed(state, seed)
    state.locked_seed = seed
end

--- Exports the current painted editor state as a valid JSON level definition string.
-- @param state table The editor state table.
-- @return string json_str Formatted schema-compliant JSON string.
function level_editor.export_json(state)
    local active_mask = {}
    local obstacles = {}

    for y = 1, state.height do
        local row_chars = {}
        for x = 1, state.width do
            local c = state.cells[y][x]
            if c.active then
                row_chars[#row_chars + 1] = "1"
            else
                row_chars[#row_chars + 1] = "0"
            end
            if c.obstacle then
                obstacles[#obstacles + 1] = {
                    type = c.obstacle.type,
                    layer = c.obstacle.layer,
                    x = x - 1,
                    y = y - 1
                }
            end
        end
        active_mask[#active_mask + 1] = table.concat(row_chars)
    end

    local spawners = {}
    for col = 0, state.width - 1 do
        spawners[#spawners + 1] = {
            col = col,
            colors = { "amber", "emerald", "sapphire", "ruby", "amethyst" }
        }
    end

    local level_def = {
        version = 1,
        level_id = state.level_id,
        difficulty = state.difficulty,
        moves = state.moves,
        grid = {
            width = state.width,
            height = state.height,
            active_cells = active_mask
        },
        spawners = spawners,
        obstacles = obstacles,
        goals = state.goals
    }

    return json.encode(level_def)
end

--- Loads a level definition table into the editor for visual inspection and modification.
-- @param state table The editor state table.
-- @param level_def table The parsed level configuration table.
function level_editor.load_level(state, level_def)
    state.width = level_def.grid.width
    state.height = level_def.grid.height
    state.level_id = level_def.level_id or state.level_id
    state.difficulty = level_def.difficulty or state.difficulty
    state.moves = level_def.moves or state.moves
    state.goals = level_def.goals or state.goals

    local grid_cells = {}
    for y = 1, state.height do
        grid_cells[y] = {}
        for x = 1, state.width do
            grid_cells[y][x] = {
                active = true,
                tile_type = "amber",
                obstacle = nil
            }
        end
    end

    if level_def.grid.active_cells then
        for y, row_str in ipairs(level_def.grid.active_cells) do
            for x = 1, #row_str do
                if grid_cells[y] and grid_cells[y][x] then
                    grid_cells[y][x].active = (row_str:sub(x, x) == "1")
                end
            end
        end
    end

    if level_def.obstacles then
        for _, obs in ipairs(level_def.obstacles) do
            local ox = obs.x + 1
            local oy = obs.y + 1
            if grid_cells[oy] and grid_cells[oy][ox] then
                grid_cells[oy][ox].obstacle = {
                    type = obs.type,
                    layer = obs.layer or 1
                }
            end
        end
    end

    state.cells = grid_cells
end

return level_editor
