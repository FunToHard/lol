#!/usr/bin/env python3
"""
tools/build_sprites.py

Generates the full set of 23 high-fidelity, colorblind-accessible 2D sprites
for Lantern Grove as 128x128 32-bit transparent PNGs and compiles the Defold .atlas file.
"""

import os
import re
import json
import base64
import subprocess

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SPRITES_DIR = os.path.join(PROJECT_ROOT, "assets", "sprites")
ATLAS_DIR = os.path.join(PROJECT_ROOT, "assets", "atlases")

os.makedirs(SPRITES_DIR, exist_ok=True)
os.makedirs(ATLAS_DIR, exist_ok=True)

# Define SVGs (viewBox 0 0 100 100)
SPRITES = {
    # 1. 5 Core Match-3 Pieces
    "piece_amber": """
      <path d="M50 10 C68 35 84 55 84 70 C84 84 69 92 50 92 C31 92 16 84 16 70 C16 55 32 35 50 10 Z" fill="url(#grad-amber)" stroke="url(#grad-amber-rim)" stroke-width="3"/>
      <path d="M46 22 C34 40 26 56 26 68" stroke="#ffffff" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.65"/>
      <path d="M50 42 C56 50 62 58 60 68 C58 75 52 78 50 78 C48 78 42 75 40 68 C38 58 44 50 50 42 Z" fill="#ffffff" opacity="0.95"/>
    """,
    "piece_emerald": """
      <polygon points="50,12 85,32 85,68 50,88 15,68 15,32" fill="url(#grad-emerald)" stroke="url(#grad-emerald-rim)" stroke-width="3"/>
      <path d="M22 36 L48 20 L76 34" stroke="#ffffff" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.65"/>
      <path d="M50 34 L50 74 M42 46 L50 54 M58 46 L50 54 M40 58 L50 66 M60 58 L50 66" stroke="#ffffff" stroke-width="4.5" stroke-linecap="round" fill="none" opacity="0.95"/>
    """,
    "piece_sapphire": """
      <polygon points="50,10 88,50 50,90 12,50" fill="url(#grad-sapphire)" stroke="url(#grad-sapphire-rim)" stroke-width="3"/>
      <polygon points="50,15 82,50 50,50" fill="#ffffff" opacity="0.25"/>
      <path d="M22 48 L48 18" stroke="#ffffff" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.7"/>
      <path d="M50 34 C58 44 64 54 64 64 C64 72 58 76 50 76 C42 76 36 72 36 64 C36 54 42 44 50 34 Z" fill="#ffffff" opacity="0.95"/>
    """,
    "piece_ruby": """
      <path d="M50 88 C20 70 12 50 16 34 C20 18 36 18 50 32 C64 18 80 18 84 34 C88 50 80 70 50 88 Z" fill="url(#grad-ruby)" stroke="url(#grad-ruby-rim)" stroke-width="3"/>
      <path d="M24 30 C30 22 40 24 46 32" stroke="#ffffff" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.65"/>
      <circle cx="50" cy="50" r="7" fill="#ffffff" opacity="0.95"/>
      <circle cx="50" cy="38" r="4.5" fill="#ffffff" opacity="0.85"/>
      <circle cx="50" cy="62" r="4.5" fill="#ffffff" opacity="0.85"/>
      <circle cx="38" cy="50" r="4.5" fill="#ffffff" opacity="0.85"/>
      <circle cx="62" cy="50" r="4.5" fill="#ffffff" opacity="0.85"/>
    """,
    "piece_amethyst": """
      <path d="M50 10 C50 36 64 50 90 50 C64 50 50 64 50 90 C50 64 36 50 10 50 C36 50 50 36 50 10 Z" fill="url(#grad-amethyst)" stroke="url(#grad-amethyst-rim)" stroke-width="3"/>
      <path d="M24 46 C38 46 46 38 46 24" stroke="#ffffff" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.75"/>
      <polygon points="50,34 60,50 50,66 40,50" fill="#ffffff" opacity="0.95"/>
    """,

    # 2. Power-Ups
    "powerup_rocket_h": """
      <rect x="22" y="32" width="56" height="36" rx="8" fill="url(#grad-wood)" stroke="url(#grad-brass)" stroke-width="2.5"/>
      <rect x="36" y="32" width="6" height="36" fill="url(#grad-brass)"/>
      <rect x="58" y="32" width="6" height="36" fill="url(#grad-brass)"/>
      <path d="M78 32 L94 50 L78 68 Z" fill="url(#grad-amber)" stroke="url(#grad-brass)" stroke-width="2"/>
      <path d="M22 32 L10 20 L22 42 Z" fill="#92400e"/>
      <path d="M22 68 L10 80 L22 58 Z" fill="#92400e"/>
      <path d="M20 50 Q10 46 4 52" stroke="#f59e0b" stroke-width="3" fill="none"/>
      <circle cx="4" cy="52" r="3" fill="#fef08a"/>
      <path d="M46 50 L54 50 M50 46 L54 50 L50 54" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "powerup_rocket_v": """
      <rect x="32" y="22" width="36" height="56" rx="8" fill="url(#grad-wood)" stroke="url(#grad-brass)" stroke-width="2.5"/>
      <rect x="32" y="36" width="36" height="6" fill="url(#grad-brass)"/>
      <rect x="32" y="58" width="36" height="6" fill="url(#grad-brass)"/>
      <path d="M32 22 L50 6 L68 22 Z" fill="url(#grad-amber)" stroke="url(#grad-brass)" stroke-width="2"/>
      <path d="M32 78 L20 90 L42 78 Z" fill="#92400e"/>
      <path d="M68 78 L80 90 L58 78 Z" fill="#92400e"/>
      <path d="M50 80 Q46 90 52 96" stroke="#f59e0b" stroke-width="3" fill="none"/>
      <circle cx="52" cy="96" r="3" fill="#fef08a"/>
      <path d="M50 54 L50 46 M46 50 L50 46 L54 50" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "powerup_bomb": """
      <circle cx="50" cy="56" r="34" fill="#1e293b" stroke="url(#grad-brass)" stroke-width="3"/>
      <rect x="42" y="16" width="16" height="8" rx="2" fill="url(#grad-brass)"/>
      <path d="M50 16 Q54 6 62 8" stroke="#f59e0b" stroke-width="3.5" fill="none"/>
      <circle cx="63" cy="8" r="4.5" fill="#fef08a"/>
      <circle cx="50" cy="56" r="16" fill="none" stroke="url(#grad-amber)" stroke-width="2.5" stroke-dasharray="8 4"/>
      <circle cx="50" cy="56" r="6" fill="#f59e0b"/>
    """,
    "powerup_firefly": """
      <rect x="26" y="24" width="48" height="60" rx="14" fill="rgba(191, 219, 254, 0.25)" stroke="#93c5fd" stroke-width="3"/>
      <rect x="36" y="14" width="28" height="10" rx="3" fill="#b45309" stroke="#78350f" stroke-width="2"/>
      <line x1="32" y1="24" x2="68" y2="24" stroke="url(#grad-brass)" stroke-width="3"/>
      <circle cx="50" cy="54" r="14" fill="#fef08a" opacity="0.45"/>
      <ellipse cx="50" cy="54" rx="7" ry="10" fill="#f59e0b"/>
      <ellipse cx="44" cy="50" rx="5" ry="8" fill="#ffffff" opacity="0.8" transform="rotate(-25 44 50)"/>
      <ellipse cx="56" cy="50" rx="5" ry="8" fill="#ffffff" opacity="0.8" transform="rotate(25 56 50)"/>
      <circle cx="36" cy="68" r="2.5" fill="#fef08a"/>
      <circle cx="62" cy="40" r="2" fill="#fef08a"/>
    """,
    "powerup_lantern": """
      <polygon points="50,6 84,24 16,24" fill="url(#grad-brass)" stroke="#78350f" stroke-width="2"/>
      <circle cx="50" cy="6" r="4" fill="url(#grad-brass)"/>
      <polygon points="24,78 76,78 82,90 18,90" fill="url(#grad-brass)" stroke="#78350f" stroke-width="2"/>
      <polygon points="26,24 74,24 68,78 32,78" fill="url(#grad-rainbow)" stroke="url(#grad-brass)" stroke-width="3"/>
      <line x1="50" y1="24" x2="50" y2="78" stroke="#ffffff" stroke-width="2" opacity="0.75"/>
      <circle cx="50" cy="51" r="14" fill="#ffffff" opacity="0.6"/>
    """,

    # 3. Obstacles
    "obstacle_bramble_1": """
      <path d="M15 25 Q50 40 85 20 M20 80 Q55 60 80 85 M25 15 Q40 50 15 85 M80 20 Q60 55 85 80" stroke="#78350f" stroke-width="7" stroke-linecap="round" fill="none"/>
      <path d="M35 30 L30 20 M65 25 L75 18 M28 65 L18 70 M70 70 L78 78" stroke="#b45309" stroke-width="4" stroke-linecap="round"/>
      <circle cx="50" cy="50" r="5" fill="#047857"/>
    """,
    "obstacle_bramble_2": """
      <rect x="10" y="10" width="80" height="80" rx="16" fill="rgba(69, 26, 3, 0.45)" stroke="#78350f" stroke-width="4"/>
      <path d="M15 15 L85 85 M85 15 L15 85" stroke="#78350f" stroke-width="9" stroke-linecap="round"/>
      <path d="M10 50 Q50 20 90 50 Q50 80 10 50" stroke="#92400e" stroke-width="7" fill="none"/>
      <!-- Thorns -->
      <polygon points="30,30 25,20 35,26" fill="#b45309"/>
      <polygon points="70,30 75,20 65,26" fill="#b45309"/>
      <polygon points="50,50 55,38 48,42" fill="#b45309"/>
      <!-- Small moss tufts -->
      <circle cx="36" cy="62" r="6" fill="#047857"/>
      <circle cx="64" cy="38" r="6" fill="#047857"/>
    """,
    "obstacle_stone_1": """
      <!-- Cracked river stone -->
      <path d="M20 35 C25 18 75 18 80 35 C85 55 82 78 70 85 C55 92 35 90 22 82 C14 74 15 55 20 35 Z" fill="#475569" stroke="#334155" stroke-width="4"/>
      <!-- Surface crack -->
      <path d="M45 25 L48 48 L38 60 L42 82 M48 48 L62 56" stroke="#0f172a" stroke-width="3" stroke-linecap="round" fill="none"/>
      <!-- Moss patches -->
      <ellipse cx="30" cy="32" rx="8" ry="5" fill="#059669"/>
    """,
    "obstacle_stone_2": """
      <!-- Solid smooth river stone -->
      <path d="M20 35 C25 18 75 18 80 35 C85 55 82 78 70 85 C55 92 35 90 22 82 C14 74 15 55 20 35 Z" fill="#64748b" stroke="#475569" stroke-width="4"/>
      <path d="M30 30 C45 22 65 24 72 32" stroke="#94a3b8" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.6"/>
      <!-- Moss patches -->
      <ellipse cx="28" cy="40" rx="10" ry="7" fill="#047857"/>
      <ellipse cx="65" cy="70" rx="12" ry="8" fill="#047857"/>
    """,

    # 4. Board & Cell Elements
    "cell_slot": """
      <rect x="4" y="4" width="92" height="92" rx="18" fill="#131b2a" stroke="#1e293b" stroke-width="3"/>
      <!-- Subtle inner recess shadow -->
      <rect x="7" y="7" width="86" height="86" rx="15" fill="none" stroke="#090d16" stroke-width="2"/>
    """,
    "cell_highlight": """
      <rect x="4" y="4" width="92" height="92" rx="18" fill="rgba(245, 158, 11, 0.15)" stroke="#fbbf24" stroke-width="4"/>
    """,
    "ingredient_acorn": """
      <!-- Golden Woodland Acorn -->
      <ellipse cx="50" cy="62" rx="26" ry="28" fill="url(#grad-amber)" stroke="#b45309" stroke-width="3"/>
      <!-- Cap -->
      <path d="M22 42 C24 28 76 28 78 42 Z" fill="#78350f" stroke="#451a03" stroke-width="3"/>
      <line x1="50" y1="28" x2="50" y2="18" stroke="#451a03" stroke-width="4" stroke-linecap="round"/>
      <path d="M30 38 Q50 32 70 38" stroke="#92400e" stroke-width="2.5" fill="none"/>
    """,

    # 5. Tokens & Currency
    "token_star": """
      <polygon points="50,8 62,35 92,38 69,58 76,88 50,72 24,88 31,58 8,38 38,35" fill="url(#grad-amber)" stroke="url(#grad-amber-rim)" stroke-width="3"/>
      <polygon points="50,20 57,38 77,40 62,54 67,73 50,62 33,73 38,54 23,40 43,38" fill="#fef08a" opacity="0.6"/>
    """,
    "token_coin": """
      <circle cx="50" cy="50" r="42" fill="url(#grad-brass)" stroke="#78350f" stroke-width="3"/>
      <circle cx="50" cy="50" r="34" fill="none" stroke="#b45309" stroke-width="2" stroke-dasharray="4 3"/>
      <!-- Acorn stamp -->
      <ellipse cx="50" cy="56" rx="14" ry="16" fill="#78350f"/>
      <path d="M34 46 C36 38 64 38 66 46 Z" fill="#451a03"/>
      <line x1="50" y1="38" x2="50" y2="30" stroke="#451a03" stroke-width="3" stroke-linecap="round"/>
    """,

    # 6. UI & HUD Elements
    "hud_moves_capsule": """
      <rect x="5" y="15" width="90" height="70" rx="16" fill="url(#grad-wood)" stroke="url(#grad-brass)" stroke-width="3"/>
      <rect x="12" y="22" width="76" height="56" rx="10" fill="#1e130c"/>
    """,
    "hud_goal_capsule": """
      <rect x="5" y="18" width="90" height="64" rx="20" fill="#1e293b" stroke="#334155" stroke-width="3"/>
    """,
    "btn_settings": """
      <circle cx="50" cy="50" r="42" fill="url(#grad-wood)" stroke="url(#grad-brass)" stroke-width="3.5"/>
      <!-- Gear cog -->
      <circle cx="50" cy="50" r="22" fill="#fbbf24"/>
      <circle cx="50" cy="50" r="10" fill="#2a160c"/>
      <path d="M50 20 L50 26 M50 74 L50 80 M20 50 L26 50 M74 50 L80 50 M29 29 L34 34 M66 66 L71 71 M29 71 L34 66 M66 34 L71 29" stroke="#fbbf24" stroke-width="7" stroke-linecap="round"/>
    """,
    "btn_play": """
      <circle cx="50" cy="50" r="42" fill="url(#grad-emerald)" stroke="url(#grad-brass)" stroke-width="3.5"/>
      <!-- Play Triangle -->
      <polygon points="40,28 72,50 40,72" fill="#ffffff" filter="drop-shadow(0 2px 4px rgba(0,0,0,0.4))"/>
    """
}

