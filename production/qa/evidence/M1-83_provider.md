# M1-83 — Care Round presentation provider for Atik M1-49

Ramim/codex · 7 Nov 2026 UTC / 8 Nov Bangladesh · provider only, no runtime wiring.

`res://scripts/ui/care_round_panel.gd` (`CareRoundPanel`, extends `Control`) reuses UiDesign/UiKit. Add it to the active UI tree before calling `open(view)`. Runtime must coordinate the modal with player movement, pause and other panels. There are no current callers: Atik M1-49 is the first consumer. No campaign, biology, rooms, resources, project/input settings or imports were changed.

## Exact producer/consumer contract

```gdscript
panel.set_settings({"large_text": true}) # optional; 150%, default false
panel.action_requested.connect(_on_care_request)
panel.closed.connect(_on_care_closed)
panel.open({
    "scene_id": "EX-CH01-S04",
    "date": "2046-04-12",
    "plants": [
        {
            "individual_id": "ALO-01", "name": "Alo", "stage": actual_stage,
            "moisture": calibrated_moisture, "temperature": actual_temperature_c,
            "current_photo_path": actual_current_local_image,
            "previous_photo_path": actual_previous_local_image,
            "care_options": [{"id": "note_leaf", "label": "Note a new leaf"}]
        },
        # Tara has the identical schema and equal-size presentation.
    ],
    "allowed_actions": {
        "ALO-01": ["observe", "measure", "photograph", "care", "record"],
        "TARA-01": ["observe"]
    },
    "family_mode": false,
    "capture_photo": Callable(self, "_capture_care_photo")
})
```

`plants` is an array of dictionaries with unique nonempty `individual_id`s; M1-49 supplies Alo and Tara. All names/stages/dates/readings/images come from the caller. Missing/nonfinite readings display `Unavailable`; missing/unreadable images remain empty with explicit text. No placeholder measurement or generated photo is substituted. Moisture preserves fractions; the reference band is 40–60. Both readings are required before the panel emits `measure`. Omitted actions are disabled. No care action is available without a supplied care option.

`signal action_requested(action: String, payload: Dictionary)` sends a request, never a receipt. Common payload:

```gdscript
{"individual_id": "ALO-01", "scene_id": "EX-CH01-S04", "date": "2046-04-12"}
```

| Action | Additional payload | Presentation behavior |
|---|---|---|
| `observe` | none | Explicit selected-plant request. |
| `measure` | `values: {"moisture": <provided number>, "temperature": <provided number>}` | Never computes or fabricates readings; missing either blocks request. |
| `photograph` | `photo_path: String`, `alignment: {"x": float, "y": float}` | Emitted only after the capture producer accepts and the local image can be decoded. |
| `care` | `care_id: String` | Selected supplied option id, never inferred from label. |
| `record` | none | Explicit selected-plant request; does not advance a lifecycle marker locally. |

Use `await panel.request_action(individual_id, action)` for programmatic invocation. It returns bool for whether a request was emitted; a true value is **not** gameplay acceptance. UI button handlers already await it. Open, selection, alignment, close, result rendering and requests never update gameplay state. Runtime validates current date, individual, stage, calibration, allowed action, order and daily photo rule through existing Director/PlantService; then updates its own authoritative view.

`render_result({"accepted": bool, "code": String, "message": String})` displays runtime feedback and emits nothing. `message` is the player-facing explanation; `code` is available to the caller (including `duplicate_date`) but is not rendered as developer text. A missing message gets a generic accepted/rejected message. Call it after open. It does not update readings, photos, action availability or receipts. Reopen with the refreshed view to present authoritative changes; an open resets local alignment/selection/feedback and reading focus to the top.

## Real capture handshake (required for photograph)

`capture_photo(request: Dictionary) -> Dictionary` may return immediately or `await` a rendered world frame. The panel awaits both forms. Request fields are exactly the common payload plus `alignment: {"x", "y"}`. Success returns `{"accepted": true, "photo_path": "<real local saved image>"}`. Failure returns `{"accepted": false, "message": "<player-facing reason>"}`. Non-dictionary, refused, missing, empty, nonexistent or undecodable output emits no photograph request. A callback is not optional for successful photos; the UI never invents a filename or treats a generic montage as a capture.

