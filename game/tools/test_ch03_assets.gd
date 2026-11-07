## M3-3A: the Chapter 3 (Moonquake) assets load, snap, carry collision and moving parts, and keep their canon counts:
## the Expedition Zero annex pieces (annex.json, read by habitat_kit.gd as an extension catalogue), the helmet role
## variants (helmet_roles.json), the descendant rack (descendants.json: seven purple stems, five green), the pressed
## petal in its sleeve, and the five fitted EVA suits (CH_<Name>_EVA) with their helmets locked on.
## Headless: game/tools/run_tests.sh ch03_assets
## Evidence (needs a window): Godot --path game --script res://tools/test_ch03_assets.gd -- --evidence
extends SceneTree

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const Helmet = preload("res://assets/props/PR_Helmet_Roles/helmet_roles.gd")
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const ANNEX_CATALOG := "res://assets/environment/EN_ZeroAnnex/annex.json"
const ANNEX_IDS := ["EN_ZeroAnnex_FloorHatch", "EN_ZeroAnnex_Ladder", "EN_ZeroAnnex_Wall", "EN_ZeroAnnex_Wall_Corner", "EN_ZeroAnnex_Floor",
	"EN_ZeroAnnex_Ceiling", "EN_ZeroAnnex_CeilingLamp", "EN_ZeroAnnex_TrayBench", "EN_ZeroAnnex_ChartArchive", "EN_ZeroAnnex_SupportStation"]
