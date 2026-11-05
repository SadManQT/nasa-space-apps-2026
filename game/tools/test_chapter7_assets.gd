## M3-7A: the Chapter 7 shelter and uplink props and EN_Fabrication load, carry collision and a Compatibility LOD,
## hold canon counts (15 + 15 founder seeds, five seat markers, six water units, three branch tests, three repeater
## pins) and drive every moving part, lamp and screen the chapter's scenes need.
## Headless: game/tools/run_tests.sh chapter7_assets
## Evidence (needs a window): Godot --path game --script res://tools/test_chapter7_assets.gd -- --evidence
extends SceneTree

const C7 = preload("res://assets/props/chapter7_assets.gd")
const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const IDS := ["PR_ShelterDiagram", "PR_SeedCase", "PR_ValveDiagram", "PR_TelemetryDisplay", "PR_ArchivePlayer",
	"PR_UplinkFeedthrough", "PR_NetworkDiagnostic", "EN_Fabrication_Bench", "EN_Fabrication_RouteSimulator"]
const BUDGET := {"PR_ShelterDiagram": 8000, "PR_SeedCase": 15000, "PR_ValveDiagram": 8000, "PR_TelemetryDisplay": 8000,
	"PR_ArchivePlayer": 5000, "PR_UplinkFeedthrough": 5300, "PR_NetworkDiagnostic": 8000, "EN_Fabrication_Bench": 40000,
	"EN_Fabrication_RouteSimulator": 40000}
