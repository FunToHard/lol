# Woodland Village Restoration (`game/restoration`)

## 1. Directory Responsibility
Manages the woodland village diorama, renovation task progression, 3-style customization choices, zero-cost re-styling, and companion character emote reactions.

## 2. Public API Contract
* `task_catalog`:
  * `get_tasks_for_area(area_id)`: Enumerates all restoration tasks for a designated village area.
  * `get_task(task_id)`: Looks up task details, star costs, and 3-style aesthetic themes.
* `village_state`:
  * `new(saved_data, econ_ledger)`: Initializes village state backed by persistent save data and transaction ledger.
  * `get_active_task(state)`: Resolves next available task in the renovation sequence.
  * `can_complete_task(state, task_id)`: Checks task availability and star affordability.
  * `complete_task(state, task_id, chosen_style_idx, op_id)`: Atomically deducts stars, registers completion, and locks in chosen style.
  * `restyle_prop(state, task_id, new_style_idx)`: Re-styles a previously restored prop at zero currency cost.
  * `get_completion_stats(state)`: Calculates area completion count and percentage.
* `companion`:
  * `new(name)`: Creates companion state instance (Pip the Owl / Bramble the Hedgehog).
  * `trigger_reaction(state, emote_type, duration)`: Plays emote (`"idle"`, `"curious"`, `"happy"`, `"celebrate"`) and sets dialogue line.
  * `update(state, dt)`: Updates emote timer and reverts automatically to idle.

## 3. Strict Inclusions
* Area renovation task catalog and style metadata.
* Village progression state and free re-styling logic.
* Companion character reactions and dialogue cues.

## 4. Strict Exclusions
* **Puzzle Board Logic:** Must never depend on match-3 board simulation internals.
* **Direct Billing:** Must never trigger IAP purchases or ad reward callbacks.