# SVG Defs shared across all sprites
SVG_DEFS = """
<defs>
  <radialGradient id="grad-amber" cx="40%" cy="30%" r="70%">
    <stop offset="0%" stop-color="#fef08a"/>
    <stop offset="40%" stop-color="#f59e0b"/>
    <stop offset="100%" stop-color="#b45309"/>
  </radialGradient>
  <linearGradient id="grad-amber-rim" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.8"/>
    <stop offset="100%" stop-color="#78350f" stop-opacity="0.9"/>
  </linearGradient>

  <radialGradient id="grad-emerald" cx="40%" cy="30%" r="70%">
    <stop offset="0%" stop-color="#a7f3d0"/>
    <stop offset="40%" stop-color="#10b981"/>
    <stop offset="100%" stop-color="#047857"/>
  </radialGradient>
  <linearGradient id="grad-emerald-rim" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.8"/>
    <stop offset="100%" stop-color="#064e3b" stop-opacity="0.9"/>
  </linearGradient>

  <radialGradient id="grad-sapphire" cx="40%" cy="30%" r="70%">
    <stop offset="0%" stop-color="#bfdbfe"/>
    <stop offset="40%" stop-color="#3b82f6"/>
    <stop offset="100%" stop-color="#1d4ed8"/>
  </radialGradient>
  <linearGradient id="grad-sapphire-rim" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.8"/>
    <stop offset="100%" stop-color="#172554" stop-opacity="0.9"/>
  </linearGradient>

  <radialGradient id="grad-ruby" cx="40%" cy="30%" r="70%">
    <stop offset="0%" stop-color="#fecaca"/>
    <stop offset="40%" stop-color="#ef4444"/>
    <stop offset="100%" stop-color="#b91c1c"/>
  </radialGradient>
  <linearGradient id="grad-ruby-rim" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.8"/>
    <stop offset="100%" stop-color="#7f1d1d" stop-opacity="0.9"/>
  </linearGradient>

  <radialGradient id="grad-amethyst" cx="40%" cy="30%" r="70%">
    <stop offset="0%" stop-color="#e9d5ff"/>
    <stop offset="40%" stop-color="#8b5cf6"/>
    <stop offset="100%" stop-color="#6d28d9"/>
  </radialGradient>
  <linearGradient id="grad-amethyst-rim" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.8"/>
    <stop offset="100%" stop-color="#4c1d95" stop-opacity="0.9"/>
  </linearGradient>

  <linearGradient id="grad-brass" x1="0%" y1="0%" x2="100%" y2="100%">
    <stop offset="0%" stop-color="#fef08a"/>
    <stop offset="50%" stop-color="#fbbf24"/>
    <stop offset="100%" stop-color="#92400e"/>
  </linearGradient>

  <linearGradient id="grad-wood" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#5a3825"/>
    <stop offset="100%" stop-color="#2a160c"/>
  </linearGradient>

  <radialGradient id="grad-rainbow" cx="50%" cy="50%" r="50%">
    <stop offset="0%" stop-color="#ffffff"/>
    <stop offset="35%" stop-color="#fef08a"/>
    <stop offset="60%" stop-color="#ec4899"/>
    <stop offset="85%" stop-color="#8b5cf6"/>
    <stop offset="100%" stop-color="#3b82f6"/>
  </radialGradient>
</defs>
"""


