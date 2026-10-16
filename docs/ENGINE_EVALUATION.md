# Engine Evaluation: Iteration Capabilities for Lantern Grove

**Target Game:** *Lantern Grove* (Fluid Match-3 + Cozy Woodland Village Restoration)  
**Development Model:** Solo Developer + AI Agentic Pair Programming  
**Target Platforms:** Android-first (mobile portrait), desktop testing  

---

## 1. What Defines "Maximum Iteration Capability" for Solo + AI Development?

When building a game with AI agents, iteration speed is not just about typing code. It depends on four interconnected bottlenecks:

1. **Agent Diffability & File Cleanliness:** Can AI agents read, write, and refactor scene files, configs, and scripts without corrupting hidden GUIDs, binary caches, or multi-thousand-line meta-files?
2. **Turnaround & Hot-Reload Speed:** How many milliseconds between saving a change and seeing it live on screen? Can changes be reloaded into a running game session without resetting the board?
3. **Headless Execution & Automated Testing:** Can we run 1,000 simulated games or automated level solver passes in seconds from the command line without opening a heavy graphical editor?
4. **Mobile Deployment Reliability:** Does building an Android APK take 30 seconds or 10 minutes? Is the resulting binary 6MB or 60MB?

---

## 2. Engine Comparison Matrix

| Criteria | **Defold** | **Godot 4** | **Unity** | **Love2D / Solar2D** |
|---|---|---|---|---|
| **Language** | Lua 5.1 / LuaJIT | GDScript / C# | C# | Lua |
| **Hot Reload** | **Native sub-second hot reload** over socket (scripts, textures, materials) | Script reload only (often requires scene re-instantiation) | Domain reload takes 5–20s; no live state preservation | Love2D: manual library (lurker); Solar2D: fast live reload |
| **Agent Interoperability** | **Exceptional.** Plaintext protobuf (`.collection`, `.gui`, `.go`) + pure Lua | **Very High.** Plaintext `.tscn` & `.gd`, human-readable | **Poor.** GUID hell, `.meta` file desync, YAML merge conflicts | **High.** Pure Lua files, minimal editor metadata |
| **Headless Simulation** | **Instantaneous.** Pure Lua logic runs via standard CLI runner or `bob.jar` in ms | Moderate. Requires `godot --headless`, takes 1–3s boot | Slow. Requires batch-mode Unity editor boot (10–30s) | Instantaneous via standard Lua CLI |
| **Engine Footprint & APK Size** | **~5 MB base APK.** Zero engine bloat. 60–120 FPS on $80 phones | ~35–50 MB base APK. Good 2D performance | ~25–45 MB base APK. High memory overhead | ~8–15 MB. Good performance |
| **Visual UI / Scene Editor** | Lightweight, minimalist 2D GUI & node editor. Fast, but less flashy | **Rich 2D editor.** Built-in Control nodes, visual theme editor | Rich visual editor, extensive asset store, heavy IDE | Minimal to none. Mostly code-driven layout |
| **Native Mobile Extensions** | First-class official extensions (AdMob, Google Play Billing, GPGS) | Third-party GDExtension / custom export templates (can be brittle) | Massive plugin ecosystem, but constant version breakages | Community plugins, inconsistent upkeep |
| **MCP / Tooling Integration** | **Direct MCP Server already integrated** (`defold-mcp` with Bob 1.14.0) | Third-party community MCPs only | Heavy COM/IPC or custom MCP servers | None |

---

## 3. Deep Dive: Defold's Iteration Strengths

### A. Instant Socket Hot-Reloading
Defold has an in-engine HTTP/socket server running during development (`dmengine`). You can modify:
- Any Lua script
- Textures & Atlases
- Shaders & Materials

...and trigger a reload. The engine re-executes the module **in place** while preserving existing Lua state and object positions. For a match-3 game, you can tweak cascade physics, swap feel, or match detection algorithms *while a level is actively paused or playing* without restarting from the title screen.

### B. Agent-Friendly Clean Architecture
- Defold scenes (`.collection`), game objects (`.go`), and interfaces (`.gui`) are formatted in lightweight, human-readable Protobuf text.
- An AI agent can parse, write, and patch these files cleanly with zero risk of "meta file corruption" (the #1 failure mode when using agents with Unity).
- No hidden GUIDs: links between components are plain relative paths (e.g. `path: "/board#board_script"`).

### C. Direct Headless CLI Tool (`bob.jar`)
- Defold’s build tool `bob.jar` is a standalone Java JAR.
- It can resolve dependencies, compile assets, build project bundles, and package signed Android APKs completely unattended via command line.
- In our local environment, `defold-mcp` is **already active and equipped with Bob 1.13.2 and 1.14.0**.

### D. Zero-Bloat Mobile Runtime
- Royal Match’s success relies heavily on 60–120 FPS smoothness, instant taps, and zero stutter during large board explosions.
- Defold’s engine core is written in ultra-optimized C++, with no heavy garbage collection pauses. It delivers buttery-smooth mobile rendering even on older Android devices.

---

## 4. Defold’s Limitations & How We Mitigate Them

| Limitation | Impact | Mitigation Strategy |
|---|---|---|
| **GUI Layout System is simpler than Godot's UI anchors** | Building complex responsive menus requires understanding Defold GUI box nodes and pivot modes. | We will keep HUD and UI modular, using reusable GUI templates with explicit anchor rules. |
| **No visual particle graph / node editor** | Creating complex fireworks and glowing lantern particles is done via `.particlefx` text files. | Defold has a built-in particle fx editor in the Defold Editor; agents can author and parameterize them easily. |
| **Ecosystem size is smaller than Unity** | Fewer pre-made asset store templates to buy. | We are writing an original game engine tailored specifically for *Lantern Grove* (Royal Match mechanics); custom architecture is cleaner and avoids third-party technical debt. |

---

## 5. Recommendation

**Defold offers the highest net iteration capability for this specific project and team setup.**

1. **Compared to Godot:** Godot has a slightly friendlier UI node editor, but Defold wins decisively on Android footprint (5MB vs 40MB), startup speed, memory predictability, and headless CI.
2. **Compared to Unity:** Unity is drastically slower to iterate with AI agents due to domain reload lag, heavy compilation, merge conflicts, and fragile GUID metadata.
3. **Tooling Advantage:** You already have the `defold-mcp` environment configured and operational on this machine with Bob ready.

**Verdict:** Proceed with **Defold + Lua**.
