## M3-6A: the Chapter 6 eclipse power props load with collision and a Compatibility LOD, share the habitat kit's
## textures, expose every part, lamp, screen, label and socket the P-11 / P-12 scenes need, and pose correctly:
## the board takes the five segment cards and the 08 accepted plan, the panel's P-12 presets never touch the
## protected essentials, the monitor shows a geometrically honest eclipse with a labelled, not-to-scale inset.
## Headless: game/tools/run_tests.sh eclipse_props
## Evidence (needs a window): Godot --path game --script res://tools/test_eclipse_props.gd -- --evidence
extends SceneTree

const Props = preload("res://assets/props/eclipse_power/eclipse_props.gd")
const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const KIT_TEXTURES := "res://assets/environment/kit/textures/"
const EXPECTED := ["PR_EclipseBoard", "PR_SegmentCard", "PR_ServiceTag", "PR_GuideLightBranch", "PR_GuideLightRun",
	"PR_DecorativeFlood", "PR_ProtectedBusPanel", "PR_FilteredCamera", "PR_EclipseMonitor"]
const SEGMENTS := ["precharge", "ingress", "totality", "egress", "recovery"]  # EX-CH06-S03, 08 P-11
const PROTECTED := ["Air", "Heat", "Grow", "Guide"]                              # the essential package
const SPECIAL_MATERIALS := ["Lamp", "LightLens", "Screen", "FilterGlass", "CameraGlass", "M_Kit_Glass"]
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
	var catalog := Props.catalog()
	_check(Array(Props.ids()) == EXPECTED, "nine CH06 props in catalogue order: %s" % [Props.ids()])
	for id in EXPECTED:
		_check(Props.prop_content(id).size() > 0, id + " has authored content")
		_test_prop(Props.prop(id))
	_test_content_text()
	_test_board()
	_test_panel()
	_test_guide_and_flood()
	_test_camera()
	_test_monitor()
	await _test_collision()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence()
	print("ECLIPSE PROPS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

# ----------------------------------------------------------------------------------------------- per prop

func _surfaces(root: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			out.append({"mesh": mi, "material": mi.mesh.surface_get_material(s)})
	return out

func _special(material: Material) -> bool:
	for prefix in SPECIAL_MATERIALS:
		if material.resource_name.begins_with(prefix):
			return true
	return false

func _test_prop(entry: Dictionary) -> void:
	var id: String = entry.id
	_check(entry.lods.size() == 2 and entry.triangles.size() == 2, id + " has a game LOD and a Compatibility LOD")
	var cap := 40000 if id in ["PR_EclipseBoard", "PR_ProtectedBusPanel", "PR_FilteredCamera"] else 15000 if id == "PR_EclipseMonitor" else 5000
	_check(int(entry.triangles[0]) <= cap and int(entry.triangles[1]) < int(entry.triangles[0]), id + " within the art bible budget and LOD1 lighter than LOD0")
	for path in entry.lods:
		_check(load(path) is PackedScene, "load " + String(path))
	var node := Props.instance(id)
	root.add_child(node)
	var lod0: Node3D = node.get_node("LOD0")
	var lod1: Node3D = node.get_node("LOD1")
	_check(lod0.find_children("*", "StaticBody3D", true, false).size() > 0, id + " game LOD carries collision")
	_check(lod1.find_children("*", "StaticBody3D", true, false).is_empty(), id + " Compatibility LOD has no collision")
	var ranges := true
	for mesh in lod0.find_children("*", "MeshInstance3D", true, false):
		ranges = ranges and mesh.visibility_range_end == float(entry.lod_distance_m)
	for mesh in lod1.find_children("*", "MeshInstance3D", true, false):
		ranges = ranges and mesh.visibility_range_begin == float(entry.lod_distance_m) and mesh.visibility_range_end == 0.0
	_check(ranges, id + " LOD ranges meet at %s m" % entry.lod_distance_m)
	# textures: every opaque painted surface uses the kit's own texture files (stored once), 1024 / 512 px
	for lod in 2:
		var group: Node3D = lod0 if lod == 0 else lod1
		var shared := true
		var opaque := 0
		var max_tex := 0
		for slot in _surfaces(group):
			var mat := slot.material as StandardMaterial3D
			if mat == null or _special(mat):
				continue
			opaque += 1
			shared = shared and mat.albedo_texture != null and mat.normal_texture != null \
				and mat.albedo_texture.resource_path.begins_with(KIT_TEXTURES) and mat.normal_texture.resource_path.begins_with(KIT_TEXTURES)
			for t in [mat.albedo_texture, mat.normal_texture]:
				if t != null:
					max_tex = maxi(max_tex, maxi(t.get_width(), t.get_height()))
		_check(opaque > 0 and shared, "%s LOD%d paints every opaque surface with the shared kit textures" % [id, lod])
		_check(max_tex > 0 and max_tex <= (1024 if lod == 0 else 512), "%s LOD%d texture size %d px within %d" % [id, lod, max_tex, 1024 if lod == 0 else 512])
	# size, floor and anchor
	var box := _bounds(lod0, node)
	_check(absf(box.position.y) <= 0.005, id + " lowest point on y = 0 (%.4f)" % box.position.y)
	var size: Array = entry.size_m
	_check(box.size.distance_to(Vector3(size[0], size[1], size[2])) <= 0.004, "%s imported size %s matches the catalogue %s" % [id, box.size, size])
	if entry.anchor == "wall" or id == "PR_ProtectedBusPanel":
		_check(box.end.z <= 0.005 and box.position.z < -0.02, id + " back plane on z = 0, body towards -Z (the room)")
	# every named node the puzzles and rooms use
	for kind in ["parts", "lamps", "screens"]:
		for key in entry.get(kind, {}):
			var node_name: String = key if kind == "parts" else entry[kind][key].node
			_check(Props.nodes_named(node, node_name).size() == 2, "%s %s %s exists in both LODs" % [id, kind, node_name])
	for kind in ["labels", "sockets"]:
		for key in entry.get(kind, {}):
			_check(lod0.find_child(entry[kind][key].node, true, false) != null, "%s %s %s exists in the game LOD" % [id, kind, entry[kind][key].node])
	for label_id in entry.get("labels", {}):
		var text := Props.label(node, label_id)
		_check(text != null and text.pixel_size > 0.0 and is_equal_approx(text.rotation_degrees.y, 180.0), "%s label %s is a Label3D facing the room" % [id, label_id])
	# presets reference real lamps, parts, positions and labels, and apply cleanly
	var content := Props.prop_content(id)
	for state_name in Props.states(id):
		var preset: Dictionary = content.states[state_name]
		for lamp_id in preset.get("lamps", {}):
			_check(entry.lamps.has(lamp_id) and Props.content().lamp_states.has(preset.lamps[lamp_id]), "%s.%s lamp %s" % [id, state_name, lamp_id])
		for part_id in preset.get("parts", {}):
			_check(entry.parts.has(part_id) and entry.parts[part_id].positions.has(preset.parts[part_id]), "%s.%s part %s -> %s" % [id, state_name, part_id, preset.parts[part_id]])
		for label_id in preset.get("label_visible", {}):
			_check(entry.labels.has(label_id), "%s.%s label %s" % [id, state_name, label_id])
		Props.apply_state(node, state_name)
		_check(node.get_meta("eclipse_state") == state_name, "%s applies preset %s" % [id, state_name])
	for label_id in content.get("labels", {}):
		_check(entry.labels.has(label_id), "%s authored label %s has a plate" % [id, label_id])
	node.free()

## Bounds of a LOD's meshes in the prop's own space.
func _bounds(group: Node3D, prop_root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh in group.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh as MeshInstance3D
		var xf := prop_root.global_transform.affine_inverse() * mi.global_transform
		var aabb := xf * mi.get_aabb()
		box = aabb if first else box.merge(aabb)
		first = false
	return box

## English only (no Bangla script), no logos named on equipment, no geography painted on the eclipse view.
func _test_content_text() -> void:
	var words: Array[String] = []
	for id in EXPECTED:
		var content := Props.prop_content(id)
		for label_id in content.get("labels", {}):
			var spec = content.labels[label_id]
			words.append(spec if spec is String else String(spec.get("text", "")))
			if spec is Dictionary:
				for w in spec.get("words", {}).values():
					words.append(String(w))
		for v in content.get("variants", []):
			for t in v.get("labels", {}).values():
				words.append(String(t))
	for state in Props.content().lamp_states.values():
		words.append(String(state.word))
	var clean := true
	for w in words:
		for i in w.length():
			var code := w.unicode_at(i)
			clean = clean and (code < 0x0980 or code > 0x09FF)
		clean = clean and not w.to_upper().contains("NASA")
	_check(words.size() > 60 and clean, "every prop word is English with no Bangla script and no agency mark (%d strings)" % words.size())

# ----------------------------------------------------------------------------------------------- board (P-11)

func _test_board() -> void:
	var board := Props.instance("PR_EclipseBoard")
	root.add_child(board)
	var xs: Array[float] = []
	for k in 5:
		var slot := Props.socket(board, "Card_%d" % (k + 1))
		_check(slot != null, "board card slot %d" % (k + 1))
		if slot != null:
			xs.append(slot.position.x)
	# the viewer stands on -Z, so left to right on the board is +X to -X
	_check(xs.size() == 5 and xs[0] > xs[1] and xs[1] > xs[2] and xs[2] > xs[3] and xs[3] > xs[4], "segment slots read left to right: %s" % [xs])
	var cells := 0
	for s in 5:
		for r in 4:
			cells += 1 if Props.socket(board, "Tag_%d_%d" % [s + 1, r + 1]) != null else 0
	_check(cells == 20, "20 service-tag cells (5 segments x 4 services)")
	_check(Array(Props.variant_ids("PR_SegmentCard")) == SEGMENTS, "card variants are the five canon segments in order")
	_check(Array(Props.prop_content("PR_EclipseBoard").rows) == ["essentials", "return_pump", "camera", "decorative_floods"], "board rows: essentials, pump, camera, floods")
	var placed := Props.populate_board(board, "accepted_plan")
	var cards := placed.filter(func(n): return n.get_meta("eclipse_prop") == "PR_SegmentCard")
	var tags := placed.filter(func(n): return n.get_meta("eclipse_prop") == "PR_ServiceTag")
	_check(cards.size() == 5 and tags.size() == 7, "accepted plan: 5 cards and 7 service tags (5 essentials + pump once + camera once = 7)")
	var grid := {}
	for tag in tags:
		grid[String(tag.get_parent().name).trim_prefix("Socket_")] = tag.get_meta("eclipse_variant")
	var essentials := true
	for s in 5:
		essentials = essentials and grid.get("Tag_%d_1" % (s + 1), "") == "essentials"
	_check(essentials, "essentials in all five segments (08 P-11: [1,1,1,1,1])")
	_check(grid.get("Tag_1_2", "") == "return_pump" and grid.get("Tag_2_3", "") == "camera", "pump in segment 1, camera in segment 2")
	_check(not grid.values().has("decorative_floods"), "decorative floods all off")
	for k in 5:
		var card: Node3D = cards[k]
		var text := Props.label(card, "Name")
		_check(text != null and text.text.contains(String(SEGMENTS[k]).to_upper()), "card %d reads %s" % [k + 1, SEGMENTS[k]])
		_check(Props.lamp_state(board, "Seg%d" % (k + 1)) == "ok", "segment %d lamp protected in the accepted plan" % (k + 1))
	_check(Props.label(board, "SegState1").text == "PROTECTED", "segment state is words as well as colour")
	Props.apply_state(board, "segment3_unprotected")
	_check(Props.label(board, "SegState3").text == "SERVICE MISSING", "a missing package names its segment in words")
	board.free()

# ----------------------------------------------------------------------------------------------- panel (P-12)

func _test_panel() -> void:
	var panel := Props.instance("PR_ProtectedBusPanel")
	root.add_child(panel)
	var content := Props.prop_content("PR_ProtectedBusPanel")
	for state_name in Props.states("PR_ProtectedBusPanel"):
		var preset: Dictionary = content.states[state_name]
		var essentials := true
		for lamp in PROTECTED:
			essentials = essentials and preset.lamps.get(lamp, "") == "ok"
		_check(essentials, "preset %s keeps the four protected essentials on" % state_name)
		_check(preset.parts.get("ProtectedGuard", "closed") == "closed", "preset %s leaves the protected guard sealed" % state_name)
	# P-12 order: isolate before reset, fault cleared before reset, reconnect only after reset, camera branch only
	var sequence: Array = content.sequences.p12_restore
	var seen_isolated := false
	var reset_ok := true
	var previous_breaker := ""
	for state_name in sequence:
		var parts: Dictionary = content.states[state_name].parts
		var lamps: Dictionary = content.states[state_name].lamps
		if parts.get("F2Isolator", "") == "isolated":
			seen_isolated = true
		if parts.get("F2Breaker", "") == "on" and previous_breaker in ["tripped", "off"]:
			reset_ok = reset_ok and seen_isolated and parts.get("F2Isolator", "") == "isolated" and lamps.get("F2Fault", "") == "off"
		previous_breaker = parts.get("F2Breaker", previous_breaker)
		Props.apply_state(panel, state_name)
	_check(sequence.size() == 5 and reset_ok, "P-12 sequence: isolate, fault cleared, reset, reconnect (%s)" % [sequence])
	_check(Props.part_position(panel, "F2Isolator") == "connected" and Props.lamp_state(panel, "F2") == "ok", "F2 restored and its lamp back on")
	Props.apply_state(panel, "f2_tripped")
	_check(Props.label(panel, "F2").text == "F2 CAMERA\nFAULT" and Props.label(panel, "F2Controls").text == "F2 BREAKER\nTRIPPED", "the trip is in words on the plates")
	_check(Props.label(panel, "Air").text == "AIR\nON", "protected branch plates still read ON during the trip")
	var lever := Props.nodes_named(panel, "F2Breaker")
	_check(lever.size() == 2 and is_equal_approx((lever[0] as Node3D).rotation_degrees.x, 0.0), "tripped breaker lever sits in the middle")
	Props.apply_state(panel, "f2_isolated")
	var iso := Props.nodes_named(panel, "F2Isolator")
	_check(is_equal_approx((iso[0] as Node3D).rotation_degrees.z, 90.0) and is_equal_approx((iso[1] as Node3D).rotation_degrees.z, 90.0), "isolator turns a quarter clockwise in both LODs")
	_check(Props.label(panel, "ColF2").text == "F2 ISOLATOR\nISOLATED", "isolation in words")
	var button := Props.nodes_named(panel, "F2TestButton")[0] as Node3D
	var rest := button.position
	Props.set_part(panel, "F2TestButton", "pressed")
	_check(is_equal_approx(button.position.z - rest.z, 0.004), "test button travels 4 mm into the panel")
	Props.apply_state(panel, "test_disconnected")
	_check(Props.lamp_state(panel, "Test") == "off" and Props.lamp_state(panel, "Air") == "ok" and Props.label(panel, "Test").text == "TEST BRANCH\nDISCONNECTED", "S05 rehearsal drops only the test branch")
	var lamp := Props.nodes_named(panel, "Lamp_F2Fault")[0] as GeometryInstance3D
	Props.set_lamp(panel, "F2Fault", "fault")
	var mat := lamp.material_override as StandardMaterial3D
	_check(mat != null and mat.emission_enabled and mat.emission.r > 0.9, "fault lamp glows red")
	var label := Props.attach_text_screen(panel, "Main", "")
	_check(label != null and Props.screen_surfaces(panel).size() >= 4, "status text on the live screen; screens Main and F2Current in both LODs")
	Props.apply_state(panel, "f2_tripped")
	_check(label.text.contains("F2 CAMERA FAULT") and label.text.contains("AIR ON"), "the status screen follows the preset in words")
	for state_name in Props.states("PR_ProtectedBusPanel"):
		var current: String = content.states[state_name].screens.F2Current
		var numbers: Array[String] = []
		for word in current.split(" ", false):
			if word.is_valid_float():
				numbers.append(word)
		_check(numbers.is_empty() or numbers == ["0"], "F2 readout in %s shows no invented number (%s)" % [state_name, current])
	panel.free()

# ----------------------------------------------------------------------------------------------- guide light and flood

func _test_guide_and_flood() -> void:
	var branch := Props.prop("PR_GuideLightBranch")
	var run := Props.prop("PR_GuideLightRun")
	var branch_y := float(branch.mount_y) + float(branch.parts.Diffuser.pivot_m[1])
	var run_y := float(run.mount_y) + float(run.parts.Diffuser.pivot_m[1])
	_check(is_equal_approx(branch_y, run_y), "branch and run channels line up on the wall (%.3f / %.3f m)" % [branch_y, run_y])
	_check(branch_y > 0.33 and branch_y < 0.95, "guide light runs low along the wall, above the skirting and under the handrail")
	var node := Props.instance("PR_GuideLightBranch")
	root.add_child(node)
	_check(Props.socket(node, "RunJoin").position.is_equal_approx(Vector3(-0.5, 0, 0)), "a run joins at the branch's right end on the 1 m grid")
	Props.apply_state(node, "taped")
	_check(Props.nodes_named(node, "MarkerTape")[0].visible and not Props.label(node, "Branch").visible, "CH05->CH06 bridge: Kai's marker tape on the circuit, branch not yet labelled")
	Props.apply_state(node, "labelled_on")
	_check(Props.label(node, "Branch").visible and Props.label(node, "Branch").text.begins_with("GUIDE LIGHT"), "S04->S05 join: the labelled guide-light branch")
	var lights := node.get_node_or_null("Lights")
	_check(lights != null and lights.get_child_count() >= 2 and lights.get_child(0) is OmniLight3D, "guide light on: amber lights along the channel")
	Props.apply_state(node, "labelled_off")
	_check(node.get_node_or_null("Lights") == null and Props.label(node, "BranchState").text == "SUPPLY OFF", "guide light off, in words")
	node.free()
	var flood := Props.instance("PR_DecorativeFlood")
	root.add_child(flood)
	var head := Props.nodes_named(flood, "Head")[0] as Node3D
	_check(is_equal_approx(head.rotation_degrees.x, -25.0), "flood head ships aimed 25 degrees down")
	Props.apply_state(flood, "on")
	var spot := Props.socket(flood, "Light").get_child(0)
	_check(spot is SpotLight3D, "flood on: a spot light at the lens")
	_check((spot as Node3D).global_basis.z.y > 0.3, "the flood shines downward")
	Props.apply_state(flood, "off")
	_check(Props.socket(flood, "Light").get_child_count() == 0, "decorative flood shed")
	flood.free()

func _test_camera() -> void:
	var cam := Props.instance("PR_FilteredCamera")
	root.add_child(cam)
	_check(Props.part_position(cam, "Filter") == "in", "camera starts in the protective configuration (filter in)")
	var flap := Props.nodes_named(cam, "Filter")[0] as Node3D
	Props.apply_state(cam, "filter_out")
	_check(is_equal_approx(flap.rotation_degrees.x, 115.0), "filter flap swings up out of the light path")
	Props.apply_state(cam, "f2_lost")
	_check(Props.lamp_state(cam, "Power") == "off", "F2 drop shows on the camera's power lamp")
	cam.free()

# ----------------------------------------------------------------------------------------------- monitor (S07)

func _test_monitor() -> void:
	var monitor := Props.instance("PR_EclipseMonitor")
	root.add_child(monitor)
	var screen = Props.attach_monitor_screen(monitor)  # untyped: the screen script's own API
	var live := 0
	for slot in Props.screen_surfaces(monitor):
		var m := (slot.mesh as MeshInstance3D).get_surface_override_material(slot.surface) as StandardMaterial3D
		live += 1 if m != null and m.albedo_texture is ViewportTexture else 0
	_check(live == 2, "the camera picture is on Screen_Main in both LODs")
	# science: from the Moon, Earth looks about 3.5 times wider than the Sun (12,742 km at 384,400 km vs 0.54 deg)
	var earth_deg := rad_to_deg(2.0 * atan(6371.0 / 384400.0))
	_check(absf(earth_deg / 0.542 - float(screen.data.science.earth_to_sun_width_ratio)) < 0.1, "Earth/Sun width ratio %.2f matches the data" % (earth_deg / 0.542))
	_check(is_equal_approx(screen.visible_fraction(0.0), 1.0) and is_equal_approx(screen.visible_fraction(1.0), 1.0), "the Sun is whole before first and after last contact")
	_check(screen.ring_visible(0.5) and not screen.ring_visible(0.12) and not screen.ring_visible(0.88), "totality (the red rim) only mid-eclipse")
	_check(screen.visible_fraction(0.2) < 1.0 and screen.visible_fraction(0.2) > 0.0, "a partial bite at ingress")
	_check(screen.exposure_gain(0.5) > screen.exposure_gain(0.2) and screen.exposure_gain(0.2) > screen.exposure_gain(0.0), "auto exposure rises as the Sun is covered")
	_check(screen.eclipse_date() == "12 Jan 2047", "date from the NASA fixture: %s" % screen.eclipse_date())
	var words := "\n".join(screen.all_text())
	_check(words.contains("12 Jan 2047") and words.contains("(checked)") and words.contains("scenario"), "checked date and scenario geometry labelled apart")
	_check(words.contains("not to scale") and words.contains("not a map of Earth") and words.contains("limb"), "inset labelled conceptual, not to scale, not a map")
	_check(not words.contains("Bangladesh") and not words.contains("sunrise"), "no geographic stripe or sunrise claim on the camera image")
	screen.set_logged("ring", true)
	_check(words.contains("NOT LOGGED") and "\n".join(screen.all_text()).contains("RING  -  LOGGED"), "observation chips say logged in words")
	screen.set_mode("no_signal")
	_check(not screen.get_node("CameraView").visible and screen.get_node("NoSignal").visible, "F2 drop: the screen says NO SIGNAL")
	screen.set_mode("held")
	_check(screen.get_node("CameraView").visible, "held frame stays on screen")
	screen.show_inset(false)
	_check(not screen.inset_visible(), "the inset can be closed")
	monitor.free()

# ----------------------------------------------------------------------------------------------- collision

func _test_collision() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var panel := Props.place(world, "PR_ProtectedBusPanel", Vector3(0, 0, 0))
	var board := Props.place(world, "PR_EclipseBoard", Vector3(3, 0, 0))
	var camera := Props.place(world, "PR_FilteredCamera", Vector3(-3, 0, 0))
	await physics_frame
	await physics_frame
	var space := world.get_world_3d().direct_space_state
	var hit_panel := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 1.2, -2), Vector3(0, 1.2, 1)))
	_check(not hit_panel.is_empty() and absf(hit_panel.position.z + 0.46) < 0.02, "a ray from the room hits the panel's front (%s)" % [hit_panel.get("position", "none")])
	var hit_board := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(3, 1.6, -2), Vector3(3, 1.6, 1)))
	_check(not hit_board.is_empty() and hit_board.position.z > -0.08, "a ray hits the wall board at its mount height")
	var hit_cam := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-3, 1.75, -2), Vector3(-3, 1.75, 1)))
	_check(not hit_cam.is_empty(), "the camera head blocks")
	_check(is_equal_approx(board.position.y, 1.10), "wall props are lifted to their mount height")
	world.free()

