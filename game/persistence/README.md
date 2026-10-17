# Persistence & Data Storage (`game/persistence`)

## 1. Directory Responsibility
Guarantees 100% data durability and zero progress loss through atomic two-file disk writes, automatic backup recovery, versioned schema migrations, and Google Play Games Services cloud synchronization.

## 2. Public API Contract
* `save_manager`:
  * `save(state, base_dir)`: Atomically commits save data (`save.json.tmp` -> integrity check -> `save.json.bak` -> atomic rename to `save.json`).
  * `load(base_dir)`: Resilient startup loader with recovery hierarchy (`save.json` -> `save.json.bak` -> defaults). Never crashes on corrupted data.
  * `create_default_state()`: Produces fresh new-game state table matching current schema version.
* `migrations`:
  * `migrate(save_data)`: Sequentially upgrades older schema versions to `CURRENT_SCHEMA_VERSION`.
* `cloud_sync`:
  * `reconcile(local_data, cloud_data)`: Deterministic conflict resolution matrix (`MAX(level)`, task set union, merged transaction ledger).

## 3. Strict Inclusions
* Atomic disk serialization and integrity validation.
* Backup failover and auto-migration logic.
* Cloud reconciliation matrix.

## 4. Strict Exclusions
* **Game Authority:** Must never directly modify economy balances or alter board gameplay rules.
* **UI Presentation:** Must never display modal dialogs directly.
