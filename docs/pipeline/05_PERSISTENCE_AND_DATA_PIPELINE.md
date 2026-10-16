# Pipeline Stage 5: Persistence, Save Data & Conflict Resolution

**Goal:** Guarantee 100% data durability—zero progress loss, zero save corruption, and safe offline-to-cloud synchronization.

---

## 1. Local Persistence Architecture (Offline-First)

The game must boot, play, and save without internet connectivity.

### The Atomic Two-File Commit Pattern
On mobile devices, an app can be terminated by Android OS (OOM killer or low battery) at any millisecond during disk writes. Writing directly into `save.json` can cause catastrophic 0-byte file corruption.

```
[ In-Memory Save Data ]
           │
           ▼
[ 1. Write to "save.json.tmp" with Checksum ]
           │
           ▼
[ 2. Verify JSON integrity on disk ]
           │
           ▼
[ 3. Copy existing "save.json" to "save.json.bak" ]
           │
           ▼
[ 4. Atomically rename "save.json.tmp" to "save.json" ]
```

### Startup Recovery Hierarchy
When the game boots:
1. Attempt to load and validate `save.json`.
2. If `save.json` is missing or corrupt (e.g. bad CRC / truncated JSON), log a recovery event and load `save.json.bak`.
3. If both are invalid, generate fresh new-game defaults. **Never crash on bad save data.**

---

## 2. Schema Versioning & Migration System

Every save file begins with an integer schema version:

```json
{
  "schema_version": 2,
  "last_updated": 1776340000,
  "player": {
    "coins": 350,
    "stars": 4,
    "inventory": {
      "hammer": 2,
      "rocket_booster": 1
    }
  },
  "progression": {
    "max_unlocked_level": 12,
    "stars_earned_per_level": {"1": 3, "2": 3, "3": 2}
  }
}
```

### Migration Table Pattern
When `schema_version < CURRENT_SCHEMA_VERSION`, the save is piped through sequential migration functions in Lua:

```lua
local migrations = {
    [2] = function(data)
        -- Added hammer booster in v2
        data.player.inventory.hammer = data.player.inventory.hammer or 0
        data.schema_version = 2
        return data
    end,
    [3] = function(data)
        -- Restructured area format in v3
        ...
    end
}
```
Automated unit tests run all previous save fixtures through the migration pipeline on every build.

---

## 3. Google Play Games Services (GPGS) Cloud Reconciliation

Cloud synchronization runs silently in the background via `extension-gpgs`.

### Conflict Resolution Matrix
When local save and cloud save differ:

| Data Type | Resolution Rule | Rationale |
|---|---|---|
| **Max Level Unlocked** | `MAX(local, cloud)` | A player must never be forced to replay completed levels. |
| **Restoration Tasks Done** | Set Union (`local ∪ cloud`) | Combines completed tasks; never reverts village restoration. |
| **Purchased Entitlements** | Backend / Google Play Billing Authority | Permanent purchases (e.g., No Ads) are authoritative from Google Play store cache. |
| **Consumables (Coins / Boosters)** | Monotonic Delta or Timestamped Snapshot | Prevent item duplication exploits while ensuring legitimately purchased coins are never erased. |

### Idempotent Transactions (Operation IDs)
Every transaction that grants or spends coins/boosters generates a unique `op_id` (e.g. `op_level_14_reward_550e8400`):
- Before applying a grant, the transaction engine checks `history[op_id]`.
- If the `op_id` was already processed, the grant returns success without incrementing the balance a second time.
