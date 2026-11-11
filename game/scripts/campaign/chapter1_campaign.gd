extends Node3D
class_name Chapter1Campaign

signal exit_requested
## Ramim's panel subscribes here. Opening/cancelling never submits choices.
signal p01_panel_requested(view: Dictionary)
## Chapter 2 decision panel (P-03 and P-04). Opening, previewing and cancelling
## never commit; only confirm_chapter2_choice with the previewed choices does.
signal chapter2_panel_requested(view: Dictionary)
## Class puzzle commits ask every role to review the same current forecast.
signal class_team_plan_requested(view: Dictionary)
## A cutscene closed (watched to the end, skipped, or its text card dismissed).
signal cutscene_closed(result: Dictionary)

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const ExtendedRouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const TerrainSessionScript = preload("res://scripts/campaign/terrain_session.gd")
const CompanionRosterScript = preload("res://scripts/companions/companion_roster.gd")
const CutsceneRuntimeScript = preload("res://scripts/cutscenes/cutscene_runtime.gd")
const AudioRuntimeScript = preload("res://scripts/audio/audio_runtime.gd")
const EvaSuitScript = preload("res://scripts/eva/eva_suit.gd")
const CadetProgressionScript = preload("res://scripts/progression/cadet_progression.gd")
const FieldSystemsScript = preload("res://scripts/campaign/campaign_field_systems.gd")
const CampaignProgressionScript = preload("res://scripts/campaign/campaign_progression.gd")
const SaveSlotsScript = preload("res://scripts/save/save_slots.gd")
const GameSettingsScript = preload("res://scripts/settings/game_settings.gd")
const CrewModesScript = preload("res://scripts/classmode/crew_modes.gd")
const HUDScene: PackedScene = preload("res://scenes/ui/chapter1_campaign_hud.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

@export var initial_snapshot: Dictionary = {}
@export var initial_accessibility: Dictionary = {}

# Direct scene fixtures may still use the synchronous API. Production boot
# always enables incremental loading and supplies the title's prepared resources.
var incremental_loading := false
var preparation: LoadPreparation
var prepared_content: Dictionary = {}
var loading := false
var _transition_card: LoadingCard
var _lookahead_room := ""

var _dialogue: CampaignDialogueService
var content: Dictionary = {}
var director: CampaignDirector
var route: RefCounted
var save_service: SaveService
var save_slots: SaveSlots
var game_settings: GameSettings
var hud: Chapter1CampaignHUD
var _room: CampaignRoom
var _crew: CampaignCrew
var _player: PlayerController
var eva_suit: EvaSuit
var progression: RefCounted
var field_systems: RefCounted
var progression_flow: RefCounted
var _progression_flow: RefCounted
var _last_eva_room_id := ""
var _last_scan_origin := Vector3(INF, INF, INF)
## M1-36: the LOLA terrain under an exterior whose placement and lighting are ready (RoomContract.terrain_lighting).
var _terrain: Node3D
var _startup_error := ""
var _ui_paused := false
## The open Chapter 2 panel and the exact choices last previewed for it.
var _chapter2_pending: Dictionary = {}
## Signatures are evidence for one exact live choice, never checkpoint state.
var _class_team_signoffs: Dictionary = {}
var _exit_without_save_armed := false
var save_path: String = SaveScript.DEFAULT_PATH
var settings_path: String = GameSettingsScript.DEFAULT_PATH
var _play_time_seconds := 0.0
var _last_autosave_trigger := "checkpoint"
var cutscenes: CampaignCutsceneRuntime
var cutscene_player: CampaignCutscenePlayer
var audio: CampaignAudioDirector
var _cutscene_queue: Array = []
var _played_cutscenes := {}
var _saved_garage_dock: Dictionary = {}

func _ready() -> void:
	if incremental_loading:
		loading = true
		_ready_incremental.call_deferred()
		return
	_start_session()
	if _startup_error.is_empty():
		_refresh_world()
		_build_hud()
		_save_campaign("scene_join")

func _start_session_incremental() -> void:
	var stamp := LoadTrace.begin()
	content = prepared_content if not prepared_content.is_empty() else ContentScript.load_full()
	_dialogue = CampaignDialogueService.new(content)
	var validation := preparation.validation if preparation != null and not prepared_content.is_empty() else ContentScript.validate_full(content)
	if not bool(validation.get("valid", false)):
		_fail_startup("Campaign content could not be verified.")
		return
	LoadTrace.end("content_validation", stamp)
	await get_tree().process_frame
	stamp = LoadTrace.begin()
	save_service = SaveScript.new()
	save_service.session_validator = restore_session
	save_slots = SaveSlotsScript.new(save_path, restore_session)
	if game_settings == null:
		game_settings = GameSettingsScript.new(settings_path)
	if initial_snapshot.is_empty():
		director = DirectorScript.new()
		if director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION).is_empty():
			_fail_startup("The gameplay profile could not be verified.")
			return
		route = RouteScript.new(director)
	else:
		var session := restore_session(initial_snapshot)
		if not bool(session.get("accepted", false)):
			_fail_startup(String(session.get("reason", "The checkpoint could not be restored.")))
			return
		director = session.director
		route = session.route
		var saved_dock = initial_snapshot.get("route_runtime", {}).get("garage_dock", {}) if initial_snapshot.get("route_runtime", null) is Dictionary else {}
		if saved_dock is Dictionary:
			_saved_garage_dock = saved_dock.duplicate(true)
	await get_tree().process_frame
	var presentation := director.snapshot()
	presentation["paused"] = false
	for key in initial_accessibility:
		presentation["accessibility"][key] = initial_accessibility[key]
	director.restore_snapshot(presentation)
	var assist_mode := String(presentation.get("accessibility", {}).get("assist_mode", "Cadet"))
	eva_suit = EvaSuitScript.new(assist_mode)
	progression = CadetProgressionScript.new()
	field_systems = FieldSystemsScript.new(self)
	var resume: Dictionary = initial_snapshot.get("presentation_resume", {})
	var loaded_meta: Variant = resume.get("slot_metadata", {})
	if loaded_meta is Dictionary:
		_play_time_seconds = maxf(0.0, float((loaded_meta as Dictionary).get("play_time_seconds", 0.0)))
	field_systems.restore(resume.get("field_systems", {}))
	_progression_flow = CampaignProgressionScript.new(self)
	progression_flow = _progression_flow
	_progression_flow.restore(resume)
	progression = _progression_flow.model
	_sync_route_projection()
	LoadTrace.end("route_profile", stamp)
	await get_tree().process_frame
	_build_media()

func _start_session() -> void:
	var stamp := LoadTrace.begin()
	content = prepared_content if not prepared_content.is_empty() else ContentScript.load_full()
	_dialogue = CampaignDialogueService.new(content)
	var validation := preparation.validation if preparation != null and not prepared_content.is_empty() else ContentScript.validate_full(content)
	if not bool(validation.get("valid", false)):
		_fail_startup("Campaign content could not be verified.")
		return
	LoadTrace.end("content_validation", stamp)
	stamp = LoadTrace.begin()
	save_service = SaveScript.new()
	save_service.session_validator = restore_session
	save_slots = SaveSlotsScript.new(save_path, restore_session)
	if game_settings == null:
		game_settings = GameSettingsScript.new(settings_path)
	if initial_snapshot.is_empty():
		director = DirectorScript.new()
		if director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION).is_empty():
			_fail_startup("The gameplay profile could not be verified.")
			return
		route = RouteScript.new(director)
	else:
		var session := restore_session(initial_snapshot)
		if not bool(session.get("accepted", false)):
			_fail_startup(String(session.get("reason", "The checkpoint could not be restored.")))
			return
		director = session.director
		route = session.route
		var saved_dock = initial_snapshot.get("route_runtime", {}).get("garage_dock", {}) if initial_snapshot.get("route_runtime", null) is Dictionary else {}
		if saved_dock is Dictionary:
			_saved_garage_dock = saved_dock.duplicate(true)
	var presentation := director.snapshot()
	presentation["paused"] = false
	for key in initial_accessibility:
		presentation["accessibility"][key] = initial_accessibility[key]
	director.restore_snapshot(presentation)
	var assist_mode := String(presentation.get("accessibility", {}).get("assist_mode", "Cadet"))
	eva_suit = EvaSuitScript.new(assist_mode)
	progression = CadetProgressionScript.new()
	field_systems = FieldSystemsScript.new(self)
	var resume: Dictionary = initial_snapshot.get("presentation_resume", {})
	var loaded_meta: Variant = resume.get("slot_metadata", {})
	if loaded_meta is Dictionary:
		_play_time_seconds = maxf(0.0, float((loaded_meta as Dictionary).get("play_time_seconds", 0.0)))
	field_systems.restore(resume.get("field_systems", {}))
	var flow_script = load("res://scripts/campaign/campaign_progression.gd")
	if flow_script != null:
		_progression_flow = flow_script.new(self)
		progression_flow = _progression_flow
		_progression_flow.restore(resume)
		progression = _progression_flow.model
	_sync_route_projection()
	LoadTrace.end("route_profile", stamp)
	_build_media()

## Cutscene and audio presentation. Both share the session's dialogue service
## and media manifest; neither can change gameplay state.
func _build_media() -> void:
	var metadata := AudioRuntimeScript.read_metadata()
	cutscenes = CutsceneRuntimeScript.new(content, metadata, _dialogue)
	cutscene_player = CampaignCutscenePlayer.new()
	cutscene_player.name = "Cutscene"
	cutscene_player.skip_hold_s = cutscenes.skip_hold_seconds()
	cutscene_player.closed.connect(_on_cutscene_closed)
	add_child(cutscene_player)
	audio = CampaignAudioDirector.new()
	audio.name = "Audio"
	audio.setup(AudioRuntimeScript.new(content, metadata, _dialogue), preparation)
	add_child(audio)

