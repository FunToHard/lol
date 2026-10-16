# Asset Catalog Specification: Lantern Grove

**Document Status:** Asset Definitions & Palette Standards  
**Target Resolution:** 128×128 base tile sprites (256×256 @2x for high-DPI displays)  
**Visual Style:** Cozy twilight woodland with glowing amber, bioluminescence, and high-readability tactile shapes.

---

## 1. Palette Standards

| Token | Hex | Role | Mood / Association |
|---|---|---|---|
| `night_bg` | `#0C101D` | Canvas / Scene backdrop | Midnight twilight forest |
| `board_slot` | `#162032` | Cell recessed pocket | Carved river slate with soft moss |
| `amber_primary` | `#F59E0B` | Tile: Amber Acorn | Warm hearth flame, comfort |
| `emerald_primary` | `#10B981` | Tile: Forest Leaf | Fern leaves, woodland life |
| `sapphire_primary` | `#3B82F6` | Tile: Twilight Sapphire | Clear spring water, moon reflection |
| `ruby_primary` | `#EF4444` | Tile: Dawn Ruby | Night-blooming camellia blossom |
| `amethyst_primary` | `#8B5CF6` | Tile: Mystic Star | Evening twilight, enchanted crystal |
| `brass_accent` | `#FBBF24` | Metal trims & Lantern frames | Antique polished brass, lantern filigree |

---

## 2. Match-3 Pieces (100% Colorblind Accessible)

Every piece features:
1. A unique **outer silhouette** easily recognizable at small scale.
2. An **embossed inner icon** reinforcing the identity.
3. Subtle top-down specular highlight giving physical candy/gem tactile depth.

| Asset ID | Shape Silhouette | Symbol | Color Gradient |
|---|---|---|---|
| `piece_amber` | Acorn / Teardrop | Sacred Hearth Flame | `#FBBF24` → `#D97706` |
| `piece_emerald` | Chamfered Hexagon | Woodland Oak Leaf | `#34D399` → `#059669` |
| `piece_sapphire` | Diamond Prism | Moon Water Droplet | `#60A5FA` → `#1D4ED8` |
| `piece_ruby` | Rounded Blossom / Heart | Night Lily Flower | `#F87171` → `#B91C1C` |
| `piece_amethyst` | 4-Point Curved Star | Mystic Crystal Shard | `#A78BFA` → `#6D28D9` |

---

## 3. Power-Up Pieces

| Asset ID | Description | Visual Details |
|---|---|---|
| `powerup_rocket_h` | Horizontal Sky Rocket | Carved walnut rocket, polished brass bands, glowing amber tip, horizontal directional arrows |
| `powerup_rocket_v` | Vertical Sky Rocket | Same as above with vertical directional orientation |
| `powerup_bomb` | Woodland Bomb | Spherical dark iron pot, carved leaf runes with glowing amber fissures, sparkling fuse |
| `powerup_firefly` | Firefly Jar | Fluted glass jar, cork stopper with copper tie, radiant bioluminescent golden firefly inside |
| `powerup_lantern` | Magic Rainbow Lantern | Hexagonal pagoda lantern, antique bronze framing, multifaceted iridescent rainbow crystal core |

---

## 4. Obstacles & Ingredients

| Asset ID | Dimensions | Description |
|---|---|---|
| `obstacle_bramble_1` | 128×128 | Thorn vines layer 1 (partially damaged) |
| `obstacle_bramble_2` | 128×128 | Dense thorny bramble vines layer 2 (full strength) |
| `obstacle_stone_1` | 128×128 | Cracked ancient mossy river stone |
| `obstacle_stone_2` | 128×128 | Smooth solid ancient mossy river stone |
| `ingredient_acorn` | 128×128 | Golden woodland acorn (falling collection ingredient) |

---

## 5. Board, Tokens & UI Elements

| Asset ID | Dimensions | Description |
|---|---|---|
| `cell_slot` | 128×128 | Inset carved dark river slate cell |
| `cell_highlight` | 128×128 | Golden halo aura for active selection/drag |
| `token_star` | 128×128 | Radiant golden restoration star with warm trail |
| `token_coin` | 128×128 | Antique woodland brass coin stamped with an acorn |
| `hud_moves_capsule` | 128×128 | Ornate wooden move counter plaque |
| `hud_goal_capsule` | 128×128 | Compact dark slate goal capsule |
| `btn_settings` | 128×128 | Carved wooden cog settings button |
| `btn_play` | 128×128 | Glowing emerald play button with gold rim |

---

## 6. Atlas Compilation

All 23 sprites are compiled into the Defold texture atlas:
* **Path:** `assets/atlases/game.atlas`
* **Trim Mode:** `SPRITE_TRIM_MODE_OFF`
* **Margin / Extrude:** `2px` extrude borders to prevent tile bleeding in texture filtering.