const CEILING_IDS := ["EN_ZeroAnnex_Ceiling", "EN_ZeroAnnex_CeilingLamp"]
## Dead fixture tiles in the 10 x 6 m sample, one every 3 m on two rows (tile x, tile z; centres at +0.5).
const LAMP_TILES := [Vector2i(-2, -2), Vector2i(1, -2), Vector2i(4, -2), Vector2i(7, -2), Vector2i(-2, 1), Vector2i(1, 1), Vector2i(4, 1), Vector2i(7, 1)]
const WALL_IDS := ["EN_ZeroAnnex_Wall", "EN_ZeroAnnex_Wall_Corner"]
const DESCENDANTS := "res://assets/plants/PL_Descendants/PL_Descendants.glb"
const DESCENDANTS_PLANTED := "res://assets/plants/PL_Descendants_Planted/PL_Descendants_Planted.glb"
const DESCENDANTS_DATA := "res://assets/plants/PL_Descendants/descendants.json"
const PETAL := "res://assets/props/PR_PressedPetal/PR_PressedPetal.glb"
const PETAL_MOUNTED := "res://assets/props/PR_PressedPetal_Mounted/PR_PressedPetal_Mounted.glb"
const TRAY := "res://assets/plants/PL_ZeroSeedlingTray/PL_ZeroSeedlingTray.glb"
const DRUM := "res://assets/props/PR_AnnexDrum/PR_AnnexDrum.glb"
## The fitted EVA suits and their skeletons (Mei's carries three ponytail bones); every suit has the cast's 44 clips.
const EVA_BONES := {"kai": 65, "amara": 65, "mei": 68, "rafi": 65, "ferreira": 65}
const EVA_LAYERS := ["Body", "FaceEyeL", "FaceEyeR", "FaceMouth", "PatchFlagL", "PatchAuroraR", "PatchAuroraChest"]
const ANNEX_DROP := 3.0  # the lower annex floor is 3 m below the corridor deck (annex.json conventions)
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
	_test_catalogue()
	for id in ANNEX_IDS:
		_test_piece(id)
	await _test_moving_parts()
	await _test_assembly()
	_test_helmet()
	_test_descendants()
	_test_petal()
	_test_eva()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence()
	print("CH03 ASSETS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

# ----------------------------------------------------------------------------------------------- annex pieces

func _test_catalogue() -> void:
	_check(Kit.catalog().pieces.size() == 12, "the habitat kit's own catalogue is untouched (12 pieces)")
	var ids := Kit.extension_ids(ANNEX_CATALOG)
	_check(ids.size() == 10 and Array(ids) == ANNEX_IDS, "annex.json lists the ten annex pieces in order")
	for id in ids:
		_check(not Kit.piece(id).is_empty(), id + " resolves through Kit.piece() like a kit piece")
	_check(Kit.piece("EN_Kit_Hatch").id == "EN_Kit_Hatch", "kit pieces still resolve first")
	_check(Kit.piece("EN_Nope").is_empty(), "unknown ids stay empty")
	var hatch: Dictionary = Kit.piece("EN_ZeroAnnex_FloorHatch")
	_check(hatch.sockets.parts.has("HatchLeaf") and hatch.sockets.parts.has("Cover") and hatch.sockets.parts.has("PortShutter") and hatch.sockets.parts.has("FeedValve"),
		"the floor hatch declares its four moving parts (leaf, cover, port shutter, feed valve)")
	_check(absf(float(hatch.sockets.opening_diameter) - 0.9) < 0.01, "the N.R. hatch opening is 0.9 m")

func _test_piece(id: String) -> void:
	var entry := Kit.piece(id)
	_check(entry.lods.size() == 2 and entry.triangles.size() == 2, id + " has a game LOD and a Compatibility LOD")
	_check(int(entry.triangles[0]) <= 8000 and int(entry.triangles[1]) <= int(entry.triangles[0]), id + " triangle budget 8k and LOD1 no heavier than LOD0")
	for path in entry.lods:
		_check(load(path) is PackedScene, "load " + String(path))
	var node := Kit.instance(id)
	root.add_child(node)
	_check(node.get_node_or_null("LOD0") != null and node.get_node_or_null("LOD1") != null, id + " builds both LOD children")
	var lod0: Node3D = node.get_node("LOD0")
	var lod1: Node3D = node.get_node("LOD1")
	var max_tex0 := 0
	var max_tex1 := 0
	var textured := 0
	var opaque := 0
	for mesh in lod0.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material == null:
				continue
			var live := material.resource_name.begins_with("Screen") or material.resource_name.begins_with("Document") or material.resource_name.begins_with("Label") or material.resource_name.begins_with("DeadLamp")
			if material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not material.emission_enabled and not live and material.albedo_texture != null:
				opaque += 1
				if material.normal_texture != null:
					textured += 1
			for texture in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
				if texture != null:
					max_tex0 = maxi(max_tex0, maxi(texture.get_width(), texture.get_height()))
	for mesh in lod1.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material != null:
				for texture in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
					if texture != null:
						max_tex1 = maxi(max_tex1, maxi(texture.get_width(), texture.get_height()))
	_check(opaque > 0 and textured == opaque, id + " every textured surface carries albedo and normal maps (shared annex sets)")
	_check(max_tex0 > 0 and max_tex0 <= 1024 and max_tex1 > 0 and max_tex1 <= 512, id + " texture budget: LOD0 <= 1024 px, LOD1 <= 512 px")
	_check(lod0.find_children("*", "StaticBody3D", true, false).size() > 0, id + " game LOD carries collision bodies")
	_check(lod1.find_children("*", "StaticBody3D", true, false).is_empty(), id + " Compatibility LOD has no duplicate collision")
	var box := Kit.bounds(node, 0)
	_check(absf(box.position.y) <= 0.01, id + " lowest point on the floor (gate rule)")
	var footprint: Array = entry.footprint_m
	_check(absf(box.size.x - float(footprint[0])) <= 0.01, id + " footprint width %.3f matches catalogue %.2f" % [box.size.x, float(footprint[0])])
	if id in WALL_IDS:
		_check(absf(box.size.y - 2.6) <= 0.01, id + " is 2.6 m tall like the kit walls")
		_check(box.end.z >= 0.149 and box.end.z <= 0.22, id + " body ends on the 0.15 m wall depth (frost layer in front)")
	if id == "EN_ZeroAnnex_Floor":
		_check(absf(float(entry.mount_y) + 0.06) < 0.001 and box.end.y <= 0.07, "annex grating deck sits at y=0 when mounted at -0.06")
	if id == "EN_ZeroAnnex_Ladder":
		_check(absf(box.end.y - 3.0) <= 0.01, "the ladder reaches 3.0 m: the corridor deck from the annex floor")
	if id == "EN_ZeroAnnex_TrayBench":
		for socket in ["Socket_Tray_A", "Socket_Tray_B"]:
			var found := node.find_children(socket, "Node3D", true, false)
			_check(found.size() == 2 and absf((found[0] as Node3D).position.y - 0.902) < 0.01, "tray bench exposes %s on the bench top (both LODs)" % socket)
	if id == "EN_ZeroAnnex_SupportStation":
		_check(Kit.screen_surfaces(node).size() == 4, "support station exposes Screen and Screen_Gauge live-UI surfaces in both LODs")
		for socket in ["Socket_ToolTag", "Socket_HandLight"]:
			_check(node.find_children(socket, "Node3D", true, false).size() == 2, "support station exposes " + socket)
	if id == "EN_ZeroAnnex_FloorHatch":
		_check(node.find_children("Socket_Camera", "Node3D", true, false).size() == 2, "the hatch leaf carries Socket_Camera for the viewing camera")
		_check(_material_count(lod0, "Label_Nameplate") == 1, "the N.R. nameplate is a live-UI slot, no text baked")
	if id in CEILING_IDS:
		# both ceiling tiles hang with their frosted face on the 2.6 m wall tops, so plain and fixture tiles line up
		var face := float(entry.mount_y) + float(entry.sockets.frosted_face_y)
		_check(absf(face - 2.6) <= 0.001, id + " frosted face at 2.6 m when mounted (%.3f)" % face)
		_check(_material_count(lod0, "DeadLamp") == (1 if id == "EN_ZeroAnnex_CeilingLamp" else 0),
			id + (" carries the one dead fixture (DeadLamp slot)" if id == "EN_ZeroAnnex_CeilingLamp" else " is a plain panel (fixtures are their own tile)"))
	if id == "EN_ZeroAnnex_ChartArchive":
		for slot in ["Document_Chart", "Document_Route", "Document_Photo", "Label_ServiceTag"]:
			_check(_material_count(lod0, slot) >= 1, "chart archive exposes the %s slot (clue text is drawn by the game)" % slot)
	node.free()

func _material_count(group: Node3D, prefix: String) -> int:
	var n := 0
	for child in group.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var material: Material = mesh.get_active_material(surface)
			if material != null and material.resource_name.begins_with(prefix):
				n += 1
	return n

func _test_moving_parts() -> void:
	# Kit.place() needs a Node3D parent; the SceneTree root is a Window, so the pieces stand on a bare stage.
	var stage := Node3D.new()
	root.add_child(stage)
	var hatch := Kit.place(stage, "EN_ZeroAnnex_FloorHatch", Vector3.ZERO)
	var archive := Kit.place(stage, "EN_ZeroAnnex_ChartArchive", Vector3(4, 0, 0))
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	var deck := _ray(space, Vector3(0.8, 1.0, 0.8), Vector3(0.8, -1.0, 0.8))
	_check(not deck.is_empty() and absf(deck.position.y) <= 0.012, "the module's deck collides at the corridor floor plane y = 0")
	var covered := _ray(space, Vector3(0, 1.0, 0), Vector3(0, -1.0, 0))
	_check(not covered.is_empty() and covered.position.y > 0.1, "at rest the service cover closes the opening (hit at %.3f m)" % (covered.position.y if not covered.is_empty() else -9.0))
	# the hood must hide the whole leaf before the quake (CH02-S12): its top plate (4 cm) clears the dogging wheel
	var leaf_top := -INF
	var leaf_node := hatch.find_children("HatchLeaf", "Node3D", true, false)[0] as Node3D
	for mesh in leaf_node.find_children("*", "MeshInstance3D", true, false):
		var leaf_mesh := mesh as MeshInstance3D
		leaf_top = maxf(leaf_top, ((hatch.global_transform.affine_inverse() * leaf_mesh.global_transform) * leaf_mesh.get_aabb()).end.y)
	var hood_underside: float = (covered.position.y - hatch.global_position.y) - 0.04 if not covered.is_empty() else -9.0
	_check(leaf_top < hood_underside, "the closed cover hood clears the leaf's wheel and handles (leaf top %.3f m, hood underside %.3f m)" % [leaf_top, hood_underside])
	Kit.set_part_open(hatch, "Cover", 1.0)
	await physics_frame
	await physics_frame
	space = root.get_world_3d().direct_space_state
	var leaf_hit := _ray(space, Vector3(0, 1.0, 0), Vector3(0, -1.0, 0))
	_check(not leaf_hit.is_empty() and leaf_hit.position.y > 0.1 and leaf_hit.position.y < 0.2, "with the cover displaced the closed N.R. leaf still blocks the opening")
	var cover := hatch.find_children("Cover", "Node3D", true, false)[0] as Node3D
	var rest_y := float(Kit.piece("EN_ZeroAnnex_FloorHatch").sockets.parts.Cover.rest_position[1])
	_check(cover.position.x > 1.1 and absf(cover.position.y - rest_y) < 0.001 and absf(cover.rotation_degrees.y - 14.0) < 0.01, "the displaced cover hood slid along the deck, clear of the 0.53 m coaming, and turned 14 degrees (quake pose from annex.json)")
	Kit.set_part_open(hatch, "HatchLeaf", 1.0)
	await physics_frame
	await physics_frame
	space = root.get_world_3d().direct_space_state
	var open_hit := _ray(space, Vector3(0, 1.0, 0), Vector3(0, -1.0, 0))
	_check(open_hit.is_empty(), "with the leaf swung up the 0.9 m opening is clear")
	var leaf := hatch.find_children("HatchLeaf", "Node3D", true, false)[0] as Node3D
	_check(absf(leaf.rotation_degrees.z - 100.0) < 0.01, "the leaf opens 100 degrees about its hinge")
	var shutter := hatch.find_children("PortShutter", "Node3D", true, false)[0] as Node3D
	var shutter_x := shutter.position.x
	Kit.set_part_open(hatch, "PortShutter", 1.0)
	_check(absf(shutter.position.x - shutter_x - 0.17) < 0.001, "the camera-port shutter slides 0.17 m along the leaf")
	Kit.set_part_open(hatch, "PortShutter", 0.0)
	_check(absf(shutter.position.x - shutter_x) < 0.001, "and closes again")
	Kit.set_part_open(hatch, "FeedValve", 1.0)
	var valve := hatch.find_children("FeedValve", "Node3D", true, false)[0] as Node3D
	_check(absf(valve.rotation_degrees.y - 90.0) < 0.01, "the utility feed valve turns a quarter to isolate")
	Kit.set_part_open(hatch, "HatchLeaf", 0.0)
	Kit.set_part_open(hatch, "Cover", 0.0)
	_check(absf(leaf.rotation_degrees.z) < 0.01 and cover.position.x < 0.001, "closing restores the leaf and the cover")
	var cover_body := cover.find_children("*", "StaticBody3D", true, false)
	_check(cover_body.size() == 1, "the cover carries its own collision so it moves with the plate")
	var sealed := archive.find_children("SealedCover", "Node3D", true, false)
	_check(sealed.size() == 2, "sealed route-sheet cover in both LODs")
	Kit.set_part_open(archive, "SealedCover", 1.0)
	_check(absf((sealed[0] as Node3D).rotation_degrees.x + 110.0) < 0.01, "the sealed cover hinges open 110 degrees")
	_check(archive.find_children("MapPouch", "Node3D", true, false).size() == 2, "the map pouch is its own removable child")
	stage.free()

func _test_assembly() -> void:
	var scene := _annex_sample()
	root.add_child(scene)
	Kit.set_part_open(scene.get_node("Hatch"), "Cover", 1.0)
	Kit.set_part_open(scene.get_node("Hatch"), "HatchLeaf", 1.0)
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	var down := _ray(space, Vector3(0.1, 1.0, 0.1), Vector3(0.1, -4.0, 0.1))  # inside the 0.45 m opening, off the grating tiles' shared corner
	_check(not down.is_empty() and absf(down.position.y + ANNEX_DROP) <= 0.012, "through the open hatch a ray reaches the annex grating 3.0 m below the corridor (hit %.3f)" % (down.position.y if not down.is_empty() else 9.0))
	var ladder := _ray(space, Vector3(0, -1.5, -0.6), Vector3(0, -1.5, 0.6))
	_check(not ladder.is_empty(), "the ladder stands in the hatch well under the opening")
	var up := _ray(space, Vector3(3.0, -2.5, -2.0), Vector3(3.0, 0.5, -2.0))
	var rib_y := Kit.mount_y("EN_ZeroAnnex_Ceiling") - ANNEX_DROP
	_check(not up.is_empty() and absf(up.position.y - rib_y) <= 0.005, "annex clear height %.3f m under the ceiling ribs, the frosted face at 2.6 m (hit %.3f)" % [rib_y + ANNEX_DROP, up.position.y if not up.is_empty() else 9.0])
	var fixture := _ray(space, Vector3(1.5, -2.5, -1.5), Vector3(1.5, 0.5, -1.5))
	var lamp_y := Kit.mount_y("EN_ZeroAnnex_CeilingLamp") - ANNEX_DROP
	_check(not fixture.is_empty() and absf(fixture.position.y - lamp_y) <= 0.005, "a dead fixture tile hangs its diffuser 3 cm under the ribs (hit %.3f)" % (fixture.position.y if not fixture.is_empty() else 9.0))
	var lamps := 0
	for child in scene.get_node("Annex").get_children():
		if Kit.piece_id(child) == "EN_ZeroAnnex_CeilingLamp":
			lamps += 1  # counted by the piece_id meta: Godot renames same-named siblings
	_check(lamps == LAMP_TILES.size(), "eight dead fixtures in the 10 x 6 m annex, one every 3 m (%d)" % lamps)
	var wall := _ray(space, Vector3(3.0, -1.5, -2.0), Vector3(3.0, -1.5, -5.0))
	_check(not wall.is_empty() and absf(wall.position.z + 3.0) <= 0.03, "the annex far wall collides on the 10 x 6 m room edge")
	var lamp := _ray(space, Vector3(6.0, -1.0, -2.0), Vector3(6.0, -3.0, -2.0))
	_check(not lamp.is_empty() and absf(lamp.position.y - (1.55 - ANNEX_DROP)) <= 0.03, "the dead grow lamp hangs 1.55 m over the bench and collides (hit %.3f)" % (lamp.position.y if not lamp.is_empty() else 9.0))
	# the bench ray starts under the lamp and between the two tray sockets (x = 6 +- 0.3)
	var bench := _ray(space, Vector3(6.0, -1.6, -2.0), Vector3(6.0, -3.0, -2.0))
	_check(not bench.is_empty() and absf(bench.position.y - (0.9 - ANNEX_DROP)) <= 0.03, "the frozen-tray bench top is 0.9 m above the annex floor (hit %.3f)" % (bench.position.y if not bench.is_empty() else 9.0))
	var trays := scene.find_children("PL_ZeroSeedlingTray*", "Node3D", true, false)
	_check(trays.size() == 2, "two frozen 2034 trays sit in the bench sockets (unflowered seedlings only, canon)")
	scene.free()

func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

# ----------------------------------------------------------------------------------------------- helmet, plants, petal

func _test_helmet() -> void:
	var data := Helmet.data()
	_check(data.roles.size() == 5 and Array(Helmet.role_ids()) == ["kai", "amara", "mei", "rafi", "ferreira"], "helmet_roles.json carries the four cadets and Ferreira")
	_check(String(data.get("equip_bone", "")) == "Head", "the Head bone carries the helmet, so the face stays inside it in every clip")
	for key in data.roles:
		var role: Dictionary = data.roles[key]
		# measured on the installed EVA suits (production/tools/fit_helmets_eva.py): never below the approved helmet, and
		# no wider than 1.4x (the suits' neck rings alone need about 1.17x)
		_check(role.stripe_rgb.size() == 3 and float(role.scale) >= 1.0 and float(role.scale) <= 1.4, "%s: stripe colour and a fit scale between 1.0 and 1.4 (%.2f)" % [key, float(role.scale)])
		var clearance: Dictionary = role.head_clearance_m
		_check(float(clearance.width) >= 0.03 and float(clearance.depth) >= 0.03 and float(clearance.height) >= 0.015, "%s: at least 3 cm round the head and 1.5 cm above it at that scale" % key)
		_check(String(role.get("suit", "")) == "CH_%s_EVA" % key.capitalize() and role.equip_origin_m.size() == 3, "%s: fitted to CH_%s_EVA" % [key, key.capitalize()])
	var helmet := Helmet.instance()
	_check(helmet != null, "PR_Helmet_Roles.glb instances")
	if helmet == null:
		return
	root.add_child(helmet)
	_check(Helmet.stripe_surfaces(helmet).size() == 1, "one RoleStripe surface to colour")
	_check(helmet.find_children("Visor", "Node3D", true, false).size() == 1, "the sun visor is its own child (under the GLB root)")
	_check(_material_count(helmet, "M_Crown") == 1, "a crown (its own M_Crown slot on the shell) closes the helmet under the raised visor")
	for socket in ["Socket_Head", "Socket_Lamp"]:
		_check(helmet.find_children(socket, "Node3D", true, false).size() == 1, "helmet exposes " + socket)
	var flag := helmet.find_children("PatchFlag", "MeshInstance3D", true, false)
	var aurora := helmet.find_children("PatchAurora", "MeshInstance3D", true, false)
	_check(flag.size() == 1 and (flag[0] as MeshInstance3D).get_aabb().get_center().x > 0.1, "the Bangladesh flag decal sits on the wearer's LEFT side (+X)")
	_check(aurora.size() == 1 and (aurora[0] as MeshInstance3D).get_aabb().get_center().x < -0.1, "the Aurora patch decal sits on the wearer's RIGHT side (-X)")
	_check(Helmet.apply_role(helmet, "rafi") and absf(helmet.scale.x - float(data.roles.rafi.scale)) < 0.001, "apply_role scales the helmet to Rafi's fit")
	var slot: Dictionary = Helmet.stripe_surfaces(helmet)[0]
	var override := (slot.mesh as MeshInstance3D).get_surface_override_material(slot.surface) as StandardMaterial3D
	_check(override != null and override.albedo_color.is_equal_approx(Color(0.541, 0.286, 0.741)), "the stripe override is Rafi's purple (ART_BIBLE role colour)")
	_check(not Helmet.apply_role(helmet, "noor"), "an unknown role is refused (Noor never wears a suit)")
	Helmet.set_visor_closed(helmet, 1.0)
	var visor := helmet.find_children("Visor", "Node3D", true, false)[0] as Node3D
	_check(absf(visor.rotation_degrees.x - float(data.visor_closed_rotation_deg_x)) < 0.01, "the visor lowers about its hinge")
	Helmet.set_visor_closed(helmet, 0.0)
	_check(absf(visor.rotation_degrees.x) < 0.01, "and raises again")
	var xf := Helmet.equip_transform("kai")
	_check(xf.origin.y > 1.3 and xf.origin.y < 1.5 and absf(xf.basis.get_scale().x - float(data.roles.kai.scale)) < 0.001, "Kai's helmet base sits on his suit's neck ring (1.3 to 1.5 m) at his fit scale")
	helmet.free()

# ----------------------------------------------------------------------------------------------- fitted EVA suits

func _eva_path(key: String) -> String:
	return "res://assets/characters/CH_%s_EVA/CH_%s_EVA.glb" % [key.capitalize(), key.capitalize()]

func _test_eva() -> void:
	var clips_of_cast := {}
	for key in EVA_BONES:
		var packed := load(_eva_path(key)) as PackedScene
		_check(packed != null, "CH_%s_EVA.glb loads" % key.capitalize())
		if packed == null:
			continue
		var suit := packed.instantiate() as Node3D
		root.add_child(suit)
		var skeleton := suit.find_child("Skeleton3D", true, false) as Skeleton3D
		var player := suit.find_child("AnimationPlayer", true, false) as AnimationPlayer
		_check(skeleton != null and skeleton.get_bone_count() == EVA_BONES[key], "%s: %d bones" % [key, EVA_BONES[key]])
		var names := player.get_animation_list() if player != null else PackedStringArray()
		var loops := 0
		for clip in names:   # the importer turns a "_loop" name into a looping animation
			loops += int(player.get_animation(clip).loop_mode != Animation.LOOP_NONE)
		_check(names.size() == 44 and loops == 13, "%s: the cast's 44 clips, 13 looping (%d, %d)" % [key, names.size(), loops])
		var coverall := (load("res://assets/characters/CH_%s/CH_%s.glb" % [key.capitalize(), key.capitalize()]) as PackedScene).instantiate()
		var cast_names := (coverall.find_child("AnimationPlayer", true, false) as AnimationPlayer).get_animation_list()
		coverall.free()
		var same := true
		for clip in cast_names:
			same = same and names.has(clip)
		_check(same, "%s: every clip the coverall character has, by the same name (the game swaps outfits without retargeting)" % key)
		for layer in EVA_LAYERS:
			_check(suit.find_child(layer, true, false) is MeshInstance3D, "%s: has %s" % [key, layer])
		var flag := suit.find_child("PatchFlagL", true, false) as MeshInstance3D
		var aurora := suit.find_child("PatchAuroraR", true, false) as MeshInstance3D
		var chest := suit.find_child("PatchAuroraChest", true, false) as MeshInstance3D
		if flag != null and aurora != null and chest != null:
			_check(flag.get_aabb().get_center().x > 0.1, "%s: the Bangladesh flag on the LEFT sleeve (+X)" % key)
			_check(aurora.get_aabb().get_center().x < -0.1, "%s: the Aurora patch on the RIGHT sleeve (-X)" % key)
			var c := chest.get_aabb().get_center()
			_check(c.x < -0.03 and c.x > -0.14 and c.z > 0.0, "%s: the Aurora patch on the RIGHT chest, on the front (%.3f, %.3f)" % [key, c.x, c.z])
		# helmet: every head and hair vertex (ponytail tucked) inside the scaled interior, the base on the neck ring
		var helmet := Helmet.instance()
		Helmet.apply_role(helmet, key)
		var mount := Helmet.equip(helmet, suit, key)
		_check(mount != null and mount.bone_name.ends_with("Head"), "%s: helmet mounted on the Head bone" % key)
		var outside := _head_outside_helmet(suit, skeleton, key)
		_check(outside == 0, "%s: no head or hair vertex outside the helmet interior (%d outside)" % [key, outside])
		if key == "mei":
			var tuck := skeleton.find_bone("mixamorig:Ponytail1") if skeleton.find_bone("mixamorig:Ponytail1") >= 0 else skeleton.find_bone("mixamorig_Ponytail1")
			_check(tuck >= 0 and skeleton.get_bone_pose_scale(tuck).x < 0.01, "mei: her ponytail is tucked while the helmet is on")
			Helmet.untuck(suit)
			_check(tuck >= 0 and is_equal_approx(skeleton.get_bone_pose_scale(tuck).x, 1.0), "mei: and let out again when it comes off")
		suit.free()

## Head-weighted vertices of the suit's Body (rest pose) that fall outside the role's helmet interior box.
func _head_outside_helmet(suit: Node, skeleton: Skeleton3D, key: String) -> int:
	var body := suit.find_child("Body", true, false) as MeshInstance3D
	var head := -1
	for i in skeleton.get_bone_count():
		if skeleton.get_bone_name(i).ends_with("Head"):
			head = i
	if body == null or head < 0:
		return -1
	var data := Helmet.data()
	var inner: Dictionary = data.interior_clearance_m
	var to_helmet := Helmet.equip_transform(key).affine_inverse()
	var bind_bone := PackedInt32Array()
	for b in body.skin.get_bind_count():
		var bone := body.skin.get_bind_bone(b)
		bind_bone.append(bone if bone >= 0 else skeleton.find_bone(body.skin.get_bind_name(b)))
	var outside := 0
	for surface in body.mesh.get_surface_count():
		var arrays := body.mesh.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per := bones.size() / verts.size()
		for v in verts.size():
			var best := 0
			for k in per:
				if weights[v * per + k] > weights[v * per + best]:
					best = k
			if bind_bone[bones[v * per + best]] != head:
				continue
			var p := to_helmet * verts[v]
			if p.y < 0.0:
				continue  # the neck below the helmet's base ring, inside the suit collar
			if absf(p.x) > float(inner.width) / 2.0 + 0.003 or absf(p.z) > float(inner.depth) / 2.0 + 0.003 or p.y > float(inner.height) + 0.003:
				outside += 1
	return outside

func _test_descendants() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESCENDANTS_DATA))
	var purple := 0
	var green := 0
	for p in data.positions:
		if p.stem == "purple":
			purple += 1
		elif p.stem == "green":
			green += 1
	_check(data.positions.size() == 12 and purple == 7 and green == 5, "descendants.json: twelve positions, seven purple stems and five green (EX-CH04-S01)")
	_check(data.counts.purple == 7 and data.counts.green == 5 and data.counts.positions == 12, "the counts block agrees with the positions")
	_check(data.dedication_options.size() == 3 and data.dedication_options.has("The Next Small Thing"), "the three canon dedication options travel with the rack")
	_check(String(data.lineage).begins_with("Alo x Tara"), "lineage label names Alo x Tara, never a revived Alo")
	var packed := load(DESCENDANTS) as PackedScene
	_check(packed != null, "PL_Descendants.glb loads")
	if packed != null:
		var rack := packed.instantiate() as Node3D
		root.add_child(rack)
		var plants := 0
		for p in data.positions:
			var pos := rack.find_children(p.node, "Node3D", true, false)
			_check(pos.size() == 1, "position node " + p.node)
			if pos.size() == 1 and (pos[0] as Node3D).find_children("Plant_*", "MeshInstance3D", true, false).size() == 1:
				plants += 1
		_check(plants == 12, "every position carries one instanced descendant plant")
		_check(rack.find_children("Label_*", "MeshInstance3D", true, false).size() == 12, "twelve lineage label plates (live UI, no text baked)")
		_check(_material_count(rack, "Document_Dedication") == 1, "the dedication card slot exists")
		_check(_material_count(rack, "GrowLamp") == 1, "the grow lamp is an emissive slot")
		rack.free()
	var planted := load(DESCENDANTS_PLANTED) as PackedScene
	_check(planted != null, "PL_Descendants_Planted.glb loads")
	if planted != null:
		var rack := planted.instantiate() as Node3D
		root.add_child(rack)
		_check(rack.find_children("Cassette_*", "MeshInstance3D", true, false).size() == 12 and rack.find_children("Plant_*", "MeshInstance3D", true, false).is_empty(),
			"planting-day rack: twelve filled cassettes and no plants (EX-CH03-S11)")
		rack.free()

