"""Level authoring generator for Lantern Grove Batch 1 (Levels 1 to 25).
Generates valid JSON level definitions adhering to the project level schema.
"""

import json
import os

LEVELS_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "levels")
os.makedirs(LEVELS_DIR, exist_ok=True)

def generate_level(level_id, difficulty, moves, width, height, goals, active_mask=None, obstacles=None, spawners=None):
    if active_mask is None:
        active_mask = ["1" * width for _ in range(height)]
    
    if obstacles is None:
        obstacles = []
        
    if spawners is None:
        spawners = [{"col": c, "colors": ["amber", "emerald", "sapphire", "ruby", "amethyst"]} for c in range(width)]

    level = {
        "version": 1,
        "level_id": level_id,
        "difficulty": difficulty,
        "moves": moves,
        "grid": {
            "width": width,
            "height": height,
            "active_cells": active_mask
        },
        "spawners": spawners,
        "obstacles": obstacles,
        "goals": goals
    }
    return level

batch_1 = []

intro_spawners = [{"col": c, "colors": ["amber", "emerald", "sapphire", "ruby"]} for c in range(8)]

# Level 1: Gentle introduction to Match-3
batch_1.append(generate_level(
    1, "intro", moves=26, width=8, height=8,
    spawners=intro_spawners,
    goals=[{"type": "collect_color", "target": "amber", "count": 12}]
))

# Level 2: Two-color collection
batch_1.append(generate_level(
    2, "intro", moves=28, width=8, height=8,
    spawners=intro_spawners,
    goals=[
        {"type": "collect_color", "target": "emerald", "count": 12},
        {"type": "collect_color", "target": "sapphire", "count": 12}
    ]
))

# Level 3: Rocket incentive with high piece counts
batch_1.append(generate_level(
    3, "intro", moves=26, width=8, height=8,
    spawners=intro_spawners,
    goals=[
        {"type": "collect_color", "target": "ruby", "count": 14},
        {"type": "collect_color", "target": "emerald", "count": 14}
    ]
))

# Level 4: Introduction of Bramble obstacles (1-layer)
batch_1.append(generate_level(
    4, "intro", moves=26, width=8, height=8,
    spawners=intro_spawners,
    goals=[{"type": "clear_obstacle", "target": "bramble", "count": 6}],
    obstacles=[
        {"type": "bramble", "layer": 1, "x": 2, "y": 3},
        {"type": "bramble", "layer": 1, "x": 3, "y": 3},
        {"type": "bramble", "layer": 1, "x": 4, "y": 3},
        {"type": "bramble", "layer": 1, "x": 5, "y": 3},
        {"type": "bramble", "layer": 1, "x": 3, "y": 4},
        {"type": "bramble", "layer": 1, "x": 4, "y": 4}
    ]
))

# Level 5: Mini-challenge combining Brambles and collection
batch_1.append(generate_level(
    5, "intro", moves=28, width=8, height=8,
    spawners=intro_spawners,
    goals=[
        {"type": "clear_obstacle", "target": "bramble", "count": 8},
        {"type": "collect_color", "target": "amber", "count": 14}
    ],
    obstacles=[
        {"type": "bramble", "layer": 1, "x": 1, "y": 4},
        {"type": "bramble", "layer": 1, "x": 2, "y": 4},
        {"type": "bramble", "layer": 1, "x": 5, "y": 4},
        {"type": "bramble", "layer": 1, "x": 6, "y": 4},
        {"type": "bramble", "layer": 1, "x": 1, "y": 5},
        {"type": "bramble", "layer": 1, "x": 2, "y": 5},
        {"type": "bramble", "layer": 1, "x": 5, "y": 5},
        {"type": "bramble", "layer": 1, "x": 6, "y": 5}
    ]
))

# --- FLOW LEVELS (6 - 15): Target Win Rate 75% - 85% ---
# Level 6: Custom grid shape with corner cutouts
batch_1.append(generate_level(
    6, "flow", moves=25, width=8, height=8,
    active_mask=[
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110"
    ],
    goals=[{"type": "clear_obstacle", "target": "bramble", "count": 10}],
    obstacles=[
        {"type": "bramble", "layer": 1, "x": 2, "y": 2},
        {"type": "bramble", "layer": 1, "x": 5, "y": 2},
        {"type": "bramble", "layer": 1, "x": 3, "y": 3},
        {"type": "bramble", "layer": 1, "x": 4, "y": 3},
        {"type": "bramble", "layer": 1, "x": 2, "y": 4},
        {"type": "bramble", "layer": 1, "x": 5, "y": 4},
        {"type": "bramble", "layer": 1, "x": 3, "y": 5},
        {"type": "bramble", "layer": 1, "x": 4, "y": 5},
        {"type": "bramble", "layer": 1, "x": 1, "y": 3},
        {"type": "bramble", "layer": 1, "x": 6, "y": 3}
    ]
))

