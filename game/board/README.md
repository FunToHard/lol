# Board Engine (`game/board`)

## Responsibility
Contains the **deterministic match-3 board simulation**. This module handles grid matrices, legal swap validation, match-3/4/5 detection, gravity cascades, refill spawns, obstacle damage calculations, and dead-board reshuffles.

## Boundary Rules
- **MUST OWN:** Pure grid state, move counting, goal progression, cascade ticks, seeded PRNG.
- **MUST NOT OWN:** Rendering, sprites, animations, sound effects, particle effects, UI nodes, store callbacks, or network services.
- **Dependency Rule:** Must remain 100% pure Lua. Must be runnable headlessly outside Defold via CLI without graphical dependencies.

## Key Planned Modules
- `board_state.lua`: Core grid data structure and cell lifecycle (`IDLE`, `FALLING`, `MATCHED`).
- `match_finder.lua`: Scan algorithm detecting lines, crosses, squares, and combo targets.
- `cascade.lua`: Step-by-step gravity and refill resolver.
- `powerup_rules.lua`: Logic for spawning and detonating rockets, bombs, fireflies, and magic lanterns.
