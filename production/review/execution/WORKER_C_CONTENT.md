# Worker C content and presentation handoff

**Task / owner:** Worker C — content, dialogue, UI presentation, audio/cutscene metadata
**Date:** 3 November 2026
**Source HEAD:** `5f94bc0e8e6ffc49aea5a2ae36570b13d0bfc4c1` (inherited; this follow-up remains uncommitted)
**Commit/push:** none

## Goal and ownership

Imported the final canonical story package into an engine-readable campaign
catalog, added the frozen content/dialogue lookup API, kept the existing
three-scene commissioning loader path intact, and added read-only presentation
services/panels. No Worker A systems file, Worker B world/mission file,
`project.godot`, `main.gd`, installed GLB/OGV/portrait, or paid/AI asset tool
was changed.

The owned presentation surface also includes `game/resources/ui/lla_theme.tres`,
the shared Godot Theme consumed by the menu, HUD and campaign panels.

## Canonical inputs and revisions

| Input | SHA-256 | Structural result |
|---|---|---|
| `full-game-story/story-data.json` | `02fa2dee03d11d455f67406de28a4da3cee97b1f8f19fda2cee0e6c1e895a272` | 8 chapters, 32 missions, 96 scenes, 385 story lines |
| `production/manifest/scene_index.csv` | `8c0b8cda424d6bc6abb32ef64fd090c9afca53a0eedf16dee74e84dc4d51a934` | 96 manifest rows, legacy IDs retained as provenance |
| `production/audio/vo_lines.csv` | `d4d1aaae60f13504477462bca5141c4fa3343057760b3f199f82bb8509404a19` | 385 rows; every ID and text matches story data |

Generated content revision: `campaign-content-1-3e003a55fa46e38f`
Campaign catalog hash: `31a768ef49efa7a9f5c1c97a581a66c0b5c731938bb3191a67fe56ecc7bf18c4`
Dialogue catalog hash: `a3410ee72ab2e1e9349d6fdc66d312c15937646d7a25de9f87362d9d558addd2`

## Files created or changed

- `game/scripts/content/build_catalog.py` — deterministic importer from the
  three canonical sources.
- `game/resources/campaign/content/campaign_catalog.json` — full normalized
  catalog: chapter/mission/scene order, exact dialogue, stable IDs, speaker
  identities, delivery/origin labels, actions, choice, learning, exit,
  evidence and source references.
- `game/resources/campaign/dialogue_catalog.json` — exact 385-line dialogue
  catalog, speaker registry, origin labels and acknowledgement contract.
- `game/scripts/content/content_loader.gd` — `CampaignContentFull` API and
  compatibility slice methods.
- `game/scripts/dialogue/dialogue_service.gd` — exact captions, origin labels,
  knowledge gating and dialogue-only acknowledgement commands.
- `game/resources/campaign/content/presentation_media.json` — truthful media
  inventory: the three installed OGVs, explicit not-installed CS-04..CS-18,
  and captions-only audio fallback.
- `game/scripts/audio/audio_runtime.gd` — runtime voice availability and
  captions-only fallback metadata.
- `game/scripts/cutscenes/cutscene_runtime.gd` — OGV/text fallback plans and
  skip receipts that cannot complete predicates.
- `game/scripts/ui/campaign_panels.gd` and
  `game/scenes/ui/campaign_panels.tscn` — data-driven Objective,
  Dialogue/Captions, Journal/Discovery, Mission Table, Puzzle, Outcome,
  Pause, Settings/Accessibility and Credits panels.
- `game/scripts/ui/main_menu.gd` — additive query binding and command emission,
  plus settings/credits entry points, recursive modal disabling/focus trapping,
  safe focus restoration and accessibility presentation binding.
- `game/scripts/ui/slice_hud.gd` — additive query binding, panel host and
  primitive command emission while retaining existing slice signals/flow;
  captions, timer-free labels, reduced-motion metadata, large text and pause /
  journal focus restoration are wired here.
- `game/resources/ui/lla_theme.tres` — shared UI Theme resource for the owned
  menu/HUD/panel presentation path.
- `game/tools/test_worker_c_content.gd` — focused content/UI/audio/cutscene
  fixture.