const ROLE_HEX := {"Kai": "#F26B21", "Amara": "#20B8C9", "Mei": "#4CAF50", "Rafi": "#8E5CC2", "Ferreira": "#B8A06A"}
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
	var catalog := C7.catalog()
	_check(catalog.task == "M3-7A", "catalogue written by the M3-7A build")
	_check(Array(C7.ids()) == IDS, "nine Chapter 7 assets in catalogue order")
	for id in IDS:
		_test_asset(id)
	_test_seed_case()
	_test_shelter_diagram()
	_test_valve_diagram()
	_test_diagnostic_and_feedthrough()
	_test_bench()
	_test_route_simulator()
	_test_no_baked_text()
	await _test_collision_rays()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence()
	print("CHAPTER7 ASSETS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

# ----------------------------------------------------------------------------------------------- per asset

func _bounds(group: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh in group.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh as MeshInstance3D
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != null and n != group:
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var aabb := xf * mi.get_aabb()
		box = aabb if first else box.merge(aabb)
		first = false
	return box

func _triangles(group: Node3D) -> int:
	var total := 0
	for mesh in group.find_children("*", "MeshInstance3D", true, false):
		var m := (mesh as MeshInstance3D).mesh
		for s in m.get_surface_count():
			total += m.surface_get_array_index_len(s) / 3
	return total

func _max_texture(group: Node3D) -> int:
	var largest := 0
	for mesh in group.find_children("*", "MeshInstance3D", true, false):
		var m := (mesh as MeshInstance3D).mesh
		for s in m.get_surface_count():
			var mat := m.surface_get_material(s) as BaseMaterial3D
			if mat == null:
				continue
			for t in [mat.albedo_texture, mat.normal_texture, mat.roughness_texture]:
				if t != null:
					largest = maxi(largest, maxi(t.get_width(), t.get_height()))
	return largest

func _test_asset(id: String) -> void:
	var item := C7.entry(id)
	_check(item.lods.size() == 2 and item.triangles.size() == 2, id + " has a game LOD and a Compatibility LOD")
	_check(int(item.triangles[0]) <= int(BUDGET[id]) and int(item.triangles[1]) <= int(item.triangles[0]), id + " triangle budget (%d) and LOD1 no heavier than LOD0" % int(BUDGET[id]))
	for path in item.lods:
		_check(load(path) is PackedScene, "load " + String(path))
	var node := C7.instance(id)
	root.add_child(node)
	var lod0: Node3D = node.get_node_or_null("LOD0")
	var lod1: Node3D = node.get_node_or_null("LOD1")
	_check(lod0 != null and lod1 != null, id + " builds both LOD children")
	if lod0 == null or lod1 == null:
		node.free()
		return
	_check(_triangles(lod0) == int(item.triangles[0]) and _triangles(lod1) == int(item.triangles[1]), id + " imported triangles match the catalogue")
	var box := _bounds(lod0)
	var size: Array = item.size_m
	_check(absf(box.position.y) < 0.006, id + " stands on its base (lowest point %.4f)" % box.position.y)
	_check(box.size.distance_to(Vector3(size[0], size[1], size[2])) < 0.012, id + " imported size matches the catalogue (%s)" % str(box.size))
	var bodies := lod0.find_children("*", "StaticBody3D", true, false)
	_check(bodies.size() > 0, id + " game LOD carries collision")
	var shapes := true
	for body in bodies:
		var shape_nodes := (body as Node).find_children("*", "CollisionShape3D", true, false)
		shapes = shapes and not shape_nodes.is_empty() and (shape_nodes[0] as CollisionShape3D).shape is ConvexPolygonShape3D
	_check(shapes, id + " collision is simplified convex shapes, not the visual mesh")
	_check(lod1.find_children("*", "StaticBody3D", true, false).is_empty(), id + " Compatibility LOD has no collision")
	var ranges := true
	for mesh in lod0.find_children("*", "MeshInstance3D", true, false):
		ranges = ranges and mesh.visibility_range_begin == 0.0 and mesh.visibility_range_end == float(item.lod_distance_m)
	for mesh in lod1.find_children("*", "MeshInstance3D", true, false):
		ranges = ranges and mesh.visibility_range_begin == float(item.lod_distance_m) and mesh.visibility_range_end == 0.0
	_check(ranges, id + " LOD ranges meet at %.0f m and the far LOD stays visible" % float(item.lod_distance_m))
	var tex0 := _max_texture(lod0)
	var tex1 := _max_texture(lod1)
	var cap := 2048 if id == "EN_Fabrication_RouteSimulator" else 1024
	_check(tex0 > 0 and tex0 <= cap and tex1 > 0 and tex1 <= cap / 2, id + " textures load and stay in budget (%d / %d px)" % [tex0, tex1])
	var sockets: Dictionary = item.get("sockets", {})
	var placed := true
	for s in sockets:
		var found := lod0.find_child(s, true, false) as Node3D
		var want: Array = sockets[s]
		placed = placed and found != null and _local(found, lod0).origin.distance_to(Vector3(want[0], want[1], want[2])) < 0.002
	_check(placed, id + " every catalogue socket exists in the game LOD at its position (%d)" % sockets.size())
	var moving := true
	for part in item.get("moving_parts", {}):
		moving = moving and lod0.find_child(part, true, false) != null and lod1.find_child(part, true, false) != null
	_check(moving, id + " every moving part exists in both LODs (%d)" % item.get("moving_parts", {}).size())
	for screen in item.get("screens", []):
		_check(C7.screen_surfaces(node, screen).size() == 2, id + " live screen slot " + screen + " in both LODs")
	for lamp in item.get("lamps", []):
		_check(C7.set_lamp(node, lamp, "idle") == 2, id + " lamp " + lamp + " in both LODs")
	node.free()

func _local(n: Node3D, ancestor: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != ancestor:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf

# ----------------------------------------------------------------------------------------------- canon and states

func _test_seed_case() -> void:
	var node := C7.instance("PR_SeedCase")
	root.add_child(node)
	var states: Dictionary = C7.entry("PR_SeedCase").states
	_check(int(states.seeds_per_compartment) == 15 and int(states.founder_total) == 30, "founder reserve is 15 + 15 = 30 (08 P-13)")
	_check(C7.count_seeds(node) == 30, "the game LOD physically holds exactly 30 seeds, one per vial (counted %d)" % C7.count_seeds(node))
	for c in ["A", "B"]:
		var wells: Array = states.compartments[c].wells
		var present := 0
		for w in wells:
			present += 1 if node.get_node("LOD0").find_child(w, true, false) != null else 0
		_check(present == 15, "compartment %s has 15 well sockets" % c)
	_check(C7.parts(node, "Lid")[0].rotation_degrees.x == 0.0 and C7.parts(node, "Latch")[0].rotation_degrees.x == 0.0, "the case starts closed and latched")
	C7.set_case(node, 1.0, false)
	_check(is_equal_approx(C7.parts(node, "Lid")[0].rotation_degrees.x, 105.0) and is_equal_approx(C7.parts(node, "Lid")[1].rotation_degrees.x, 105.0), "the lid opens in both LODs")
	_check(is_equal_approx(C7.parts(node, "Latch")[0].rotation_degrees.x, -120.0), "the latch releases")
	C7.set_compartment(node, "B", 1.0)
	_check(is_equal_approx(C7.parts(node, "CompartmentLid_B")[0].rotation_degrees.x, 100.0) and C7.parts(node, "CompartmentLid_A")[0].rotation_degrees.x == 0.0, "one compartment opens without the other")
	C7.set_case(node, 0.0, true)
	_check(C7.parts(node, "Latch")[0].rotation_degrees.x == 0.0, "the case latches again")
	_check(C7.set_lamp(node, "Lamp_SealA", "pass") == 2 and C7.set_lamp(node, "Lamp_SealB", "pass") == 2, "both seal lamps report (sealed telemetry is the safe check, S06)")
	var grips := 0
	for g in states.grips:
		grips += 1 if node.get_node("LOD0").find_child(g, true, false) != null else 0
	_check(grips == 2, "two grips for the two-handed carry (S04)")
	node.free()

func _test_shelter_diagram() -> void:
	var node := C7.instance("PR_ShelterDiagram")
	root.add_child(node)
	var states: Dictionary = C7.entry("PR_ShelterDiagram").states
	_check(states.markers.size() == 5 and states.seats.size() == 5 and states.parking.size() == 5, "five seat markers, five seats, five parking spots")
	var colours := {}
	for role in states.roles:
		var marker := C7.parts(node, "SeatMarker_" + role)
		_check(marker.size() == 2, role + "'s marker exists in both LODs")
		var found := false
		for mesh in marker[0].find_children("*", "MeshInstance3D", true, false):
			var m := (mesh as MeshInstance3D).mesh
			for s in m.get_surface_count():
				var mat := m.surface_get_material(s) as BaseMaterial3D
				if mat != null and mat.resource_name == "Role_" + role:
					found = true
					colours[role] = mat.albedo_color
		_check(found and colours[role].is_equal_approx(Color(ROLE_HEX[role])) or (found and _close(colours[role], Color(ROLE_HEX[role]))), role + "'s marker wears the ART_BIBLE role colour " + ROLE_HEX[role])
	for k in 5:
		var role: String = states.roles[k]
		_check(C7.set_marker(node, role, "Seat_%d" % (k + 1)), role + " placed on seat %d" % (k + 1))
		var want := C7.socket_position("PR_ShelterDiagram", "Seat_%d" % (k + 1))
		_check(C7.parts(node, "SeatMarker_" + role)[1].position.distance_to(want) < 0.0001, role + "'s Compatibility marker follows")
	_check(not C7.set_marker(node, "Kai", "Seat_6") and not C7.set_marker(node, "Nobody", "Seat_1"), "unknown seats and roles are refused")
	node.free()

func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 and absf(a.b - b.b) < 0.02

func _test_valve_diagram() -> void:
	var node := C7.instance("PR_ValveDiagram")
	root.add_child(node)
	var states: Dictionary = C7.entry("PR_ValveDiagram").states
	_check(states.water_cells.size() == 6 and int(states.water_units_cap) == 6, "six water units (08 P-13 W cap 6)")
	var witness := []
	for w in states.witness_w:
		witness.append(int(w))
	_check(witness == [4, 4, 4, 4, 4, 2], "the P-13 witness W [4,4,4,4,4,2] is recorded")
	var shown := func() -> int:
		var n := 0
		for k in range(1, 7):
			n += 1 if C7.parts(node, "WaterCell_%d" % k)[0].visible else 0
		return n
	_check(shown.call() == 0, "the wall starts empty (W0)")
	C7.set_water_units(node, 4)
	_check(shown.call() == 4 and C7.parts(node, "WaterCell_4")[1].visible and not C7.parts(node, "WaterCell_5")[1].visible, "W4 lights four units in both LODs")
	C7.set_water_units(node, 2)
	_check(shown.call() == 2, "the step-6 drain to W2 shows two units")
	C7.set_return_selector(node, "after")
	_check(is_equal_approx(C7.parts(node, "ReturnSelector")[0].rotation_degrees.z, 35.0), "selector to 'after the exposure sample'")
	C7.set_return_selector(node, "early")
	_check(is_equal_approx(C7.parts(node, "ReturnSelector")[0].rotation_degrees.z, -35.0), "selector to 'early'")
	node.free()

func _test_diagnostic_and_feedthrough() -> void:
	var node := C7.instance("PR_NetworkDiagnostic")
	root.add_child(node)
	var states: Dictionary = C7.entry("PR_NetworkDiagnostic").states
	_check(states.expected_after_storm == {"Local": "pass", "Dish": "fail", "Feed": "fail"}, "after the storm: local PASS, dish FAIL, feedthrough FAIL (08 P-14)")
	for branch in states.branches:
		_check(C7.set_lamp(node, states.branches[branch].lamp, states.expected_after_storm[branch]) == 2, branch + " lamp shows its result")
		var rest: float = C7.parts(node, "TestButton_" + branch)[0].position.z
		C7.press_test(node, branch, true)
		_check(is_equal_approx(C7.parts(node, "TestButton_" + branch)[0].position.z, rest + 0.004), branch + " test button presses in")
		C7.press_test(node, branch, false)
		_check(is_equal_approx(C7.parts(node, "TestButton_" + branch)[0].position.z, rest), branch + " test button releases")
	C7.set_isolated(node, true)
	_check(is_equal_approx(C7.parts(node, "IsolationKey")[0].rotation_degrees.z, 90.0), "the isolation key turns")
	var seated: float = C7.parts(node, "DataCard")[0].position.z
	C7.set_card_out(node, true)
	_check(is_equal_approx(C7.parts(node, "DataCard")[0].position.z, seated - 0.05), "the DataCard pulls out with the saved relay-bypass diagram (S09 -> S10)")
	node.free()
	var feed := C7.instance("PR_UplinkFeedthrough")
	root.add_child(feed)
	_check(C7.parts(feed, "DiagnosedTag").size() == 2 and not C7.parts(feed, "DiagnosedTag")[0].visible, "the feedthrough starts failed, the lockout tag hidden")
	C7.set_diagnosed(feed, true)
	_check(C7.parts(feed, "DiagnosedTag")[0].visible and C7.parts(feed, "DiagnosedTag")[1].visible, "diagnosing F-EXT shows the tag in both LODs")
	_check(C7.entry("PR_UplinkFeedthrough").front == "+Z", "the reused Tripo feedthrough keeps its +Z facing")
	feed.free()
	var player := C7.instance("PR_ArchivePlayer")
	root.add_child(player)
	var y0: float = C7.parts(player, "ArchiveCard")[0].position.y
	C7.set_card_out(player, true)
	_check(is_equal_approx(C7.parts(player, "ArchiveCard")[0].position.y, y0 + 0.03), "the archive card ejects")
	_check(player.find_children("*Antenna*", "", true, false).is_empty(), "the archive player has no antenna: the last log is stored, not received")
	player.free()

func _test_bench() -> void:
	var node := C7.instance("EN_Fabrication_Bench")
	root.add_child(node)
	var states: Dictionary = C7.entry("EN_Fabrication_Bench").states
	var wrong := 0
	for c in states.connectors:
		wrong += 0 if states.connectors[c] else 1
		_check(C7.parts(node, c).size() == 2, c + " exists in both LODs")
	_check(states.connectors.size() == 4 and wrong == 1, "three matching connectors and one wrong one (S11)")
	_check(C7.move_part(node, "SpareBattery", "Socket_Controller"), "the spare battery can move to another socket")
	_check(C7.parts(node, "SpareBattery")[0].position.distance_to(C7.socket_position("EN_Fabrication_Bench", "Socket_Controller")) < 0.0001, "the battery sits on the socket")
	_check(String(states.controller_asset) == "PR_RelayController" and ResourceLoader.exists("res://assets/props/PR_RelayController/PR_RelayController.glb"), "the controller cradle takes the December spare (PR_RelayController)")
	node.free()

func _test_route_simulator() -> void:
	var node := C7.instance("EN_Fabrication_RouteSimulator")
	root.add_child(node)
	var r := C7.route()
	_check(String(r.credit_line).begins_with("Terrain made from NASA data") and String(r.credit_line).ends_with("NASA does not endorse this game."), "the NASA LOLA credit line travels with the relief (handbook section 5)")
	_check(float(r.vertical_exaggeration) == 2.0 and String(r.scale) == "1:90,000", "scale 1:90,000 with a stated vertical exaggeration of 2")
	_check(r.pads.size() == 3, "three repeater pads: three sites, four links (STORY_FULL CH07 handoff)")
	var links := 0
	for h in r.hops:
		if h.chain_link:
			links += 1
			_check(h.clear, "chain link %s -> %s is clear (%.1f m)" % [h.frm, h.to, float(h.min_clearance_m)])
	_check(links == 4, "Aurora -> R1 -> R2 -> R3 -> Summit is four links")
	var blocked_down := 0
	for alt in r.road_level_alternatives:
		for leg in alt.legs:
			blocked_down += 0 if leg.clear else 1
	_check(blocked_down >= 2, "moving a pad down to the road blocks a link (the S11 obstructed-site lesson)")
	_check(r.blocked_examples.size() >= 1 and not r.blocked_examples[0].clear, "a straight road-level line over a ridge fails the obstruction check")
	_check(r.direct_aurora_summit.has("note") and String(r.direct_aurora_summit.note).begins_with("FINDING"), "the direct Aurora -> summit line-of-sight finding is recorded for review")
	for k in 3:
		_check(C7.place_pin(node, k + 1, "Pad_R%d" % (k + 1)), "pin %d onto pad R%d" % [k + 1, k + 1])
		var pad: Array = r.pads[k].table
		_check(C7.parts(node, "RepeaterPin_%d" % (k + 1))[0].position.distance_to(Vector3(pad[0], pad[1], pad[2])) < 0.001, "pin %d stands on the relief at its pad" % (k + 1))
	var relief_box := _bounds(node.get_node("LOD0"))
	_check(relief_box.size.x >= float(r.relief_size_m[0]), "the relief spans the table (%.3f m of corridor)" % float(r.relief_size_m[0]))
	var aurora: Array = r.sites.Aurora.table
	var summit: Array = r.sites.Summit.table
	_check(float(summit[1]) > float(aurora[1]), "the summit stands higher than Aurora on the relief (4,994 m vs 1,959 m)")
	node.free()

func _test_no_baked_text() -> void:
	# every word is a live slot: no material, mesh or node in the set is named for text, a logo or a flag
	var bad := []
	for id in IDS:
		var node := C7.instance(id)
		for n in node.find_children("*", "", true, false):
			var lower := String(n.name).to_lower()
			if "text" in lower or "logo" in lower or "nasa" in lower or "flag" in lower:
				bad.append(id + ":" + n.name)
			if n is MeshInstance3D:
				var m := (n as MeshInstance3D).mesh
				for s in m.get_surface_count():
					var mat := m.surface_get_material(s)
					if mat != null and String(mat.resource_name).contains("."):
						bad.append(id + ": duplicate material " + String(mat.resource_name))
		node.free()
	_check(bad.is_empty(), "no baked text, logo or flag parts and no duplicated material names (%s)" % str(bad))

func _test_collision_rays() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var bench := C7.place(world, "EN_Fabrication_Bench", Vector3(20, 0, 0))
	var board := C7.place(world, "PR_ShelterDiagram", Vector3(30, 0, 0))
	C7.place(world, "PR_SeedCase", Vector3(40, 0, 0))
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(20, 3, -0.1), Vector3(20, -1, -0.1)))
	_check(not hit.is_empty() and absf(hit.position.y - 0.903) < 0.01, "a ray down onto the bench stops at the worktop (0.903 m)")
	hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(30, 1.40, -2), Vector3(30, 1.40, 1)))
	_check(not hit.is_empty() and hit.position.z < 0.0 and hit.position.z > -0.05, "a ray into the wall board stops on its face")
	_check(absf(board.position.y - 1.05) < 0.001, "the board mounts at its catalogue height (1.05 m)")
	hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(40, 1, 0), Vector3(40, -1, 0)))
	_check(not hit.is_empty() and absf(hit.position.y - 0.15) < 0.01, "the seed case can be set on and picked from a surface (top at 0.15 m)")
	_check(bench != null, "the bench places")
	world.free()

