--- Pure Lua JSON parser and serializer with native Defold json fallback.
-- Provides seamless JSON support both in Defold runtime and headless CLI Lua.
-- @module json

local json_module = {}

--- Serializes a Lua table, string, number, or boolean into a valid JSON string.
-- @param val any The value to serialize.
-- @return string json_str The resulting JSON formatted string.
function json_module.encode(val)
    if _G.json and _G.json.encode and pcall(_G.json.encode, {}) then
        return _G.json.encode(val)
    end

    local val_type = type(val)
    if val_type == "nil" then
        return "null"
    elseif val_type == "boolean" then
        return tostring(val)
    elseif val_type == "number" then
        return tostring(val)
    elseif val_type == "string" then
        local escaped = val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
        return '"' .. escaped .. '"'
    elseif val_type == "table" then
        -- Check if it's an array or object
        local is_array = true
        local n = #val
        local count = 0
        for _ in pairs(val) do
            count = count + 1
        end
        if count ~= n then
            is_array = false
        end

        if is_array then
            local items = {}
            for i = 1, n do
                items[i] = json_module.encode(val[i])
            end
            return "[" .. table.concat(items, ", ") .. "]"
        else
            local items = {}
            for k, v in pairs(val) do
                items[#items + 1] = string.format("%s: %s", json_module.encode(tostring(k)), json_module.encode(v))
            end
            return "{" .. table.concat(items, ", ") .. "}"
        end
    else
        error("Unsupported JSON serialization type: " .. val_type)
    end
end

--- Internal recursive JSON scanner and parser.
-- @param str string Raw JSON string.
-- @param idx number Current character index.
-- @return any parsed_val The parsed Lua value.
-- @return number next_idx Index after the parsed value.
local function parse_value(str, idx)
    idx = str:find("%S", idx) or idx
    local char = str:sub(idx, idx)

    if char == "{" then
        -- Parse Object
        local obj = {}
        idx = idx + 1
        while true do
            idx = str:find("%S", idx) or idx
            if str:sub(idx, idx) == "}" then
                return obj, idx + 1
            end
            local key, next_i = parse_value(str, idx)
            idx = str:find("%S", next_i) or next_i
            if str:sub(idx, idx) ~= ":" then
                error("Expected ':' after key in object at position " .. idx)
            end
            idx = idx + 1
            local val, after_v = parse_value(str, idx)
            obj[key] = val
            idx = str:find("%S", after_v) or after_v
            local sep = str:sub(idx, idx)
            if sep == "," then
                idx = idx + 1
            elseif sep == "}" then
                return obj, idx + 1
            else
                error("Expected ',' or '}' in object at position " .. idx)
            end
        end
    elseif char == "[" then
        -- Parse Array
        local arr = {}
        idx = idx + 1
        while true do
            idx = str:find("%S", idx) or idx
            if str:sub(idx, idx) == "]" then
                return arr, idx + 1
            end
            local val, after_v = parse_value(str, idx)
            arr[#arr + 1] = val
            idx = str:find("%S", after_v) or after_v
            local sep = str:sub(idx, idx)
            if sep == "," then
                idx = idx + 1
            elseif sep == "]" then
                return arr, idx + 1
            else
                error("Expected ',' or ']' in array at position " .. idx)
            end
        end
    elseif char == '"' then
        -- Parse String
        local end_idx = idx + 1
        while true do
            end_idx = str:find('"', end_idx)
            if not end_idx then error("Unterminated string starting at " .. idx) end
            local slashes = 0
            local p = end_idx - 1
            while p > idx and str:sub(p, p) == "\\" do
                slashes = slashes + 1
                p = p - 1
            end
            if slashes % 2 == 0 then
                break
            else
                end_idx = end_idx + 1
            end
        end
        local content = str:sub(idx + 1, end_idx - 1)
        content = content:gsub('\\"', '"'):gsub('\\\\', '\\'):gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\t', '\t')
        return content, end_idx + 1
    elseif char == "t" and str:sub(idx, idx + 3) == "true" then
        return true, idx + 4
    elseif char == "f" and str:sub(idx, idx + 4) == "false" then
        return false, idx + 5
    elseif char == "n" and str:sub(idx, idx + 3) == "null" then
        return nil, idx + 4
    else
        -- Parse Number
        local num_str = str:match("^[%-%d%.%w%+]+", idx)
        if num_str then
            local n = tonumber(num_str)
            if n then
                return n, idx + #num_str
            end
        end
        error("Unexpected character in JSON at index " .. idx .. ": " .. char)
    end
end

--- Decodes a JSON formatted string into a Lua table or primitive value.
-- @param str string JSON string to decode.
-- @return any result Decoded Lua representation.
function json_module.decode(str)
    if _G.json and _G.json.decode and pcall(_G.json.decode, "{}") then
        return _G.json.decode(str)
    end

    local val, _ = parse_value(str, 1)
    return val
end

return json_module
