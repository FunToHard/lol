# Economy & Inventory (`game/economy`)

## Responsibility
Manages player balances of Lantern Sparks (stars), Coins, and countable booster items. Guarantees idempotent transactions so rewards and purchases cannot duplicate.

## Boundary Rules
- **MUST OWN:** Currency balances, booster inventories, transaction history ledger (`op_id`).
- **MUST NOT OWN:** Store SDK callbacks, ad presentation logic, or board rendering.
- **Authority:** Local transactions use deterministic ledger entries (`op_id -> balance_delta -> reason`).
