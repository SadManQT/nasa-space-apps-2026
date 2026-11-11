# Classroom materials

Printable crew notes for **Class mode** (2–4 players on one machine). Each role's note is private: deal one card per role, read it privately, tell the crew what matters in your own words, then every role signs the team plan on screen before the operator locks it in.

- `role_cards/Last_Light_Academy_crew_notes.pdf` — cover sheet (how to play, seat plans for 2, 3 and 4 players, arrival shifts) plus one A5 landscape card per role: Kai (power and heat), Amara (atmosphere), Mei (horticulture), Rafi (safety).
- `role_cards/*.png` — the same five pages as images (1240 × 874 px, 150 dpi).

These files are **generated, never edited by hand**, from the same data the game reads:

```bash
python3 production/tools/build_role_cards.py
```

Sources: `game/resources/campaign/content/p02_mission_table.json` (the facts, quotes and arrival shifts the Mission Table shows) and `game/resources/campaign/content/crew_modes.json` (seat plans and every printed word). Change the data, rerun the script, and the cards, the on-screen hand-off and the printed sheet stay identical. Numbers are training units from `game-design/08_PUZZLE_DESIGNS.md`, not real measurements. No NASA logos; English only.
