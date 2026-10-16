# Pipeline Stage 4: Metagame & Restoration Pipeline

**Goal:** Bridge the match-3 puzzle loop with a meaningful, cozy woodland village restoration metagame that drives long-term player retention.

---

## 1. The Metagame Loop & Economy

```
[ Beat Level ] ──► Earn 1 Lantern Spark (Star)
                         │
                         ▼
             [ Open Task Journal ]
                         │
                         ▼
        [ Spend Stars on Restoration Task ]
                         │
                         ▼
       [ Select from 3 Customization Styles ]
                         │
                         ▼
    [ Watch Renovation Animation & Village Glow Up ]
                         │
                         ▼
          [ Unlock Rewards & Next Chapter ]
```

### Player Customization Principle
- When a task is completed (e.g., "Install the Teahouse Lanterns"), the player chooses from **3 distinct aesthetic themes**:
  * **Style A (Rustic Cedar):** Carved wood, warm honey-toned glass, traditional craftsmanship.
  * **Style B (Mossy Stone):** Ancient engraved river stone, verdigris metalwork, natural ivy.
  * **Style C (Bioluminescent / Whimsical):** Paper lanterns, hanging crystals, enchanted blue/purple flora.
- **Zero-Friction Re-styling:** Players can tap any restored object in the village at any time to switch styles for free. Customization is expressive, not punitive.

---

## 2. Technical Implementation in Defold

The village scene is rendered as an interactive, layered **2.5D Diorama** in a dedicated Defold collection (`village.collection`):

### Scene Layer Hierarchy
1. **Layer 0 (Background Plate):** Painted woodland backdrop and ground terrain.
2. **Layer 1 (Pre-restoration Ruins):** Dilapidated, mossy versions of structures. When repaired, these smoothly cross-fade or pop into their restored versions.
3. **Layer 2 (Restored Props):** Game objects with sprite components representing the player's selected style (`rustic`, `mossy`, `whimsical`).
4. **Layer 3 (Ambient Juice & Lighting):**
   * Particle FX: Drifting golden fireflies, gentle campfire smoke, falling autumn leaves.
   * Shaders: Simple 2D radial light-mask shader to render warm flickering lantern pools in real-time.
5. **Layer 4 (Guide Character):**
   * A friendly village companion (e.g., *Pip the Owl* or *Bramble the Hedgehog*) who reacts with joyful emotes when tasks finish.
6. **Layer 5 (Village HUD):**
   * Task Journal button with unread badge.
   * Spark / Coin balances.
   * Big green "Play Level X" button.

---

## 3. Data Schema for Village Progression

Village state is serialized as a lightweight, clean JSON block within the player save file:

```json
{
  "current_area": "hearthstone_courtyard",
  "areas": {
    "hearthstone_courtyard": {
      "completed_tasks": [
        {"task_id": "repair_main_hearth", "chosen_style": 1},
        {"task_id": "clear_overgrowth", "chosen_style": 0},
        {"task_id": "install_lanterns", "chosen_style": 2}
      ],
      "active_task_index": 3
    }
  }
}
```

---

## 4. Area Roadmap (Vertical Slice to Beta)

| Area | Theme | Tasks | Levels Covered |
|---|---|---|---|
| **Area 1: Hearthstone Courtyard** | Abandoned central plaza, overgrown fountain, cold stone hearth | 12 tasks | Levels 1–25 |
| **Area 2: Whispering Willow Pond** | Overgrown koi pond, broken wooden bridge, dark water lanterns | 16 tasks | Levels 26–55 |
| **Area 3: Firefly Ridge** | Mountain shrine, wind chimes, twilight stargazing tower | 20 tasks | Levels 56–90 |
