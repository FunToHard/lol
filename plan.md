**I’d stay with Defold, target Android first, and build an original match-3 game through small, independently reversible implementations.** Your biggest constraints will be maintaining quality, producing levels, and getting real player feedback—not generating enough code.

The plan below assumes you work solo with agents, use free creative tools where practical, and monetize through **ads plus in-app purchases**. Server and development expenses are treated as covered, as requested.

One important limitation: **isolated rollback is something we design for, not something Git automatically guarantees.** Once features depend on one another—or player data has changed—you cannot always undo an old feature safely with a simple revert.

**1. Name ideas and recommended direction**

These are creative candidates; availability and trademark clearance have not been checked.

| Name | Direction it suggests |
|---|---|
| **Bloomhaven Match** | Restore a welcoming garden village |
| **Cloudberry Match** | Bright floating islands and whimsical characters |
| **Lantern Grove** | Cozy woodland village with glowing evening scenes |
| **Skybloom Match** | Floating gardens, water, and flowers |
| **Wonderwharf** | Restore a colorful harbor town |
| **Pocket Orchard** | Compact, friendly fruit-and-garden world |
| **Petal & Pebble** | Distinctive garden identity and character duo |
| **Match & Mend** | Puzzle solving directly tied to restoration |
| **Pebblewick** | A memorable village name with room for stories |
| **Little Wonders: Match** | Restore small magical places |

**My working choice: Bloomhaven Match.**

The promise: *Satisfying puzzles that bring a village back to life.*

The loop:

**Play a level → earn restoration stars → choose an upgrade → see the village change → unlock the next puzzle.**

Start with one garden courtyard, one guide character, and simple decoration choices. Keep floating islands as an optional visual direction; they should not require a large world simulation.

Your differentiation should be:

- Excellent puzzle responsiveness.
- Decoration choices players can revisit.
- Clear, fair difficulty.
- Optional rewarded ads with predictable benefits.
- A recognizable original visual style.

**2. Scope that a solo developer can maintain**

Aim for these three deliverables:

| Milestone | Scope |
|---|---|
| Technical proof | Android build, test ads, test purchases, persistence proof |
| Playable vertical slice | 20–30 polished levels, one small restoration area, complete core loop |
| Closed beta | Approximately 80–120 validated levels, a few compact areas, monetization, recovery tools |

Those level counts are planning targets, not promises of sufficient retention.

Initially exclude guilds, chat, real-time competition, subscriptions, battle passes, player-generated levels, and simultaneous iOS release. Each introduces ongoing operational work.

Allow unrestricted basic retries initially. You can still sell boosters and optional conveniences without building the entire game around an energy system.

**3. Recommended tool stack**

| Job | Recommendation | How to use it |
|---|---|---|
| Game runtime | **Defold + Lua** | Core game, interface, animation, Android packaging |
| Version control | **Git** | One implementation branch and one reviewed merge at a time |
| Agent execution | Your existing agentic tools | Small tickets with explicit file boundaries and acceptance criteria |
| Automated builds | **Defold Bob** | Repeatable builds outside the editor |
| Game logic tests | Small Lua test harness | Board rules, saves, rewards, deterministic replays |
| Content validation | Python scripts | Validate level files, assets, references, and balancing reports |
| Level authoring | Small in-project editor | Paint cells, set goals, replay a seed, export data |
| 2D artwork | **Krita** | UI assets, paintovers, sprite cleanup |
| Consistent dimensional artwork | **Blender** | Render reusable props to 2D with fixed lighting and camera |
| Audio | **Audacity** | Edit your recordings and properly licensed source audio |
| Performance | Defold profiler + Android device tools | Measure actual phones, especially your weakest supported device |
| Ads | One provider adapter initially | Start with AdMob if the complete consent integration passes |
| Purchases | Defold IAP extension | Keep platform callbacks outside gameplay code |
| Backend | Your existing server stack | Purchase verification, entitlements, recovery, configuration |
| Tracking work | Markdown tickets in the repository | Keep specifications alongside code and history |

