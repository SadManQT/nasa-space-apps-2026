# UI_Kit: the shared UI art and widget kit (M1-07), sheet for approval

Board task M1-07. **Status: approved and installed. Sadman, in chat on 6 Nov 2026 (about 10:58): "Approve, Space weather": [UI_Kit_sheet_v1.png](UI_Kit_sheet_v1.png) and the six decisions below as built, and Rafi's role word everywhere in the game is "Space weather".** No credits spent (the same kit at 150 % text: `production/qa/evidence/M1-07_ui_kit_sheet_150.png`). The sheet is a Godot capture of the real kit widgets, drawn at the 1080p type reference in a 1920-wide SubViewport (`game/tools/probe_ui_kit_sheet.gd`), so what is approved is what ships and a small laptop screen cannot crop it.

| Piece | Where | What it is |
|---|---|---|
| Icons | `game/assets/ui/kit/icons/*.svg` (39 files) | One line-icon set on a 24 px grid, 2 px round stroke, white, tinted by palette token at runtime. Written by [build_ui_kit.py](build_ui_kit.py), so every glyph is editable vector source. The SVG declares 48 px so Godot rasterises it at 2x. |
| Words | `game/resources/ui/ui_kit.json` | Every icon kind has its word (doc 25 §2.1: an icon always with a word), the four panel-state words, the meter level words (OK / Low / Critical), the source chips and the role markers. |
| Widgets | `game/scripts/ui/ui_kit.gd` (`UiKit`) | `icon`, `icon_label`, `meter`, `source_chip`, `role_marker`, `key_glyph`, `state_card`, `theme`, `contrast_ratio`. All built from the UiDesign tokens in `ui_design.json`. |
| Theme | `game/resources/ui/lla_theme.tres` | The Theme resource written from `UiKit.theme()` by `game/tools/build_ui_theme.gd`: buttons, labels, glass panels, progress bars, sliders, line edits, separators. |
| Existing screens | `UiDesign.LineIcon` | Now draws the kit SVG of its kind when one exists (the HUD, What now, Outpost Status), with the old code-drawn glyph as the fallback. |
| Text size | `UiDesign.apply_type` | Kit icons grow with the text beside them (24 px at 1080p and 100 %, 36 px at 150 %), so a larger text setting keeps icon and word in proportion. |

## Rules it keeps

- Palette from ART_BIBLE §3 and doc 25 §2.1: navy, ivory, muted, one mustard-gold accent, amber caution, red danger, green good; role colours Kai orange, Amara cyan, Mei green, Rafi purple, Ferreira steel-gold.
- No colour-only meaning: meters say their level in a word beside the bar; state cards say the state; chips carry the source word; role markers carry the name and the role word.
- English only, player words (the `test_ui_kit.gd` suite runs every kit word through the doc 25 §8.1 developer-language detector).
- Targets at least 44 px (buttons, key caps); contrast of every pair the kit uses at or above WCAG AA (checked by the suite); the sample reflows at 150 % text inside a 1280x720 safe area, icons scaling with it, and no label ever wraps one letter per line.
- No essential text baked into any texture: the SVGs are glyphs only.

## Decisions (all approved as built, 6 Nov 2026)

1. The glyph set and its words (sheet, top block).
2. Button states (rest navy, hover and pressed gold with ink text, focus outlined, disabled dimmed).
3. The four state cards and their words: "Nothing here yet", "Something went wrong", "Loading", "Not available now".
4. Meters: level words OK / Low / Critical at 50 % and 25 % of full (data in `ui_kit.json`).
5. Source chips: Earth link, Radio, Recording, Message (words from `ui_text.json`).
6. Role markers (dot, role icon, name, role word). Ferreira's role word is "Commander" (handbook §4); say if Chapter 1 screens should use another word. Rafi's is "Space weather" with the sun icon, the same as his Mission Table card (M1-09, `p02_mission_table.json`). **Decided:** "Space weather" is Rafi's role word on every game screen; handbook §4 now says so (in the story he still also carries safety and field operations).

To rebuild: `python3 production/concept/ui_kit/build_ui_kit.py`, then `godot --headless --path game --script res://tools/build_ui_theme.gd`, then the sheet with `production/qa/evidence/M1-07_capture.sh` (windowed). Both builds are deterministic: on 6 Nov 2026 they reproduced the 39 SVGs and `lla_theme.tres` byte for byte.
