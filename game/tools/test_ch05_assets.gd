## M3-5A: the Chapter 5 assets import with their runtime contract: the three cotton stages (pot, plant, blend shapes),
## the impact-camera monitor (Screen slot, moving keys and jog wheel, sockets) and the authored impact frame set
## (eight genuine transients, two fixed artifacts, both cameras, three frames each), and the objects Chapter 5's scene
## joins carry (doc 24 §2.9, clues 17-18, D9): the sealed document sleeve, the four 2034 records under their weights and
## Kai's marker tape.
## Headless: game/tools/run_tests.sh ch05_assets
## Evidence (needs a window): Godot --path game --script res://tools/test_ch05_assets.gd -- --evidence
extends SceneTree

const AssetGeometryScript = preload("res://scripts/asset_geometry.gd")
const ToonMaterialsScript = preload("res://scripts/toon_materials.gd")
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const FRAMES_DIR := "res://assets/ui/impact_monitor/"
const SCREEN_PX := Vector2i(1280, 800)   # the monitor Screen's 16:10 surface (0.44 x 0.275 m) as a texture
const PLANTS := {
	"PL_Cotton_Seed": {"height": 0.092, "parts": ["Pot", "Seed", "Dimple"], "shapes": []},
	"PL_Cotton_Sprout": {"height": 0.134, "parts": ["Pot", "Plant", "SoilCap"], "shapes": ["Thirst", "Cold"]},
	"PL_Cotton_Seedling": {"height": 0.180, "parts": ["Pot", "Plant", "SoilCap"], "shapes": ["Thirst", "Cold"]},
}
const RECORDS := ["RelayFault", "ServiceNote", "EvacuationOrder", "AscentManifest"]
const MONITOR_PARTS := ["Base", "Deck", "DeckRiser", "Head", "Screen", "JogWheel", "CompareBar", "StatusStrip", "Key_01", "Key_02", "Key_03", "Key_04", "Key_05", "Key_06", "Socket_Focus", "Socket_Hand"]
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	for id in PLANTS:
		_test_plant(id, PLANTS[id])
	_test_stage_order()
	_test_monitor()
	_test_frames()
	_test_sleeve()
	_test_records()
	_test_tape()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence()
	print("CH05 ASSETS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

## Loads a GLB and adds it to the scene tree at the origin: global transforms (bounds, hinges, sockets) are only
## computed for nodes inside the tree. The caller frees the returned node.
func _place(path: String) -> Node3D:
	var node := AssetGeometryScript.load_glb(path)
	if node != null:
		get_root().add_child(node)
	return node

func _plant_path(id: String) -> String:
	return "res://assets/plants/%s/%s.glb" % [id, id]

## The mesh-local vertex positions of `mesh` with blend shape `shape` at full weight (or the rest pose for -1).
## Mesh.get_aabb() ignores morph targets, so the vertices are blended here the way the renderer does for either
## blend-shape mode.
func _blend_points(mesh: ArrayMesh, shape: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for surface in mesh.get_surface_count():
		var base: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		if shape < 0:
			points.append_array(base)
			continue
		var target: PackedVector3Array = mesh.surface_get_blend_shape_arrays(surface)[shape][Mesh.ARRAY_VERTEX]
		for i in base.size():
			points.append(target[i] if mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_NORMALIZED else base[i] + target[i])
	return points

## How a stress pose changes the plant: the largest vertex move and how far the moved vertices' centroid drops
## (a drooping or cupping blade comes down; a pose that only recolours would move nothing).
func _pose_change(rest: PackedVector3Array, posed: PackedVector3Array) -> Dictionary:
	var largest := 0.0
	var rest_sum := Vector3.ZERO
	var posed_sum := Vector3.ZERO
	var moved := 0
	for i in rest.size():
		var move := rest[i].distance_to(posed[i])
		largest = maxf(largest, move)
		if move > 0.0005:
			rest_sum += rest[i]
			posed_sum += posed[i]
			moved += 1
	var drop := (rest_sum.y - posed_sum.y) / moved if moved > 0 else 0.0
	return {"largest": largest, "drop": drop, "moved": moved}

## The plant mesh that carries the stage's blend shapes (the GLB's `Plant` node).
func _plant_mesh(root: Node3D) -> MeshInstance3D:
	return root.find_child("Plant", true, false) as MeshInstance3D

func _test_plant(id: String, spec: Dictionary) -> void:
	var root := _place(_plant_path(id))
	_check(root != null, id + " loads")
	if root == null:
		return
	for part in spec.parts:
		_check(root.find_child(part, true, false) is MeshInstance3D, "%s has mesh node %s" % [id, part])
	var box := AssetGeometryScript.bounds(root)
	_check(absf(box.size.y - spec.height) <= 0.02 * spec.height, "%s height %.3f m within 2%% of %.3f" % [id, box.size.y, spec.height])
	_check(absf(box.position.y) <= 0.01, "%s stands on the floor (min y %.3f)" % [id, box.position.y])
	_check(box.size.x < 0.17 and box.size.z < 0.17, "%s keeps the PL_Cotton_Young pot footprint" % id)
	var plant := _plant_mesh(root)
	if spec.shapes.is_empty():
		_check(plant == null, id + " is the seed stage: no plant mesh")
	else:
		_check(plant != null and plant.mesh != null, id + " has the Plant mesh")
		if plant != null and plant.mesh != null:
			for shape in spec.shapes:
				var index := plant.find_blend_shape_by_name(shape)
				_check(index != -1, "%s blend shape %s" % [id, shape])
				if index != -1:
					_check(is_zero_approx(plant.get_blend_shape_value(index)), "%s %s rests at 0 (healthy pose is the default)" % [id, shape])
			# a stress pose must change the silhouette, not only the colour: the posed bounds differ from the rest bounds
			var array_mesh := plant.mesh as ArrayMesh
			_check(array_mesh != null, id + " Plant is an ArrayMesh with morph targets")
			if array_mesh != null:
				var rest := _blend_points(array_mesh, -1)
				for shape in spec.shapes:
					var change := _pose_change(rest, _blend_points(array_mesh, plant.find_blend_shape_by_name(shape)))
					_check(change.largest > 0.004 and change.drop > 0.001, "%s %s changes the silhouette: blades move up to %.1f mm and come down %.1f mm on average (%d vertices)" % [id, shape, change.largest * 1000.0, change.drop * 1000.0, change.moved])
	root.free()

func _test_stage_order() -> void:
	var heights := []
	for id in ["PL_Cotton_Seed", "PL_Cotton_Sprout", "PL_Cotton_Seedling", "PL_Cotton_Young"]:
		var root := _place(_plant_path(id))
		if root == null:
			_check(false, id + " loads for the stage order")
			return
		heights.append(AssetGeometryScript.bounds(root).size.y)
		root.free()
	_check(heights[0] < heights[1] and heights[1] < heights[2] and heights[2] < heights[3], "stages grow: seed %.3f < sprout %.3f < seedling %.3f < young %.3f" % heights)

func _test_monitor() -> void:
	var root := _place("res://assets/props/PR_ImpactMonitor/PR_ImpactMonitor.glb")
	_check(root != null, "PR_ImpactMonitor loads")
	if root == null:
		return
	for part in MONITOR_PARTS:
		_check(root.find_child(part, true, false) is Node3D, "PR_ImpactMonitor has node " + part)
	var box := AssetGeometryScript.bounds(root)
	_check(absf(box.size.y - 0.562) <= 0.012 and absf(box.position.y) <= 0.01, "PR_ImpactMonitor 0.56 m tall on the floor (%.3f, min y %.3f)" % [box.size.y, box.position.y])
	var screen := root.find_child("Screen", true, false) as MeshInstance3D
	_check(screen != null and screen.mesh != null and screen.mesh.get_surface_count() == 1, "Screen is one surface")
	if screen != null and screen.mesh != null:
		var material := screen.mesh.surface_get_material(0)
		_check(material != null and material.resource_name == "Screen", "Screen surface carries the Screen material (live-UI convention)")
		var texture := load(FRAMES_DIR + "frames/C02_a_1.png") as Texture2D
		_check(texture != null, "a frame loads as a texture")
		var live := _screen_material(texture)
		screen.set_surface_override_material(0, live)
		_check(screen.get_surface_override_material(0) == live, "the Screen surface accepts a live override")
		var screen_box := AssetGeometryScript.bounds(screen)
		var long_side := maxf(screen_box.size.x, maxf(screen_box.size.y, screen_box.size.z))
		var short_side := minf(screen_box.size.x, screen_box.size.y) if screen_box.size.z < screen_box.size.y else minf(screen_box.size.x, screen_box.size.z)
		_check(absf(long_side - 0.44) < 0.02 and absf(short_side - 0.275) < 0.03, "Screen is about 0.44 x 0.275 m (%.3f x %.3f)" % [long_side, short_side])
	var kit_width := _imported_albedo_width("res://assets/props/PR_ImpactMonitor/PR_ImpactMonitor.glb", "Base")
	_check(kit_width >= 256, "PR_ImpactMonitor's imported plinth keeps the shared kit paint texture (%d px)" % kit_width)
	var jog := root.find_child("JogWheel", true, false) as Node3D
	var key := root.find_child("Key_01", true, false) as Node3D
	var focus := root.find_child("Socket_Focus", true, false) as Node3D
	if jog != null and key != null and focus != null:
		var before := jog.global_transform
		# Blender local Z (the deck normal) is Godot local Y: the jog wheel turns about it and keys press along -Y
		var deck := root.find_child("Deck", true, false) as Node3D
		var normal := deck.global_basis.y.normalized() if deck != null else Vector3.UP
		jog.rotate_object_local(Vector3.UP, 0.5)
		_check(not jog.global_transform.basis.is_equal_approx(before.basis) and jog.global_transform.origin.is_equal_approx(before.origin) and jog.global_basis.y.normalized().dot(normal) > 0.999, "JogWheel turns about its own axle, the deck normal")
		var key_before := key.global_position
		key.translate_object_local(Vector3(0, -0.003, 0))
		_check((key.global_position - key_before).dot(normal) < -0.0029, "a key presses 3 mm into the deck along its local -Y")
		var head := root.find_child("Head", true, false) as Node3D
		# the screen faces the head's local +Z (Blender -Y): the focus socket must be out in front of it, near its centre line
		var ahead := (focus.global_position - head.global_position).dot(head.global_basis.z.normalized()) if head != null else 0.0
		_check(ahead > 0.2 and absf(focus.global_position.x - head.global_position.x) < 0.01, "Socket_Focus sits %.2f m in front of the screen for the camera and the Inspect verb" % ahead)
	root.free()

## The width of the albedo texture on `node_name`'s first surface in Godot's imported scene of `path` (what the gate
## and an exported build load). The kit-textured props share the habitat kit's PNGs; an import that re-embeds them
## leaves empty textures (width 0).
func _imported_albedo_width(path: String, node_name: String) -> int:
	var packed := load(path) as PackedScene
	if packed == null:
		return -1
	var scene := packed.instantiate()
	var mesh := scene.find_child(node_name, true, false) as MeshInstance3D
	var material := mesh.mesh.surface_get_material(0) as BaseMaterial3D if mesh != null and mesh.mesh != null else null
	var width := material.albedo_texture.get_width() if material != null and material.albedo_texture != null else 0
	scene.free()
	return width

func _screen_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material

## Reads a frame PNG straight from disk (not through the import cache), so the pixel checks see the authored values.
func _frame_image(relative: String) -> Image:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(FRAMES_DIR + relative))
	return image if error == OK else null

func _frame_value(image: Image, x: int, y: int) -> float:
	return image.get_pixel(x, y).b if image != null and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height() else -1.0

func _test_frames() -> void:
	var file := FileAccess.open(FRAMES_DIR + "impact_frames.json", FileAccess.READ)
	_check(file != null, "impact_frames.json opens")
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	_check(data is Dictionary, "impact_frames.json parses")
	if not (data is Dictionary):
		return
	var counts: Dictionary = data.get("counts", {})
	_check(counts.get("genuine") == 8 and counts.get("artifacts") == 2 and counts.get("verified_required") == 6 and counts.get("mastery_all") == 8, "P-10 counts: 8 genuine, 2 artifacts, 6 to verify, 8 for mastery (08_PUZZLE_DESIGNS)")
	for state in ["candidate", "paired_reference", "artifact_rejection", "verified_six", "mastery_eight"]:
		_check(data.get("states", {}).has(state), "monitor state described: " + state)
	var candidates: Array = data.get("candidates", [])
	_check(candidates.size() == 10, "ten candidates")
	var genuine := 0
	var artifacts := 0
	var offset: Array = data.get("camera_b_offset_px", [0, 0])
	for c in candidates:
		var kind := String(c.get("kind", ""))
		var frames: Dictionary = c.get("frames", {})
		_check(frames.has("a") and frames.has("b") and frames.a.size() == 3 and frames.b.size() == 3, "%s has three frames from both cameras" % c.id)
		var xy: Array = c.get("detector_xy", [0, 0])
		var a: Array[Image] = []
		var b: Array[Image] = []
		for k in 3:
			a.append(_frame_image(frames.a[k]))
			b.append(_frame_image(frames.b[k]))
		_check(a.all(func(i): return i != null) and b.all(func(i): return i != null), "%s frames exist on disk" % c.id)
		if a.any(func(i): return i == null) or b.any(func(i): return i == null):
			continue
		var va := [_frame_value(a[0], xy[0], xy[1]), _frame_value(a[1], xy[0], xy[1]), _frame_value(a[2], xy[0], xy[1])]
		var vb := [_frame_value(b[0], xy[0] + offset[0], xy[1] + offset[1]), _frame_value(b[1], xy[0] + offset[0], xy[1] + offset[1]), _frame_value(b[2], xy[0] + offset[0], xy[1] + offset[1])]
		if kind == "genuine":
			genuine += 1
			_check(c.get("onset_frame") == 1 and c.get("map_xy") != null, "%s is a mapped transient with an onset" % c.id)
			_check(va[1] > 0.5 and va[0] < 0.35 and va[2] < 0.35, "%s flashes in frame 1 only on camera a (%s)" % [c.id, va])
			_check(vb[1] > 0.5 and vb[0] < 0.35 and vb[2] < 0.35, "%s is seen by the synchronized camera b too (%s)" % [c.id, vb])
		elif kind == "artifact":
			artifacts += 1
			_check(c.get("persistent", false) and c.get("map_xy") == null, "%s is a persistent detector artifact with no map position" % c.id)
			_check(va[0] > 0.5 and va[1] > 0.5 and va[2] > 0.5, "%s stays at the same detector coordinate in every frame (%s)" % [c.id, va])
			_check(vb[0] < 0.35 and vb[1] < 0.35 and vb[2] < 0.35, "%s is absent from camera b (%s)" % [c.id, vb])
		else:
			_check(false, "%s has an unknown kind %s" % [c.id, kind])
	_check(genuine == 8 and artifacts == 2, "eight genuine and two artifacts in the set (%d / %d)" % [genuine, artifacts])
	_check(String(data.get("source", "")).begins_with("authored teaching set"), "the set is labelled as authored, never as an imported observation")

func _surface_names(mesh_instance: MeshInstance3D) -> Array[String]:
	var names: Array[String] = []
	if mesh_instance != null and mesh_instance.mesh != null:
		for i in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.mesh.surface_get_material(i)
			names.append(material.resource_name if material != null else "")
	return names

## CH05 S02->S03: the sealed sleeve Ferreira leaves on her shelf and brings to the table on 14 Dec.
func _test_sleeve() -> void:
	var root := _place("res://assets/props/PR_DocumentSleeve/PR_DocumentSleeve.glb")
	_check(root != null, "PR_DocumentSleeve loads")
	if root == null:
		return
	for part in ["Body", "Lid", "Seal", "LabelWindow", "Latch"]:
		_check(root.find_child(part, true, false) is MeshInstance3D, "PR_DocumentSleeve has mesh node " + part)
	var box := AssetGeometryScript.bounds(root)
	_check(absf(maxf(box.size.x, box.size.z) - 0.335) <= 0.007 and absf(box.position.y) <= 0.01, "PR_DocumentSleeve is an A4 case on the floor (%.3f x %.3f m, min y %.3f)" % [box.size.x, box.size.z, box.position.y])
	var kit_width := _imported_albedo_width("res://assets/props/PR_DocumentSleeve/PR_DocumentSleeve.glb", "Body")
	_check(kit_width >= 256, "PR_DocumentSleeve's imported body keeps the shared kit paint texture (%d px)" % kit_width)
	var lid := root.find_child("Lid", true, false) as Node3D
	var window := root.find_child("LabelWindow", true, false) as MeshInstance3D
	_check(_surface_names(window).has("Label"), "the label window is the live-text slot (material Label)")
	if lid != null and window != null:
		var hinge := lid.global_position
		var window_before := window.global_position
		lid.rotate_object_local(Vector3.RIGHT, deg_to_rad(-100))
		_check(lid.global_position.is_equal_approx(hinge) and window.global_position.distance_to(window_before) > 0.05 and window.global_position.y - window_before.y > 0.05, "the lid opens up about its hinge and carries the label window")
	root.free()

## CH05-S03 clue 17 / CH05-S05 clue 18 / D9: four separable records, blank forms with live-text slots, under clear weights.
func _test_records() -> void:
	var root := _place("res://assets/props/PR_Records2034/PR_Records2034.glb")
	_check(root != null, "PR_Records2034 loads")
	if root == null:
		return
	var box := AssetGeometryScript.bounds(root)
	_check(absf(box.position.y) <= 0.01 and box.size.y < 0.03, "the records lie flat on the table (%.3f m tall)" % box.size.y)
	for kind in RECORDS:
		var record := root.find_child("Record_" + kind, true, false) as MeshInstance3D
		_check(record != null, "record node Record_" + kind)
		if record == null:
			continue
		var names := _surface_names(record)
		_check(names.has("Page_" + kind), "Record_%s front is its own live-text page (Page_%s)" % [kind, kind])
		var back := "Page_EvacuationOrder_Back" if kind == "EvacuationOrder" else "Paper_Back"
		_check(names.has(back), "Record_%s back is %s" % [kind, back])
		# bounds(record) is in the record's own frame, so its pivot is the local origin
		var sheet := AssetGeometryScript.bounds(record)
		var centre := sheet.get_center()
		_check(Vector2(centre.x, centre.z).length() < 0.005, "Record_%s pivots at its own centre, so it can be moved alone (D9; centre offset %.4f m)" % [kind, Vector2(centre.x, centre.z).length()])
		_check(absf(maxf(sheet.size.x, sheet.size.z) - 0.297) < 0.03, "Record_%s is an A4 sheet (%.3f m)" % [kind, maxf(sheet.size.x, sheet.size.z)])
	for i in 4:
		var weight := root.find_child("Weight_%02d" % (i + 1), true, false) as MeshInstance3D
		_check(weight != null, "transparent weight %d" % (i + 1))
		if weight != null and weight.mesh != null:
			var material := weight.mesh.surface_get_material(0) as BaseMaterial3D
			_check(material != null and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and material.albedo_color.a < 0.6, "weight %d is clear acrylic" % (i + 1))
	root.free()

## CH05->CH06 bridge: Kai's marker tape on the guide-light branch.
func _test_tape() -> void:
	var root := _place("res://assets/props/PR_MarkerTape/PR_MarkerTape.glb")
	_check(root != null, "PR_MarkerTape loads")
	if root == null:
		return
	var roll := root.find_child("Roll", true, false) as MeshInstance3D
	var strip := root.find_child("Strip", true, false) as MeshInstance3D
	var socket := root.find_child("Socket_Cable", true, false) as Node3D
	_check(roll != null and strip != null and socket != null, "PR_MarkerTape has Roll, Strip and Socket_Cable")
	var box := AssetGeometryScript.bounds(root)
	_check(absf(box.position.y) <= 0.01 and box.size.y < 0.06, "PR_MarkerTape rests on the floor (%.3f m tall)" % box.size.y)
	if roll != null:
		var roll_box := AssetGeometryScript.bounds(roll)
		_check(absf(roll_box.size.y - 0.019) < 0.002 and absf(roll_box.size.x - 0.056) < 0.004, "the roll is 19 mm tape on a 56 mm roll (%.3f x %.3f)" % [roll_box.size.y, roll_box.size.x])
	if strip != null and socket != null:
		_check(socket.get_parent() == strip or strip.is_ancestor_of(socket), "Socket_Cable moves with the strip")
		# the band's own mesh (without its flag child) is the wrapped ring; its centre is on the cable axis
		var ring_centre := strip.global_transform * strip.get_aabb().get_center()
		_check(socket.global_position.distance_to(ring_centre) < 0.002, "Socket_Cable lies on the wrapped cable's axis (socket %s, ring centre %s)" % [socket.global_position, ring_centre])
		var ring_box := strip.get_aabb()
		var sides := [ring_box.size.x, ring_box.size.y, ring_box.size.z]
		sides.sort()
		_check(absf(sides[0] - 0.0128) < 0.001 and absf(sides[1] - 0.0128) < 0.001 and absf(sides[2] - 0.019) < 0.001, "the strip wraps a 12 mm cable with 19 mm tape (%s)" % [sides])
	root.free()

# ----------------------------------------------------------------------------------------------- evidence

func _evidence() -> void:
	root.size = Vector2i(1600, 1000)
	root.always_on_top = true
	root.grab_focus()
	var caption := _caption()
	# 1: the cotton stages beside the installed young plant, toon materials as in the game
	var stage := _studio(0.62, Vector3(0, 0.15, 0), false, 30.0)
	root.add_child(stage)
	var ids := ["PL_Cotton_Seed", "PL_Cotton_Sprout", "PL_Cotton_Seedling", "PL_Cotton_Young"]
	for i in ids.size():
		var node := AssetGeometryScript.load_glb(_plant_path(ids[i]))
		if node == null:
			continue
		node.position = Vector3(0.30 - i * 0.20, 0.0, 0.0)
		ToonMaterialsScript.apply_to_tree(node, false, true)
		stage.add_child(node)
		_label(stage, ids[i].trim_prefix("PL_Cotton_"), node.position + Vector3(0, -0.02, -0.10), 0.62)
	_set_caption(caption, "M3-5A cotton stages: seed (15 Dec), sprout (late Dec), seedling (early Jan) and the installed young plant (first light)",
		"Same PL_Cotton_Young pot in every stage so the swap never pops. Gossypium hirsutum: acid-delinted seed in its sowing dimple, kidney-shaped cotyledons, then a heart-shaped first true leaf. No eyes or faces. Studio light, toon materials as in play.")
	await _capture("M3-5A_godot_cotton_stages")
	stage.free()
	# 2: the seedling's stress poses, inspectably different silhouettes
	stage = _studio(0.30, Vector3(0, 0.125, 0), false, 18.0)
	root.add_child(stage)
	var poses := [["healthy", ""], ["Thirst 1.0", "Thirst"], ["Cold 1.0", "Cold"]]
	for i in poses.size():
		var node := AssetGeometryScript.load_glb(_plant_path("PL_Cotton_Seedling"))
		if node == null:
			continue
		node.position = Vector3(0.17 - i * 0.17, 0.0, 0.0)
		ToonMaterialsScript.apply_to_tree(node, false, true)
		stage.add_child(node)
		var plant := _plant_mesh(node)
		if plant != null and poses[i][1] != "":
			plant.set_blend_shape_value(plant.find_blend_shape_by_name(poses[i][1]), 1.0)
		_label(stage, poses[i][0], node.position + Vector3(0, 0.205, 0.0), 0.30)
	_set_caption(caption, "M3-5A cotton seedling stress states: blend shapes Thirst and Cold at full weight",
		"Thirst: cotyledons and the true leaf droop, the hypocotyl leans. Cold: blades cup downward and roll under. The silhouette changes, not only the colour. The biology service drives the weights from dated care; the model never plays them on its own.")
	await _capture("M3-5A_godot_cotton_stress")
	stage.free()
	# 3: the sealed document sleeve, closed (S02, on Ferreira's shelf) and opened (S03, at the table)
	stage = _studio(0.70, Vector3(0, 0.10, 0.04), false, 30.0)
	root.add_child(stage)
	for opened in [false, true]:
		var node := AssetGeometryScript.load_glb("res://assets/props/PR_DocumentSleeve/PR_DocumentSleeve.glb")
		if node == null:
			break
		node.position = Vector3(0.20 if not opened else -0.20, 0, 0.0)
		node.rotation_degrees.y = 180 + 32
		ToonMaterialsScript.apply_to_tree(node, false, true)
		stage.add_child(node)
		if opened:
			(node.find_child("Lid", true, false) as Node3D).rotate_object_local(Vector3.RIGHT, deg_to_rad(-105))
			node.find_child("Seal", true, false).visible = false
		_label(stage, "opened (S03)" if opened else "sealed (S02)", node.position + Vector3(0, -0.01, -0.20), 0.70)
	_set_caption(caption, "M3-5A PR_DocumentSleeve: sealed on Ferreira's locker shelf (12 Dec, S02), opened at the table (14 Dec, S03)",
		"Doc 24 2.9 bridge S02 to S03. Rigid A4 archive case: the Lid opens about its hinge and carries the blank LabelWindow (a live-text slot); the orange tamper Seal is hidden once opened. No words or logos on the case.")
	await _capture("M3-5A_godot_bridge_sleeve")
	stage.free()
	# 4: the four 2034 records under their clear weights, as set down on the mission table (clue 17)
	stage = _studio(0.70, Vector3(0, 0.0, 0.05), false, 62.0, 0.55)
	root.add_child(stage)
	var records := AssetGeometryScript.load_glb("res://assets/props/PR_Records2034/PR_Records2034.glb")
	if records != null:
		records.rotation_degrees.y = 180
		ToonMaterialsScript.apply_to_tree(records, false, true)
		stage.add_child(records)
	_set_caption(caption, "M3-5A PR_Records2034: relay fault report, greenhouse service note, evacuation order and ascent manifest under clear weights (CH05-S03 clue 17)",
		"Blank printed forms: words, timestamps, signatures and Ferreira's margin note (back of the order, clue 18) are live document text on the Page_* slots, never baked. Header colours tell them apart: fault orange, service green, order red, manifest navy with a boarding tick per row. Each sheet pivots at its centre (D9).")
	await _capture("M3-5A_godot_bridge_records")
	stage.free()
	# 5: Kai's marker tape: the roll, and one strip clipped by its socket onto a stand-in 12 mm guide-light cable
	stage = _studio(0.16, Vector3(0, 0.03, 0), false, 22.0)
	root.add_child(stage)
	var tape := AssetGeometryScript.load_glb("res://assets/props/PR_MarkerTape/PR_MarkerTape.glb")
	if tape != null:
		tape.rotation_degrees.y = 180
		tape.position.x = 0.018   # the camera looks along +Z, so +X moves the pair left, to the frame centre
		ToonMaterialsScript.apply_to_tree(tape, false, true)
		stage.add_child(tape)
		var socket := tape.find_child("Socket_Cable", true, false) as Node3D
		var strip := tape.find_child("Strip", true, false) as MeshInstance3D
		if socket != null and strip != null:
			# the cable axis is the band's longest local extent (the 19 mm tape width), in world space
			var band := strip.get_aabb().size
			var local_axis := Vector3.RIGHT if band.x >= maxf(band.y, band.z) else (Vector3.UP if band.y >= band.z else Vector3.BACK)
			var along := (strip.global_basis * local_axis).normalized()
			var side := along.cross(Vector3.UP if absf(along.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT).normalized()
			var cable := MeshInstance3D.new()
			var tube := CylinderMesh.new()
			tube.top_radius = 0.006
			tube.bottom_radius = 0.006
			tube.height = 0.11
			var grey := StandardMaterial3D.new()
			grey.albedo_color = Color(0.25, 0.27, 0.31)
			grey.roughness = 0.6
			tube.material = grey
			cable.mesh = tube
			stage.add_child(cable)
			cable.global_transform = Transform3D(Basis(side, along, side.cross(along)), socket.global_position)
			_label(stage, "stand-in 12 mm cable", socket.global_position + Vector3(0, 0.022, 0), 0.16)
	_set_caption(caption, "M3-5A PR_MarkerTape: Kai's 19 mm marker tape, the roll and one strip on the guide-light branch (CH05 to CH06-S01)",
		"Doc 24 2.9 bridge CH05 to CH06: the strip wraps a 12 mm cable once and its two ends press into a flag. The room clips it on by Socket_Cable, which lies on the cable axis (grey cylinder: a stand-in, not part of the asset).")
	await _capture("M3-5A_godot_bridge_tape")
	stage.free()
	# 6 to 8: the impact monitor with its live screen in three of its states, in a dim room as in EX-CH05-S07
	var frames := _frames_data()
	var states := [
		["candidate", "M3-5A impact monitor, state Candidate: one enlarged frame of candidate C02 from camera a",
			"EX-CH05-S07: a dark plain and small flashes enlarged for inspection, no streaks. Keys, compare bar, jog wheel and the status strip are blank hardware; words and reason chips are live UI."],
		["paired_reference", "M3-5A impact monitor, state Paired reference: camera a beside the synchronized camera b, same frame",
			"A real flash (C02) appears in both cameras at the mapped location; a hot pixel would show in camera a only. Two synchronized cameras are how NASA's lunar impact monitoring rejects noise."],
		["artifact_rejection", "M3-5A impact monitor, state Artifact rejection: frames before, event and after for candidate C01",
			"C01 stays at the same detector coordinate in all three frames: a fixed artifact, rejected with a reason. Compare with the transient onset of C02 in the Candidate capture."],
	]
	for s in states:
		stage = _studio(0.86, Vector3(0, 0.32, 0), true, 14.0)
		root.add_child(stage)
		var node := AssetGeometryScript.load_glb("res://assets/props/PR_ImpactMonitor/PR_ImpactMonitor.glb")
		if node == null:
			break
		# the GLB's front faces +Z; the studio camera looks along +Z, so turn it to face the camera, a little to the side
		node.rotation_degrees.y = 180 - 24
		ToonMaterialsScript.apply_to_tree(node, false, true)
		stage.add_child(node)
		var screen := node.find_child("Screen", true, false) as MeshInstance3D
		if screen != null:
			screen.set_surface_override_material(0, _screen_material(_state_texture(frames, s[0])))
		_set_caption(caption, s[1], s[2])
		await _capture("M3-5A_godot_impact_" + s[0])
		stage.free()
	caption.get_parent().get_parent().free()

func _frames_data() -> Dictionary:
	var file := FileAccess.open(FRAMES_DIR + "impact_frames.json", FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return data if data is Dictionary else {}

## Composes the screen content of one monitor state from the authored frames (the game UI does the same with its
## own overlays): one frame, two cameras side by side, or three consecutive frames.
func _state_texture(data: Dictionary, state: String) -> Texture2D:
	var candidates: Array = data.get("candidates", [])
	var pick := func(id: String) -> Dictionary:
		for c in candidates:
			if c.id == id:
				return c
		return {}
	var tiles: Array[Image] = []
	match state:
		"candidate":
			tiles.append(_frame_image(pick.call("C02").frames.a[1]))
		"paired_reference":
			tiles.append(_frame_image(pick.call("C02").frames.a[1]))
			tiles.append(_frame_image(pick.call("C02").frames.b[1]))
		_:
			# frames before, event and after, each an 80 x 50 window round the candidate's detector position, so the
			# fixed hot pixel is visible at the monitor's viewing distance
			var c: Dictionary = pick.call("C01")
			var xy: Array = c.detector_xy
			for k in 3:
				var frame := _frame_image(c.frames.a[k])
				tiles.append(frame.get_region(Rect2i(int(xy[0]) - 40, int(xy[1]) - 25, 80, 50)))
	var w: int = tiles[0].get_width()
	var h: int = tiles[0].get_height()
	var sheet := Image.create(w * tiles.size() + 4 * (tiles.size() - 1), h, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.02, 0.03, 0.05))
	for i in tiles.size():
		sheet.blit_rect(_rgb8(tiles[i]), Rect2i(0, 0, w, h), Vector2i(i * (w + 4), 0))
	# the Screen maps 0..1 UV edge to edge on a 16:10 surface: letterbox the frames on a 1280 x 800 canvas with
	# nearest-neighbour scaling, so detector pixels stay square (not stretched) and a hot pixel stays one sharp dot
	var scale := minf(float(SCREEN_PX.x) / sheet.get_width(), float(SCREEN_PX.y) / sheet.get_height())
	sheet.resize(int(sheet.get_width() * scale), int(sheet.get_height() * scale), Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(SCREEN_PX.x, SCREEN_PX.y, false, Image.FORMAT_RGB8)
	canvas.fill(Color(0.02, 0.03, 0.05))
	canvas.blit_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), (SCREEN_PX - sheet.get_size()) / 2)
	return ImageTexture.create_from_image(canvas)

func _rgb8(image: Image) -> Image:
	var copy := image.duplicate() as Image
	copy.convert(Image.FORMAT_RGB8)
	return copy

## A billboard label about 24 px tall whatever the shot's orthographic `shot_size` (metres of frame height).
func _label(stage: Node3D, text: String, at: Vector3, shot_size: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 36
	label.pixel_size = shot_size * 0.00068
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 8
	label.outline_modulate = Color(1, 1, 1, 0.9)
	label.modulate = Color(0.12, 0.16, 0.27)
	label.position = at
	stage.add_child(label)

func _caption() -> Label:
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.09, 0.86)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(16, 12)
	layer.add_child(panel)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(root.get_visible_rect().size.x - 32 - 36, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98))
	label.add_theme_constant_override("line_spacing", 2)
	panel.add_child(label)
	return label