# ----------------------------------------------------------------------------------------------- evidence

const SERVICE_WHITE := Color(1.0, 0.89, 0.81)  # 5000 K: service rooms (art bible section 4)

func _evidence() -> void:
	root.size = Vector2i(1600, 1000)
	root.always_on_top = true
	root.grab_focus()
	var caption := _caption()
	# 1-2: every prop on a neutral stage, game LOD then Compatibility LOD
	for lod in 2:
		var stage := _studio()
		root.add_child(stage)
		# back row: board, panel, camera, monitor; front row: card, tag, guide branch, guide run, flood (+X is screen left)
		var spots := [Vector3(2.9, 0.75, 1.6), Vector3(2.55, 0.0, -1.1), Vector3(1.6, 0.0, -1.1), Vector3(0.45, 0.0, -1.1), Vector3(-0.95, 0.0, -1.1),
			Vector3(-2.45, 0.35, -1.1), Vector3(0.75, 0.0, 1.6), Vector3(-0.95, 0.0, 1.6), Vector3(-2.6, 0.75, 1.6)]
		var shown := {}
		for i in EXPECTED.size():
			var id: String = EXPECTED[i]
			var node := Props.instance(id, false, 0 if lod == 0 else 1, "totality" if id == "PR_SegmentCard" else "camera" if id == "PR_ServiceTag" else "")
			if lod == 1:
				node.get_node("LOD0").visible = false
				for mesh in node.get_node("LOD1").find_children("*", "GeometryInstance3D", true, false):
					mesh.visibility_range_begin = 0.0
			node.position = spots[i]
			if id in ["PR_SegmentCard", "PR_ServiceTag"]:
				node.scale = Vector3.ONE * 3.0
			stage.add_child(node)
			shown[id] = node
			var tag := Label3D.new()
			tag.text = id.trim_prefix("PR_")
			tag.font_size = 32
			tag.pixel_size = 0.0045
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			tag.no_depth_test = true
			tag.outline_size = 10
			tag.outline_modulate = Color(1, 1, 1, 0.9)
			tag.modulate = Color(0.12, 0.16, 0.27)
			tag.position = Vector3(spots[i].x, 0.02, spots[i].z - (0.75 if spots[i].z > 0 else 0.35))
			stage.add_child(tag)
		Props.populate_board(shown.PR_EclipseBoard, "accepted_plan")
		Props.apply_state(shown.PR_ProtectedBusPanel, "f2_tripped")
		Props.apply_state(shown.PR_DecorativeFlood, "on")
		var studio_screen = Props.attach_monitor_screen(shown.PR_EclipseMonitor)
		studio_screen.set_phase(0.5)
		_set_caption(caption, "M3-6A Chapter 6 eclipse power props, %s" % ["LOD0: game LOD with collision" if lod == 0 else "LOD1: Compatibility build, 512 px kit textures"],
			"Board with the five segment cards and the P-11 accepted plan, segment card and service tag (x3), guide-light branch and run (lit), decorative flood (on), protected-bus panel (F2 tripped), filtered camera (filter in), monitor (ring). Neutral studio light.")
		await _capture("M3-6A_props_lod%d" % lod)
		stage.free()
	# 3: the power room built from the habitat kit, eclipse schedule (floods shed, guide light on)
	var room := _power_room()
	root.add_child(room)
	var camera := Camera3D.new()
	camera.fov = 62
	room.add_child(camera)
	camera.current = true
	camera.position = Vector3(3.1, 1.62, 0.35)
	camera.look_at(Vector3(3.2, 1.15, 4.0))
	_set_caption(caption, "M3-6A in the power room (LOC-02), built from the M1-05 habitat kit: the eclipse schedule",
		"Allocation board with the five cards and the accepted plan; protected-bus panel (floods shed); the guide-light branch leaves the panel with Kai's orange marker tape and runs low along the wall, lit amber; decorative flood off. 5000 K service strips.")
	await _capture("M3-6A_power_room")
	# 4-5: panel close-ups, F2 tripped then isolated (P-12)
	var panel: Node3D = room.get_node("PR_ProtectedBusPanel")
	Props.apply_state(panel, "f2_tripped")
	camera.fov = 40
	camera.position = Vector3(4.62, 1.46, 1.95)
	camera.look_at(Vector3(4.95, 1.44, 3.9))
	_set_caption(caption, "M3-6A protected-bus test panel, P-12: feeder F2 has tripped",
		"Mimic: the four protected essentials stay ON left of the orange isolation boundary; F2 CAMERA reads FAULT, the fault lamp is lit, the F2 breaker sits TRIPPED. The essentials' breakers are sealed under the guard. Every state is words as well as colour.")
	await _capture("M3-6A_panel_f2_tripped")
	Props.apply_state(panel, "f2_isolated")
	camera.fov = 34
	camera.position = Vector3(4.78, 1.3, 2.78)
	camera.look_at(Vector3(4.66, 1.24, 3.42))
	_set_caption(caption, "M3-6A protected-bus test panel, P-12: F2 isolated before any reset",
		"The orange isolator is a quarter turn clockwise (ISOLATED); F2 reads NO SUPPLY; the breaker stays tripped until the fault is cleared. Protected essentials unchanged.")
	await _capture("M3-6A_panel_f2_isolated")
	Props.apply_state(panel, "eclipse_schedule")
	# 6: board close-up
	camera.fov = 44
	camera.position = Vector3(2.5, 1.62, 2.35)
	camera.look_at(Vector3(2.5, 1.6, 4.0))
	_set_caption(caption, "M3-6A eclipse allocation board, P-11 accepted plan (EX-CH06-S03)",
		"Five segment cards left to right: precharge, ingress, totality, egress, recovery. Essentials in every segment, return pump once (segment 1), camera once (segment 2), decorative floods none: seven tags. Each segment lamp says PROTECTED in words.")
	await _capture("M3-6A_board_plan")
	# 7-8: matched corridor previews for S04: decorative floods on, then shed with the guide light kept
	camera.fov = 66
	camera.position = Vector3(5.4, 1.55, 0.55)
	camera.look_at(Vector3(1.2, 0.9, 3.4))
	# the eclipse schedule's dim service level (the room "can be dim while a reliable route remains visible")
	for lamp in get_nodes_in_group("service_lights"):
		(lamp as SpotLight3D).light_energy = 0.22
	for flood in room.find_children("PR_DecorativeFlood*", "Node3D", false, false):
		Props.apply_state(flood, "on")
	_set_caption(caption, "M3-6A matched preview A (EX-CH06-S04): decorative floods on",
		"Same room, same view, service lights at their eclipse level: the two decorative floods light the room. In the P-11 teaching model this brightness spends reserve without serving circulation, return water or the camera.")
	await _capture("M3-6A_s04_floods_on")
	for flood in room.find_children("PR_DecorativeFlood*", "Node3D", false, false):
		Props.apply_state(flood, "off")
	_set_caption(caption, "M3-6A matched preview B (EX-CH06-S04): floods shed, guide light protected",
		"Only the change in decorative lighting differs from preview A: the room is dimmer, the small amber guide light still marks a known way through.")
	await _capture("M3-6A_s04_guide_only")
	room.free()
	# 9-10: monitor at totality with the inset, then the screen itself at full resolution
	var desk := _monitor_desk()
	root.add_child(desk)
	var monitor: Node3D = desk.get_node("PR_EclipseMonitor")
	var screen = monitor.get_node("MonitorView/EclipseMonitorScreen")
	screen.set_phase(0.5)
	screen.set_logged("ingress", true)
	screen.set_logged("ring", true)
	_set_caption(caption, "M3-6A filtered-camera monitor at the mission table (EX-CH06-S07): the red ring",
		"Instrument view, not a window. Earth's night side hides the Sun; only the refracted rim is lit. The labelled inset explains it and is not a map; the checked date and Aurora's scenario geometry are labelled apart.")
	await _capture("M3-6A_monitor_ring")
	await _save_viewport(monitor.get_node("MonitorView") as SubViewport, "M3-6A_monitor_screen_ring")
	screen.set_phase(0.2)
	screen.show_inset(false)
	await _save_viewport(monitor.get_node("MonitorView") as SubViewport, "M3-6A_monitor_screen_ingress")
	screen.set_mode("no_signal")
	await _save_viewport(monitor.get_node("MonitorView") as SubViewport, "M3-6A_monitor_screen_no_signal")
	desk.free()
	# 11: the filtered camera outside, on regolith under a low Sun and a black sky
	var outside := _exterior()
	root.add_child(outside)
	_set_caption(caption, "M3-6A filtered remote camera outside Aurora (EX-CH06-S06): protective configuration",
		"Solar filter closed over the sun hood, MLI-wrapped body on a pan-tilt head, feeder F2 junction box and cable to the habitat. Black sky, one low hard Sun, no haze.")
	await _capture("M3-6A_camera_exterior")
	outside.free()
	caption.get_parent().get_parent().free()