- Godot UID sidecars for the owned scripts:
  `game/scripts/content/content_loader.gd.uid`,
  `game/scripts/dialogue/dialogue_service.gd.uid`,
  `game/scripts/audio/audio_runtime.gd.uid`,
  `game/scripts/cutscenes/cutscene_runtime.gd.uid`,
  `game/scripts/ui/campaign_panels.gd.uid`, and
  `game/tools/test_worker_c_content.gd.uid`.

## Frozen interfaces

### Content

`res://scripts/content/content_loader.gd` publishes:

```gdscript
load_full() -> Dictionary
validate_full(content: Dictionary) -> Dictionary
validate_dialogue_catalog(dialogue_catalog) -> Dictionary
scene_by_id(content: Dictionary, scene_id: String) -> Dictionary
mission_by_id(content: Dictionary, mission_id: String) -> Dictionary
dialogue_by_id(content: Dictionary, line_id: String) -> Dictionary
```

The global `CampaignContent` class under `res://scripts/campaign/` is not
replaced. The new class is `CampaignContentFull`; its `load_slice`, `validate`
and `scene_at` methods provide a bounded compatibility path for old callers.
Every mission has three ordered scene IDs. The catalog has 136 predicates
(96 scene, 32 mission, 8 chapter); all are explicitly world-state-owned.
Acknowledging a line can only acknowledge a line/cursor and has
`completes_predicate=false`.

### Dialogue and knowledge

`CampaignDialogueService` provides `dialogue_by_id`, `lines_for_scene`,
`caption_for_line`, `transcript`, `acknowledgement_command` and
`acknowledgement_result`. Noor text requires `noor_identity_revealed`; the
first live Noor line also requires `relay_local_verified` and
`relay_earth_verified`. Before the reveal, N. remains an unknown-initial
stored/recorded identity. The service is read-only and never grants a flag.

### Presentation commands

`CampaignPanels`, `MainMenu` and `SliceHUD` read duplicated primitive query
dictionaries and emit the frozen fields:

```text
command_id, issuer, owning_mission_id, owning_scene_id,
expected_state_revision, target_id, verb, payload
```

Example emitted acknowledgement:

```text
verb=acknowledge_line
target_id=EX-CH01-S01-L01
payload={line_id: EX-CH01-S01-L01, dialogue_only: true}
completes_predicate=false
```

The panels expose keyboard/controller-focusable buttons, captions-on and
timer-free defaults, large text, reduced motion labels and text/icon cues that
do not rely on colour alone. UI renders supplied labels; it does not calculate
simulation values.

`CampaignPanels` captures the focused control before a panel opens and restores
it safely after close. The main menu recursively disables background controls
while science, briefing or campaign-panel modals are active. Accessibility
settings are consumed by the panels, main menu and slice HUD: captions control
caption visibility, timer-free changes timing labels/mode, reduced motion sets
zero presentation transition time, and large text applies the 150% text scale.
These are presentation contracts only; campaign arithmetic remains state-owner
work.

### Audio and cutscenes

`CampaignAudioRuntime.voice_plan(line_id, flags)` returns a voice plan only if
the referenced runtime file actually exists and has a supported `.ogg`/`.wav`
extension; metadata booleans cannot promote missing or unsupported files.
Music/SFX availability uses the same file checks. `CampaignCutsceneRuntime`
enters video mode only for an existing path whose metadata and path extension
are both supported `.ogv`; otherwise it returns the exact text/caption
fallback. `skip()` emits only a presentation event and sets
`completes_predicate`, `completes_scene` and `completes_mission` to false.

## Verification executed

All commands used the approved executable:
`C:\Users\User\AppData\Local\Temp\opencode\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe`
(`Godot Engine v4.7.2.stable.official.ed1daf0bf`).

