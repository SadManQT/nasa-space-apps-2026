# M1-84 — Chapter 1 room hooks for the Care Round (Atik's M1-49)

7 Nov 2026 · Sadman/claude (Claude Opus 5.5) · rooms and staging only; no campaign, route, HUD or catalog edit; no
generation, no credits. Tests: `game/tools/test_ch01_room_hooks.gd`. Capture: `M1-84_capture.sh`.

## What was there

- **S02 blink:** LOC-04 (Safe Room, the scene's room) has a "shared inventory status lamp" fixture `inventory_lamp` at
  the roll-call board (`[-1.88, 1.24, -2.68]`), which blinked by itself 6 s after staging, whatever the player did.
- **S03 opening:** LOC-01's `inventory_lamp` sits on the dry-storage drawer (`dry_storage_drawer`, `[-5, 0.7, -4.8]`)
  and blinks 1.5 s after the Commons is staged for EX-CH01-S03 (canon S03: "The inventory lamp blinks beside a
  drawer"). The drawer itself is a fixture; nothing opens.
- **S04/S05 care:** the garden (LOC-03) has the focus targets `garden_alo_glove_port` (approach `[2.4, 0, 1.2]`) and
  `garden_tara_bay` (approach `[-3.2, 0, 0.5]`) and the plant anchors `plant_positions.ALO-01 [2.15, 0.8, 3.15]`
  (behind the pressure glazing and the viewing shutter) and `TARA-01 [-3.2, 0.8, -1.5]`. EX-CH01-S05 is mapped to
  the service rooms (LOC-02: corridor switch, hand-light locker), so its care visits had no garden data.
- **S12 mugs:** four plain `PR_Mug` on the Mission Table (`PR_Mug`, `commons_mug_2..4`); the approved M3-99
  `PR_Mug_Named` (variants KAI, AMARA, MEI, RAFI) was never placed.

## Published hooks

| Hook | Exact API / ids | Behaviour |
|---|---|---|
| Requested blink | `CampaignRoom.trigger_cue("inventory_lamp") -> {"accepted", "fixture_id", "scene_id", "sfx_id"}` | One pulse now in a scene the cue lists in `on_request` (LOC-04: `EX-CH01-S02`). A second call in the same staged scene returns `accepted: false, duplicate: true`; other scenes are refused. |
| Automatic blink | `set_scene_context("EX-CH01-S03")` returns 1 | LOC-01 drawer lamp, 1.5 s after staging; `trigger_cue` refuses it. Re-staging the same scene or new story state never restarts a cue. |
| Tick | `signal CampaignRoom.cue_lit(fixture_id, sfx_id)` → `CampaignAudioDirector.play_effect(sfx_id)` | Fires as the lamp lights, `sfx_id = "SFX_INVENTORY_LAMP_TICK"` (installed, caption "[inventory lamp]"). `play_effect` is new; any sfx_list id works. |
| Care Round | `RoomContract.care_round(scene_id)` (`EX-CH01-S04`, `EX-CH01-S05`; `{}` otherwise); also `CampaignRoom.stage().care_round` | `ALO-01`: `focus_target garden_alo_glove_port`, `plant_anchor ALO-01`, `stand [2.4, 0, 1.2]`, `photo_view {from [2.08, 1.25, 2.25], to [2.15, 0.86, 3.15]}`, `reach glove_ports`, `view_boundary garden_viewing_shutter`. `TARA-01`: `focus_target garden_tara_bay`, `plant_anchor TARA-01`, `stand [-3.2, 0, 0.5]`, `photo_view {from [-3.2, 1.22, -0.8], to [-3.2, 0.86, -1.5]}`, `reach direct`. Layer `ch01_care_round` in LOC-03. |
| S05 bridge | `RoomContract.room_for_scene("EX-CH01-S05") == "LOC-02"` (unchanged) | For S05's care visits stage a garden room (`garden.tscn`, `set_scene_context("EX-CH01-S05")`); the layer is active there. Alo's photo needs `set_door_open("garden_viewing_shutter", true)` from the route state (view only). |
| Named mugs | Layer `ch01_named_mugs` (LOC-01, from `EX-CH01-S12`, `"moment": "CH01-MUGS-NAMED"`) | Hides `PR_Mug`, `commons_mug_2/3/4`, places `commons_mug_kai` `[-0.45, 0.76, 0.2]`, `commons_mug_amara` `[0.45, 0.76, 0.2]`, `commons_mug_mei` `[-0.45, 0.76, -0.2]`, `commons_mug_rafi` `[0.45, 0.76, -0.2]` (PR_Mug_Named, yaw 62.6°, names facing the commons; the base mugs take the same yaw, so only the tape appears). |
| Moments in | `CampaignRoom.set_story_choices(choices, moments)`, `CampaignCrew.place(scene_id, room, at, choices, moments)`, `RoomContract.staging/staged_layout/staged_anchors(..., choices, moments)` | `moments` = `story_log.moments`. After the Director records CH01-MUGS-NAMED, pass the new moments and the Commons re-stages in place; every later Commons build shows the names. Without the moment the mugs stay nameless (matches the CH04-S12 echo gating). |

Wiring for M1-49 (Atik's code, not edited here): after each room build `_room.cue_lit.connect(func(_id, sfx): audio.play_effect(sfx))`;
on the S02 `roll_call` beat (`safe_roll_call_board`) `_room.trigger_cue("inventory_lamp")`; at the end of S12 record
`CH01-MUGS-NAMED`, then call `set_story_choices(story_log.choices, story_log.moments)` on any staged Commons (S12 plays
in the garden; to show the change on screen stage the Commons for EX-CH01-S12, otherwise the next Commons visit shows
the names). Do not record the moment from the room.

## EX-CH01-S01-L01..L04 and CS-01

Confirmed: `production/cutscenes/v8/src/CS-01.json` has `"lines": []`; `presentation_media.json` CS-01
(`res://assets/cutscenes/CS-01_Arrival.ogv`, trigger `scene_enter`) has `"caption_cues": []`; so
`CampaignCutsceneRuntime.heard_line_ids("CS-01", end)` is `[]` and `_on_cutscene_closed` marks none of the four heard.
All four have installed voices (`voice_plan(id).mode == "voice"`). No media edit was needed.

How to request them through the existing interface (campaign `Chapter1Campaign`, Atik's):

1. Line rows: `_dialogue.dialogue_by_id("EX-CH01-S01-L0n")` (`CampaignDialogueService`; `lines_for_scene("EX-CH01-S01")`
   returns exactly L01..L04 in order).
2. Present: `present_dialogue(line)` → `CampaignCrew.present_line` (speaker body; Ferreira on the Earth screen) and
   `CampaignAudioDirector.present_line(line, knowledge_flags)` (voices once per session, ducks music; L04's
   `origin: earth_link` adds `SFX_RADIO_EARTH_IN`). The caption is the HUD's (`_render_caption`, Ramim's), and its Next
   records `acknowledge_dialogue(line_id)`.
3. Beats: L01 then L02 when the player reaches the Mission Table (`commons_mission_table`) after CS-01 closes; L03 at
   the route preview (`forecast_target("commission_route", ...)`); L04 just before the commit
   (`perform_target("commission_route", ...)`). Today the HUD walks a scene's lines from scene entry, so holding L03/L04
   for their beats is campaign/HUD logic; nothing in the rooms or media blocks it.

## Checks

`test_ch01_room_hooks.gd`: lamp positions (roll-call board, drawer top), S02 no auto blink, one requested pulse, duplicate
refused, lit mid-pulse and dark after, `cue_lit` once with the tick, no restart on re-stage or story state, refused outside
S02; S03 one automatic pulse; `play_effect` plays the tick; Care Round for S04/S05 only, focus targets, plant anchors and
seedlings at them, stands reachable on navigation with line of sight, photo frames hold the plant within 8°; named mugs
only with the moment and from S12 (S12, CH02-S07, CH05-S02 with Ferreira's fifth mug, CH07-S12), same spots as the
Chapter 1 mugs, written names, facing the commons, resting on the table, restored without the moment; CS-01 and
L01..L04 as above.

Screenshots: `M1-84_S02_lamp_dark.png`, `M1-84_S02_lamp_blink.png`, `M1-84_S02_roll_call_wide_dark.png`,
`M1-84_S03_drawer_dark.png`, `M1-84_S03_drawer_blink.png`, `M1-84_S12_mugs_nameless.png`, `M1-84_S12_mugs_named.png`,
`M1-84_care_{alo,tara}_{0412,0416}.png`.