# Level 7: Introduction to 2-layer Bramble bushes
batch_1.append(generate_level(
    7, "flow", moves=26, width=8, height=8,
    goals=[{"type": "clear_obstacle", "target": "bramble", "count": 8}],
    obstacles=[
        {"type": "bramble", "layer": 2, "x": 2, "y": 3},
        {"type": "bramble", "layer": 2, "x": 3, "y": 3},
        {"type": "bramble", "layer": 2, "x": 4, "y": 3},
        {"type": "bramble", "layer": 2, "x": 5, "y": 3},
        {"type": "bramble", "layer": 2, "x": 2, "y": 4},
        {"type": "bramble", "layer": 2, "x": 3, "y": 4},
        {"type": "bramble", "layer": 2, "x": 4, "y": 4},
        {"type": "bramble", "layer": 2, "x": 5, "y": 4}
    ]
))

# Level 8: Bomb incentive (cluster destruction)
batch_1.append(generate_level(
    8, "flow", moves=26, width=8, height=8,
    goals=[
        {"type": "clear_obstacle", "target": "bramble", "count": 12},
        {"type": "collect_color", "target": "emerald", "count": 18}
    ],
    obstacles=[
        {"type": "bramble", "layer": 1, "x": c, "y": 5} for c in range(1, 7)
    ] + [
        {"type": "bramble", "layer": 2, "x": c, "y": 6} for c in range(2, 6)
    ] + [
        {"type": "bramble", "layer": 1, "x": 3, "y": 4},
        {"type": "bramble", "layer": 1, "x": 4, "y": 4}
    ]
))

# Level 9: First Ingredient Acorn drop level
batch_1.append(generate_level(
    9, "flow", moves=24, width=8, height=8,
    goals=[{"type": "drop_ingredient", "target": "acorn", "count": 2}],
    obstacles=[
        {"type": "ingredient", "layer": 1, "x": 2, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 5, "y": 0}
    ]
))

# Level 10: Acorns + Color collection
batch_1.append(generate_level(
    10, "flow", moves=25, width=8, height=8,
    goals=[
        {"type": "drop_ingredient", "target": "acorn", "count": 2},
        {"type": "collect_color", "target": "ruby", "count": 20}
    ],
    obstacles=[
        {"type": "ingredient", "layer": 1, "x": 1, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 6, "y": 0},
        {"type": "bramble", "layer": 1, "x": 1, "y": 3},
        {"type": "bramble", "layer": 1, "x": 6, "y": 3}
    ]
))

# Level 11: Introduction to solid River Stones
batch_1.append(generate_level(
    11, "flow", moves=26, width=8, height=8,
    goals=[
        {"type": "clear_obstacle", "target": "bramble", "count": 10}
    ],
    obstacles=[
        {"type": "stone", "layer": 1, "x": 2, "y": 3},
        {"type": "stone", "layer": 1, "x": 5, "y": 3},
        {"type": "bramble", "layer": 1, "x": 1, "y": 4},
        {"type": "bramble", "layer": 1, "x": 2, "y": 4},
        {"type": "bramble", "layer": 1, "x": 3, "y": 4},
        {"type": "bramble", "layer": 1, "x": 4, "y": 4},
        {"type": "bramble", "layer": 1, "x": 5, "y": 4},
        {"type": "bramble", "layer": 1, "x": 6, "y": 4},
        {"type": "bramble", "layer": 1, "x": 3, "y": 5},
        {"type": "bramble", "layer": 1, "x": 4, "y": 5},
        {"type": "bramble", "layer": 1, "x": 2, "y": 5},
        {"type": "bramble", "layer": 1, "x": 5, "y": 5}
    ]
))

# Level 12: Cross shaped board
batch_1.append(generate_level(
    12, "flow", moves=25, width=8, height=8,
    active_mask=[
        "00111100",
        "00111100",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "00111100",
        "00111100"
    ],
    goals=[
        {"type": "clear_obstacle", "target": "bramble", "count": 10},
        {"type": "collect_color", "target": "sapphire", "count": 16}
    ],
    obstacles=[
        {"type": "bramble", "layer": 1, "x": c, "y": 3} for c in range(1, 7)
    ] + [
        {"type": "bramble", "layer": 1, "x": c, "y": 4} for c in range(2, 6)
    ]
))

