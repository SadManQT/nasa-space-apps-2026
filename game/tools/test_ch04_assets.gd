## M3-4A: the Chapter 4 environment sets (EN_Garage, EN_ColdTrap and the vault set) load, keep the kit conventions and
## match the layout and the LOLA survey Sadman approved on 7 Nov 2026 ("Approve all 12").
## Headless: game/tools/run_tests.sh ch04_assets
## Evidence (needs a window): Godot --path game --script res://tools/test_ch04_assets.gd -- --evidence
extends SceneTree

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const Garage = preload("res://assets/environment/EN_Garage/en_garage.gd")
const GARAGE_CATALOG := "res://assets/environment/EN_Garage/garage.json"
const COLD_CATALOG := "res://assets/environment/EN_ColdTrap/coldtrap.json"
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const REGOLITH := "res://assets/environment/terrain/materials/EN_Regolith_Compacted.tres"
## Live-UI slots per piece across both LODs (decision 7: every word is drawn at runtime).
const SCREENS := {"EN_Garage_DockingPort": 2, "EN_Garage_CargoLock": 2, "EN_Garage_SuitSealPanel": 2, "EN_Garage_RouteBoard": 2,
		"EN_Garage_DepartureBoard": 2, "EN_Garage_HandoverConsole": 6, "EN_Garage_CargoRack": 2, "EN_ColdTrap_BeaconMast": 2}
