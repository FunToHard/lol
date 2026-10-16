# Pipeline Stage 1: Board Engine & Mechanics Specification

**Goal:** Establish an unambiguous, deterministic specification for the match-3 core to prevent architectural churn during agent implementation.

---

## 1. The "Royal Match" Fluidity Architecture

Classic match-3 engines (Candy Crush) use a **Global Board Lock**: the moment a match occurs, all player input is rejected until every cascade, gravity drop, and explosion completely stops. This feels sluggish to modern players.

*Royal Match* achieves its tactile satisfaction through **Spatial (Per-Cell) Locking**:

### Cell State Machine
Each cell `(x, y)` on the grid independently cycles through states:
1. `IDLE`: Fully settled, selectable, and swappable.
2. `SWAPPING`: Animating a swap between two adjacent cells.
3. `MATCHED`: Actively playing clear/explosion animation; cannot be swapped.
4. `FALLING`: Moving downward under gravity; cannot be swapped.
5. `SPAWNING`: Emerging from a top spawner; cannot be swapped.

### Input Concurrency Rules
- A player can touch, drag, and swap **any two adjacent cells** if and only if **both cells are in the `IDLE` state**.
- If Column 1 is cascading from an explosion, but Columns 5 and 6 are `IDLE`, the player can immediately swap pieces in Columns 5 and 6.
- A swap completes its match check locally without halting unrelated cascades.
- **Move Budgeting:** Each successful swap consumes 1 move immediately at swap commitment, even if cascades from a previous move are still settling.

---

## 2. Power-Up Generation Rules

When a match contains 4 or more pieces, a power-up is generated.

### Spawn Position Rule
Where does the power-up appear?
- **User Swap:** If the match resulted from a direct player swap, the power-up spawns **at the target tile that the player dragged into**.
- **Cascade Refill:** If the match occurred automatically during a cascade drop, the power-up spawns **at the intersection center** (for T/L shapes) or **at the lowest cell of the match** (for lines).

### Creation Criteria
| Match Pattern | Created Power-Up | Description |
|---|---|---|
| **4 in a row / column** | **Sky Rocket** | Horizontal rocket if swiped horizontally; vertical if swiped vertically. (Cascade: 50% random or matches orientation). |
| **2×2 Square** | **Firefly Jar (Propeller)** | Clears adjacent cross tiles, lifts off, and flies to the highest-priority goal or obstacle. |
| **5 in T-shape or L-shape** | **Woodland Bomb** | Explodes in a 2-tile radius (5×5 diamond / area). |
| **5 in a straight line** | **Magic Lantern (Light Ball)** | Prismatic lantern. Swapping with any color destroys all tiles of that color on the board. |

### Activation Mechanics (Dual-Mode)
1. **Direct Tap:** Tapping a single power-up immediately detonates it in place.
2. **Swap:** Swapping a power-up into a normal tile moves the power-up to that cell and detonates it.
3. **Power-Up Swap (Combo):** Swapping two power-ups together **overrides** individual behaviors and triggers a massive Combo reaction.

---

## 3. The Power-Up Combination Matrix

When two adjacent power-ups are swapped together, they fuse at the destination tile:

| Combo | Resulting Effect |
|---|---|
| **Rocket + Rocket** | Fires a cross-blast (clears full row AND full column simultaneously). |
| **Rocket + Bomb** | Massive 3-row AND 3-column clearing barrage (cross width of 3 tiles). |
| **Rocket + Firefly** | Firefly carries the Rocket and flies directly into a target goal, detonating a full row/column at the destination. |
| **Bomb + Bomb** | Giant explosion (clears a massive 7×7 area on the board). |
| **Bomb + Firefly** | Firefly carries the Bomb to the most urgent goal or stubborn obstacle and explodes in a 5×5 area. |
| **Firefly + Firefly** | Spawns 3 separate fireflies that fly to 3 distinct priority targets. |
| **Magic Lantern + Rocket** | Converts all tiles of the most populous color on the board into Rockets, then triggers all of them simultaneously. |
| **Magic Lantern + Bomb** | Converts all tiles of the most populous color into Bombs and detonates them in chain reactions. |
| **Magic Lantern + Firefly** | Converts all tiles of the most populous color into Fireflies and releases a swarm. |
| **Magic Lantern + Magic Lantern** | Ultimate board clear: wipes the entire board of all tiles and damages every obstacle by 1 full layer. |

---

## 4. Obstacle Hierarchy & Interaction Rules

Obstacles give levels strategic depth. We group them into 3 distinct functional classes:

### Class A: Fixed Layer Blockers (e.g. Bramble Bushes / Crates)
- **Behavior:** Fixed in place; do not fall under gravity.
- **Damage Condition:** Damaged by adjacent matches or direct power-up hits.
- **Multi-layer:** Can require 1, 2, or 3 hits to clear. When destroyed, the cell becomes passable.

### Class B: Falling Obstacles / Ingredients (e.g. Glowing Acorns)
- **Behavior:** Subject to gravity; fall when empty cells appear beneath them.
- **Clear Condition:** Cannot be matched directly. Must be guided to the bottom-most row of the board to collect.

### Class C: Spreading Obstacles (e.g. Creeping Moss)
- **Behavior:** If a player turn ends without clearing at least one moss tile, the moss creeps and covers one adjacent normal tile.
- **Tension:** Forces the player to prioritize board sanitation before working on primary goals.

---

## 5. Board Determinism & Seeded RNG

To support automated solver testing and instant replay debugging:
1. **PRNG Algorithm:** Fast, deterministic 64-bit generator (e.g., PCG or Xoshiro256 in pure Lua).
2. **Replay Record:** A complete game replay consists only of:
   * `level_id`
   * `initial_seed` (64-bit integer)
   * Array of player actions: `[{turn: 1, from: [x1, y1], to: [x2, y2]}, ...]`
3. **Dead-Board Detection & Reshuffle:**
   * After all cascades settle, the board scans for at least one legal swap.
   * If zero legal swaps exist: triggers a visual "No More Moves - Reshuffling" banner, and rearranges existing regular pieces without changing their types or move count until at least 2 valid swaps exist.
