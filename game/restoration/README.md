# Woodland Village Restoration (`game/restoration`)

## Responsibility
Manages the woodland village diorama, player customization choices (e.g. Cedar, Stone, Whimsical styles), area task progression, and companion character emote animations.

## Boundary Rules
- **MUST OWN:** Village scene props, active area task list, style selection dialog, restoration cinematics.
- **MUST NOT OWN:** Raw match-3 board logic or direct IAP store purchases.
- **Style Reversibility:** A player must be allowed to inspect and switch styles of any previously restored prop without additional currency cost.
