--- View-model controller managing visual prop layering, coordinates, and style tinting.
-- Translates task completions and 3-style selections into 2.5D visual diorama state.
-- @module prop_layer_controller

local prop_layer_controller = {}

-- Visual color tints corresponding to the 3 aesthetic styles
prop_layer_controller.STYLE_TINTS = {
    [1] = { r = 1.0,  g = 0.85, b = 0.6,  a = 1.0, name = "Rustic Cedar" },
    [2] = { r = 0.7,  g = 1.0,  b = 0.75, a = 1.0, name = "Mossy Stone" },
    [3] = { r = 0.9,  g = 0.7,  b = 1.0,  a = 1.0, name = "Whimsical Crystal" }
}

-- 12 Area 1 Restoration Props & Spatial Coordinates in the 720x1280 Diorama
prop_layer_controller.PROPS = {
    {
        task_id = "clear_ruined_leaves",
        prop_id = "leaves",
        pos = { x = 360, y = 320, z = 0.05 },
        scale = { x = 1.2, y = 1.2, z = 1.0 },
        sprite = "cell_slot"
    },
    {
        task_id = "repair_stone_hearth",
        prop_id = "hearth",
        pos = { x = 360, y = 520, z = 0.1 },
        scale = { x = 1.4, y = 1.4, z = 1.0 },
        sprite = "village_hearth"
    },
    {
        task_id = "light_first_lantern",
        prop_id = "lantern_1",
        pos = { x = 180, y = 780, z = 0.2 },
        scale = { x = 1.0, y = 1.0, z = 1.0 },
        sprite = "village_lantern"
    },
    {
        task_id = "rebuild_wooden_benches",
        prop_id = "bench",
        pos = { x = 540, y = 460, z = 0.1 },
        scale = { x = 1.1, y = 0.9, z = 1.0 },
        sprite = "village_bench"
    },
    {
        task_id = "restore_village_well",
        prop_id = "well",
        pos = { x = 200, y = 420, z = 0.1 },
        scale = { x = 1.3, y = 1.3, z = 1.0 },
        sprite = "village_well"
    },
    {
        task_id = "plant_flower_beds",
        prop_id = "flower_beds",
        pos = { x = 360, y = 360, z = 0.08 },
        scale = { x = 1.0, y = 1.0, z = 1.0 },
        sprite = "ingredient_acorn"
    },
    {
        task_id = "repair_courtyard_paving",
        prop_id = "paving",
        pos = { x = 360, y = 440, z = 0.02 },
        scale = { x = 1.5, y = 1.5, z = 1.0 },
        sprite = "cell_slot"
    },
    {
        task_id = "construct_birdhouse",
        prop_id = "birdhouse",
        pos = { x = 160, y = 600, z = 0.15 },
        scale = { x = 1.1, y = 1.1, z = 1.0 },
        sprite = "obstacle_bramble_1"
    },
    {
        task_id = "hang_garden_lights",
        prop_id = "garden_lights",
        pos = { x = 360, y = 720, z = 0.25 },
        scale = { x = 1.2, y = 0.8, z = 1.0 },
        sprite = "powerup_firefly"
    },
    {
        task_id = "rebuild_teahouse_kiosk",
        prop_id = "teahouse",
        pos = { x = 580, y = 700, z = 0.18 },
        scale = { x = 1.3, y = 1.3, z = 1.0 },
        sprite = "village_teahouse"
    },
    {
        task_id = "place_tea_table_and_seats",
        prop_id = "tea_table",
        pos = { x = 480, y = 540, z = 0.12 },
        scale = { x = 1.0, y = 1.0, z = 1.0 },
        sprite = "hud_goal_capsule"
    },
    {
        task_id = "light_central_bonfire",
        prop_id = "bonfire",
        pos = { x = 360, y = 880, z = 0.3 },
        scale = { x = 1.5, y = 1.5, z = 1.0 },
        sprite = "village_hearth"
    }
}

--- Evaluates the visual presentation state for a single prop based on completed tasks.
-- @param completed_tasks table Array of completed task records.
-- @param chosen_styles table Map of task_id to chosen style index (1..3).
-- @param prop_def table Prop descriptor from PROPS table.
-- @return table state Prop view snapshot table.
function prop_layer_controller.get_prop_state(completed_tasks, chosen_styles, prop_def)
    local is_restored = false
    local style_idx = nil

    if completed_tasks then
        for _, t in ipairs(completed_tasks) do
            if t.task_id == prop_def.task_id then
                is_restored = true
                style_idx = t.chosen_style
                break
            end
        end
    end

    if chosen_styles and chosen_styles[prop_def.task_id] then
        style_idx = chosen_styles[prop_def.task_id]
    end
    if not style_idx then style_idx = 1 end

    local tint_def = prop_layer_controller.STYLE_TINTS[style_idx] or prop_layer_controller.STYLE_TINTS[1]

    return {
        task_id = prop_def.task_id,
        prop_id = prop_def.prop_id,
        is_restored = is_restored,
        style_idx = style_idx,
        sprite_name = prop_def.sprite,
        pos = { x = prop_def.pos.x, y = prop_def.pos.y, z = prop_def.pos.z },
        scale = { x = prop_def.scale.x, y = prop_def.scale.y, z = prop_def.scale.z },
        tint = { r = tint_def.r, g = tint_def.g, b = tint_def.b, a = tint_def.a, name = tint_def.name }
    }
end

--- Compiles a full diorama snapshot containing all visual props and Pip companion position.
-- @param completed_tasks table Array of completed task records.
-- @param chosen_styles table Map of task_id to chosen style index.
-- @param companion_state table|nil Optional companion state instance.
-- @return table snapshot Full village visual presentation state.
function prop_layer_controller.get_diorama_snapshot(completed_tasks, chosen_styles, companion_state)
    local props_view = {}
    local restored_count = 0

    for _, prop_def in ipairs(prop_layer_controller.PROPS) do
        local state = prop_layer_controller.get_prop_state(completed_tasks, chosen_styles, prop_def)
        table.insert(props_view, state)
        if state.is_restored then
            restored_count = restored_count + 1
        end
    end

    -- Companion Pip coordinates in the courtyard
    local companion_pos = { x = 440, y = 520, z = 0.25 }
    local companion_state_name = companion_state and (companion_state.current_emote or companion_state.current_state) or "idle"
    local companion_dialogue = companion_state and companion_state.dialogue or "The courtyard is awakening!"

    return {
        total_props = #prop_layer_controller.PROPS,
        restored_count = restored_count,
        completion_percent = math.floor((restored_count / #prop_layer_controller.PROPS) * 100),
        props = props_view,
        companion = {
            pos = companion_pos,
            state = companion_state_name,
            dialogue = companion_dialogue,
            sprite_name = "powerup_firefly"
        }
    }
end

return prop_layer_controller
