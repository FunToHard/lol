--- Level lifecycle controller managing victory fanfares, star grants, and out-of-moves continuations.
-- Enforces fair continuation rules: 900 coins (+5 moves) or 1 rewarded ad (+3 moves).
-- @module level_flow

local ledger = require("game.economy.ledger")
local save_manager = require("game.persistence.save_manager")

local level_flow = {}

level_flow.COIN_CONTINUATION_COST = 900
level_flow.COIN_CONTINUATION_MOVES = 5
level_flow.AD_CONTINUATION_MOVES = 3
level_flow.LEVEL_VICTORY_COINS = 50

--- Creates a new level flow controller instance for an active gameplay session.
-- @param econ_ledger table Economy ledger state table.
-- @param ads_svc table Configured ads service instance.
-- @param save_data table Active player save data table.
-- @param level_id number Current numeric level ID.
-- @param base_dir string|nil Optional custom directory path for save persistence.
-- @return table controller Initialized level flow controller table.
function level_flow.new(econ_ledger, ads_svc, save_data, level_id, base_dir)
    assert(type(econ_ledger) == "table", "level_flow requires an economy ledger")
    assert(type(ads_svc) == "table", "level_flow requires an ads service")
    assert(type(save_data) == "table", "level_flow requires save data")

    local instance = {
        ledger = econ_ledger,
        ads_service = ads_svc,
        save_data = save_data,
        level_id = level_id or 1,
        base_dir = base_dir,
        ad_continuation_used = false
    }
    setmetatable(instance, { __index = level_flow })
    return instance
end

--- Handles the victory sequence upon level completion.
-- Atomically grants 1 Lantern Spark (Star) and milestone coins, advances progression, and saves.
-- @param self table Level flow controller instance.
-- @return table reward Summary of granted rewards { stars, coins, next_level }.
function level_flow.on_level_won(self)
    local lvl_id = self.level_id
    local op_star = string.format("op_win_star_lvl_%d_%d", lvl_id, self.save_data.created_at or 0)
    local op_coin = string.format("op_win_coins_lvl_%d_%d", lvl_id, self.save_data.created_at or 0)

    -- 1. Grant 1 Star (Lantern Spark)
    ledger.apply_transaction(self.ledger, op_star, "stars", 1, "level_win:" .. lvl_id)

    -- 2. Grant Milestone Coins
    ledger.apply_transaction(self.ledger, op_coin, "coins", level_flow.LEVEL_VICTORY_COINS, "level_win_coins:" .. lvl_id)

    -- 3. Update progression
    local prog = self.save_data.progression
    prog.completed_levels[tostring(lvl_id)] = 3
    prog.max_unlocked_level = math.max(prog.max_unlocked_level or 1, lvl_id + 1)

    -- 4. Sync player save state
    self.save_data.player.stars = ledger.get_balance(self.ledger, "stars")
    self.save_data.player.coins = ledger.get_balance(self.ledger, "coins")
    self.save_data.ledger_history = self.ledger.history
    save_manager.save(self.save_data, self.base_dir)

    return {
        stars = 1,
        coins = level_flow.LEVEL_VICTORY_COINS,
        next_level = lvl_id + 1
    }
end

--- Checks if the player can afford the 900-coin continuation (+5 moves).
-- @param self table Level flow controller instance.
-- @return boolean can_afford True if player has at least 900 coins.
function level_flow.can_afford_coin_continuation(self)
    return ledger.can_afford(self.ledger, "coins", level_flow.COIN_CONTINUATION_COST)
end

--- Applies a 900-coin continuation to add +5 extra moves.
-- @param self table Level flow controller instance.
-- @param tracker table Level tracker instance to receive extra moves.
-- @return boolean success True if continuation succeeded and moves were granted.
-- @return number moves_added Number of extra moves added (5 or 0).
-- @return string|nil error_code "INSUFFICIENT_COINS" if purchase failed.
function level_flow.buy_extra_moves_with_coins(self, tracker)
    if not level_flow.can_afford_coin_continuation(self) then
        return false, 0, "INSUFFICIENT_COINS"
    end

    local op_id = string.format("op_continue_coins_lvl_%d_%d", self.level_id, os.time and os.time() or 0)
    local ok = ledger.apply_transaction(self.ledger, op_id, "coins", -level_flow.COIN_CONTINUATION_COST, "continue_moves:" .. self.level_id)
    if not ok then
        return false, 0, "INSUFFICIENT_COINS"
    end

    tracker.moves_remaining = tracker.moves_remaining + level_flow.COIN_CONTINUATION_MOVES
    tracker.status = "IN_PROGRESS"

    self.save_data.player.coins = ledger.get_balance(self.ledger, "coins")
    self.save_data.ledger_history = self.ledger.history
    save_manager.save(self.save_data, self.base_dir)

    return true, level_flow.COIN_CONTINUATION_MOVES, nil
end

--- Checks if the rewarded ad continuation (+3 moves) is currently available.
-- @param self table Level flow controller instance.
-- @return boolean is_available True if ad continuation has not yet been used this level attempt.
function level_flow.can_use_ad_continuation(self)
    if self.ad_continuation_used then return false end
    return self.ads_service:is_rewarded_ready()
end

--- Presents a rewarded ad to earn +3 extra moves (capped at 1 ad continuation per attempt).
-- @param self table Level flow controller instance.
-- @param tracker table Level tracker instance to receive extra moves.
-- @param on_complete function Completion callback: `on_complete(success, moves_added, error_or_reason)`.
function level_flow.watch_ad_for_extra_moves(self, tracker, on_complete)
    if self.ad_continuation_used then
        if on_complete then on_complete(false, 0, "AD_CONTINUATION_EXHAUSTED") end
        return
    end

    self.ads_service:show_rewarded(function()
        self.ad_continuation_used = true
        tracker.moves_remaining = tracker.moves_remaining + level_flow.AD_CONTINUATION_MOVES
        tracker.status = "IN_PROGRESS"

        if on_complete then
            on_complete(true, level_flow.AD_CONTINUATION_MOVES, "REWARD_GRANTED")
        end
    end, nil, function(err_msg)
        if on_complete then
            on_complete(false, 0, err_msg or "AD_FAILED")
        end
    end)
end

return level_flow