# ----------------------------------------------------------------------------------------------- evidence

const WARM_WHITE := Color(1.0, 0.81, 0.65)
const SERVICE_WHITE := Color(1.0, 0.89, 0.81)
const AMBER := Color(1.0, 0.62, 0.22)

func _evidence() -> void:
	root.size = Vector2i(1600, 1000)
	root.always_on_top = true
	root.grab_focus()
	var caption := _caption()
	var room := _safe_room()
	root.add_child(room)
	var camera := Camera3D.new()
	camera.fov = 62
	room.add_child(camera)
	camera.current = true
	camera.position = Vector3(3.6, 1.62, 1.15)
	camera.look_at(Vector3(3.6, 1.25, 5.0))
	_set_caption(caption, "M3-7A Safe Room props on the habitat kit (EX-CH07-S02..S09)",
		"Far wall, from the left: shelter diagram with five markers seated, valve diagram (W4) beside the water-wall panel, telemetry displays, network diagnostic (local PASS, dish FAIL, feedthrough FAIL). Table: the founder case and the archive player. Every word is a live screen.")
	await _capture("M3-7A_godot_safe_room")
	camera.position = Vector3(5.75, 1.43, 3.72)
	camera.fov = 40
	camera.look_at(Vector3(5.75, 1.43, 5.0))
	_set_caption(caption, "M3-7A shelter diagram: the fifth seat changes the sum (EX-CH07-S02)",
		"The 8 x 6 m Safe Room plan: hatch (orange), perimeter water panels (blue), four bundle slots, the central seed latch (gold). Five role-colour markers on the five seats; the names are live labels, never baked.")
	await _capture("M3-7A_godot_shelter_markers")
	camera.position = Vector3(2.12, 1.46, 3.92)
	camera.look_at(Vector3(2.12, 1.46, 5.0))
	_set_caption(caption, "M3-7A local telemetry displays: the first wave has a ledger (EX-CH07-S06)",
		"Left: ship systems, step 2 of 6 against the forecast (energy, air, rations, exposure with the shield at S6). Right: the garden's local telemetry and the sealed founder case. Between them the six ledger lamps E A H C R Z. All words are live screens.")
	await _capture("M3-7A_godot_telemetry")
	var case: Node3D = room.get_node("PR_SeedCase")
	C7.set_case(case, 1.0, false)
	C7.set_compartment(case, "A", 1.0)
	C7.set_compartment(case, "B", 1.0)
	camera.fov = 38
	camera.position = case.global_position + Vector3(0.0, 0.66, -0.36)
	camera.look_at(case.global_position + Vector3(0, 0.07, 0.0))
	var inspect := OmniLight3D.new()  # a hand light for the close inspection, as a cadet would hold one
	inspect.position = case.global_position + Vector3(0.25, 0.75, -0.45)
	inspect.light_color = Color(1.0, 0.95, 0.88)
	inspect.light_energy = 1.4
	inspect.omni_range = 2.0
	inspect.shadow_enabled = true
	room.add_child(inspect)
	_set_caption(caption, "M3-7A founder-reserve case open: fifteen and fifteen, thirty founders (EX-CH07-S04)",
		"Two compartments of 15 vials, one Brassica rapa seed (about 2 mm) in each; seal lamps on the inner lids; the front window is the sealed-telemetry screen used during exposure (S06).")
	await _capture("M3-7A_godot_seed_case")
	C7.set_case(case, 0.0, true)
	C7.set_compartment(case, "A", 0.0)
	C7.set_compartment(case, "B", 0.0)
	inspect.free()
	camera.fov = 42
	camera.position = Vector3(0.9, 1.33, 3.72)
	camera.look_at(Vector3(0.9, 1.33, 5.0))
	_set_caption(caption, "M3-7A local network diagnostic: a different silence (EX-CH07-S09)",
		"Branch tests after the storm: local network PASS, direct dish path FAIL, external feedthrough FAIL, so the fault is on the way out to Earth. Isolation key turned; the DataCard carries the saved relay-bypass diagram to S10.")
	await _capture("M3-7A_godot_diagnostic")
	room.free()
	var outside := _exterior()
	root.add_child(outside)
	_set_caption(caption, "M3-7A damaged external uplink feedthrough (A-43), diagnosed",
		"The 27 Oct Tripo feedthrough with collision and its lockout tag shown once F-EXT is diagnosed, on a hull panel. No direct repair: the finale bypasses it through the relay.")
	await _capture("M3-7A_godot_uplink")
	var wide := outside.get_node("ExteriorCamera") as Camera3D
	wide.position = Vector3(1.55, 1.05, 3.1)
	wide.look_at(Vector3(-0.1, 0.85, 0.0))
	_set_caption(caption, "M3-7A the feedthrough outside: one low hard Sun, black sky, grey regolith (ART_BIBLE section 2)",
		"The Sun 4 degrees above the horizon throws long, hard, near-black shadows: the cables across the hull, the hull across the regolith. No glow, no haze, no dust in the air.")
	await _capture("M3-7A_godot_uplink_exterior")
	outside.free()
	var fab := _fabrication_room()
	root.add_child(fab)
	var cam2 := Camera3D.new()
	cam2.fov = 60
	fab.add_child(cam2)
	cam2.current = true
	cam2.position = Vector3(1.2, 1.75, 0.35)
	cam2.look_at(Vector3(3.2, 0.95, 3.4))
	_set_caption(caption, "M3-7A EN_Fabrication: the bench and the surveyed-route simulator (EX-CH07-S11)",
		"Bench: the December spare controller on its cradle, the spare battery, three matching connectors and a wrong one, echo test unit, isolation checklist. Simulator: the real LOLA corridor from Aurora to the Malapert summit with three repeater pins on computed pads.")
	await _capture("M3-7A_godot_fabrication")
	var sim: Node3D = fab.get_node("EN_Fabrication_RouteSimulator")
	cam2.fov = 40
	cam2.position = sim.global_position + Vector3(0.0, 1.80, -1.32)
	cam2.look_at(sim.global_position + Vector3(0.0, 0.90, 0.02))
	var rake := SpotLight3D.new()  # a low raking work light along the table shows the relief
	rake.position = sim.global_position + Vector3(1.6, 1.25, -0.6)
	rake.look_at_from_position(rake.position, sim.global_position + Vector3(0.0, 0.92, 0.05), Vector3.UP)
	rake.light_color = SERVICE_WHITE
	rake.light_energy = 3.0
	rake.spot_range = 4.0
	rake.spot_angle = 40.0
	rake.shadow_enabled = true
	fab.add_child(rake)
	_set_caption(caption, "M3-7A route simulator relief: make the road hear us (EX-CH07-S11)",
		"NASA LRO LOLA 80 m heights at 1:90,000, vertical exaggeration 2, the computed surveyed road in orange. Pins on R1-R3, the high ground beside the road: four clear links. Moved down to the road, R1 and R2 are blocked by the next ridge.")
	await _capture("M3-7A_godot_route_relief")
	fab.free()
	for lod in 2:
		var stage := _studio()
		root.add_child(stage)
		for i in IDS.size():
			var node := C7.instance(IDS[i], false, 0) if lod == 0 else C7.instance(IDS[i], false)
			if lod == 1:
				node.get_node("LOD0").visible = false
				for mesh in node.get_node("LOD1").find_children("*", "MeshInstance3D", true, false):
					mesh.visibility_range_begin = 0.0
			var fab_piece: bool = String(IDS[i]).begins_with("EN_")
			# +X is the viewer's left: the front row runs from the left in catalogue order, the fab pieces behind it
			node.position = Vector3(1.4 - 2.8 * (i - 7), 0.0, 1.6) if fab_piece else Vector3(2.85 - i * 0.95, 0.0, -1.2)
			if IDS[i] == "PR_UplinkFeedthrough":
				node.rotation_degrees.y = 180.0
			stage.add_child(node)
			var label := Label3D.new()
			label.text = ["Shelter diagram", "Seed case", "Valve diagram", "Telemetry", "Archive player", "Uplink feedthrough", "Network diagnostic", "Fabrication bench", "Route simulator"][i]
			label.font_size = 40
			label.pixel_size = 0.0026
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.outline_size = 8
			label.modulate = Color(0.12, 0.16, 0.27)
			label.outline_modulate = Color(1, 1, 1, 0.9)
			label.position = node.position + Vector3(0, -0.06, (-0.5 if i % 2 == 0 else -0.85) if not fab_piece else -0.75)
			stage.add_child(label)
		_set_caption(caption, "M3-7A, %s" % ["LOD0: the game LOD (its collision boxes are invisible by design)" if lod == 0 else "LOD1: the Compatibility LOD, 512 px kit textures, fewer segments"],
			"The nine Chapter 7 assets imported by Godot at true size: front row the props and wall pieces (stood on the floor here), back row the fabrication bench and the route simulator. Neutral studio light.")
		await _capture("M3-7A_godot_lod%d" % lod)
		stage.free()
	caption.get_parent().get_parent().free()

