extends Node3D
class_name Chapter1Campaign

signal exit_requested
## Ramim's panel subscribes here. Opening/cancelling never submits choices.
signal p01_panel_requested(view: Dictionary)
## A cutscene closed (watched to the end, skipped, or its text card dismissed).
signal cutscene_closed(result: Dictionary)

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const ExtendedRouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const CompanionRosterScript = preload("res://scripts/companions/companion_roster.gd")
const CutsceneRuntimeScript = preload("res://scripts/cutscenes/cutscene_runtime.gd")
const AudioRuntimeScript = preload("res://scripts/audio/audio_runtime.gd")
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
var hud: Chapter1CampaignHUD
var _room: CampaignRoom
var _crew: CampaignCrew
var _player: PlayerController
var _startup_error := ""
var _ui_paused := false
var _exit_without_save_armed := false
var save_path: String = SaveScript.DEFAULT_PATH
var cutscenes: CampaignCutsceneRuntime
var cutscene_player: CampaignCutscenePlayer
var audio: CampaignAudioDirector
var _cutscene_queue: Array = []
var _played_cutscenes := {}

func _ready() -> void:
	if incremental_loading:
		loading = true
		_ready_incremental()
		return
	_start_session()
	if _startup_error.is_empty():
		_refresh_world()
		_build_hud()
		_save_campaign()

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
	var presentation := director.snapshot()
	presentation["paused"] = false
	for key in initial_accessibility:
		presentation["accessibility"][key] = initial_accessibility[key]
	director.restore_snapshot(presentation)
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
	_start_session()
	if _startup_error.is_empty():
		await _refresh_world_incremental()
		var stamp := LoadTrace.begin()
		_build_hud()
		LoadTrace.end("campaign_ui", stamp)
		await get_tree().process_frame
		_save_campaign()
	loading = false
	_on_scene_ready()
	if hud != null:
		hud.refresh_scene()
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
	return route.targets_for_current_scene() if route != null else []

func query() -> Dictionary:
	var result := director.query()
	result["scene_id"] = route.current_scene_id()
	result["mission_id"] = route.current_mission_id()
	result["room_id"] = route.current_room_id()
	result["objective"] = current_scene_data().get("playerActions", [])
	result["dialogue_lines"] = current_dialogue()
	result["journal_entries"] = CampaignKnowledge.journal(director.snapshot())
	result["accessibility"] = director.snapshot().get("accessibility", {})
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

func perform_target(target_id: String, payload: Dictionary = {}) -> Dictionary:
	if loading or not _startup_error.is_empty() or route == null:
		return {"accepted": false, "reason": "The expedition is unavailable."}
	if is_chapter_complete():
		return {"accepted": false, "reason": "Chapter 1 is complete. Return to title to keep this checkpoint."}
	var target := physical_target(target_id)
	var result: Dictionary
	if target == null or _player == null:
		result = {"accepted": false, "reason": "This operation has no physical target in the current room."}
	else:
		var distance := _player.global_position.distance_to(target.global_position)
		var ray := PhysicsRayQueryParameters3D.create(_player.global_position + Vector3.UP * 1.4, target.global_position, _player.collision_mask, [_player.get_rid()])
		var clear := _player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
		if not clear:
			result = {"accepted": false, "reason": "Move into clear view of " + String(target.get_meta("focus_label", "the target")) + "."}
		else:
			result = route.perform(target_id, payload, {"room_id": _room.room_id, "distance_m": distance, "line_of_sight": clear})
	if result.has("result") and result.result is Dictionary and result.get("accepted", false):
		for key in ["reason", "deltas", "warnings", "ledger_summary"]:
			if result.result.has(key):
				result[key] = result.result[key]
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
			if not bool(flags.get(flag, false)):
				missing = true
		if missing:
			continue
		var target := _focus_node(String(spec.get("world_focus_id", "")))
		if target == null:
			continue
		var distance := _player.global_position.distance_to(target.global_position)
		if distance > float(spec.get("range_m", 3.0)) or distance >= nearest or not camera.is_position_in_frustum(target.global_position):
			continue
		var ray := PhysicsRayQueryParameters3D.create(_player.global_position + Vector3.UP * 1.4, target.global_position, _player.collision_mask, [_player.get_rid()])
		if not _player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		closest = spec
		nearest = distance
	return closest

func interact_nearby() -> Dictionary:
	var selected := nearby_target()
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) == "P-01":
		var view := p01_view(String(selected.target_id))
		if not view.get("accepted", false):
			return view
		p01_panel_requested.emit(view)
		return {"accepted": true, "p01_panel_requested": true, "physical_commit": false, "reason": "Choose the P-01 inputs before confirming."}
	if not selected.is_empty() and String(selected.get("puzzle_id", "")) == "P-02" and hud != null and hud.open_mission_table(String(selected.target_id)):
		return {"accepted": true, "reason": "Mission Table open.", "mission_table": true}
	if not selected.is_empty():
		return perform_target(String(selected.target_id))
	var result := {"accepted": false, "reason": "Walk up to the next job and face it. Press H to see where it is."}
	if hud != null:
		hud.show_status(result.reason)
	return result

