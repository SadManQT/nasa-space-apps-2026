# Task 13 / M1-72 independent source and quality review

What this change does: Mission and fixture data cards gain Watch buttons for registered science clips. The Journal gains a Science tab that groups unlocked clips by reached chapter and uses the existing HintPlayer modal.

Reviewed candidate: `d8243e430fb9214ceebd50cd1640b24adc1e3bb7`, game tree `9d51548860c25a93f23e197de3c44fdbf25710ed`, against `889936e` (controller states its game tree equals original binding base `018b297`). Inputs were task-13-brief.md, task-13-preparation.md, the explicitly interim task-13-report.md, and the supplied full task diff. Production behavior was checked against the candidate source. The uncommitted test-input correction is outside this review package.

## Verdicts

- **Spec/source: PASS for the reviewed production implementation.** No production correctness or ownership blocker found in the scoped review. This is a source verdict, not verified final acceptance.
- **Quality: correct finding 1 before accepting this candidate's validation.** Finding 2 is a minor efficiency improvement; no measured timing failure is attributed to it.
- **Acceptance: PENDING.** The fresh frozen-source player-text walk, warning-free sequential native run, and current integrated full runner are not supplied as completed final evidence. Do not mark M1-72 done from this report.
- Counts: **C=0 / I=1 / M=1** (critical / important / minor). The important finding is in the test harness, not production runtime.

## Should fix

1. **Injected press and release reuse an unsafe input object** — Important. `game/tools/test_science_watch.gd:217`, `:220`, `:226`, `:229` (candidate lines).
   - **What this is:** `_click` and `_send_key` mutate one event object and submit it for both press and release in the same frame.
   - **Problem:** The preserved native log explicitly reports: “An input event object is being parsed more than once in the same frame, which is unsafe.” Its backtrace points to `_send_key:231`. The final-watch focused log has the same warning. These tests exercise keyboard activation, mouse activation, focus, close and blocked game input, so unsafe injection weakens the task-specific input evidence even though assertions print PASS.
   - **Fix:** Construct a distinct event for each press/release, as the implementer already plans, and retain clean focused/native results on that frozen correction. No production change is requested.
   - **If we skip it:** Input behavior is accepted on a harness path the engine itself calls unsafe. The correction is expressly pending and was not verified here.

## Nice to have

2. **Each registry lookup copies every clip and caption** — Minor. `game/scripts/ui/science_explainers.gd:12`, `:15`, `:25`; repeated caller `game/scripts/dialogue/knowledge_service.gd:207`.
   - **What this is:** `entries()` protects the cache by deep-copying all 19 registry records. Both `find()` and `matching()` call it, even for one selected clip or a mission with no new clips.
   - **Problem:** `_science_tab` invokes `matching()` once per reached mission. A late journal query with all 32 missions reached therefore copies 608 registry records plus their nested arrays before returning at most 18 deduplicated science entries. `chapter1_campaign.gd:197` builds this during normal campaign queries, including HUD refresh and forecast paths, not only when Science is opened.
   - **Fix:** Keep the read-only result contract, but iterate the internal cached records and duplicate only records actually returned. Preserve the existing cache-isolation test. Alternatively retain the current version if measured cached early/late query cost is acceptable; no new catalog layer is needed.
   - **If we skip it:** Queries retain unnecessary copying. This review did not measure its duration and does not claim it causes existing performance failures or misses a runtime budget. The HUD's target/revision cache avoids making every physics-frame forecast a full campaign query.

## Binding requirement and source checks

