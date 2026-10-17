--- Two-file atomic save system with backup recovery and automatic schema migration.
-- Protects player save data against OS termination, battery cutoffs, and corrupted disk writes.
-- @module save_manager

local json = require("game.board.json")
local migrations = require("game.persistence.migrations")

local save_manager = {}

--- Generates fresh new-game default state table compliant with CURRENT_SCHEMA_VERSION.
-- @return table default_save Brand-new player state table.
function save_manager.create_default_state()
    local state = {
        schema_version = migrations.CURRENT_SCHEMA_VERSION,
        created_at = os.time and os.time() or 0,
        last_updated = os.time and os.time() or 0,
        player = {
            stars = 0,
            coins = 100,
            inventory = {
                hammer = 1,
                rocket = 1,
                bomb = 1
            }
        },
        progression = {
            max_unlocked_level = 1,
            completed_levels = {}
        },
        village = {
            current_area = "hearthstone_courtyard",
            completed_tasks = {},
            chosen_styles = {}
        },
        ledger_history = {}
    }
    return state
end

--- Computes standard file paths for the active save, temp write buffer, and backup file.
-- @param base_dir string|nil Optional directory path (defaults to Defold save directory or local dir).
-- @return string path_save Absolute or relative path to "save.json".
-- @return string path_tmp Path to "save.json.tmp".
-- @return string path_bak Path to "save.json.bak".
function save_manager.get_save_paths(base_dir)
    local dir = base_dir
    if not dir then
        if sys and sys.get_save_file then
            local main_file = sys.get_save_file("lantern_grove", "save.json")
            return main_file, main_file .. ".tmp", main_file .. ".bak"
        else
            dir = "."
        end
    end
    -- Clean trailing slashes
    if dir:sub(-1) == "/" or dir:sub(-1) == "\\" then
        dir = dir:sub(1, -2)
    end
    return dir .. "/save.json", dir .. "/save.json.tmp", dir .. "/save.json.bak"
end

--- Internal helper to read raw text content from a file path.
-- @param path string File path to read.
-- @return string|nil content File string or nil if unreadable.
local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

--- Internal helper to write text content to a file path.
-- @param path string Target file path.
-- @param content string String content to write.
-- @return boolean success True if write succeeded.
local function write_file(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

--- Copies contents of one file to another destination.
-- @param src_path string Source file path.
-- @param dst_path string Destination file path.
-- @return boolean success True if copied successfully.
local function copy_file(src_path, dst_path)
    local content = read_file(src_path)
    if not content then return false end
    return write_file(dst_path, content)
end

--- Atomically saves the state table to disk using the two-file commit pattern.
-- Writes to .tmp -> verifies integrity -> copies .json to .bak -> renames .tmp to .json.
-- @param state table The player state table to serialize.
-- @param base_dir string|nil Optional custom directory path.
-- @return boolean success True if save was atomically written and verified.
-- @return string|nil error_msg Error explanation if save failed.
function save_manager.save(state, base_dir)
    assert(type(state) == "table", "Save state must be a table")

    state.last_updated = os.time and os.time() or 0
    state.schema_version = migrations.CURRENT_SCHEMA_VERSION

    local json_str = json.encode(state)
    local p_save, p_tmp, p_bak = save_manager.get_save_paths(base_dir)

    -- Step 1: Write to temporary file
    local wrote = write_file(p_tmp, json_str)
    if not wrote then
        return false, "Failed to write temporary save buffer: " .. p_tmp
    end

    -- Step 2: Verify integrity on disk
    local verify_raw = read_file(p_tmp)
    if not verify_raw or #verify_raw < 2 then
        return false, "Corrupted temporary save buffer"
    end
    local ok_parse, verify_data = pcall(json.decode, verify_raw)
    if not ok_parse or type(verify_data) ~= "table" then
        return false, "Integrity check failed: invalid JSON in temporary buffer"
    end

    -- Step 3: Copy existing save.json to save.json.bak
    local existing_raw = read_file(p_save)
    if existing_raw and #existing_raw > 0 then
        copy_file(p_save, p_bak)
    end

    -- Step 4: Atomically rename temp buffer to save.json
    -- On Windows, os.rename will fail if target exists, so remove target first
    os.remove(p_save)
    local renamed, rename_err = os.rename(p_tmp, p_save)
    if not renamed then
        -- Fallback: copy temp to save
        local copied = copy_file(p_tmp, p_save)
        os.remove(p_tmp)
        if not copied then
            return false, "Failed to commit save file: " .. tostring(rename_err)
        end
    end

    return true, nil
end

--- Loads and returns player save data adhering to the startup recovery hierarchy.
-- 1. Attempts save.json -> 2. Falls back to save.json.bak -> 3. Falls back to default state.
-- Automatically migrates loaded data to CURRENT_SCHEMA_VERSION.
-- @param base_dir string|nil Optional custom directory path.
-- @return table state Validated and migrated state table (never crashes).
-- @return string source Origin of loaded state: "primary", "backup", or "defaults".
function save_manager.load(base_dir)
    local p_save, _, p_bak = save_manager.get_save_paths(base_dir)

    -- Step 1: Attempt primary save file
    local primary_raw = read_file(p_save)
    if primary_raw and #primary_raw > 0 then
        local ok, data = pcall(json.decode, primary_raw)
        if ok and type(data) == "table" and data.player and data.progression then
            local migrated = migrations.migrate(data)
            return migrated, "primary"
        end
    end

    -- Step 2: Attempt backup file
    local backup_raw = read_file(p_bak)
    if backup_raw and #backup_raw > 0 then
        local ok_bak, bak_data = pcall(json.decode, backup_raw)
        if ok_bak and type(bak_data) == "table" and bak_data.player and bak_data.progression then
            local migrated_bak = migrations.migrate(bak_data)
            -- Restore backup as primary save
            save_manager.save(migrated_bak, base_dir)
            return migrated_bak, "backup"
        end
    end

    -- Step 3: Generate clean defaults (guaranteed non-crash)
    local default_state = save_manager.create_default_state()
    save_manager.save(default_state, base_dir)
    return default_state, "defaults"
end

return save_manager