func _ready_incremental() -> void:
	await get_tree().process_frame
	if preparation == null:
		preparation = LoadPreparation.new()
		add_child(preparation)
		await preparation.prepare_campaign()
		if not preparation.failed.is_empty():
			_fail_startup(preparation.failed)
			loading = false
			return
		prepared_content = preparation.content
		_crew = preparation.crew
		_crew.reparent(self)
	await get_tree().process_frame
	await _start_session_incremental()
	await get_tree().process_frame
	if _startup_error.is_empty():
		await _refresh_world_incremental()
		var stamp := LoadTrace.begin()
		await _build_hud()
		LoadTrace.end("campaign_ui", stamp)
		await get_tree().process_frame
		_save_campaign()
		await get_tree().process_frame
	if hud != null:
		var ready_stamp := LoadTrace.begin()
		await hud.refresh_scene({}, true)
		LoadTrace.end("campaign_hud_refresh", ready_stamp)
	loading = false
	_on_scene_ready()
	if hud != null:
		hud._render_caption()
		hud._offer_resume_card()
	_prefetch_next_room()

func wait_loading() -> void:
	while loading:
		await get_tree().process_frame

## Rebuilds a director and its chapter route from a saved snapshot in fresh
## objects, without touching any live session. SaveService uses it to judge
## whether a checkpoint can actually resume before choosing it over a backup.
static func restore_session(snapshot: Dictionary) -> Dictionary:
	var saved_route = snapshot.get("route_runtime", {})
	if not saved_route is Dictionary or saved_route.is_empty():
		return {"accepted": false, "reason": "This checkpoint is missing its physical mission route."}
	if str(saved_route.get("current_scene_id", "")) != str(snapshot.get("scene_id", "")):
		return {"accepted": false, "reason": "The checkpoint scene and physical mission route disagree."}
	var state := snapshot.duplicate(true)
	state.erase("route_runtime")
	var session_director := DirectorScript.new()
	var restored: Dictionary = session_director.restore_snapshot(state, ContentScript.EXPECTED_CONTENT_REVISION)
	if not bool(restored.get("accepted", false)):
		return restored
	var chapter := int(String(state.get("chapter_id", "CH01")).trim_prefix("CH"))
	var route_chapter = saved_route.get("chapter", chapter)
	if not (route_chapter is int or route_chapter is float) or float(route_chapter) != chapter:
		return {"accepted": false, "reason": "The saved mission route belongs to a different chapter."}
	var session_route: RefCounted
	if chapter == 2:
		session_route = Chapter2RouteScript.new(session_director, true)
	elif chapter >= 3 and chapter <= 8:
		session_route = ExtendedRouteScript.new(session_director, true)
	elif chapter == 1:
		session_route = RouteScript.new(session_director, true)
	else:
		return {"accepted": false, "reason": "The checkpoint names an unknown chapter."}
	var route_restore: Dictionary = session_route.restore(saved_route)
	if not bool(route_restore.get("accepted", false)):
		return route_restore
	return {"accepted": true, "director": session_director, "route": session_route}

func current_scene_data() -> Dictionary:
	return ContentScript.scene_by_id(content, route.current_scene_id())

func current_dialogue() -> Array:
	return _dialogue.lines_for_scene(route.current_scene_id(), director.snapshot().get("knowledge_flags", []))

func targets_for_current_scene() -> Array:
	return _targets_for_scene()

func _targets_for_scene() -> Array:
	if route == null:
		return []
	var raw: Array = route.targets_for_current_scene()
	if _room == null:
		return raw
	var stations: Dictionary = _room.stage().get("stations", {})
	if stations.is_empty():
		return raw
	var bound: Array = []
	for item in raw:
		var target: Dictionary = item.duplicate(true)
		var target_id := String(target.get("target_id", ""))
		var station := String(stations.get(target_id, stations.get("p03_" + target_id, "")))
		if not station.is_empty():
			target["world_focus_id"] = station
		bound.append(target)
	return bound

func query() -> Dictionary:
	var result := director.query()
	result["crew"] = director.crew()
	result["scene_id"] = route.current_scene_id()
	result["mission_id"] = route.current_mission_id()
	result["room_id"] = route.current_room_id()
	result["objective"] = current_scene_data().get("playerActions", [])
	result["dialogue_lines"] = current_dialogue()
	result["journal_entries"] = CampaignKnowledge.journal(director.snapshot())
	var current := director.snapshot()
	result["accessibility"] = current.get("accessibility", {})
	for key in ["plants", "scenario_datetime", "current_shift", "completed_scene_ids", "resources"]:
		result[key] = current.get(key)
	result["route_runtime"] = route.snapshot()
	result["cadet_progression"] = progression.snapshot() if progression != null else {}
	result["completed_chapters"] = completed_chapters()
	result["available_upgrade_chapter"] = available_upgrade_chapter()
	result["field_systems"] = field_systems.snapshot() if field_systems != null else {}
	var puzzle_ids: Array = []
	for target in targets_for_current_scene():
		var puzzle_id := String(target.get("puzzle_id", ""))
		if not puzzle_id.is_empty() and not puzzle_ids.has(puzzle_id):
			puzzle_ids.append(puzzle_id)
	result["source_puzzle_ids"] = puzzle_ids
	result["mission_table"] = {"title": current_scene_data().get("title", ""), "status": route.gate_status()}
	if _chapter_number() == 1:
		var decision: Dictionary = current_scene_data().get("choice", {}).duplicate(true)
		var choice_id := String(decision.get("id", ""))
		decision["choice_id"] = choice_id
		decision["recorded_option_id"] = director.snapshot().story_log.choices.get(choice_id, {}).get("option_id", "")
		decision["locked"] = CampaignState.story_choice_locked(director.snapshot(), choice_id)
		result["puzzle"] = decision
	return result

## Public Class contract for the later puzzle panels. P-02 keeps its existing
## route-owned team plan, while every other puzzle uses this physical campaign
## bridge so plain USE and panel callbacks share one commit guard.
func class_team_plan_view(target_id: String, payload: Dictionary = {}) -> Dictionary:
	if director == null or route == null or String(director.crew().get("mode", "solo")) != "class":
		return {"accepted": false, "reason": "A Class expedition is required for a team plan."}
	var spec := _class_puzzle_spec(target_id)
	if spec.is_empty():
		return {"accepted": false, "reason": "This is not a later puzzle decision in the current scene."}
	var forecast := forecast_target(target_id, payload)
	if not bool(forecast.get("accepted", false)):
		return {"accepted": false, "reason": String(forecast.get("reason", "Review a valid choice before signing."))}
	var state := director.snapshot()
	var after: Dictionary = forecast.get("query", {})
	var selection := {
		"target_id": target_id,
		"scene_id": route.current_scene_id(),
		"crew": director.crew(),
		"state_revision": int(state.get("state_revision", -1)),
		"payload": payload.duplicate(true),
		"forecast": {
			"resources": after.get("resources", {}).duplicate(true),
			"status": String(after.get("status", "")),
			"current_shift": int(after.get("current_shift", 0)),
			"scenario_datetime": String(after.get("scenario_datetime", "")),
		},
	}
	var signed: Array = []
	var stale: Array = []
	for role_id in CrewModesScript.ROLE_ORDER:
		if not _class_team_signoffs.has(role_id):
			continue
		if _class_team_signoffs[role_id] == selection:
			signed.append(role_id)
		else:
			stale.append(role_id)
	return {
		"accepted": true,
		"target_id": target_id,
		"puzzle_id": String(spec.get("puzzle_id", "")),
		"focus_label": String(spec.get("focus_label", target_id)),
		"crew": director.crew(),
		"required_roles": CrewModesScript.ROLE_ORDER.duplicate(),
		"signed_roles": signed,
		"stale_roles": stale,
		"selection": selection,
		"forecast": forecast.duplicate(true),
	}

func sign_class_team_plan(role_id: String, target_id: String, payload: Dictionary, reviewed_selection: Variant) -> Dictionary:
	var view := class_team_plan_view(target_id, payload)
	if not bool(view.get("accepted", false)):
		return view
	if not view.required_roles.has(role_id):
		return {"accepted": false, "reason": "This role cannot sign the Class team plan."}
	if not reviewed_selection is Dictionary or reviewed_selection != view.selection:
		return {"accepted": false, "reason": "The choice or forecast changed. Review it again."}
	var duplicate: bool = _class_team_signoffs.get(role_id, {}) == view.selection
	_class_team_signoffs[role_id] = view.selection.duplicate(true)
	return {"accepted": true, "duplicate": duplicate, "role_id": role_id}

func cancel_class_team_plan() -> void:
	_class_team_signoffs.clear()

func _class_puzzle_spec(target_id: String) -> Dictionary:
	for spec in targets_for_current_scene():
		if String(spec.get("target_id", "")) == target_id and not String(spec.get("puzzle_id", "")).is_empty() and String(spec.get("puzzle_id", "")) != "P-02":
			return spec
	return {}

func _class_commit_hold(target_id: String, payload: Dictionary) -> Dictionary:
	if director == null or String(director.crew().get("mode", "solo")) != "class" or _class_puzzle_spec(target_id).is_empty():
		return {}
	var view := class_team_plan_view(target_id, payload)
	if not bool(view.get("accepted", false)):
		return view
	for role_id in view.required_roles:
		if not view.signed_roles.has(role_id):
			if not class_team_plan_requested.get_connections().is_empty():
				class_team_plan_requested.emit(view.duplicate(true))
			return {"accepted": false, "class_team_plan_required": true, "reason": "Every Class role must sign this exact choice before lock-in."}
	return {}