func _safe_room() -> Node3D:
	var room := Node3D.new()
	room.add_child(_interior_environment(0.05))
	for x in 7:
		for z in 5:
			Kit.place(room, "EN_Kit_FloorTile", Vector3(x + 0.5, 0, z + 0.5))
			Kit.place(room, "EN_Kit_CeilingTile", Vector3(x + 0.5, 0, z + 0.5))
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(0, 0, 5), -90)
	for x in range(1, 7):
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(x, 0, 5))
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(7, 0, 5), 0)
	for z in range(1, 5):
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(0, 0, z), -90)
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(7, 0, z), 90)
	for x in [2, 5]:
		for z in [2, 4]:
			Kit.place(room, "EN_Kit_LightStrip", Vector3(x, 0, z))
			room.add_child(_downlight(Vector3(x, Kit.mount_y("EN_Kit_LightStrip") - 0.015, z), WARM_WHITE, 1.3))
	for x in [0.6, 3.5, 6.4]:  # low amber guide lights along the far wall (09 LOC-04)
		var guide := OmniLight3D.new()
		guide.position = Vector3(x, 0.25, 4.7)
		guide.light_color = AMBER
		guide.light_energy = 0.6
		guide.omni_range = 2.2
		room.add_child(guide)
	# x grows to the viewer's left when facing the far wall (+Z), so the plates are listed right to left
	var diag := C7.place(room, "PR_NetworkDiagnostic", Vector3(0.9, 0, 5))
	var tele := C7.place(room, "PR_TelemetryDisplay", Vector3(2.12, 0, 5))
	var wall_panel := (load("res://assets/props/PR_WaterWallPanel/PR_WaterWallPanel.glb") as PackedScene).instantiate() as Node3D
	wall_panel.position = Vector3(3.42, 0, 4.82)   # the reused Tripo panel faces +Z: turn it to the room
	wall_panel.rotation_degrees.y = 180.0
	room.add_child(wall_panel)
	var valve := C7.place(room, "PR_ValveDiagram", Vector3(4.45, 0, 5))
	var board := C7.place(room, "PR_ShelterDiagram", Vector3(5.75, 0, 5))
	var roles: Array = C7.entry("PR_ShelterDiagram").states.roles
	for k in 5:
		C7.set_marker(board, roles[k], "Seat_%d" % (k + 1))
		var label := Label3D.new()
		label.text = roles[k]
		label.font_size = 20
		label.pixel_size = 0.0009
		label.modulate = Color(0.12, 0.16, 0.27)
		label.rotation_degrees.y = 180.0
		label.position = C7.socket_position("PR_ShelterDiagram", "Seat_%d" % (k + 1)) + Vector3(0, 0.034, -0.013)
		board.add_child(label)
	_screen(board, "Screen_Roster", "SHELTER ROSTER   5 / 5 seated   answers 5 / 5", Vector2i(1040, 100), 46)
	C7.set_water_units(valve, 4)
	C7.set_return_selector(valve, "after")
	C7.set_lamp(valve, "Lamp_Supply", "off")
	C7.set_lamp(valve, "Lamp_Return", "warn")
	_screen(valve, "Screen_Return", "RETURN  after the step-6 sample\nW 4 in the wall   garden 2", Vector2i(760, 150), 40)
	for k in C7.entry("PR_TelemetryDisplay").states.ledger_lamps:
		C7.set_lamp(tele, C7.entry("PR_TelemetryDisplay").states.ledger_lamps[k], "pass")
	_screen(tele, "Screen_Systems", "STEP 2 / 6   (7.2 h each)\nE  26 -> 22   forecast 22\nA  8.75 -> 7.5   forecast 7.5\nR  16.5 -> 15.0  forecast 15.0\nZ   0   shield S6", Vector2i(640, 400), 38)
	_screen(tele, "Screen_Garden", "GARDEN  local telemetry\npressure  steady\ntemperature  steady\ncotton  watered 06:10\nfounder case  sealed 30", Vector2i(640, 400), 38)
	C7.set_lamp(diag, "Lamp_Local", "pass")
	C7.set_lamp(diag, "Lamp_Dish", "fail")
	C7.set_lamp(diag, "Lamp_Feed", "fail")
	C7.set_isolated(diag, true)
	C7.set_card_out(diag, true)
	_screen(diag, "Screen_Diag", "BRANCH TESTS\nlocal network   PASS\ndirect dish path   FAIL\nexternal feedthrough   FAIL\n-> F-EXT  (saved to card)", Vector2i(680, 360), 40)
	var table := _table(Vector3(3.3, 0, 3.2), Vector3(1.4, 0.76, 0.7))
	room.add_child(table)
	var case := C7.place(room, "PR_SeedCase", Vector3(3.75, 0.76, 3.15))
	C7.set_lamp(case, "Lamp_SealA", "pass")
	C7.set_lamp(case, "Lamp_SealB", "pass")
	_screen(case, "Screen_Case", "SEALED 15 + 15", Vector2i(360, 140), 48)
	var player := C7.place(room, "PR_ArchivePlayer", Vector3(2.85, 0.76, 3.2), 15)
	C7.set_lamp(player, "Lamp_Stored", "on")
	_screen(player, "Screen_Archive", "LOG 2034-09\nstored locally", Vector2i(400, 160), 44)
	return room