def generate_renderer_html() -> str:
    """Creates the automated browser rendering harness."""
    items_js = []
    for name, content in SPRITES.items():
        svg_full = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="128" height="128">{SVG_DEFS}{content}</svg>'
        items_js.append(f'{{ name: "{name}", svg: `{svg_full}` }}')

    items_array_str = ",\n".join(items_js)

    return f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="background: transparent; margin: 0; padding: 0;">
  <div id="results" style="display: none;"></div>
  <script>
    const items = [
      {items_array_str}
    ];

    async function renderAll() {{
      const output = {{}};
      const canvas = document.createElement('canvas');
      canvas.width = 128;
      canvas.height = 128;
      const ctx = canvas.getContext('2d');

      for (const item of items) {{
        ctx.clearRect(0, 0, 128, 128);
        const blob = new Blob([item.svg], {{ type: 'image/svg+xml;charset=utf-8' }});
        const url = URL.createObjectURL(blob);
        const img = new Image();
        
        await new Promise((resolve, reject) => {{
          img.onload = () => {{
            ctx.drawImage(img, 0, 0, 128, 128);
            URL.revokeObjectURL(url);
            output[item.name] = canvas.toDataURL('image/png');
            resolve();
          }};
          img.onerror = reject;
          img.src = url;
        }});
      }}

      const resDiv = document.getElementById('results');
      resDiv.textContent = JSON.stringify(output);
      resDiv.style.display = 'block';
    }}

    renderAll();
  </script>
