--- Loads, validates, and initializes board grids from JSON level definitions.
-- Supports custom active masks, obstacle placements, spawner palettes, and initial pieces.
-- @module level_loader

local json = require("game.board.json")
local grid = require("game.board.grid")
local cell = require("game.board.cell")
local obstacles = require("game.board.obstacles")
local cascade = require("game.board.cascade")
local reshuffle = require("game.board.reshuffle")

local level_loader = {}

local DEFAULT_COLORS = { "amber", "amethyst", "emerald", "ruby", "sapphire" }

--- Validates that a parsed level definition contains all required schema fields.
-- @param level_def table Parsed level table to validate.
-- @return boolean is_valid True if all required fields are present and valid.
-- @return string|nil error_msg Error explanation if validation failed.
function level_loader.validate_schema(level_def)
    if type(level_def) ~= "table" then
        return false, "Level definition must be a table"
    end
    if not level_def.version or type(level_def.version) ~= "number" then
        return false, "Missing or invalid 'version' field"
    end
    if not level_def.level_id or type(level_def.level_id) ~= "number" then
        return false, "Missing or invalid 'level_id' field"
    end
    if not level_def.moves or type(level_def.moves) ~= "number" or level_def.moves <= 0 then
        return false, "Missing or invalid 'moves' field (must be > 0)"
    end
    if not level_def.grid or type(level_def.grid) ~= "table" then
        return false, "Missing 'grid' object"
    end
    if not level_def.grid.width or not level_def.grid.height then
        return false, "Grid must define 'width' and 'height'"
    end
    if not level_def.goals or type(level_def.goals) ~= "table" or #level_def.goals == 0 then
        return false, "Level must define at least one goal in 'goals' array"
    end
    for i, g in ipairs(level_def.goals) do
        if not g.type or not g.target or not g.count or g.count <= 0 then
            return false, string.format("Goal #%d is malformed (requires type, target, and count > 0)", i)
        end
    end
    return true, nil
end

--- Parses a JSON level definition string into a Lua table and validates schema.
-- @param json_str string Raw JSON content.
-- @return table level_def Parsed and validated level definition table.
function level_loader.parse(json_str)
    local def = json.decode(json_str)
    local ok, err = level_loader.validate_schema(def)
    if not ok then
        error("Level validation error: " .. tostring(err))
    end
    return def
end

--- Reads a level file from disk or Defold resources and parses its JSON content.
-- @param file_path string Path to level JSON file.
-- @return table level_def Parsed level definition table.
function level_loader.load_from_file(file_path)
    local content = nil
    -- Defold runtime check
    if sys and sys.load_resource then
        local res, _ = sys.load_resource("/" .. file_path)
        if res then content = res end
    end
    -- Standard file I/O fallback
    if not content then
        local f = io.open(file_path, "r")
        if not f then
            error("Could not open level file at: " .. tostring(file_path))
        end
        content = f:read("*a")
        f:close()
    end
    return level_loader.parse(content)
end

--- Instantiates and populates a board grid from a validated level definition.
-- Sets up custom cell masks, initial obstacles, spawner color pools, and initial tiles.
-- @param level_def table Validated level configuration.
-- @param rng table Seeded PRNG instance for populating random pieces.
-- @return table board Initialized and playable board grid table.
function level_loader.setup_board(level_def, rng)
    local w = level_def.grid.width
    local h = level_def.grid.height
    local board = grid.create(w, h)

    -- 1. Apply active cell mask if defined
    if level_def.grid.active_cells then
        for row_idx, row_str in ipairs(level_def.grid.active_cells) do
            local gy = row_idx
            for gx = 1, math.min(w, #row_str) do
                local char = row_str:sub(gx, gx)
                if char == "0" then
                    local c = grid.get(board, gx, gy)
                    if c then
                        cell.set_state(c, "DISABLED")
                        c.is_enabled = false
                    end
                end
            end
        end
    end

    -- 2. Configure column spawners
    board.spawners = {}
    if level_def.spawners and #level_def.spawners > 0 then
        for _, sp in ipairs(level_def.spawners) do
            local col = sp.col
            -- Normalize 0-indexed or 1-indexed column
            if not sp.is_one_indexed then
                col = col + 1
            end
            board.spawners[col] = sp.colors or DEFAULT_COLORS
        end
    end
    -- Fallback default colors for any unspecified columns
    for x = 1, w do
        if not board.spawners[x] then
            board.spawners[x] = DEFAULT_COLORS
        end
    end

    -- 3. Place obstacles
    if level_def.obstacles then
        for _, obs in ipairs(level_def.obstacles) do
            local ox = obs.x
            local oy = obs.y
            -- Normalize 0-indexed coordinates
            if ox < w and oy < h and (ox == 0 or oy == 0 or not obs.is_one_indexed) then
                ox = ox + 1
                oy = oy + 1
            end
            local c = grid.get(board, ox, oy)
            if c and c.is_enabled then
                local is_solid = (obs.type == "stone")
                c.obstacle = obstacles.create(obs.type, obs.layer or 1, is_solid)
            end
        end
    end

    -- 4. Place explicit initial tiles if specified
    if level_def.initial_tiles then
        for _, it in ipairs(level_def.initial_tiles) do
            local tx = it.x
            local ty = it.y
            if tx < w and ty < h and (tx == 0 or ty == 0 or not it.is_one_indexed) then
                tx = tx + 1
                ty = ty + 1
            end
            grid.set_tile(board, tx, ty, it.tile)
            if it.powerup then
                grid.set_powerup(board, tx, ty, it.powerup)
            end
        end
    end

    -- 5. Fill remaining unassigned active cells with random pieces and resolve pre-matches
    cascade.refill_spawners(board, rng, DEFAULT_COLORS)
    reshuffle.execute(board, rng)

    return board
end

return level_loader