## Project the real route operation on a restored copy. This exercises the
## owning puzzle/ledger/director transition, including custom physical steps,
## without changing live receipts, flags, resources, time or saves.
func forecast_target(target_id: String, payload: Dictionary = {}) -> Dictionary:
	var state := _save_snapshot()
	state["paused"] = false
	if state.get("route_runtime", null) is Dictionary:
		state["route_runtime"]["retry_checkpoint"] = {}
	var projected := restore_session(state)
	if not bool(projected.get("accepted", false)):
		return projected
	var result: Dictionary = projected.route.perform(target_id, payload)
	if not bool(result.get("accepted", false)):
		return {"accepted": false, "reason": result.get("reason", "Forecast unavailable.")}
	var predicted = result.get("snapshot", {})
	if predicted is Dictionary and predicted.get("schema_version") == state.get("schema_version") and predicted.get("resources", {}).has("E"):
		projected.director.restore_snapshot(predicted)
	var forecast := {"accepted": true, "target_id": target_id, "input_revision": state.state_revision, "query": projected.director.query(), "reason": result.get("reason", "Read-only forecast")}
	if projected.route.has_method("p01_view"):
		var plant_view: Dictionary = projected.route.p01_view(target_id)
		if plant_view.get("accepted", false):
			forecast["p01"] = plant_view
	return forecast

func p01_view(target_id: String) -> Dictionary:
	if route == null or not route.has_method("p01_view"):
		return {"accepted": false, "reason": "P-01 is unavailable in this chapter."}
	return route.p01_view(target_id)

## Read-only forecast of the player's chosen Chapter 2 inputs. Needs the open,
## paused panel for this target. Any rejected preview forgets the earlier one.
func preview_chapter2_choice(target_id: String, payload: Dictionary) -> Dictionary:
	if _chapter2_pending.is_empty() or String(_chapter2_pending.get("target_id", "")) != target_id or not _ui_paused:
		return {"accepted": false, "reason": "Open this Chapter 2 panel first; previews need the paused panel."}
	var forecast := forecast_target(target_id, payload)
	if not bool(forecast.get("accepted", false)):
		_chapter2_pending["previewed"] = null
		return forecast
	_chapter2_pending["previewed"] = payload.duplicate(true)
	_chapter2_pending["input_revision"] = int(forecast.get("input_revision", -1))
	return forecast

## Commits exactly the previewed choices, once, at the physical target.
func confirm_chapter2_choice(target_id: String, payload: Dictionary) -> Dictionary:
	if _chapter2_pending.is_empty() or String(_chapter2_pending.get("target_id", "")) != target_id:
		return {"accepted": false, "reason": "Open this Chapter 2 panel and preview your choice first."}
	if _ui_paused:
		return {"accepted": false, "reason": "Close the panel's pause before confirming."}
	var previewed = _chapter2_pending.get("previewed", null)
	if not previewed is Dictionary or previewed != payload:
		return {"accepted": false, "reason": "Preview these exact choices before confirming."}
	if int(_chapter2_pending.get("input_revision", -2)) != int(director.snapshot().get("state_revision", -1)):
		return {"accepted": false, "reason": "The expedition changed since the preview. Preview again."}
	if String(nearby_target().get("target_id", "")) != target_id:
		return {"accepted": false, "reason": "Walk up to the target and face it to confirm."}
	var result := perform_target(target_id, payload)
	if bool(result.get("accepted", false)):
		_chapter2_pending = {}
	return result

func cancel_chapter2_choice() -> void:
	_chapter2_pending = {}
	_class_team_signoffs.clear()

func perform_target(target_id: String, payload: Dictionary = {}) -> Dictionary:
	if loading or not _startup_error.is_empty() or route == null:
		return {"accepted": false, "reason": "The expedition is unavailable."}
	if is_chapter_complete():
		return {"accepted": false, "reason": "Chapter 1 is complete. Return to title to keep this checkpoint."}
	var prev_segment := _current_terrain_segment()
	var target := physical_target(target_id)
	var result: Dictionary
	if target == null or _player == null:
		result = {"accepted": false, "reason": "This operation has no physical target in the current room."}
	elif _room != null and _room.room_id == "LOC-08" and _room.garage() != null and target == _focus_node("garage_dock") and _room.garage().dock_state() != "SAFE TO OPEN":
		var clear := _has_line_of_sight(target)
		if not clear:
			result = {"accepted": false, "reason": "Move into clear view of " + String(target.get_meta("focus_label", "the target")) + "."}
		elif director != null and String(director.crew().get("mode", "solo")) == "class" and not _class_puzzle_spec(target_id).is_empty() and String(nearby_target().get("target_id", "")) != target_id:
			result = {"accepted": false, "reason": "Walk up to this puzzle target and face it before signing."}
		else:
			var bay := _room.garage()
			var cycled: Dictionary = bay.request_dock_cycle("habitat")
			var card: String = bay.time_card()
			result = {"accepted": false, "dock_cycling": bool(cycled.get("accepted", false)), "time_card": card, "reason": card if not card.is_empty() else String(cycled.get("reason", "Equalising the rover dock tunnel."))}
			if hud != null and not card.is_empty():
				hud.show_status(card)
	else:
		var distance := _player.global_position.distance_to(target.global_position)
		var clear := _has_line_of_sight(target)
		if not clear:
			result = {"accepted": false, "reason": "Move into clear view of " + String(target.get_meta("focus_label", "the target")) + "."}
		else:
			var class_hold := _class_commit_hold(target_id, payload)
			result = class_hold if not class_hold.is_empty() else route.perform(target_id, payload, {"room_id": _room.room_id, "distance_m": distance, "line_of_sight": clear})
	if result.has("result") and result.result is Dictionary and result.get("accepted", false):
		for key in ["reason", "deltas", "warnings", "ledger_summary"]:
			if result.result.has(key):
				result[key] = result.result[key]
	if bool(result.get("accepted", false)) and _room != null and _room.room_id == "LOC-08" and _room.garage() != null and target == _focus_node("garage_dock") and _room.garage().dock_state() == "SAFE TO OPEN":
		route.world().set_boundary_state("garage_dock_hatch", {"airlock_ready": true, "open": true})
	# M1-49: the S02 roll call blinks the inventory lamp once in the
	# background (doc 24 §2.9 CH01 S02->S03); the room owns the single pulse
	# and S03 opens on it. The tick plays through the audio director.
	if bool(result.get("accepted", false)) and target_id == "roll_call" and route.current_scene_id() == "EX-CH01-S02" and route.has_method("request_inventory_lamp_blink"):
		var blink: Dictionary = route.request_inventory_lamp_blink()
		if not blink.is_empty() and _room != null:
			var fired: Dictionary = _room.trigger_cue(String(blink.get("cue_id", "inventory_lamp")))
			result["inventory_lamp_blink"] = fired
			if bool(fired.get("accepted", false)) and audio != null:
				audio.play_effect(String(fired.get("sfx_id", "SFX_INVENTORY_LAMP_TICK")))
	# M1-49: the S04/S05 care targets hand the scene layer the Care Round
	# visit (CareRoundRuntime.open_round opens the panel with it).
	if bool(result.get("accepted", false)) and target_id in ["record_paired_conditions", "care_montage"] and route.has_method("care_round_visit"):
		result["care_round"] = route.care_round_visit(route.current_scene_id())
	var next_segment := _current_terrain_segment()
	if bool(result.get("accepted", false)) and next_segment != prev_segment:
		var cruise_card := _segment_cruise_card(prev_segment, next_segment)
		result["terrain_segment"] = next_segment
		result["cruise_time_card"] = cruise_card
		_refresh_world()
		if hud != null and not cruise_card.is_empty():
			hud.show_status(cruise_card)
	_sync_world_boundaries()
	if audio != null and not bool(result.get("duplicate", false)):
		var label := ""
		for spec in targets_for_current_scene():
			if String(spec.get("target_id", "")) == target_id:
				label = String(spec.get("focus_label", ""))
		audio.play_operation(target_id, label, bool(result.get("accepted", false)))
	if _crew != null:
		_crew.react(result, bool(director.snapshot().get("accessibility", {}).get("reduced_motion", false)))
	if hud != null:
		hud.refresh_after_action(result)
	if bool(result.get("accepted", false)) and field_systems != null:
		field_systems.sync_route()
	if bool(result.get("accepted", false)):
		_class_team_signoffs.clear()
	_save_campaign()
	return result

func _focus_node(world_focus_id: String) -> Node3D:
	if _room == null or _room.focus_root == null or world_focus_id.is_empty():
		return null
	var direct := _room.focus_root.get_node_or_null("Focus_" + world_focus_id) as Node3D
	if direct != null:
		return direct
	for node in _room.focus_root.get_children():
		if String(node.get_meta("target_id", "")) == world_focus_id:
			return node as Node3D
	return null

func physical_target(target_id: String) -> Node3D:
	if _room == null or _room.focus_root == null:
		return null
	for spec in targets_for_current_scene():
		if String(spec.get("target_id", "")) == target_id:
			return _focus_node(String(spec.get("world_focus_id", "")))
	return null

func target_completed(spec: Dictionary, flags_override: Variant = null, director_receipts_override: Variant = null, p01_receipts_override: Variant = null) -> bool:
	var id := String(spec.get("target_id", ""))
	var physical_flags: Dictionary = flags_override if flags_override is Dictionary else route.gate_status().get("physical_flags", {})
	if id == "p02_stage_shift2":
		return bool(physical_flags.get("shift2_preview_staged", false))
	if String(spec.get("puzzle_id", "")) == "P-01":
		var p01_receipts: Dictionary = p01_receipts_override if p01_receipts_override is Dictionary else (route._p01.snapshot().get("receipts", {}) if "_p01" in route and route._p01 != null else route.snapshot().get("p01", {}).get("receipts", {}))
		return p01_receipts.has("p01:" + id)
	if bool(physical_flags.get(String(spec.get("physical_flag", "")), false)):
		return true
	var receipts: Dictionary = director_receipts_override if director_receipts_override is Dictionary else director.snapshot().get("receipts", {})
	return receipts.has(String(spec.get("command_id", "")))

