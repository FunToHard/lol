# Board Engine (`game/board`)

## 1. Directory Responsibility
Contains the **pure deterministic match-3 board simulation**. This module handles grid matrices, legal swap validation, match-3/4/5 detection, gravity cascades, refill spawns, obstacle damage calculations, dead-board reshuffles, level loading, and goal tracking.

## 2. Public API Contract
* `grid`: 2D board matrix creation, cell bounds, coordinate queries, swaps, and debug string visualization.
* `cell`: Cell lifecycle states (`STATE_IDLE`, `STATE_SWAPPING`, `STATE_MATCHED`, `STATE_FALLING`, `STATE_SPAWNING`, `STATE_DISABLED`).
* `match_finder`: Scan algorithm detecting lines, T/L intersections, 2x2 squares, created power-ups, and swap validation.
* `cascade`: Gravity drops, top spawner refills, and iterative cascade settling.
* `powerups`: Detonation logic for Rockets, Bombs, Fireflies, Magic Lanterns, and the complete 10-combo fusion matrix.
* `obstacles`: Multi-layer Brambles, solid River Stones, and falling Acorn ingredient collection.
* `reshuffle`: Dead-board detection and Fisher-Yates piece shuffling.
* `prng`: Seeded 32-bit linear congruential pseudo-random number generator.
* `json`: Pure Lua JSON decoder and encoder with Defold runtime fallback.
* `level_loader`: Schema validation, level JSON parsing, and board instantiation with masks and blockers.
* `level_tracker`: Move limit tracking, goal progression, and win/loss lifecycle evaluation.

## 3. Strict Inclusions
* Deterministic simulation logic.
* Level schema parsing and goal monitoring.
* 100% headless CLI compatibility.

## 4. Strict Exclusions
* **Rendering / UI:** Must never depend on Defold GUI, sprites, particles, or screen dimensions.
* **Audio & Haptics:** Must never trigger sound playback or device vibration.
* **Persistence:** Must never write save files directly to disk.
