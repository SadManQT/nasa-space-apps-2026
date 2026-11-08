# M1-75 independent closeout review

**Candidate:** `993df85..c33c199` (three paths). **Scope:** read-only source/spec and quality review of `main_menu.gd`, `test_main_menu_contrast.gd`, and its UID. No engine run or source/git mutation was performed for this review.

## Verdict

**Source/spec: pass. Quality: pass. Final acceptance: pending.** Counts: **C0 / I0 / M0** (critical / important / minor findings in the reviewed diff). I found no source-blocking finding for a reviewed WIP delivery. This is not a claim that M1-75 has completed its full acceptance gate.

## What the change does

The shared `_button` factory overrides focused text to `INK` only for the two mustard primary actions and makes the focus style transparent with a visible 2 px border. This leaves normal, hover, and pressed fills in charge of their own backgrounds and leaves secondary buttons' inherited light focus text on their dark normal fill. The briefing now follows the existing science panel pattern: title and actions stay fixed while its body scrolls.

## Checks against the brief and connected code

- Both primary callers (`NEW EXPEDITION`, `ENTER AURORA`) pass `MUSTARD` and `INK`; the remaining factory callers have dark normal fills. `lla_theme.tres` supplies light inherited focus text for the latter. No focus-order, save-state, command, palette, font, or foreign-folder source change appears in the three-path diff.
- The regression uses actual key events for Tab, Shift+Tab, Enter, and Escape at 100% and 150%; checks briefing focus, one launch, restored title focus, and full action-rectangle enclosure. It checks actual hover/pressed draw modes, state and native pixel contrast, visible transparent focus borders, and a scrolled body with an unchanged action rectangle. This is meaningful coverage for the new behavior.
- I inspected the 150% title, briefing, and secondary focused PNGs. The primary text and outlines are readable; the entire Enter Aurora button is on screen. The retained native Compatibility log reports **146 checks / 0 failures**, with the corrected clear-fill probe, minimum reported primary ratio **9.26:1**, and the briefing action at **y=553..601**. The manifest identifies source `c33c199`, the input hashes, and nine PNGs. This review did not rerun or independently hash those artifacts.
- The recovery report records focused runner results of contrast **83/0**, worker content **572/0**, UI kit **522/0**, and Chapter 1 UI **41/0**. Those are reported evidence, not new runs in this review.

## Acceptance gaps and observations

- The required integrated `game/tools/run_tests.sh` pass and all eight acceptance walkthroughs remain pending by explicit user deferral. Keep the board task in progress until those finish; a safe source push can describe it as reviewed WIP.
- Compatibility emits one project TAA/Forward+ warning; this diff does not touch project rendering settings. The Chapter 1 UI focused run reports three ObjectDB leak warnings, with cause not established. Neither is attributed to this change here.
- The Tab probe observes disabled Continue receiving focus (`FOCUS_ALL`). That is an existing navigation issue outside this diff and owner-approved scope; file separate follow-up work if needed. It does not explain a regression in the reviewed source.

**Not checked:** Integrated runner, all eight walkthroughs, other renderers or viewport sizes, and independent artifact hash verification. Risk: final acceptance may reveal an unrelated integration or navigation issue.

Controller clarification: references to eight walkthroughs mean the expanded all-eight-chapter player-text test within the integrated runner. No physical eight-chapter playthrough is claimed or newly required by this task.