func nearby_target() -> Dictionary:
	if _ui_paused or _player == null or _room == null:
		return {}
	var camera := _player.follow_camera.camera
	var flags: Dictionary = route.current_flags() if route.has_method("current_flags") else route.gate_status().get("physical_flags", {})
	var prerequisites: Dictionary = route._context_flags() if route.has_method("_context_flags") else flags
	var director_receipts: Dictionary = director._state.get("receipts", {}) if "_state" in director else director.snapshot().get("receipts", {})
	var p01_receipts: Variant = null
	var closest: Dictionary = {}
	var nearest := INF
	for spec in targets_for_current_scene():
		if String(spec.get("puzzle_id", "")) == "P-01" and p01_receipts == null:
			p01_receipts = route._p01.snapshot().get("receipts", {}) if "_p01" in route and route._p01 != null else route.snapshot().get("p01", {}).get("receipts", {})
		if target_completed(spec, flags, director_receipts, p01_receipts):
			continue
		var missing := false
		for flag in spec.get("required_flags", []):
			if not bool(prerequisites.get(flag, false)):
				missing = true
		if missing:
			continue
		var target := _focus_node(String(spec.get("world_focus_id", "")))
		if target == null:
			continue
		var distance := _player.global_position.distance_to(target.global_position)
		if distance > float(spec.get("range_m", 3.0)) or distance >= nearest or not camera.is_position_in_frustum(target.global_position):
			continue
		if not _has_line_of_sight(target):
			continue
		closest = spec
		nearest = distance
	return closest

func _has_line_of_sight(target: Node3D) -> bool:
	if _player == null or target == null:
		return false
	var ray := PhysicsRayQueryParameters3D.create(_player.global_position + Vector3.UP * 1.4, target.global_position, _player.collision_mask, [_player.get_rid()])
	var hit: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return true
	var collider: Object = hit.get("collider", null)
	var asset_id := String(target.get_meta("asset_id", ""))
	if collider is Node and not asset_id.is_empty() and _room != null:
		if _room.visual_root != null:
			var asset := _room.visual_root.get_node_or_null(asset_id)
			if asset != null and (collider == asset or asset.is_ancestor_of(collider as Node)):
				return true
		if _room.collision_root != null:
			var obs := _room.collision_root.get_node_or_null(asset_id)
			if obs != null and (collider == obs or obs.is_ancestor_of(collider as Node)):
				return true
	return false

func interact_nearby() -> Dictionary:
	var selected := nearby_target()
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) == "P-01":
		var view := p01_view(String(selected.target_id))
		if not view.get("accepted", false):
			return view
		p01_panel_requested.emit(view)
		return {"accepted": true, "p01_panel_requested": true, "physical_commit": false, "reason": "Choose the P-01 inputs before confirming."}
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) in ["P-03", "P-04"] and route != null and route.has_method("puzzle_view"):
		var view: Dictionary = route.puzzle_view(String(selected.target_id))
		if not view.get("accepted", false):
			return view
		if chapter2_panel_requested.get_connections().is_empty():
			return {"accepted": false, "reason": "The Chapter 2 decision panel is unavailable, so nothing was committed."}
		_chapter2_pending = {"target_id": String(selected.target_id), "input_revision": int(view.get("input_revision", -1)), "previewed": null}
		chapter2_panel_requested.emit(view)
		return {"accepted": true, "chapter2_panel_requested": true, "physical_commit": false, "reason": "Choose the inputs before confirming."}
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) == "P-02" and hud != null and hud.open_mission_table(String(selected.target_id)):
		return {"accepted": true, "reason": "Mission Table open.", "mission_table": true}
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) in ["P-05", "P-06"] and hud != null and hud.open_chapter3_panel(String(selected.target_id)):
		return {"accepted": true, "reason": "Decision card open.", "chapter3_panel": true}
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) in ["P-07", "P-08"] and hud != null and hud.open_chapter4_panel(String(selected.target_id)):
		return {"accepted": true, "reason": "Decision card open.", "chapter4_panel": true}
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) in ["P-11", "P-12"] and hud != null and hud.open_chapter6_panel(String(selected.target_id)):
		return {"accepted": true, "reason": "Decision card open.", "chapter6_panel": true}
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) in ["P-15", "P-16"] and hud != null and hud.open_chapter8_panel(String(selected.target_id)):
		return {"accepted": true, "reason": "Decision card open.", "chapter8_panel": true}
	if not selected.is_empty():
		return perform_target(String(selected.target_id))
	var dock_interacted := _interact_garage_dock()
	if not dock_interacted.is_empty():
		return dock_interacted
	var result := {"accepted": false, "reason": "Walk up to the next job and face it. Press H to see where it is."}
	if hud != null:
		hud.show_status(result.reason)
	return result

func _physics_process(delta: float) -> void:
	if loading:
		return
	if not _ui_paused and not is_cutscene_active():
		_play_time_seconds += maxf(0.0, delta)
	if _room == null:
		return
	var selected := nearby_target()
	_room.set_focus_target(String(selected.get("world_focus_id", "")))
	if _terrain != null and _player != null:
		_terrain.move_focus(_terrain.to_local(_player.global_position))
	_step_campaign_eva()
	if field_systems != null:
		field_systems.step(delta)
	if _progression_flow != null and not _ui_paused and not is_cutscene_active():
		_progression_flow.step(delta)
	if hud != null:
		hud.show_nearby_forecast(String(selected.get("target_id", "")))

func _step_campaign_eva() -> void:
	if _player == null or eva_suit == null:
		return
	if not eva_suit.indoor:
		var field: TerrainHeightfield = _terrain.stream.field if _terrain != null and _terrain.get("stream") != null and _terrain.stream.get("field") != null else null
		if field != null:
			var p: Vector3 = _terrain.origin + _terrain.turn * _terrain.to_local(_player.global_position)
			_player.eva_slope_override_deg = field.slope_deg_at(p.x, p.z)
			_player.eva_surface_tags = _terrain_surface_tags_at(_player.global_position.x, _player.global_position.z, field, _collect_real_boulder_zones(_player.global_position, 6.0), _is_scene_in_cold_shadow())
		else:
			_player.eva_slope_override_deg = -1.0
			_player.eva_surface_tags = _fallback_surface_tags_at(_player.global_position.x, _player.global_position.z, _collect_real_boulder_zones(_player.global_position, 6.0), _is_scene_in_cold_shadow())
		if eva_suit.scanner_pulse_active and (eva_suit.last_scan_samples.is_empty() or _player.global_position.distance_to(_last_scan_origin) > 1.5):
			_last_scan_origin = _player.global_position
			_scan_campaign_terrain(_player.global_position)
	elif eva_suit.scanner_pulse_active and eva_suit.last_scan_samples.is_empty():
		_last_scan_origin = _player.global_position
		_scan_campaign_terrain(_player.global_position)

func _scan_campaign_terrain(origin_world: Vector3) -> Array:
	if eva_suit == null:
		return []
	var field: TerrainHeightfield = _terrain.stream.field if _terrain != null and _terrain.get("stream") != null and _terrain.stream.get("field") != null else null
	var boulder_zones := _collect_real_boulder_zones(origin_world, 20.0)
	var cold_shadow := _is_scene_in_cold_shadow()
	var sample_h: Callable
	var sample_tags: Callable
	if field != null:
		sample_h = func(wx: float, wz: float) -> float:
			var local_pt := _terrain.to_local(Vector3(wx, 0.0, wz))
			var region_pt: Vector3 = _terrain.origin + _terrain.turn * local_pt
			return field.height_at(region_pt.x, region_pt.z)
		sample_tags = func(wx: float, wz: float) -> Array:
			return _terrain_surface_tags_at(wx, wz, field, boulder_zones, cold_shadow)
	else:
		sample_h = func(wx: float, wz: float) -> float:
			return _sample_world_floor_height(wx, wz, origin_world.y)
		sample_tags = func(wx: float, wz: float) -> Array:
			return _fallback_surface_tags_at(wx, wz, boulder_zones, cold_shadow)
	return eva_suit.scan_grid(origin_world, sample_h, sample_tags)

func _sample_world_floor_height(wx: float, wz: float, fallback_y: float) -> float:
	if _room != null:
		return _room.global_position.y
	if is_inside_tree() and get_world_3d() != null and get_world_3d().direct_space_state != null:
		var exclude: Array[RID] = []
		if _player != null:
			exclude.append(_player.get_rid())
		var query := PhysicsRayQueryParameters3D.create(
			Vector3(wx, fallback_y + 12.0, wz),
			Vector3(wx, fallback_y - 12.0, wz),
			1,
			exclude
		)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.get("position") is Vector3 and hit.get("normal") is Vector3:
			if (hit.normal as Vector3).y > 0.7:
				return (hit.position as Vector3).y
	return fallback_y

func _is_scene_in_cold_shadow() -> bool:
	if route == null or eva_suit == null or eva_suit.indoor:
		return false
	var scene_id := String(route.current_scene_id())
	var seg := _current_terrain_segment()
	var row := RoomContract.Heightfield.scene_lighting(scene_id, seg)
	if not row.is_empty():
		return String(row.get("sun_state", "")) == "dark"
	if _room != null:
		var room_light := RoomContract.terrain_lighting(_room.room_id, scene_id, seg)
		if String(room_light.get("sun_state", "")) == "dark":
			return true
	return false

func _is_on_graded_fixture(wx: float, wz: float) -> bool:
	if _room == null or _room.get("_layout") == null:
		return false
	var room_pt := _room.to_local(Vector3(wx, 0.0, wz))
	var layout: Dictionary = _room._layout
	for lane in layout.get("clear_lanes", []):
		if lane is Dictionary and lane.get("from") is Array and lane.get("to") is Array:
			var a := Vector2(float(lane.from[0]), float(lane.from[2]))
			var b := Vector2(float(lane.to[0]), float(lane.to[2]))
			var p := Vector2(room_pt.x, room_pt.z)
			var ab := b - a
			var len_sq := ab.length_squared()
			var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0) if len_sq > 0.0001 else 0.0
			var closest := a + ab * t
			if p.distance_to(closest) <= float(lane.get("radius_m", 3.0)):
				return true
	var stage_fixtures: Array = _room.stage().get("fixtures", []) if _room.has_method("stage") else []
	for spec in layout.get("fixtures", []) + stage_fixtures:
		if not spec is Dictionary or not spec.get("position") is Array or not spec.get("size") is Array:
			continue
		var id := String(spec.get("id", "")).to_lower()
		if not (id.contains("road") or id.contains("pad") or id.contains("track") or id.contains("apron")):
			continue
		var pos: Array = spec.position
		var sz: Array = spec.size
		if absf(room_pt.x - float(pos[0])) <= float(sz[0]) * 0.5 and absf(room_pt.z - float(pos[2])) <= float(sz[2]) * 0.5:
			return true
	return false