func _exterior() -> Node3D:
	var stage := Node3D.new()
	var env := WorldEnvironment.new()
	var look := Environment.new()
	look.background_mode = Environment.BG_COLOR
	look.background_color = Color("#05060A")
	look.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	look.ambient_light_color = Color(0.5, 0.52, 0.56)
	look.ambient_light_energy = 0.02
	look.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.environment = look
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-4.0, 53.0, 0.0)   # one low hard Sun (south pole: a few degrees up), from the front right
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	stage.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	var regolith := StandardMaterial3D.new()
	regolith.albedo_color = Color("#7A7672")
	regolith.roughness = 1.0
	plane.material = regolith
	ground.mesh = plane
	stage.add_child(ground)
	var hull := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(3.0, 2.6, 0.2)
	hull.mesh = slab
	hull.material_override = load("res://assets/environment/kit/materials/M_Kit_PaintWhite.tres")
	hull.position = Vector3(0, 1.3, float(C7.entry("PR_UplinkFeedthrough").bounds_min_m[2]) - 0.1)   # the plate's back on the hull
	stage.add_child(hull)
	var feed := C7.place(stage, "PR_UplinkFeedthrough", Vector3(0, 0, 0), 0, true, 0)
	C7.set_diagnosed(feed, true)
	var camera := Camera3D.new()
	camera.fov = 36
	stage.add_child(camera)
	camera.current = true
	camera.name = "ExteriorCamera"
	camera.position = Vector3(0.62, 1.72, 1.35)   # from the junction-box side, so the cables do not hide the tag
	camera.basis = Basis.looking_at(Vector3(0.0, 1.48, 0.05) - camera.position, Vector3.UP)  # not in the tree yet
	return stage

