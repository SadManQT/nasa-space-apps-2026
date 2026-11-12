# UI direction: "Instrument Light" (12 Nov 2026, Sadman/claude, takes over M4-22 from Ramim)

User brief (12 Nov): make every screen more attractive, professional and minimal; icons rather than big text;
fit the game's goal (a Moon-base science story that teaches all ages) and theme; the 15 `ui_proposal/` sheets
are references only.

## What the research says (sources in the session log)

- Diegetic or near-diegetic UI keeps players in the world: Dead Space (health on the suit), Firewatch (map and
  radio as objects), Subnautica (the PDA is a held device), Astroneer (almost no overlay: oxygen on the backpack,
  power as yellow flow, red = interactive, sound confirms actions).
- Show information when it matters, hide it when it doesn't (Death Stranding's context HUD): stats appear when they
  change or turn dangerous.
- Shape over text: a ring or bar is read faster than a number; keep exact numbers for when precision matters.
- Colour never carries meaning alone: pair it with an icon or shape (colour-blind and young players).
- For young players: literal icons, large targets (44 px at 1080p minimum here), familiar patterns, few choices
  per screen, positive feedback, no dead ends.
- Cozy/learning games (Terra Nil, Alba, Mini Motorways) read well through a calm palette, simple shapes and one
  accent colour.

## Principles for Last Light Academy

1. **Light is the accent.** The game is about scarce sunlight: warm sun-gold marks the one thing to do now (the
   primary button, the goal marker, the selected tab). Everything else stays quiet navy glass.
2. **One meaning per colour, always with an icon:** gold = act now / sunlight, teal = measured data and "simulated"
   previews, leaf green = living plants and success, coral = danger. Radiation and warnings keep their icon.
3. **Icon first, word second, sentence on demand.** Buttons are icon + one or two words; explanations live behind
   What now (H), the journal, or a "Why?" fold. No sentence-long buttons.
4. **Show it when it changes.** Station vitals are compact icon gauges; their labels and numbers expand only when a
   value changes, turns low, or the player opens What now.
5. **One shell for every panel:** icon + title on one line, close (×) top right, content, one action bar bottom right
   with exactly one gold primary. No repeated logo header inside panels; the brand lives on the title screen.
6. **Three text sizes only** (title, body, label in small caps); Barlow Semi Condensed headings, Roboto body.
7. **Respect what exists:** every command, preview/confirm step, accessibility option (150% text, reduced motion,
   high contrast, captions, timer-free) and keyboard/controller focus keeps working; tests stay green.

## Screen plan

| Screen | Change |
|---|---|
| Shared kit (UiDesign/UiKit/theme) | New tokens; icon buttons; primary/secondary/ghost buttons with icons; switch and segmented controls; panel shell with header + close; key-glyph chips |
| HUD | Objective chip (◇ icon, short goal, distance); vitals as icon gauges that expand on change; one toast line under the chip (no duplicate goal); subtitle-style dialogue with speaker colour and a small Space glyph |
| Pause | Icon tile grid; Resume as the gold primary |
| Settings | Icon tabs; rows of label + switch/segmented control; live reading preview |
| Title | Keep the cinematic art; clean left menu; Continue disabled with a small note when there is no save |
| Mission Table, calibration, garden, journal, messages, chapters, trainers | The shared shell; fix layout bugs (vertical brand text, caption over buttons, cropped image); trim headers and helper sentences |

Done when: every screen captured at 1280x720 and 150% text, looked at, and the full `run_tests.sh` passes.