</body>
</html>"""


def build_atlas_file(sprite_names):
    """Generates a valid Defold .atlas file referencing all sprites."""
    lines = []
    for name in sorted(sprite_names):
        lines.append("images {")
        lines.append(f'  image: "/assets/sprites/{name}.png"')
        lines.append("  sprite_trim_mode: SPRITE_TRIM_MODE_OFF")
        lines.append("}")

    lines.append("margin: 2")
    lines.append("extrude_borders: 2")
    lines.append("inner_padding: 0")
    lines.append("max_page_width: 0")
    lines.append("max_page_height: 0")
    lines.append('rename_patterns: ""')

    atlas_path = os.path.join(ATLAS_DIR, "game.atlas")
    with open(atlas_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated Defold atlas: {atlas_path}")


def main():
    print(f"Generating {len(SPRITES)} sprites for Lantern Grove...")

    html_content = generate_renderer_html()
    harness_path = os.path.join(PROJECT_ROOT, "tools", "render_harness.html")
    with open(harness_path, "w", encoding="utf-8") as f:
        f.write(html_content)

    harness_url = "file:///" + harness_path.replace("\\", "/")

    # Run Edge headless with dump-dom
    edge_exe = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    cmd = [
        edge_exe,
        "--headless",
        "--no-sandbox",
        "--dump-dom",
        harness_url
    ]

    res = subprocess.run(cmd, capture_output=True, text=True)

    # Extract JSON from results div
    match = re.search(r'<div id="results"[^>]*>(.*?)</div>', res.stdout, re.DOTALL)
    if not match:
        print("Failed to find results div in dump-dom output!")
        print("Stdout:", res.stdout[:500])
        return

    data_json_str = match.group(1).strip()
    data = json.loads(data_json_str)

    # Save each PNG
    for name, data_url in data.items():
        base64_data = re.sub(r"^data:image/png;base64,", "", data_url)
        png_bytes = base64.b64decode(base64_data)
        out_png = os.path.join(SPRITES_DIR, f"{name}.png")
        with open(out_png, "wb") as f:
            f.write(png_bytes)
        print(f"Saved: assets/sprites/{name}.png ({len(png_bytes)} bytes)")

    # Clean up harness
    if os.path.exists(harness_path):
        os.remove(harness_path)

    # Generate Defold .atlas
    build_atlas_file(data.keys())
    print("\nAll 23 sprites and Defold atlas generated successfully!")


if __name__ == "__main__":
    main()
