# Economy & Inventory (`game/economy`)

## 1. Directory Responsibility
Manages player balances of Lantern Sparks (Stars), Coins, and countable booster items (`hammer`, `rocket`, `bomb`). Guarantees idempotent transactions so rewards and purchases cannot duplicate.

## 2. Public API Contract
* `ledger.new(initial_state)`: Creates an isolated economy ledger state with currency balances, booster inventories, and transaction history.
* `ledger.get_balance(state, key)`: Queries current balance of `"stars"`, `"coins"`, or boosters.
* `ledger.can_afford(state, key, amount)`: Non-mutating balance check.
* `ledger.apply_transaction(state, op_id, key, delta, reason)`: Idempotent transaction executor enforcing non-negative balances and recording unique `op_id` audit records.

## 3. Strict Inclusions
* Currency and booster balance calculations.
* Idempotent double-spend and duplicate grant protection.
* Pure Lua simulation without UI dependencies.

## 4. Strict Exclusions
* **Network & IAP Billing:** Must never make direct Google Play Billing or ads network calls (handled by `game/services`).
* **Disk I/O:** Must never write save files directly to disk (handled by `game/persistence`).
