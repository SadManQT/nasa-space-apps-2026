## Serial preparation coordinator. Worker results are published only after completion.
extends Node
class_name LoadPreparation

const Content = preload("res://scripts/content/content_loader.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
const ROOM_SCENES := {
	"LOC-01": "res://scenes/campaign/rooms/commons.tscn",
	"LOC-02": "res://scenes/campaign/rooms/service_rooms.tscn",
	"LOC-03": "res://scenes/campaign/rooms/garden.tscn",
	"LOC-04": "res://scenes/campaign/rooms/safe_room.tscn",
	"LOC-06": "res://scenes/campaign/rooms/exterior.tscn",
	# M1-36: the terrain exteriors; each scene's site preloader keeps its kit GLBs and VH_Rover_Lit.tscn decoded off
	# the main thread and cached while the room is prepared.
	"LOC-09": "res://scenes/campaign/rooms/ridge.tscn",
	"LOC-10": "res://scenes/campaign/rooms/vault_shelf.tscn",
	"LOC-11": "res://scenes/campaign/rooms/relay_road.tscn",
}
var resources: Dictionary = {}
var content: Dictionary = {}
var validation: Dictionary = {}
var crew: CampaignCrew
var campaign_ready := false
var preparing := false
var failed := ""
var _warm_view: SubViewport
var _warm_root: Node3D
var _room_busy := false
var _warmed: Dictionary = {}

func resource(path: String) -> Resource:
	if resources.has(path):
		return resources[path]
	if not ResourceLoader.exists(path):
		return null
	var error := ResourceLoader.load_threaded_request(path)
	if error != OK:
		return null
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	var result := ResourceLoader.load_threaded_get(path)
	# A small strong-reference cache keeps title/room textures and audio resident.
	if resources.size() >= 64:
		resources.erase(resources.keys()[0])
	resources[path] = result
	return result

func prepare_content() -> void:
	if not content.is_empty():
		return
	var job := PreparationJob.new()
	job.start(_content_job)
	var result := await job.finish(get_tree())
	content = result.content
	validation = result.validation
	if LoadTrace.enabled:
		LoadTrace.steps.append({"step": "worker_content_validation", "ms": result.ms})
	if not validation.get("valid", false):
		failed = "Campaign content could not be verified."

static func _content_job() -> Dictionary:
	var start := Time.get_ticks_usec()
	var data := Content._read_json(Content.FULL_PATH)
	return {"content": data, "validation": Content.validate_full(data), "ms": (Time.get_ticks_usec() - start) / 1000.0}

func prepare_campaign() -> void:
	if preparing or campaign_ready:
		return
	preparing = true
	await prepare_content()
	await resource("res://scenes/campaign/chapter1_campaign.tscn")
	await resource("res://scenes/player/player.tscn")
	await resource("res://scenes/ui/chapter1_campaign_hud.tscn")
	for id in ["Ferreira", "Rao"]:
		await resource("res://assets/ui/portraits/CH_%s_screen.png" % id)
	_make_warm_view()
	crew = CampaignCrew.new()
	_warm_root.add_child(crew)
	for id in CompanionRoster.ACTOR_IDS:
		var path := "res://assets/characters/CH_%s/CH_%s.glb" % [id.capitalize(), id.capitalize()]
		if not await AssetGeometry.prepare(path, get_tree()):
			failed = "A crew model could not be prepared."
			break
		var sample := AssetGeometry.load_glb(path)
		if sample == null:
			failed = "A crew model could not be instanced."
			break
		if not await LocomotionClips.prewarm(sample, path, get_tree()):
			# Original gait analysis is time-sliced when its validated bake is absent.
			_warm_root.add_child(sample)
			if not await LocomotionClips.prewarm_incremental(sample, path, get_tree()):
				sample.free()
				failed = "Crew motion could not be prepared."
				break
		sample.free()
		await get_tree().process_frame
		await resource("res://resources/player/ch_%s.tres" % id)
		var stamp := LoadTrace.begin()
		var body := crew._body(id)
		LoadTrace.end("cast_rig_setup:" + id, stamp)
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.collision_layer = 0
		await _draw_warm_frames()
		body.hide()
	await prepare_scene_media("EX-CH01-S01")
	await prepare_room("LOC-01")
	await prepare_room("LOC-03")
	campaign_ready = true
	preparing = false

func wait_campaign() -> bool:
	if not preparing and not campaign_ready:
		prepare_campaign()
	while preparing:
		await get_tree().process_frame
	return failed.is_empty()

static func room_paths(room_id: String) -> Array:
	var paths: Array = Contract.room(room_id).get("asset_paths", []).duplicate()
	if room_id == "LOC-03":
		# Every dated plant model CampaignRoom.apply_plant_state can show (seedlings from M1-07), so a stage swap never decodes on the main thread.
		for id in ["PL_Alo_Sprout", "PL_Tara_Sprout", "PL_Alo_Bloom", "PL_Alo_Pods"]:
			paths.append("res://assets/plants/%s/%s.glb" % [id, id])
	return paths

## True while campaign preparation or a room look-ahead is still loading.
func busy() -> bool:
	return preparing or _room_busy

func activate_room(room_id: String) -> void:
	AssetGeometry.pinned.assign(room_paths(room_id))

func room_ready(room_id: String) -> bool:
	if ROOM_SCENES.has(room_id) and not resources.has(ROOM_SCENES[room_id]):
		return false
	for value in room_paths(room_id):
		if not AssetGeometry.is_prepared(String(value)) or int(_warmed.get(value, -1)) != FileAccess.get_modified_time(String(value)):
			return false
	return true

func prepare_scene_media(scene_id: String) -> void:
	for line in content.get("dialogue", []):
		if line.get("scene_id", "") != scene_id:
			continue
		var path := String(line.get("voice_file", ""))
		if path.begins_with("game/"):
			path = "res://" + path.trim_prefix("game/")
		if ResourceLoader.exists(path):
			await resource(path)

func prepare_room(room_id: String) -> bool:
	# Background look-ahead and foreground entry share one queue; never consume
	# the same ResourceLoader request twice or mutate the same cached material.
	while _room_busy:
		await get_tree().process_frame
	_room_busy = true
	if ROOM_SCENES.has(room_id):
		await resource(ROOM_SCENES[room_id])
	var paths := room_paths(room_id)
	for value in paths:
		var path := String(value)
		if not await AssetGeometry.prepare(path, get_tree()):
			failed = "Room equipment could not be prepared."
			_room_busy = false
			return false
		if int(_warmed.get(path, -1)) != FileAccess.get_modified_time(path):
			# The dummy renderer cannot compile pipelines and reports invalid
			# material RIDs when temporary styled instances are destroyed.
			if DisplayServer.get_name() != "headless":
				_make_warm_view()
				var sample := AssetGeometry.load_glb(path)
				_warm_root.add_child(sample)
				ToonMaterials.apply_to_tree(sample, false, true)
				await _draw_warm_frames()
				sample.free()
			_warmed[path] = FileAccess.get_modified_time(path)
	_room_busy = false
	return true

## A real off-screen viewport draws color, depth and shadow passes. Merely
## hiding a MeshInstance would skip pipeline creation entirely.
func _make_warm_view() -> void:
	if _warm_view != null:
		return
	_warm_view = SubViewport.new()
	_warm_view.size = Vector2i(256, 256)
	_warm_view.own_world_3d = true
	_warm_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_warm_view)
	_warm_root = Node3D.new()
	_warm_view.add_child(_warm_root)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.5, 5)
	camera.current = true
	_warm_root.add_child(camera)
	camera.look_at(Vector3(0, 1, 0))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.shadow_enabled = true
	_warm_root.add_child(light)

func _draw_warm_frames() -> void:
	_warm_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for frame in 3:
		await get_tree().process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
	_warm_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
