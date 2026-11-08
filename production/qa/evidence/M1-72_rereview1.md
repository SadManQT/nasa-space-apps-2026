# Task 13 / M1-72 fix round 1 re-review

What this change does: The fix gives each injected mouse/key press and release its own event object. Registry lookup now copies only selected clips, while keeping returned nested data isolated from the cache.

Scope: `d8243e4..9de251daf937a4c5b21e9b7946c2675abf999c1d`, exactly `game/scripts/ui/science_explainers.gd` and `game/tools/test_science_watch.gd`. Read the supplied fix diff once and the appended “Review fix round 1” and “Final executed commands and evidence” report sections. This supplements task-13-review.md; untouched source was not re-reviewed. No engine/test run, helper, index update, commit or HEAD change was performed.

## Verdict

- **Important 1: ADDRESSED.**
- **Minor 2: ADDRESSED.**
- **New breakage in the two-path fix: none found.**
- Findings addressed/open: **2 / 0**. Open C/I/M: **0 / 0 / 0**.
- **Source spec and quality verdict: PASS for source delivery.** The previous production spec/source PASS remains valid; this fix resolves both review findings. Corrected input and final native evidence are ready for the controller's source-delivery gate.
- **Task completion / final acceptance: PENDING**, subject to the gates below.

## Finding 1 — separate input event objects

`test_science_watch.gd` now constructs `InputEventMouseButton` and `InputEventKey` inside each press/release iteration. Each submitted event is distinct; key fields, pointer location, pressed values and flush behavior remain intact. The unsafe same-frame object reuse from the reviewed candidate is removed without changing production input handling.

Checked final evidence directly: SCIENCE WATCH 65 checks / 0 failures, SCIENCE DATA 206 / 0, JOURNAL TABS 281 / 0, HINT PLAYER 124 / 0; final native prints SCIENCE WATCH 79 / 0. An independent text scan of the four focused suite logs, their three setup logs and the final native log found **0** matches for WARNING:, SCRIPT ERROR, Parse Error or ERROR:. These are retained executed results, not tests rerun by this reviewer.

The final native manifest identifies source `9de251d`, game tree `ace451743058a1a535b31df8d42e248d234d0387`, capture interval `2026-11-08T15:52:28.5888821Z` to `2026-11-08T15:53:08.6403651Z`, and exit 0. Only original editor PID 22348 appears in the before/after inventories. Hashes of both fix files independently match the final native manifest. The supplied integrity summary records 11 PNG hashes/timestamps inside that interval and 8 unchanged loaded source/data hashes. Thus the earlier input warning is cleared by corrected source plus clean final execution evidence.

## Finding 2 — copy selected registry records

`science_explainers.gd` replaces public `entries()` with the internal `_registry()` accessor. `find()` returns `entry.duplicate(true)` for its selected record; `matching()` appends `entry.duplicate(true)` only for matches. The registry is still loaded once, no second cache is introduced, and nonmatching records/captions are no longer deep-copied on each lookup.

The prior task-scoped caller search established that entries() had only the two internal callers. A fix-round search of game scripts/tools found no remaining `Explainers.entries()`, `clips.entries()` or external `._registry()` call. Existing matching, deduplication, ordering and unknown-lookup branches are unchanged. Strengthened assertions mutate nested returned sources and nested returned captions, then check that subsequent selections remain unchanged; the final 65/0 run includes them.

The before/after profile JSON files use the same saved snapshot hash `8f8897ff0ec7fbb0133d50c1df8f5bf7f51ddfa315ca695d9cd83e7edbaecd52`; both report 0 integrity failures, unchanged snapshots and 18 late clips. Late Science median/p95 changes from 6.815/9.234 ms to 2.501/3.897 ms. Late Journal median/p95 changes from 31.055/34.147 ms to 26.445/29.228 ms, with its after maximum 46.817 ms retained. This supports the narrow copying improvement; it is not a rendered-FPS result, general timing-budget pass, physical campaign-completion witness or M1-68 fix.

## Unresolved acceptance gates

1. The expanded all-eight-chapter / 32-card player-text walk is still pending. Per the controller's explicit ruling, run it once inside the integrated full runner with the documented 1500-second watchdog. The prior changing-source 900-second run exited 124 with no final assertion count and is not passing evidence.
2. The current integrated `game/tools/run_tests.sh` result is still pending. Source-delivery approval and the clean 79/0 native run do not authorize marking M1-72 done. Existing global M1-68/M1-100 concerns are not cleared by this fix.
3. Physical controller use and a physical all-eight-chapter playthrough remain unchecked. Grouped-chapter screenshots remain the disclosed synthetic reached-snapshot witness. This re-review did not repeat the previous UI image inspection or any engine execution.

Verdict: both findings addressed; source-delivery gate can clear, final task acceptance remains pending.

Not checked: untouched source, new runtime execution or physical hardware playthrough.
Risk: do not mark M1-72 done before the actual integrated full/text results are recorded.