func _physics_process(_delta: float) -> void:
	if loading:
		return
	if _room == null:
		return
	var selected := nearby_target()
	_room.set_focus_target(String(selected.get("world_focus_id", "")))
	if hud != null:
		hud.show_nearby_forecast(String(selected.get("target_id", "")))

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
	var result: Dictionary
	if is_chapter_complete():
		result = _transition_after_chapter()
	else:
		result = route.advance_scene()
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
	if hud != null:
		hud.refresh_scene(result)
	_save_campaign()
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
		if _chapter_number() != 1 or payload.get("choice_id") != choice.get("id") or not payload.get("option_id") is String:
			return {"accepted": false, "reason": "This decision does not belong to the current Chapter 1 scene."}
		var problem := CampaignState.story_choice_problem(String(payload.choice_id), String(payload.option_id))
		if not problem.is_empty():
			return {"accepted": false, "reason": problem}
		if verb == "preview_puzzle":
			return {"accepted": true, "reason": "Decision preview only; no story record changed."}
		var result: Dictionary = director.preview(command) if preview_only else director.commit(command)
		if hud != null and not preview_only:
			hud.refresh_after_action(result)
		if bool(result.get("accepted", false)) and not preview_only and not bool(result.get("duplicate", false)):
			_save_campaign()
		return result
	if verb == "acknowledge_line":
		return acknowledge_dialogue(String(payload.get("line_id", command.get("target_id", ""))))
	if verb == "set_accessibility":
		var next := director.snapshot()
		next["accessibility"] = payload.duplicate(true)
		var restored := director.restore_snapshot(next)
		_save_campaign()
		if audio != null:
			audio.captions_enabled = bool(payload.get("captions", true))
		if hud != null:
			hud.apply_accessibility()
		return restored
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
func _save_campaign() -> Dictionary:
	if not _startup_error.is_empty():
		return {"accepted": false, "reason": _startup_error}
	var result: Dictionary = save_service.save(_save_snapshot(), save_path)
	if bool(result.get("accepted", false)):
		_exit_without_save_armed = false
	else:
		push_warning("Autosave failed: " + String(result.get("reason", "unknown error")))
		if hud != null:
			hud.show_status("AUTOSAVE FAILED · " + String(result.get("reason", "unknown error")) + " · progress since the last save is not on disk yet.")
	return result

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
	elif event.is_action_pressed("interact") and not event.is_echo():
		interact_nearby()
		get_viewport().set_input_as_handled()

func _refresh_world() -> void:
	if incremental_loading:
		if not loading and preparation.room_ready(route.current_room_id()):
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
		preparation.activate_room(route.current_room_id())
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
	_room.load_approved_assets = not incremental_assets
	add_child(_room)
	if incremental_assets:
		_room.load_approved_assets = true
	if not incremental_assets:
		_place_crew()
	LoadTrace.end("room_rebuild", stamp)

func _place_crew() -> void:
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
	_player = _crew.place(route.current_scene_id(), _room, Vector3(player_anchor[0], player_anchor[1], player_anchor[2]))
	_crew.set_paused(_ui_paused)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sync_world_boundaries()

func _refresh_world_incremental() -> void:
	await get_tree().process_frame
	await preparation.prepare_scene_media(route.current_scene_id())
	if not await preparation.prepare_room(route.current_room_id()):
		_fail_startup(preparation.failed)
		return
	_refresh_world_now(true)
	await get_tree().process_frame
	await _room.load_assets_incremental()
	_place_crew()
	await get_tree().process_frame
	# First real room draw (including its lighting/layout variants) is covered.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw

func _rebuild_transition() -> void:
	var was_paused := _ui_paused
	set_ui_paused(true)
	await _refresh_world_incremental()
	set_ui_paused(was_paused)
	_on_scene_ready()
	if hud != null:
		hud.refresh_scene({}, true)
	await get_tree().process_frame
	_transition_card.queue_free()
	_transition_card = null
	loading = false
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
	await preparation.prepare_room(room_id)
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
	hud = HUDScene.instantiate() as Chapter1CampaignHUD
	layer.add_child(hud)
	hud.setup(self)

func present_dialogue(line: Dictionary) -> void:
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
	cutscene_player.play(_cutscene_queue.pop_front())

func _on_cutscene_closed(result: Dictionary) -> void:
	audio.mark_heard(cutscenes.heard_line_ids(String(result.get("cutscene_id", "")), float(result.get("position_s", 0.0))))
	if _cutscene_queue.is_empty():
		_set_cinematic(false)
	cutscene_closed.emit(result)
	_play_next_cutscene()

func _set_cinematic(value: bool) -> void:
	audio.set_cinematic(value)
	if _crew != null:
		_crew.set_paused(value or _ui_paused)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
