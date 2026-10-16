# Persistence & Data Storage (`game/persistence`)

## Responsibility
Provides atomic local save file storage, backup recovery, schema migrations, and Google Play Games Services cloud synchronization.

## Boundary Rules
- **MUST OWN:** Serialization/deserialization of player state, atomic two-file commit (`.tmp` -> `.json` with `.bak` fallback), schema migration table.
- **MUST NOT OWN:** Puzzle gameplay rules, game balance tuning, or UI dialog presentation.
- **Safety Guarantee:** A crash or power loss at any point during writing must never corrupt the active save file.