The producer is **capture-only**: acquire the real selected-plant world frame with the requested alignment, save a new local image without overwriting any existing Growth Record image, return only after saving succeeds. It must not call `apply_care`, mutate biology/date/receipts, or report gameplay success. Runtime commits the emitted `photograph` request afterward; a rejected request may leave an unreferenced capture file, whose cleanup is the runtime producer's responsibility.

The current world and HUD share a viewport. A producer using that viewport must temporarily suppress the UI, wait for the real rendered frame, capture/save, and restore presentation **before returning**. Use visibility suppression rather than `panel.close()`/`open()`; those represent real cancellation. Alternatively supply an independently rendered real world frame. Do not save the Care Round overlay. World staging, camera setup, correct shutter/glazing boundaries and persistence are Atik's runtime integration scope; no camera or room code was changed here.

Alignment is a normalized offset, clamped per axis to [-1, 1], rounded to 0.001 for the request. Preview movement is 48 canvas pixels per full axis, applied to the current image against a stationary previous ghost at 28% opacity. Arrow buttons change an axis by 0.1; Center resets both. A photo is allowed when both rounded absolute offsets are <= 0.3 (inclusive, generous tolerance). Producer must apply the same framing offset to its real frame. Family Mode snaps both offsets to zero immediately before capture. An absent previous photo stays honestly absent; center remains a usable frame for the first photo.

Only one capture per panel instance can be pending. Repeated requests while pending return false. Close/reopen increments a generation token; an old asynchronous result can never emit a stale request, reset the current capture's busy state, or show old feedback. Runtime should give each capture a unique local destination and dispose of orphan files if cancelled/rejected. No panel timer or automatic action progression exists.

## Input and evidence

Fresh open focuses the reading scroll at the title/date/sequence. Tab and directional focus traverse controls; focus scrolling makes all actions and Close reachable at 150%. Enter/Space confirm native buttons. Controller A confirms, D-pad navigates, B closes and restores the previous focus. Care-choice popup has its own controller input node because its Window owns input while open; D-pad selects, A confirms, B dismisses. Project input settings are unchanged. Hardware controller connection was not tested: focused and native evidence inject real Godot key/pad events into the active viewport.

`game/tools/test_care_round_panel.gd`: behavioral RED before source existed; final focused suite 26 checks. Covers no mutation/request on open, paired real/missing readings, both ghosts, allowed/unknown requests, absent/refused/unreadable capture, inclusive/outside alignment, Family snap, duplicate feedback, async frame delay and stale close/reopen cancellation, top entry focus, 150% card widths, keyboard/pad confirmation and selected care value.

`game/tools/capture_care_round_m183.gd`: windowed Godot Forward+ at 1280×720; `M1-83_capture_probe.txt` records title/date/sequence visibility on fresh open, both ghosts, normal/150 text/control width bounds, 44px targets, actual preview movement, async local save, Family snap, popup selection, final-control scrolling, D-pad cycle and Back focus restoration. Six native images were visually inspected:

- `M1-83_paired_ghost.png`: fresh normal entry, both supplied images/ghosts and sequence.
- `M1-83_alo_aligned.png`: keyboard-shifted Alo current frame against prior ghost, waiting for runtime confirmation.
- `M1-83_tara_family_duplicate.png`: Tara controller photograph with Family snap, supplied runtime duplicate-date feedback.
- `M1-83_tara_family_duplicate_150.png`: the same feedback at 150%.
- `M1-83_paired_ghost_150.png`: fresh 150% open, not a reused duplicate-result state.
- `M1-83_actions_150.png`: focus-scrolled action footer, selected Tara care value and reachable Close at 150%.

Native fixture images are Sadman's real `M1-84_care_{alo,tara}_{0412,0416}.png` room captures. The readings 40.25/59.75 and 21/22°C and dates are explicitly supplied provider fixtures, not a campaign measurement. The capture fixture waits a rendered frame and saves a real supplied image to a process-specific OS cache directory, then removes only those fixture files. It does not stage a runtime camera or prove a two-date campaign/save/reload flow. The older frame overlay is visible but the source room photographs contain very small plants; no replacement image or unsupported visual upgrade is claimed.

No asset generation, paid tool, new dependency, handbook decision, campaign transaction, board change or AI generation occurred. Full runner/independent review results are recorded in the task report; runtime M1-49 acceptance remains Atik's.
