# Pipeline Stage 2: Level Design & Solver Pipeline

**Goal:** Enable a solo developer with AI assistance to design, balance, and validate 50–100 high-quality levels rapidly without manual burnout.

---

## 1. Level Data Format Specification

Levels are defined as clean, human-readable JSON files (e.g. `assets/levels/level_001.json`).

```json
{
  "version": 1,
  "level_id": 14,
  "difficulty": "normal",
  "moves": 24,
  "grid": {
    "width": 9,
    "height": 9,
    "active_cells": [
      "111111111",
      "111111111",
      "111000111",
      "111000111",
      "111111111",
      "111111111",
      "111111111",
      "111111111",
      "111111111"
    ]
  },
  "spawners": [
    {"col": 0, "colors": ["amber", "emerald", "sapphire", "ruby"]},
    {"col": 1, "colors": ["amber", "emerald", "sapphire", "ruby"]}
  ],
  "obstacles": [
    {"type": "bramble_bush", "layer": 2, "x": 4, "y": 0},
    {"type": "bramble_bush", "layer": 1, "x": 4, "y": 1}
  ],
  "goals": [
    {"type": "clear_obstacle", "target": "bramble_bush", "count": 2},
    {"type": "collect_color", "target": "amber", "count": 18}
  ]
}
```

---

## 2. In-Engine Level Authoring Tool (Dev Mode)

Instead of maintaining a separate external web app or desktop app, the level editor is built as an **in-project Defold dev overlay**:

* **Toggle via Hotkey / Hidden Button:** (e.g. `~` key on desktop or secret multi-tap on mobile HUD).
* **Grid Painting:** Click a palette brush (Amber Tile, Bramble Layer 1, Spawner, Blocked Cell) and click/drag on the board to paint cells.
* **Immediate Playtest:** One-click "Test Play" starts the level with live input.
* **Instant Export:** Saves the current level JSON directly to disk via Defold file I/O.
* **Seed Locking:** Allows fixing an RNG seed to test deterministic edge cases.

---

## 3. Headless Monte Carlo AI Level Solver

Balancing match-3 difficulty by hand is the #1 reason solo developers abandon puzzle games. An automated simulation tool eliminates guesswork.

### Architecture of the Heuristic Solver
A lightweight Lua CLI script simulates full games headlessly at 50,000 turns per second.

```
                  ┌───────────────────────────────┐
                  │      Level JSON Definition    │
                  └───────────────┬───────────────┘
                                  │
                                  ▼
                  ┌───────────────────────────────┐
                  │ 1,000 Deterministic Runs      │
                  │ (Varied Seeds & Heuristics)   │
                  └───────────────┬───────────────┘
                                  │
                                  ▼
      ┌───────────────────────────────────────────────────────┐
      │                  Difficulty Telemetry                 │
      ├───────────────────────┬───────────────────────────────┤
      │ Win Rate (%)          │ Average Remaining Moves       │
      │ Reshuffle Frequency   │ Target Win Rate Variance      │
      │ Blocker Bottlenecks   │ Unwinnable Seed Detection     │
      └───────────────────────────────────────────────────────┘
```

### Player Persona Heuristics
The solver tests using three automated player personas:
1. **The Casual Player (Greedy / Random):** Takes the first valid match-3 they see near the bottom of the board.
2. **The Goal-Oriented Player (Heuristic):** Evaluates all available legal moves; picks moves that directly damage goals or hit obstacles.
3. **The Power-Up Master (Strategic):** Prioritizes creating match-4s, bombs, and combos above simple match-3s.

### Difficulty Classification Benchmarks
- **Tutorial / Introduction (Levels 1–5):** Win Rate > 95%
- **Easy / Flow State (Levels 6–15):** Win Rate ~ 75%–85%
- **Normal / Engaging:** Win Rate ~ 50%–65%
- **Hard ("Super Hard" levels):** Win Rate ~ 20%–35% (creates demand for coins/boosters)

---

## 4. Content Production Milestones

* **Batch 1 (Vertical Slice):** Levels 1–25 (Mechanic introduction: basic matches, 4 power-ups, bramble obstacles, 1 area).
* **Batch 2 (Beta Expansion):** Levels 26–60 (Introduce falling acorns, creeping moss, multi-layer obstacles).
* **Batch 3 (Soft Launch Ready):** Levels 61–100+ (Full variety, rhythmic difficulty pacing: Normal -> Normal -> Hard -> Flow/Super Easy).