func _collect_real_boulder_zones(origin_world: Vector3, search_radius_m: float) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	# 1. Real scattered lunar rocks from TerrainStream (LunarScatter placements on LOLA heightfield)
	if _terrain != null and _terrain.get("stream") != null and _terrain.stream.get("field") != null and _terrain.stream.has_method("rock_records"):
		var stream: Node3D = _terrain.stream
		var chunk_m := float(stream.config.get("rock_chunk_m", 64.0))
		if chunk_m > 0.0:
			var center_local := _terrain.to_local(origin_world)
			var center_reg: Vector3 = _terrain.origin + _terrain.turn * center_local
			var min_cell := Vector2i(floori((center_reg.x - search_radius_m) / chunk_m), floori((center_reg.z - search_radius_m) / chunk_m))
			var max_cell := Vector2i(floori((center_reg.x + search_radius_m) / chunk_m), floori((center_reg.z + search_radius_m) / chunk_m))
			var inv_turn: Basis = _terrain.turn.inverse()
			for cz in range(min_cell.y, max_cell.y + 1):
				for cx in range(min_cell.x, max_cell.x + 1):
					var records: Array = stream.call("rock_records", Vector2i(cx, cz))
					for rec in records:
						if not rec is Dictionary or not rec.get("position") is Vector3:
							continue
						var reg_pos: Vector3 = rec.position
						var terrain_local: Vector3 = inv_turn * (reg_pos - _terrain.origin)
						var world_pos: Vector3 = _terrain.to_global(terrain_local)
						var rad := maxf(0.5, float(rec.get("radius_m", rec.get("size_m", 1.0))))
						if Vector2(world_pos.x - origin_world.x, world_pos.z - origin_world.z).length() <= search_radius_m + rad:
							zones.append({"x": world_pos.x, "z": world_pos.z, "radius_m": rad})
	# 2. Real authored room obstacles and rock/boulder nodes in _room
	if _room != null:
		if _room.get("_layout") is Dictionary:
			var stage_obs: Array = _room.stage().get("obstacles", []) if _room.has_method("stage") else []
			for obs in _room._layout.get("obstacles", []) + stage_obs:
				if not obs is Dictionary or not obs.get("position") is Array or not obs.get("size") is Array:
					continue
				var obs_local := Vector3(float(obs.position[0]), float(obs.position[1]), float(obs.position[2]))
				var obs_world := _room.to_global(obs_local)
				var obs_rad := maxf(float(obs.size[0]), float(obs.size[2])) * 0.5
				if Vector2(obs_world.x - origin_world.x, obs_world.z - origin_world.z).length() <= search_radius_m + obs_rad:
					zones.append({"x": obs_world.x, "z": obs_world.z, "radius_m": obs_rad})
		if _room.visual_root != null:
			for child in _room.visual_root.get_children():
				if not child is Node3D:
					continue
				var cname := String(child.name).to_lower()
				if cname.contains("rock") or cname.contains("boulder"):
					var cpos := (child as Node3D).global_position
					var crad := float(child.get_meta("radius_m", 1.5))
					zones.append({"x": cpos.x, "z": cpos.z, "radius_m": crad})
	return zones

func _has_boulder_near(wx: float, wz: float, boulder_zones: Array[Dictionary]) -> bool:
	var pt := Vector2(wx, wz)
	for z in boulder_zones:
		var center := Vector2(float(z.get("x", 0.0)), float(z.get("z", 0.0)))
		if pt.distance_to(center) <= float(z.get("radius_m", 1.0)) + 1.5:
			return true
	return false

func _terrain_surface_tags_at(wx: float, wz: float, field: TerrainHeightfield, boulder_zones: Array[Dictionary], cold_shadow: bool) -> Array:
	var local_pt := _terrain.to_local(Vector3(wx, 0.0, wz))
	var region_pt: Vector3 = _terrain.origin + _terrain.turn * local_pt
	var tags: Array = []
	if field.slope_deg_at(region_pt.x, region_pt.z) >= 8.0 and not _is_on_graded_fixture(wx, wz):
		tags.append("soft_regolith")
	if _has_boulder_near(wx, wz, boulder_zones):
		tags.append("boulder")
	if cold_shadow:
		tags.append("cold_shadow")
	return tags

func _fallback_surface_tags_at(wx: float, wz: float, boulder_zones: Array[Dictionary], cold_shadow: bool) -> Array:
	var tags: Array = []
	if _has_boulder_near(wx, wz, boulder_zones):
		tags.append("boulder")
	if cold_shadow and not eva_suit.indoor:
		tags.append("cold_shadow")
	return tags

func is_chapter_complete() -> bool:
	if route == null:
		return false
	var scene_id: String = route.current_scene_id()
	return scene_id.ends_with("-S12") and route.completed_scene_ids().has(scene_id)

func is_campaign_complete() -> bool:
	if route == null:
		return false
	var scene_id: String = route.current_scene_id()
	return scene_id == "EX-CH08-S12" and route.completed_scene_ids().has(scene_id)

func set_ui_paused(value: bool) -> void:
	_ui_paused = value
	if route != null:
		route.pause("reading_panel") if value else route.resume()
	if _crew != null:
		_crew.set_paused(value or is_cutscene_active())
	if audio != null:
		audio.set_paused(value)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func retry_checkpoint() -> Dictionary:
	_chapter2_pending = {}
	_class_team_signoffs.clear()
	var result: Dictionary = route.retry()
	if bool(result.get("accepted", false)):
		_sync_route_projection()
		_refresh_world()
	if hud != null:
		hud.refresh_scene(result)
		hud.show_status(String(result.get("reason", "Checkpoint restored.")))
	if bool(result.get("accepted", false)):
		_save_campaign()
	return result

func acknowledge_dialogue(line_id: String) -> Dictionary:
	var result: Dictionary = route.acknowledge_dialogue(line_id)
	if hud != null:
		hud.refresh_after_action(result)
	if bool(result.get("accepted", false)) and not bool(result.get("duplicate", false)):
		_save_campaign()
	return result

func advance_scene() -> Dictionary:
	if loading:
		return {"accepted": false, "reason": "Preparing Aurora."}
	# M1-49: at the end of EX-CH01-S12 the four mugs gain names
	# (CH01-MUGS-NAMED). Recorded while S12 is still the current scene so
	# the director accepts the moment; it never gates the advance.
	var mugs_named: Dictionary = {}
	if director != null and route != null and not is_chapter_complete() and route.current_scene_id() == "EX-CH01-S12" and route.has_method("mugs_named_moment_command"):
		var moment: Dictionary = route.mugs_named_moment_command()
		if not moment.is_empty():
			mugs_named = director.commit(moment)
			if not bool(mugs_named.get("accepted", false)):
				push_warning("CH01-MUGS-NAMED was not recorded: " + String(mugs_named.get("reason", "unknown")))
	var previous_mission: String = route.current_mission_id()
	var result: Dictionary
	if is_chapter_complete():
		result = _transition_after_chapter()
	else:
		result = route.advance_scene()
	if bool(result.get("accepted", false)):
		_class_team_signoffs.clear()
	if not mugs_named.is_empty():
		result["mugs_named"] = mugs_named
	if bool(result.get("accepted", false)) and bool(result.get("chapter_complete", false)) and not bool(result.get("campaign_complete", false)):
		_sync_route_projection()
		result["next_chapter"] = _transition_after_chapter()
	elif bool(result.get("accepted", false)):
		_sync_route_projection()
		_refresh_world()
	if bool(result.get("accepted", false)) and bool(result.get("campaign_complete", false)):
		_queue_cutscenes("campaign_complete")
		if audio != null:
			audio.play_credits()
	var mission_ended: bool = bool(result.get("accepted", false)) and (route.current_mission_id() != previous_mission or is_chapter_complete() or bool(result.get("chapter_complete", false)))
	if mission_ended and _progression_flow != null:
		_progression_flow.record_mission(previous_mission)
	if hud != null:
		hud.refresh_scene(result)
		var pending := available_upgrade_chapter()
		var learned_chapter := pending if pending > 0 else (8 if bool(result.get("campaign_complete", false)) else 0)
		if bool(result.get("chapter_complete", false)) and learned_chapter > 0 and hud.has_method("open_chapter_learning") and hud.open_chapter_learning(learned_chapter, pending):
			pass
		elif (bool(result.get("chapter_complete", false)) or bool(result.get("upgrade_pending", false))) and pending > 0 and hud.has_method("open_upgrade"):
			hud.open_upgrade(pending)
	_save_campaign("mission_end" if mission_ended else "scene_join")
	return result

func _start_chapter2() -> Dictionary:
	_sync_route_projection()
	var next_route = Chapter2RouteScript.new(director)
	var entry: Dictionary = next_route.apply_entry_profile()
	if not bool(entry.get("accepted", false)):
		return entry
	route = next_route
	var started: Dictionary = route.start_at("EX-CH02-S01")
	_sync_route_projection()
	_refresh_world()
	started["chapter_started"] = "CH02"
	return started

func _transition_after_chapter() -> Dictionary:
	var pending := available_upgrade_chapter()
	if pending > 0:
		return {"accepted": false, "upgrade_pending": true, "chapter": pending, "reason": "Choose your earned upgrade before the next chapter."}
	var chapter := _chapter_number()
	if chapter == 1:
		return _start_chapter2()
	if chapter == 2:
		return _start_extended("EX-CH03-S01")
	if chapter >= 3 and chapter < 8 and route.has_method("start_at"):
		return _start_extended("EX-CH%02d-S01" % (chapter + 1))
	return {"accepted": true, "chapter_complete": true, "campaign_complete": true, "reason": "The eight-chapter campaign is complete."}