func _set_caption(label: Label, heading: String, detail: String) -> void:
	label.text = heading + "\n" + detail
	(label.get_parent() as Control).reset_size()

## Neutral studio: grey sweep, key and fill, an orthographic camera framing `size` metres around `look`, seen from
## -Z at `elevation` degrees above the horizon; `bright` scales the key and ambient light (paper needs less).
func _studio(size: float, look: Vector3, dark: bool = false, elevation: float = 21.4, bright: float = 1.0) -> Node3D:
	var stage := Node3D.new()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.17, 0.2) if dark else Color(0.60, 0.61, 0.63)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = (0.2 if dark else 0.35) * bright
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, 35, 0)
	key.light_energy = (0.9 if dark else 1.6) * bright
	key.shadow_enabled = true
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, -120, 0)
	fill.light_energy = 0.5
	stage.add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.2, 0.21, 0.24) if dark else Color(0.52, 0.53, 0.55)
	ground_material.roughness = 0.95
	plane.material = ground_material
	ground.mesh = plane
	ground.position.y = -0.002
	stage.add_child(ground)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = size
	camera.position = look + Vector3(0.0, sin(deg_to_rad(elevation)), -cos(deg_to_rad(elevation))) * size * 1.5
	camera.basis = Basis.looking_at(look - camera.position, Vector3.UP)
	stage.add_child(camera)
	camera.current = true
	return stage

## Saves the window to EVIDENCE_DIR/<label>.png. The first frame after a shader compile can come back solid black
## on Metal ("timeout waiting for fence"), so a frame with no picture in it is taken again, up to five times.
func _capture(label: String) -> void:
	var image: Image = null
	for attempt in 5:
		for _frame in 3 + attempt * 6:
			await process_frame
		await RenderingServer.frame_post_draw
		image = root.get_texture().get_image()
		if not _is_blank(image):
			break
	_check(image != null and not _is_blank(image), "evidence frame has a picture: " + label)
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := image.save_png(path) if image != null else ERR_CANT_CREATE
	_check(error == OK, "evidence written: " + label)

## True when `image` is a single flat colour (a frame the renderer did not draw): a 32 x 20 sample grid whose
## luminance spread is under 2 %.
func _is_blank(image: Image) -> bool:
	if image == null or image.is_empty():
		return true
	var low := 1.0
	var high := 0.0
	for gy in 20:
		for gx in 32:
			var value := image.get_pixel(int((gx + 0.5) * image.get_width() / 32.0), int((gy + 0.5) * image.get_height() / 20.0)).get_luminance()
			low = minf(low, value)
			high = maxf(high, value)
	return high - low < 0.02
