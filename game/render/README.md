# Board Presentation & Rendering (`game/render`)

## 1. Directory Responsibility
Translates deterministic match-3 game simulation events into fluid 60 FPS visual animations, sprite flipbooks, camera shake, pentatonic audio cues, and mobile haptic responses.

## 2. Public API Contract
External callers and engine bootstrap interact exclusively with:
* `board_view`: Coordinate math between 720x1280 screen pixels and grid columns/rows, plus sprite flipbook mappings.
* `input_controller`: Drag-and-swap swipe threshold (22px) and tap gesture recognizer.
* `camera_shake`: Decaying impulse camera offset calculation (2–4px) for explosive powerups.
* `audio_manager`: Pentatonic scale cascade pitching (C4 → D4 → E4 → G4 → A4 → C5) and sound dispatch.
* `haptic`: Tactile feedback for tile swaps (tick), matches (impact), and detonations (heavy).
* `effects`: Deterministic tween configurations, 80ms squash & stretch, quadratic Bezier arcs for Fireflies, and Rocket trajectories.
* `board.script` / `board.go`: Defold lifecycle orchestrator synchronizing visual game objects with `game/board` simulation.

## 3. Strict Inclusions
* Tile & recessed cell game object templates (`tile.go`, `cell_bg.go`).
* Input interpretation (screen-space touch coordinates to grid actions).
* Tweening, visual feedback juice, squash & stretch, and camera shake.
* Audio pitch modulation and haptic triggers.

## 4. Strict Exclusions
* **Simulation Authority:** Must never decide whether a match or cascade is valid (owned exclusively by `game/board`).
* **Game Economy:** Must never grant stars, coins, or deduct moves directly (owned by `game/economy`).
* **Persistence:** Must never write to disk or mutate save files (owned by `game/persistence`).