# Level 13: Narrow chute Acorn drops
batch_1.append(generate_level(
    13, "flow", moves=25, width=8, height=8,
    goals=[
        {"type": "drop_ingredient", "target": "acorn", "count": 2},
        {"type": "clear_obstacle", "target": "bramble", "count": 6}
    ],
    obstacles=[
        {"type": "ingredient", "layer": 1, "x": 3, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 4, "y": 0},
        {"type": "bramble", "layer": 1, "x": 3, "y": 4},
        {"type": "bramble", "layer": 1, "x": 4, "y": 4},
        {"type": "bramble", "layer": 1, "x": 3, "y": 5},
        {"type": "bramble", "layer": 1, "x": 4, "y": 5},
        {"type": "bramble", "layer": 1, "x": 2, "y": 4},
        {"type": "bramble", "layer": 1, "x": 5, "y": 4}
    ]
))

# Level 14: 14 mixed Brambles + Emeralds
batch_1.append(generate_level(
    14, "flow", moves=27, width=8, height=8,
    goals=[
        {"type": "clear_obstacle", "target": "bramble", "count": 12},
        {"type": "collect_color", "target": "emerald", "count": 20}
    ],
    obstacles=[
        {"type": "bramble", "layer": 2, "x": 1, "y": 5},
        {"type": "bramble", "layer": 2, "x": 2, "y": 5},
        {"type": "bramble", "layer": 2, "x": 5, "y": 5},
        {"type": "bramble", "layer": 2, "x": 6, "y": 5},
        {"type": "bramble", "layer": 1, "x": 2, "y": 4},
        {"type": "bramble", "layer": 1, "x": 3, "y": 4},
        {"type": "bramble", "layer": 1, "x": 4, "y": 4},
        {"type": "bramble", "layer": 1, "x": 5, "y": 4},
        {"type": "bramble", "layer": 1, "x": 3, "y": 3},
        {"type": "bramble", "layer": 1, "x": 4, "y": 3},
        {"type": "bramble", "layer": 1, "x": 0, "y": 5},
        {"type": "bramble", "layer": 1, "x": 7, "y": 5}
    ]
))

# Level 15: Chapter Milestone Level (3 Acorns + 8 Brambles)
batch_1.append(generate_level(
    15, "flow", moves=28, width=8, height=8,
    goals=[
        {"type": "drop_ingredient", "target": "acorn", "count": 3},
        {"type": "clear_obstacle", "target": "bramble", "count": 8}
    ],
    obstacles=[
        {"type": "ingredient", "layer": 1, "x": 1, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 3, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 6, "y": 0},
        {"type": "bramble", "layer": 1, "x": 1, "y": 4},
        {"type": "bramble", "layer": 1, "x": 2, "y": 4},
        {"type": "bramble", "layer": 1, "x": 3, "y": 4},
        {"type": "bramble", "layer": 1, "x": 4, "y": 4},
        {"type": "bramble", "layer": 1, "x": 5, "y": 4},
        {"type": "bramble", "layer": 1, "x": 6, "y": 4},
        {"type": "bramble", "layer": 2, "x": 3, "y": 5},
        {"type": "bramble", "layer": 2, "x": 4, "y": 5}
    ]
))

# --- ENGAGING / HARD LEVELS (16 - 25): Target Win Rate 45% - 65% ---
# Level 16: Solid River Stones + 12 Brambles
batch_1.append(generate_level(
    16, "hard", moves=24, width=8, height=8,
    goals=[{"type": "clear_obstacle", "target": "bramble", "count": 12}],
    obstacles=[
        {"type": "stone", "layer": 2, "x": 1, "y": 3},
        {"type": "stone", "layer": 2, "x": 6, "y": 3},
        {"type": "bramble", "layer": 2, "x": 2, "y": 4},
        {"type": "bramble", "layer": 2, "x": 3, "y": 4},
        {"type": "bramble", "layer": 2, "x": 4, "y": 4},
        {"type": "bramble", "layer": 2, "x": 5, "y": 4},
        {"type": "bramble", "layer": 1, "x": 1, "y": 5},
        {"type": "bramble", "layer": 1, "x": 2, "y": 5},
        {"type": "bramble", "layer": 1, "x": 3, "y": 5},
        {"type": "bramble", "layer": 1, "x": 4, "y": 5},
        {"type": "bramble", "layer": 1, "x": 5, "y": 5},
        {"type": "bramble", "layer": 1, "x": 6, "y": 5},
        {"type": "bramble", "layer": 1, "x": 3, "y": 6},
        {"type": "bramble", "layer": 1, "x": 4, "y": 6}
    ]
))

