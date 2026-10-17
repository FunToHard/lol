--- Idempotent transaction ledger managing player currencies and consumables.
-- Guarantees double-spend and duplicate grant protection via operation IDs.
-- @module ledger

local ledger = {}

--- Creates a new ledger instance initialized with default or existing state.
-- @param initial_state table|nil Optional existing state table containing balances and history.
-- @return table state Initialized ledger state table.
function ledger.new(initial_state)
    local s = initial_state or {}
    return {
        balances = {
            stars = (s.balances and s.balances.stars) or 0,
            coins = (s.balances and s.balances.coins) or 0,
            boosters = {
                hammer = (s.balances and s.balances.boosters and s.balances.boosters.hammer) or 0,
                rocket = (s.balances and s.balances.boosters and s.balances.boosters.rocket) or 0,
                bomb = (s.balances and s.balances.boosters and s.balances.boosters.bomb) or 0
            }
        },
        history = s.history or {}
    }
end

--- Retrieves the current balance of a currency or booster item.
-- @param state table The active ledger state table.
-- @param key string Item identifier ("stars", "coins", "hammer", "rocket", "bomb").
-- @return number balance Current quantity owned.
function ledger.get_balance(state, key)
    if key == "stars" or key == "coins" then
        return state.balances[key] or 0
    elseif state.balances.boosters and state.balances.boosters[key] ~= nil then
        return state.balances.boosters[key]
    end
    return 0
end

--- Checks if the player owns at least the required amount of an item.
-- @param state table The active ledger state table.
-- @param key string Item identifier.
-- @param amount number Required quantity.
-- @return boolean can_afford True if balance is greater than or equal to amount.
function ledger.can_afford(state, key, amount)
    local req = amount or 1
    return ledger.get_balance(state, key) >= req
end

--- Applies an idempotent transaction to modify a balance by delta.
-- Rejects duplicate transactions with the same operation ID without double-crediting.
-- Prevents balances from falling below zero.
-- @param state table The active ledger state table.
-- @param op_id string Unique operation identifier (e.g. "op_level_1_reward_xyz").
-- @param key string Item identifier ("stars", "coins", "hammer", "rocket", "bomb").
-- @param delta number Positive integer for grants, negative integer for spending.
-- @param reason string Human-readable audit description (e.g. "level_completion").
-- @return boolean success True if transaction was newly applied or previously processed.
-- @return number balance Resulting item balance after the operation.
-- @return string|nil error_code "INSUFFICIENT_FUNDS" or "ALREADY_PROCESSED" if applicable.
function ledger.apply_transaction(state, op_id, key, delta, reason)
    assert(type(op_id) == "string" and #op_id > 0, "Transaction requires a valid non-empty op_id string")
    assert(type(delta) == "number", "Transaction delta must be a number")

    -- Idempotency check: Return existing result if already processed
    if state.history[op_id] then
        local current_bal = ledger.get_balance(state, key)
        return true, current_bal, "ALREADY_PROCESSED"
    end

    local current = ledger.get_balance(state, key)
    if current + delta < 0 then
        return false, current, "INSUFFICIENT_FUNDS"
    end

    local new_bal = current + delta
    if key == "stars" or key == "coins" then
        state.balances[key] = new_bal
    elseif state.balances.boosters and state.balances.boosters[key] ~= nil then
        state.balances.boosters[key] = new_bal
    else
        error("Unsupported currency or booster key: " .. tostring(key))
    end

    state.history[op_id] = {
        timestamp = os.time and os.time() or 0,
        key = key,
        delta = delta,
        reason = reason or "unspecified",
        balance_after = new_bal
    }

    return true, new_bal, nil
end

return ledger
