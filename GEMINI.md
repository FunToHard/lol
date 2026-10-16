# GEMINI.md - AI Agent Operating Manual & Project Guidelines

This file governs all AI-assisted engineering and pair-programming on **Lantern Grove**. Every AI agent interacting with this codebase must adhere strictly to the rules, structure, and constraints outlined below.

---

## 1. Core Operating Principles

### A. The "Stop & Ask" Rule
* **Never assume or guess** when encountering breaking errors, missing dependencies, unexpected state, or ambiguous requirements.
* If a problem occurs where human intervention, architectural preference, or product judgement is needed:
  * **STOP immediately.**
  * Do not proceed with speculative fixes or architectural workarounds.
  * Formulate the problem clearly and **ask the user what to do**.

### B. Prompt Clarification Rule
* If a user prompt does not fully clarify the intent or contains ambiguity:
  * Ask for clarification directly in **standard markdown text**.
  * **STRICT RULE:** **DO NOT use the `ask_question` tool modal.** Ask directly in your chat response.

### C. No AI-Generated Image "Slop"
* **Never** attempt to generate synthetic placeholder images, hallucinated sprites, or AI-generated texture art through automated image generation tools unless explicitly requested by the user.
* All visual assets follow the defined [2D/3D Hybrid Pipeline](file:///F:/DEV/mobile-games/LanternGroove/docs/pipeline/03_ART_AND_AUDIO_PIPELINE.md) (Blender fixed-lighting renders, Krita cleanups, and properly licensed vector/audio sources).

### D. Strict Code Decoupling
* Every Lua module must have a single, isolated responsibility.
* Modules interact through explicit public function contracts.
* **Never** reach into another module's internal state tables directly.
* Keep game simulation (board logic, moves, cascades) 100% independent from rendering, sound, and platform SDKs.

### E. MCP Application Availability Rule
* If an MCP tool requires a companion application (e.g., Defold Editor, Blender, Photoshop, Reaper, etc.) to be running and that application is not open or cannot be reached:
  * **STOP immediately.**
  * Do not retry in a loop or attempt speculative workarounds.
  * Explicitly ask the user to open/launch the required application and wait for their confirmation.
* **No Programmatic GUI Launching:** Due to a known issue in the Antigravity CLI environment, running shell commands to launch desktop GUI applications (such as `Start-Process`, `Invoke-Item`, or background executables) does not work and will fail or hang. **Never** attempt to launch GUI applications via terminal commands; always ask the user to open them manually.

---

## 2. Code Quality & Formatting Standards

### A. Compact UI & Script Formatting
* **No excessive newlines or bloated whitespace** in UI scripts (`.gui_script`, `.script`) or module files.
* Do not leave 3–4 blank lines between functions. One clean blank line between functions is the project standard.
* Use consistent 4-space indentation. No mixed tabs and spaces.

### B. Mandatory Function Documentation Headers
Every function—without exception—must have a complete, structured docblock header (LDoc / EmmyLua style). This ensures AI agents and human developers never have to guess arguments, return types, or side effects.

#### Required Format:
```lua
--- Evaluates whether swapping two adjacent grid coordinates produces a valid match.
-- Validates cell bounds, cell idle states, and checks match lines on both axes.
-- @param board table The active board state table.
-- @param from_x number Grid column of the initiating cell (1-indexed).
-- @param from_y number Grid row of the initiating cell (1-indexed).
-- @param to_x number Grid column of the target cell (1-indexed).
-- @param to_y number Grid row of the target cell (1-indexed).
-- @return boolean is_valid True if the swap results in at least one match-3 or power-up activation.
-- @return table|nil match_data Table containing matched coordinates, or nil if invalid.
local function is_valid_swap(board, from_x, from_y, to_x, to_y)
    -- implementation
end
```

---

## 3. Function Lookup Tooling (Mandatory Agent Guideline)

### `tools/extract_functions.py`
To avoid dumping huge script files into the context window and wasting tokens, a dedicated extraction tool is provided.

#### Agent Operating Guideline:
* **STRICT RULE:** **DO NOT view or read the source code of `tools/extract_functions.py`.** (Do not call `view_file` on it).
* Simply execute it via `run_command` using Python.

#### Usage Examples:
```bash
# 1. Search for a specific function across the entire project
python tools/extract_functions.py --search "is_valid_swap"

# 2. List all functions in a specific folder or file with signatures and doc summaries
python tools/extract_functions.py --path "game/board"

# 3. Output clean JSON for automated parsing
python tools/extract_functions.py --path "game/persistence" --json
```

---

## 4. Project Directory Structure & Boundaries

```
LanternGroove/
├── app/                  # Application bootstrap, main.collection, render pipeline
├── game/
│   ├── board/            # Pure Lua deterministic match-3 simulation (NO GUI/Render deps)
│   ├── render/           # Visual board presentation, tile animations, particle fx
│   ├── restoration/      # Woodland village diorama, layered props, character emotes
│   ├── economy/          # Currency balances, booster inventories, transaction history
│   ├── persistence/      # Local atomic saves, migrations, GPGS cloud sync
│   └── services/         # Decoupled service interfaces (Ads, IAP, Analytics)
├── assets/
│   ├── atlases/          # Sprite sheets and texture atlases
│   ├── audio/            # Sound effects and music tracks
│   ├── fonts/            # Clean game typography
│   └── levels/           # Level JSON definitions
├── tools/                # Python helper utilities (extract_functions, solvers)
├── tests/                # Headless unit tests & deterministic replay verifiers
└── docs/                 # Architectural specs, pipeline guides, project charter
```

---

## 5. Per-Directory Root READMEs

Every major functional directory must maintain a root `README.md` that explicitly declares:
1. **Directory Responsibility:** Exactly what problem this folder solves.
2. **Public API Contract:** What other modules are allowed to call.
3. **Strict Inclusions:** What this folder owns.
4. **Strict Exclusions:** What this folder **MUST NOT** own or depend on.

---

## 6. Implementation Lifecycle & Rollback Safety

1. **One ticket at a time:** Never implement multiple features simultaneously.
2. **Acceptance Gate:** Verify against written criteria before marking a ticket complete.
3. **Rollback on Failure:** If an implementation fails tests or introduces architectural rot, revert it cleanly to the last accepted commit before starting a revised approach.