func _start_extended(scene_id: String) -> Dictionary:
	_sync_route_projection()
	if not route is ExtendedCampaignRoute:
		route = ExtendedRouteScript.new(director)
	var started: Dictionary = route.start_at(scene_id)
	_sync_route_projection()
	_refresh_world()
	started["chapter_started"] = String(scene_id.substr(3, 4))
	return started

## Inbox writes use the bounded Director API and the existing checkpoint store.
func message_metadata() -> Dictionary:
	return director.message_metadata() if director != null else {"delivered_ids": [], "read_ids": []}

func update_message_metadata(metadata: Dictionary) -> Dictionary:
	if director == null or route == null or save_service == null or not _startup_error.is_empty():
		return {"accepted": false, "persisted": false, "reason": "The expedition is not ready to save messages."}
	var result := director.update_message_metadata(metadata)
	result["persisted"] = false
	if bool(result.get("accepted", false)):
		var saved := _save_campaign()
		result["persisted"] = bool(saved.get("accepted", false))
		if not result.persisted:
			result["reason"] = "Messages remain available in this game, but could not be saved. " + String(saved.get("reason", "Try Save again."))
	return result

func save_campaign() -> Dictionary:
	var result := _save_campaign()
	if hud != null:
		hud.show_status(("CHECKPOINT SAVED · " if bool(result.get("accepted", false)) else "SAVE FAILED · ") + String(result.get("reason", "verified")))
	return result

## Routes decision previews without writes and confirmed choices to the director.
func handle_ui_command(command: Dictionary, preview_only: bool = false) -> Dictionary:
	var verb := String(command.get("verb", ""))
	var payload: Dictionary = command.get("payload", {}) if command.get("payload", {}) is Dictionary else {}
	if verb in ["preview_puzzle", "record_choice"]:
		var choice: Dictionary = current_scene_data().get("choice", {})
		var choice_id := String(payload.get("choice_id", ""))
		var valid_scene_choice: bool = (_chapter_number() == 1 and choice_id == String(choice.get("id", ""))) or (route != null and String(route.current_scene_id()) == "EX-CH03-S11" and choice_id == "EX-CH03-S11-DEDICATION")
		if not valid_scene_choice or not payload.get("option_id") is String:
			return {"accepted": false, "reason": "This decision does not belong to the current Chapter 1 scene."}
		var problem := CampaignState.story_choice_problem(choice_id, String(payload.option_id))
		if not problem.is_empty():
			return {"accepted": false, "reason": problem}
		if verb == "preview_puzzle":
			return {"accepted": true, "reason": "Decision preview only; no story record changed."}
		var result: Dictionary = director.preview(command) if preview_only else director.commit(command)
		if bool(result.get("accepted", false)) and not preview_only and _room != null:
			var story_log: Dictionary = director.snapshot().get("story_log", {})
			_room.set_story_choices(story_log.get("choices", {}), story_log.get("moments", []))
		if hud != null and not preview_only:
			hud.refresh_after_action(result)
		if bool(result.get("accepted", false)) and not preview_only and not bool(result.get("duplicate", false)):
			_save_campaign()
		return result
	if verb == "acknowledge_line":
		return acknowledge_dialogue(String(payload.get("line_id", command.get("target_id", ""))))
	if verb == "set_accessibility":
		var next := director.snapshot()
		var accessibility: Dictionary = next.get("accessibility", {}).duplicate(true)
		accessibility.merge(payload, true)
		if accessibility.has("assist_mode") and not String(accessibility.assist_mode) in ["Story", "Cadet", "Expedition"]:
			return {"accepted": false, "reason": "Choose Story, Cadet or Expedition assistance."}
		next["accessibility"] = accessibility
		var restored := director.restore_snapshot(next)
		if eva_suit != null:
			eva_suit.set_assist_mode(String(payload.get("assist_mode", eva_suit.assist_mode)))
		_save_campaign()
		if audio != null:
			audio.captions_enabled = bool(payload.get("captions", true))
		if hud != null:
			hud.apply_accessibility()
		return restored
	if verb == "set_assist_mode":
		return handle_ui_command({"verb": "set_accessibility", "payload": {"assist_mode": String(payload.get("mode", payload.get("assist_mode", "Cadet")))}})
	if verb in ["plant_care", "harvest_plant"]:
		return _plant_ui_command(verb, payload, preview_only)
	if verb in ["board_rover", "exit_rover", "toggle_rover_camera", "toggle_headlights", "pickup_supply", "place_structure", "secure_item"]:
		if preview_only:
			return {"accepted": false, "reason": "Use the live field controls to perform this action."}
		return handle_field_command(command)
	return {"accepted": false, "reason": "The campaign runtime does not own UI command " + verb}

## Leaves only after the checkpoint is written. A failed save keeps the live
## session open; pressing TITLE again is the explicit choice to leave without it.
func exit_to_title() -> void:
	if _startup_error.is_empty() and not _exit_without_save_armed:
		var saved := _save_campaign()
		if not bool(saved.get("accepted", false)):
			_exit_without_save_armed = true
			if hud != null:
				hud.show_status("SAVE FAILED · %s\nYour game is still open. Choose Save to try again, or Save and quit again to leave without saving." % String(saved.get("reason", "unknown error")))
			return
	exit_requested.emit()

func _save_snapshot() -> Dictionary:
	var snapshot := director.snapshot()
	snapshot["paused"] = false
	snapshot["route_runtime"] = route.snapshot()
	snapshot["route_runtime"]["chapter"] = _chapter_number()
	var resume: Dictionary = snapshot.get("presentation_resume", {}).duplicate(true)
	if field_systems != null:
		resume["field_systems"] = field_systems.snapshot()
		resume["lunar_network"] = field_systems.network.to_dict()
	if _progression_flow != null:
		resume.merge(_progression_flow.snapshot(), true)
	snapshot["presentation_resume"] = resume
	if save_slots != null:
		snapshot = save_slots.enrich_snapshot(snapshot, SaveSlotsScript.AUTOSAVE_SLOT, _last_autosave_trigger, _play_time_seconds)
	if _room != null and _room.room_id == "LOC-08" and _room.garage() != null:
		snapshot["route_runtime"]["garage_dock"] = _room.garage().dock_snapshot()
	return snapshot

func _chapter_number() -> int:
	if route == null:
		return 1
	var scene_id: String = route.current_scene_id()
	return int(scene_id.substr(5, 2)) if scene_id.length() >= 7 else 1

func _sync_route_projection() -> void:
	if director == null or route == null:
		return
	var next := director.snapshot()
	var chapter_number := _chapter_number()
	next["chapter_id"] = "CH%02d" % chapter_number
	next["mission_id"] = route.current_mission_id()
	next["scene_id"] = route.current_scene_id()
	next["checkpoint_id"] = route.current_scene_id() + "-CHECKPOINT"
	var campaign_completed: Array = next.get("completed_scene_ids", []).duplicate()
	for completed_scene_id in route.completed_scene_ids():
		if not campaign_completed.has(completed_scene_id):
			campaign_completed.append(completed_scene_id)
	next["completed_scene_ids"] = campaign_completed
	next["scene_phase"] = "chapter_complete" if is_chapter_complete() else "briefing"
	if chapter_number >= 2:
		next["chapter1_ready"] = true
	var result := director.restore_snapshot(next)
	if not bool(result.get("accepted", false)):
		push_warning("Unable to synchronize the saved campaign scene projection: " + String(result.get("reason", "unknown")))

## Every autosave goes through here, so a failure is always shown to the player.
func _save_campaign(trigger: String = "checkpoint") -> Dictionary:
	if not _startup_error.is_empty():
		return {"accepted": false, "reason": _startup_error}
	_last_autosave_trigger = trigger
	if save_slots != null:
		save_slots.base_save_path = save_path
	var stamp := LoadTrace.begin()
	var result: Dictionary = save_service.save(_save_snapshot(), save_path)
	LoadTrace.end("campaign_save", stamp)
	if bool(result.get("accepted", false)):
		_exit_without_save_armed = false
	else:
		push_warning("Autosave failed: " + String(result.get("reason", "unknown error")))
		if hud != null:
			hud.show_status("AUTOSAVE FAILED · " + String(result.get("reason", "unknown error")) + " · progress since the last save is not on disk yet.")
	return result

func save_to_slot(slot_id: String, trigger: String = "manual") -> Dictionary:
	if save_slots == null:
		save_slots = SaveSlotsScript.new(save_path, restore_session)
	save_slots.base_save_path = save_path
	var result: Dictionary = save_slots.save_slot(slot_id, _save_snapshot(), trigger, {"play_time_seconds": _play_time_seconds})
	if hud != null and bool(result.get("accepted", false)):
		hud.show_status("SAVED TO " + SaveSlotsScript.slot_label(slot_id).to_upper())
	return result

func load_from_slot(slot_id: String, allow_auto_recover: bool = true) -> Dictionary:
	if save_slots == null:
		save_slots = SaveSlotsScript.new(save_path, restore_session)
	save_slots.base_save_path = save_path
	var loaded: Dictionary = save_slots.load_slot(slot_id, allow_auto_recover)
	if not bool(loaded.get("accepted", false)):
		return loaded
	var snap: Dictionary = loaded.get("snapshot", {})
	var session := restore_session(snap)
	if not bool(session.get("accepted", false)):
		return session
	director = session.director
	route = session.route
	var resume: Dictionary = snap.get("presentation_resume", {})
	var loaded_meta: Variant = resume.get("slot_metadata", {})
	if loaded_meta is Dictionary:
		_play_time_seconds = maxf(0.0, float((loaded_meta as Dictionary).get("play_time_seconds", _play_time_seconds)))
	if field_systems != null:
		field_systems.restore(resume.get("field_systems", {}))
	if _progression_flow != null:
		_progression_flow.restore(resume)
		progression = _progression_flow.model
	_sync_route_projection()
	_refresh_world()
	if hud != null:
		hud.refresh_scene(loaded)
	return loaded

