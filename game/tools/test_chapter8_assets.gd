## M3-8A: the Chapter 8 summit and road pieces load with collision and a Compatibility LOD, carry their sockets, moving
## nodes, live screens and lamps; the Earth dish and the local antenna aim where the dated sky and the road chain say;
## VH_Rover's light sockets point where rover_lights.json says; the rooftop backdrops and Noor's cut-out are installed.
## Headless: game/tools/run_tests.sh chapter8_assets
## Evidence (needs a window): Godot --path game --script res://tools/test_chapter8_assets.gd -- --evidence
extends SceneTree

const C8 = preload("res://assets/environment/EN_MalapertSummit/chapter8_assets.gd")
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const SUMMIT := ["EN_MalapertSummit_RelayDeck", "EN_MalapertSummit_ControllerHousing", "EN_MalapertSummit_PowerIsolator",
	"EN_MalapertSummit_ControlPedestal", "EN_MalapertSummit_SolarMast", "EN_MalapertSummit_TetherAnchor",
	"EN_MalapertSummit_PerimeterMarker", "EN_MalapertSummit_UmbilicalPost", "EN_MalapertSummit_ViewpointRail",
	"EN_MalapertSummit_CableTray"]
const ROAD := ["EN_RelayRoad_Repeater", "EN_RelayRoad_BatteryModule", "EN_RelayRoad_GuideLight", "EN_RelayRoad_SlopeSign",
	"EN_RelayRoad_TurnbackBarrier", "EN_RelayRoad_SupplyCache"]
