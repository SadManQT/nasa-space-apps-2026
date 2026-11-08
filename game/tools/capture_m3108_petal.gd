## M3-108: Alo's pressed petal after the material and facing fix. Probes the imported paper and petal materials
## (metallic 0 on M_Card and M_Petal, roughness from the ORM map), then stages the garden (LOC-03) and checks that the
## mounted petal reads as a mustard petal from the lineage board's review view (the pixels around the projected petal),
## with close-ups of the board (EX-CH03-S11, S12) and of the flat sleeve on the harvest bench (EX-CH03-S10).
##   Godot --path game --windowed --resolution 1600x900 --script res://tools/capture_m3108_petal.gd
## Writes production/qa/evidence/M3-108_*.png and M3-108_probe.txt. Needs a window; see M3-108_capture.sh.
## Use --headless --script res://tools/capture_m3108_petal.gd -- --probe-only for the material probe alone.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Geometry = preload("res://scripts/asset_geometry.gd")
const EVIDENCE := "res://../production/qa/evidence/"
const PETALS := ["res://assets/props/PR_PressedPetal/PR_PressedPetal.glb", "res://assets/props/PR_PressedPetal_Mounted/PR_PressedPetal_Mounted.glb"]
const CHOICES := {"EX-CH01-S04-CHOICE": {"option_id": "EX-CH01-S04-OPT01"}, "EX-CH02-S06-CHOICE": {"option_id": "EX-CH02-S06-OPT01"}, "EX-CH03-S11-DEDICATION": {"option_id": "EX-CH03-S11-DEDICATION-OPT03"}}
const MOMENTS := ["CH03-ALO-VIGIL-1", "CH03-ALO-VIGIL-2", "CH03-ALO-VIGIL-3", "CH03-ALO-VIGIL-4", "CH03-ALO-VIGIL-5", "CH03-TARA-FAREWELL"]
## The garden plants' dated stages (as test_chapter3_rooms.gd's captures), so nothing out of canon stands in a frame.
const PLANTS := {
	"EX-CH03-S10": {"ALO-01": "mature_dry", "TARA-01": "pod_bearing"},
	"EX-CH03-S11": {"ALO-01": "archived_petal", "TARA-01": "pod_bearing"},
	"EX-CH03-S12": {"ALO-01": "archived_petal", "TARA-01": "mature_dry"},
}
## A pressed Brassica rapa petal: yellow to mustard (hue 30-65 degrees), clearly coloured, not a grey or navy patch.
const MUSTARD_HUE := Vector2(30.0, 65.0)
const MUSTARD_MIN_SATURATION := 0.25
const MUSTARD_MIN_PIXELS := 4

