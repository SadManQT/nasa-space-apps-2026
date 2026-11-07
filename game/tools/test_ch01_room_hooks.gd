## M1-84: the Chapter 1 room hooks Atik's Care Round (M1-49) wires through the campaign without editing the rooms.
## (1) The inventory lamp: CampaignRoom.trigger_cue("inventory_lamp") gives exactly one pulse at the EX-CH01-S02 roll
## call (LOC-04), S03 opens on one automatic pulse beside the dry-storage drawer (LOC-01), nothing restarts either, and
## cue_lit carries SFX_INVENTORY_LAMP_TICK to CampaignAudioDirector.play_effect. (2) RoomContract.care_round(scene_id):
## both real plant anchors in the garden for every dated care visit of S04 and S05, reachable, in line of sight and in
## one fixed photo frame. (3) The four existing mugs show KAI, AMARA, MEI and RAFI once story_log.moments holds
## CH01-MUGS-NAMED, from EX-CH01-S12 on. (4) CS-01 speaks none of EX-CH01-S01-L01..L04, so the campaign voices them.
##   Godot --headless --path game --script res://tools/test_ch01_room_hooks.gd
##   --capture (windowed) also writes production/qa/evidence/M1-84_*.png.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const NarrativeProps = preload("res://assets/props/narrative/narrative_props.gd")
const Content = preload("res://scripts/content/content_loader.gd")
const PlantServiceScript = preload("res://scripts/biology/plant_service.gd")
const SCENE_FILES := {"LOC-01": "commons", "LOC-03": "garden", "LOC-04": "safe_room"}
const MOMENT := "CH01-MUGS-NAMED"
const LAMP := "inventory_lamp"
const TICK := "SFX_INVENTORY_LAMP_TICK"
const NAMES := {"commons_mug_kai": "KAI", "commons_mug_amara": "AMARA", "commons_mug_mei": "MEI", "commons_mug_rafi": "RAFI"}
const BASE_MUGS := ["PR_Mug", "commons_mug_2", "commons_mug_3", "commons_mug_4"]
const OPENING := ["EX-CH01-S01-L01", "EX-CH01-S01-L02", "EX-CH01-S01-L03", "EX-CH01-S01-L04"]
## Evidence cameras for the lamp (kept here so the M1-06 room capture is unchanged).
const LAMP_VIEWS := {
	"LOC-04": {"from": [-1.15, 1.5, -1.55], "to": [-1.95, 1.25, -2.68]},
	"LOC-04_wide": {"from": [1.2, 1.75, 0.2], "to": [-2.2, 1.3, -2.7]},
	"LOC-01": {"from": [-4.15, 1.6, -3.25], "to": [-5.0, 1.25, -4.5]},
}
var checks := 0
var failures := 0
var capture := false

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	root.size = Vector2i(1600, 900)
	await _check_lamp()
	await _check_care_round()
	await _check_mugs()
	_check_opening_lines()
	if capture:
		await _capture_all()
	print("CH01 ROOM HOOKS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

## Builds a real room scene the way the campaign's loading card does (incremental prop binding).
func _room(room_id: String) -> CampaignRoom:
	var room := (load("res://scenes/campaign/rooms/%s.tscn" % SCENE_FILES[room_id]) as PackedScene).instantiate() as CampaignRoom
	room.load_approved_assets = false
	root.add_child(room)
	room.load_approved_assets = true
	await room.load_assets_incremental()
	return room

func _seconds(value: float) -> void:
	await create_timer(value).timeout

# --------------------------------------------------------------------------------------------- inventory lamp

func _check_lamp() -> void:
	var safe := await _room("LOC-04")
	var lit: Array = []
	safe.cue_lit.connect(func(id: String, sfx: String) -> void: lit.append([id, sfx]))
	var lamp := safe.visual_root.get_node(LAMP) as MeshInstance3D
	var material := lamp.material_override as StandardMaterial3D
	var dark := material.albedo_color
	var board := Presentation.vector(safe.fixture("roll_call").position)
	_check(lamp.position.distance_to(board) < 1.0, "S02 lamp hangs at the roll-call board, in the background of the roll call")
	_check(safe.trigger_cue(LAMP).accepted == false, "no blink before the room is staged for a scene")
	_check(safe.set_scene_context("EX-CH01-S02") == 0, "S02 starts no automatic blink: the campaign asks at the roll call")
	await _seconds(0.3)
	_check(lit.is_empty() and material.albedo_color == dark, "the S02 lamp stays dark until it is requested")
	var first := safe.trigger_cue(LAMP)
	_check(bool(first.accepted) and String(first.scene_id) == "EX-CH01-S02" and String(first.sfx_id) == TICK, "trigger_cue accepts one S02 blink with the tick: " + str(first))
	var again := safe.trigger_cue(LAMP)
	_check(not bool(again.accepted) and bool(again.get("duplicate", false)), "a second S02 request is refused: exactly one blink")
	await _seconds(0.45)
	_check(material.albedo_color.is_equal_approx(Color("#F2C230")), "the lamp is lit mid-pulse")
	await _seconds(0.9)
	_check(material.albedo_color.is_equal_approx(dark), "the lamp returns to dark after its single pulse")
	_check(lit == [[LAMP, TICK]], "cue_lit fired once, carrying the tick: " + str(lit))
	_check(safe.set_scene_context("EX-CH01-S02") == 0 and not bool(safe.trigger_cue(LAMP).accepted), "staging S02 again cannot restart it")
	safe.set_story_choices({"EX-CH01-S01-CHOICE": {"option_id": "EX-CH01-S01-OPT01"}}, [MOMENT])
	_check(not bool(safe.trigger_cue(LAMP).accepted), "re-staging for story state cannot restart it")
	safe.set_scene_context("EX-CH01-S08")
	_check(not bool(safe.trigger_cue(LAMP).accepted), "outside S02 the Safe Room lamp cannot be requested")
	await _seconds(0.1)
	_check(lit.size() == 1, "one Safe Room pulse in all")
	safe.free()
	await process_frame

	var commons := await _room("LOC-01")
	var commons_lit: Array = []
	commons.cue_lit.connect(func(id: String, sfx: String) -> void: commons_lit.append([id, sfx]))
	var drawer_lamp := commons.visual_root.get_node(LAMP) as MeshInstance3D
	var drawer := commons.fixture("dry_storage_drawer")
	var top := Presentation.vector(drawer.position) + Vector3(0, float(drawer.size[1]) * 0.5, 0)
	_check(drawer_lamp.position.distance_to(top) < 0.5, "S03 lamp sits on the dry-storage drawer")
	_check(commons.set_scene_context("EX-CH01-S03") == 1, "S03 opens on one automatic blink beside the drawer")
	_check(not bool(commons.trigger_cue(LAMP).accepted), "the S03 blink cannot be requested a second time")
	await _seconds(1.5 + 0.45)
	_check((drawer_lamp.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Color("#F2C230")), "the drawer lamp is lit 1.5 s into S03")
	await _seconds(0.9)
	_check(commons_lit == [[LAMP, TICK]], "S03 cue_lit fired once with the tick: " + str(commons_lit))
	_check(commons.set_scene_context("EX-CH01-S03") == 0, "a repeat of S03 cannot restart it")
	commons.free()
	await process_frame

	var media := CampaignAudioRuntime.read_metadata()
	var audio_runtime := CampaignAudioRuntime.new(Content.load_full(), media)
	var plan := audio_runtime.sfx_plan(TICK)
	_check(bool(plan.media_present) and String(plan.caption) == "[inventory lamp]", "the existing tick is installed with its caption")
	var director := CampaignAudioDirector.new()
	director.setup(audio_runtime)
	root.add_child(director)
	director.play_effect(TICK)
	for frame in 30:
		await process_frame
	var started := director.find_children("Effect*", "AudioStreamPlayer", false, false).any(func(p): return p.stream != null and String(p.stream.resource_path).ends_with(TICK + ".ogg"))
	_check(started, "CampaignAudioDirector.play_effect plays the tick")
	director.free()

# ----------------------------------------------------------------------------------------------- care round

func _check_care_round() -> void:
	_check(Contract.room_for_scene("EX-CH01-S04") == "LOC-03" and Contract.room_for_scene("EX-CH01-S05") == "LOC-02", "S04 plays in the garden, S05 keeps its corridor room")
	for scene_id in ["EX-CH01-S03", "EX-CH01-S06", "EX-CH02-S05"]:
		_check(Contract.care_round(scene_id).is_empty(), scene_id + " has no CH01 Care Round")
	var garden := await _room("LOC-03")
	var layout := Contract.layout("LOC-03")
	var service := PlantServiceScript.new()
	var plants: Array = [service.new_plant("ALO-01", "", "seed", "2046-04-11 06:00 UTC"), service.new_plant("TARA-01", "", "seed", "2046-04-11 06:00 UTC")]
	garden.apply_plant_state(plants.map(func(plant): return service.advance_to(plant, "2046-04-16 06:00 UTC").plant))
	for scene_id in ["EX-CH01-S04", "EX-CH01-S05"]:
		var care := Contract.care_round(scene_id)
		_check(care.keys().size() == 2 and care.has("ALO-01") and care.has("TARA-01"), scene_id + " Care Round visits both plants")
		garden.set_scene_context(scene_id)
		_check(garden.stage().layers.has("ch01_care_round") and garden.stage().care_round == care, scene_id + " the garden staged for the scene carries the same Care Round")
		var map := (garden.navigation_root.get_node("NavigationRegion") as NavigationRegion3D).get_navigation_map()
		NavigationServer3D.map_force_update(map)
		var spawn := Presentation.vector(layout.anchors.garden_player)
		for plant_id in care:
			var visit: Dictionary = care[plant_id]
			var focus := garden.focus_root.get_node_or_null("Focus_" + String(visit.focus_target)) as Node3D
			_check(focus != null, "%s %s focus target %s exists" % [scene_id, plant_id, visit.focus_target])
			_check(String(visit.plant_anchor) == plant_id and layout.plant_positions.has(plant_id), "%s %s names its real plant anchor" % [scene_id, plant_id])
			_check(String(visit.reach) == ("glove_ports" if plant_id == "ALO-01" else "direct"), "%s %s reach: Alo through the glove ports, Tara directly" % [scene_id, plant_id])
			var shutter := String(visit.get("view_boundary", ""))
			_check(shutter == ("garden_viewing_shutter" if plant_id == "ALO-01" else "") and (shutter.is_empty() or garden.set_door_open(shutter, true)), "%s %s names the view it needs (Alo behind the pressure glazing)" % [scene_id, plant_id])
			var plant_at := Presentation.vector(layout.plant_positions[plant_id])
			var model := garden.visual_root.get_node_or_null(("PL_Alo_" if plant_id == "ALO-01" else "PL_Tara_") + "Sprout") as Node3D
			_check(model != null and model.visible and model.position.distance_to(plant_at) < 0.01, "%s %s seedling stands at its anchor" % [scene_id, plant_id])
			var stand := Presentation.vector(visit.stand)
			var path := NavigationServer3D.map_get_path(map, spawn, stand, true)
			_check(not path.is_empty() and path[path.size() - 1].distance_to(stand) < 0.3, "%s %s stand point is reachable %s" % [scene_id, plant_id, str(stand)])
			if focus != null:
				_check(_ray(stand + Vector3.UP * 1.4, focus.position).is_empty(), "%s %s line of sight from the stand to the station" % [scene_id, plant_id])
				_check(stand.distance_to(Vector3(focus.position.x, 0, focus.position.z)) < 1.5, "%s %s stands within reach of the station" % [scene_id, plant_id])
			var view: Dictionary = visit.photo_view
			var from := Presentation.vector(view.from)
			var axis := (Presentation.vector(view.to) - from).normalized()
			var to_plant := plant_at + Vector3(0, 0.05, 0) - from
			_check(rad_to_deg(axis.angle_to(to_plant)) < 8.0 and to_plant.length() < 2.0, "%s %s photo frame holds the plant (%.1f deg off axis, %.2f m)" % [scene_id, plant_id, rad_to_deg(axis.angle_to(to_plant)), to_plant.length()])
	garden.free()
	await process_frame

# ---------------------------------------------------------------------------------------------------- mugs

func _check_mugs() -> void:
	_check(not Contract.staging("LOC-01", "EX-CH01-S12").layers.has("ch01_named_mugs"), "without the recorded moment the mugs stay nameless")
	_check(not Contract.staging("LOC-01", "EX-CH01-S11", {}, [MOMENT]).layers.has("ch01_named_mugs"), "no names before EX-CH01-S12")
	for scene_id in ["EX-CH01-S12", "EX-CH02-S07", "EX-CH05-S02", "EX-CH07-S12"]:
		var staged := Contract.staged_layout("LOC-01", scene_id, {}, [MOMENT])
		var ids: Array = staged.props.map(func(p): return String(p.id))
		_check(NAMES.keys().all(func(id): return ids.has(id)) and not BASE_MUGS.any(func(id): return ids.has(id)), scene_id + " the four named mugs replace the nameless ones")
		_check(ids.has("commons_mug_5") == (Contract.scene_order(scene_id) >= 501), scene_id + " Ferreira's fifth mug only from CH05")
	var commons := await _room("LOC-01")
	commons.set_scene_context("EX-CH01-S12")
	var spots: Array[Vector3] = []
	for id in BASE_MUGS:
		var mug := commons.visual_root.get_node(id) as Node3D
		_check(mug.visible, "before the moment the existing mug %s stands nameless" % id)
		spots.append(mug.position)
	commons.set_story_choices({}, [MOMENT])
	var staged_root := commons.visual_root.get_node_or_null(Staging.ROOT_NAME) as Node3D
	_check(staged_root != null, "recording the moment re-stages the commons in place")
	for id in BASE_MUGS:
		_check(not (commons.visual_root.get_node(id) as Node3D).visible, "the nameless mug %s gives way to its named twin" % id)
	var used: Array[Vector3] = []
	for id in NAMES:
		var mug := staged_root.get_node_or_null(id) as Node3D if staged_root != null else null
		_check(mug != null and NarrativeProps.current_variant(mug) == NAMES[id], "%s shows %s" % [id, NAMES[id]])
		if mug == null:
			continue
		var at := spots.filter(func(p: Vector3): return p.distance_to(mug.position) < 0.001)
		_check(at.size() == 1 and not used.has(at[0]), "%s stands exactly where a Chapter 1 mug stood" % id)
		if not at.is_empty():
			used.append(at[0])
		var ink := mug.find_children("Ink*", "Label3D", true, false)
		var letters := "".join(PackedStringArray(ink.map(func(label): return (label as Label3D).text)))
		_check(letters == NAMES[id], "%s carries the written name %s (got %s)" % [id, NAMES[id], letters])
		var arc := mug.find_child("NameArc", true, false) as Node3D
		_check(arc != null and arc.global_basis.z.normalized().dot(Vector3.BACK) > 0.95, "%s name faces the commons" % id)
		_check(absf(AssetGeometry.bounds(mug).position.y + mug.position.y - 0.76) < 0.01, "%s rests on the Mission Table top" % id)
	commons.set_story_choices({}, [])
	for id in BASE_MUGS:
		_check((commons.visual_root.get_node(id) as Node3D).visible, "without the moment the Chapter 1 mug %s comes back" % id)
	commons.free()
	await process_frame

# ------------------------------------------------------------------------------------------- opening lines

func _check_opening_lines() -> void:
	var content := Content.load_full()
	var dialogue := CampaignDialogueService.new(content)
	var media := CampaignAudioRuntime.read_metadata()
	var cs01: Dictionary = {}
	for entry in media.get("available_cutscenes", []):
		if String(entry.get("id", "")) == "CS-01":
			cs01 = entry
	_check(String(cs01.get("runtime_path", "")) == "res://assets/cutscenes/CS-01_Arrival.ogv" and cs01.get("caption_cues", [null]).is_empty(), "CS-01 (the M1-51 cold open) carries no caption cue")
	var source = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../production/cutscenes/v8/src/CS-01.json")))
	_check(source is Dictionary and source.get("lines", [null]).is_empty(), "the v8 CS-01 film speaks no line")
	var cutscenes := CampaignCutsceneRuntime.new(content, media, dialogue)
	_check(cutscenes.heard_line_ids("CS-01", 1.0e6).is_empty(), "watching CS-01 to the end marks none of L01-L04 heard")
	var ids: Array = dialogue.lines_for_scene("EX-CH01-S01").map(func(line): return String(line.id))
	_check(ids == OPENING, "EX-CH01-S01 has exactly L01-L04 in order: " + str(ids))
	var audio := CampaignAudioRuntime.new(content, media, dialogue)
	for id in OPENING:
		_check(String(audio.voice_plan(id).get("mode", "")) == "voice", id + " has its installed voice")
	_check(String(dialogue.dialogue_by_id("EX-CH01-S01-L04").get("origin", "")) == "earth_link" and String(audio.line_sfx("earth_link").get("id", "")) == "SFX_RADIO_EARTH_IN", "L04 arrives over the Earth link with SFX_RADIO_EARTH_IN")

# ------------------------------------------------------------------------------------------------- capture

func _capture_all() -> void:
	root.always_on_top = true
	var camera := Camera3D.new()
	root.add_child(camera)
	var safe := await _room("LOC-04")
	safe.set_scene_context("EX-CH01-S02")
	await _settle()
	await _shot(camera, LAMP_VIEWS["LOC-04"], 40, "S02_lamp_dark")
	await _shot(camera, LAMP_VIEWS["LOC-04_wide"], 60, "S02_roll_call_wide_dark")
	safe.trigger_cue(LAMP)
	await _seconds(0.4)
	await _shot(camera, LAMP_VIEWS["LOC-04"], 40, "S02_lamp_blink")
	safe.free()
	await process_frame
	var commons := await _room("LOC-01")
	commons.set_scene_context("EX-CH01-S03")
	await _settle()
	await _shot(camera, LAMP_VIEWS["LOC-01"], 45, "S03_drawer_dark")
	await _seconds(1.5)
	await _shot(camera, LAMP_VIEWS["LOC-01"], 45, "S03_drawer_blink")
	commons.set_scene_context("EX-CH01-S12")
	var mugs: Dictionary = Contract.staged_layout("LOC-01", "EX-CH01-S12", {}, [MOMENT]).review_views.named_mugs
	await _settle()
	await _shot(camera, mugs, 45, "S12_mugs_nameless")
	commons.set_story_choices({}, [MOMENT])
	await _settle()
	await _shot(camera, mugs, 45, "S12_mugs_named")
	commons.free()
	await process_frame
	var garden := await _room("LOC-03")
	var service := PlantServiceScript.new()
	var sown: Array = [service.new_plant("ALO-01", "", "seed", "2046-04-11 06:00 UTC"), service.new_plant("TARA-01", "", "seed", "2046-04-11 06:00 UTC")]
	garden.set_scene_context("EX-CH01-S05")
	garden.set_door_open(String(Contract.care_round("EX-CH01-S05")["ALO-01"].view_boundary), true)
	for date in ["2046-04-12", "2046-04-16"]:
		garden.apply_plant_state(sown.map(func(plant): return service.advance_to(plant, date + " 06:00 UTC").plant))
		await _settle()
		for plant_id in ["ALO-01", "TARA-01"]:
			await _shot(camera, Contract.care_round("EX-CH01-S05")[plant_id].photo_view, 50, "care_%s_%s" % [plant_id.get_slice("-", 0).to_lower(), date.substr(5).replace("-", "")])
	garden.free()
	camera.free()

func _settle() -> void:
	for frame in 30:
		await process_frame

func _shot(camera: Camera3D, view: Dictionary, fov: float, id: String) -> void:
	camera.fov = fov
	camera.position = Presentation.vector(view.from)
	camera.look_at(Presentation.vector(view.to))
	camera.current = true
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-84_%s.png" % id)) == OK, "capture " + id)

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return root.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
