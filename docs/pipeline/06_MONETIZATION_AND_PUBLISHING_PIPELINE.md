# Pipeline Stage 6: Monetization, Economy & Store Publishing Pipeline

**Goal:** Establish clean commercial boundaries, avoid early store bureaucracy, and ensure a smooth path to Google Play launch.

---

## 1. The Decoupled Staging Gate Architecture

Per our decision, native store setup and AdMob account configuration are deferred until the gameplay vertical slice is proven and polished.

```
┌─────────────────────────────────────────────────────────────┐
│                       Game Core Loop                        │
│          (Board, Shop UI, Level End, Settings)              │
└──────────────────────────────┬──────────────────────────────┘
                               │
                Calls Abstract Service Contracts
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
       [ IAdsService ]                 [ IIAPService ]
               │                               │
    ┌──────────┴──────────┐         ┌──────────┴──────────┐
    ▼                     ▼         ▼                     ▼
[ MockAdsAdapter ]   [ NativeAdMob ] [ MockIAPAdapter ] [ NativeGooglePlay ]
 (Early Phases 1-3)    (Stage Gate)   (Early Phases 1-3)   (Stage Gate)
```

### Behavior of Mock Services During Development
- **Mock Ads:** Displays a clean 1.5-second in-game overlay: *"Simulating Rewarded Ad... [Reward Granted]"*. Allows instant testing of ad continuations and reward triggers without network calls.
- **Mock IAP:** Opens a dev confirmation dialog granting test coins/boosters immediately.
- **Benefit:** 100% of the game's economy, shop UI, and reward loops are built, tested, and polished **without touching Google Play Console**.

---

## 2. In-Game Economy & Store Catalog

### Three-Tier Resource Model
1. **Lantern Sparks (Stars):** Non-purchasable. Only earned through level completion. Spent on village restoration.
2. **Coins (Soft Currency):** Earned via level milestones, star chests, or purchased in shop. Spent on:
   * Extra Moves (+5 moves when board runs out): 900 coins.
   * Purchasing booster refills.
3. **Boosters:**
   * **Pre-Game Boosters:** Start level with pre-placed Rocket, Bomb, or Magic Lantern.
   * **In-Game Tactical Boosters:**
     * *Woodland Mallet:* Smash any single tile or obstacle layer without using a move.
     * *Gentle Breeze (Glove):* Swap any two adjacent tiles without triggering a turn/move.

### Initial SKU Catalog (Google Play In-App Products)
| Product ID | Type | Price Target | Contents |
|---|---|---|---|
| `pack_starter` | One-Time Non-Consumable | $1.99 | 1,000 Coins + 2 Mallets + 2 Rockets + **No Forced Ads** |
| `coins_small` | Consumable | $0.99 | 500 Coins |
| `coins_medium` | Consumable | $2.99 | 1,800 Coins + 1 of each booster |
| `coins_large` | Consumable | $7.99 | 5,500 Coins + 3 of each booster |
| `no_ads` | Permanent Non-Consumable | $2.99 | Removes automatic interstitial ads permanently |

---

## 3. Ad Placement Policy & Ethics

*Lantern Grove* is designed as a relaxing, cozy experience. Intrusive ads destroy player goodwill:
1. **Never Interstitial Mid-Level:** An ad must never interrupt a player while they are contemplating a move.
2. **Conservative Frequency:** Interstitials (if active) appear only after level completion/failure, with a strict 3-level and 4-minute minimum cooldown.
3. **Fair Continuations:** 
   * Option A: Spend 900 Coins for +5 moves.
   * Option B: Watch 1 Rewarded Ad for +3 moves (capped at 1 ad continuation per attempt).
4. **Ad Fail-Open:** If an ad fails to load or no network is available, the game must never lock up or penalize the player.

---

## 4. Final Staging Gate: Google Play Release Checklist

When the 20–30 level vertical slice is approved, the project transitions from Mock to Production:

### Technical Requirements
- [ ] Defold `game.project` package ID configured (e.g. `com.lanterngrove.match3`).
- [ ] Signed Release Android App Bundle (`.aab`) generated with private release keystore.
- [ ] Google Play Billing Library integration via `extension-iap` (v6+ compliant).
- [ ] Google UMP (User Messaging Platform) consent dialog integrated for EU/EEA/UK GDPR compliance.
- [ ] Target API Level 34+ (Android 14/15) compliant.

### Store Console & Bureaucracy
- [ ] **Closed Testing Track (20 Testers / 14 Days):** Mandatory Google Play policy for personal accounts created after Nov 2023. Testers must opt-in for 14 continuous days before production access is granted.
- [ ] Store Listing Assets: App icon (512×512), Feature Graphic (1024×500), 4–6 high-resolution phone screenshots in portrait.
- [ ] Privacy Policy & Data Safety Form declaring AdMob and Google Play Games Services SDK usage.