var checks := 0
var failures := 0
var report: PackedStringArray = []
var camera: Camera3D

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	report.append(("ok   " if ok else "FAIL ") + message)
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	root.size = Vector2i(1600, 900)
	root.always_on_top = true
	report.append("M3-108 pressed petal probe, %s, %s" % [Time.get_datetime_string_from_system(), RenderingServer.get_current_rendering_method()])
	_probe_materials()
	if "--probe-only" in OS.get_cmdline_user_args():
		_finish("M3-108 MATERIAL PROBE", "M3-108_materials.txt")
		return
	camera = Camera3D.new()
	root.add_child(camera)
	var room := (load("res://scenes/campaign/rooms/garden.tscn") as PackedScene).instantiate() as CampaignRoom
	room.load_approved_assets = false
	root.add_child(room)
	room.load_approved_assets = true
	await room.load_assets_incremental()
	room.set_story_choices(CHOICES, MOMENTS)
	# EX-CH03-S11: the petal goes onto the lineage board; the review view first, then a reading-distance close-up
	await _stage(room, "EX-CH03-S11")
	var mount := _staged(room, "alo_petal")
	var view: Dictionary = Contract.staged_layout(room.room_id, "EX-CH03-S11", CHOICES, MOMENTS).review_views.lineage_board
	var eye := Presentation.vector(view.from)
	var facing := (-mount.global_basis.z).dot((eye - mount.global_position).normalized())
	report.append("mounted petal at %s, front (-Z) toward the review camera: dot %.3f" % [mount.global_position, facing])
	_check(facing > 0.5, "EX-CH03-S11 the mounted petal faces the lineage board's review view")
	var review := await _shot(eye, Presentation.vector(view.to), 70.0)
	_measure_petal(review, mount, "EX-CH03-S11 review view")
	_save(review, "S11_review_view")
	_save(_zoom(review, _petal_pixel(review, mount), Vector2i(160, 100), 5), "S11_review_view_zoom")
	var card := _aabb_centre(mount, "Card")
	await _save_shot(card + (-mount.global_basis.z) * 0.26 + Vector3(0, 0.03, 0), card, 30.0, "S11_petal_closeup")
	# EX-CH03-S12: Alo's petal beside Tara's nameplate, from a step back
	await _stage(room, "EX-CH03-S12")
	mount = _staged(room, "alo_petal")
	var tara := _staged(room, "tara_nameplate").global_position
	var middle := (mount.global_position + tara) * 0.5 + Vector3(0, 0.05, 0)
	await _save_shot(middle + Vector3(0, -0.02, 0.62), middle, 45.0, "S12_board_petal_and_tara")
	# EX-CH03-S10: the flat sleeve on the harvest bench, from the harvest view's side, looking down about 55 degrees
	await _stage(room, "EX-CH03-S10")
	var sleeve := _staged(room, "alo_petal_sleeve")
	var harvest: Dictionary = Contract.staged_layout(room.room_id, "EX-CH03-S10", CHOICES, MOMENTS).review_views.s10_harvest
	var toward := Presentation.vector(harvest.from) - sleeve.global_position
	var centre := _aabb_centre(sleeve, "Card")
	await _save_shot(centre + Vector3(toward.x, 0, toward.z).normalized() * 0.18 + Vector3(0, 0.26, 0), centre, 35.0, "S10_bench_sleeve")
	room.free()
	camera.free()
	_finish("M3-108 PETAL CAPTURE", "M3-108_probe.txt")

func _finish(label: String, filename: String) -> void:
	var line := "%s RESULT: %s (%d checks, %d failures)" % [label, "PASS" if failures == 0 else "FAIL", checks, failures]
	report.append(line)
	var file := FileAccess.open(ProjectSettings.globalize_path(EVIDENCE + filename), FileAccess.WRITE)
	file.store_string("\n".join(report) + "\n")
	file.close()
	print("\n".join(report))
	quit(0 if failures == 0 else 1)

## The materials of both petal props as the editor imports them and as rooms decode them at runtime
## (AssetGeometry.load_glb): the paper and petal are dielectrics, roughness comes from the ORM map.
func _probe_materials() -> void:
	for path in PETALS:
		var sources := {"imported": (load(path) as PackedScene).instantiate() as Node3D, "runtime": Geometry.load_glb(path)}
		for source in sources:
			var node: Node3D = sources[source]
			_check(node != null, "%s (%s) loads" % [path.get_file(), source])
			if node == null:
				continue
			var found: Dictionary = {}
			for mesh_node in node.find_children("*", "MeshInstance3D", true, false):
				var mesh := mesh_node as MeshInstance3D
				for surface in mesh.mesh.get_surface_count():
					var material := mesh.get_active_material(surface) as BaseMaterial3D
					if material == null or not (material.resource_name in ["M_Card", "M_Petal"]):
						continue
					found[material.resource_name] = true
					var orm: Image = material.roughness_texture.get_image() if material.roughness_texture != null else null
					var mean := _mean_colour(orm)
					report.append("%s %s (%s): metallic %.2f, roughness %.2f x ORM green (mean %.2f), ORM blue mean %.3f" % [
						path.get_file(), material.resource_name, source, material.metallic, material.roughness, mean.g, mean.b])
					_check(is_zero_approx(material.metallic) and orm != null, "%s %s (%s) has metallic 0 and its roughness map" % [path.get_file(), material.resource_name, source])
			_check(found.has("M_Card") and found.has("M_Petal"), "%s (%s) contains both paper and petal materials" % [path.get_file(), source])
			node.free()

func _mean_colour(image: Image) -> Color:
	if image == null or image.is_empty():
		return Color(0, 0, 0, 0)
	if image.is_compressed():
		image.decompress()
	var sum := Color(0, 0, 0, 0)
	var n := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			sum += image.get_pixel(x, y)
			n += 1
	return Color(sum.r / n, sum.g / n, sum.b / n, 1.0)