func _test_petal() -> void:
	for path in [PETAL, PETAL_MOUNTED]:
		var packed := load(path) as PackedScene
		_check(packed != null, "load " + path)
		if packed == null:
			continue
		var node := packed.instantiate() as Node3D
		root.add_child(node)
		_check(node.find_children("Petal", "MeshInstance3D", true, false).size() == 1, path.get_file() + ": one dried petal")
		_check(node.find_children("Sleeve", "MeshInstance3D", true, false).size() == 1, path.get_file() + ": the archival sleeve")
		_check(_material_count(node, "Label") == 1, path.get_file() + ": the date label is a live-UI slot")
		var transparent := false
		for mesh in node.find_children("Sleeve", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var material := mesh.get_active_material(surface) as StandardMaterial3D
				transparent = transparent or (material != null and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED)
		_check(transparent, path.get_file() + ": the sleeve is a transparent material")
		if path == PETAL_MOUNTED:
			_check(node.find_children("Clip", "MeshInstance3D", true, false).size() == 1 and node.find_children("SleeveStand", "Node3D", true, false).size() == 1, "mounted variant stands the sleeve in a board clip")
		node.free()

# ----------------------------------------------------------------------------------------------- sample annex

const SERVICE_WHITE := Color(1.0, 0.89, 0.81)

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

## The LOC-07 sample: a 4 x 4 m stretch of the service corridor deck with the floor hatch module at the origin and
## the support station beside it, over a 10 x 6 m lower annex (y = -3) with the ladder under the hatch, the
## frozen-tray bench with two 2034 trays, the chart archive and the annex drum debris.
func _annex_sample() -> Node3D:
	var scene := Node3D.new()
	var env := WorldEnvironment.new()
	var look := Environment.new()
	look.background_mode = Environment.BG_COLOR
	look.background_color = Color("#030406")
	look.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	look.ambient_light_color = Color(0.86, 0.88, 0.92)
	look.ambient_light_energy = 0.05
	look.tonemap_mode = Environment.TONE_MAPPER_AGX
	look.ssao_enabled = true
	look.ssao_radius = 0.6
	look.ssao_intensity = 1.6
	look.ssil_enabled = true
	look.ssil_radius = 3.0
	look.ssil_intensity = 1.0
	look.glow_enabled = true
	look.glow_intensity = 0.4
	look.glow_bloom = 0.02
	look.glow_hdr_threshold = 1.2
	look.fog_enabled = false
	env.environment = look
	scene.add_child(env)
	# corridor level: kit floor tiles around the 2 x 2 hatch module, kit walls on the far side, light strips
	for x in range(-2, 2):
		for z in range(-2, 2):
			if x >= -1 and x <= 0 and z >= -1 and z <= 0:
				continue
			Kit.place(scene, "EN_Kit_FloorTile", Vector3(x + 0.5, 0, z + 0.5))
			Kit.place(scene, "EN_Kit_CeilingTile", Vector3(x + 0.5, 0, z + 0.5))
	var hatch := Kit.place(scene, "EN_ZeroAnnex_FloorHatch", Vector3.ZERO)
	hatch.name = "Hatch"
	Kit.place(scene, "EN_Kit_Wall_Corner", Vector3(-2, 0, 2), -90)
	for x in range(-1, 2):
		Kit.place(scene, "EN_Kit_Wall_Straight", Vector3(x, 0, 2))
	Kit.place(scene, "EN_Kit_Wall_Corner", Vector3(2, 0, 2), 0)
	for z in range(-1, 2):
		Kit.place(scene, "EN_Kit_Wall_Straight", Vector3(-2, 0, z), -90)
	var station := Kit.place(scene, "EN_ZeroAnnex_SupportStation", Vector3(-1.3, 0, 1.5), 15)
	station.name = "Station"
	for x in [-1, 1]:
		Kit.place(scene, "EN_Kit_LightStrip", Vector3(x, 0, 1))
		scene.add_child(_downlight(Vector3(x, Kit.mount_y("EN_Kit_LightStrip") - 0.015, 1), SERVICE_WHITE, 2.0))
	# the lower annex: 10 x 6 m, its far wall on z = -3, near wall on z = +3, x from -2 to 8; the ladder under the hatch
	var annex := Node3D.new()
	annex.name = "Annex"
	annex.position.y = -ANNEX_DROP
	scene.add_child(annex)
	for x in range(-2, 8):
		for z in range(-3, 3):
			Kit.place(annex, "EN_ZeroAnnex_Floor", Vector3(x + 0.5, 0, z + 0.5))
			if x in [-1, 0] and z in [-1, 0]:
				continue  # the hatch well: the 2 x 2 m under the floor-hatch module stays open up to the corridor deck
			Kit.place(annex, "EN_ZeroAnnex_CeilingLamp" if Vector2i(x, z) in LAMP_TILES else "EN_ZeroAnnex_Ceiling", Vector3(x + 0.5, 0, z + 0.5))
	Kit.place(annex, "EN_ZeroAnnex_Wall_Corner", Vector3(-2, 0, 3), -90)
	for x in range(-1, 8):
		Kit.place(annex, "EN_ZeroAnnex_Wall", Vector3(x, 0, 3))
	Kit.place(annex, "EN_ZeroAnnex_Wall_Corner", Vector3(8, 0, 3), 0)
	for z in range(-2, 3):
		Kit.place(annex, "EN_ZeroAnnex_Wall", Vector3(-2, 0, z), -90)
		Kit.place(annex, "EN_ZeroAnnex_Wall", Vector3(8, 0, z), 90)
	Kit.place(annex, "EN_ZeroAnnex_Wall_Corner", Vector3(-2, 0, -3), 180)
	for x in range(-1, 8):
		Kit.place(annex, "EN_ZeroAnnex_Wall", Vector3(x, 0, -3), 180)
	Kit.place(annex, "EN_ZeroAnnex_Wall_Corner", Vector3(8, 0, -3), 90)
	Kit.place(annex, "EN_ZeroAnnex_Ladder", Vector3(0, 0, 0.55), 0)
	var bench := Kit.place(annex, "EN_ZeroAnnex_TrayBench", Vector3(6.0, 0, -2.0), 0)
	bench.name = "Bench"
	var tray_scene := load(TRAY) as PackedScene
	if tray_scene != null:
		for socket in bench.get_node("LOD0").find_children("Socket_Tray_*", "Node3D", true, false):
			var tray := tray_scene.instantiate() as Node3D
			tray.name = "PL_ZeroSeedlingTray_" + socket.name.right(1)
			tray.position = bench.position + (socket as Node3D).position
			tray.rotation_degrees.y = 90
			annex.add_child(tray)
	Kit.place(annex, "EN_ZeroAnnex_ChartArchive", Vector3(3.0, 0, -2.6), 0)
	var drum_scene := load(DRUM) as PackedScene
	if drum_scene != null:
		var drum := drum_scene.instantiate() as Node3D
		drum.position = Vector3(7.0, 0, 2.0)
		drum.rotation_degrees.y = 30
		annex.add_child(drum)
	return scene

# ----------------------------------------------------------------------------------------------- evidence

func _evidence() -> void:
	root.size = Vector2i(1600, 1000)
	root.always_on_top = true
	root.grab_focus()
	var caption := _caption()
	# 1: every annex piece on a neutral stage (game LOD)
	var stage := _studio()
	root.add_child(stage)
	for i in ANNEX_IDS.size():
		var node := Kit.instance(ANNEX_IDS[i], false, 0)
		var column := i % 5
		var front := i >= 5
		node.position = Vector3(7.0 - column * 3.5, 0.0, -4.0 if front else 2.2)
		if ANNEX_IDS[i] in CEILING_IDS:  # turned face up so the stage shows the side the room sees
			node.rotation_degrees = Vector3(180, 0, 0)
			node.position.y = Kit.bounds(node, 0).end.y
		stage.add_child(node)
		if ANNEX_IDS[i] == "EN_ZeroAnnex_FloorHatch":
			Kit.set_part_open(node, "Cover", 1.0)
		if ANNEX_IDS[i] == "EN_ZeroAnnex_ChartArchive":
			Kit.set_part_open(node, "SealedCover", 1.0)
		var label := Label3D.new()
		label.text = ANNEX_IDS[i].trim_prefix("EN_ZeroAnnex_")
		label.font_size = 56
		label.pixel_size = 0.007
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.outline_size = 10
		label.outline_modulate = Color(1, 1, 1, 0.9)
		label.position = node.position + Vector3(0, 0.25, -1.7)
		label.modulate = Color(0.12, 0.16, 0.27)
		stage.add_child(label)
	_set_caption(caption, "M3-3A Expedition Zero annex pieces, game LOD (annex.json, ten pieces)",
		"Floor hatch module with the displaced cover and the N.R. hatch, ladder, 2034 wall and corner, grating deck, ceiling panel and the panel with its dead fixture (both shown face up), frozen-tray bench, chart archive (sealed cover open), warm-side support station. Neutral studio light.")
	await _capture("M3-3A_annex_pieces")
	stage.free()
	# 2 to 4: the LOC-07 sample
	var scene := _annex_sample()
	root.add_child(scene)
	var camera := Camera3D.new()
	camera.fov = 70
	scene.add_child(camera)
	camera.current = true
	Kit.set_part_open(scene.get_node("Hatch"), "Cover", 1.0)
	camera.position = Vector3(-0.9, 1.55, -1.9)
	camera.look_at(Vector3(0.25, 0.05, 0.35))
	_set_caption(caption, "M3-3A EX-CH03-S06: the displaced floor cover exposes the N.R. hatch (service corridor level)",
		"The quake slid the service cover hood 1.2 m aside along the deck (left); the N.R. hatch leaf is closed, its camera port shuttered, the utility feed coupling at the corner. Kai and Amara's warm-side support station stands by the wall.")
	await _capture("M3-3A_annex_corridor")
	Kit.set_part_open(scene.get_node("Hatch"), "HatchLeaf", 1.0)
	Kit.set_part_open(scene.get_node("Hatch"), "PortShutter", 1.0)
	# from the far side of the opening, so the ladder (under the +Z rim) stands against the far wall of the well
	camera.position = Vector3(-0.15, 1.35, -1.05)
	camera.look_at(Vector3(0.0, -1.7, 0.3))
	# the annex below is unlit (dead fixtures): a hand light held over the coaming shines down the well, as the crew's
	# would, so the ladder and the frosted grating 3 m below read
	var hand_light := SpotLight3D.new()
	hand_light.position = Vector3(-0.05, -0.25, -0.2)  # lowered just inside the well, under the coaming
	hand_light.rotation_degrees = Vector3(-80, 0, 0)
	hand_light.light_color = Color(1.0, 0.95, 0.88)
	hand_light.light_energy = 4.0
	hand_light.spot_range = 6.0
	hand_light.spot_angle = 38.0
	hand_light.shadow_enabled = true
	scene.add_child(hand_light)
	_set_caption(caption, "M3-3A EX-CH03-S07: the N.R. hatch swung open, the ladder down into the cold annex",
		"The leaf hinges up 100 degrees at the corridor side; a hand light shows the fixed ladder reaching the grating 3 m below. Physics rays prove the opening is blocked when closed and clear when open.")
	await _capture("M3-3A_annex_hatch_open")
	hand_light.queue_free()
	var lamp := SpotLight3D.new()
	lamp.light_color = Color(1.0, 0.95, 0.88)
	lamp.light_energy = 6.0
	lamp.spot_range = 12.0
	lamp.spot_angle = 38.0
	lamp.shadow_enabled = true
	camera.add_child(lamp)
	camera.position = Vector3(1.2, -ANNEX_DROP + 1.55, 1.6)
	camera.look_at(Vector3(5.5, -ANNEX_DROP + 0.9, -2.2))
	_set_caption(caption, "M3-3A EX-CH03-S07: the cold annex by headlamp",
		"Frozen 2034 trays (young unflowered seedlings, curled leaves only) on the bench under a dead grow lamp, the chart archive with the growth chart, the sealed route sheet and the map pouch, annex debris. Frost, no fog, no haze; dead fixtures, headlamp-led detail.")
	await _capture("M3-3A_annex_cold")
	scene.free()
	# 5: five helmets with their role stripes, one visor lowered
	stage = _studio()
	root.add_child(stage)
	var cam := stage.find_children("*", "Camera3D", true, false)[0] as Camera3D
	cam.size = 2.2
	cam.position = Vector3(0, 0.9, -2.4)
	cam.basis = Basis.looking_at(Vector3(0, 0.15, 0.2) - cam.position, Vector3.UP)
	var ids := Helmet.role_ids()
	for i in ids.size():
		var helmet := Helmet.instance()
		Helmet.apply_role(helmet, ids[i])
		helmet.position = Vector3(0.9 - i * 0.45, 0.0, 0.0)
		# the helmet's front is +Z: at 45 degrees the camera (on -Z) sees the wearer's left side (the flag) and the back
		# of the shell, where the role stripe runs; Mei's helmet faces the camera with the gold sun visor lowered
		helmet.rotation_degrees.y = 45.0
		if ids[i] == "mei":
			helmet.rotation_degrees.y = 180.0 + 20.0
			Helmet.set_visor_closed(helmet, 1.0)
		stage.add_child(helmet)
		var label := Label3D.new()
		label.text = String(Helmet.data().roles[ids[i]].display)
		label.font_size = 48
		label.pixel_size = 0.0012
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.outline_size = 8
		label.outline_modulate = Color(1, 1, 1, 0.9)
		label.modulate = Color(0.12, 0.16, 0.27)
		label.position = helmet.position + Vector3(0, -0.05, -0.3)
		stage.add_child(label)
	_set_caption(caption, "M3-3A PR_Helmet_Roles: one helmet GLB, the stripe coloured and the shell scaled per cadet at runtime (helmet_roles.json)",
		"Kai orange, Amara cyan, Rafi purple (largest fit) and Ferreira gold seen from behind on the wearer's left: the role stripe down the back of the shell, the Bangladesh flag decal on the left side. Mei green faces the camera with the gold sun visor lowered. No text, no NASA marks.")
	await _capture("M3-3A_helmet_roles")
	stage.free()
	# 6: the descendant rack, October and planting day
	stage = _studio()
	root.add_child(stage)
	cam = stage.find_children("*", "Camera3D", true, false)[0] as Camera3D
	cam.size = 1.8  # both 1.3 m racks fill the frame, so stem colours read
	cam.position = Vector3(0, 2.6, -4.2)
	cam.basis = Basis.looking_at(Vector3(0, 1.0, 0) - cam.position, Vector3.UP)
	var grown := (load(DESCENDANTS) as PackedScene).instantiate() as Node3D
	grown.position = Vector3(0.72, 0, 0)
	stage.add_child(grown)
	var planted := (load(DESCENDANTS_PLANTED) as PackedScene).instantiate() as Node3D
	planted.position = Vector3(-0.72, 0, 0)
	stage.add_child(planted)
	_set_caption(caption, "M3-3A PL_Descendants: the October rack (left) and the 21 May planting-day rack (right)",
		"Twelve labelled positions; seven purple-stem and five green-stem descendants instanced from the installed Alo and Tara bloom models (EX-CH04-S01's authored sample, not a ratio claim). Lineage labels and the dedication card are live-UI slots; no plant has a face.")
	await _capture("M3-3A_descendants")
	# 6b: close on the October rack's shelf so the purple and green stems read (CH03->CH04 last montage frame)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 32.0
	cam.position = grown.position + Vector3(-0.15, 1.30, -0.95)
	cam.basis = Basis.looking_at(grown.position + Vector3(0.0, 1.02, 0.0) - cam.position, Vector3.UP)
	_set_caption(caption, "M3-3A PL_Descendants, close: the 21 October rack (EX-CH03-S12 montage, last frame into EX-CH04-S01)",
		"Purple-stem Alo-type and green-stem Tara-type descendants of Alo x Tara side by side, four-petal yellow crosses, lobed leaves; the stem colour is the visible inheritance. No faces, labels left for live UI.")
	await _capture("M3-3A_descendants_closeup")
	stage.free()
	# 7: the pressed petal, flat and mounted
	stage = _studio()
	root.add_child(stage)
	cam = stage.find_children("*", "Camera3D", true, false)[0] as Camera3D
	cam.size = 0.26
	cam.position = Vector3(0, 0.22, -0.26)
	cam.basis = Basis.looking_at(Vector3(0, 0.02, 0) - cam.position, Vector3.UP)
	var flat := (load(PETAL) as PackedScene).instantiate() as Node3D
	flat.position = Vector3(0.065, 0.0, 0)
	stage.add_child(flat)
	var mounted := (load(PETAL_MOUNTED) as PackedScene).instantiate() as Node3D
	mounted.position = Vector3(-0.065, 0.0, 0.02)
	stage.add_child(mounted)
	_set_caption(caption, "M3-3A PR_PressedPetal: Alo's dried petal in its archival sleeve, flat on the bench (left) and standing in the board clip (right)",
		"A real-size Brassica rapa petal (about 13 mm with its claw) on an archival card; the date label is a live-UI slot. A memory of the original Alo, never a living flower.")
	await _capture("M3-3A_pressed_petal")
	stage.free()
	await _eva_evidence(caption)
	caption.get_parent().get_parent().free()

## 8: the five fitted EVA suits in the game look (toon materials, drawn face layers), standing in Idle_loop: front,
## left side and back with the helmets locked on (visors up), a close-up of the helmets, and the bare heads.
func _eva_evidence(caption: Label) -> void:
	var stage := _studio()
	root.add_child(stage)
	var cam := stage.find_children("*", "Camera3D", true, false)[0] as Camera3D
	var suits: Array[Node3D] = []
	var helmets: Array[Node3D] = []
	var ids := Helmet.role_ids()
	for i in ids.size():
		var suit := (load(_eva_path(ids[i])) as PackedScene).instantiate() as Node3D
		suit.position = Vector3(-1.64 + i * 0.82, 0.0, 0.0)   # Kai on the left as the camera (on +Z) sees them
		stage.add_child(suit)
		ToonMaterials.apply_to_tree(suit, true, true)
		var face := FaceAtlas.new()
		face.name = "FaceAtlas"
		suit.add_child(face)
		var player := suit.find_child("AnimationPlayer", true, false) as AnimationPlayer
		player.play("Idle")
		player.seek(0.4, true)
		player.pause()
		var helmet := Helmet.instance()
		Helmet.apply_role(helmet, ids[i])
		Helmet.equip(helmet, suit, ids[i])
		suits.append(suit)
		helmets.append(helmet)
	var label := func(text: String, at: Vector3) -> Label3D:
		var l := Label3D.new()
		l.text = text
		l.font_size = 36
		l.pixel_size = 0.006
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.outline_size = 10
		l.outline_modulate = Color(1, 1, 1, 0.9)
		l.modulate = Color(0.12, 0.16, 0.27)
		l.position = at
		stage.add_child(l)
		return l
	var labels: Array = []
	for i in ids.size():
		labels.append(label.call(String(Helmet.data().roles[ids[i]].display), suits[i].position + Vector3(0, 0.08, 0.6)))
	cam.size = 2.75
	cam.position = Vector3(0, 1.15, 8.0)
	cam.basis = Basis.looking_at(Vector3(0, 1.05, 0) - cam.position, Vector3.UP)
	_set_caption(caption, "M3-3A CH_Cadet_EVA: the fitted EVA suits, front, helmets seated on the neck rings (visors up), Idle_loop",
		"Kai, Amara, Mei, Rafi, Ferreira (left to right) in the approved suit: quilted off-white, navy trim, orange accents, navy pack; role tabs; Bangladesh flag on the LEFT sleeve, Aurora patch on the RIGHT sleeve and RIGHT chest (Ferreira keeps her gear patch). Helmet scale per cadet from helmet_roles.json.")
	await _capture("M3-3A_eva_front")
	for suit in suits:   # each turned in place so its LEFT side (+X, the flag sleeve) faces the camera
		suit.rotation_degrees.y = -90.0
	_set_caption(caption, "M3-3A CH_Cadet_EVA: the suits from their LEFT side (flag side), helmets on",
		"Profile: helmet seated over the navy neck ring, life-support pack, over-boots; nothing intersects at rest.")
	await _capture("M3-3A_eva_side")
	for suit in suits:
		suit.rotation_degrees.y = 180.0
	_set_caption(caption, "M3-3A CH_Cadet_EVA: the suits from behind (turned in place, Kai still on the left), helmets on",
		"Role stripe on each helmet's back, navy life-support packs (stray marks Tripo copied from the side views painted back to the pack's navy), Mei's ponytail tucked inside her helmet.")
	await _capture("M3-3A_eva_back")
	for suit in suits:
		suit.rotation_degrees.y = 0.0
	# close-up of the five helmets from the front, a little from the side so the visor opening and the ring read
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 26.0
	cam.position = Vector3(-0.4, 1.75, 6.2)
	cam.basis = Basis.looking_at(Vector3(0, 1.45, 0) - cam.position, Vector3.UP)
	for l in labels:
		(l as Label3D).visible = false
	_set_caption(caption, "M3-3A PR_Helmet_Roles on CH_Cadet_EVA: helmet fit per cadet (visors up)",
		"Scales from fit_helmets_eva.py measured on these suits: Kai %.2f, Amara %.2f, Mei %.2f, Rafi %.2f, Ferreira %.2f; seated on the neck ring at rest, carried by the head." % [
			float(Helmet.data().roles.kai.scale), float(Helmet.data().roles.amara.scale), float(Helmet.data().roles.mei.scale),
			float(Helmet.data().roles.rafi.scale), float(Helmet.data().roles.ferreira.scale)])
	await _capture("M3-3A_eva_helmets")
	# the bare heads: faces, Amara's low coil, Mei's ponytail let out
	for i in ids.size():
		helmets[i].get_parent().queue_free()
		Helmet.untuck(suits[i])
	await process_frame
	_set_caption(caption, "M3-3A CH_Cadet_EVA: the heads without helmets",
		"Faces from the approved sheets with the drawn face layers, Amara's braids in the low coil at the nape (decision 2), Mei's ponytail, the navy neck rings.")
	await _capture("M3-3A_eva_heads")
	stage.free()

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
	label.add_theme_constant_override("line_spacing", 2)
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
	env.environment.ambient_light_energy = 0.35
	# a soft studio sky that only metals reflect (the background stays the flat grey): without it the gold visor and
	# the steel read as black mirrors
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.82, 0.84, 0.88)
	sky_material.sky_horizon_color = Color(0.70, 0.71, 0.73)
	sky_material.ground_bottom_color = Color(0.30, 0.30, 0.31)
	sky_material.ground_horizon_color = Color(0.55, 0.56, 0.58)
	sky_material.sun_angle_max = 1.0
	sky.sky_material = sky_material
	env.environment.sky = sky
	env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, 35, 0)
	key.light_energy = 1.6
	key.shadow_enabled = true
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, -120, 0)
	fill.light_energy = 0.5
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
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11.5
	camera.position = Vector3(0, 8, -12)
	camera.basis = Basis.looking_at(Vector3(0, 1.0, 0.6) - camera.position, Vector3.UP)
	stage.add_child(camera)
	camera.current = true
	return stage

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "evidence written: " + label)