## A caption panel across the top of the capture: a heading line and a wrapped detail line on a dark backing.
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
	panel.add_child(label)
	return label

func _set_caption(label: Label, heading: String, detail: String) -> void:
	label.text = heading + "\n" + detail
	(label.get_parent() as Control).reset_size()

func _studio() -> Node3D:
	var stage := Node3D.new()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.60, 0.61, 0.63)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.4
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.glow_enabled = true
	env.environment.glow_hdr_threshold = 1.2
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, 155, 0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, -150, 0)
	fill.light_energy = 0.55
	stage.add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.52, 0.53, 0.55)
	ground_material.roughness = 0.95
	plane.material = ground_material
	ground.mesh = plane
	ground.position.y = -0.002
	stage.add_child(ground)
	var camera := Camera3D.new()
	camera.fov = 34
	camera.position = Vector3(0.15, 3.1, -8.4)
	camera.basis = Basis.looking_at(Vector3(0.15, 0.7, 0.4) - camera.position, Vector3.UP)
	stage.add_child(camera)
	camera.current = true
	return stage

func _downlight(at: Vector3, color: Color, energy: float, reach: float = 4.5) -> SpotLight3D:
	var lamp := SpotLight3D.new()
	lamp.position = at
	lamp.rotation_degrees = Vector3(-90, 0, 0)
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.light_size = 0.08
	lamp.spot_range = reach
	lamp.spot_angle = 82.0
	lamp.spot_angle_attenuation = 0.7
	lamp.shadow_enabled = true
	return lamp

