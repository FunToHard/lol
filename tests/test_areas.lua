--- Unit tests for area_catalog multi-area progression and unlock requirements.
-- Usage: `lua tests/test_areas.lua`

package.path = package.path .. ";./?.lua"

local area_catalog = require("game.restoration.area_catalog")

local total_tests = 0
local passed_tests = 0

--- Asserts equality between actual and expected values.
-- @param actual any Evaluated test value.
-- @param expected any Desired reference value.
-- @param msg string Description of the assertion.
local function assert_eq(actual, expected, msg)
    total_tests = total_tests + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, Got: %s", tostring(msg), tostring(expected), tostring(actual)))
    end
    passed_tests = passed_tests + 1
end

print("--- Running Village Area Catalog & Unlock Progression Tests ---")

-- 1. Area Definitions & Total Count
assert_eq(#area_catalog.AREAS, 3, "Exactly 3 village areas defined")

local a1 = area_catalog.get_area("hearthstone_courtyard")
assert_eq(a1 ~= nil, true, "Area 1 exists")
assert_eq(a1.name, "Hearthstone Courtyard", "Area 1 name verified")
assert_eq(a1.total_tasks, 12, "Area 1 has 12 tasks")

local a2 = area_catalog.get_area("whispering_willow_pond")
assert_eq(a2 ~= nil, true, "Area 2 exists")
assert_eq(a2.name, "Whispering Willow Pond", "Area 2 name verified")
assert_eq(a2.total_tasks, 16, "Area 2 has 16 tasks")

local a3 = area_catalog.get_area("firefly_ridge")
assert_eq(a3 ~= nil, true, "Area 3 exists")
assert_eq(a3.name, "Firefly Ridge", "Area 3 name verified")

-- 2. Area 1 Always Unlocked Initially
assert_eq(area_catalog.is_area_unlocked("hearthstone_courtyard", 0, 1), true, "Area 1 unlocked initially with 0 tasks")

-- 3. Area 2 Unlock Logic (Requires 12 tasks OR level 25)
assert_eq(area_catalog.is_area_unlocked("whispering_willow_pond", 0, 1), false, "Area 2 locked initially")
assert_eq(area_catalog.is_area_unlocked("whispering_willow_pond", 11, 1), false, "Area 2 locked at 11 tasks")
assert_eq(area_catalog.is_area_unlocked("whispering_willow_pond", 12, 1), true, "Area 2 unlocks upon completing 12 tasks")
assert_eq(area_catalog.is_area_unlocked("whispering_willow_pond", 0, 25), true, "Area 2 unlocks upon reaching level 25")

-- 4. Area 3 Unlock Logic (Requires 28 tasks OR level 55)
assert_eq(area_catalog.is_area_unlocked("firefly_ridge", 12, 25), false, "Area 3 locked after Area 1")
assert_eq(area_catalog.is_area_unlocked("firefly_ridge", 28, 1), true, "Area 3 unlocks with 28 tasks")
assert_eq(area_catalog.is_area_unlocked("firefly_ridge", 0, 55), true, "Area 3 unlocks at level 55")

-- 5. Unlock Progress Percentage
local p1 = area_catalog.get_unlock_progress("whispering_willow_pond", 6, 1)
assert_eq(p1.is_unlocked, false, "Area 2 not unlocked at 6 tasks")
assert_eq(p1.percent, 50, "Area 2 progress is 50% (6/12 tasks)")

local p2 = area_catalog.get_unlock_progress("whispering_willow_pond", 12, 1)
assert_eq(p2.is_unlocked, true, "Area 2 unlocked at 12 tasks")
assert_eq(p2.percent, 100, "Progress reaches 100%")

-- 6. Spatial Camera Coordinates & Bounds
assert_eq(a1.camera_center.x, 360, "Area 1 camera centered at 360")
assert_eq(a2.camera_center.x, 1080, "Area 2 camera centered at 1080 (720 offset)")
assert_eq(a3.camera_center.x, 1800, "Area 3 camera centered at 1800 (1440 offset)")

print(string.format("All tests passed! (%d/%d assertions)\n", passed_tests, total_tests))
