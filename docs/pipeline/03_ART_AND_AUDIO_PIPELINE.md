# Pipeline Stage 3: Art, Visual FX & Audio Pipeline

**Goal:** Establish a repeatable production pipeline for high-readability 2D assets, cozy visual juice, and dynamic audio without relying on an external art department.

---

## 1. Visual Direction & Color Palette

*Lantern Grove* blends the warm coziness of *Animal Crossing* and *Ghibli woodland night scenes* with the hyper-readable clarity of *Royal Match*.

### Core Color Palette
- **Deep Night / Backgrounds:** Midnight Navy (`#161B2E`), Dark Forest Teal (`#0F2424`).
- **Warm Glow / Primary Accent:** Hearth Amber (`#F5A623`), Radiant Golden Lantern (`#FFD166`).
- **Nature Accents:** Moss Green (`#48A97A`), Soft Wood Brown (`#5A3E2B`).

### The 5 Standard Piece Silhouettes (100% Colorblind Accessible)
Every tile must be immediately identifiable by **silhouette and interior icon alone**, never solely by color:

| Color Identity | Tile Shape | Symbol / Motif |
|---|---|---|
| **Amber Gold** | Round Acorn / Teardrop | Glowing Hearth Flame |
| **Forest Emerald** | Hexagonal Leaf | Woodland Fern / Oak Leaf |
| **Twilight Sapphire** | Diamond Prism | Moon Water Droplet |
| **Dawn Ruby** | Soft Heart / Flower | Night-blooming Blossom |
| **Mystic Amethyst** | Starburst (4-point) | Star / Crystal Shard |

---

## 2. 2D/3D Hybrid Asset Workflow

To maintain consistent isometric perspective, shadows, and materials across the woodland village without hand-drawing every angle:

```
[ 3D Graybox / Low-Poly Prop in Blender ]
                    │
                    ▼
[ Fixed Lighting Rig (Orthographic 30° / Sunset Rim Light) ]
                    │
                    ▼
[ High-Res 2D Render Export (PNG with Alpha) ]
                    │
                    ▼
[ Krita Touch-up: Line Art Accents & Color Balancing ]
                    │
                    ▼
[ Defold Texture Atlas Compilation via Bob ]
```

### Key Tool Roles
1. **Blender:** Used for village props (lanterns, teahouses, wooden benches, stone arches). Fixed camera and lighting guarantees every asset matches perspective perfectly.
2. **Krita:** Used for UI frames, icon polishing, 9-slice slice scaling, and hand-painted touches.
3. **Defold Atlases:** Auto-packed sprite sheets with power-of-two padding and zero runtime texture switching.

---

## 3. "Game Feel" & Juice System

The tactile delight of *Royal Match* comes from micro-animations and physics feedback:

* **Squash & Stretch:** When tiles drop and hit the bottom or another tile, they compress 15% on the Y-axis and expand 15% on the X-axis for 80ms before rebounding.
* **Trail Effects:** Rockets and Fireflies emit warm glowing particle trails with soft alpha fade.
* **Subtle Screen Shake:** 
  * Normal Match: 0px shake.
  * Bomb / Rocket: 2–3px impulse shake for 100ms.
  * Mega Combos (Light Ball + Light Ball): 6px shake with radial light burst.
* **Haptics:** Android vibration API calls:
  * Legal swap: Light tick (10ms).
  * Power-up detonation: Medium thump (25ms).
  * Level Victory: Triple burst fanfare vibration.

---

## 4. Adaptive Audio Architecture

Audio gives puzzles their rhythm and dopamine feedback loop:

### Dynamic Pentatonic Cascade Pitching
When a single move triggers successive automatic cascades, the match chime sound pitches up along a warm pentatonic scale (Root, 2nd, 3rd, 5th, 6th, Octave):
- **Cascade 1:** C4 chime + crisp wood pop.
- **Cascade 2:** D4 chime (+2 semitones).
- **Cascade 3:** E4 chime (+4 semitones).
- **Cascade 4:** G4 chime (+7 semitones).
- **Cascade 5+:** High C5 chime with golden firefly sparkles.

### Ambient Soundscape
- Main Menu / Village: Soft acoustic guitar, gentle night wind, soothing crickets, and flickering campfire crackles.
- Puzzle Board: Low-key, non-intrusive rhythmic background that lowers in volume during intense cascades so sound effects remain punchy and clear.