func _room_environment(ambient: float) -> WorldEnvironment:
	var env := WorldEnvironment.new()
	var look := Environment.new()
	look.background_mode = Environment.BG_COLOR
	look.background_color = Color("#030406")
	look.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	look.ambient_light_color = Color(0.86, 0.88, 0.92)
	look.ambient_light_energy = ambient
	look.tonemap_mode = Environment.TONE_MAPPER_AGX
	look.ssao_enabled = true
	look.ssao_radius = 0.6
	look.ssao_intensity = 1.4
	look.ssil_enabled = true
	look.ssil_radius = 3.0
	look.ssil_intensity = 1.1
	look.glow_enabled = true
	look.glow_intensity = 0.5
	look.glow_bloom = 0.03
	look.glow_hdr_threshold = 1.1
	env.environment = look
	return env

## A 6 x 4 m power room from the kit: far wall (z = 4) carries the board, the guide-light line and a flood; the
## protected-bus cabinet stands 8 cm off the far wall (clear of the handrail); a second flood on the left wall.
func _power_room() -> Node3D:
	var room := Node3D.new()
	room.add_child(_room_environment(0.05))
	for x in 6:
		for z in 4:
			Kit.place(room, "EN_Kit_FloorTile", Vector3(x + 0.5, 0, z + 0.5))
			Kit.place(room, "EN_Kit_CeilingTile", Vector3(x + 0.5, 0, z + 0.5))
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(0, 0, 4), -90)
	for x in range(1, 6):
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(x, 0, 4))
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(6, 0, 4), 0)
	for z in range(1, 4):
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(0, 0, z), -90)
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(6, 0, z), 90)
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(0, 0, 0), 180)
	for x in range(1, 6):
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(x, 0, 0), 180)
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(6, 0, 0), 90)
	for x in [1.5, 4.5]:
		for z in [1, 3]:
			Kit.place(room, "EN_Kit_LightStrip", Vector3(x, 0, z))
			var lamp := _downlight(Vector3(x, Kit.mount_y("EN_Kit_LightStrip") - 0.015, z), SERVICE_WHITE, 1.6)
			lamp.add_to_group("service_lights")
			room.add_child(lamp)
	var board := Props.place(room, "PR_EclipseBoard", Vector3(2.5, 0, 4))
	Props.populate_board(board, "accepted_plan")
	var forecast := Props.attach_text_screen(board, "Forecast", "ESSENTIALS 5 + PUMP 1 + CAMERA 1 = 7 UNITS  -  JAR 14 TO 7 AT RECOVERY", 96)
	forecast.add_theme_color_override("font_color", Color("#9ff0c4"))
	Props.refresh_text_screen(forecast)
	var panel := Props.place(room, "PR_ProtectedBusPanel", Vector3(4.95, 0, 3.92))
	Props.attach_text_screen(panel, "Main", "", 160).add_theme_color_override("font_color", Color("#9ff0c4"))
	Props.attach_text_screen(panel, "F2Current", "", 64)
	Props.apply_state(panel, "eclipse_schedule")
	Props.place(room, "PR_GuideLightBranch", Vector3(4.0, 0, 4), 0.0)
	for x in [3.0, 2.0, 1.0]:
		var run := Props.place(room, "PR_GuideLightRun", Vector3(x, 0, 4), 0.0)
		Props.set_part_visible(run, "EndCap", x == 1.0)
	Props.place(room, "PR_DecorativeFlood", Vector3(0.9, 0, 4), 0.0)
	Props.place(room, "PR_DecorativeFlood", Vector3(0, 0, 2.2), -90.0)
	return room