func _fabrication_room() -> Node3D:
	var room := Node3D.new()
	room.add_child(_interior_environment(0.06))
	for x in 7:
		for z in 5:
			Kit.place(room, "EN_Kit_FloorTile", Vector3(x + 0.5, 0, z + 0.5))
			Kit.place(room, "EN_Kit_CeilingTile", Vector3(x + 0.5, 0, z + 0.5))
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(0, 0, 5), -90)
	for x in range(1, 7):
		Kit.place(room, "EN_Kit_Wall_Straight" if x != 3 else "EN_Kit_Wall_EquipBay", Vector3(x, 0, 5))
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(7, 0, 5), 0)
	for z in range(1, 5):
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(7, 0, z), 90)
	for x in [1.5, 3.5, 5.5]:
		for z in [1.5, 3.5]:
			Kit.place(room, "EN_Kit_LightStrip", Vector3(x, 0, z))
			room.add_child(_downlight(Vector3(x, Kit.mount_y("EN_Kit_LightStrip") - 0.015, z), SERVICE_WHITE, 1.5))
	var bench := C7.place(room, "EN_Fabrication_Bench", Vector3(5.4, 0, 4.55), 0, true, 0)
	var controller := (load("res://assets/props/PR_RelayController/PR_RelayController.glb") as PackedScene).instantiate() as Node3D
	controller.position = bench.position + C7.socket_position("EN_Fabrication_Bench", "Socket_Controller")
	room.add_child(controller)
	var task := SpotLight3D.new()
	task.position = bench.position + Vector3(0, 1.78, 0.17)
	task.rotation_degrees = Vector3(-90, 0, 0)
	task.light_color = SERVICE_WHITE
	task.light_energy = 2.2
	task.spot_range = 2.2
	task.spot_angle = 70.0
	task.shadow_enabled = true
	room.add_child(task)
	C7.set_lamp(bench, "Lamp_Echo", "pass")
	C7.set_lamp(bench, "Lamp_Battery", "pass")
	_screen(bench, "Screen_Echo", "ECHO  known content\nsent = received\nBENCH PASS (not field)", Vector2i(480, 200), 32)
	_screen(bench, "Screen_Checklist", "ISOLATION CHECKLIST\n[x] power isolated\n[x] zero tested\n[x] connector matched\n[x] battery loaded\n[ ] field test at marker 2\nsigned:  Ferreira", Vector2i(420, 560), 34, Color(0.92, 0.92, 0.90), Color(0.10, 0.12, 0.18))
	var sim := C7.place(room, "EN_Fabrication_RouteSimulator", Vector3(3.0, 0, 2.6), 0, true, 0)
	for k in 3:
		C7.place_pin(sim, k + 1, "Pad_R%d" % (k + 1))
	var r := C7.route()
	var lines := "LINE OF SIGHT  (true scale, lunar curvature)\n"
	for h in r.hops:
		if h.chain_link:
			lines += "%s -> %s   %.1f km   clear by %.0f m\n" % [h.frm, h.to, float(h.distance_m) / 1000.0, float(h.min_clearance_m)]
	lines += "R1 on the road:  R1 -> R2 BLOCKED"
	_screen(sim, "Screen_Route", lines, Vector2i(900, 520), 34)
	for name in ["Aurora", "Summit"]:
		var site: Array = r.sites[name].table
		_tag(sim, "Malapert summit" if name == "Summit" else "Aurora", Vector3(site[0] + (0.10 if name == "Summit" else 0.0), site[1] + 0.07, site[2]))
	for k in 3:
		var pad: Array = r.pads[k].table
		_tag(sim, "R%d" % (k + 1), Vector3(pad[0], pad[1] + 0.09, pad[2]))
	return room

