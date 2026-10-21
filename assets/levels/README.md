# Level Definitions (`assets/levels`)

## 1. Directory Responsibility
Stores human-readable, schema-compliant JSON configuration files for all puzzle levels (`level_001.json` through `level_025.json`).

## 2. Public API / JSON Schema Contract
Every level file must strictly follow this JSON schema:
* `version` (number): Configuration format version (current: 1).
* `level_id` (number): Unique integer identifying the level.
* `difficulty` (string): Tier classification (`"intro"`, `"flow"`, `"hard"`, or `"custom"`).
* `moves` (number): Player move limit (> 0).
* `grid` (object):
  * `width` (number): Column count.
  * `height` (number): Row count.
  * `active_cells` (array of strings): Binary character masks (`"1"` active, `"0"` hole/inactive).
* `spawners` (array of objects): Per-column allowed drop colors `{ col, colors: [...] }`.
* `obstacles` (array of objects): Initial blockers `{ type, layer, x, y }` (`"bramble"`, `"stone"`, `"ingredient"`).
* `goals` (array of objects): Win objectives `{ type, target, count }` (`"collect_color"`, `"clear_obstacle"`, `"drop_ingredient"`).

## 3. Strict Inclusions
* Canonical level definition files (`level_001.json` - `level_025.json`).
* Level authoring documentation and schema specs.

## 4. Strict Exclusions
* **Executable Code:** Must never contain Lua code, scripts, or runtime state tables.
* **Game Art / Binary Data:** Must never contain raw image files, sound effects, or textures.