const ROLES := ["docking_port", "cargo_lock", "rover_door", "route_board", "departure_a", "departure_b", "handover_console",
		"relief_locker", "cargo_rack", "suit_seals", "eva_porch", "berm", "umbilical", "inner_door"]
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
	var garage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GARAGE_CATALOG))
	var cold: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COLD_CATALOG))
	_check(garage.pieces.size() == 17, "garage.json lists the 17 garage pieces")
	_check(cold.pieces.size() == 7 and cold.props.size() == 4, "coldtrap.json lists 7 site pieces and the 4-piece vault set")
	_check(String(garage.approval).contains("Approve all 12") and String(cold.approval).contains("Approve all 12"), "both catalogues quote Sadman's approval")
	for entry in garage.pieces + cold.pieces:
		_test_piece(entry)
	for entry in cold.props:
		_test_prop(entry)
	_test_parts()
	_test_vault(cold)
	_test_layout(garage)
	_test_survey(cold)
	await _test_assembled()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence()
	print("CH04_ASSETS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

# ----------------------------------------------------------------------------------------------- pieces

func _test_piece(entry: Dictionary) -> void:
	var id: String = entry.id
	_check(entry.lods.size() == 2 and entry.triangles.size() == 2, id + " has a game LOD and a Compatibility LOD")
	_check(int(entry.triangles[0]) <= 8000 and int(entry.triangles[1]) <= int(entry.triangles[0]), id + " within the 8k modular budget, LOD1 no heavier than LOD0")
	_check(not Kit.piece(id).is_empty(), id + " resolves through habitat_kit.gd (extension catalogue)")
	_check(absf(Kit.mount_y(id) - float(entry.mount_y)) < 0.0001, id + " mount offset comes from the catalogue")
	var node := Kit.instance(id)
	root.add_child(node)
	var box := Kit.bounds(node, 0)
	_check(absf(box.position.y) <= 0.01, id + " stands on its base (lowest point y = 0)")
	var size: Array = entry.size_m
	_check(absf(box.size.x - float(size[0])) <= 0.02 and absf(box.size.y - float(size[1])) <= 0.02 and absf(box.size.z - float(size[2])) <= 0.02,
			id + " imports at its catalogue size %s (got %s)" % [str(size), str(box.size)])
	var lod0 := node.get_node("LOD0") as Node3D
	var lod1 := node.get_node("LOD1") as Node3D
	var bodies := lod0.find_children("*", "StaticBody3D", true, false)
	if String(entry.kind) == "decal":
		_check(bodies.is_empty(), id + " is floor paint with no collision")
	else:
		_check(bodies.size() >= 1, id + " carries collision on the game LOD")
	_check(lod1.find_children("*", "StaticBody3D", true, false).is_empty(), id + " Compatibility LOD has no collision")
	var textured := false
	for mesh in lod0.find_children("*", "MeshInstance3D", true, false):
		for surface in (mesh as MeshInstance3D).mesh.get_surface_count():
			var material := (mesh as MeshInstance3D).get_active_material(surface) as StandardMaterial3D
			if material != null and material.albedo_texture != null and material.normal_texture != null:
				textured = true
	_check(textured, id + " resolves its shared PBR sets by uri (albedo and normal maps)")
	_check(Kit.screen_surfaces(node).size() == int(SCREENS.get(id, 0)), id + " exposes %d live-UI Screen surfaces (got %d)" % [int(SCREENS.get(id, 0)), Kit.screen_surfaces(node).size()])
	if String(entry.kind) == "wall":
		_check((absf(box.size.x - 1.0) <= 0.01 or absf(box.size.x - 2.0) <= 0.01) and absf(box.size.y - 2.6) <= 0.01, id + " is a 1 or 2 m x 2.6 m wall module")
		_check(box.position.z <= 0.001 and box.end.z >= 0.149, id + " face on z = 0 with the body behind it")
	node.free()

func _test_prop(entry: Dictionary) -> void:
	var id: String = entry.id
	var prop := (load(String(entry.lods[0])) as PackedScene).instantiate() as Node3D
	root.add_child(prop)
	var box := _bounds(prop)
	_check(absf(box.position.y) <= 0.01, id + " rests on y = 0")
	_check(int(entry.triangles[0]) <= 5000, id + " within the small-prop budget")
	_check(prop.find_children("*", "Skeleton3D", true, false).is_empty(), id + " is a plain prop: no rig")
	prop.free()

## Every surface of a node whose material name starts with the prefix.
func _surfaces_named(node: Node3D, prefix: String) -> int:
	var count := 0
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		for surface in (mesh as MeshInstance3D).mesh.get_surface_count():
			var material := (mesh as MeshInstance3D).get_active_material(surface)
			if material != null and material.resource_name.begins_with(prefix):
				count += 1
	return count

# ----------------------------------------------------------------------------------------------- moving parts

func _test_parts() -> void:
	var dock := Kit.instance("EN_Garage_DockingPort")
	root.add_child(dock)
	var leaf := dock.find_children("HatchLeaf", "Node3D", true, false)
	_check(leaf.size() == 2, "dock HatchLeaf in both LODs")
	var closed := _subtree_bounds(leaf[0] as Node3D, dock)
	Kit.set_part_open(dock, "HatchLeaf", 1.0)
	var opened := _subtree_bounds(leaf[0] as Node3D, dock)
	_check(opened.position.z < closed.position.z - 0.5, "the dock hatch swings into the ready room (-Z) when open")
	var collar := dock.find_children("DockCollar", "Node3D", true, false)[0] as Node3D
	var reach := _subtree_bounds(collar, dock).end.z
	_check(absf(reach - (0.15 + 1.10)) <= 0.03, "the extended dock collar reaches 1.10 m from the wall's bay face (%.3f)" % reach)
	Kit.set_part_open(dock, "DockCollar", 1.0)
	_check(_subtree_bounds(collar, dock).end.z < reach - 0.39, "the dock collar retracts 0.40 m when the rover is away")
	_check(_surfaces_named(dock, "LampSealed") == 2 and _surfaces_named(dock, "LampEqualising") == 2 and _surfaces_named(dock, "LampSafe") == 2, "the dock panel carries the three state lamps in both LODs")
	dock.free()
	var lock := Kit.instance("EN_Garage_CargoLock")
	root.add_child(lock)
	var inner := lock.find_children("InnerDoor", "Node3D", true, false)[0] as Node3D
	var outer := lock.find_children("OuterDoor", "Node3D", true, false)[0] as Node3D
	var inner_closed := _subtree_bounds(inner, lock)
	var outer_closed := _subtree_bounds(outer, lock)
	Kit.set_part_open(lock, "InnerDoor", 1.0)
	Kit.set_part_open(lock, "OuterDoor", 1.0)
	_check(_subtree_bounds(inner, lock).position.z < inner_closed.position.z - 0.4, "the cargo lock's inner door swings into the room")
	_check(_subtree_bounds(outer, lock).end.z > outer_closed.end.z + 0.4, "the cargo lock's outer door swings up and out over the porch")
	_check(_surfaces_named(lock, "LampDry") == 2, "the cargo lock shows the dry-nitrogen fill lamp in both LODs")
	lock.free()
	var door := Kit.instance("EN_Garage_BayDoor")
	root.add_child(door)
	var panel := door.find_children("DoorPanel", "Node3D", true, false)[0] as Node3D
	_check(_subtree_bounds(panel, door).position.y <= 0.05, "the rover door reaches the floor when shut")
	Kit.set_part_open(door, "DoorPanel", 1.0)
	var coiled := _subtree_bounds(panel, door)
	_check(coiled.position.y > 4.6 and coiled.size.y < 0.4, "the rover door coils up into its drum, clear of a 4.41 m rover")
	door.free()
	var locker := Kit.instance("EN_Garage_ReliefLocker")
	root.add_child(locker)
	var left := locker.find_children("DoorL", "Node3D", true, false)[0] as Node3D
	var right := locker.find_children("DoorR", "Node3D", true, false)[0] as Node3D
	var shut_z := _subtree_bounds(left, locker).position.z
	Kit.set_part_open(locker, "DoorL", 1.0)
	Kit.set_part_open(locker, "DoorR", 1.0)
	_check(_subtree_bounds(left, locker).position.z < shut_z - 0.4 and _subtree_bounds(right, locker).position.z < shut_z - 0.4, "both relief-locker doors swing out to the front")
	locker.free()

func _test_vault(cold: Dictionary) -> void:
	var entry: Dictionary = {}
	for prop in cold.props:
		if prop.id == "PR_VaultCase":
			entry = prop
	var vault := (load(String(entry.lods[0])) as PackedScene).instantiate() as Node3D
	root.add_child(vault)
	var box := _bounds(vault)
	_check(absf(box.size.z - 0.60) <= 0.01 and absf(box.size.x - 0.39) <= 0.01 and box.size.y < 0.30, "vault V12 keeps the installed case's 0.60 x 0.39 m footprint (0.60 along z) under 0.30 m")
	var lids := vault.find_children("Lid", "Node3D", true, false)
	_check(lids.size() == 1, "the vault has its hinged Lid")
	_check(_surfaces_named(vault, "Label_Lid") == 1, "the lid underside carries the Label_Lid slot for clue 15 (no baked text)")
	_check(_surfaces_named(vault, "Label") >= 2, "the well tabs are blank Label slots")
	_check(entry.sockets.wells.size() == 12, "twelve specimen wells (EX-CH04-S10)")
	var lid := lids[0] as Node3D
	var closed_top := _subtree_bounds(lid, vault).end.y
	lid.rotation_degrees.z = float(entry.sockets.parts.Lid.degrees)
	var open_lid := _subtree_bounds(lid, vault)
	_check(open_lid.end.y > closed_top + 0.15 and open_lid.position.x > -0.05, "the lid opens upward about its back hinge")
	vault.free()
	var carrier := (load("res://assets/props/PR_VaultCarrier/PR_VaultCarrier.glb") as PackedScene).instantiate() as Node3D
	root.add_child(carrier)
	var cbox := _bounds(carrier)
	_check(cbox.size.x > 0.86 and cbox.size.z > 0.39 and cbox.size.y > 0.27, "the recovery carrier's cradle takes the 0.60 x 0.39 x 0.27 m case")
	carrier.free()

# ----------------------------------------------------------------------------------------------- layout and survey

func _test_layout(garage: Dictionary) -> void:
	var layout: Dictionary = garage.layout
	_check(layout.bounds_m == [12.0, 9.0], "the garage is canon's 12 x 9 m (LOC-08)")
	_check(absf(float(layout.deck_y) - 1.40) < 0.001, "the ready-room deck stands 1.40 m above the bay floor (decision 1)")
	var unknown := PackedStringArray()
	for p in layout.placements:
		if Kit.piece(String(p.piece)).is_empty():
			unknown.append(String(p.piece))
	_check(unknown.is_empty(), "every placement is a known kit or garage piece " + ", ".join(unknown))
	var rover: Dictionary = layout.rover
	var centre := Vector3(rover.centre[0], rover.centre[1], rover.centre[2])
	var hatch := Vector3(rover.hatch[0], rover.hatch[1], rover.hatch[2])
	_check(absf(hatch.y - 1.85) < 0.01, "the dock sill (deck + 0.45 m) meets VH_Rover's side hatch at 1.85 m")
	_check(absf(centre.z - 1.42 - hatch.z) < 0.02, "the tunnel ends on the rover's body side (1.42 m off its centre line)")
	_check(centre.x - 3.0 > float(Kit.piece("EN_Garage_EVAPorch").sockets.deck_x) and centre.x + 3.0 < 12.0, "the 6 m rover parks between the EVA porch deck and the rover door")
	var door: Array = Kit.piece("EN_Garage_BayDoor").sockets.opening_size
	_check(float(door[0]) > 4.66 + 0.5 and float(door[1]) > 4.41 + 0.3, "the rover door clears VH_Rover (4.66 m track, 4.41 m tall)")
	_check(absf(float(Kit.piece("EN_Garage_EVAPorch").sockets.deck_y) - float(layout.deck_y)) < 0.001, "the EVA porch is level with the ready-room deck (decision 4)")
	_check(garage.dock.states == ["SEALED", "EQUALISING", "SAFE TO OPEN"], "the dock uses the canonical interlock words")

func _test_survey(cold: Dictionary) -> void:
	var survey: Dictionary = cold.survey
	var beacons: Array = survey.beacons
	_check(beacons.size() == 3, "canon's three beacons on the real road (decision 9: 5 m masts)")
	var states := []
	for b in beacons:
		_check(float(b.link_back.clearance_m) > 0.0, "%s sees its predecessor over the curved terrain (%.1f m clear)" % [b.id, float(b.link_back.clearance_m)])
		_check(float(b.segment.max_slope_deg) <= 12.0, "%s segment within the 12 deg approach slope" % b.id)
		states.append(String(b.light.sun_state))
	_check(states == ["lit", "lit", "dark"], "B1 and B2 are sunlit and B3 is in terrain shadow at EX-CH04-S04")
	_check(float(survey.shelf_link.clearance_m) > 0.0, "B3 links to the vault shelf")
	_check(float(survey.road.max_slope_deg) < 15.0, "the road stays under the rover's 15 deg limit")
	_check(survey.vault_shelf.size_m == [20.0, 15.0] and String(survey.vault_shelf.light.sun_state) == "dark", "the 20 x 15 m shelf is in permanent shadow")
	_check(absf(float(Kit.piece("EN_ColdTrap_BeaconMast").size_m[1]) - 5.0) < 0.02, "the beacon mast stands 5 m")

# ----------------------------------------------------------------------------------------------- assembled garage

func _test_assembled() -> void:
	var garage := Garage.new()
	garage.build_on_ready = false
	root.add_child(garage)
	garage.build()
	var missing := PackedStringArray()
	for role in ROLES:
		if not garage.nodes.has(role):
			missing.append(role)
	_check(missing.is_empty(), "every role of the layout is placed " + ", ".join(missing))
	_check(garage.rover != null, "VH_Rover is docked in the bay")
	await physics_frame
	await physics_frame
	var space := garage.get_world_3d().direct_space_state
	var deck := _ray(space, Vector3(4.0, 3.6, 1.5), Vector3(4.0, -1.0, 1.5))
	_check(not deck.is_empty() and absf(deck.position.y - 1.40) < 0.03, "the ready-room deck is walkable at +1.40 m")
	var porch := _ray(space, Vector3(1.5, 3.6, 5.0), Vector3(1.5, -1.0, 5.0))
	_check(not porch.is_empty() and absf(porch.position.y - 1.40) < 0.03, "the EVA porch deck is walkable at +1.40 m")
	var bay := _ray(space, Vector3(11.2, 3.0, 8.6), Vector3(11.2, -1.0, 8.6))
	_check(not bay.is_empty() and absf(bay.position.y) < 0.03, "the bay floor is walkable at 0.00")
	var collar := garage.nodes.docking_port.find_children("DockCollar", "Node3D", true, false)[0] as Node3D
	var reach := _subtree_bounds(collar, garage).end.z
	var hatch_z := float(Garage.layout().rover.hatch[2])
	_check(absf(reach - hatch_z) < 0.05, "the docked collar meets the rover's hatch plane (%.3f vs %.3f)" % [reach, hatch_z])
	_check(garage.set_lock_door("InnerDoor", true) and not garage.set_lock_door("OuterDoor", true), "the cargo lock never opens both doors at once")
	garage.set_lock_door("InnerDoor", false)
	_check(garage.set_lock_door("OuterDoor", true), "the outer door opens once the inner is shut")
	garage.set_lock_door("OuterDoor", false)
	garage.free()

func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

func _bounds(node: Node3D) -> AABB:
	return _subtree_bounds(node, node)

func _subtree_bounds(leaf: Node3D, ancestor: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh in leaf.find_children("*", "MeshInstance3D", true, false):
		var xf := ancestor.global_transform.affine_inverse() * (mesh as MeshInstance3D).global_transform
		var aabb := xf * (mesh as MeshInstance3D).get_aabb()
		box = aabb if first else box.merge(aabb)
		first = false
	return box

# ----------------------------------------------------------------------------------------------- evidence

func _evidence() -> void:
	root.size = Vector2i(1600, 1000)
	root.always_on_top = true
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	camera.far = 4000.0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#020305")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.88, 0.92)
	env.ambient_light_energy = 0.04
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.fog_enabled = false
	var world := WorldEnvironment.new()
	world.environment = env
	stage.add_child(world)
	# apron ground and the dated low Sun of EX-CH04-S02 (40 deg left of the door's outward normal, 1.8 deg up)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	ground.mesh = plane
	ground.material_override = load(REGOLITH)
	ground.position = Vector3(6.0, -0.002, 4.5)
	stage.add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.light_energy = 3.0
	sun.directional_shadow_max_distance = 120.0
	stage.add_child(sun)
	var toward := Vector3(cos(deg_to_rad(40.0)), tan(deg_to_rad(1.8)), -sin(deg_to_rad(40.0))).normalized()
	sun.look_at_from_position(toward * 50.0 + Vector3(6, 0, 4.5), Vector3(6, 0, 4.5), Vector3.UP)
	var garage := Garage.new()
	garage.build_on_ready = false
	stage.add_child(garage)
	garage.build()
	var caption := _caption()
	garage.set_rover_door_open(true)
	_aim(camera, Vector3(19.5, 1.9, 7.6), Vector3(4.0, 2.2, 4.6), 66)
	_set_caption(caption, "EN_Garage (LOC-08) in Godot: into the vacuum bay through the open rover door",
			"VH_Rover docked at the telescoping tunnel, the EVA porch at its rear, the ready-room windows on the left; the door coiled into its drum; low Sun of EX-CH04-S02")
	await _capture("M3-4A_godot_bay")
	_aim(camera, Vector3(34.0, 4.0, 1.0), Vector3(10.0, 2.6, 6.0), 50)
	_set_caption(caption, "EN_Garage exterior: the 1 m regolith berm, the sintered headwall and wing walls",
			"The rover door faces the apron and the marked path to the courtyard (decision 3); black sky, one low Sun")
	await _capture("M3-4A_godot_exterior")
	garage.set_dock_hatch_open(true)
	_aim(camera, Vector3(1.2, 3.02, 0.6), Vector3(8.8, 2.75, 2.9), 80)
	_set_caption(caption, "Ready room (habitat air, deck +1.40 m): route board, two departure boards, the open dock hatch",
			"Windows onto the bay; Amara's handover console and the relief locker along the back wall; every screen is a live slot")
	await _capture("M3-4A_godot_ready")
	_aim(camera, Vector3(5.6, 2.6, 4.1), Vector3(8.6, 2.4, 3.6), 70)
	_set_caption(caption, "The dock: the collar extended to VH_Rover's side hatch (1.85 m sill), seen from the bay",
			"A trip pumps down about 1 m3 of tunnel, never the bay (decision 1)")
	await _capture("M3-4A_godot_dock")
	garage.set_lock_door("OuterDoor", true)
	_aim(camera, Vector3(2.6, 3.2, 6.6), Vector3(1.6, 2.0, 3.0), 70)
	_set_caption(caption, "EVA porch (+1.40 m) and the dry cargo lock, outer door open",
			"Suited crew load the sealed vault here; the lock fills with dry nitrogen, then the inner door opens into the ready room (decision 5)")
	await _capture("M3-4A_godot_porch")
	garage.free()
	# the cold-trap site pieces and the vault set on the regolith, sunlit
	var line := Node3D.new()
	stage.add_child(line)
	var x := 0.0
	for id in ["EN_ColdTrap_BeaconMast", "EN_ColdTrap_ReturnMarker", "EN_ColdTrap_SlopeSign", "EN_ColdTrap_ReferencePlate", "EN_ColdTrap_SampleStake",
			"EN_ColdTrap_TetherAnchor", "EN_ColdTrap_SurveyMarker2034"]:
		Kit.place(line, id, Vector3(x, 0.0, 0.0), 0.0)
		x += 1.6
	_aim(camera, Vector3(4.8, 2.6, -8.5), Vector3(4.8, 1.4, 0.0), 58)
	_set_caption(caption, "EN_ColdTrap site pieces in Godot: 5 m beacon mast, return marker, slope sign, dry reference plate, sample stake, tether anchor, 2034 marker",
			"Driven pieces sit at their mount depth; signs, tags and the slope value are blank live slots")
	await _capture("M3-4A_godot_coldtrap_pieces")
	line.free()
	var set_node := Node3D.new()
	stage.add_child(set_node)
	var closed := (load("res://assets/props/PR_VaultCase/PR_VaultCase.glb") as PackedScene).instantiate() as Node3D
	closed.position = Vector3(-0.55, 0, 0)
	set_node.add_child(closed)
	var open_case := (load("res://assets/props/PR_VaultCase/PR_VaultCase.glb") as PackedScene).instantiate() as Node3D
	open_case.position = Vector3(0.15, 0, 0)
	set_node.add_child(open_case)
	(open_case.find_children("Lid", "Node3D", true, false)[0] as Node3D).rotation_degrees.z = -105.0
	for item in [["res://assets/props/PR_VaultProbe/PR_VaultProbe.glb", Vector3(0.75, 0, 0.25)], ["res://assets/props/PR_VaultCarrier/PR_VaultCarrier.glb", Vector3(-0.3, 0, -1.0)],
			["res://assets/props/PR_RoverCargoMount/PR_RoverCargoMount.glb", Vector3(0.95, 0, -0.95)]]:
		var node := (load(String(item[0])) as PackedScene).instantiate() as Node3D
		node.position = item[1]
		set_node.add_child(node)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.2, 2.2, 1.6)
	fill.light_energy = 1.2
	fill.omni_range = 6.0
	set_node.add_child(fill)
	_aim(camera, Vector3(0.2, 1.45, 1.9), Vector3(0.1, 0.2, -0.3), 48)
	_set_caption(caption, "The vault set in Godot: V12 closed and open (12 wells, Label_Lid under the lid), probe, recovery carrier, rover cargo mount",
			"The rebuilt case keeps the installed case's 0.60 x 0.39 m footprint; the inscription and the tags are live text (clues 14-15)")
	await _capture("M3-4A_godot_vault_set")
	stage.free()

func _aim(camera: Camera3D, from: Vector3, at: Vector3, fov: float) -> void:
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = fov
	camera.global_position = from
	camera.look_at(at, Vector3.UP)

func _caption() -> Label:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -128
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.86)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	panel.add_child(label)
	return label

func _set_caption(label: Label, heading: String, detail: String) -> void:
	label.text = heading + "\n" + detail

func _capture(label: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "evidence written: " + label)