func _fail_startup(reason: String) -> void:
	_startup_error = reason
	var layer := CanvasLayer.new()
	add_child(layer)
	var page := VBoxContainer.new()
	page.position = Vector2(80, 180)
	page.size = Vector2(960, 300)
	layer.add_child(page)
	var message := Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.text = "CHECKPOINT COULD NOT BE OPENED\n" + reason + "\nYour saved files have been preserved."
	page.add_child(message)
	var back := Button.new()
	back.text = "RETURN TO TITLE"
	back.pressed.connect(func() -> void: exit_requested.emit())
	page.add_child(back)
	back.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if loading or _ui_paused or _player == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_player.follow_camera.look(event.screen_relative * _player.follow_camera.mouse_sensitivity)
		if hud != null and hud.has_method("offer_first_time"):
			hud.offer_first_time("look")
	elif event.is_action_pressed("interact") and not event.is_echo():
		var job_result: Dictionary = _progression_flow.interact_job() if _progression_flow != null else {}
		if not bool(job_result.get("handled", false)):
			if field_systems != null and field_systems.rover.aboard:
				handle_field_command({"verb": "exit_rover", "payload": {}})
			else:
				interact_nearby()
		elif hud != null:
			hud.show_status(String(job_result.get("reason", "")))
		if hud != null and hud.has_method("offer_first_time"):
			hud.offer_first_time("use")
		get_viewport().set_input_as_handled()

func _refresh_world() -> void:
	if incremental_loading:
		var plants: Array = director.snapshot().get("plants", []) if director != null else []
		if not loading and preparation.room_ready(route.current_room_id(), route.current_scene_id(), plants) and not _terrain_wanted():
			_refresh_world_now()
			_on_scene_ready()
			_prefetch_next_room()
		elif not loading:
			loading = true
			_transition_card = LoadingCard.new()
			add_child(_transition_card)
			_rebuild_transition()
		return
	_refresh_world_now()
	_on_scene_ready()

func _refresh_world_now(incremental_assets: bool = false) -> void:
	var stamp := LoadTrace.begin()
	if incremental_loading:
		var plants: Array = director.snapshot().get("plants", []) if director != null else []
		preparation.activate_room(route.current_room_id(), route.current_scene_id(), plants)
	if not incremental_assets:
		_clear_terrain()  # only the incremental entry prepares terrain; this path builds the flat fallback floor
	if _room != null and is_instance_valid(_room):
		remove_child(_room)
		_room.queue_free()
		_room = null
	var room_path: String = LoadPreparation.ROOM_SCENES.get(route.current_room_id(), "")
	if room_path.is_empty():
		_room = CampaignRoom.new()
		_room.room_id = route.current_room_id()
	else:
		var scene := preparation.resources[room_path] as PackedScene if incremental_loading else load(room_path) as PackedScene
		_room = scene.instantiate() as CampaignRoom
	_room.upcoming_scene = route.current_scene_id()
	_room.terrain_segment = _current_terrain_segment()
	_room.load_approved_assets = not incremental_assets
	_room.terrain_ground = _terrain != null
	add_child(_room)
	if incremental_assets:
		_room.load_approved_assets = true
	if not incremental_assets:
		_place_crew()
	LoadTrace.end("room_rebuild", stamp)

func _place_crew() -> void:
	var stamp := LoadTrace.begin()
	var anchors: Dictionary = RoomContract.anchors(route.current_room_id())
	var anchor_id: String = {"LOC-01": "commons_player", "LOC-02": "service_player", "LOC-03": "garden_player", "LOC-04": "safe_player", "LOC-06": "exterior_player"}.get(route.current_room_id(), "")
	var player_anchor: Array = anchors.get(anchor_id, [])
	if player_anchor.is_empty():
		for candidate in anchors.keys():
			if String(candidate).ends_with("_player"):
				player_anchor = anchors[candidate]
				break
	if player_anchor.is_empty():
		player_anchor = [0.0, 0.0, 2.0]
	if _crew == null:
		_crew = CampaignCrew.new()
		_crew.name = "Crew"
		add_child(_crew)
	var story_log: Dictionary = director.snapshot().get("story_log", {}) if director != null else {}
	_player = _crew.place(route.current_scene_id(), _room, Vector3(player_anchor[0], player_anchor[1], player_anchor[2]), story_log.get("choices", {}), story_log.get("moments", []))
	_player.generic_interaction_input = false
	_bind_player_eva()
	if field_systems != null:
		field_systems.bind_scene()
	if _player != null and _player.follow_camera != null and _player.follow_camera.camera != null:
		_player.follow_camera.camera.far = 30000.0 if _terrain != null else 4000.0  # kilometre views on the terrain
		if game_settings != null:
			_player.follow_camera.camera.fov = float(game_settings.display.get("fov", 75.0))
	_crew.set_paused(_ui_paused)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_garage_dock()
	_sync_world_boundaries()
	LoadTrace.end("campaign_place_crew", stamp)

func _bind_player_eva() -> void:
	if eva_suit == null:
		var mode := String(director.snapshot().get("accessibility", {}).get("assist_mode", "Cadet")) if director != null else "Cadet"
		eva_suit = EvaSuitScript.new(mode)
	var room_id: String = _room.room_id if _room != null else (String(route.current_room_id()) if route != null else "LOC-01")
	var pressure := String(RoomContract.room(room_id).get("pressure", "pressurised"))
	var was_indoor := eva_suit.indoor
	var now_indoor := pressure != "vacuum"
	eva_suit.indoor = now_indoor
	if _last_eva_room_id != room_id and (now_indoor or was_indoor):
		eva_suit.reset_budget()
	_last_eva_room_id = room_id
	if _player != null:
		_player.eva_suit = eva_suit
		_player.gravity = EvaSuitScript.MOON_G
		if now_indoor:
			_player.eva_surface_tags = []
			_player.eva_slope_override_deg = -1.0

func _current_terrain_segment() -> String:
	if route == null or route.current_scene_id() != "EX-CH04-S04":
		return ""
	var flags: Dictionary = route.current_flags() if route.has_method("current_flags") else route.gate_status().get("physical_flags", {})
	if not bool(flags.get("p07_place_beacon_1_done", false)):
		return "B1"
	if not bool(flags.get("p07_place_beacon_2_done", false)):
		return "B2"
	return "B3"

func _segment_cruise_card(from_segment: String, to_segment: String) -> String:
	if from_segment == "B1" and to_segment == "B2":
		return "ROVER CRUISE · 1.02 KM TO 1.88 KM (B1 → B2)"
	if from_segment == "B2" and to_segment == "B3":
		return "ROVER CRUISE · 1.88 KM TO 5.24 KM (B2 → B3)"
	return "ROVER CRUISE · %s → %s" % [from_segment, to_segment]

func _setup_garage_dock() -> void:
	if _room == null or _room.room_id != "LOC-08":
		_saved_garage_dock = {}
		return
	var bay := _room.garage()
	if bay == null:
		return
	if not _saved_garage_dock.is_empty():
		bay.dock_restore(_saved_garage_dock)
		_saved_garage_dock = {}
	if not bay.dock_state_changed.is_connected(_on_garage_dock_state_changed):
		bay.dock_state_changed.connect(_on_garage_dock_state_changed)
	if not bay.dock_cycle_finished.is_connected(_on_garage_dock_cycle_finished):
		bay.dock_cycle_finished.connect(_on_garage_dock_cycle_finished)
	_sync_garage_dock_boundary(bay)

func _on_garage_dock_state_changed(_text: String) -> void:
	if _room != null and _room.garage() != null:
		_sync_garage_dock_boundary(_room.garage())
		_sync_world_boundaries()

func _on_garage_dock_cycle_finished(_side: String) -> void:
	if _room != null and _room.garage() != null:
		_sync_garage_dock_boundary(_room.garage())
		_sync_world_boundaries()

func _sync_garage_dock_boundary(bay: Node3D) -> void:
	if route == null or bay == null:
		return
	var safe: bool = bay.dock_state() == "SAFE TO OPEN"
	route.world().set_boundary_state("garage_dock_hatch", {"airlock_ready": safe, "open": safe and bay.is_dock_hatch_open()})

func _interact_garage_dock() -> Dictionary:
	if _room == null or _room.room_id != "LOC-08" or _room.garage() == null or _player == null:
		return {}
	var target := _focus_node("garage_dock")
	if target == null or _player.global_position.distance_to(target.global_position) > 3.0:
		return {}
	var camera := _player.follow_camera.camera
	if camera != null and not camera.is_position_in_frustum(target.global_position):
		return {}
	if not _has_line_of_sight(target):
		return {}
	var bay := _room.garage()
	if bay.dock_state() != "SAFE TO OPEN":
		var cycled: Dictionary = bay.request_dock_cycle("habitat")
		var card: String = bay.time_card()
		if hud != null and not card.is_empty():
			hud.show_status(card)
		_save_campaign()
		return {"accepted": bool(cycled.get("accepted", false)), "dock_cycling": true, "time_card": card, "reason": card if not card.is_empty() else String(cycled.get("reason", "Equalising the rover dock tunnel."))}
	var opened: Dictionary = route.world().set_boundary_state("garage_dock_hatch", {"airlock_ready": true, "open": not bay.is_dock_hatch_open()})
	_sync_world_boundaries()
	_save_campaign()
	return opened