# Level 17: Donut/Ring shaped board
batch_1.append(generate_level(
    17, "hard", moves=23, width=8, height=8,
    active_mask=[
        "11111111",
        "11111111",
        "11000011",
        "11000011",
        "11000011",
        "11000011",
        "11111111",
        "11111111"
    ],
    goals=[
        {"type": "collect_color", "target": "amber", "count": 22},
        {"type": "collect_color", "target": "ruby", "count": 22}
    ]
))

# Level 18: 3 Acorns through stone-bordered channels
batch_1.append(generate_level(
    18, "hard", moves=25, width=8, height=8,
    goals=[
        {"type": "drop_ingredient", "target": "acorn", "count": 3},
        {"type": "clear_obstacle", "target": "bramble", "count": 8}
    ],
    obstacles=[
        {"type": "ingredient", "layer": 1, "x": 1, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 4, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 6, "y": 0},
        {"type": "stone", "layer": 1, "x": 2, "y": 3},
        {"type": "stone", "layer": 1, "x": 5, "y": 3},
        {"type": "bramble", "layer": 2, "x": 1, "y": 4},
        {"type": "bramble", "layer": 2, "x": 4, "y": 4},
        {"type": "bramble", "layer": 2, "x": 6, "y": 4},
        {"type": "bramble", "layer": 1, "x": 1, "y": 5},
        {"type": "bramble", "layer": 1, "x": 4, "y": 5},
        {"type": "bramble", "layer": 1, "x": 6, "y": 5},
        {"type": "bramble", "layer": 1, "x": 3, "y": 5},
        {"type": "bramble", "layer": 1, "x": 0, "y": 5}
    ]
))

# Level 19: Dual goal: 16 Brambles + 24 Rubies
batch_1.append(generate_level(
    19, "hard", moves=24, width=8, height=8,
    goals=[
        {"type": "clear_obstacle", "target": "bramble", "count": 14},
        {"type": "collect_color", "target": "ruby", "count": 24}
    ],
    obstacles=[
        {"type": "bramble", "layer": 2, "x": c, "y": 4} for c in range(1, 7)
    ] + [
        {"type": "bramble", "layer": 1, "x": c, "y": 5} for c in range(0, 8)
    ]
))

# Level 20: Super Hard hurdle (16 2-hit Brambles)
batch_1.append(generate_level(
    20, "hard", moves=24, width=8, height=8,
    goals=[{"type": "clear_obstacle", "target": "bramble", "count": 16}],
    obstacles=[
        {"type": "bramble", "layer": 2, "x": c, "y": r}
        for r in range(4, 6) for c in range(0, 8)
    ]
))

# Level 21: Split columns layout + drop 3 Acorns
batch_1.append(generate_level(
    21, "hard", moves=25, width=8, height=8,
    active_mask=[
        "11100111",
        "11100111",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "11100111",
        "11100111"
    ],
    goals=[
        {"type": "drop_ingredient", "target": "acorn", "count": 3},
        {"type": "collect_color", "target": "emerald", "count": 22}
    ],
    obstacles=[
        {"type": "ingredient", "layer": 1, "x": 0, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 2, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 7, "y": 0}
    ]
))

# Level 22: River stones blocking bottom collection row + 4 Acorns
batch_1.append(generate_level(
    22, "hard", moves=26, width=8, height=8,
    goals=[
        {"type": "drop_ingredient", "target": "acorn", "count": 3},
        {"type": "clear_obstacle", "target": "bramble", "count": 10}
    ],
    obstacles=[
        {"type": "ingredient", "layer": 1, "x": 1, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 3, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 5, "y": 0},
        {"type": "stone", "layer": 1, "x": 0, "y": 7},
        {"type": "stone", "layer": 1, "x": 2, "y": 7},
        {"type": "stone", "layer": 1, "x": 4, "y": 7},
        {"type": "stone", "layer": 1, "x": 6, "y": 7},
        {"type": "bramble", "layer": 1, "x": 1, "y": 6},
        {"type": "bramble", "layer": 1, "x": 3, "y": 6},
        {"type": "bramble", "layer": 1, "x": 5, "y": 6},
        {"type": "bramble", "layer": 1, "x": 7, "y": 6},
        {"type": "bramble", "layer": 2, "x": 2, "y": 5},
        {"type": "bramble", "layer": 2, "x": 4, "y": 5},
        {"type": "bramble", "layer": 1, "x": 1, "y": 5},
        {"type": "bramble", "layer": 1, "x": 5, "y": 5},
        {"type": "bramble", "layer": 1, "x": 3, "y": 4},
        {"type": "bramble", "layer": 1, "x": 4, "y": 4}
    ]
))

