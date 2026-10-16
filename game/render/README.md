# Board Presentation & Rendering (`game/render`)

## Responsibility
Listens to events emitted by `game/board` and translates them into smooth visual animations, particle bursts, screen shake, tactile haptics, and sound triggers.

## Boundary Rules
- **MUST OWN:** Tile game objects, sprite animations, visual coordinates, trail particles, squash & stretch tweens, input touch mapping.
- **MUST NOT OWN:** Board state authority, win/loss determination, economy grants, or save files.
- **Animation Decoupling:** Skipping an animation or accelerating playback must never alter the underlying deterministic board outcome.