const SLOTS := {"EN_MalapertSummit_ControlPedestal": ["Screen_LocalLeg", "Screen_EarthLeg", "Screen_Checksum"],
	"EN_MalapertSummit_ControllerHousing": ["Lamp_Status_0", "Lamp_Status_1", "Lamp_Status_2"],
	"EN_RelayRoad_Repeater": ["Lamp_Beacon", "Lamp_Link_0", "Lamp_Link_1"], "EN_RelayRoad_GuideLight": ["Lamp_Guide"]}
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
	var summit := C8.catalog("EN_MalapertSummit")
	var road := C8.catalog("EN_RelayRoad")
	_check(summit.get("task") == "M3-8A" and road.get("task") == "M3-8A", "both catalogues written by the M3-8A build")
	_check(_ids(summit) == SUMMIT, "ten summit pieces in catalogue order")
	_check(_ids(road) == ROAD, "six road pieces in catalogue order")
	for id in SUMMIT + ROAD:
		_test_piece(id)
	_test_aims()
	_test_summit_layout(summit)
	_test_road_data(road)
	_test_rover()
	_test_screens()
	await _test_collision()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence(summit)
	print("CHAPTER8 ASSETS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _ids(cat: Dictionary) -> Array:
	var out := []
	for p in cat.get("pieces", []):
		out.append(p.id)
	return out

func _local(node: Node3D, ancestor: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != ancestor:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf

func _bounds(group: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh in group.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh as MeshInstance3D
		var aabb := _local(mi, group) * mi.get_aabb()
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

func _test_piece(id: String) -> void:
	var item := C8.entry(id)
	_check(item.lods.size() == 2 and item.triangles.size() == 2, id + " has a game LOD and a Compatibility LOD")
	_check(int(item.triangles[0]) <= 8000 and int(item.triangles[1]) <= int(item.triangles[0]), id + " within the art bible's 8k and LOD1 no heavier")
	var node := C8.instance(id)
	root.add_child(node)
	var lod0: Node3D = node.get_node_or_null("LOD0")
	var lod1: Node3D = node.get_node_or_null("LOD1")
	_check(lod0 != null and lod1 != null, id + " builds both LODs")
	if lod0 == null or lod1 == null:
		node.free()
		return
	_check(abs(_triangles(lod0) - int(item.triangles[0])) <= int(item.triangles[0]) / 100 + 2, id + " imported triangles match the catalogue (%d)" % _triangles(lod0))
	var box := _bounds(lod0)
	var size: Array = item.size_m
	_check(absf(box.position.y) < 0.01, id + " stands on its base (lowest point %.4f)" % box.position.y)
	# rotated parts (dish, antennas) inflate a transformed mesh AABB by a few cm, so the height is exact and the footprint loose
	_check(absf(box.size.y - float(size[1])) < 0.02 and Vector2(box.size.x, box.size.z).distance_to(Vector2(size[0], size[2])) < 0.08, id + " imported size matches the catalogue (%s)" % str(box.size))
	var bodies := lod0.find_children("*", "StaticBody3D", true, false)
	_check(bodies.size() > 0, id + " game LOD carries collision")
	var convex := true
	for body in bodies:
		var shapes := (body as Node).find_children("*", "CollisionShape3D", true, false)
		convex = convex and not shapes.is_empty() and (shapes[0] as CollisionShape3D).shape is ConvexPolygonShape3D
	_check(convex, id + " collision is simplified convex boxes, not the visual mesh")
	_check(lod1.find_children("*", "StaticBody3D", true, false).is_empty(), id + " Compatibility LOD has no collision")
	var sockets: Dictionary = item.get("sockets", {})
	var placed := true
	for s in sockets:
		var found := lod0.find_child(s, true, false) as Node3D
		var want: Array = sockets[s]
		placed = placed and found != null and _local(found, lod0).origin.distance_to(Vector3(want[0], want[1], want[2])) < 0.01
	_check(placed, id + " every catalogue socket is in the game LOD at its position (%d)" % sockets.size())
	var moving := true
	for part in item.get("moving_nodes", {}):
		moving = moving and lod0.find_child(part, true, false) != null and lod1.find_child(part, true, false) != null
	_check(moving, id + " every moving node is in both LODs (%d)" % item.get("moving_nodes", {}).size())
	for slot in SLOTS.get(id, []):
		_check(C8.surfaces(node, slot).size() == 2, id + " slot " + slot + " in both LODs")
	if id.ends_with("ControlPedestal"):
		_check(C8.set_screen(node, "Screen_Checksum", ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGB8))) == 2, "the checksum screen takes a live texture")
	if SLOTS.get(id, []).size() > 0 and String(SLOTS[id][0]).begins_with("Lamp"):
		_check(C8.set_lamp(node, SLOTS[id][0], Color(1.0, 0.55, 0.1)) == 2, id + " lamp lights in both LODs")
	node.free()

func _test_aims() -> void:
	var deck := (load(C8.entry("EN_MalapertSummit_RelayDeck").lods[0]) as PackedScene).instantiate() as Node3D
	root.add_child(deck)
	var dish := deck.find_child("DishElevation", true, false) as Node3D
	var local := deck.find_child("LocalElevation", true, false) as Node3D
	var earth := C8.sky_direction(358.7, -2.3)
	var r3 := C8.sky_direction(216.7, -4.8)
	# the sheet's +Z boresight is Godot +Y on the elevation nodes
	var dish_axis := _local(dish, deck).basis.y.normalized()
	var local_axis := _local(local, deck).basis.y.normalized()
	_check(rad_to_deg(dish_axis.angle_to(earth)) < 0.3, "the Earth dish boresight aims at azimuth 358.7, elevation -2.3 (off by %.2f deg)" % rad_to_deg(dish_axis.angle_to(earth)))
	_check(rad_to_deg(local_axis.angle_to(r3)) < 0.3, "the local antenna aims at R3: azimuth 216.7, elevation -4.8 (off by %.2f deg)" % rad_to_deg(local_axis.angle_to(r3)))
	_check(dish_axis.y < 0.0, "the dish points below level: Earth sits under the mathematical horizon from the 5 km summit")
	deck.free()

func _test_summit_layout(cat: Dictionary) -> void:
	var sky: Dictionary = cat.get("dated_sky", {})
	_check(absf(float(sky.get("earth_el_deg", 0)) - (-2.32)) < 0.01 and absf(float(sky.get("sun_el_deg", 0)) - 2.313) < 0.01, "the dated sky is the EX-CH08-S10 Horizons row")
	_check(float(cat.terrain.pad_level_m) == -0.3, "the pad is cut level 0.3 m under the crown (decision 1)")
	var markers := 0
	for p in cat.placements:
		if p.piece == "EN_MalapertSummit_PerimeterMarker":
			markers += 1
	_check(markers == 20, "perimeter markers every 5 m round the 30 x 20 m pad (%d)" % markers)
	_check(cat.anchors.has("kai_housing") and cat.anchors.has("ferreira_door_brace") and cat.anchors.has("rafi_tether"), "crew anchors for S07")

func _test_road_data(cat: Dictionary) -> void:
	var total := 0
	for s in cat.segments:
		total += int(s.length_m)
	_check(cat.segments.size() == 5 and total == 700, "five playable segments, 700 m in all")
	_check(cat.repeaters.size() == 3 and cat.laybys.size() == 2, "three repeaters and two laybys")
	var chain := 0
	var clear := true
	for h in cat.hops:
		if h.chain_link:
			chain += 1
			clear = clear and bool(h.clear)
	_check(chain == 4 and clear, "four clear hops: Aurora, R1, R2, R3, summit")
	var ten := true
	for s in cat.segments:
		if s.id != "E":
			ten = ten and s.lola_10m is Dictionary and s.lola_10m.has("height_m")
	_check(ten, "segments A-D carry heights from the 10 m LOLA tiles")
	_check(int(cat.road.game_km) == 120, "the game keeps 120 km each way")

func _test_rover() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/vehicles/VH_Rover/rover_lights.json"))
	var scene := load("res://assets/vehicles/VH_Rover/VH_Rover_Lit.tscn") as PackedScene
	_check(scene != null, "VH_Rover_Lit.tscn loads")
	if scene == null:
		return
	var rover := scene.instantiate() as Node3D
	root.add_child(rover)
	_check(rover.get_node_or_null("VH_Rover") != null, "the lit scene instances VH_Rover.glb")
	var ok := true
	for l in data.lights:
		var light := rover.get_node_or_null(String(l.name)) as Light3D
		ok = ok and light != null and light.position.distance_to(Vector3(l.position[0], l.position[1], l.position[2])) < 0.01
		if light is SpotLight3D:
			var d := Vector3(l.direction[0], l.direction[1], l.direction[2])
			ok = ok and (-light.transform.basis.z).normalized().angle_to(d) < deg_to_rad(0.5)
	_check(ok and data.lights.size() == 5, "five light sockets where rover_lights.json puts and aims them")
	_check(not (rover.get_node("RoofFlood_L") as Light3D).visible and (rover.get_node("Headlight_L") as Light3D).visible, "roof work floods off until an EVA stop (decision 7)")
	var front := true
	for l in data.lights:
		front = front and float(l.position[2]) > 1.0
	_check(front, "every light sits at the cabin end (+Z)")
	rover.free()

func _test_screens() -> void:
	for path in ["res://assets/ui/screens/EN_NoorRooftop.png", "res://assets/ui/screens/EN_NoorRooftop_noon.png"]:
		var t := load(path) as Texture2D
		_check(t != null and t.get_width() == 1536 and t.get_height() == 864, path + " is a 1536 x 864 Earth-screen backdrop")
	var noor := load("res://assets/ui/portraits/CH_Noor_live.png") as Texture2D
	_check(noor != null, "CH_Noor_live.png loads")
	if noor != null:
		var img := noor.get_image()
		if img.is_compressed():
			img.decompress()
		_check(img.detect_alpha() != Image.ALPHA_NONE and img.get_pixel(1, 1).a < 0.05, "Noor's live-call portrait is a cut-out (transparent corners)")

func _test_collision() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var deck := C8.instance("EN_MalapertSummit_RelayDeck")
	world.add_child(deck)
	var housing := C8.instance("EN_MalapertSummit_ControllerHousing")
	housing.position = Vector3(10, 0, 0)
	world.add_child(housing)
	for i in 3:
		await physics_frame
	var space := (world as Node3D).get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(1.4, 4, 1.4), Vector3(1.4, -1, 1.4)))
	_check(not hit.is_empty() and absf(hit.position.y - 1.25) < 0.05, "the relay deck can be stood on (top at 1.25 m)")
	hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(12, 1, 0.2), Vector3(9, 1, 0.2)))
	_check(not hit.is_empty() and hit.position.x > 10.3 and hit.position.x < 10.5, "a ray from the east stops on the closed service door")
	world.free()

