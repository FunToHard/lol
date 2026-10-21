--- Pure Lua view-model controller driving the 25-Level Winding Map Path.
-- Calculates winding sinusoidal node geometry, scroll clamping, star ratings, and unlock states.
-- @module map_controller

local map_controller = {}

map_controller.TOTAL_LEVELS = 25
map_controller.BASE_Y = 280
map_controller.SPACING_Y = 130
map_controller.CENTER_X = 360
map_controller.AMPLITUDE_X = 160
map_controller.VIEW_TOP = 1100
map_controller.VIEW_BOTTOM = 180

--- Creates a new map controller state table.
-- @param save_data table Active player save data table.
-- @return table ctrl Initialized map controller table.
function map_controller.new(save_data)
    assert(type(save_data) == "table", "map_controller requires save data")

    local prog = save_data.progression or {}
    local max_unlocked = prog.max_unlocked_level or 1
    if max_unlocked < 1 then max_unlocked = 1 end
    if max_unlocked > map_controller.TOTAL_LEVELS then max_unlocked = map_controller.TOTAL_LEVELS end

    local completed_levels = prog.completed_levels or {}

    -- Calculate level positions along winding sinusoidal curve
    local levels = {}
    for i = 1, map_controller.TOTAL_LEVELS do
        -- Sinusoidal S-curve: Left -> Center -> Right -> Center -> Left
        local angle = (i - 1) * 0.75
        local x = math.floor(map_controller.CENTER_X + math.sin(angle) * map_controller.AMPLITUDE_X)
        local y = map_controller.BASE_Y + (i - 1) * map_controller.SPACING_Y

        local is_completed = (i < max_unlocked) or (completed_levels[i] ~= nil and completed_levels[i].completed == true)
        local is_unlocked = (i <= max_unlocked)
        local is_current = (i == max_unlocked)

        local stars = 0
        if completed_levels[i] and completed_levels[i].stars then
            stars = completed_levels[i].stars
        elseif is_completed then
            stars = 1
        end

        local stars_text = ""
        if stars == 3 then
            stars_text = "***"
        elseif stars == 2 then
            stars_text = "**"
        elseif stars == 1 then
            stars_text = "*"
        end

        table.insert(levels, {
            id = i,
            x = x,
            base_y = y,
            is_unlocked = is_unlocked,
            is_completed = is_completed,
            is_current = is_current,
            stars = stars,
            stars_text = stars_text
        })
    end

    local total_content_height = (map_controller.TOTAL_LEVELS - 1) * map_controller.SPACING_Y
    local max_scroll = 0
    local min_scroll = -(total_content_height - (map_controller.VIEW_TOP - map_controller.VIEW_BOTTOM - 200))
    if min_scroll > 0 then min_scroll = 0 end

    local ctrl = {
        save_data = save_data,
        levels = levels,
        max_unlocked = max_unlocked,
        scroll_y = 0,
        min_scroll_y = min_scroll,
        max_scroll_y = max_scroll,
        event_log = {}
    }

    -- Auto-center on current unlocked level
    map_controller.scroll_to_level(ctrl, max_unlocked)

    return ctrl
end

--- Centers the map view on a specific level index, clamping to valid scroll boundaries.
-- @param ctrl table Map controller state table.
-- @param level_id number Target level index (1 to 25).
function map_controller.scroll_to_level(ctrl, level_id)
    local target_lvl = ctrl.levels[level_id]
    if not target_lvl then return end

    local target_center = (map_controller.VIEW_TOP + map_controller.VIEW_BOTTOM) / 2
    local desired_scroll = target_center - target_lvl.base_y
    ctrl.scroll_y = math.max(ctrl.min_scroll_y, math.min(ctrl.max_scroll_y, desired_scroll))
    table.insert(ctrl.event_log, { event = "scroll_to_level", level = level_id, scroll_y = ctrl.scroll_y })
end

--- Offsets the map vertical scroll by a touch drag delta.
-- @param ctrl table Map controller state table.
-- @param delta_y number Drag distance in pixels.
-- @return number scroll_y Resulting clamped scroll position.
function map_controller.scroll_by(ctrl, delta_y)
    ctrl.scroll_y = math.max(ctrl.min_scroll_y, math.min(ctrl.max_scroll_y, ctrl.scroll_y + delta_y))
    return ctrl.scroll_y
end

--- Generates a presentation snapshot containing view coordinates and visibility flags for all 25 levels.
-- @param ctrl table Map controller state table.
-- @return table view Presentation snapshot table.
function map_controller.get_view_data(ctrl)
    local stars_total = ctrl.save_data.player and ctrl.save_data.player.stars or 0
    local coins = ctrl.save_data.player and ctrl.save_data.player.coins or 0

    local level_views = {}
    for _, lvl in ipairs(ctrl.levels) do
        local screen_y = lvl.base_y + ctrl.scroll_y
        local is_visible = (screen_y >= (map_controller.VIEW_BOTTOM - 60) and screen_y <= (map_controller.VIEW_TOP + 60))

        table.insert(level_views, {
            id = lvl.id,
            screen_x = lvl.x,
            screen_y = screen_y,
            is_visible = is_visible,
            is_unlocked = lvl.is_unlocked,
            is_completed = lvl.is_completed,
            is_current = lvl.is_current,
            stars = lvl.stars,
            stars_text = lvl.stars_text
        })
    end

    return {
        stars = stars_total,
        coins = coins,
        max_unlocked = ctrl.max_unlocked,
        scroll_y = ctrl.scroll_y,
        levels = level_views
    }
end

return map_controller
