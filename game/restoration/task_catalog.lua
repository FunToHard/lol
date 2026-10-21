--- Task catalog defining renovation tasks and aesthetic themes for Area 1 (Hearthstone Courtyard).
-- Specifies star costs, prop identifiers, and 3-style customization options.
-- @module task_catalog

local task_catalog = {}

task_catalog.AREA_1_ID = "hearthstone_courtyard"

local AREA_1_TASKS = {
    {
        id = "clear_ruined_leaves",
        title = "Sweep Fallen Autumn Leaves",
        cost = 1,
        styles = {
            { id = "rustic_broom", name = "Woven Birch Broom" },
            { id = "mossy_rake", name = "River Reed Rake" },
            { id = "whimsical_gust", name = "Breezy Feather Fan" }
        }
    },
    {
        id = "repair_stone_hearth",
        title = "Restore Central Stone Hearth",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Rustic Cedar Mantel" },
            { id = "mossy_stone", name = "Mossy River Stone" },
            { id = "whimsical_crystal", name = "Whimsical Amethyst Inlay" }
        }
    },
    {
        id = "light_first_lantern",
        title = "Hang Courtyard Entrance Lantern",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Carved Cedar Lantern" },
            { id = "mossy_stone", name = "Verdigris Copper Lantern" },
            { id = "whimsical_crystal", name = "Glowing Firefly Orb" }
        }
    },
    {
        id = "rebuild_wooden_benches",
        title = "Craft Cozy Resting Benches",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Carved Oak Log" },
            { id = "mossy_stone", name = "Moss Cushioned Slate" },
            { id = "whimsical_crystal", name = "Moonlit Wisteria Arbor" }
        }
    },
    {
        id = "restore_village_well",
        title = "Clean the Wishing Well",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Timber Shingle Canopy" },
            { id = "mossy_stone", name = "Cobblestone Basin" },
            { id = "whimsical_crystal", name = "Starfall Shimmer Well" }
        }
    },
    {
        id = "plant_flower_beds",
        title = "Plant Woodland Flower Borders",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Golden Autumn Marigolds" },
            { id = "mossy_stone", name = "Wild Ferns & Moss" },
            { id = "whimsical_crystal", name = "Luminescent Bluebells" }
        }
    },
    {
        id = "repair_courtyard_paving",
        title = "Relay Flagstone Pathways",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Timber Board Plank Path" },
            { id = "mossy_stone", name = "Natural River Cobble" },
            { id = "whimsical_crystal", name = "Starlight Embedded Stone" }
        }
    },
    {
        id = "construct_birdhouse",
        title = "Erect Pip's Owl Roost",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Cedar Bark Birdhouse" },
            { id = "mossy_stone", name = "Stone Garden Pagoda" },
            { id = "whimsical_crystal", name = "Hanging Crystal Nest" }
        }
    },
    {
        id = "hang_garden_lights",
        title = "String Canopy Fairy Lights",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Warm Amber Filament" },
            { id = "mossy_stone", name = "Verdigris Glass Bells" },
            { id = "whimsical_crystal", name = "Sparkling Prisms" }
        }
    },
    {
        id = "rebuild_teahouse_kiosk",
        title = "Assemble Woodland Teahouse",
        cost = 2,
        styles = {
            { id = "rustic_cedar", name = "Rustic Timber Gazebo" },
            { id = "mossy_stone", name = "Moss-Topped Stone Pavilion" },
            { id = "whimsical_crystal", name = "Twilight Crystal Pagoda" }
        }
    },
    {
        id = "place_tea_table_and_seats",
        title = "Furnish the Tea Kiosk",
        cost = 1,
        styles = {
            { id = "rustic_cedar", name = "Polished Tree Slice Table" },
            { id = "mossy_stone", name = "Carved Granite Bistro" },
            { id = "whimsical_crystal", name = "Shimmering Geode Table" }
        }
    },
    {
        id = "light_central_bonfire",
        title = "Kindle the Great Hearth Flame",
        cost = 2,
        styles = {
            { id = "rustic_cedar", name = "Roaring Birch Bonfire" },
            { id = "mossy_stone", name = "Ancestral Stone Brazier" },
            { id = "whimsical_crystal", name = "Enchanted Violet Flame" }
        }
    }
}

--- Retrieves the list of all tasks defined for a specific village area.
-- @param area_id string|nil Target area ID (defaults to Area 1 "hearthstone_courtyard").
-- @return table tasks Array of task definitions.
function task_catalog.get_tasks_for_area(area_id)
    local id = area_id or task_catalog.AREA_1_ID
    if id == task_catalog.AREA_1_ID then
        return AREA_1_TASKS
    end
    return {}
end

--- Retrieves a single task definition by its unique identifier.
-- @param task_id string Task identifier (e.g. "repair_stone_hearth").
-- @return table|nil task Task definition table or nil if not found.
function task_catalog.get_task(task_id)
    for _, t in ipairs(AREA_1_TASKS) do
        if t.id == task_id then
            return t
        end
    end
    return nil
end

return task_catalog
