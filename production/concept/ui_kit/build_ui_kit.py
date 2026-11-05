#!/usr/bin/env python3
"""Write the UI_Kit line-icon set as editable SVG files (M1-07; no AI generation, no credits).

  python3 production/concept/ui_kit/build_ui_kit.py          # writes game/assets/ui/kit/icons/<kind>.svg

One line-icon set at 24 px (doc 25 §2.1): every glyph is drawn on a 24 x 24 grid with a 2 px round stroke in
white, so the runtime tints it with a palette token (UiDesign.colour) and the same file serves accent, muted,
caution and danger uses. The SVG declares a 48 x 48 size so Godot rasterises it at 2x for sharp 24 px icons on
high-DPI screens. Every kind has a word in game/resources/ui/ui_kit.json: an icon never appears without one.

The glyphs mirror the ten shapes UiDesign.LineIcon already drew in code (power, life, water, shielding,
radiation, plant, food, goal, message, place), so screens built before the kit do not change their meaning,
and add the kinds the journal, settings, Mission Table, source chips and state cards need.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "game", "assets", "ui", "kit", "icons")

# Each icon: a list of SVG elements (path d strings, or ("circle", cx, cy, r), ("rect", x, y, w, h, rx)).
# Coordinates are on the 24 px grid; strokes are 2 px, so keep 2 px inside the edge (range 2..22).
ICONS = {
    # the ten legacy LineIcon shapes (same silhouettes as the code-drawn glyphs)
    "power": ["M3 7h15v10H3z", "M20 10v4", "M7 12h7"],
    "life": ["M3 6h18", "M3 12h18", "M3 18h18"],
    "water": ["M12 3 5 13l2 7h10l2-7z"],
    "shielding": ["M3 3h18l-1 12-8 7-8-7z"],
    "radiation": [("circle", 12, 12, 8), ("circle", 12, 12, 1.6), "M12 16v4", "M8.5 10 5 8", "M15.5 10 19 8"],
    "plant": ["M12 21V8", "M12 12c-4 0-6-2-6-6 4 0 6 2 6 6z", "M12 16c4 0 6-2 6-6-4 0-6 2-6 6z"],
    "food": ["M3 11a9 9 0 0 1 18 0", "M3 11h18", "M12 11v11"],
    "goal": ["M12 2l10 10-10 10L2 12z", ("circle", 12, 12, 2.5)],
    "message": [("rect", 3, 5, 18, 13, 1.5), "M3 5l9 8 9-8"],
    "place": [("circle", 12, 10, 6), "M12 16v6"],
    # navigation, panels and keys
    "journal": [("rect", 4, 3, 16, 18, 1.5), "M8 8h8", "M8 12h8", "M8 16h5"],
    "settings": [("circle", 12, 12, 3), "M12 2v3", "M12 19v3", "M2 12h3", "M19 12h3", "M4.9 4.9l2.1 2.1", "M17 17l2.1 2.1", "M19.1 4.9 17 7", "M7 17l-2.1 2.1"],
    "save": ["M4 4h13l3 3v13H4z", "M8 4v5h7V4", "M7 20v-6h10v6"],
    "pause": ["M8 4v16", "M16 4v16"],
    "what_now": [("circle", 12, 12, 9), "M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.3-1 .8-1 1.7", ("circle", 12, 17, 0.6)],
    "info": [("circle", 12, 12, 9), "M12 11v6", ("circle", 12, 8, 0.6)],
    "check": ["M4 12l5 5L20 6"],
    "close": ["M6 6l12 12", "M18 6 6 18"],
    "warning": ["M12 3 2 20h20z", "M12 9v5", ("circle", 12, 17, 0.6)],
    "clock": [("circle", 12, 12, 9), "M12 7v5l3 2"],
    "arrow_right": ["M4 12h15", "M13 6l6 6-6 6"],
    "lock": [("rect", 5, 11, 14, 10, 1.5), "M8 11V7a4 4 0 0 1 8 0v4"],
    "key": [("rect", 3, 6, 18, 12, 2), "M8 12h.01", "M12 12h.01", "M16 12h.01"],
    # sources (the dialogue origin chips) and people
    "earth_link": [("circle", 12, 12, 9), "M3 12h18", "M12 3c3 3 3 15 0 18", "M12 3c-3 3-3 15 0 18"],
    "radio": ["M12 20V9", ("circle", 12, 7, 2), "M7 12a7 7 0 0 1 0-10", "M17 12a7 7 0 0 0 0-10"],
    "recording": [("circle", 12, 12, 9), ("circle", 12, 12, 3.5)],
    "text_message": ["M4 4h16v11H9l-5 4z", "M8 8h8", "M8 11h5"],
    "people": [("circle", 9, 8, 3.5), "M3 20c0-3.5 2.7-6 6-6s6 2.5 6 6", ("circle", 17, 9, 2.5), "M15.5 14.5c2.8.3 5 2.6 5 5.5"],
    "person": [("circle", 12, 8, 4), "M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"],
    # station and mission resources (Mission Table role cards use battery, tank, sun, leaf)
    "battery": [("rect", 2, 7, 17, 10, 1.5), "M21 10v4", "M6 11v2", "M10 11v2"],
    "tank": [("rect", 6, 4, 12, 17, 3), "M9 4V2h6v2", "M6 10h12"],
    "sun": [("circle", 12, 12, 4), "M12 2v3", "M12 19v3", "M2 12h3", "M19 12h3", "M4.9 4.9l2.1 2.1", "M17 17l2.1 2.1", "M19.1 4.9 17 7", "M7 17l-2.1 2.1"],
    "leaf": ["M20 4c-9 0-15 5-15 13 0 1 .2 2 .5 3C9 15 13 11 18 9c-4 3-7 7-9 12 8 0 12-7 11-17z"],
    "heat": ["M12 3a3 3 0 0 0-3 3v7.5a4.5 4.5 0 1 0 6 0V6a3 3 0 0 0-3-3z", "M12 10v7"],
    "light": [("circle", 12, 10, 5), "M9 19h6", "M10 22h4", "M12 2v1", "M4 10H3", "M21 10h-1", "M6 4l.7.7", "M18 4l-.7.7"],
    "seed": ["M12 3c5 0 8 4 8 9s-3 9-8 9-8-4-8-9 3-9 8-9z", "M12 8v8"],
    "rover": ["M3 13l2-5h9l5 5h2v4h-2", "M5 17H3v-4", ("circle", 7, 17, 2), ("circle", 17, 17, 2), "M9 17h6"],
    "route": [("circle", 5, 19, 2), ("circle", 19, 5, 2), "M7 19h6a3 3 0 0 0 0-6h-3a3 3 0 0 1 0-6h7"],
    "moon": ["M20 14.5A8 8 0 1 1 9.5 4 6.5 6.5 0 0 0 20 14.5z"],
}


def element(e):
    if isinstance(e, str):
        return f'<path d="{e}"/>'
    if e[0] == "circle":
        _, cx, cy, r = e
        return f'<circle cx="{cx}" cy="{cy}" r="{r}"/>'
    if e[0] == "rect":
        _, x, y, w, h, rx = e
        return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"/>'
    raise ValueError(e)


def svg(kind, elements):
    body = "".join(element(e) for e in elements)
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" '
            'stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
            f'<title>{kind}</title>{body}</svg>\n')


def main():
    os.makedirs(OUT, exist_ok=True)
    for kind, elements in ICONS.items():
        with open(os.path.join(OUT, kind + ".svg"), "w", encoding="utf-8") as f:
            f.write(svg(kind, elements))
    print(f"wrote {len(ICONS)} icons to {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
