--- View-model controller managing in-game tactical boosters (Hammer, Row Cleaver Rocket, Bomb).
-- Coordinates booster selection, cell targeting, and atomic inventory deductions via the economy ledger.
-- @module booster_controller

local ledger = require("game.economy.ledger")
local grid = require("game.board.grid")

local booster_controller = {}

booster_controller.BOOSTER_TYPES = {
    HAMMER = "hammer",
    ROCKET = "rocket",
    BOMB = "bomb"
}

--- Creates a new booster controller instance backed by the player economy ledger.
-- @param econ_ledger table Active economy ledger instance.
-- @return table ctrl Initialized booster controller state table.
function booster_controller.new(econ_ledger)
    assert(type(econ_ledger) == "table", "booster_controller requires an economy ledger instance")
    return {
        ledger = econ_ledger,
        active_booster = nil,
        event_log = {}
    }
end

--- Selects or toggles an in-game booster tool for target placement on the board.
-- Tapping the currently active booster deselects it.
-- @param ctrl table Controller state table.
-- @param booster_key string Booster identifier ("hammer", "rocket", "bomb").
-- @return boolean success True if selection state changed or was cleared.
-- @return string|nil active_or_err Active booster key, nil if deselected, or error reason.
function booster_controller.select_booster(ctrl, booster_key)
    if not booster_key or not booster_controller.BOOSTER_TYPES[booster_key:upper()] then
        return false, "INVALID_BOOSTER_TYPE"
    end

    -- Toggle off if currently active
    if ctrl.active_booster == booster_key then
        ctrl.active_booster = nil
        table.insert(ctrl.event_log, { event = "booster_deselected", booster = booster_key })
        return true, nil
    end

    -- Check inventory affordability
    if not ledger.can_afford(ctrl.ledger, booster_key, 1) then
        return false, "INSUFFICIENT_INVENTORY"
    end

    ctrl.active_booster = booster_key
    table.insert(ctrl.event_log, { event = "booster_selected", booster = booster_key })
    return true, booster_key
end

--- Cancels any active booster targeting mode.
-- @param ctrl table Controller state table.
function booster_controller.cancel_selection(ctrl)
    ctrl.active_booster = nil
    table.insert(ctrl.event_log, { event = "targeting_cancelled" })
end

--- Validates whether the active booster can be deployed onto the target grid coordinates.
-- @param ctrl table Controller state table.
-- @param board table Active board grid instance.
-- @param gx number Column coordinate (1-indexed).
-- @param gy number Row coordinate (1-indexed).
-- @return boolean can_use True if cell is valid and active on the board.
function booster_controller.can_use_on_cell(ctrl, board, gx, gy)
    if not ctrl.active_booster then return false end
    if not board or gx < 1 or gx > board.width or gy < 1 or gy > board.height then
        return false
    end
    local c = grid.get(board, gx, gy)
    return c ~= nil and c.is_enabled ~= false
end

--- Applies the active booster to the target grid cell and deducts 1 count from player inventory.
-- @param ctrl table Controller state table.
-- @param board table Active board grid instance.
-- @param gx number Target column coordinate (1-indexed).
-- @param gy number Target row coordinate (1-indexed).
-- @param op_id string|nil Optional unique idempotency transaction ID.
-- @return boolean success True if booster was successfully applied.
-- @return table|string result_or_err Result table with affected cells or error description.
function booster_controller.apply_to_cell(ctrl, board, gx, gy, op_id)
    if not ctrl.active_booster then
        return false, "NO_ACTIVE_BOOSTER"
    end
    if not booster_controller.can_use_on_cell(ctrl, board, gx, gy) then
        return false, "INVALID_TARGET_CELL"
    end

    local b_type = ctrl.active_booster
    local affected = {}

    if b_type == booster_controller.BOOSTER_TYPES.HAMMER then
        -- Single target cell smash
        table.insert(affected, { x = gx, y = gy })
    elseif b_type == booster_controller.BOOSTER_TYPES.ROCKET then
        -- Full horizontal row cleave
        for x = 1, board.width do
            local c = grid.get(board, x, gy)
            if c and c.is_enabled ~= false then
                table.insert(affected, { x = x, y = gy })
            end
        end
    elseif b_type == booster_controller.BOOSTER_TYPES.BOMB then
        -- 3x3 surrounding radius blast
        for y = math.max(1, gy - 1), math.min(board.height, gy + 1) do
            for x = math.max(1, gx - 1), math.min(board.width, gx + 1) do
                local c = grid.get(board, x, y)
                if c and c.is_enabled ~= false then
                    table.insert(affected, { x = x, y = y })
                end
            end
        end
    end

    -- Deduct 1 item from inventory ledger
    local tx_id = op_id or string.format("op_booster_%s_%d_%d_%d", b_type, gx, gy, os.time and os.time() or 0)
    local ok_deduct, balance, err = ledger.apply_transaction(ctrl.ledger, tx_id, b_type, -1, "tactical_booster_use")
    if not ok_deduct then
        return false, err or "INVENTORY_DEDUCTION_FAILED"
    end

    ctrl.active_booster = nil
    local result = {
        booster = b_type,
        target = { x = gx, y = gy },
        cells = affected,
        remaining_balance = balance
    }
    table.insert(ctrl.event_log, { event = "booster_applied", result = result })
    return true, result
end

--- Compiles a presentation snapshot for HUD booster dock view binding.
-- @param ctrl table Controller state table.
-- @return table view Presentation snapshot table.
function booster_controller.get_view_data(ctrl)
    local hammer_qty = ledger.get_balance(ctrl.ledger, "hammer")
    local rocket_qty = ledger.get_balance(ctrl.ledger, "rocket")
    local bomb_qty = ledger.get_balance(ctrl.ledger, "bomb")

    return {
        active_booster = ctrl.active_booster,
        is_targeting = (ctrl.active_booster ~= nil),
        boosters = {
            hammer = { quantity = hammer_qty, can_select = hammer_qty > 0, is_selected = (ctrl.active_booster == "hammer") },
            rocket = { quantity = rocket_qty, can_select = rocket_qty > 0, is_selected = (ctrl.active_booster == "rocket") },
            bomb = { quantity = bomb_qty, can_select = bomb_qty > 0, is_selected = (ctrl.active_booster == "bomb") }
        }
    }
end

return booster_controller
