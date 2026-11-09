## Serial preparation coordinator. Worker results are published only after completion.
extends Node
class_name LoadPreparation

const Content = preload("res://scripts/content/content_loader.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
const Helmet = preload("res://assets/props/PR_Helmet_Roles/helmet_roles.gd")
const PLANT_STAGE_MODELS := {
	"ALO-01": {
		"seed": "PL_Alo_Sprout",
		"sprout": "PL_Alo_Sprout",
		"bud": "PL_Alo_Bud",
		"bloom": "PL_Alo_Bloom",
		"pollinated": "PL_Alo_Bloom",
		"pod_bearing": "PL_Alo_PodsGreen",
		"mature_pods": "PL_Alo_Senescent",
		"mature_dry": "PL_Alo_Dry",
	},
	"TARA-01": {
		"seed": "PL_Tara_Sprout",
		"sprout": "PL_Tara_Sprout",
		"bud": "PL_Tara_Bloom",
		"bloom": "PL_Tara_Bloom",
		"pollinated": "PL_Tara_Bloom",
		"pod_bearing": "PL_Tara_Pods",
		"mature_pods": "PL_Tara_Senescent",
		"mature_dry": "PL_Tara_Dry",
	},
}
const PLANT_STAGE_NEXT := {
	"seed": "sprout",
	"sprout": "bud",
	"bud": "bloom",
	"bloom": "pollinated",
	"pollinated": "pod_bearing",
	"pod_bearing": "mature_pods",
	"mature_pods": "mature_dry",
	"mature_dry": "mature_dry",
}
const ROOM_SCENES := {
	"LOC-01": "res://scenes/campaign/rooms/commons.tscn",
	"LOC-02": "res://scenes/campaign/rooms/service_rooms.tscn",
	"LOC-03": "res://scenes/campaign/rooms/garden.tscn",
	"LOC-04": "res://scenes/campaign/rooms/safe_room.tscn",
	"LOC-05": "res://scenes/campaign/rooms/airlock.tscn",
	"LOC-06": "res://scenes/campaign/rooms/exterior.tscn",
	"LOC-07": "res://scenes/campaign/rooms/annex.tscn",
	"LOC-08": "res://scenes/campaign/rooms/garage.tscn",
	# M1-36: the terrain exteriors; each scene's site preloader keeps its kit GLBs and VH_Rover_Lit.tscn decoded off
	# the main thread and cached while the room is prepared.
	"LOC-09": "res://scenes/campaign/rooms/ridge.tscn",
	"LOC-10": "res://scenes/campaign/rooms/vault_shelf.tscn",
	"LOC-11": "res://scenes/campaign/rooms/relay_road.tscn",
	"LOC-12": "res://scenes/campaign/rooms/malapert_summit.tscn",
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
var _resource_pending: Dictionary = {}
var _draw_generation := 0
var _draw_completed := 0

## Shares one request/result per path, including overlapping audio look-ahead.
func resource(path: String) -> Resource:
	if resources.has(path):
		return resources[path]
	if not ResourceLoader.exists(path):
		return null
	if _resource_pending.has(path):
		if not await PreparationWatchdog.wait_until(get_tree(), "resource_queue:" + path, func(): return not _resource_pending.has(path)):
			return await _recover_resource(path)
		return resources.get(path)
	if PreparationWatchdog.synchronous:
		return await _recover_resource(path)
	var error := ResourceLoader.load_threaded_request(path)
	if error != OK:
		return await _recover_resource(path)
	_resource_pending[path] = "threaded"
	var completed := await PreparationWatchdog.wait_until(get_tree(), "resource:" + path, func():
		return _resource_pending.get(path) != "threaded" or ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_IN_PROGRESS)
	if _resource_pending.get(path) != "threaded":
		return await resource(path)
	if not completed:
		return await _recover_resource(path)
	_resource_pending.erase(path)
	return _remember_resource(path, ResourceLoader.load_threaded_get(path))

func _recover_resource(path: String) -> Resource:
	if _resource_pending.get(path) == "recovering":
		if not await PreparationWatchdog.wait_until(get_tree(), "resource_recovery:" + path, func(): return not _resource_pending.has(path)):
			failed = "A resource recovery could not be completed."
			return null
		return resources.get(path)
	if _resource_pending.get(path) == "threaded":
		PreparationWatchdog.retire_resource(get_tree(), path)
	_resource_pending[path] = "recovering"
	# REUSE would join the stuck request; IGNORE alone still reuses dependencies.
	var result: Resource = await PreparationWatchdog.fallback(get_tree(), func(): return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP))
	_remember_resource(path, result)
	_resource_pending.erase(path)
	return result

func _remember_resource(path: String, result: Resource) -> Resource:
	if result == null:
		return null
	# A small strong-reference cache keeps title/room textures and audio resident.
	# Pin only outstanding abandoned paths, rather than keeping every later voice
	# forever in a recovered session. The reaper releases pins as workers finish.
	if not resources.has(path) and resources.size() >= 64:
		for candidate in resources.keys():
			if not PreparationWatchdog.resource_is_retired(candidate):
				resources.erase(candidate)
				break
	resources[path] = result
	return result

func prepare_content() -> void:
	if not content.is_empty():
		return
	var job := PreparationJob.new()
	job.start(_content_job, "content_validation")
	var result := await job.finish(get_tree())
	content = result.content
	validation = result.validation
	if LoadTrace.enabled:
		LoadTrace.steps.append({"step": "worker_content_validation", "ms": result.ms})
	if not validation.get("valid", false):
		failed = "Campaign content could not be verified."

static func _content_job() -> Dictionary:
	var start := Time.get_ticks_usec()
	ScienceData.new()
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
	campaign_ready = failed.is_empty()
	preparing = false

func wait_campaign() -> bool:
	if not preparing and not campaign_ready:
		prepare_campaign()
	while preparing:
		await get_tree().process_frame
	return failed.is_empty()

static func room_paths(room_id: String, scene_id: String = "", plants: Array = []) -> Array:
	var paths: Array = Contract.room(room_id).get("asset_paths", []).duplicate()
	if room_id == "LOC-03":
		# M3-100: preload the models the garden can show for the snapshot's date (each plant's current stage and its next stage),
		# or the early sprout/bloom models when no plant state is supplied; drop the legacy PL_Alo_Pods.
		var stage_models: Array[String] = []
		if plants.is_empty():
			if not scene_id.is_empty() and Contract.scene_order(scene_id) >= 300:
				stage_models.assign(["PL_Alo_Bloom", "PL_Alo_PodsGreen", "PL_Alo_Senescent", "PL_Alo_Dry", "PL_Tara_Bloom", "PL_Tara_Pods", "PL_Tara_Senescent", "PL_Tara_Dry"])
			else:
				stage_models.assign(["PL_Alo_Sprout", "PL_Tara_Sprout", "PL_Alo_Bloom"])
		else:
			for individual in ["ALO-01", "TARA-01"]:
				var cur_stage := "seed"
				for plant in plants:
					if plant is Dictionary and String(plant.get("individual_id", "")) == individual:
						cur_stage = String(plant.get("stage", "seed"))
				var next_stage := String(PLANT_STAGE_NEXT.get(cur_stage, cur_stage))
				for st in [cur_stage, next_stage]:
					var model := String(PLANT_STAGE_MODELS.get(individual, {}).get(st, ""))
					if not model.is_empty() and model not in stage_models:
						stage_models.append(model)
		for id in stage_models:
			var p := "res://assets/plants/%s/%s.glb" % [id, id]
			if p not in paths:
				paths.append(p)
	if not scene_id.is_empty():
		var layout := Contract.layout(room_id)
		for p in Contract.staging_asset_paths(layout, scene_id):
			if p not in paths:
				paths.append(p)
		for p in Contract.work_light_asset_paths(room_id):
			if p not in paths:
				paths.append(p)
	return paths

## True while campaign preparation or a room look-ahead is still loading.
func busy() -> bool:
	return preparing or _room_busy

func activate_room(room_id: String, scene_id: String = "", plants: Array = []) -> void:
	AssetGeometry.pinned.assign(room_paths(room_id, scene_id, plants))

func room_ready(room_id: String, scene_id: String = "", plants: Array = []) -> bool:
	if ROOM_SCENES.has(room_id) and not resources.has(ROOM_SCENES[room_id]):
		return false
	for value in room_paths(room_id, scene_id, plants):
		if not AssetGeometry.is_prepared(String(value)) or int(_warmed.get(value, -1)) != FileAccess.get_modified_time(String(value)):
			return false
	if not scene_id.is_empty() and crew != null:
		var outfits: Dictionary = Contract.staging(room_id, scene_id).get("outfits", {})
		for id in outfits:
			var outfit := String(outfits[id])
			if not outfit.is_empty() and not crew._wardrobe.has(String(id) + "/" + outfit):
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

## Prepares any EVA or custom outfit bodies staged in scene_id off the main thread so CampaignCrew.place never decodes on main.
func prepare_scene_outfits(room_id: String, scene_id: String) -> bool:
	if scene_id.is_empty() or crew == null:
		return true
	var outfits: Dictionary = Contract.staging(room_id, scene_id).get("outfits", {})
	if outfits.is_empty():
		return true
	var needed: Array[String] = []
	for id in outfits:
		var outfit := String(outfits[id])
		if outfit == "eva" and not crew._wardrobe.has(String(id) + "/eva"):
			needed.append(String(id))
	if needed.is_empty():
		return true
	if not await AssetGeometry.prepare(Helmet.SCENE_PATH, get_tree()):
		failed = "EVA helmet could not be prepared."
		return false
	for id in needed:
		var cast := id.capitalize()
		var path := "res://assets/characters/CH_%s_EVA/CH_%s_EVA.glb" % [cast, cast]
		if not await AssetGeometry.prepare(path, get_tree()):
			failed = "An EVA crew model could not be prepared."
			return false
		var sample := AssetGeometry.load_glb(path)
		if sample == null:
			failed = "An EVA crew model could not be instanced."
			return false
		if not await LocomotionClips.prewarm(sample, path, get_tree()):
			_make_warm_view()
			_warm_root.add_child(sample)
			if not await LocomotionClips.prewarm_incremental(sample, path, get_tree()):
				sample.free()
				failed = "EVA crew motion could not be prepared."
				return false
		await get_tree().process_frame
		var skeletons := sample.find_children("*", "Skeleton3D", true, false)
		if not skeletons.is_empty():
			LocomotionClips.FootSlideScript.new().setup(sample, skeletons[0] as Skeleton3D)
		sample.free()
		await get_tree().process_frame
		await resource("res://resources/player/ch_%s.tres" % id)
		var stamp := LoadTrace.begin()
		var body := crew._body(id, "eva")
		LoadTrace.end("cast_rig_setup:" + id + "_eva", stamp)
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.collision_layer = 0
		body.hide()
		await get_tree().process_frame
	return true

func prepare_room(room_id: String, scene_id: String = "", plants: Array = []) -> bool:
	# Background look-ahead and foreground entry share one queue; never consume
	# the same ResourceLoader request twice or mutate the same cached material.
	if not await PreparationWatchdog.wait_until(get_tree(), "room_queue:" + room_id, func(): return not _room_busy):
		# Do not steal an active raw importer: its owner may still publish or
		# style shared resources. AssetGeometry needs its owner-side watchdog.
		failed = "Room preparation timed out. Please return to the title and try again."
		return false
	_room_busy = true
	if ROOM_SCENES.has(room_id):
		if await resource(ROOM_SCENES[room_id]) == null:
			failed = "The room could not be prepared."
			_room_busy = false
			return false
	var layout := Contract.layout(room_id)
	var is_pbr_kit: bool = layout.get("assembly") in ["habitat_kit", "site_kit", "exterior_kit"]
	var paths := room_paths(room_id, scene_id, plants)
	for value in paths:
		var path := String(value)
		if not await AssetGeometry.prepare(path, get_tree()):
			failed = "Room equipment could not be prepared."
			_room_busy = false
			return false
		if int(_warmed.get(path, -1)) != FileAccess.get_modified_time(path):
			# M4-12: skip ToonMaterials warm-draw on PBR habitat_kit / site_kit / exterior_kit props.
			# The dummy renderer cannot compile pipelines and reports invalid
			# material RIDs when temporary styled instances are destroyed.
			if DisplayServer.get_name() != "headless" and not is_pbr_kit:
				_make_warm_view()
				var sample := AssetGeometry.load_glb(path)
				_warm_root.add_child(sample)
				ToonMaterials.apply_to_tree(sample, false, true)
				await _draw_warm_frames()
				sample.free()
			_warmed[path] = FileAccess.get_modified_time(path)
	if not await prepare_scene_outfits(room_id, scene_id):
		_room_busy = false
		return false
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
	if PreparationWatchdog.synchronous:
		return
	_warm_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for frame in 3:
		await get_tree().process_frame
		if DisplayServer.get_name() != "headless":
			if not await wait_for_draw("warm_draw:" + str(frame)):
				break
	_warm_view.render_target_update_mode = SubViewport.UPDATE_DISABLED

## Drains optional look-ahead while its owning world is still alive.
func wait_idle() -> bool:
	return await PreparationWatchdog.wait_until(get_tree(), "preparation_drain", func():
		return not preparing and not _room_busy and _resource_pending.is_empty())

## A render notification may never arrive (minimized window/device interruption).
## Keep pumping frames so recovery does not depend on receiving that notification.
func wait_for_draw(step: String) -> bool:
	if DisplayServer.get_name() == "headless" or PreparationWatchdog.synchronous:
		return true
	_draw_generation += 1
	var generation := _draw_generation
	var completed := func(): _draw_completed = maxi(_draw_completed, generation)
	RenderingServer.frame_post_draw.connect(completed, CONNECT_ONE_SHOT)
	var success := await PreparationWatchdog.wait_until(get_tree(), step, func(): return _draw_completed >= generation)
	if RenderingServer.frame_post_draw.is_connected(completed):
		RenderingServer.frame_post_draw.disconnect(completed)
	return success
