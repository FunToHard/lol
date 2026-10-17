# Platform Services & Monetization (`game/services`)

## 1. Directory Responsibility
Decouples external platform SDKs (Ads, In-App Purchases, Analytics, Game Services) from gameplay simulation code through abstract interface contracts. Provides offline mock adapters for rapid vertical slice testing.

## 2. Public API Contract
* `ads_service`:
  * `new(adapter)`: Creates an ads service wrapper.
  * `is_rewarded_ready()`: Checks if rewarded video is available.
  * `show_rewarded(on_reward, on_closed, on_failed)`: Presents rewarded ad with fail-open callbacks.
  * `show_interstitial(placement, on_closed)`: Presents interstitial between levels.
* `mock_ads_adapter`:
  * `new(auto_succeed)`: Headless and offline development adapter simulating rewarded video views.
* `iap_service`:
  * `new(adapter)`: Creates an IAP service wrapper.
  * `get_catalog()`: Returns registered store SKUs (`pack_starter`, `coins_small`, `coins_medium`, `coins_large`, `no_ads`).
  * `purchase(product_id, on_success, on_failed)`: Initiates digital purchase.
  * `restore_purchases(on_restored)`: Restores non-consumable entitlements.
* `mock_iap_adapter`:
  * `new(auto_succeed)`: Offline billing adapter simulating purchase fulfillment and order receipts.
* `shop_controller`:
  * `new(econ_ledger, iap_svc, save_data)`: Bridges IAP products and coin booster refills to player ledger.
  * `buy_refill_with_coins(refill_id)`: Deducts coins and grants tactical boosters (`hammer`, `rocket`, `bomb`).
  * `buy_iap_product(product_id, on_complete)`: Purchases and fulfills real-money store bundles.
* `level_flow`:
  * `new(econ_ledger, ads_svc, save_data, level_id, base_dir)`: Coordinates level-end victory fanfares, star grants, progression advancement, and out-of-moves continuations (+5 moves for 900 coins or +3 moves for 1 rewarded ad).

## 3. Strict Inclusions
* Abstract service interface definitions.
* Development and headless mock service adapters.
* In-game shop transactions and level-end continuation logic.

## 4. Strict Exclusions
* **Board Simulation Logic:** Must never manipulate match-3 grid matrices directly.
* **Persistent Authority:** Must write save files through `game/persistence/save_manager.lua`.