func _tag(parent: Node3D, text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 40
	label.pixel_size = 0.0007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 8
	label.modulate = Color(0.10, 0.13, 0.22)
	label.outline_modulate = Color(1, 1, 1, 0.9)
	label.position = at
	parent.add_child(label)

## A live screen for the evidence: a SubViewport with plain words, shown unshaded on the asset's Screen_* slot.
func _screen(node: Node3D, screen: String, text: String, size: Vector2i, font: int, bg: Color = Color("#0b1220"), fg: Color = Color("#e6eefc")) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var panel := ColorRect.new()
	panel.color = bg
	panel.size = Vector2(size)
	vp.add_child(panel)
	var label := Label.new()
	label.text = text
	label.position = Vector2(size.x * 0.04, size.y * 0.06)
	label.add_theme_font_size_override("font_size", font)
	label.add_theme_color_override("font_color", fg)
	vp.add_child(label)
	node.add_child(vp)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = vp.get_texture()
	for slot in C7.screen_surfaces(node, screen):
		(slot.mesh as MeshInstance3D).set_surface_override_material(int(slot.surface), mat)

func _table(at: Vector3, size: Vector3) -> Node3D:
	var table := StaticBody3D.new()
	table.position = at
	var top := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, 0.04, size.z)
	top.mesh = box
	top.material_override = load("res://assets/environment/kit/materials/M_Kit_PaintGrey.tres")
	top.position.y = size.y - 0.02
	table.add_child(top)
	for sx in [-1, 1]:
		var leg := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.06, size.y - 0.04, size.z - 0.1)
		leg.mesh = lb
		leg.material_override = load("res://assets/environment/kit/materials/M_Kit_PaintNavy.tres")
		leg.position = Vector3(sx * (size.x / 2 - 0.08), (size.y - 0.04) / 2, 0)
		table.add_child(leg)
	return table

func _interior_environment(ambient: float) -> WorldEnvironment:
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
	look.glow_intensity = 0.4
	look.glow_hdr_threshold = 1.2
	env.environment = look
	return env

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

func _studio() -> Node3D:
	var stage := Node3D.new()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.60, 0.61, 0.63)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.35
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, 150, 0)
	key.light_energy = 1.6
	key.shadow_enabled = true
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 40, 0)
	fill.light_energy = 0.5
	stage.add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.53, 0.55)
	mat.roughness = 0.95
	plane.material = mat
	ground.mesh = plane
	ground.position.y = -0.002
	stage.add_child(ground)
	var camera := Camera3D.new()
	camera.fov = 34
	camera.position = Vector3(0.0, 3.6, -8.4)
	camera.basis = Basis.looking_at(Vector3(0, 0.55, 0.3) - camera.position, Vector3.UP)
	stage.add_child(camera)
	camera.current = true
	return stage

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

func _capture(label: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "evidence written: " + label)
