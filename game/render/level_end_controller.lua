--- View-model controller governing victory fanfare rewards and out-of-moves continuation popups.
-- Integrates level tracker evaluations with level flow economy transactions and save data.
-- @module level_end_controller

local level_end_controller = {}

--- Computes the star rating (1 to 3 stars) awarded for completing a level.
-- 1 Star: Level goals satisfied.
-- 2 Stars: >= 20% remaining move allowance.
-- 3 Stars: >= 40% remaining move allowance.
-- @param moves_remaining number Moves remaining when goals were completed.
-- @param total_moves number Total move budget for the level.
-- @return number stars Star rating between 1 and 3.
function level_end_controller.calculate_star_rating(moves_remaining, total_moves)
    if not total_moves or total_moves <= 0 then return 1 end
    local remaining = math.max(0, moves_remaining or 0)
    local ratio = remaining / total_moves
    if ratio >= 0.40 then
        return 3
    elseif ratio >= 0.20 then
        return 2
    else
        return 1
    end
end

--- Creates a new level end controller state instance.
-- @param level_id number Numeric identifier of the finished level.
-- @param tracker table Active level tracker instance.
-- @param flow_inst table Active level flow controller instance.
-- @return table state Initialized controller state table.
function level_end_controller.new(level_id, tracker, flow_inst)
    local moves_left = tracker and tracker.moves_remaining or 0
    local total_m = tracker and tracker.total_moves or 25
    local stars = level_end_controller.calculate_star_rating(moves_left, total_m)

    return {
        level_id = level_id or 1,
        tracker = tracker,
        flow = flow_inst,
        stars_awarded = stars,
        coins_reward = 50,
        stars_reward = 1,
        mode = "NONE", -- "VICTORY", "DEFEAT", or "NONE"
        is_visible = false,
        claimed = false,
        continuation_succeeded = false,
        event_log = {}
    }
end

--- Activates the victory fanfare modal state.
-- @param state table Controller state instance.
-- @return table view Presentation-ready snapshot for UI view binding.
function level_end_controller.show_victory(state)
    state.mode = "VICTORY"
    state.is_visible = true
    table.insert(state.event_log, { event = "shown_victory", stars = state.stars_awarded })
    return level_end_controller.get_view_data(state)
end

--- Activates the out-of-moves continuation modal state.
-- @param state table Controller state instance.
-- @return table view Presentation-ready snapshot for UI view binding.
function level_end_controller.show_defeat(state)
    state.mode = "DEFEAT"
    state.is_visible = true
    table.insert(state.event_log, { event = "shown_defeat" })
    return level_end_controller.get_view_data(state)
end

--- Claims victory rewards (+1 Star Spark, +50 Coins) via level_flow.
-- @param state table Controller state instance.
-- @return table|nil reward Summary of granted rewards if claimed, or nil if already claimed.
function level_end_controller.claim_victory(state)
    if state.claimed then return nil end
    state.claimed = true
    local reward = nil
    if state.flow and state.flow.on_level_won then
        reward = state.flow:on_level_won()
    else
        reward = { stars = state.stars_reward, coins = state.coins_reward, next_level = state.level_id + 1 }
    end
    table.insert(state.event_log, { event = "victory_claimed", reward = reward })
    return reward
end

--- Purchases +5 extra moves using 900 coins via level_flow.
-- @param state table Controller state instance.
-- @return boolean success True if continuation succeeded.
-- @return string|nil error_code Error explanation if purchase failed.
function level_end_controller.buy_coin_continuation(state)
    if not state.flow or not state.tracker then
        return false, "MISSING_FLOW_OR_TRACKER"
    end
    local ok, moves_added, err = state.flow:buy_extra_moves_with_coins(state.tracker)
    if ok then
        state.mode = "NONE"
        state.is_visible = false
        state.continuation_succeeded = true
        table.insert(state.event_log, { event = "continued_with_coins", moves_added = moves_added })
        return true, nil
    end
    return false, err
end

--- Grants +3 extra moves by watching 1 rewarded ad via level_flow.
-- @param state table Controller state instance.
-- @param on_complete fun(success: boolean, err: string|nil) Completion callback.
function level_end_controller.watch_ad_continuation(state, on_complete)
    if not state.flow or not state.tracker then
        if on_complete then on_complete(false, "MISSING_FLOW_OR_TRACKER") end
        return
    end

    local ad_fn = state.flow.watch_ad_for_extra_moves or state.flow.use_rewarded_ad_continuation
    if not ad_fn then
        if on_complete then on_complete(false, "UNSUPPORTED_FLOW_METHOD") end
        return
    end

    ad_fn(state.flow, state.tracker, function(ok, moves_added, err)
        if ok then
            state.mode = "NONE"
            state.is_visible = false
            state.continuation_succeeded = true
            table.insert(state.event_log, { event = "continued_with_ad", moves = moves_added })
        end
        if on_complete then on_complete(ok, err) end
    end)
end

--- Generates presentation snapshot for GUI view binding.
-- @param state table Controller state instance.
-- @return table view Presentation snapshot table.
function level_end_controller.get_view_data(state)
    local can_afford_coins = false
    local can_watch_ad = false

    if state.flow then
        if state.flow.can_afford_coin_continuation then
            can_afford_coins = state.flow:can_afford_coin_continuation()
        end
        if state.flow.can_use_ad_continuation then
            can_watch_ad = state.flow:can_use_ad_continuation()
        end
    end

    return {
        level_id = state.level_id,
        mode = state.mode,
        is_visible = state.is_visible,
        stars_awarded = state.stars_awarded,
        coins_reward = state.coins_reward,
        stars_reward = state.stars_reward,
        can_afford_coins = can_afford_coins,
        can_watch_ad = can_watch_ad,
        claimed = state.claimed
    }
end

return level_end_controller
