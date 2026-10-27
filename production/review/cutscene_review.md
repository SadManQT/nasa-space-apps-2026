# Cutscene review

Every shot in [shots.csv](../cutscenes/shots.csv) is checked twice: by Claude against the checklist in the handbook (section 6, cutscene step 2), then by Codex (gpt-6-astra, high effort). A Codex FIX is accepted only when a full-resolution crop confirms it.

On 26 Oct Codex audited all 23 shots against a stricter checklist (flag on every left sleeve, mission patch design, Ferreira's hair, readable text). It found real problems the per-shot reviews had missed; the confirmed ones were fixed the same day.

## Verdicts

| Shot | Claude | Codex | Fixes made |
|---|---|---|---|
| CS-01-A | PASS | PASS (audit: MINOR) | |
| CS-01-B | PASS | FIX rejected twice | Ferreira's sheet used as reference so her hair stays dark |
| CS-02-A | PASS | FIX accepted (audit) | Horizon glow graded to black in post: `tools/clear_stars.py --grade-sky 0.45` |
| CS-02-B | PASS | PASS | Other take picked (first had stars over sunlit ground) |
| CS-03-A | PASS | PASS | Regenerated (desert window, flower already open) |
| CS-03-B | PASS | PASS | Regenerated with Rafi, recorder edited to match PR_Recorder2034 |
| CS-04-A | PASS | PASS | |
| CS-05-A | PASS (v2) | FIX accepted (audit); PASS (v2) | Frame mirrored (flags were on the right); v2: star chest badges replaced with the mustard-flower patch |
| CS-06-A | PASS | PASS | |
| CS-07-A | PASS (v3) | FIX accepted in part (audit); PASS (v3) | v2: adult scale, no light beams; v3: star chest badges replaced. Codex's "light cones" claim rejected (only lamp glare and the lit ground) |
| CS-08-A | PASS | PASS | |
| CS-08-B | PASS | FIX rejected (audit) | Hair is dark, greying at the temples |
| CS-09-A | PASS (v2) | FIX accepted (audit); PASS (v2) | Ferreira's grey hair made jet-black with grey temples; locker plates blanked |
| CS-10-A | PASS (v2) | FIX rejected (v1), FIX accepted (audit); PASS (v2) | Same hair and locker fix on both start and end frames |
| CS-11-A | PASS | MINOR (audit) | |
| CS-12-A | PASS (v2) | FIX accepted (audit); PASS (v2) | Star chest badge replaced with the mustard-flower patch |
| CS-13-A | PASS (v3) | FIX accepted (audit); PASS (v3) | v2: name tag blanked; v3: lettered patches on Mei's sleeve removed |
| CS-14-A | PASS | PASS | |
| CS-15-A | PASS | PASS | Shawl added to Noor |
| CS-15-B | PASS (v2) | PASS | Kai's gold tabs, Ferreira's grey hair, readable name tag and Rafi's orange tabs fixed by edits |
| CS-16-A | PASS (v3) | PASS (v3) | Billowing wheel dust cleaned from the start frame, re-animated with a "crisp tread tracks, clear ground" prompt |
| CS-17-A | PASS (v2) | PASS (v2) | Golden sky edited to black; stars removed in post with `tools/clear_stars.py --rows 0.62` |
| CS-17-B | PASS (v4) | PASS (v4) | Golden sky, grey hair, wrong suits, readable name tags fixed; Kai and Amara given their missing flag patches |

The re-renders made after the audit (CS-05-A v2, CS-07-A v3, CS-09-A v2, CS-10-A v2, CS-12-A v2, CS-13-A v3) were re-checked by Codex later on 26 Oct, on strips plus a full-resolution frame each: all six PASS.

## Rejected Codex claims

- **CS-01-B:** Codex first read the commander on the screen as Rao, then said her hair was grey across the crown. It is Ferreira, dark-haired with grey temples; the wing emblem is on her Earth duty coverall, which the art bible allows.
- **CS-08-B:** "hair grey across the head". Close-up shows dark hair greying at the temples.
- **CS-10-A (v1):** Codex said Rao wears no headset. The full-resolution crop shows the headset.
- **CS-07-A:** "visible light cones in vacuum". Only the lamps' own glare and the lit ground show.

## Polish backlog (no rule broken, worth fixing before release)

- **CS-01-B:** lip-sync once Ferreira's line is voiced.
- **In-world screens and labels with pseudo-text:** CS-01-A wall label, CS-02-B console button labels and star-chart table. These are illegible AI glyphs, found by an OCR sweep of 3 frames per shot (macOS Vision). Plan: composite real UI art onto screens in post, or render them from the game's UI once it exists.
- **Ferreira's older engineering patch** (left sleeve, below the flag) has an illustrated picture that varies a little between shots; CS-13-A v3 also gives Mei an illustrated lander patch on the right shoulder. Neither has readable text. A fixed patch design in the character sheets would make them consistent.
- **CS-11-A and CS-17-A:** one or two faint star-like specks remain, visible only when brightened.
