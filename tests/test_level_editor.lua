--- Unit tests for in-engine developer level editor controller.
-- Run headlessly with Lua 5.1 CLI: `lua tests/test_level_editor.lua`

package.path = package.path .. ";./?.lua"

local level_editor = require("game.render.level_editor")
local level_loader = require("game.board.level_loader")

local total_tests = 0
local passed_tests = 0

local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Developer Level Editor Tests ---")

-- Test 1: Editor initialization and toggle
local ed = level_editor.new(8, 8)
assert_eq(ed.is_active, false, "Editor inactive by default")
assert_eq(ed.width, 8, "Editor grid width is 8")
assert_eq(ed.height, 8, "Editor grid height is 8")

local active = level_editor.toggle(ed)
assert_eq(active, true, "Editor toggled to active")
assert_eq(ed.is_active, true, "State flag matches")

-- Test 2: Brush selection
local ok1 = level_editor.select_brush(ed, "bramble_2")
assert_eq(ok1, true, "Valid brush selected")
assert_eq(ed.current_brush, "bramble_2", "Current brush is bramble_2")

local ok2 = level_editor.select_brush(ed, "invalid_brush_name")
assert_eq(ok2, false, "Invalid brush rejected")
assert_eq(ed.current_brush, "bramble_2", "Brush unchanged")

-- Test 3: Grid painting
level_editor.paint_cell(ed, 3, 4)
assert_eq(ed.cells[4][3].obstacle.type, "bramble", "Bramble obstacle painted at (3,4)")
assert_eq(ed.cells[4][3].obstacle.layer, 2, "Bramble layer is 2")

level_editor.select_brush(ed, "disabled")
level_editor.paint_cell(ed, 1, 1)
assert_eq(ed.cells[1][1].active, false, "Cell (1,1) disabled")

-- Test 4: Export JSON and schema compliance
local json_str = level_editor.export_json(ed)
assert_eq(type(json_str), "string", "Exported JSON is a string")

local parsed = level_loader.parse(json_str)
assert_eq(parsed.grid.width, 8, "Parsed export width is 8")
assert_eq(parsed.grid.height, 8, "Parsed export height is 8")
local valid, err = level_loader.validate_schema(parsed)
assert_eq(valid, true, "Exported JSON passes schema validation: " .. tostring(err))

-- Test 5: Loading existing level into editor
local l1 = level_loader.load_from_file("assets/levels/level_001.json")
level_editor.load_level(ed, l1)
assert_eq(ed.level_id, 1, "Level ID loaded into editor")
assert_eq(ed.moves, 26, "Move allowance loaded into editor")

print(string.format("All tests passed! (%d/%d assertions)", passed_tests, total_tests))
