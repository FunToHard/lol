# FINAL.md - Master Development & Google Play Launch Checklist

**Project:** *Lantern Grove*  
**Engine:** Defold + Lua  
**Platform:** Android (Portrait)  
**Execution Model:** Single-ticket sequential implementation with rollback safety.

---

## Phase 0: Project Setup & Baseline Integrity
- [x] Initialize Defold project structure (`game.project`, `main.collection`, display settings: 720×1280 portrait).
- [x] Initialize Git repository with proper `.gitignore` (ignore build artifacts, cache, and temporary files).
- [x] Test and verify headless builds via Defold Bob (`bob.jar`).
- [x] Perform and verify baseline rollback cycle (create test ticket, verify, revert cleanly to baseline).

---

## Phase 1: Deterministic Match-3 Simulation (Pure Lua)
- [x] Build 2D grid matrix data structure with cell states (`IDLE`, `SWAPPING`, `MATCHED`, `FALLING`, `SPAWNING`).
- [x] Implement legal swap detection and spatial (per-cell) non-blocking input rules.
- [x] Implement match-3, match-4, match-5, and 2×2 square detection.
- [x] Implement gravity drop, column refill spawners, and cascade resolution.
- [x] Implement power-up creation (Rocket, Bomb, Firefly Jar, Magic Lantern).
- [x] Implement power-up activation (single tap and swap-to-activate).
- [x] Implement 10-combo power-up fusion interaction matrix (Rocket+Rocket, Rocket+Bomb, etc.).
- [x] Implement obstacle layer mechanics (1-hit/2-hit Brambles, cracked/solid Stones).
- [x] Implement dead-board detection and automatic piece reshuffle.
- [x] Build headless test suite verifying determinism, seeded replays, and cascade settling.

---

## Phase 2: Visual Board Presentation & Tactile "Juice"
- [x] Connect `game.atlas` sprites to board grid game objects.
- [x] Implement responsive touch drag-and-swap input controller.
- [x] Implement smooth piece falling and swap animations with 80ms squash & stretch on impact.
- [x] Add visual particle effects (golden sparks, trail particles for Rockets and Fireflies).
- [x] Add subtle camera impulse shake (2–3px on Bombs and Mega Combos).
- [x] Implement audio manager with dynamic pentatonic cascade pitching (C4 → D4 → E4 → G4 → A4 → C5).
- [x] Add Android haptic tick feedback on swaps and explosions.

---

## Phase 3: Level Authoring & Automated Solver
- [x] Define JSON level schema (`width`, `height`, `cells`, `spawners`, `obstacles`, `moves`, `goals`).
- [x] Build in-engine developer level editor overlay (paint tiles, test play, export JSON).
- [x] Build headless Monte Carlo AI Level Solver (simulates 1,000 runs per level with varied player heuristics).
- [x] Author, balance, and validate Batch 1 levels (Levels 1–25) with target win rates:
  - Levels 1–5 (Intro): >95% win rate
  - Levels 6–15 (Flow): 75%–85% win rate
  - Levels 16–25 (Engaging/Hard): 45%–65% win rate

---

## Phase 4: Persistence, Economy & Village Metagame
- [x] Build two-file atomic save system (`save.json.tmp` → integrity check → rename to `save.json` with `.bak` fallback).
- [x] Implement versioned schema migration table and test suite.
- [x] Build idempotent transaction ledger for Stars, Coins, and Boosters (`op_id`).
- [x] Create `village.collection` layered 2.5D diorama (Area 1: Hearthstone Courtyard).
- [x] Build Task Journal UI (spend Stars on restoration tasks).
- [x] Implement 3-style customization selector (Rustic Cedar, Mossy Stone, Whimsical Crystal) with free re-styling.
- [x] Add companion character (*Pip the Owl* / *Bramble the Hedgehog*) emote reactions on task completion.

---

## Phase 5: Decoupled Services & Vertical Slice Polish
- [ ] Create abstract `IAdsService` and `IIAPService` contracts.
- [ ] Implement `MockAdsAdapter` (simulated 1.5s rewarded ad overlay with instant reward callback).
- [ ] Implement `MockIAPAdapter` (simulated purchase dialog for Coin Packs & Starter Bundle).
- [ ] Build In-Game Shop GUI (Starter Pack, 3 Coin Packs, Booster refills).
- [ ] Build Level-End flows (Victory fanfare + Star grant, Out of Moves prompt: +5 moves for 900 coins or 1 rewarded ad).
- [ ] Conduct external playtesting of the 25-level vertical slice (validate loop: Play Level → Earn Star → Restore Village).

---

## Phase 6: Final Staging Gate & Native Integrations
- [ ] Create Google Play Console Application (`com.lanterngrove.match3`).
- [ ] Set up Google Play Billing products in Console (`pack_starter`, `coins_small`, `coins_medium`, `coins_large`, `no_ads`).
- [ ] Swap `MockIAPAdapter` for production `extension-iap` with transaction receipt acknowledgment.
- [ ] Set up AdMob app ID and rewarded ad unit IDs.
- [ ] Integrate Google UMP (User Messaging Platform) GDPR/CCPA consent flow.
- [ ] Swap `MockAdsAdapter` for production `extension-admob`.
- [ ] Integrate Google Play Games Services (`extension-gpgs`) for cloud save synchronization.

---

## Phase 7: Google Play Closed Testing & Store Launch
- [ ] Generate release Android signing keystore and configure Defold signing credentials.
- [ ] Build signed production Android App Bundle (`.aab`) via Defold Bob.
- [ ] Verify Target API Level 34+ and 64-bit ARM architecture compliance.
- [ ] Upload `.aab` to Google Play **Closed Testing Track**.
- [ ] Recruit and maintain **20 testers opted-in for 14 continuous days** (mandatory Google Play policy).
- [ ] Prepare store listing assets:
  - [ ] App Icon (512×512 PNG)
  - [ ] Feature Graphic (1024×500 PNG)
  - [ ] 4–6 High-Resolution Portrait Screenshots
  - [ ] Short Description (80 characters) & Full Description
- [ ] Complete Google Play Data Safety Form and privacy policy URL.
- [ ] Apply for Production Access in Google Play Console after 14-day test period.
- [ ] Promote to **Production Track** and publish to Google Play Store!
