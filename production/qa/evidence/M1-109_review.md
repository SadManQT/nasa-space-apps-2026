# Task 18 independent review — 5dff8e7..7ffabe8

What this change does: Main Menu removes unavailable Continue from keyboard focus, restores it when a checkpoint exists, and updates the saved button state during an open modal. CampaignPanels preserves a valid external focus owner established by its close signal.

## Findings

C: 0. I: 0. M: 0.

Looks good. Ship the reviewed source. The Settings close path calls Main Menu's `panel_closed` handler before CampaignPanels restores its old target; the new guard keeps Main Menu's valid fallback when that target has become disabled. The guard excludes hidden, disabled, and panel-owned controls. Other connected panel owners (campaign HUD and trainer) retain their existing valid-focus restoration paths.

The regression uses a saved and reloaded checkpoint that passes the production restore validator. At 100% and 150% text scale it exercises real Tab, Shift+Tab, and Enter events, availability changes during briefing, Science, and Settings, and unchanged save bytes. The mandatory runner results are menu 154/0, Worker C 572/0, and Hint Player 124/0. The frozen candidate's Forward+ capture reports 229/0 with no engine warnings or errors and 13 hashed PNGs; the parent visually checked enabled Continue and the unavailable skip at 150%. I reviewed source and reported evidence, and did not rerun tests.

Acceptance gap: the full/all-eight-suite gate remains pending. This source review does not mark M1-75 or M1-109 fully accepted.

Verdict: Ship the reviewed source; the full-suite gate remains pending.

Not checked: live playthrough, exports, and full-suite result.

Clarification: the deferred gate is the full integrated runner, including its all-eight-chapter player-text test; it is not a set of only eight suites.