func _stage(room: CampaignRoom, scene_id: String) -> void:
	room.set_scene_context(scene_id)
	var plants: Array = []
	for individual in PLANTS[scene_id]:
		plants.append({"individual_id": individual, "stage": PLANTS[scene_id][individual]})
	room.apply_plant_state(plants)
	for frame in 30:
		await process_frame

func _staged(room: CampaignRoom, id: String) -> Node3D:
	return room.visual_root.get_node(Staging.ROOT_NAME).get_node(id) as Node3D

func _aabb_centre(prop: Node3D, part: String) -> Vector3:
	var mesh := prop.find_children(part, "MeshInstance3D", true, false)[0] as MeshInstance3D
	return mesh.global_transform * mesh.get_aabb().get_center()

func _shot(from: Vector3, to: Vector3, fov: float) -> Image:
	camera.fov = fov
	camera.position = from
	camera.look_at(to)
	camera.current = true
	for frame in 20:
		await process_frame
	return await _grab()

func _save_shot(from: Vector3, to: Vector3, fov: float, id: String) -> void:
	_save(await _shot(from, to, fov), id)

## The presented frame. A window macOS marks covered never draws (frame_post_draw never fires), so after 30 frames
## without a draw the frame is forced; a blank first frame after a shader compile is re-read for up to two seconds.
func _grab() -> Image:
	var drawn := [false]
	var mark := func() -> void: drawn[0] = true
	RenderingServer.frame_post_draw.connect(mark)
	for frame in 30:
		await process_frame
		if drawn[0]:
			break
	RenderingServer.frame_post_draw.disconnect(mark)
	if not drawn[0]:
		RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	for attempt in 120:
		if image.get_pixel(image.get_width() / 2, image.get_height() / 2).get_luminance() > 0.01:
			break
		await process_frame
		image = root.get_texture().get_image()
	return image

func _save(image: Image, id: String) -> void:
	_check(image.save_png(ProjectSettings.globalize_path(EVIDENCE + "M3-108_%s.png" % id)) == OK, "saved M3-108_%s.png" % id)

## The petal's centre in saved-frame pixels (unproject answers in the stretched base canvas, not the window).
func _petal_pixel(image: Image, prop: Node3D) -> Vector2i:
	var canvas := camera.unproject_position(_aabb_centre(prop, "Petal"))
	var scale := Vector2(image.get_size()) / root.get_visible_rect().size
	return Vector2i((canvas * scale).round())

## Counts mustard pixels in a 15 x 15 window around the projected petal: the petal must read as yellow, not grey.
func _measure_petal(image: Image, prop: Node3D, label: String) -> void:
	var at := _petal_pixel(image, prop)
	var count := 0
	var best := Color(0, 0, 0)
	for y in range(at.y - 7, at.y + 8):
		for x in range(at.x - 7, at.x + 8):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var c := image.get_pixel(x, y)
			if c.s >= MUSTARD_MIN_SATURATION and c.h * 360.0 >= MUSTARD_HUE.x and c.h * 360.0 <= MUSTARD_HUE.y and c.v > 0.3:
				count += 1
				if c.s > best.s:
					best = c
	report.append("%s: petal at pixel %s, %d mustard pixels in the 15 x 15 window, most saturated %s (hue %.0f, sat %.2f, value %.2f)" % [
		label, at, count, best.to_html(false), best.h * 360.0, best.s, best.v])
	_check(count >= MUSTARD_MIN_PIXELS, label + ": the petal reads as a mustard petal on the card")

## An enlarged crop (nearest neighbour) around a pixel, for reading a small object in the evidence.
func _zoom(image: Image, at: Vector2i, size: Vector2i, factor: int) -> Image:
	var origin := Vector2i(clampi(at.x - size.x / 2, 0, image.get_width() - size.x), clampi(at.y - size.y / 2, 0, image.get_height() - size.y))
	var crop := image.get_region(Rect2i(origin, size))
	crop.resize(size.x * factor, size.y * factor, Image.INTERPOLATE_NEAREST)
	return crop
