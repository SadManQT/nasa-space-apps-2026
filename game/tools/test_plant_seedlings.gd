# Run: Godot --headless --path game --script res://tools/test_plant_seedlings.gd
#      add `-- --evidence` in a window to save production/qa/evidence/M1-07_garden_*.png
extends SceneTree

## M1-07: Alo's and Tara's seed, cotyledon and true-leaf states. The biology service picks the dated form,
## the garden room shows the matching stage node of PL_Alo_Sprout / PL_Tara_Sprout, and later stages still use
## the existing bud and bloom models.

const Room = preload("res://scripts/world/campaign_room.gd")
const PlantServiceScript = preload("res://scripts/biology/plant_service.gd")
const AssetGeometry = preload("res://scripts/asset_geometry.gd")
const STAGES := ["Stage_Seed", "Stage_Cotyledon", "Stage_TrueLeaf"]

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var service := PlantServiceScript.new()
	_check_dated_forms(service)
	for asset in ["PL_Alo_Sprout", "PL_Tara_Sprout"]:
		_check_model(asset)
	await _check_room(service)
	print("PLANT SEEDLINGS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check_dated_forms(service: PlantServiceScript) -> void:
	var alo: Dictionary = service.new_plant("ALO-01", "", "seed", "2046-04-11 06:00 UTC")
	_check(service.seedling_form(alo) == "seed", "11 Apr: Alo is a sown seed")
	var expected := {"2046-04-12 06:00 UTC": "cotyledon", "2046-04-14 06:00 UTC": "cotyledon",
		"2046-04-15 06:00 UTC": "true_leaf", "2046-04-17 06:00 UTC": "true_leaf", "2046-04-18 06:00 UTC": ""}
	var plant := alo
	for when in expected:
		var advanced: Dictionary = service.advance_to(plant, String(when))
		_check(bool(advanced.get("accepted", false)), "advance accepted to " + String(when))
		plant = advanced.plant
		_check(service.seedling_form(plant) == expected[when], "%s: form %s (stage %s)" % [when, expected[when], plant.stage])
	_check(String(plant.stage) == "bud" and service.seedling_form(plant) == "", "18 Apr: the bud model takes over")
	# a direct jump keeps the same answer as stepping day by day (no playback timer)
	var jumped: Dictionary = service.advance_to(alo, "2046-04-16 00:00 UTC").plant
	_check(service.seedling_form(jumped) == "true_leaf", "jumping straight to 16 Apr gives true leaves")
	# the form survives a save round trip: it is a pure function of the stored dates
	var restored = JSON.parse_string(JSON.stringify(jumped))
	_check(restored is Dictionary and service.seedling_form(restored) == "true_leaf", "saved and reloaded plant keeps its form")
	var tara: Dictionary = service.advance_to(service.new_plant("TARA-01", "", "seed", "2046-04-11 06:00 UTC"), "2046-04-13 00:00 UTC").plant
	_check(service.seedling_form(tara) == "cotyledon", "Tara follows the same dated seedling forms")
	var cotton: Dictionary = service.new_plant("COTTON-01", "", "sprout", "2046-12-15 00:00 UTC")
	_check(service.seedling_form(cotton) == "", "cotton keeps its own art, not the mustard seedling")

func _check_model(asset: String) -> void:
	var model := AssetGeometry.load_glb("res://assets/plants/%s/%s.glb" % [asset, asset])
	_check(model != null, asset + " imports")
	if model == null:
		return
	root.add_child(model)
	_check(model.find_child("Pot", true, false) is MeshInstance3D, asset + " keeps the plant's own pot")
	for stage_name in STAGES:
		var mesh := model.find_child(stage_name, true, false) as MeshInstance3D
		_check(mesh != null, asset + " has " + stage_name)
		if mesh == null or stage_name == "Stage_Seed":
			continue
		var names: Array[String] = []
		for index in mesh.mesh.get_blend_shape_count():
			names.append(String(mesh.mesh.get_blend_shape_name(index)))
		_check(names == ["Droop", "Cup"], asset + " " + stage_name + " carries Droop and Cup posture: " + str(names))
		_check(mesh.get_blend_shape_value(0) == 0.0 and mesh.get_blend_shape_value(1) == 0.0, asset + " " + stage_name + " rests upright by default")
	for node in model.find_children("*", "", true, false):
		var lowered := String(node.name).to_lower()
		_check(not (lowered.contains("eye") or lowered.contains("face") or lowered.contains("mouth")), asset + " has no face part: " + node.name)
	var box := AssetGeometry.bounds(model)
	_check(absf(box.position.y) <= 0.01, asset + " stands on the floor (min y %.3f)" % box.position.y)
	_check(box.size.y < 0.15, asset + " is a seedling, not a grown plant (%.3f m tall)" % box.size.y)
	model.free()

func _check_room(service: PlantServiceScript) -> void:
	var room := Room.new()
	room.room_id = "LOC-03"
	room.load_approved_assets = true
	root.add_child(room)
	var sown: Array = [service.new_plant("ALO-01", "", "seed", "2046-04-11 06:00 UTC"), service.new_plant("TARA-01", "", "seed", "2046-04-11 06:00 UTC")]
	var shots := {"seed": sown}
	for pair in [["cotyledon", "2046-04-12 06:00 UTC"], ["true_leaf", "2046-04-16 06:00 UTC"], ["bud", "2046-04-18 06:00 UTC"]]:
		shots[pair[0]] = sown.map(func(plant): return service.advance_to(plant, String(pair[1])).plant)
	for form in shots:
		room.apply_plant_state(shots[form])
		for prefix in ["PL_Alo_", "PL_Tara_"]:
			var sprout := room.visual_root.get_node_or_null(prefix + "Sprout") as Node3D
			if form == "bud":
				_check(sprout == null or not sprout.visible, prefix + " seedling hides once the bud is due")
				continue
			_check(sprout != null and sprout.visible, prefix + "Sprout shows on " + form)
			if sprout == null:
				continue
			var wanted: String = Room.SEEDLING_NODES[form]
			for stage_name in STAGES:
				var node := sprout.find_child(stage_name, true, false) as Node3D
				_check(node != null and node.visible == (stage_name == wanted), "%sSprout %s visible only on %s" % [prefix, stage_name, wanted])
			var focus_id := "garden_alo_glove_port" if prefix == "PL_Alo_" else "garden_tara_bay"
			var label := room.focus_root.get_node("Focus_" + focus_id).get_child(0) as Label3D
			_check(label.text.contains(String(Room.SEEDLING_WORDS[form])), "the focus label names the form in words: " + label.text)
		var bud := room.visual_root.get_node_or_null("PL_Alo_Bud") as Node3D
		_check((bud != null and bud.visible) == (form == "bud"), "PL_Alo_Bud shows only from its dated bud stage (" + form + ")")
		var bloom := room.visual_root.get_node_or_null("PL_Tara_Bloom") as Node3D
		_check(bloom == null or not bloom.visible, "Tara's bloom never shows before 30 Apr (" + form + ")")
		if OS.get_cmdline_user_args().has("--evidence"):
			await _capture(room, form)
	room.free()
	await process_frame

func _capture(room: Node3D, form: String) -> void:
	root.size = Vector2i(1600, 900)
	var camera := room.get_node_or_null("EvidenceCamera") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "EvidenceCamera"
		camera.fov = 30.0
		room.add_child(camera)
	camera.current = true
	# Alo grows inside the opaque PR_GrowthChamber, so her close-up is a labelled cutaway with the shell hidden.
	var chamber := room.visual_root.get_node_or_null("PR_GrowthChamber") as Node3D
	for shot in [["alo_cutaway", "PL_Alo_"], ["tara", "PL_Tara_"]]:
		if chamber != null:
			chamber.visible = shot[0] != "alo_cutaway"
		var target := _plant_position(room, shot[1]) + Vector3(0.0, 0.07, 0.0)
		camera.position = target + Vector3(0.07, 0.09, 0.27)
		camera.look_at(target)
		for index in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-07_garden_%s_%s.png" % [shot[0], form]))
	if chamber != null:
		chamber.visible = true
	# The garden's own overview (review_views in its room data), so the shot follows the room layout.
	var overview: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign/rooms/LOC-03.json")).review_views.overview
	camera.position = Vector3(overview.from[0], overview.from[1], overview.from[2])
	camera.look_at(Vector3(overview.to[0], overview.to[1], overview.to[2]))
	for index in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-07_garden_wide_%s.png" % form))

## Where the room placed the plant whose model name starts with prefix (its visible stage model).
func _plant_position(room: Node3D, prefix: String) -> Vector3:
	for model in room.visual_root.get_children():
		if String(model.name).begins_with(prefix) and (model as Node3D).visible:
			return (model as Node3D).position
	return Vector3.ZERO

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)
