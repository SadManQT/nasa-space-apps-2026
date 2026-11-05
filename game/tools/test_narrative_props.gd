## M3-99: Alo and Tara stage variants, the narrative props and their runtime words, and the two new effects.
## Headless: game/tools/run_tests.sh narrative_props
## Evidence (needs a window): Godot --path game --script res://tools/test_narrative_props.gd -- --evidence <dir>
##   writes one studio render per asset and garden close-ups into <dir> (production/qa/evidence/M3-99_capture.sh
##   composes them into M3-99_contact.png and M3-99_garden_stages.png).
extends SceneTree

const Props = preload("res://assets/props/narrative/narrative_props.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
const GARDEN := "res://scenes/campaign/rooms/garden.tscn"
const PLANT_TRIS := 15000           # ART_BIBLE §7 plant per stage
const SMALL_PROP_TRIS := 5000       # ART_BIBLE §7 small prop
const EXPECTED_STAGES := {
	"ALO-01": {"bud": "PL_Alo_Bud", "bloom": "PL_Alo_Bloom", "pollinated": "PL_Alo_Bloom", "pod_bearing": "PL_Alo_PodsGreen",
		"mature_pods": "PL_Alo_Senescent", "mature_dry": "PL_Alo_Dry", "archived_petal": ""},
	"TARA-01": {"bud": "", "bloom": "PL_Tara_Bloom", "pollinated": "PL_Tara_Bloom", "pod_bearing": "PL_Tara_Pods",
		"mature_pods": "PL_Tara_Senescent", "mature_dry": "PL_Tara_Dry", "archived_nameplate": ""},
}
# Canon words (STORY_FULL EX-CH01-S03, EX-CH01-S04, EX-CH01-S12, EX-CH03-S12; doc 24 §4 clues 2 and 12, §5.2 D10).
const CANON_TEXT := {
	"PR_LabelHolder/alo": ["ALO", "ALO-01  |  purple stem"],
	"PR_LabelHolder/tara": ["TARA", "TARA-01  |  green stem"],
	"PR_LabelHolder/n": ["N."],
	"PR_Mug_Named/unnamed": [],
	"PR_Mug_Named/KAI": ["KAI"], "PR_Mug_Named/AMARA": ["AMARA"], "PR_Mug_Named/MEI": ["MEI"],
	"PR_Mug_Named/RAFI": ["RAFI"], "PR_Mug_Named/FERREIRA": ["FERREIRA"],
	"PR_ToolTag_Gear/default": ["ENG-07"],
	"PR_DrawerLidNote/default": ["Seed 1: outer chamber.", "Seed 2: inside, for comparison.", "Water at"],
	"PR_WorkingStockEnvelope/default": ["Working stock", "Tara × Alo"],
}
# Usable writing width of each flat surface (m), with a margin from the edges. The holder's words must stay inside
# its printed band (inner radius 13.9 mm), so they are checked against the band's chord at their height instead.
const PLATE_WIDTH := {"PR_ToolTag_Gear": 0.022, "PR_DrawerLidNote": 0.16, "PR_WorkingStockEnvelope": 0.07}
const HOLDER_BAND_INNER_M := 0.0139

var checks := 0
var failures := 0

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_check_catalogue()
	_check_plants()
	await _check_garden()
	_check_props()
	_check_effects()
	if args.has("--evidence"):
		var index := args.find("--evidence")
		var out_dir := args[index + 1] if index + 1 < args.size() else ProjectSettings.globalize_path("res://../production/qa/evidence")
		await _evidence(out_dir)
	var line := "NARRATIVE PROPS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures]
	print(line)
	quit(0 if failures == 0 else 1)

# --------------------------------------------------------------------------------------------- catalogue

func _check_catalogue() -> void:
	var catalog := Props.catalog()
	_check(catalog.plants.size() == 6 and catalog.props.size() == 5, "catalogue lists six stage variants and five props")
	for item in catalog.plants + catalog.props:
		var id := String(item.id)
		var node := AssetGeometry.load_glb(String(item.path))
		_check(node != null, id + " loads through the shared room loader")
		if node == null:
			continue
		root.add_child(node)  # global transforms are only meaningful inside the tree
		var tris := 0
		for mesh_node in node.find_children("*", "MeshInstance3D", true, false):
			var mesh := (mesh_node as MeshInstance3D).mesh
			for surface in mesh.get_surface_count():
				tris += int(mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size() / 3.0)
				var material := mesh.surface_get_material(surface)
				_check(material != null and not material.resource_name.contains("."), id + " material name has no duplicate suffix: " + (material.resource_name if material else "none"))
		var budget := PLANT_TRIS if String(item.kind) == "plant" else SMALL_PROP_TRIS
		_check(tris == int(item.triangles) and tris <= budget, "%s triangles %d match the catalogue and stay within %d" % [id, tris, budget])
		var box := AssetGeometry.bounds(node)
		_check(absf(box.position.y) <= 0.001, "%s stands on the floor (min y %.4f m)" % [id, box.position.y])
		var size: Array = item.size_m
		_check(box.size.distance_to(Vector3(size[0], size[1], size[2])) < 0.002, "%s size %s matches the catalogue %s" % [id, box.size, size])
		node.free()

# --------------------------------------------------------------------------------------------- plants

func _check_plants() -> void:
	var tops := {}
	for id in ["PL_Alo_PodsGreen", "PL_Tara_Pods"]:
		var node := AssetGeometry.load_glb(String(Props.entry(id).path))
		var arrays := (node.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var top := verts[0]
		for v in verts:
			if v.y > top.y:
				top = v
		tops[id] = top
		tops[id + "/winding"] = _winding_agreement(arrays)
		node.free()
	var alo: Vector3 = tops["PL_Alo_PodsGreen"]
	var tara: Vector3 = tops["PL_Tara_Pods"]
	_check(absf(alo.x) > 0.002 and absf(tara.x + alo.x) < 0.0005 and absf(tara.z - alo.z) < 0.001 and absf(tara.y - alo.y) < 0.001,
		"Tara's mesh is Alo's pod mesh mirrored in x, so the two plants never read as copies (%s vs %s)" % [tara, alo])
	_check(absf(float(tops["PL_Tara_Pods/winding"]) - float(tops["PL_Alo_PodsGreen/winding"])) < 0.02,
		"mirroring kept the face winding and normals consistent (%.3f vs %.3f)" % [tops["PL_Tara_Pods/winding"], tops["PL_Alo_PodsGreen/winding"]])
	var purple := {}
	for id in ["PL_Alo_PodsGreen", "PL_Alo_Senescent", "PL_Alo_Dry", "PL_Tara_Pods", "PL_Tara_Senescent", "PL_Tara_Dry"]:
		purple[id] = _purple_texels(id)
	for id in ["PL_Alo_PodsGreen", "PL_Alo_Senescent"]:
		_check(purple[id] > 2000, "%s keeps Alo's purple stem (%d purple texels)" % [id, purple[id]])
	for id in ["PL_Tara_Pods", "PL_Tara_Senescent", "PL_Tara_Dry"]:
		_check(purple[id] < 100, "%s has a green stem to the soil, no purple texels (%d)" % [id, purple[id]])
	for item in Props.catalog().plants:
		_check(int(item.texture_px) <= 2048, String(item.id) + " textures within the 2K plant budget")

## Fraction of triangles whose winding agrees with their vertex normals (convention-free: compared between meshes).
func _winding_agreement(arrays: Array) -> float:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var agree := 0
	for t in range(0, index.size(), 3):
		var a := index[t]
		var b := index[t + 1]
		var c := index[t + 2]
		var face := (verts[b] - verts[a]).cross(verts[c] - verts[a])
		if face.dot(normals[a] + normals[b] + normals[c]) > 0.0:
			agree += 1
	return float(agree) / (index.size() / 3.0)

## Saturated purple texels in a variant's base-colour map (anthocyanin stem colour).
func _purple_texels(id: String) -> int:
	var node := AssetGeometry.load_glb(String(Props.entry(id).path))
	var mesh := (node.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var material := mesh.surface_get_material(0) as BaseMaterial3D
	var image := material.albedo_texture.get_image()
	node.free()
	if image.is_compressed():
		image.decompress()
	image.resize(512, 512, Image.INTERPOLATE_NEAREST)
	var count := 0
	for y in 512:
		for x in 512:
			var c := image.get_pixel(x, y)
			if c.h > 0.70 and c.h < 0.95 and c.s > 0.25 and c.v > 0.12:
				count += 1
	return count

func _check_garden() -> void:
	for individual in EXPECTED_STAGES:
		for stage in EXPECTED_STAGES[individual]:
			var expected: String = EXPECTED_STAGES[individual][stage]
			if expected.begins_with("PL_Alo_Pods") or expected.begins_with("PL_Alo_Senescent") or expected.begins_with("PL_Alo_Dry") or expected.begins_with("PL_Tara_Pods") or expected.begins_with("PL_Tara_Senescent") or expected.begins_with("PL_Tara_Dry"):
				_check(CampaignRoom.plant_stage_model(individual, stage, "base") == expected, "%s %s uses %s" % [individual, stage, expected])
			else:
				_check(CampaignRoom.plant_stage_model(individual, stage, "base") == "base", "%s %s keeps its base model" % [individual, stage])
	var room := (load(GARDEN) as PackedScene).instantiate() as CampaignRoom
	room.load_approved_assets = false
	root.add_child(room)
	room.load_approved_assets = true
	await room.load_assets_incremental()
	var dates := [
		{"label": "8 May", "ALO-01": "pod_bearing", "TARA-01": "pod_bearing"},
		{"label": "16 May", "ALO-01": "mature_pods", "TARA-01": "pod_bearing"},
		{"label": "18 May", "ALO-01": "mature_dry", "TARA-01": "pod_bearing"},
		{"label": "26 May", "ALO-01": "archived_petal", "TARA-01": "mature_pods"},
		{"label": "28 May", "ALO-01": "archived_petal", "TARA-01": "mature_dry"},
		{"label": "27 Apr", "ALO-01": "bloom", "TARA-01": "bud"},
	]
	var layout := Contract.layout("LOC-03")
	for date in dates:
		room.apply_plant_state([{"individual_id": "ALO-01", "stage": date["ALO-01"]}, {"individual_id": "TARA-01", "stage": date["TARA-01"]}])
		for individual in ["ALO-01", "TARA-01"]:
			var expected: String = EXPECTED_STAGES[individual][date[individual]]
			var prefix := "PL_Alo_" if individual == "ALO-01" else "PL_Tara_"
			var shown := room.visual_root.get_children().filter(func(n): return String(n.name).begins_with(prefix) and (n as Node3D).visible)
			if expected.is_empty():
				_check(shown.is_empty(), "%s: %s shows no plant model at %s" % [date.label, individual, date[individual]])
			else:
				_check(shown.size() == 1 and String(shown[0].name) == expected, "%s: %s shows only %s (%s)" % [date.label, individual, expected, shown.map(func(n): return n.name)])
				if shown.size() == 1:
					var at: Array = layout.plant_positions[individual]
					_check((shown[0] as Node3D).position.distance_to(Vector3(at[0], at[1], at[2])) < 0.001, "%s: %s stands at its chamber position" % [date.label, expected])
	room.free()
	await process_frame

# --------------------------------------------------------------------------------------------- props

func _check_props() -> void:
	for id in Props.ids():
		for variant in Props.variant_ids(id):
			var key := id + "/" + variant
			_check(CANON_TEXT.has(key), key + " is a known canon variant")
			var node := Props.instance(id, variant)
			_check(node != null, key + " instances")
			if node == null:
				continue
			root.add_child(node)
			_check(Props.current_variant(node) == variant, key + " reports its variant")
			var labels := node.find_children("Ink*", "Label3D", true, false)
			var expected: Array = CANON_TEXT.get(key, [])
			var spec: Dictionary = Props.content().props[id]
			if bool(spec.get("arc", false)):
				var word := "".join(labels.map(func(l): return (l as Label3D).text))
				_check(word == "".join(expected), "%s draws the name %s letter by letter (%s)" % [key, "".join(expected), word])
				_check_arc(node, labels, key)
				for tape in node.find_children("Tape_*", "MeshInstance3D", true, false):
					_check((tape as MeshInstance3D).visible == (String(tape.name) == "Tape_" + variant), "%s shows only its own tape (%s)" % [key, tape.name])
			else:
				var texts := labels.map(func(l): return (l as Label3D).text)
				_check(texts == expected, "%s words are canon word for word (%s)" % [key, texts])
				_check_flat(node, labels, id, key)
			for label in labels:
				var l := label as Label3D
				_check(_english(l.text), key + " uses English in Latin letters only: " + l.text)
				_check(l.font != null and l.font.resource_path.begins_with("res://assets/props/narrative/fonts/"), key + " uses a bundled OFL font")
				_check(l.shaded and not l.double_sided and l.alpha_cut == Label3D.ALPHA_CUT_OPAQUE_PREPASS, key + " ink is lit, single-sided and depth-sorted")
			if spec.has("band_node"):
				var band := node.find_child(String(spec.band_node), true, false) as MeshInstance3D
				var v: Dictionary = {}
				for item in spec.variants:
					if String(item.id) == variant:
						v = item
				_check(band != null and band.material_override != null and (band.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Color(String(v.band))), key + " band colour " + String(v.get("band", "")))
			node.free()
	# Re-dressing replaces words instead of stacking them.
	var mug := Props.instance("PR_Mug_Named")
	root.add_child(mug)
	_check(mug.find_children("Ink*", "Label3D", true, false).is_empty(), "a fresh named mug starts nameless, like the four mugs of EX-CH01-S01")
	Props.apply_variant(mug, "KAI")
	Props.apply_variant(mug, "MEI")
	_check(mug.find_children("Ink*", "Label3D", true, false).size() == 3, "re-dressing a mug replaces its name")
	_check(not Props.apply_variant(mug, "NOBODY") and Props.current_variant(mug) == "MEI", "an unknown variant is refused and the mug keeps its name")
	mug.free()

func _check_flat(node: Node3D, labels: Array, id: String, key: String) -> void:
	var up := node.global_transform.basis.y.normalized()
	for label in labels:
		var l := label as Label3D
		_check(l.global_transform.basis.z.normalized().dot(up) > 0.999, key + " ink faces up out of the surface: " + l.text)
		var line := {"text": l.text, "font": "hand" if l.font.resource_path.contains("Gochi") else "print", "size_m": l.pixel_size * l.font_size}
		var width := Props.line_width_m(line)
		var room := float(PLATE_WIDTH.get(id, 0.0))
		if id == "PR_LabelHolder":
			var reach := absf(l.position.y) + float(line.size_m) * 0.4
			room = 2.0 * sqrt(maxf(HOLDER_BAND_INNER_M * HOLDER_BAND_INNER_M - reach * reach, 0.0))
		_check(width <= room, "%s line fits its surface (%.4f <= %.4f m): %s" % [key, width, room, l.text])

func _check_arc(node: Node3D, labels: Array, key: String) -> void:
	var item := Props.entry("PR_Mug_Named")
	var arc := node.find_child("NameArc", true, false) as Node3D
	var radius := float(item.arc_radius_m) + float(Props.content().lift_m)
	var tape: Dictionary = item.tapes.get(key.get_slice("/", 1), {})
	for label in labels:
		var l := label as Label3D
		var local := arc.global_transform.affine_inverse() * l.global_position
		_check(absf(Vector2(local.x, local.z).length() - radius) < 0.0002, "%s letter %s sits on the mug wall (r %.4f m)" % [key, l.text, Vector2(local.x, local.z).length()])
		var outward := Vector3(local.x, 0, local.z).normalized()
		var facing := (arc.global_transform.basis.inverse() * l.global_transform.basis.z).normalized()
		_check(facing.dot(outward) > 0.999, "%s letter %s faces out of the wall" % [key, l.text])
		if not tape.is_empty():
			_check(absf(atan2(local.x, local.z)) < float(tape.half_angle_rad), "%s letter %s stays on its tape" % [key, l.text])
	var handle: Array = item.handle_dir
	var front := arc.global_transform.basis.z.normalized()
	_check(absf(front.dot(Vector3(handle[0], handle[1], handle[2]))) < 0.01, key + " name is centred a quarter turn from the handle")

func _english(text: String) -> bool:
	for i in text.length():
		var code := text.unicode_at(i)
		if not ((code >= 32 and code < 127) or code == 0x00D7):
			return false
	return true

# --------------------------------------------------------------------------------------------- effects

func _check_effects() -> void:
	var media: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign/content/presentation_media.json"))
	var rows := {}
	for effect in media.audio.sfx:
		rows[String(effect.id)] = effect
	for spec in [["SFX_INVENTORY_LAMP_TICK", false, 0.1, 0.5, "[inventory lamp]"], ["SFX_DHAKA_ROOFTOP_MORNING", true, 11.0, 13.0, "[city morning]"]]:
		var id: String = spec[0]
		var stream := load("res://assets/audio/sfx/%s.ogg" % id) as AudioStreamOggVorbis
		_check(stream != null, id + " imports as Ogg Vorbis")
		if stream == null:
			continue
		_check(stream.loop == spec[1], "%s loop flag is %s" % [id, spec[1]])
		_check(stream.get_length() > spec[2] and stream.get_length() < spec[3], "%s length %.2f s" % [id, stream.get_length()])
		var row: Dictionary = rows.get(id, {})
		_check(bool(row.get("media_present", false)) and String(row.get("caption", "")) == spec[4] and bool(row.get("loop", not spec[1])) == spec[1],
			id + " is in presentation_media.json with its caption " + String(spec[4]))

# --------------------------------------------------------------------------------------------- evidence

func _evidence(out_dir: String) -> void:
	root.always_on_top = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	var studio := _studio()
	root.add_child(studio)
	for item in Props.catalog().plants:
		var node := AssetGeometry.load_glb(String(item.path))
		await _shoot(studio, [node], out_dir.path_join("cell_%s.png" % item.id), 22.0, -28.0, 1.15)
	var holders: Array = []
	for variant in ["alo", "tara", "n"]:
		var h := Props.instance("PR_LabelHolder", variant)
		h.position.x = (holders.size() - 1) * 0.046
		holders.append(h)
	await _shoot(studio, holders, out_dir.path_join("cell_PR_LabelHolder.png"), 62.0, 0.0, 1.12)
	var mugs: Array = []
	var front := Vector3(Props.entry("PR_Mug_Named").tape_dir[0], 0, Props.entry("PR_Mug_Named").tape_dir[2])
	for name in ["KAI", "AMARA", "MEI", "RAFI", "FERREIRA"]:
		var m := Props.instance("PR_Mug_Named", name)
		m.rotation.y = atan2(front.x, front.z) * -1.0  # turn each name to face +Z (the camera side)
		m.position.x = (mugs.size() - 2) * 0.115
		mugs.append(m)
	await _shoot(studio, mugs, out_dir.path_join("cell_PR_Mug_Named.png"), 8.0, 0.0, 1.06, Vector2i(1200, 500))
	var close := Props.instance("PR_Mug_Named", "FERREIRA")
	close.rotation.y = -atan2(front.x, front.z)
	await _shoot(studio, [close], out_dir.path_join("cell_PR_Mug_Named_FERREIRA.png"), 10.0, 0.0, 1.05)
	await _shoot(studio, [Props.instance("PR_ToolTag_Gear")], out_dir.path_join("cell_PR_ToolTag_Gear.png"), 60.0, -15.0, 1.25)
	await _shoot(studio, [Props.instance("PR_DrawerLidNote")], out_dir.path_join("cell_PR_DrawerLidNote.png"), 72.0, 0.0, 1.08)
	await _shoot(studio, [Props.instance("PR_WorkingStockEnvelope")], out_dir.path_join("cell_PR_WorkingStockEnvelope.png"), 62.0, -10.0, 1.12)
	studio.free()
	await _garden_shots(out_dir)

## A neutral grey sweep, a soft key and fill, and a camera (the approval sheets' studio, in Godot's renderer).
func _studio() -> SubViewport:
	var view := SubViewport.new()
	view.size = Vector2i(800, 800)
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#d9d9da")
	# a neutral grey sky lights and reflects (metals need something to mirror), behind a plain grey backdrop
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#8f9297")
	sky_material.sky_horizon_color = Color("#b9babd")
	sky_material.ground_horizon_color = Color("#a5a6a8")
	sky_material.ground_bottom_color = Color("#5d5e61")
	sky_material.sun_angle_max = 0.0
	env.environment.sky = Sky.new()
	env.environment.sky.sky_material = sky_material
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.environment.ambient_light_energy = 0.3
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	view.add_child(env)
	for spec in [[Vector3(-48, -38, 0), 0.8, true], [Vector3(-65, 130, 0), 0.25, false]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = spec[0]
		light.light_energy = spec[1]
		light.shadow_enabled = spec[2]
		light.directional_shadow_max_distance = 3.0
		view.add_child(light)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#a3a3a4")
	floor_material.roughness = 0.85
	floor.material_override = floor_material
	view.add_child(floor)
	var camera := Camera3D.new()
	camera.name = "Camera"
	view.add_child(camera)
	return view

func _shoot(view: SubViewport, nodes: Array, path: String, elevation: float, azimuth: float, margin: float, size: Vector2i = Vector2i(800, 800)) -> void:
	view.size = size
	var holder := Node3D.new()
	view.add_child(holder)
	for node in nodes:
		holder.add_child(node)
	var box := AABB()
	var first := true
	for mesh in holder.find_children("*", "MeshInstance3D", true, false):
		if not (mesh as MeshInstance3D).is_visible_in_tree():
			continue
		var b := (mesh as MeshInstance3D).global_transform * (mesh as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	var camera := view.get_node("Camera") as Camera3D
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	var centre := box.get_center()
	var extent := maxf(box.size.x, maxf(box.size.y, box.size.z))
	var e := deg_to_rad(elevation)
	var a := deg_to_rad(azimuth)
	camera.position = centre + Vector3(sin(a) * cos(e), sin(e), cos(a) * cos(e)) * extent * 6.0
	camera.look_at(centre, Vector3.UP)
	camera.near = 0.001
	camera.far = extent * 20.0
	var across := maxf(box.size.x, box.size.z)
	var projected_height := box.size.y * cos(e) + across * sin(e)
	camera.size = maxf(projected_height, across / (float(size.x) / float(size.y))) * margin
	await _save_view(view, path)
	holder.free()

func _save_view(view: SubViewport, path: String) -> void:
	for attempt in 6:
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := view.get_texture().get_image()
		if image != null and not _blank(image):
			_check(image.save_png(path) == OK, "evidence written: " + path.get_file())
			return
	_check(false, "evidence frame stayed blank: " + path.get_file())

func _blank(image: Image) -> bool:
	var c := image.get_pixel(image.get_width() >> 1, image.get_height() >> 1)
	var d := image.get_pixel(int(image.get_width() / 3.0), int(image.get_height() / 3.0))
	return c.v < 0.02 and d.v < 0.02

## The garden at its dated stages, in the room's own light, from fixed close views of each plant.
func _garden_shots(out_dir: String) -> void:
	root.size = Vector2i(1280, 720)
	var room := (load(GARDEN) as PackedScene).instantiate() as CampaignRoom
	room.load_approved_assets = false
	root.add_child(room)
	room.load_approved_assets = true
	await room.load_assets_incremental()
	room.set_door_open("garden_viewing_shutter", true)
	var camera := Camera3D.new()
	camera.fov = 45
	root.add_child(camera)
	camera.current = true
	var views := {"ALO-01": [Vector3(2.0, 1.2, 2.45), Vector3(2.15, 0.97, 3.15)], "TARA-01": [Vector3(-2.75, 1.2, -0.95), Vector3(-3.2, 0.97, -1.5)]}
	var stages := {"ALO-01": ["pod_bearing", "mature_pods", "mature_dry"], "TARA-01": ["pod_bearing", "mature_pods", "mature_dry"]}
	for individual in views:
		for stage in stages[individual]:
			room.apply_plant_state([{"individual_id": individual, "stage": stage}])
			camera.position = views[individual][0]
			camera.look_at(views[individual][1])
			for attempt in 6:
				for frame in 12:
					await process_frame
				await RenderingServer.frame_post_draw
				var image := root.get_texture().get_image()
				if not _blank(image):
					var path := out_dir.path_join("garden_%s_%s.png" % [individual, stage])
					_check(image.save_png(path) == OK, "evidence written: " + path.get_file())
					break
	room.free()
	camera.free()
