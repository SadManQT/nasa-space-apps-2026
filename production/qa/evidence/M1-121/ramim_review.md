# Ramim saved branch audit

Base: main 5f6f1df9. Scope: nine local Ramim pointers and thirteen reserved night pointers, including ancestors and stale chapter pointers. Divergent tips were inspected against merge base and connected main code; duplicate SHAs are named.

## Clip blockers and reuse

- Mission Table/P01: main has MissionTablePanel and P01Panel signal-to-campaign wiring. Saved 948ef2f was semantically replayed through f126974, e5d518c, 9da76ea and 46398b4. The old night/M1-08 route erases private Director receipts; do not port it. Current P01 uses p01_view, forecast_target and perform_target with explicit choices. M1-95 and M1-115 are separate route/label blockers. This audit gives no native clip pass.
- Messages: no scoped ref adds an inbox, arrival toast, unlock service, validator or message UI source. Main has ch01 and ch05-ch08 prose packs plus CampaignDirector.update_message_metadata({delivered_ids,read_ids}) and message_metadata(). The bounded API allows pause-time updates, requires delivery before read and preserves gameplay revision/checkpoint. M1-56 remains todo; implement on that API and current CampaignKnowledge/CampaignPanels.
- Later puzzles: M1-104 delivered current P03/P04 data. Saved M3-2P needs M1-105 chosen-input dispatch. M3-3P collides with the M3-2P ScientificPuzzlePanel class/scene and API. M3-8P needs an Atik route API. M1-37 needs M1-103 and its saved setter is unsafe.

## All ref decisions

| Ref | SHA | Classification | Finding and action |
|---|---|---|---|
| refs/heads/ramim/atik-label-20261109 | 5f6f1df9 | ancestor integrated | Ancestor with no branch-only files; historical board block or current main pointer. No port; use main. |
| refs/heads/ramim/continue-20261106 | afe0c747 | superseded semantic port | afe0c747 P01 draft; panel scene is byte-identical in main and later current panel/HUD supersede it. Use current P01. |
| refs/heads/ramim/continue-20261108 | 948ef2f0 | superseded semantic port | 948ef2f controller and prediction candidate; HUD/scene blobs byte-identical in main, panel/test revised by e5d518c, 9da76ea and 46398b4. Use current P01. |
| refs/heads/ramim/m108-await-runtime-20261108 | afe0c747 | superseded semantic port | Alias of afe0c747. No separate port. |
| refs/heads/ramim/m108-ui-review-20261109 | 948ef2f0 | superseded semantic port | Alias of 948ef2f. No separate port. |
| refs/heads/ramim/m170-full-20261108 | defddc9f | superseded semantic port | M1-70 credits ported by d956fa8; science test blob exact; old captures historical. Use main credits. |
| refs/heads/ramim/m172-postpull-validated-20261108 | 7ff8f61e | superseded semantic port | M1-72 Watch/Journal ported by e04ba9a; knowledge, hint, explainer and focused watch test blobs exact. Use main Watch. |
| refs/heads/ramim/m172-validated-20261108 | 0fbfeac5 | superseded semantic port | Earlier M1-72 pointer with same substantive Watch code. No separate port. |
| refs/heads/ramim/m175-validated-20261109 | c33c1991 | superseded semantic port | M1-75 contrast sampling ported as 4a101db; menu/test subsequently revised by 17876bf and 7ffabe8. Use main contrast test. |
| refs/remotes/origin/night/M1-08 | 1f01baaa | blocked unsafe owner-spanning WIP | Old 988-line P01 panel and 601-line workbench hold zero/span/cassette choices; apply_canonical_setup prefills correct fixture values. Route reset erases private _director._state receipts. Current P01 uses p01_view/forecast_target/perform_target explicit payloads. Use only UI ideas, never cherry-pick route. |
| refs/remotes/origin/night/M1-18 | 29877b8f | metadata-only | Only BOARD.html and tasks.json status/owner edits; no UI code. Build from current UI and player evidence. |
| refs/remotes/origin/night/M1-19 | 8a253dd7 | ancestor integrated | Ancestor with no branch-only files; historical board block or current main pointer. No port; use main. |
| refs/remotes/origin/night/M1-19-saved | 3f67b011 | superseded semantic port | Old standalone outcome/debrief scene and route; current main has replay/debrief in CampaignPanels and scripts/debrief via ce1fe28 and 52fb20d. Use main debrief; acceptance still separate. |
| refs/remotes/origin/night/M1-29 | a1e0a6ce | ancestor integrated | Ancestor with no branch-only files; historical board block or current main pointer. No port; use main. |
| refs/remotes/origin/night/M1-37 | 8a792c11 | blocked unsafe owner-spanning WIP | Class handoff, P02 read/share/sign-off and printable cards. Saved main.gd declares var crew twice in one function; set_crew uses restore_snapshot and risks checkpoint replacement. M1-102 landed; M1-103 todo. Port owned UI after bridge, never setter. |
| refs/remotes/origin/night/M3-2P | 5203a6fb | blocked unsafe owner-spanning WIP | Saved P03/P04 panel uses open(route,target,settings), commit_requested(target,payload), rich models. Current M1-104 data exists but route lacks saved puzzle_view/p03/p04 and chosen-input dispatch; M1-105 todo. Port owned panel/model against published dispatch. |
| refs/remotes/origin/night/M3-3P | 704baf3f | blocked unsafe owner-spanning WIP | Saved P05/P06 JSON/models and another ScientificPuzzlePanel with panel_closed and different open return/signature; route/ledger changes absent on main. Define common panel contract first. |
| refs/remotes/origin/night/M3-4P | f815b1a1 | ancestor integrated | Ancestor with no branch-only files; historical board block or current main pointer. No port; use main. |
| refs/remotes/origin/night/M3-5P | 3a1112e9 | ancestor integrated | Ancestor with no branch-only files; historical board block or current main pointer. No port; use main. |
| refs/remotes/origin/night/M3-6P | d04968d2 | ancestor integrated | Ancestor with no branch-only files; historical board block or current main pointer. No port; use main. |
| refs/remotes/origin/night/M3-7P | d503b42e | ancestor integrated | Ancestor with no branch-only files; historical board block or current main pointer. No port; use main. |
| refs/remotes/origin/night/M3-8P | 9a83b682 | blocked unsafe owner-spanning WIP | Saved P15/P16 Chapter8 panel/model/data/rules, but chapter8_view/preview and dispatch absent on main. Saved preview clones Director/route while paused; integration needs current revision/checkpoint semantics. Establish owner API then port owned UI/model/data. |

## Verification limits

No engine, tests or binary rendering were run. PNG/PDF sheets and old QA logs are provenance, not current runtime evidence. The existing Godot .import churn was untouched. No source, board, HEAD or ref changed. The JSON companion lists reusable paths and blockers per ref.
