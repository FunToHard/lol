# Project Charter: Lantern Grove

**Document Status:** Approved Baseline Decisions  
**Date:** October 2026  
**Game Title:** *Lantern Grove*  

---

## 1. Vision & Core Loop

*Lantern Grove* is a cozy, high-polish mobile match-3 puzzle game set in a peaceful woodland village at twilight. Players solve responsive, fluid puzzles to collect Lantern Sparks and restore antique lanterns, tea houses, glowing stone bridges, and firefly shrines.

### The Core Loop
```
[ Play Match-3 Level ]
         │
         ▼
[ Earn Lantern Sparks / Stars ]
         │
         ▼
[ Choose Village Restoration & Upgrades ]
         │
         ▼
[ Watch Woodland Village Glow & Evolve ]
         │
         ▼
[ Unlock Next Story Chapter / Level ]
```

### Aesthetic & Mood
- **Visuals:** Warm evening woodland palette: deep indigo/midnight blues, moss greens, amber lantern light, bioluminescent flora, and golden fireflies.
- **Atmosphere:** Relaxing, non-stressful, magical, and rewarding.
- **Audio:** Gentle ambient acoustic instruments, warm chimes, crackling hearths, and soft night breezes.

---

## 2. Gameplay Feel & Mechanics (Royal Match Inspiration)

The puzzle experience is modeled on the best-in-class responsiveness of modern match-3 titles (e.g. *Royal Match*):

1. **Fluid, Non-Blocking Swapping:**
   - Players do **not** have to wait for entire cascade animations to finish before making their next legal swap.
   - If a section of the board is stable, the player can immediately manipulate it.
2. **Dual Activation for Special Pieces:**
   - Power-ups can be activated by **direct single-tap** OR by **swapping** them into adjacent tiles.
3. **Special Power-up Roster:**
   - **Line of 4:** *Rocket / Sky Lantern* (Clears full row or column depending on orientation).
   - **2×2 Square:** *Firefly Jar / Propeller* (Clears immediate 1-tile radius, then flies directly to an active goal or priority obstacle).
   - **T or L Shape (5 pieces):** *Woodland Firework / Bomb* (2-ring circular explosion clearing 3×3 to 5×5 area).
   - **Line of 5:** *Magic Prismatic Lantern / Light Ball* (Clears all pieces matching the swapped color, or triggers massive board-clearing effects when combined with another special piece).
4. **Special Combos:**
   - Every combination of special pieces (e.g., Rocket + Bomb, Firefly + Bomb, Light Ball + Rocket) has an explicit, high-impact interaction matrix.

---

## 3. Technical & Architectural Strategy

### A. Engine & Platform
- **Engine:** Defold + Lua (managed via `defold-mcp` and `bob.jar`).
- **Target Platform:** Android-first (portrait orientation, designed for one-handed thumb play).
- **Secondary Platform:** Desktop builds (Windows / macOS) for rapid local development and automated CI.

### B. Monetization Architecture (Decoupled Stage Gate)
- **Phase 1 to Phase 3:** Complete decoupling via service interfaces (`ads_service.lua`, `iap_service.lua`). All game features run seamlessly with local mock/fake implementations. No dependency on Google Play Console or AdMob accounts during gameplay prototyping.
- **Final Staging Phase:** Swap fake adapters for production `extension-admob` (with UMP consent) and `extension-iap` once the core game loop is validated and enjoyable.

### C. Backend & Data Authority
- **Offline-First:** The game runs 100% offline with zero server requirements.
- **Local Persistence:** Atomic, versioned JSON save files with checksums and automatic rollback to secondary backup in case of write interruption.
- **Cloud Sync:** Google Play Games Services (GPGS) Saved Games API for cross-install progress restoration and cloud backup.

---

## 4. Orchestration & Ticket Rules

All development proceeds under strict single-ticket execution:
1. **One active ticket in progress at any time.**
2. **Deterministic Simulation Isolated from View:**
   - Board logic, match detection, gravity, and cascade rules run in pure Lua with zero engine GUI/Render dependencies.
   - Render and sound modules observe board events (`tile_matched`, `piece_fell`, `powerup_spawned`) and animate them.
3. **Rollback-First Verification:**
   - Every ticket defines an exact rollback command and verifiable acceptance test before code is written.