Defold is free without engine royalties, supports command-line builds, and has built-in profiling. [Defold FAQ](https://defold.com/faq/faq/), [Bob documentation](https://defold.com/llms/manuals/bob/), [profiling documentation](https://defold.com/manuals/profiling/).

Krita, Blender, and Audacity provide free creative tooling. Using them does not automatically license third-party assets you import. [Krita](https://krita.org/en/), [Blender licensing](https://www.blender.org/about/license/), [Audacity](https://www.audacityteam.org/).

**I would not switch engines unless the early Android monetization proof exposes a concrete blocker.** Avoid adding a second programming language or transpiler to the game runtime just to accommodate agent preferences.

**4. The orchestration rule: one implementation in progress**

Use four roles sequentially. They can be separate agent sessions; they do not require paid collaborators or simultaneous coding.

| Role | Responsibility |
|---|---|
| Planner | Produce the next bounded ticket and its acceptance criteria |
| Implementer | Change only that ticket’s approved scope |
| Reviewer | Inspect the diff, challenge assumptions, run relevant checks |
| Release controller | Accept the implementation or revert it and record the failure |

You remain responsible for visual quality, game feel, and product decisions. Agent approval cannot substitute for playing the game.

The cycle is:

**Accepted baseline → ticket → implementation → verification → accept or revert → next ticket.**

Rules:

1. Only one ticket can be in `IMPLEMENTING`.
2. No dependent ticket starts until its prerequisite is accepted.
3. Unrelated cleanup gets its own ticket.
4. Engine upgrades and extension upgrades are separate tickets.
5. Interface changes are separate from feature implementations when possible.
6. A failed implementation is removed before its replacement begins.
7. Preserve the failure report, reproduction case, and useful regression tests.
8. If two attempts fail for the same reason, reassess the design before generating attempt three.

Agents must not quietly broaden the task to “fix the architecture.”

**5. Make rollback part of the architecture**

Use explicit module boundaries:

| Module | Owns | Must not own |
|---|---|---|
| Board simulation | Tiles, swaps, matches, gravity, cascades | Ads, UI, purchases |
| Board presentation | Sprites, animation, effects, input mapping | Reward balances |
| Level session | Moves, goals, win/loss state | Store SDK callbacks |
| Progression | Unlocks and restoration progress | Raw purchase verification |
| Economy | Grants, spending, inventory | Ad presentation |
| Persistence | Versioned saves and recovery | Puzzle design decisions |
| Platform services | Ads, billing, lifecycle integration | Board rules |
| Content | Levels, obstacles, area definitions | Arbitrary executable behavior |

For example, gameplay asks `ads.show_rewarded(placement)` through your own interface. It never directly calls the ad SDK.

If the provider changes, the board and economy remain untouched.

For each accepted ticket, record:

- Ticket ID and implementation commit.
- Previous accepted baseline.
- Files and contracts changed.
- Required dependencies.
- Data/schema changes.
- Verification evidence.
- Rollback procedure.
- Any external configuration changes.

**Before release:** revert the failed ticket’s code and assets, restore test fixtures, verify the accepted baseline, then reimplement.

**After release:** disable the affected feature where possible and ship a compatible replacement. **Never rewind purchase records or overwrite player progress just because code was reverted.** Store-distributed updates also cannot be assumed to disappear instantly from players’ devices.

For an older module with later dependents, preserve its public contract and replace its implementation. If that is impossible, pause and identify the affected dependency chain rather than promising a one-module revert.

**6. Ordered implementation plan**

Each numbered item below is a separate acceptance checkpoint. Where an item describes repeated work, implement **one booster, obstacle, or content batch at a time**.

| Step | Implementation | Acceptance gate |
|---|---|---|
| **01** | Write the product specification | Audience, orientation, visual direction, first-release scope, and exclusions are explicit |
| **02** | Create repository and recovery workflow | A dummy change can be added and reverted without losing the baseline |
| **03** | Pin Defold and dependencies | A clean checkout builds using documented versions |
| **04** | Produce minimal Android package | Signed build installs, launches, pauses, resumes, and relaunches on a real phone |
| **05** | Define service interfaces with fake implementations | Gameplay shell works without network or SDK availability |
| **06** | Prove consent and rewarded test ads | Valid consent flow, ad completion, cancellation, no-fill, and offline behavior all work |
| **07** | Prove a test purchase | Purchase, cancellation, pending state, callback replay, and relaunch recovery are demonstrated |
| **08** | Build save storage | Interrupted writes and corrupted primary saves recover from a valid previous copy |
| **09** | Build deterministic board representation | Same level, seed, and actions produce the same board state |
| **10** | Implement legal swaps | Invalid swaps change neither the board nor remaining moves |
| **11** | Implement match detection | Horizontal, vertical, intersecting, and overlapping matches resolve according to written rules |
| **12** | Implement clearing, gravity, and refill | Cascades settle reliably; invalid content cannot hang the game |
| **13** | Implement dead-board detection and reshuffle | A board without legal moves recovers without changing its objectives or consuming a move |
| **14** | Implement goals and move limits | Goals completed on the last move count correctly; win/loss fires once |
| **15** | Connect basic board rendering and touch input | Visual coordinates match simulation; input cannot corrupt resolution in progress |
| **16** | Add one power-up | Creation, targeting, activation, and goal interactions pass tests |
| **17** | Add remaining power-ups individually | Each passes before the next starts |
| **18** | Add power-up combinations individually | Each pair follows a documented interaction matrix |
| **19** | Add obstacles individually | Each obstacle’s damage, movement, and power-up behavior is explicit |
| **20** | Build a minimal level editor | You can author and export a playable level without editing gameplay code |
| **21** | Build level validation and replay tools | Invalid layouts are rejected; reported failures can be replayed |
| **22** | Add session persistence | Closing the app cannot duplicate rewards or spend the same resource twice |
| **23** | Add economy transactions | Grants and spending are recorded once; duplicate requests are harmless |
| **24** | Add progression | Completing a level unlocks the intended next content exactly once |
| **25** | Add one restoration interaction | Spend a star, choose a decoration, save it, and recover it after relaunch |
| **26** | Produce one final-quality asset set | Board pieces remain readable at actual phone size and use consistent lighting |
| **27** | Add animation, sound, and haptics | Feedback follows simulation events; skipping effects cannot alter results |
| **28** | Add onboarding and settings | First-time players can complete the first levels without your explanation |
| **29** | Add minimal analytics | Events are versioned, deduplicated where needed, and cannot block play |
| **30** | Build the 20–30-level vertical slice | Unpaid outside testers can complete the full puzzle-to-restoration loop |
| **31** | Add production purchase verification and entitlements | Successful purchases recover after interruption; replayed tokens do not duplicate value |
| **32** | Connect rewarded ads to the economy | A valid reward is granted once, even if callbacks repeat or the app resumes |
| **33** | Add the initial shop | Store prices are displayed correctly; unavailable products fail gracefully |
| **34** | Add optional interstitial placement | Frequency limits and purchased removal work; ads never interrupt a board |
| **35** | Add configuration controls | Bad configuration falls back safely; ads and offers can be disabled independently |
| **36** | Add account/recovery capability | Reinstall and supported account recovery preserve server-owned entitlements |
| **37** | Expand content in small batches | Each batch passes validation and human playtesting |
| **38** | Run device and failure testing | No unresolved save-loss, purchase-loss, or board-locking defects |
| **39** | Complete store submission requirements | Listing, declarations, SDK versions, testing access, and release build agree |
| **40** | Run a limited release | Observe retention, reliability, economy, and player feedback before expanding |

Steps 06–07 are deliberately early **technical proofs**. Steps 31–34 turn those proven integrations into the actual commercial experience.

Defold provides AdMob and IAP extensions, but you still need to verify the exact extension versions together. Do not assume ad support automatically includes a complete consent solution. [AdMob extension](https://defold.com/extension-admob/), [IAP extension](https://defold.com/extension-iap/), [Google UMP guidance](https://developers.google.com/admob/android/privacy).

**7. Board rules that must be decided before agents implement them**

Ambiguity here creates cascading rework.

Write down:

- Which match shapes create each power-up.
- Where the power-up appears when several valid positions exist.
- Whether players tap power-ups or must swap them.
- Whether a swap between two power-ups is always legal.
- Which objects fall, remain fixed, or block gravity.
- Whether secondary explosions can damage the same obstacle more than once.
- When goals are counted.
- Whether newly spawned pieces can create automatic matches.
- What happens if a reshuffle cannot produce a valid board.
- The exact point at which input becomes available again.

Use stable tile IDs and your own seeded random-number generator. Record the seed, level version, and player actions in debug replays.

A solver that finds a solution for one seed does **not** establish that every refill sequence is fair. Use simulations to detect suspicious levels, then playtest them.

**8. Ads and IAP design**

Your dual model makes sense, provided ads and purchases do not create conflicting promises.

| Revenue feature | Initial recommendation |
|---|---|
| Rewarded ad | Optional pre-level booster |
| Rewarded continuation | One optional continuation per attempt |
| Rewarded daily gift | Small capped bonus |
| Interstitial | Test only at natural breaks, with a conservative cooldown |
| Banner | Omit initially to protect screen space |
| Starter bundle | One clear offer with a modest amount of currency and boosters |
| Currency packs | Three understandable sizes |
| Ad-removal purchase | Explicitly removes automatic interstitials; optional rewarded ads remain clearly identified |
| Cosmetics | Decoration packs once players demonstrate interest |
| Subscription/pass | Defer until you can sustain recurring content |

Make these product rules explicit:

- Never show an interstitial during a level.
- Never require an ad to complete the tutorial.
- If an ad is unavailable, normal play remains available.
- Grant rewarded benefits from the reward event, not merely ad dismissal.
- Never change board randomness based on whether someone spends.
- Keep restoration stars separate from purchasable coins.
- Define whether an ad continuation and paid continuation can both occur in one attempt.
- Show exactly what every purchase grants.

Start with **one ad network integration**, not a large mediation stack. Add mediation only when actual traffic and revenue justify the complexity.

Purchase verification belongs on the backend; entitlement grants must be durable and idempotent, with acknowledgment/consumption handled correctly and retried safely. Google recommends verifying purchases before granting entitlements. [Google Play billing security](https://developer.android.com/google/play/billing/security).

Use test ads and licensed test purchases throughout development. [Google Play test-purchase setup](https://support.google.com/googleplay/android-developer/answer/6062777).

**9. Economy and data protection**

Use three simple resource types initially:

- **Stars:** earned through progression and spent on restoration.
- **Coins:** earned or purchased, spent on defined conveniences.
- **Boosters:** countable inventory items.

Every mutation should have an operation ID:

`operation_id → reason → amount → source → resulting balance`

Reprocessing the same operation must return its previous result rather than grant again.

Decide authority clearly:

| Data | Authority |
|---|---|
| Current offline puzzle state | Local client |
| Ordinary offline progress | Local first, reconciled under explicit rules |
| Verified purchase history | Backend/store records |
| Permanent purchase entitlements | Backend, cached locally |
| Competitive scores | Defer until server validation exists |

Do not merge consumable balances by taking the larger value from two devices. That enables duplication.

For the first release, a single active progression device is a reasonable simplification. If you support cross-device play, define conflict handling before implementation.

Save formats need version numbers, migration fixtures, backup recovery, and upgrade tests. A feature flag cannot reverse a destructive migration.

**10. Asset and level production without hired manpower**

Build a reusable production system rather than generating every screen independently.

For artwork:

- Define a palette, camera angle, lighting direction, outline style, and material treatment.
- Produce a small reference sheet before generating large asset batches.
- Use fixed Blender scenes for props that need consistency.
- Use Krita for cleanup and matching colors.
- Keep text out of generated images; render it in the interface.
- Track the origin and license of every imported asset, font, and sound.
- Keep editable source files and exported game assets separate.

For levels:

- Start with a teaching objective: one new idea per introductory level.
- Assign a difficulty intention before playtesting.
- Record attempts, remaining moves, failure causes, and booster dependence.
- Reuse validated mechanics in new combinations.
- Add content in batches of approximately 5–10 levels.
- Measure how long a fully validated batch actually takes.

**Content throughput is a release constraint.** If players consume levels faster than you can responsibly produce them, reduce your promised update cadence and maintain a content buffer.

**11. Project breakers and containment**

| Potential breaker | Early signal | Response |
|---|---|---|
| Ads/consent integration fails | Native build conflicts or incorrect initialization | Stop at the technical proof; replace the adapter or compatible extension before content work |
| Billing is unreliable | Lost or repeated grants after restart | Block release; fix transaction state and reconciliation |
| Agents create tightly coupled code | Every feature touches many unrelated modules | Revert that implementation and restore the boundary |
| Rollback removes unrelated work | Tickets contain cleanup and feature changes together | Reduce ticket scope and enforce one merge unit |
| Save corruption | Relaunch loses progress | Block release; repair storage and migration handling |
| Board lockups | Certain cascades never settle | Preserve a replay, revert the rule change, add regression coverage |
| Game is visually polished but dull | Testers stop voluntarily after a few levels | Revisit the puzzle loop before adding more content |
| Difficulty becomes purchase-dependent | Repeated failures concentrate around offers | Rebalance levels and resource sinks independently |
| Inconsistent generated art | Different lighting, proportions, or readability | Narrow the style and regenerate only the failing asset set |
| Low-end devices struggle | Long frames during explosions or repeated sessions | Profile; reduce effect cost, texture memory, and object churn |
| Backend outage stops gameplay | Startup waits for services | Use cached configuration and offline play; preserve pending transactions |
| Cloud synchronization duplicates value | Device switching increases balances | Enforce server ownership and operation deduplication |
| Store access delays launch | Testing or declarations incomplete | Check your Play Console requirements during the first milestone |
| No player acquisition | Good build, almost no outside players | Test screenshots, gameplay clips, and community interest before mass-producing levels |
| Solo workload becomes unsustainable | QA, support, and content compete constantly | Reduce release scope and update frequency |

Plan tester recruitment early. Google Play has account-specific production-access testing requirements; verify the current requirements in your own Console instead of treating release as an immediate upload. [Google Play testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465).

**12. Testing and release gates**

Automate the expensive-to-repeat correctness checks:

- Match and power-up interactions.
- Deterministic replay.
- Invalid level detection.
- Save migration and corruption recovery.
- Duplicate purchase and reward callbacks.
- Interrupted grants and spending.
- Upgrade from a previous accepted build.

Test manually on real devices:

- Touch accuracy and board readability.
- Animation pacing.
- Long sessions and thermal behavior.
- Ad return, incoming interruptions, backgrounding, and process termination.
- Offline startup.
- Purchase cancellation and recovery.

For performance, choose a real minimum device and set measured targets—for example, stable 60 FPS on your main test device and an explicitly acceptable fallback on the weakest supported phone.

Do not launch with known defects that lose purchases, lose saves, duplicate paid value, or permanently lock progression.

**13. Product checkpoints and schedule**

Treat these as rough effort ranges for an experienced solo developer using agents, not fixed delivery promises:

| Stage | Planning allowance |
|---|---|
| Repository, Android, ads, billing proofs | 1–3 weeks |
| Board engine and core mechanics | 3–6 weeks |
| Editor, progression, vertical slice, initial polish | 4–8 weeks |
| Production monetization, recovery, beta content, QA | 4–8 weeks |
| Testing, iteration, and release preparation | 3–6 weeks |

Some testing and feedback collection can overlap, while implementation remains serial. Expect longer if you are learning Lua, Defold, art production, or mobile publishing simultaneously.

At the vertical slice, ask:

- Do testers understand the game without coaching?
- Do they voluntarily play again?
- Can they name something they prefer about it?
- Does restoration motivate another level?
- Can you produce new levels fast enough?

During beta, measure day-one and day-seven retention, attempts by level, crash rate, ad availability, purchase failures, and revenue per active user. Treat small cohorts as directional evidence.

**Do not increase ad pressure merely to compensate for weak retention.**

**14. Reusable agent ticket**

Use this structure for every implementation:

```text
Ticket:
Player-visible outcome:
Accepted baseline commit:

Prerequisites:
Allowed files/modules:
Public contracts that must remain stable:
Explicitly out of scope:

Implementation requirements:
Acceptance criteria:
Relevant automated checks:
Required device/manual checks:

Save/backend/configuration impact:
Rollback procedure:
Evidence to retain on failure:

Completion report:
- What changed
- What was verified
- What remains unverified
- Commit and changed files
- Known limitations

Failure rule:
If acceptance fails, preserve the reproduction and diagnostics,
revert this implementation without touching unrelated work,
verify the accepted baseline, and prepare a revised attempt.
Do not start the next ticket.
```

**The first actual implementation should be repository setup plus a proven rollback exercise.** Then validate Android, consent, ads, and billing before building the full game. That sequence gives your “only the failed part gets replaced” requirement a practical foundation.