# ----------------------------------------------------------------------------------------------- evidence

func _evidence(summit: Dictionary) -> void:
	root.size = Vector2i(1600, 900)
	root.always_on_top = true
	var label := _caption()
	var scene := Node3D.new()
	root.add_child(scene)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color.BLACK
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.03, 0.03, 0.035)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	scene.add_child(env)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	var regolith := load("res://assets/environment/terrain/materials/EN_Regolith_Fresh.tres") as Material
	ground.material_override = regolith if regolith != null else StandardMaterial3D.new()
	scene.add_child(ground)
	var sun := DirectionalLight3D.new()
	var to_sun := C8.sky_direction(float(summit.dated_sky.sun_az_deg), float(summit.dated_sky.sun_el_deg))
	sun.light_energy = 4.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	scene.add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, -to_sun, Vector3.UP)
	var holder := Node3D.new()
	scene.add_child(holder)
	for p in summit.placements:
		var piece := C8.instance(String(p.piece))
		piece.position = Vector3(p.at_xz[0], 0, p.at_xz[1])
		piece.rotation.y = deg_to_rad(float(p.yaw_deg))
		holder.add_child(piece)
	for run in summit.cable_runs:
		var a := Vector3(run.from_xz[0], 0, run.from_xz[1])
		var b := Vector3(run.to_xz[0], 0, run.to_xz[1])
		var n := maxi(1, int(round(a.distance_to(b) / 2.0)))
		for k in n:
			var tray := C8.instance("EN_MalapertSummit_CableTray")
			tray.position = a.lerp(b, (k + 0.5) / n)
			tray.rotation.y = -atan2(b.z - a.z, b.x - a.x)
			holder.add_child(tray)
	var rover := (load("res://assets/vehicles/VH_Rover/VH_Rover_Lit.tscn") as PackedScene).instantiate() as Node3D
	rover.position = Vector3(summit.rover.at_xz[0], 0, summit.rover.at_xz[1])
	rover.rotation.y = deg_to_rad(-90)
	holder.add_child(rover)
	var camera := Camera3D.new()
	camera.fov = 55
	scene.add_child(camera)
	camera.current = true
	camera.look_at_from_position(Vector3(18, 9, -24), Vector3(-3, 0, -2), Vector3.UP)
	_say(label, "M3-8A EN_MalapertSummit in Godot: the catalogue layout (malapert_summit.json) under the EX-CH08-S10 Sun (azimuth 18.1, elevation +2.3)",
		"Relay deck with the dish aimed at Earth (azimuth 358.7, 2.3 deg below level), housing, isolator, pedestal, solar mast, tether anchors, viewpoint rail, cable trays, 20 perimeter markers; VH_Rover_Lit heading west. Flat stand-in ground; the LOLA tile and the pad cut are M3-8R's.")
	await _capture("M3-8A_godot_summit")
	var housing := _find_piece(holder, "EN_MalapertSummit_ControllerHousing")
	var hinge := housing.find_child("DoorHinge", true, false) as Node3D
	hinge.rotation.y = deg_to_rad(105)
	for i in 3:
		C8.set_lamp(housing, "Lamp_Status_%d" % i, Color(1.0, 0.55, 0.1) if i < 2 else Color.BLACK)
	var pedestal := _find_piece(holder, "EN_MalapertSummit_ControlPedestal")
	for slot in ["Screen_LocalLeg", "Screen_EarthLeg", "Screen_Checksum"]:
		var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
		img.fill(Color(0.1, 0.6, 0.3) if slot != "Screen_Checksum" else Color(0.15, 0.4, 0.9))
		C8.set_screen(pedestal, slot, ImageTexture.create_from_image(img))
	var fill := SpotLight3D.new()
	fill.light_energy = 6.0
	fill.spot_range = 20.0
	scene.add_child(fill)
	fill.look_at_from_position(Vector3(3.5, 2.5, 0.5), Vector3(-3.6, 0.9, -1.4), Vector3.UP)
	camera.fov = 50
	camera.look_at_from_position(Vector3(-0.2, 1.7, 1.6), Vector3(-3.4, 0.9, -1.5), Vector3.UP)
	_say(label, "M3-8A controller housing at EX-CH08-S07/S08: door open on its hinge, two status lamps amber (two unverified channels), pedestal screens live",
		"Every lamp and screen is a named slot (Lamp_Status_0..2, Screen_LocalLeg, Screen_EarthLeg, Screen_Checksum) driven at runtime; no words are baked into any surface. Fill light stands in for the rover's work floods.")
	await _capture("M3-8A_godot_housing")
	holder.free()
	fill.free()
	var lineup := Node3D.new()
	scene.add_child(lineup)
	var x := 0.0
	for id in SUMMIT + ROAD:
		var item := C8.entry(id)
		var width := maxf(float(item.size_m[0]), 0.6)
		for lod in 2:
			var node := (load(item.lods[lod]) as PackedScene).instantiate() as Node3D
			node.position = Vector3(x + width / 2.0, 0, -6.0 * lod)
			lineup.add_child(node)
		x += width + 0.8
	camera.fov = 40
	camera.look_at_from_position(Vector3(x / 2.0, 14, 22), Vector3(x / 2.0, 0.5, -3), Vector3.UP)
	sun.look_at_from_position(Vector3.ZERO, Vector3(-0.3, -0.8, -0.5), Vector3.UP)
	_say(label, "M3-8A all sixteen pieces: game LOD with collision (front row) and Compatibility LOD (back row), summit pieces then road pieces",
		"Summit: relay deck, housing, isolator, pedestal, solar mast, tether anchor, perimeter marker, umbilical post, viewpoint rail, cable tray. Road: repeater, battery module, guide light, slope sign, turnback barrier, supply cache. Studio sun for readability.")
	await _capture("M3-8A_godot_lods")
	lineup.free()
	sun.visible = false
	var night := Node3D.new()
	scene.add_child(night)
	var repeater := C8.instance("EN_RelayRoad_Repeater")
	night.add_child(repeater)
	C8.set_lamp(repeater, "Lamp_Beacon", Color(1.0, 0.55, 0.1), 6.0)
	C8.set_lamp(repeater, "Lamp_Link_0", Color(0.2, 1.0, 0.35))
	C8.set_lamp(repeater, "Lamp_Link_1", Color(0.2, 1.0, 0.35))
	var battery := C8.instance("EN_RelayRoad_BatteryModule")
	battery.position = Vector3(0.7, 0, 0.6)
	night.add_child(battery)
	for k in 6:
		var gl := C8.instance("EN_RelayRoad_GuideLight")
		gl.position = Vector3(-6.0 - k * 18.0 * 0.926, 0, 2.0 + k * 18.0 * 0.378 + (3.4 if k % 2 == 0 else -3.4))
		night.add_child(gl)
		var omni := OmniLight3D.new()
		omni.light_color = Color(1.0, 0.6, 0.2)
		omni.light_energy = 1.2
		omni.omni_range = 4.0
		omni.position = gl.position + Vector3(0, 0.66, 0)
		night.add_child(omni)
	var slope_sign := C8.instance("EN_RelayRoad_SlopeSign")
	slope_sign.position = Vector3(-14, 0, 9)
	night.add_child(slope_sign)
	var barrier := C8.instance("EN_RelayRoad_TurnbackBarrier")
	barrier.position = Vector3(-16, 0, 11)
	barrier.rotation.y = deg_to_rad(35)
	night.add_child(barrier)
	var cache := C8.instance("EN_RelayRoad_SupplyCache")
	cache.position = Vector3(4, 0, -5)
	night.add_child(cache)
	var lit := (load("res://assets/vehicles/VH_Rover/VH_Rover_Lit.tscn") as PackedScene).instantiate() as Node3D
	lit.position = Vector3(-7, 0, 6)
	lit.rotation.y = deg_to_rad(-130)
	night.add_child(lit)
	(lit.get_node("RoofFlood_L") as Light3D).visible = true
	(lit.get_node("RoofFlood_R") as Light3D).visible = true
	var helmet := SpotLight3D.new()  # a crew member's helmet lamp on the repeater (Kai at the battery bay)
	helmet.light_energy = 3.0
	helmet.spot_range = 9.0
	helmet.spot_angle = 30.0
	night.add_child(helmet)
	helmet.look_at_from_position(Vector3(1.6, 1.7, 2.4), Vector3(0, 1.2, 0), Vector3.UP)
	camera.fov = 50
	camera.look_at_from_position(Vector3(6.5, 2.4, 7.5), Vector3(-2.5, 1.0, 1.5), Vector3.UP)
	_say(label, "M3-8A EN_RelayRoad in Godot: the marker-two pad in the dark of EX-CH08-S04 (no sunlight; rover lights, guide lights and the repeater beacon only)",
		"Repeater lit after the swap (beacon and both link lamps), battery module, guide lights every 18 m down the spur, slope sign and turnback barrier on the bypass, layby cache; VH_Rover_Lit in its eva_stop state (headlights and both roof work floods).")
	await _capture("M3-8A_godot_road")
	night.free()
	scene.free()
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/screens/EN_NoorRooftop.png")
	bg.size = Vector2(1600, 900)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.add_child(bg)
	var noor := TextureRect.new()
	noor.texture = load("res://assets/ui/portraits/CH_Noor_live.png")
	noor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	noor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	noor.size = Vector2(380, 860)
	noor.position = Vector2(610, 120)
	layer.add_child(noor)
	_say(label, "M3-8A EN_NoorRooftop + CH_Noor_live: the S10 Earth-screen backdrop (Dhaka, 08:15) with Noor's cel-shaded cut-out",
		"Both are 2D screen assets (decision 12: \"2D portraits only\"); the commons-screen binding is a board task for the screen's owner. No lettering anywhere in the backdrop.")
	await _capture("M3-8A_godot_rooftop_screen")
	bg.texture = load("res://assets/ui/screens/EN_NoorRooftop_noon.png")
	_say(label, "M3-8A EN_NoorRooftop_noon: the S12 backdrop (10 Apr 12:00 Dhaka) for \"Show me the cotton by the window.\"", "")
	await _capture("M3-8A_godot_rooftop_noon")
	layer.free()

func _find_piece(holder: Node, id: String) -> Node3D:
	for c in holder.get_children():
		if c.name.begins_with(id):
			return c as Node3D
	return null

func _caption() -> Label:
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.09, 0.86)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(14, 10)
	layer.add_child(panel)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(1540, 0)
	label.size = Vector2(1540, 0)
	panel.custom_minimum_size = Vector2(1572, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98))
	panel.add_child(label)
	return label

func _say(label: Label, heading: String, detail: String) -> void:
	label.text = heading + ("\n" + detail if detail != "" else "")
	(label.get_parent() as Control).reset_size()

func _capture(file_name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + file_name + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "evidence written: " + file_name)