func _refresh_world_incremental() -> void:
	await get_tree().process_frame
	await preparation.prepare_scene_media(route.current_scene_id())
	var plants: Array = director.snapshot().get("plants", []) if director != null else []
	if not await preparation.prepare_room(route.current_room_id(), route.current_scene_id(), plants):
		_fail_startup(preparation.failed)
		return
	await _prepare_terrain()
	await get_tree().process_frame
	_refresh_world_now(true)
	await get_tree().process_frame
	await _room.load_assets_incremental()
	await get_tree().process_frame
	_place_crew()
	await get_tree().process_frame
	# First real room draw (including its lighting/layout variants) is covered.
	if DisplayServer.get_name() != "headless":
		await preparation.wait_for_draw("room_first_draw:" + route.current_room_id())

func _terrain_wanted() -> bool:
	return incremental_loading and bool(RoomContract.terrain_lighting(route.current_room_id(), route.current_scene_id(), _current_terrain_segment()).get("ready", false))

func _clear_terrain() -> void:
	if _terrain != null:
		remove_child(_terrain)
		_terrain.queue_free()
		_terrain = null

## Behind the loading card: a ready exterior stands on the LOLA terrain with its dated Sun and Earth; anything the
## session refuses keeps the room's flat staging floor (never a guessed sky).
func _prepare_terrain() -> void:
	_clear_terrain()
	if not _terrain_wanted():
		return
	_terrain = TerrainSessionScript.new()
	_terrain.name = "Terrain"
	add_child(_terrain)
	var result: Dictionary = await _terrain.prepare_incremental(route.current_room_id(), route.current_scene_id(), _current_terrain_segment())
	if not bool(result.get("enabled", false)):
		push_warning("Terrain kept flat for %s: %s" % [route.current_room_id(), String(result.get("reason", ""))])
		_clear_terrain()

func _rebuild_transition() -> void:
	await get_tree().process_frame
	var was_paused := _ui_paused
	set_ui_paused(true)
	await _refresh_world_incremental()
	set_ui_paused(was_paused)
	await get_tree().process_frame
	if hud != null:
		await hud.refresh_scene({}, true)
	await get_tree().process_frame
	_transition_card.queue_free()
	_transition_card = null
	loading = false
	_on_scene_ready()
	if hud != null:
		hud._render_caption()
		hud._offer_resume_card()
	_prefetch_next_room()

## Scene order is data-owned. Start the next room while the current scene is
## playable, so walking to its exit overlaps decoding instead of waiting for it.
func _prefetch_next_room() -> void:
	if preparation == null or loading or preparation.preparing:
		return
	var scenes: Array = content.get("scenes", [])
	for index in scenes.size() - 1:
		if scenes[index].get("id", "") == route.current_scene_id():
			var next_id := String(scenes[index + 1].get("id", ""))
			var roster := CompanionRosterScript.scene_roster(next_id)
			var actor := CompanionRosterScript.playable_actor(next_id)
			var next_room := String(roster.get(actor, {}).get("physical_location_id", ""))
			if not next_room.is_empty() and next_room != _lookahead_room:
				_lookahead_room = next_room
				_prefetch_room_and_media(next_room, next_id)
			return

func _prefetch_room_and_media(room_id: String, scene_id: String) -> void:
	var plants: Array = director.snapshot().get("plants", []) if director != null else []
	await preparation.prepare_room(room_id, scene_id, plants)
	await preparation.prepare_scene_media(scene_id)
	if audio != null:
		await audio.prefetch(scene_id, RoomContract.room_for_scene(scene_id))

func _sync_world_boundaries() -> void:
	if _room == null:
		return
	_room.apply_plant_state(director.snapshot().get("plants", []))
	for boundary_id in RoomContract.room(_room.room_id).get("boundary_ids", []):
		var state: Dictionary = route.world().boundary_state(String(boundary_id))
		_room.set_door_open(String(boundary_id), bool(state.get("open", false)) and not bool(state.get("exposure_lock", false)))

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CampaignHUDLayer"
	add_child(layer)
	var stamp := LoadTrace.begin()
	hud = HUDScene.instantiate() as Chapter1CampaignHUD
	LoadTrace.end("hud_instantiate", stamp)
	stamp = LoadTrace.begin()
	layer.add_child(hud)
	LoadTrace.end("hud_ready", stamp)
	if incremental_loading and is_inside_tree():
		await get_tree().process_frame
	stamp = LoadTrace.begin()
	await hud.setup(self)
	LoadTrace.end("hud_setup", stamp)

func present_dialogue(line: Dictionary) -> void:
	if loading:
		return
	if _crew != null:
		_crew.present_line(line, bool(director.snapshot().get("accessibility", {}).get("reduced_motion", false)))
	if audio != null:
		audio.present_line(line, director.snapshot().get("knowledge_flags", []))

## The current scene's world is ready (new game, Continue, advance, chapter
## change, retry): retarget its sound and open any cutscene bound to its start.
func _on_scene_ready() -> void:
	if route == null or audio == null:
		return
	audio.captions_enabled = bool(director.snapshot().get("accessibility", {}).get("captions", true))
	audio.enter_scene(route.current_scene_id(), route.current_room_id())
	# A scene the player already worked in (Continue after acknowledging a line) does not replay its film.
	if route.gate_status().get("dialogue_acknowledged", []).is_empty():
		_queue_cutscenes("scene_enter")

## Plays each cutscene bound to this beat of the current scene once per session.
func _queue_cutscenes(trigger: String) -> void:
	if cutscenes == null or not CampaignCutscenePlayer.autoplay:
		return
	for plan in cutscenes.plans_for_scene(route.current_scene_id(), trigger, director.snapshot().get("knowledge_flags", [])):
		var id := String(plan.get("cutscene_id", ""))
		if not _played_cutscenes.has(id):
			_played_cutscenes[id] = true
			_cutscene_queue.append(plan)
	_play_next_cutscene()

## True while a film or its text card covers the expedition.
func is_cutscene_active() -> bool:
	return cutscene_player != null and cutscene_player.is_active()

func _play_next_cutscene() -> void:
	if is_cutscene_active() or _cutscene_queue.is_empty():
		return
	_set_cinematic(true)
	var next_plan: Dictionary = _cutscene_queue.pop_front()
	var cid := String(next_plan.get("cutscene_id", ""))
	if game_settings != null and cutscenes != null:
		cutscene_player.skip_hold_s = game_settings.effective_cutscene_skip_hold_s(cid, cutscenes.skip_hold_seconds())
	cutscene_player.play(next_plan)

func _on_cutscene_closed(result: Dictionary) -> void:
	var cid := String(result.get("cutscene_id", ""))
	if game_settings != null and not cid.is_empty():
		game_settings.mark_cutscene_seen(cid)
	audio.mark_heard(cutscenes.heard_line_ids(cid, float(result.get("position_s", 0.0))))
	if _cutscene_queue.is_empty():
		_set_cinematic(false)
	cutscene_closed.emit(result)
	_play_next_cutscene()

func _set_cinematic(value: bool) -> void:
	audio.set_cinematic(value)
	if _crew != null:
		_crew.set_paused(value or _ui_paused)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func completed_chapters() -> Array:
	return _progression_flow.completed_chapters() if _progression_flow != null else []

func available_upgrade_chapter() -> int:
	return _progression_flow.available_upgrade_chapter() if _progression_flow != null else 0

func choose_upgrade(chapter: int, option: String) -> Dictionary:
	if _progression_flow == null:
		return {"accepted": false, "reason": "The cadet record is unavailable."}
	var result: Dictionary = _progression_flow.choose_upgrade(chapter, option)
	if bool(result.get("accepted", false)) and bool(result.get("persisted", true)) and chapter == _chapter_number() and is_chapter_complete():
		if hud != null:
			hud.close_family()
		result["next_chapter"] = _transition_after_chapter()
		if hud != null:
			hud.refresh_scene(result)
	return result

func rest_at_bunk() -> Dictionary:
	return _progression_flow.rest_at_bunk() if _progression_flow != null else {"accepted": false}

func begin_job(job_id: String) -> Dictionary:
	return _progression_flow.begin_job(job_id) if _progression_flow != null else {"accepted": false}

func job_metrics(job_id: String) -> Dictionary:
	return _progression_flow.job_metrics(job_id) if _progression_flow != null else {}

func complete_job(job_id: String, performance: Dictionary = {}) -> Dictionary:
	return _progression_flow.complete_job(job_id, performance) if _progression_flow != null else {"accepted": false}

func save_progression() -> Dictionary:
	return _progression_flow.save_progression() if _progression_flow != null else {"accepted": false}

func handle_field_command(command: Dictionary) -> Dictionary:
	if field_systems == null or loading:
		return {"accepted": false, "reason": "The field is not ready."}
	var result: Dictionary = field_systems.command(String(command.get("verb", "")), command.get("payload", {}))
	if bool(result.get("accepted", false)):
		_save_campaign()
	if hud != null:
		hud.show_status(String(result.get("reason", "Field equipment updated.")))
	return result

func eva_forecast(distance_m: float) -> Dictionary:
	return eva_suit.estimate_route(distance_m, eva_suit.current_slope_deg, 1.0 if _is_scene_in_cold_shadow() else 0.0, eva_suit.payload_mass_kg, eva_suit.current_surface_tags)

func _plant_ui_command(verb: String, payload: Dictionary, preview_only: bool) -> Dictionary:
	var current := director.snapshot()
	var projected := current.duplicate(true)
	projected["paused"] = false
	var staged = DirectorScript.new()
	staged.restore_snapshot(projected)
	var command := {"verb": verb, "payload": payload.duplicate(true), "command_id": "plant-%d-%s" % [int(current.state_revision), str(payload)],
		"issuer": "player", "owning_mission_id": route.current_mission_id(), "owning_scene_id": route.current_scene_id(), "target_id": String(payload.get("individual_id", "")), "expected_state_revision": int(current.state_revision)}
	var result: Dictionary = staged.preview(command) if preview_only else staged.commit(command)
	if bool(result.get("accepted", false)) and not preview_only:
		var next: Dictionary = staged.snapshot()
		next["paused"] = bool(current.get("paused", false))
		director.restore_snapshot(next)
		_sync_world_boundaries()
		_save_campaign()
	return result
