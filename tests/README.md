# Test Harness (`tests`)

## Responsibility
Contains headless automated unit tests, deterministic replay verifiers, save migration test fixtures, and level solver simulations.

## Boundary Rules
- **MUST OWN:** Test runners, mock inputs, regression fixtures, replay action logs.
- **MUST NOT OWN:** Production game runtime code.
- **Execution:** Tests must be runnable headlessly via CLI (pure Lua / Bob runner) in milliseconds without graphical windows.