| Evidence label | Command | Result |
|---|---|---|
| `structural-pass` | `python game/scripts/content/build_catalog.py` | Generated both catalogs with the revisions/hashes above: campaign `31a768ef49efa7a9f5c1c97a581a66c0b5c731938bb3191a67fe56ecc7bf18c4`; dialogue `a3410ee72ab2e1e9349d6fdc66d312c15937646d7a25de9f87362d9d558addd2`. |
| `structural-pass` | `Godot --headless --path game --editor --quit` | Project scan and all owned GDScript classes parsed successfully. |
| `structural-pass` | `python -m json.tool` on both catalogs and `presentation_media.json`; `python -m py_compile game/scripts/content/build_catalog.py` | **PASS**; checked-in JSON and importer parse cleanly. |
| `functional-pass` | `Godot --headless --path game --script res://tools/test_worker_c_content.gd` | **PASS — 577 checks, 0 failures.** Includes focus restoration/trapping, all four accessibility toggles, strict media checks and corrupted/tampered fixtures. |
| `functional-pass` | `Godot --headless --path game --script res://tools/test_campaign_content.gd` | **PASS — 9 checks, 0 failures**; existing slice preserved. |
| `functional-pass` | `Godot --headless --path game --script res://tools/test_slice_state.gd` | **PASS — 13 checks, 0 failures**; preview/commit, duplicate, stale and save behavior preserved. |
| `functional-pass` | `Godot --headless --path game --script res://tools/test_ch01_commissioning.gd` | **PASS — 15 checks, 0 failures**; existing commissioning flow preserved. |
| `functional-pass` | `Godot --headless --path game --script res://tools/test_campaign_boot.gd` | **PASS — 4 checks, 0 failures**; current boot/menu remains intact. |
| `functional-pass` | `Godot --headless --path game --script res://tools/test_worker_a_systems.gd` | **PASS — 97 checks, 0 failures**; Worker A interfaces were inspected, not edited. |

The focused Worker C fixture checks IDs/order/text, source/evidence refs,
speaker/origin identity, N./Noor knowledge gates, predicate separation,
captions-only fallback, supported-extension/existence checks for audio and
video, three-OGV truthfulness, skip semantics, all nine panels, panel/HUD/menu
focus restoration and trapping, each accessibility toggle, emitted command
purity, catalog/dialogue hashes and revisions, malformed/null/tampered fixture
rejection, and slice lookup compatibility.

## Pause, duplicate, cancel and persistence behavior

- UI command emission duplicates its query/payload and does not mutate campaign
  state. The state owner remains responsible for stale revisions, duplicate
  receipts, pause and save/load behavior; Worker A's 97-check fixture passed.
- Dialogue acknowledgement is idempotency-ready through the frozen command
  shape and never completes a physical predicate.
- Panel close/Escape is presentation-only and restores the pre-open focus when
  that control remains valid. Settings are explicit presentation commands;
  captions, large text, timer-free labels and reduced motion do not advance
  scenario time or own campaign arithmetic.
- Cutscene skip is presentation-only and never repairs, counts, calibrates,
  proves a relay or completes a scene.

## Evidence status and blockers

- `present`: generated catalogs, loader, dialogue service, UI panel scene,
  media metadata and runtime scripts exist and were inspected.
- `structural-pass`: canonical hashes/counts/order/text, JSON resources and
  Godot parser checks pass.
- `functional-pass`: focused Worker C fixture and affected existing tests pass.
- `visual-pass`: **unverified**; no visual UI review/export was performed in
  this worker batch.
- `learner-pass`: **unverified**; no learner observation session was run.
- `unverified`: the full 96-scene campaign is not playable from the current
  main route, the three OGVs are not yet wired into a production campaign
  scene, and runtime voice/music/SFX files are absent. No full-campaign claim
  is made.
- `unverified`: no visual UI export/review, learner observation, or physical
  device/controller focus pass was run; the checks are headless presentation
  and contract tests.

## Next integration step

The supervisor should inject `CampaignContentFull.load_full()` into the agreed
campaign composition root, have Worker B bind mission/world scenes by
`mission_by_id`/`scene_by_id`, and route HUD/menu queries through
`CampaignPanels.bind_query` plus `command_emitted` into the single
`CampaignDirector`. The campaign dialogue layer should use
`CampaignDialogueService` for exact captions, while the cutscene owner can
wrap the three available OGV paths with `CampaignCutsceneRuntime` and retain
the text fallback for every missing cut.

No AI generation, paid tool use or provenance-log entry was required for this
content/code batch. Broad handbook and manifest files were not edited because
they are outside the Worker C ownership fence; source revisions are embedded
in the runtime catalogs and recorded here.