# Level 23: Diamond grid layout + 14 Brambles + 25 Amethysts
batch_1.append(generate_level(
    23, "hard", moves=25, width=8, height=8,
    active_mask=[
        "00011000",
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "01111110",
        "00111100",
        "00011000"
    ],
    goals=[
        {"type": "clear_obstacle", "target": "bramble", "count": 12},
        {"type": "collect_color", "target": "amethyst", "count": 22}
    ],
    obstacles=[
        {"type": "bramble", "layer": 2, "x": 3, "y": 3},
        {"type": "bramble", "layer": 2, "x": 4, "y": 3},
        {"type": "bramble", "layer": 2, "x": 3, "y": 4},
        {"type": "bramble", "layer": 2, "x": 4, "y": 4},
        {"type": "bramble", "layer": 1, "x": 2, "y": 3},
        {"type": "bramble", "layer": 1, "x": 5, "y": 3},
        {"type": "bramble", "layer": 1, "x": 2, "y": 4},
        {"type": "bramble", "layer": 1, "x": 5, "y": 4},
        {"type": "bramble", "layer": 1, "x": 3, "y": 2},
        {"type": "bramble", "layer": 1, "x": 4, "y": 2},
        {"type": "bramble", "layer": 1, "x": 3, "y": 5},
        {"type": "bramble", "layer": 1, "x": 4, "y": 5}
    ]
))

# Level 24: High-density 2-layer Brambles + 28 Sapphires
batch_1.append(generate_level(
    24, "hard", moves=26, width=8, height=8,
    goals=[
        {"type": "clear_obstacle", "target": "bramble", "count": 16},
        {"type": "collect_color", "target": "sapphire", "count": 26}
    ],
    obstacles=[
        {"type": "bramble", "layer": 2, "x": c, "y": 4} for c in range(0, 8)
    ] + [
        {"type": "bramble", "layer": 2, "x": c, "y": 5} for c in range(0, 8)
    ]
))

# Level 25: Climax Milestone Level (4 Acorns + 14 2-hit Brambles)
batch_1.append(generate_level(
    25, "hard", moves=28, width=8, height=8,
    goals=[
        {"type": "drop_ingredient", "target": "acorn", "count": 4},
        {"type": "clear_obstacle", "target": "bramble", "count": 14}
    ],
    obstacles=[
        {"type": "ingredient", "layer": 1, "x": 0, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 2, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 5, "y": 0},
        {"type": "ingredient", "layer": 1, "x": 7, "y": 0},
        {"type": "bramble", "layer": 2, "x": 1, "y": 4},
        {"type": "bramble", "layer": 2, "x": 2, "y": 4},
        {"type": "bramble", "layer": 2, "x": 3, "y": 4},
        {"type": "bramble", "layer": 2, "x": 4, "y": 4},
        {"type": "bramble", "layer": 2, "x": 5, "y": 4},
        {"type": "bramble", "layer": 2, "x": 6, "y": 4},
        {"type": "bramble", "layer": 2, "x": 1, "y": 5},
        {"type": "bramble", "layer": 2, "x": 2, "y": 5},
        {"type": "bramble", "layer": 2, "x": 3, "y": 5},
        {"type": "bramble", "layer": 2, "x": 4, "y": 5},
        {"type": "bramble", "layer": 2, "x": 5, "y": 5},
        {"type": "bramble", "layer": 2, "x": 6, "y": 5},
        {"type": "bramble", "layer": 1, "x": 0, "y": 5},
        {"type": "bramble", "layer": 1, "x": 7, "y": 5}
    ]
))

for lvl in batch_1:
    filename = f"level_{lvl['level_id']:03d}.json"
    filepath = os.path.join(LEVELS_DIR, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(lvl, f, indent=2)
    print(f"Generated {filename}")

print(f"\nSuccessfully generated all {len(batch_1)} levels in {LEVELS_DIR}")