## The monitor on a desk top at the mission table, lit by a warm practical, with its live screen attached.
func _monitor_desk() -> Node3D:
	var desk := Node3D.new()
	desk.add_child(_room_environment(0.12))
	var top := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.04, 0.8)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#1f2a44")
	mat.roughness = 0.6
	box.material = mat
	top.mesh = box
	top.position = Vector3(0, 0.74, 0.1)
	desk.add_child(top)
	var monitor := Props.place(desk, "PR_EclipseMonitor", Vector3(0, 0.76, 0.2))
	Props.attach_monitor_screen(monitor)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-0.6, 1.6, -0.6)
	lamp.light_color = Color(1.0, 0.89, 0.81)
	lamp.light_energy = 0.8
	lamp.omni_range = 4.0
	desk.add_child(lamp)
	var camera := Camera3D.new()
	camera.fov = 36
	camera.position = Vector3(0.18, 1.2, -0.9)
	desk.add_child(camera)
	camera.current = true
	camera.look_at_from_position(camera.position, Vector3(0, 1.13, 0.2))
	return desk

## The camera prop on compacted regolith: black sky, one hard Sun 4 degrees up, no ambient sky light.
func _exterior() -> Node3D:
	var outside := Node3D.new()
	var env := WorldEnvironment.new()
	var look := Environment.new()
	look.background_mode = Environment.BG_COLOR
	look.background_color = Color("#05060a")
	look.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	look.ambient_light_color = Color(0.7, 0.75, 0.85)
	look.ambient_light_energy = 0.03
	look.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.environment = look
	outside.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-4, 128, 0)
	sun.light_energy = 3.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	outside.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	var regolith := load("res://assets/environment/terrain/materials/EN_Regolith_Fresh.tres") as StandardMaterial3D
	if regolith != null:
		regolith = regolith.duplicate()
		regolith.uv1_scale = Vector3(10, 10, 1)  # one repeat per 4 m (terrain kit README)
		regolith.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		plane.material = regolith
	ground.mesh = plane
	outside.add_child(ground)
	var cam_prop := Props.place(outside, "PR_FilteredCamera", Vector3.ZERO, 30.0)
	Props.apply_state(cam_prop, "filter_in")
	var camera := Camera3D.new()
	camera.fov = 40
	camera.position = Vector3(-1.9, 1.35, -2.7)
	outside.add_child(camera)
	camera.current = true
	camera.look_at_from_position(camera.position, Vector3(0, 1.05, 0))
	return outside

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "evidence written: " + label)

func _save_viewport(viewport: SubViewport, label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := viewport.get_texture().get_image().save_png(path)
	_check(error == OK, "evidence written: " + label)