- **Card matching and real integration:** `CampaignPanels._render_sources` obtains the current mission's actual `ScienceData.mission_card`, creates the Mission data card route, and `_render_card` delegates only an explicit mission route to `_render_mission_card`. Mission matching passes that mission ID and its own source IDs; fixture matching passes only the fixture ID. The ambient mission is not attached to unrelated fixtures. The registry and EX-M0101 card data support the three requested clips: crew needs, polar Sun and solar power. Selection order follows registry order and duplicate clip IDs are suppressed.
- **Honest existing source display:** The original fixture path retains the measured data, computation, caveat, licence and exact source credit blocks. The new mission route presents the existing card's title, plain explanation, Aurora meaning, decision, chart, evidence, limits and verbatim source lines, with access to full source records. No replacement simulator or campaign state is introduced.
- **Shared player:** `HintPlayer.watch` checks for a registered science entry, sets presentation-only watch state, clears first-time teaching persistence, and uses `_begin` / `_render_media`. It does not change `_levels`. Watch renders no next-hint or back-to-How-to controls. Existing 16:9 aspect, pause/replay, missing-media fallback, reduced-motion decode/still/transcript, focus trap and close path are reused. Requesting a later hint still derives its level from the existing per-context `_levels` store.
- **Journal reach/gating:** `_science_tab` walks canonical content scenes and accepts only `_scene_allowed` current/completed/acquired reach. It derives the actual mission and that mission card's puzzle reference, uses `used_by` matching without source overlap, and deduplicates by clip ID. Unknown IDs or a claimed snapshot mission alone cannot unlock a clip. First reached canonical chapter owns a shared clip. Current data has 18 mission/puzzle-linked clips and one trainer/EVA-only clip; the latter is correctly outside this agreed unlock path.
- **Existing Journal contract:** The four old tab implementations remain, Science is appended, and aggregate entries/counts include generated science entries with an allowed scene ID. The changed custom-pack tests inspect their authored Evidence fixtures directly while retaining hidden-link/gate checks. Five-tab focus wrap and target checks are updated. Existing full-chapter spoiler assertions still examine aggregate entries. The wider People/concept Journal work remains outside the brief.
- **Modal pause and focus:** CampaignPanels uses the existing HintPlayer opened/closed signals to hide and restore the underlying reader. `HintPlayer.close` restores its saved visible control after the underlying panel has returned. The unchanged HUD pause union checks active reader, Mission Table and HintPlayer, preserving pause when Watch closes onto a card or Science tab. The campaign's input guard and paused target path remain authoritative. No movement/dialogue/receipt mutation is added by Watch.
- **House UI and numeric words:** New widgets use existing `_button`, `_card_text`, section and UiDesign helpers. No new font/color tokens or generated assets are added. The approved ui_text scope preserves shielding level 6 and local/Earth bearings 2/3. Those numbers match the P-14/P-16 numeric contract at `game-design/08_PUZZLE_DESIGNS.md:195`, `:238`–`:240`; no numeric rule changes are present.
- **Ownership:** Ramim's team card lists UI, knowledge_service.gd and ui_text.json as owned. Tests are within the task's explicit permission. The supplied ten-path candidate contains no imported asset metadata, core/mission/science runtime, registry/media, project/editor, handbook or original-checkout ignore changes. No owner request was needed for the source reviewed.

## Named external checks and limits

This was task-scoped, read-only source review plus this requested report artifact. No engine, tests, helper agents, index updates, commits or HEAD mutations were performed.

- For the **real-card route and source-credit risk**, checked only `science_data.gd`'s mission-card/source interfaces and the existing EX-M0101 mission record.
- For the **hidden information and chapter grouping risk**, checked canonical content access in knowledge_service.gd and the registry's 19 titles/used_by associations; none of those clip titles introduces the hidden gardener identity. Scene reach and existing `_context`/`_scene_allowed` contracts were traced directly.
- For the **nested modal/movement risk**, checked `chapter1_campaign_hud.gd`'s modal signal connections and `_on_panel_opened`/`_on_panel_closed`, plus `chapter1_campaign.gd`'s pause and input guards.
- For the **query-copy risk**, checked `chapter1_campaign.gd:190`–`:198`, HUD query refresh/accessibility/forecast call sites, and its target/revision cache. No broad runtime audit was attempted.
- For the **plain preset risk**, checked UiDesign's whole-word conversion/capital preservation and the named numeric contract lines. Source fixture data is treated as authored internal data, not a new external trust boundary.
- Checked focused log tails directly: SCIENCE WATCH 64/0, JOURNAL TABS 281/0, HINT PLAYER 124/0, SCIENCE DATA 206/0. These are retained prior runs, not reruns by this reviewer; the Watch log includes finding 1's warning.
- Read the initial native run manifest/fingerprints and explicit native result 78/0. Independently viewed `M1-72_native_initial/M1-72_mission_card_150.png`, `M1-72_still_150.png` and `M1-72_journal_chapters_end_150.png`. The three required card buttons, real still/transcript and reached-chapter list are readable with reachable Close controls. These images remain intermediate evidence because the native attempt overlapped another job; chapter grouping screenshots use the disclosed synthetic reached snapshot.

## Cannot verify / acceptance gates

1. The test-input correction and its final commit/fingerprint are not in this candidate package.
2. A clean sequential final native run on frozen final source has not been supplied. Initial 78/0 and inspected images do not replace it.
3. The fresh frozen-source player-text walk with the documented 900-second watchdog has not been supplied as complete. Earlier changing-source/overlapping walks cannot establish final all-chapter text acceptance.
4. Current integrated `game/tools/run_tests.sh` PASS is pending. Existing M1-68/M1-100 concerns are reported controller context, not independently diagnosed or cleared here. No task-done claim is authorized.
5. Cached early/late query timing is unmeasured here. Finding 2 is an allocation/copy observation, not a performance root-cause conclusion.
6. No physical controller test or full physical eight-chapter playthrough was performed. Injected events and synthetic grouped snapshots have the explicit limits above.

Verdict: fix 1 and finish the pending final acceptance gates. Production source has no blocking finding from this review.

Not checked: final frozen runtime/text/integrated evidence and hardware playthrough; no test was rerun.
Risk: M1-72 must remain pending until the clean final validation and integrated full gate are recorded.
