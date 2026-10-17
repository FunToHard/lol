--- Catalog defining woodland village areas, unlock requirements, and spatial bounds.
-- Manages multi-area progression from Hearthstone Courtyard to Whispering Willow Pond and Firefly Ridge.
-- @module area_catalog

local area_catalog = {}

area_catalog.AREAS = {
    {
        id = "hearthstone_courtyard",
        index = 1,
        name = "Hearthstone Courtyard",
        subtitle = "The Ancient Plaza",
        description = "The historic center of Lantern Grove. Its cold stone hearth and grand pavilion await rekindling.",
        level_range = "Levels 1–25",
        total_tasks = 12,
        required_tasks = 0,
        required_level = 1,
        ambient_color = { r = 0.95, g = 0.85, b = 0.65, a = 1.0 },
        camera_center = { x = 360, y = 640 },
        bounds = { min_x = 0, max_x = 720, min_y = 0, max_y = 1280 }
    },
    {
        id = "whispering_willow_pond",
        index = 2,
        name = "Whispering Willow Pond",
        subtitle = "The Water-Lantern Basin",
        description = "A serene waterway shaded by ancient willows. Its arched wooden bridge and water lanterns are lost in mist.",
        level_range = "Levels 26–55",
        total_tasks = 16,
        required_tasks = 12,
        required_level = 25,
        ambient_color = { r = 0.55, g = 0.75, b = 0.95, a = 1.0 },
        camera_center = { x = 1080, y = 640 },
        bounds = { min_x = 720, max_x = 1440, min_y = 0, max_y = 1280 }
    },
    {
        id = "firefly_ridge",
        index = 3,
        name = "Firefly Ridge",
        subtitle = "The Celestial Shrine",
        description = "The highest peak of the grove, home to the stargazing tower and celestial wind chimes.",
        level_range = "Levels 56–90",
        total_tasks = 20,
        required_tasks = 28,
        required_level = 55,
        ambient_color = { r = 0.85, g = 0.65, b = 1.0, a = 1.0 },
        camera_center = { x = 1800, y = 640 },
        bounds = { min_x = 1440, max_x = 2160, min_y = 0, max_y = 1280 }
    }
}

--- Retrieves an area definition by identifier.
-- @param area_id string Unique area identifier.
-- @return table|nil area Area descriptor or nil if not found.
function area_catalog.get_area(area_id)
    for _, a in ipairs(area_catalog.AREAS) do
        if a.id == area_id then
            return a
        end
    end
    return nil
end

--- Retrieves an area definition by its numeric order index (1..3).
-- @param index number 1-indexed area order.
-- @return table|nil area Area descriptor or nil.
function area_catalog.get_area_by_index(index)
    return area_catalog.AREAS[index]
end

--- Evaluates whether an area is unlocked based on total completed tasks and player level.
-- @param area_id string Unique area identifier.
-- @param total_completed_tasks number Total completed tasks across the village.
-- @param player_max_level number Highest unlocked level number.
-- @return boolean is_unlocked True if area requirements are satisfied.
function area_catalog.is_area_unlocked(area_id, total_completed_tasks, player_max_level)
    local area = area_catalog.get_area(area_id)
    if not area then return false end
    if area.index == 1 then return true end

    local tasks = total_completed_tasks or 0
    local level = player_max_level or 1

    return (tasks >= area.required_tasks) or (level >= area.required_level)
end

--- Calculates unlock progress percentage and requirement details for an area.
-- @param area_id string Unique area identifier.
-- @param total_completed_tasks number Total completed tasks across the village.
-- @param player_max_level number Highest unlocked level number.
-- @return table progress Info table { is_unlocked, percent, req_tasks, req_level, current_tasks, current_level }.
function area_catalog.get_unlock_progress(area_id, total_completed_tasks, player_max_level)
    local area = area_catalog.get_area(area_id)
    if not area then
        return { is_unlocked = false, percent = 0 }
    end

    local tasks = total_completed_tasks or 0
    local level = player_max_level or 1
    local unlocked = area_catalog.is_area_unlocked(area_id, tasks, level)

    local task_pct = (area.required_tasks > 0) and math.min(100, math.floor((tasks / area.required_tasks) * 100)) or 100
    local level_pct = (area.required_level > 1) and math.min(100, math.floor((level / area.required_level) * 100)) or 100
    local best_pct = unlocked and 100 or math.max(task_pct, level_pct)

    return {
        is_unlocked = unlocked,
        percent = best_pct,
        required_tasks = area.required_tasks,
        required_level = area.required_level,
        current_tasks = tasks,
        current_level = level
    }
end

return area_catalog
