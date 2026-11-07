## M3-6R: builds a room's chapter staging (RoomContract.staging for the staged scene) on top of the base Chapter 1
## assembly: dated furniture and fixtures, the M3-6A eclipse props and the M3-7A Chapter 7 props in the scene's state
## (M3-7R), prints, signs and screens, a prop's own parts and live surfaces in the scene's pose (M3-5R: the 2034 records,
## the document sleeve, the impact monitor), per-scene practical-light levels, collision for every floor-standing addition and the staged focus stations.
## clear() puts the base room back exactly. Presentation only: puzzles, missions and the director own every rule.
## M3-3R adds live kit pieces (the M3-3A annex pieces): kit_prop() places one with its collision, moving-part poses,
## live words on its Label*, Document* and Screen* slots and objects seated in its sockets; a stage's "kit_parts",
## "kit_texts" and "kit_attach" change those per scene and clear() restores the base room's.
extends RefCounted

const Presentation = preload("res://scripts/world/room_presentation.gd")
const Habitat = preload("res://scripts/world/habitat_room_builder.gd")
const Geometry = preload("res://scripts/asset_geometry.gd")
const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const EclipseProps = preload("res://assets/props/eclipse_power/eclipse_props.gd")
const C7 = preload("res://assets/props/chapter7_assets.gd")
const NarrativeProps = preload("res://assets/props/narrative/narrative_props.gd")
const C8 = preload("res://assets/environment/EN_MalapertSummit/chapter8_assets.gd")
const EarthSky = preload("res://assets/environment/terrain/earth_sky.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
const ROVER_LIGHTS := "res://assets/vehicles/VH_Rover/rover_lights.json"
## Pixel size of each M3-7A live screen (its Screen_* slot's aspect, as the M3-7A evidence renders them).
const C7_SCREEN_PX := {"Screen_Roster": [1040, 100], "Screen_Return": [760, 150], "Screen_Systems": [640, 400],
	"Screen_Garden": [640, 400], "Screen_Diag": [680, 360], "Screen_Case": [360, 140], "Screen_Archive": [400, 160],
	"Screen_Echo": [480, 200], "Screen_Checklist": [420, 560], "Screen_Route": [900, 520]}
const CATALOG_PATH := "res://resources/campaign/dialogue_catalog.json"
const ROOT_NAME := "ChapterStaging"
## A routine white-light solar image printed in greyscale on paper: limb darkening I(mu) = 1 - u (1 - mu) with
## u = 0.6, and one active region (a sunspot group, dark umbrae in grey penumbrae) in the northern activity belt.
## Procedural, so nothing is generated or copied; the caption says what it is and what it is not.
const SOLAR_PRINT_SHADER := """
shader_type spatial;
uniform vec3 paper = vec3(0.90, 0.90, 0.88);
uniform float margin = 0.07;
float spot(vec2 p, vec2 c, float umbra, float penumbra) {
	float d = length((p - c) * vec2(1.0, 1.25));
	float pen = 1.0 - smoothstep(penumbra * 0.8, penumbra, d);
	float umb = 1.0 - smoothstep(umbra * 0.75, umbra, d);
	return max(0.38 * pen, 0.82 * umb);
}
void fragment() {
	vec3 col = paper;
	vec2 inner = (UV - vec2(margin)) / (1.0 - 2.0 * margin);
	if (all(greaterThanEqual(inner, vec2(0.0))) && all(lessThanEqual(inner, vec2(1.0)))) {
		col = vec3(0.035);
		vec2 p = inner * 2.0 - 1.0;
		float r = length(p) / 0.88;
		if (r < 1.0) {
			float mu = sqrt(1.0 - r * r);
			float shade = 1.0 - 0.6 * (1.0 - mu);
			float dark = 0.0;
			dark = max(dark, spot(p, vec2(-0.30, -0.27), 0.045, 0.105));
			dark = max(dark, spot(p, vec2(-0.17, -0.30), 0.032, 0.080));
			dark = max(dark, spot(p, vec2(-0.07, -0.25), 0.016, 0.045));
			dark = max(dark, spot(p, vec2(-0.41, -0.31), 0.014, 0.040));
			col = vec3(0.93 * shade * (1.0 - dark));
		}
	}
	ALBEDO = col;
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
}
"""
## M3-2R: a labelled side-view diagram of one flower of the Chapter 2 mustard (Brassica rapa): four petals (two seen
## edge-on), four long and two short stamens with pollen-bearing anthers, and the central pistil with its stigma.
## Shapes carry the meaning as well as colour (dotted anthers, ridged stigma, outlined parts), and the labels are
## words beside them. "contact" = 1 draws pollen grains on the stigma: the saved contact image after a transfer.
const FLOWER_DIAGRAM_SHADER := """
shader_type spatial;
uniform float aspect = 1.4;
uniform float contact = 0.0;
uniform float glow = 0.0;
float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}
float ell(vec2 p, vec2 c, vec2 r, float angle) {
	vec2 q = p - c;
	float s = sin(angle), k = cos(angle);
	q = vec2(k * q.x + s * q.y, -s * q.x + k * q.y);
	return (length(q / r) - 1.0) * min(r.x, r.y);
}
void paint(inout vec3 col, float d, vec3 fill, vec3 edge) {
	col = mix(col, fill, step(d, 0.0));
	col = mix(col, edge, step(abs(d), 0.007));
}
void fragment() {
	vec2 p = vec2((UV.x * 2.0 - 1.0) * aspect, 1.0 - UV.y * 2.0);
	vec3 col = vec3(0.95, 0.95, 0.92);
	vec3 ink = vec3(0.12, 0.14, 0.18);
	vec3 green = vec3(0.33, 0.55, 0.25);
	vec3 petal = vec3(0.95, 0.78, 0.20);
	vec3 anther = vec3(0.86, 0.62, 0.12);
	// pedicel, receptacle and sepals
	paint(col, seg(p, vec2(0.0, -1.05), vec2(0.0, -0.56)) - 0.035, green, ink);
	paint(col, ell(p, vec2(-0.14, -0.40), vec2(0.04, 0.15), 0.45), green, ink);
	paint(col, ell(p, vec2(0.14, -0.40), vec2(0.04, 0.15), -0.45), green, ink);
	// two petals in profile, spread outwards from their claws
	paint(col, ell(p, vec2(-0.47, -0.20), vec2(0.34, 0.11), -0.35), petal, ink);
	paint(col, ell(p, vec2(0.47, -0.20), vec2(0.34, 0.11), 0.35), petal, ink);
	paint(col, ell(p, vec2(0.0, -0.50), vec2(0.14, 0.07), 0.0), green, ink);
	// six stamens: four long inside, two short outside; anthers dotted with pollen
	vec2 tips[6] = vec2[6](vec2(-0.16, 0.40), vec2(-0.06, 0.44), vec2(0.06, 0.44), vec2(0.16, 0.40), vec2(-0.30, 0.14), vec2(0.30, 0.14));
	for (int i = 0; i < 6; i++) {
		vec2 root = vec2(tips[i].x * 0.3, -0.44);
		paint(col, seg(p, root, tips[i]) - 0.012, vec3(0.80, 0.84, 0.62), ink);
		float a = ell(p, tips[i] + vec2(0.0, 0.06), vec2(0.035, 0.075), 0.0);
		paint(col, a, anther, ink);
		vec2 g = fract((p - tips[i]) * 42.0) - 0.5;
		if (a < -0.006 && length(g) < 0.22) { col = vec3(0.55, 0.38, 0.06); }
	}
	// pistil: ovary, style and the ridged stigma on top
	paint(col, ell(p, vec2(0.0, -0.22), vec2(0.065, 0.22), 0.0), green, ink);
	paint(col, seg(p, vec2(0.0, -0.05), vec2(0.0, 0.46)) - 0.03, green, ink);
	float st = ell(p, vec2(0.0, 0.53), vec2(0.085, 0.05), 0.0);
	paint(col, st, vec3(0.80, 0.86, 0.52), ink);
	if (st < -0.004 && abs(fract((p.x + 0.085) * 36.0) - 0.5) < 0.12) { col = mix(col, ink, 0.45); }
	// pollen grains carried to the stigma (the contact image)
	if (contact > 0.5) {
		vec2 grains[7] = vec2[7](vec2(-0.05, 0.57), vec2(0.0, 0.59), vec2(0.045, 0.565), vec2(-0.025, 0.55), vec2(0.03, 0.535), vec2(0.065, 0.55), vec2(-0.065, 0.545));
		for (int i = 0; i < 7; i++) { paint(col, length(p - grains[i]) - 0.016, vec3(0.96, 0.70, 0.10), ink); }
	}
	// leader lines from the labels to the anther and the stigma
	paint(col, seg(p, vec2(0.66, 0.66), vec2(0.20, 0.47)) - 0.004, ink, ink);
	paint(col, seg(p, vec2(-0.66, 0.66), vec2(-0.09, 0.55)) - 0.004, ink, ink);
	ALBEDO = col;
	EMISSION = col * glow;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
}
"""
static var _lines: Dictionary = {}
static var _solar_shader: Shader
static var _flower_shader: Shader

## Builds stage into room (base nodes named in "hide" are hidden, everything else is added under ChapterStaging
## roots) and returns the visual root of the additions.
static func build(room: CampaignRoom, stage: Dictionary, layout: Dictionary) -> Node3D:
	var visuals := _root(room.visual_root)
	var colliders := _root(room.collision_root)
	var habitat: bool = layout.get("assembly") in ["habitat_kit", "site_kit"]  # PBR fixtures (site_kit: M3-106 exteriors)
	for node in room.visual_root.get_children():
		if node is Node3D and node.visible and (String(node.name) in stage.hide or (node is Label3D and String(node.text) in stage.hide_signs)):
			node.hide()
			node.set_meta("staging_hidden", true)
			# A hidden M3-8A piece carries its collision inside it (M3-8R): it goes with the piece.
			for shape in node.find_children("*", "CollisionShape3D", true, false):
				if not (shape as CollisionShape3D).disabled:
					(shape as CollisionShape3D).disabled = true
					shape.set_meta("staging_disabled", true)
	for body in room.collision_root.get_children():
		if String(body.name) in stage.hide:
			for shape in body.find_children("*", "CollisionShape3D", true, false):
				(shape as CollisionShape3D).disabled = true
			body.set_meta("staging_disabled", true)
	for spec in stage.fixtures:
		Presentation.fixture(visuals, spec, habitat)
	for spec in stage.props:
		# A packed scene (VH_Rover_Lit with its light sockets, M3-8R) or a GLB.
		var model: Node3D = (load(String(spec.path)) as PackedScene).instantiate() as Node3D if String(spec.path).ends_with(".tscn") else Geometry.load_glb(String(spec.path))
		if model == null:
			continue
		model.name = String(spec.id)
		model.position = Presentation.vector(spec.position)
		model.rotation_degrees = Presentation.vector(spec.get("rotation_degrees", [0, 0, 0]))
		model.scale = Presentation.vector(spec.get("scale", [1, 1, 1]))
		if spec.has("variant"):
			# An M3-99 narrative prop (e.g. PR_Mug_Named "KAI"): its tape and words are drawn at runtime.
			model.set_meta("narrative_prop", String(spec.path).get_file().get_basename())
			NarrativeProps.apply_variant(model, String(spec.variant))
		# M3-4R: words on a prop's plate ("inks", see ink(); "part" rides on a moving part); its moving parts are posed by
		# name in _pose_parts ("parts", both forms)
		for item in spec.get("inks", []):
			ink(model, item)
		visuals.add_child(model)
		if spec.has("parts") or spec.has("surfaces"):
			_pose_parts(model, spec)
		if spec.get("rattle") is Dictionary:
			_rattle(model, spec.rattle)
	for spec in stage.models:
		_teaching_model(visuals, spec)
	for spec in stage.eclipse_props:
		_eclipse_prop(visuals, spec)
	for spec in stage.chapter7_props:
		_chapter7_prop(visuals, spec)
	for spec in stage.prints:
		_print(visuals, spec)
	for spec in stage.kit_screens:
		_kit_screen(room, visuals, spec)
	var bay := room.garage()
	if bay != null and not stage.garage.is_empty():
		_pose_garage(bay, stage.garage)
	for spec in stage.signs:
		var shown: Dictionary = spec.duplicate()
		if spec.has("line"):
			shown.text = String(spec.text).replace("{line}", line_text(String(spec.line)))
		var label := Presentation.wall_sign(visuals, shown, layout)
		label.name = String(spec.get("id", "Sign"))
		label.outline_size = int(spec.get("outline", 12))
	for spec in stage.obstacles:
		Habitat.collider(colliders, String(spec.id), Presentation.vector(spec.position), Presentation.vector(spec.size))
	for id in stage.get("piece_states", {}):
		var piece := room.visual_root.get_node_or_null(String(id)) as Node3D
		_piece_state(piece if piece != null else visuals.get_node_or_null(String(id)) as Node3D, stage.piece_states[id])
	var lighting := room.get_node_or_null("RoomLighting") as Node3D
	if lighting != null:
		var lamps := _root(lighting)
		for spec in stage.local_lights:
			var lamp := OmniLight3D.new()
			lamp.name = String(spec.id)
			lamp.position = Presentation.vector(spec.position)
			lamp.light_color = Color(spec.color)
			lamp.light_energy = float(spec.energy)
			lamp.omni_range = float(spec.range_m)
			# a work lamp on a deck under another deck casts shadows, so it never lights the room above (M3-3R)
			lamp.shadow_enabled = bool(spec.get("shadow", false))
			lamps.add_child(lamp)
	for node_id in stage.get("kit_parts", {}):
		var piece := room.visual_root.get_node_or_null(String(node_id)) as Node3D
		if piece != null:
			for part in stage.kit_parts[node_id]:
				Kit.set_part_open(piece, String(part), float(stage.kit_parts[node_id][part]))
	for node_id in stage.get("kit_texts", {}):
		var piece := room.visual_root.get_node_or_null(String(node_id)) as Node3D
		if piece != null:
			for slot in stage.kit_texts[node_id]:
				slot_text(piece, String(slot), stage.kit_texts[node_id][slot])
	for node_id in stage.get("kit_attach", {}):
		var piece := room.visual_root.get_node_or_null(String(node_id)) as Node3D
		if piece != null:
			for item in stage.kit_attach[node_id]:
				var model := attach(piece, item)
				if model != null:
					model.set_meta("staging_attached", true)
	set_light_level(room, stage.lighting)
	for target in stage.focus_targets:
		room.add_staged_focus_target(target)
	for target_id in stage.focus_labels:
		var focus := room.focus_root.get_node_or_null("Focus_" + String(target_id)) as Node3D
		if focus != null:
			if not focus.has_meta("base_label"):
				focus.set_meta("base_label", focus.get_meta("focus_label"))
			focus.set_meta("focus_label", String(stage.focus_labels[target_id]))
			if focus.get_child_count() > 0 and focus.get_child(0) is Label3D:
				(focus.get_child(0) as Label3D).text = String(stage.focus_labels[target_id])
	return visuals

## Removes every staged addition and restores what staging hid, relabelled or dimmed.
static func clear(room: CampaignRoom) -> void:
	for parent in [room.visual_root, room.collision_root, room.get_node_or_null("RoomLighting")]:
		if parent == null:
			continue
		var old: Node = (parent as Node).get_node_or_null(ROOT_NAME)
		if old != null:
			parent.remove_child(old)
			old.queue_free()
	for node in room.visual_root.get_children():
		if node.has_meta("staging_hidden"):
			node.show()
			node.remove_meta("staging_hidden")
			for shape in node.find_children("*", "CollisionShape3D", true, false):
				if shape.has_meta("staging_disabled"):
					(shape as CollisionShape3D).disabled = false
					shape.remove_meta("staging_disabled")
	for body in room.collision_root.get_children():
		if body.has_meta("staging_disabled"):
			for shape in body.find_children("*", "CollisionShape3D", true, false):
				(shape as CollisionShape3D).disabled = false
			body.remove_meta("staging_disabled")
	for focus in room.focus_root.get_children():
		if focus.has_meta("base_label"):
			focus.set_meta("focus_label", focus.get_meta("base_label"))
			if focus.get_child_count() > 0 and focus.get_child(0) is Label3D:
				(focus.get_child(0) as Label3D).text = String(focus.get_meta("base_label"))
			focus.remove_meta("base_label")
	room.remove_staged_focus_targets()
	# kit pieces return to the base room's poses and words; seated staging objects leave their sockets
	var stage: Dictionary = room.stage()
	for map_key in ["kit_parts", "kit_texts", "kit_attach"]:
		for node_id in stage.get(map_key, {}):
			var piece := room.visual_root.get_node_or_null(String(node_id)) as Node3D
			if piece == null:
				continue
			var base: Dictionary = room.kit_prop(String(node_id))
			match map_key:
				"kit_parts":
					for part in stage.kit_parts[node_id]:
						Kit.set_part_open(piece, String(part), float(base.get("parts", {}).get(part, 0.0)))
				"kit_texts":
					for slot in stage.kit_texts[node_id]:
						if base.get("texts", {}).has(slot):
							slot_text(piece, String(slot), base.texts[slot])
						else:
							clear_slot(piece, String(slot))
				"kit_attach":
					for child in piece.get_children():
						if child.has_meta("staging_attached"):
							piece.remove_child(child)
							child.queue_free()
	for node in room.visual_root.get_children():
		if node.has_meta("piece_state"):
			_restore_piece(node)
	set_light_level(room, {})
	for slot in room.get_meta("staged_screen_slots", []):
		if is_instance_valid(slot.mesh):
			(slot.mesh as MeshInstance3D).set_surface_override_material(int(slot.surface), null)
	room.set_meta("staged_screen_slots", [])
	var bay := room.garage()
	if bay != null:
		_pose_garage(bay, {})

## Scales the room's practical lights and ceiling-strip diffusers and sets the ambient level for the staged scene
## (e.g. the eclipse's protected plan: "practical_scale" 0.3). An empty settings dictionary restores the base rig.
static func set_light_level(room: CampaignRoom, settings: Dictionary) -> void:
	var lighting := room.get_node_or_null("RoomLighting")
	if lighting == null:
		return
	var practical := float(settings.get("practical_scale", 1.0))
	for light in lighting.get_children():
		if light is OmniLight3D and String(light.name).begins_with("Practical_"):
			if not light.has_meta("base_energy"):
				light.set_meta("base_energy", light.light_energy)
			light.light_energy = float(light.get_meta("base_energy")) * practical
	var strip := float(settings.get("strip_scale", practical))
	for mesh in room.visual_root.get_children():
		if mesh is MeshInstance3D and String(mesh.name).begins_with("CeilingStrip") and mesh.material_override is StandardMaterial3D:
			var material := mesh.material_override as StandardMaterial3D
			if not mesh.has_meta("base_color"):
				mesh.set_meta("base_color", material.albedo_color)
			var base: Color = mesh.get_meta("base_color")
			material.albedo_color = Color(base.r * strip, base.g * strip, base.b * strip, base.a)
	# An exterior's Sun (M3-8R): "key_energy" 0 is a scene the dated row leaves dark (the relay road at night).
	var key := lighting.get_node_or_null("KeyLight") as DirectionalLight3D
	if key != null:
		if not key.has_meta("base_energy"):
			key.set_meta("base_energy", key.light_energy)
		key.light_energy = float(settings.get("key_energy", key.get_meta("base_energy")))
	var world := lighting.get_node_or_null("RoomEnvironment") as WorldEnvironment
	if world != null and world.environment != null:
		if not world.has_meta("base_ambient"):
			world.set_meta("base_ambient", world.environment.ambient_light_energy)
		world.environment.ambient_light_energy = float(settings.get("ambient_energy", world.get_meta("base_ambient")))

## The canon text of a catalog line, word for word (e.g. Noor's text EX-CH06-S09-L01), or "" when unknown.
static func line_text(line_id: String) -> String:
	if _lines.is_empty():
		var catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
		if catalog is Dictionary:
			for line in catalog.get("lines", []):
				_lines[String(line.get("id", ""))] = String(line.get("text", ""))
	return String(_lines.get(line_id, ""))

static func _root(parent: Node) -> Node3D:
	var existing := parent.get_node_or_null(ROOT_NAME) as Node3D
	if existing != null:
		return existing
	var node := Node3D.new()
	node.name = ROOT_NAME
	parent.add_child(node)
	return node

## M3-105: live words on a named slot of a placed kit piece (a garage screen, a slope sign's face, a tag): "node" is the
## piece under VisualRoot (a room role, e.g. "route_board", or a staged piece), "slot" the material ("Screen",
## "Screen2", "Label"...), "text" (with "{line}" filled from "line"), "fg" and "bg". Unlike kit_texts (slot_text, M3-3R),
## which paints a SubViewport through the slot's UVs, the words are a Label3D laid on the slot's own plane
## (Kit.surface_frame), fitted to it and read the right way round whatever the UVs, so the M3-4A garage and cold-trap
## pieces need no per-slot flips; the slot glows dark behind them like a lit display.
static func _kit_screen(room: CampaignRoom, parent: Node3D, spec: Dictionary) -> Label3D:
	var piece := room.visual_root.get_node_or_null(String(spec.node)) as Node3D
	if piece == null:
		piece = parent.get_node_or_null(String(spec.node)) as Node3D
	if piece == null:
		return null
	var frame := Kit.surface_frame(piece, String(spec.slot))
	if frame.is_empty():
		return null
	var text := String(spec.get("text", ""))
	if spec.has("line"):
		text = text.replace("{line}", line_text(String(spec.line)))
	var label := Label3D.new()
	label.name = String(spec.id)
	label.text = text
	label.font_size = 48
	label.outline_size = 0
	label.double_sided = false
	label.modulate = Color(spec.get("fg", "#d9f2ff"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if bool(spec.get("centred", true)) else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var size: Vector2 = frame.size
	var lines := text.split("\n")
	var longest := 1
	for one in lines:
		longest = maxi(longest, one.length())
	label.pixel_size = minf(size.x * 0.9 / (longest * 0.6 * 48.0), size.y * 0.86 / (lines.size() * 1.3 * 48.0))
	label.width = size.x * 0.94 / label.pixel_size
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var normal: Vector3 = frame.normal
	# the piece stands directly under VisualRoot or under ChapterStaging, which sits at VisualRoot's origin
	label.transform = piece.transform * Transform3D(Basis(frame.right, frame.up, normal), frame.centre + normal * 0.004)
	parent.add_child(label)
	var glow := StandardMaterial3D.new()
	glow.resource_name = "Screen_live"
	glow.albedo_color = Color(spec.get("bg", "#0b1220"))
	glow.emission_enabled = true
	glow.emission = Color(spec.get("bg", "#0b1220"))
	glow.emission_energy_multiplier = 0.6
	glow.roughness = 0.85
	glow.metallic_specular = 0.15
	var slots: Array = room.get_meta("staged_screen_slots", [])
	for found in slot_surfaces(piece, String(spec.slot)):
		(found.mesh as MeshInstance3D).set_surface_override_material(int(found.surface), glow)
		slots.append(found)
	room.set_meta("staged_screen_slots", slots)
	return label

## M3-105: the garage's scene pose ("garage" staging map): "lock_door" ("InnerDoor", "OuterDoor" or "" for both
## shut), "relief_locker_open", "rover_door_open" and "dock" (the tunnel at the scene's start: "habitat" for SAFE TO
## OPEN, "vacuum" for SEALED). {} puts the garage back to its rest: both lock doors and the locker shut, the rover door
## down, the docked tunnel at cabin pressure with the hatch shut. Presentation only: the scene's mission drives the
## dock cycle and the doors from there.
static func _pose_garage(bay: Node3D, pose: Dictionary) -> void:
	for which in ["InnerDoor", "OuterDoor"]:
		bay.set_lock_door(which, false)
	var lock := String(pose.get("lock_door", ""))
	if not lock.is_empty():
		bay.set_lock_door(lock, true)
	bay.set_relief_locker_open(bool(pose.get("relief_locker_open", false)))
	bay.set_rover_door_open(bool(pose.get("rover_door_open", false)))
	bay.dock_restore({"docked": true, "tunnel_side": String(pose.get("dock", "habitat")), "hatch_open": false})

## Places one M3-6A prop with the scene's pose: board cards/plan, text screens, state preset, part visibility and
## the monitor's live picture (phase, mode, filter, logged observations; "track" eases the phase over seconds).
static func _eclipse_prop(parent: Node3D, spec: Dictionary) -> Node3D:
	var node := EclipseProps.place(parent, String(spec.prop), Presentation.vector(spec.position), float(spec.get("yaw", 0)), String(spec.get("variant", "")))
	if node == null:
		return null
	node.name = String(spec.id)
	var board := String(spec.get("board", ""))
	if board == "cards":
		EclipseProps.populate_board(node, "")
	elif not board.is_empty():
		EclipseProps.populate_board(node, board)
	for screen_id in spec.get("screens", {}):
		var screen: Dictionary = spec.screens[screen_id]
		var label := EclipseProps.attach_text_screen(node, String(screen_id), String(screen.get("text", "")), int(screen.get("height", 160)))
		if label != null and screen.has("color"):
			label.add_theme_color_override("font_color", Color(screen.color))
			EclipseProps.refresh_text_screen(label)
	if spec.has("state"):
		EclipseProps.apply_state(node, String(spec.state))
	for part in spec.get("parts_visible", {}):
		EclipseProps.set_part_visible(node, String(part), bool(spec.parts_visible[part]))
	if spec.get("monitor") is Dictionary:
		var settings: Dictionary = spec.monitor
		var screen = EclipseProps.attach_monitor_screen(node)
		_pose_monitor(screen, settings)
		node.set_meta("monitor_screen", screen)
		var track: Array = settings.get("track", [])
		if track.size() == 3 and node.is_inside_tree():
			# Presentation only. A P-12 driver that takes over set_phase kills meta "monitor_track" first.
			var tween := node.create_tween()
			tween.tween_method(screen.set_phase, float(track[0]), float(track[1]), float(track[2])).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			node.set_meta("monitor_track", tween)
	return node

## Places one M3-7A Chapter 7 asset (chapter7_assets.gd) in the scene's pose: seat "markers" (role -> slot, each with
## its name beside it), "case" lid and latch, "water_units" and the return "selector", "lamps", "isolated", "card_out",
## repeater "pins", objects seated in its sockets ("attach") and its live "screens" (plain words on the Screen_* slot;
## "line" quotes a catalog line). Presentation only: the P-13/P-14 puzzles own the rules.
static func _chapter7_prop(parent: Node3D, spec: Dictionary) -> Node3D:
	var id := String(spec.asset)
	var node := C7.place(parent, id, Presentation.vector(spec.position), float(spec.get("yaw", 0)))
	if node == null:
		return null
	node.name = String(spec.id)
	var markers: Dictionary = spec.get("markers", {})
	var offset: Array = C7.entry(id).get("states", {}).get("label_offset_m", [0, 0.032, -0.012])
	for role in markers:
		C7.set_marker(node, String(role), String(markers[role]))
		_name_label(node, String(role), C7.socket_position(id, String(markers[role])) + Presentation.vector(offset))
	if spec.has("case"):
		C7.set_case(node, float(spec.case.get("lid", 0)), bool(spec.case.get("latched", true)))
	if spec.has("water_units"):
		C7.set_water_units(node, int(spec.water_units))
	if spec.has("selector"):
		C7.set_return_selector(node, String(spec.selector))
	if spec.has("isolated"):
		C7.set_isolated(node, bool(spec.isolated))
	if spec.has("card_out"):
		C7.set_card_out(node, bool(spec.card_out))
	for lamp in spec.get("lamps", {}):
		C7.set_lamp(node, String(lamp), String(spec.lamps[lamp]))
	for pin in spec.get("pins", {}):
		C7.place_pin(node, int(pin), String(spec.pins[pin]))
	for item in spec.get("attach", []):
		var model := Geometry.load_glb(String(item.path))
		if model != null:
			model.name = String(item.id)
			model.position = C7.socket_position(id, String(item.socket))
			model.rotation_degrees.y = float(item.get("yaw", 0))
			node.add_child(model)
	for screen in spec.get("screens", {}):
		_chapter7_screen(node, String(screen), spec.screens[screen])
	return node

## A seat marker's name beside it, single-sided and facing the board's front (-Z in the prop's own space).
static func _name_label(parent: Node3D, text: String, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.name = "Label_" + text
	label.text = text
	label.position = at
	label.rotation_degrees.y = 180.0
	label.font_size = 20
	label.pixel_size = 0.0009
	label.modulate = Color("#1f2944")
	label.outline_size = 0
	label.double_sided = false
	parent.add_child(label)
	return label

## Plain words on an M3-7A Screen_* slot in every LOD: an unshaded SubViewport picture rendered once, its font the
## largest at which every authored line fits. The Label is kept in the prop's "screen_text" meta.
static func _chapter7_screen(node: Node3D, screen: String, spec: Dictionary) -> Label:
	var px: Array = spec.get("px", C7_SCREEN_PX.get(screen, [640, 360]))
	var size := Vector2i(int(px[0]), int(px[1]))
	var view := SubViewport.new()
	view.name = "ScreenView_" + screen
	view.size = size
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	var back := ColorRect.new()
	back.color = Color(spec.get("bg", "#0b1220"))
	back.size = Vector2(size)
	view.add_child(back)
	var text := String(spec.get("text", ""))
	if spec.has("line"):
		text = text.replace("{line}", line_text(String(spec.line)))
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.position = Vector2(size) * Vector2(0.05, 0.05)
	label.size = Vector2(size) * Vector2(0.9, 0.9)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(spec.get("fg", "#d9f2ff")))
	var lines := text.split("\n")
	var longest := 1
	for one in lines:
		longest = maxi(longest, one.length())
	label.add_theme_font_size_override("font_size", maxi(8, int(minf(size.y * 0.8 / (lines.size() * 1.25), size.x * 0.88 / (longest * 0.58)))))
	view.add_child(label)
	node.add_child(view)
	var material := StandardMaterial3D.new()
	material.resource_name = "Screen_live"
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = view.get_texture()
	for slot in C7.screen_surfaces(node, screen):
		(slot.mesh as MeshInstance3D).set_surface_override_material(int(slot.surface), material)
	var texts: Dictionary = node.get_meta("screen_text", {})
	texts[screen] = label
	node.set_meta("screen_text", texts)
	return label

static func _pose_monitor(screen, settings: Dictionary) -> void:
	screen.set_filter(bool(settings.get("filter", true)))
	var track: Array = settings.get("track", [])
	screen.set_phase(float(track[0]) if track.size() == 3 else float(settings.get("phase", 0.0)))
	for event_id in settings.get("logged", []):
		screen.set_logged(String(event_id), true)
	screen.set_mode(String(settings.get("mode", "live")))
	screen.show_inset(bool(settings.get("inset", false)))

## A print pinned to a board: a quad facing +Z like a sign ("yaw" turns it), with a caption below. "solar_image"
## is the procedural white-light solar image; "eclipse_frame" is one held frame of the filtered camera, rendered
## once from the M3-6A monitor screen at the authored phase. M3-2R adds "plant_photo" (an installed plant or tray
## model photographed in its own world, "subject" GLB, optional "view", "zoom", "illustration"), "texture" (an image
## file, e.g. the paper-bee stamp) and "flower_diagram" (the labelled flower; "contact" adds pollen on the stigma,
## "glow" lights it as a screen). "border" (metres) adds a white photographic border.
static func _print(parent: Node3D, spec: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = String(spec.id)
	holder.position = Presentation.vector(spec.position)
	# "pitch" -90 lays a print on a table (top edge away from the reader); "roll" tilts it in its own plane
	holder.rotation_degrees = Vector3(float(spec.get("pitch", 0)), float(spec.get("yaw", 0)), float(spec.get("roll", 0)))
	parent.add_child(holder)
	var size := Vector2(float(spec.size[0]), float(spec.size[1]))
	var quad := MeshInstance3D.new()
	quad.name = "Print"
	var mesh := QuadMesh.new()
	mesh.size = size
	quad.mesh = mesh
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	match String(spec.kind):
		"solar_image":
			if _solar_shader == null:
				_solar_shader = Shader.new()
				_solar_shader.code = SOLAR_PRINT_SHADER
			var material := ShaderMaterial.new()
			material.shader = _solar_shader
			quad.material_override = material
		"eclipse_frame":
			var view := SubViewport.new()
			view.name = "FrameView"
			view.size = Vector2i(1152, 648)
			view.render_target_update_mode = SubViewport.UPDATE_ONCE
			var screen := (load(EclipseProps.MONITOR_SCREEN) as GDScript).new() as Control
			view.add_child(screen)
			holder.add_child(view)
			_pose_monitor(screen, spec.get("monitor", {"phase": 0.5, "mode": "held"}))
			var material := StandardMaterial3D.new()
			material.albedo_texture = view.get_texture()
			material.roughness = 0.6
			quad.material_override = material
		"plant_photo":
			var material := StandardMaterial3D.new()
			material.albedo_texture = _photo_view(holder, spec, size).get_texture()
			material.roughness = 0.45
			quad.material_override = material
		"texture":
			# "screen": true draws it as a lit display (M3-5R: the landing camera); "uv_rect" crops the image
			var material := _image_material(spec) if bool(spec.get("screen", false)) else StandardMaterial3D.new()
			if not bool(spec.get("screen", false)):
				material.albedo_texture = load(String(spec.texture)) as Texture2D
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				material.roughness = 0.9
				_crop(material, spec)
			quad.material_override = material
		"flower_diagram":
			if _flower_shader == null:
				_flower_shader = Shader.new()
				_flower_shader.code = FLOWER_DIAGRAM_SHADER
			var material := ShaderMaterial.new()
			material.shader = _flower_shader
			material.set_shader_parameter("aspect", size.x / size.y)
			material.set_shader_parameter("contact", 1.0 if bool(spec.get("contact", false)) else 0.0)
			material.set_shader_parameter("glow", float(spec.get("glow", 0.0)))
			quad.material_override = material
			_diagram_labels(holder, size, spec)
	if spec.has("border"):
		# a white photographic border, a millimetre behind the picture
		var back := MeshInstance3D.new()
		back.name = "Border"
		var card := QuadMesh.new()
		card.size = size + Vector2.ONE * float(spec.border) * 2.0
		back.mesh = card
		back.position.z = -0.001
		var paper := StandardMaterial3D.new()
		paper.albedo_color = Color("#f1f0ea")
		paper.roughness = 0.8
		back.material_override = paper
		back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(back)
	holder.add_child(quad)
	if spec.has("caption"):
		var caption := Label3D.new()
		caption.name = "Caption"
		caption.text = String(spec.caption)
		caption.position = Vector3(0, -size.y * 0.5 - 0.035, 0.002)
		caption.double_sided = false
		caption.font_size = 40
		caption.pixel_size = float(spec.get("caption_size", 0.0005))
		# wrapped to the print's own width, so a caption never runs off its board
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.width = size.x / caption.pixel_size
		caption.modulate = Color(spec.get("caption_color", "#1b2433"))
		caption.outline_size = 0
		caption.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		holder.add_child(caption)
	return holder

## M3-5R: poses a prop's own named parts and live surfaces for the scene, e.g. one 2034 record moved alone or turned
## over (PR_Records2034's per-sheet pivots), the document sleeve's lid open with its seal gone, the impact monitor's
## Screen showing one authored frame. "parts": node name -> {"visible", "position", "rotation_degrees"}, in the prop's
## own space, or (M3-4R) a bare [x, y, z] rotation in degrees set on every node of that name in its own parent's space,
## e.g. PR_VaultCase's hinged Lid open in the dry glovebox; "surfaces": material name -> {"texture", "uv_rect"}, drawn
## unshaded like a lit screen.
static func _pose_parts(model: Node3D, spec: Dictionary) -> void:
	var parts: Dictionary = spec.get("parts", {})
	for part in parts:
		if parts[part] is Array:
			for leaf in model.find_children(String(part), "Node3D", true, false):
				(leaf as Node3D).rotation_degrees = Presentation.vector(parts[part])
			continue
		var node := model.find_child(String(part), true, false) as Node3D
		if node == null:
			continue
		var pose: Dictionary = parts[part]
		if pose.has("visible"):
			node.visible = bool(pose.visible)
		if pose.has("position") or pose.has("rotation_degrees"):
			var to_model := Transform3D()
			var parent := node.get_parent()
			while parent != model and parent is Node3D:
				to_model = (parent as Node3D).transform * to_model
				parent = parent.get_parent()
			var wanted := to_model * node.transform
			if pose.has("rotation_degrees"):
				var degrees := Presentation.vector(pose.rotation_degrees)
				wanted.basis = Basis.from_euler(Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z)))
			if pose.has("position"):
				wanted.origin = Presentation.vector(pose.position)
			node.transform = to_model.affine_inverse() * wanted
	var surfaces: Dictionary = spec.get("surfaces", {})
	if surfaces.is_empty():
		return
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if instance.mesh == null:
			continue
		for i in instance.mesh.get_surface_count():
			var material := instance.mesh.surface_get_material(i)
			if material != null and surfaces.has(material.resource_name):
				instance.set_surface_override_material(i, _image_material(surfaces[material.resource_name]))

## An image drawn unshaded, like a lit display ("texture", optional "uv_rect" [x, y, w, h] crop in 0..1).
static func _image_material(spec: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "Screen_live"
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = load(String(spec.texture)) as Texture2D
	_crop(material, spec)
	return material

static func _crop(material: StandardMaterial3D, spec: Dictionary) -> void:
	var rect: Array = spec.get("uv_rect", [0, 0, 1, 1])
	material.uv1_offset = Vector3(float(rect[0]), float(rect[1]), 0)
	material.uv1_scale = Vector3(float(rect[2]), float(rect[3]), 1)

## The SubViewport that photographs an installed plant (or tray) model for a "plant_photo" print, rendered once: the
## subject GLB on its own in a dark chamber-like backdrop, one soft key and fill, framed from "view" (yaw, pitch in
## degrees) so the same frame repeats on every date. "illustration": true renders it unshaded, flat like a drawing
## (a reference illustration, never a photograph of the crew's own plant).
static func _photo_view(holder: Node3D, spec: Dictionary, size: Vector2) -> SubViewport:
	var view := SubViewport.new()
	view.name = "PhotoView"
	view.size = Vector2i(640, int(round(640.0 * size.y / size.x)))
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	if bool(spec.get("illustration", false)):
		view.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	holder.add_child(view)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(spec.get("backdrop", "#1b2433"))
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c9d3e0")
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	world.environment = environment
	view.add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -35, 0)
	key.light_color = Color(spec.get("light", "#fff1e0"))
	key.light_energy = 1.3
	view.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 150, 0)
	fill.light_energy = 0.35
	view.add_child(fill)
	var subject := Geometry.load_glb(String(spec.subject))
	var camera := Camera3D.new()
	camera.fov = 30.0
	view.add_child(camera)
	camera.current = true
	if subject == null:
		return view
	view.add_child(subject)
	var box := Geometry.bounds(subject) if subject.is_inside_tree() else AABB(Vector3(-0.15, 0, -0.15), Vector3(0.3, 0.4, 0.3))
	var aim: Array = spec.get("view", [25, -12])
	var direction := Basis.from_euler(Vector3(deg_to_rad(float(aim[1])), deg_to_rad(float(aim[0])), 0)) * Vector3.BACK
	var fit := maxf(box.size.y, maxf(box.size.x, box.size.z) * size.y / size.x) * 0.5 * float(spec.get("zoom", 1.2))
	var centre := box.get_center()
	camera.transform = Transform3D(Basis(), centre + direction * fit / tan(deg_to_rad(camera.fov) * 0.5)).looking_at(centre, Vector3.UP)
	return view

## The words of a flower diagram, beside the parts the leader lines point to (diagram space: x across the picture's
## height-relative width, y up, both -1..1 of the height).
static func _diagram_labels(holder: Node3D, size: Vector2, spec: Dictionary) -> void:
	var words: Dictionary = spec.get("labels", {"anther": "ANTHER\nmakes pollen", "stigma": "STIGMA\nreceives pollen"})
	var spots := {"anther": Vector2(0.98, 0.78), "stigma": Vector2(-0.98, 0.78)}
	for part in words:
		var label := Label3D.new()
		label.name = "Label_" + String(part)
		label.text = String(words[part])
		var at: Vector2 = spots.get(String(part), Vector2.ZERO) * size.y * 0.5
		label.position = Vector3(at.x, at.y, 0.002)
		label.double_sided = false
		label.font_size = 40
		label.pixel_size = size.y / 900.0
		label.modulate = Color("#1b2433")
		label.outline_size = 0
		holder.add_child(label)

## A nonliving teaching model of one mustard flower on a stand (EX-CH02-S02's practice model): four petals in a cross,
## four long and two short stamens with anthers, the pistil and its stigma, each part a separate primitive so the
## practice runs on contact points; tagged in words. Never a living plant, and like every plant here it has no face.
static func _teaching_model(parent: Node3D, spec: Dictionary) -> Node3D:
	var model := Node3D.new()
	model.name = String(spec.id)
	model.position = Presentation.vector(spec.position)
	model.rotation_degrees.y = float(spec.get("yaw", 0))
	parent.add_child(model)
	var parts := [
		["Base", "cylinder", Vector3(0, 0.008, 0), Vector3(0.14, 0.016, 0.14), Vector3.ZERO, "#1f2a44"],
		["Stem", "cylinder", Vector3(0, 0.09, 0), Vector3(0.012, 0.16, 0.012), Vector3.ZERO, "#4f8a3a"],
		["Receptacle", "sphere", Vector3(0, 0.172, 0), Vector3(0.03, 0.022, 0.03), Vector3.ZERO, "#4f8a3a"],
		["Pistil", "cylinder", Vector3(0, 0.205, 0), Vector3(0.011, 0.06, 0.011), Vector3.ZERO, "#5c9a44"],
		["Stigma", "sphere", Vector3(0, 0.238, 0), Vector3(0.022, 0.012, 0.022), Vector3.ZERO, "#cfd98a"],
	]
	for index in 4:
		var yaw := index * 90.0 + 45.0
		var out := Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 0.038)
		parts.append(["Petal%d" % index, "sphere", Vector3(out.x, 0.182, out.z), Vector3(0.034, 0.005, 0.06), Vector3(-22, yaw, 0), "#f2c230"])
	for index in 6:
		var long := index < 4
		var yaw: float = [0.0, 90.0, 180.0, 270.0, 45.0, 225.0][index]
		var reach := 0.012 if long else 0.024
		var out := Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, reach)
		var height := 0.05 if long else 0.034
		parts.append(["Filament%d" % index, "cylinder", Vector3(out.x, 0.175 + height * 0.5, out.z), Vector3(0.003, height, 0.003), Vector3.ZERO, "#d9dcb0"])
		parts.append(["Anther%d" % index, "sphere", Vector3(out.x, 0.178 + height, out.z), Vector3(0.008, 0.016, 0.008), Vector3.ZERO, "#d99a1c"])
	for part in parts:
		var mesh := MeshInstance3D.new()
		mesh.name = String(part[0])
		if part[1] == "cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.5
			cylinder.bottom_radius = 0.5
			cylinder.height = 1.0
			cylinder.radial_segments = 24
			mesh.mesh = cylinder
		else:
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 24
			sphere.rings = 12
			mesh.mesh = sphere
		mesh.position = part[2]
		mesh.rotation_degrees = part[4]
		mesh.scale = part[3]
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(String(part[5]))
		material.roughness = 0.55
		mesh.material_override = material
		model.add_child(mesh)
	for tag in [["TagAnther", "ANTHER", Vector3(0.07, 0.25, 0.0)], ["TagStigma", "STIGMA", Vector3(-0.075, 0.26, 0.0)]]:
		var label := Label3D.new()
		label.name = String(tag[0])
		label.text = String(tag[1])
		label.position = tag[2]
		label.font_size = 40
		label.pixel_size = 0.00045
		label.double_sided = false
		label.modulate = Color("#1b2433")
		label.outline_modulate = Color("#f1f0ea")
		label.outline_size = 8
		model.add_child(label)
	return model

## A short, deterministic rattle of a staged object (the cup at the EX-CH02-S11 -> S12 join): small slides and tilts
## for "seconds", then back to rest. Presentation only; the quake beat, its sounds and timing belong to the mission.
static func _rattle(model: Node3D, spec: Dictionary) -> void:
	if not model.is_inside_tree():
		return
	var rest_position := model.position
	var rest_rotation := model.rotation
	var amplitude := float(spec.get("amplitude_m", 0.003))
	var random := RandomNumberGenerator.new()
	random.seed = 20460506
	var tween := model.create_tween()
	tween.tween_interval(float(spec.get("delay_s", 0.0)))
	for step in int(float(spec.get("seconds", 2.5)) / 0.045):
		var nudge := Vector3(random.randf_range(-amplitude, amplitude), 0, random.randf_range(-amplitude, amplitude))
		var tilt := Vector3(random.randf_range(-0.035, 0.035), 0, random.randf_range(-0.035, 0.035))
		tween.tween_property(model, "position", rest_position + nudge, 0.045)
		tween.parallel().tween_property(model, "rotation", rest_rotation + tilt, 0.045)
	tween.tween_property(model, "position", rest_position, 0.08)
	tween.parallel().tween_property(model, "rotation", rest_rotation, 0.08)
	model.set_meta("rattle", tween)

# ------------------------------------------------------------------------------------------- live kit pieces (M3-3R)

## Places one live kit piece (a habitat-kit or M3-3A annex catalogue id) with its game-LOD collision, named spec.id:
## "piece", "position", "yaw", "parts" (moving part -> open fraction, e.g. the displaced service cover), "texts" (slot ->
## words on a full-UV screen or document slot, see slot_text), "inks" (small printed plates, see ink) and "attach"
## (objects seated in its sockets, see attach). The base room's kit_props use it.
static func kit_prop(parent: Node3D, spec: Dictionary) -> Node3D:
	var node := Kit.place(parent, String(spec.piece), Presentation.vector(spec.position), float(spec.get("yaw", 0)))
	if node == null:
		return null
	node.name = String(spec.id)
	for item in spec.get("inks", []):
		ink(node, item)
	for part in spec.get("parts", {}):
		Kit.set_part_open(node, String(part), float(spec.parts[part]))
	for slot in spec.get("texts", {}):
		slot_text(node, String(slot), spec.texts[slot])
	for item in spec.get("attach", []):
		attach(node, item)
	return node

## Printed or handwritten words on a piece's small plates (stamped nameplates, service tags, a page under a clear
## cover), whose slots are too small for a screen texture: a lit, single-sided Label3D in the piece's own space ("part"
## rides on a moving part, e.g. the N.R. nameplate on the hatch leaf). spec: "id", "text", "position", "pitch", "yaw",
## "size" (em height in metres), "color", "font" (hand / print).
static func ink(piece: Node3D, spec: Dictionary) -> Label3D:
	var parent: Node3D = piece
	var offset := Vector3.ZERO
	if spec.has("part"):
		var lod := piece.get_node_or_null("LOD0")
		var part := (lod if lod != null else piece).find_child(String(spec.part), true, false) as Node3D
		if part != null:
			parent = part
			var rest := Transform3D.IDENTITY
			var current: Node = part
			while current != null and current != piece:
				if current is Node3D:
					rest = (current as Node3D).transform * rest
				current = current.get_parent()
			# the authored point is in the piece's space with the part at rest (kit_prop inks before it poses parts)
			offset = -rest.origin
	var label := Label3D.new()
	label.name = String(spec.get("id", "Ink"))
	label.text = String(spec.text)
	label.position = Presentation.vector(spec.position) + offset
	label.rotation_degrees = Vector3(float(spec.get("pitch", 0)), float(spec.get("yaw", 0)), 0)
	label.double_sided = false
	label.font_size = 64
	label.pixel_size = float(spec.get("size", 0.01)) / 64.0
	label.outline_size = 0
	label.modulate = Color(spec.get("color", "#1F2A44"))
	if spec.has("font"):
		label.font = NarrativeProps.font(String(spec.font))
	if spec.has("wrap_m"):
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.width = float(spec.wrap_m) / label.pixel_size
	parent.add_child(label)
	return label

## Seats an object in one of a piece's sockets (a node named spec.socket inside it): a GLB ("path") or an M3-99
## narrative prop ("narrative" id with an optional "variant", e.g. PR_ToolTag_Gear on the support station's
## Socket_ToolTag), turned by "yaw". Returns the object, named spec.id.
static func attach(piece: Node3D, spec: Dictionary) -> Node3D:
	var socket := piece.find_child(String(spec.socket), true, false) as Node3D
	if socket == null:
		return null
	var model: Node3D = NarrativeProps.instance(String(spec.narrative), String(spec.get("variant", ""))) if spec.has("narrative") else Geometry.load_glb(String(spec.path))
	if model == null:
		return null
	model.name = String(spec.id)
	var at := Transform3D.IDENTITY
	var current: Node = socket
	while current != null and current != piece:
		if current is Node3D:
			at = (current as Node3D).transform * at
		current = current.get_parent()
	model.position = at.origin
	model.rotation_degrees.y = float(spec.get("yaw", 0))
	piece.add_child(model)
	return model

## Live words on a piece's material slot (the annex's Label*, Document* and Screen* slots carry no baked text): a
## SubViewport picture rendered once, at the largest font at which every line fits. spec: "text" ("{line}" is a canon
## catalog line word for word via "line"), "px" [w, h] (the slot's aspect), "bg", "fg", "font" (hand / print, the M3-99
## open fonts), "align" (left / center), "paper" (lit like paper instead of a glowing screen) and "flip" (h / v / hv,
## for a slot whose UVs run the other way). Returns the Label (kept in the piece's "slot_text" meta).
static func slot_text(piece: Node3D, slot: String, spec: Dictionary) -> Label:
	clear_slot(piece, slot)
	var px: Array = spec.get("px", [512, 256])
	var size := Vector2i(int(px[0]), int(px[1]))
	var view := SubViewport.new()
	view.name = "SlotView_" + slot
	view.size = size
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	var back := ColorRect.new()
	back.color = Color(spec.get("bg", "#0b1220"))
	back.size = Vector2(size)
	view.add_child(back)
	var text := String(spec.get("text", ""))
	if spec.has("line"):
		text = text.replace("{line}", line_text(String(spec.line)))
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.position = Vector2(size) * 0.05
	label.size = Vector2(size) * 0.9
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if spec.get("camera") is Dictionary and piece.is_inside_tree():
		# a live inspection camera (EX-CH03-S06: the camera that goes through the N.R. hatch port before anyone does):
		# the shared world seen from "from" towards "to" (room metres), the caption along the bottom edge
		var room_space: Transform3D = piece.get_parent().global_transform
		var eye := Camera3D.new()
		eye.fov = float(spec.camera.get("fov", 70))
		var from: Vector3 = room_space * Presentation.vector(spec.camera.from)
		eye.transform = Transform3D(Basis.looking_at(room_space * Presentation.vector(spec.camera.to) - from, Vector3.UP), from)
		eye.current = true
		view.add_child(eye)
		back.color = Color(0, 0, 0, 0)
		view.transparent_bg = false
		label.position = Vector2(size) * Vector2(0.04, 0.78)
		label.size = Vector2(size) * Vector2(0.92, 0.18)
		var refresh := view.create_tween()
		refresh.tween_interval(0.8)  # once more after the scene's shaders and shadow maps settle
		refresh.tween_callback(func() -> void: view.render_target_update_mode = SubViewport.UPDATE_ONCE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if String(spec.get("align", "center")) == "left" else HORIZONTAL_ALIGNMENT_CENTER
	if spec.has("font"):
		label.add_theme_font_override("font", NarrativeProps.font(String(spec.font)))
	label.add_theme_color_override("font_color", Color(spec.get("fg", "#d9f2ff")))
	var lines := text.split("\n")
	var longest := 1
	for one in lines:
		longest = maxi(longest, one.length())
	label.add_theme_font_size_override("font_size", maxi(8, int(minf(label.size.y * 0.89 / (lines.size() * 1.25), label.size.x * 0.98 / (longest * 0.58)))))
	view.add_child(label)
	piece.add_child(view)
	var material := StandardMaterial3D.new()
	material.resource_name = slot + "_live"
	if bool(spec.get("paper", false)):
		material.roughness = 0.85
	else:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = view.get_texture()
	var flip := String(spec.get("flip", ""))
	material.uv1_scale = Vector3(-1.0 if flip.contains("h") else 1.0, -1.0 if flip.contains("v") else 1.0, 1.0)
	material.uv1_offset = Vector3(1.0 if flip.contains("h") else 0.0, 1.0 if flip.contains("v") else 0.0, 0.0)
	for found in slot_surfaces(piece, slot):
		(found.mesh as MeshInstance3D).set_surface_override_material(int(found.surface), material)
	var texts: Dictionary = piece.get_meta("slot_text", {})
	texts[slot] = label
	piece.set_meta("slot_text", texts)
	return label

## Takes a slot's live words off again (the imported blank material shows).
static func clear_slot(piece: Node3D, slot: String) -> void:
	var old := piece.get_node_or_null("SlotView_" + slot)
	if old == null:
		return
	piece.remove_child(old)
	old.queue_free()
	for found in slot_surfaces(piece, slot):
		(found.mesh as MeshInstance3D).set_surface_override_material(int(found.surface), null)
	var texts: Dictionary = piece.get_meta("slot_text", {})
	texts.erase(slot)
	piece.set_meta("slot_text", texts)

## Every surface of a piece (all LODs) whose imported material is named exactly slot.
static func slot_surfaces(piece: Node3D, slot: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mesh in piece.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.mesh.surface_get_material(surface)
			if material != null and String(material.resource_name) == slot:
				out.append({"mesh": instance, "surface": surface})
	return out

# ------------------------------------------------------------------------------------------- Chapter 8 exteriors

## M3-8R: the scene's state of an authored exterior piece (an M3-8A summit or road piece, or VH_Rover_Lit placed by
## LOC-11 / LOC-12): lamp slots ("lamps": slot -> "#rrggbb", or "off"), moving parts ("parts": node -> rotation in
## degrees, e.g. the housing's DoorHinge or the isolator Handle), live screen slots ("screens": slot -> {text, fg, bg,
## px}; "line" quotes a catalog line) and the rover's light state ("lights": driving, eva_stop or parked_dark,
## rover_lights.json). clear() puts every piece back as built. Presentation only: P-15 / P-16 own the rules.
static func _piece_state(node: Node3D, spec: Dictionary) -> void:
	if node == null:
		return
	node.set_meta("piece_state", true)
	for slot in spec.get("lamps", {}):
		var colour := String(spec.lamps[slot])
		C8.set_lamp(node, String(slot), Color.BLACK if colour == "off" else Color(colour))
	for part in spec.get("parts", {}):
		for found in node.find_children(String(part), "Node3D", true, false):
			if not found.has_meta("rest_rotation"):
				found.set_meta("rest_rotation", (found as Node3D).rotation_degrees)
			(found as Node3D).rotation_degrees = Presentation.vector(spec.parts[part])
	for slot in spec.get("screens", {}):
		_piece_screen(node, String(slot), spec.screens[slot])
	if spec.has("lights"):
		set_rover_lights(node, String(spec.lights))

static func _restore_piece(node: Node) -> void:
	node.remove_meta("piece_state")
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		for surface in (mesh as MeshInstance3D).get_surface_override_material_count():
			(mesh as MeshInstance3D).set_surface_override_material(surface, null)
	for part in node.find_children("*", "Node3D", true, false):
		if part.has_meta("rest_rotation"):
			(part as Node3D).rotation_degrees = part.get_meta("rest_rotation")
			part.remove_meta("rest_rotation")
	for quad in node.find_children("PieceScreenQuad_*", "MeshInstance3D", true, false):
		quad.get_parent().remove_child(quad)
		quad.queue_free()
	for view in node.find_children("PieceScreen_*", "SubViewport", false, false):
		node.remove_child(view)
		view.queue_free()
	if node.has_meta("screen_text"):
		node.remove_meta("screen_text")
	if node.has_meta("rover_lights"):
		set_rover_lights(node as Node3D, "")

## VH_Rover_Lit's lights for one state of rover_lights.json (driving: headlights and cabin glow; eva_stop adds the two
## roof work floods; parked_dark: none); "" restores the scene file's own defaults.
static func set_rover_lights(rover: Node3D, state: String) -> void:
	var table = JSON.parse_string(FileAccess.get_file_as_string(ROVER_LIGHTS))
	var on: Array = table.get("states", {}).get(state, []) if table is Dictionary else []
	for light in rover.get_children():
		if not light is Light3D:
			continue
		if not light.has_meta("rest_visible"):
			light.set_meta("rest_visible", light.visible)
		light.visible = bool(light.get_meta("rest_visible")) if state.is_empty() else on.has(String(light.name))
	if state.is_empty():
		rover.remove_meta("rover_lights")
	else:
		rover.set_meta("rover_lights", state)

## Plain words on an M3-8A Screen_* slot (both LODs): an unshaded SubViewport picture rendered once, like the M3-7A
## screens. The Label is kept in the piece's "screen_text" meta.
static func _piece_screen(node: Node3D, slot: String, spec: Dictionary) -> Label:
	var px: Array = spec.get("px", [640, 400])
	var size := Vector2i(int(px[0]), int(px[1]))
	var view := SubViewport.new()
	view.name = "PieceScreen_" + slot
	view.size = size
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	var back := ColorRect.new()
	back.color = Color(spec.get("bg", "#0b1220"))
	back.size = Vector2(size)
	view.add_child(back)
	var text := String(spec.get("text", ""))
	if spec.has("line"):
		text = text.replace("{line}", line_text(String(spec.line)))
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.position = Vector2(size) * 0.05
	label.size = Vector2(size) * 0.9
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(spec.get("fg", "#d9f2ff")))
	var lines := text.split("\n")
	var longest := 1
	for one in lines:
		longest = maxi(longest, one.length())
	label.add_theme_font_size_override("font_size", maxi(8, int(minf(size.y * 0.8 / (lines.size() * 1.25), size.x * 0.88 / (longest * 0.58)))))
	view.add_child(label)
	node.add_child(view)
	var material := StandardMaterial3D.new()
	material.resource_name = "Screen_live"
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = view.get_texture()
	# The M3-8A screen slots carry box-projected UVs, not a picture layout, so the slot itself shows the dark glass and
	# the picture lies on a quad over the slot's largest flat face (each LOD's own, so it hides with its LOD).
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_color = back.color
	for pair in C8.surfaces(node, slot):
		var mesh := pair[0] as MeshInstance3D
		mesh.set_surface_override_material(int(pair[1]), glass)
		var quad := _face_quad(mesh, int(pair[1]), material)
		if quad != null:
			quad.name = "PieceScreenQuad_" + slot
			mesh.add_child(quad)
	var texts: Dictionary = node.get_meta("screen_text", {})
	texts[slot] = label
	node.set_meta("screen_text", texts)
	return label

## A quad 1 mm in front of the largest flat face of one surface (triangles grouped by normal, areas summed), sized to
## that face with its +X to the viewer's right and +Y up, in the mesh's own space; it copies the mesh's LOD range.
static func _face_quad(mesh: MeshInstance3D, surface: int, material: Material) -> MeshInstance3D:
	var arrays := mesh.mesh.surface_get_arrays(surface)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var count := index.size() if not index.is_empty() else verts.size()
	var faces := {}
	for t in range(0, count - 2, 3):
		var ids := [index[t], index[t + 1], index[t + 2]] if not index.is_empty() else [t, t + 1, t + 2]
		var area := (verts[ids[1]] - verts[ids[0]]).cross(verts[ids[2]] - verts[ids[0]]).length() * 0.5
		var normal := (normals[ids[0]] + normals[ids[1]] + normals[ids[2]]).normalized()
		if area < 1e-9 or normal == Vector3.ZERO:
			continue
		var key := Vector3i(roundi(normal.x * 20.0), roundi(normal.y * 20.0), roundi(normal.z * 20.0))
		var face: Array = faces.get(key, [0.0, normal, []])
		face[0] = float(face[0]) + area
		face[2] = face[2] + [verts[ids[0]], verts[ids[1]], verts[ids[2]]]
		faces[key] = face
	var best: Array = []
	for key in faces:
		if best.is_empty() or float(faces[key][0]) > float(best[0]):
			best = faces[key]
	if best.is_empty():
		return null
	var n: Vector3 = best[1]
	var u := Vector3.UP.cross(n)
	u = (u if u.length() > 0.1 else Vector3.RIGHT).normalized()
	var v := n.cross(u).normalized()
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	var depth := 0.0
	for p in best[2]:
		var at := Vector2((p as Vector3).dot(u), (p as Vector3).dot(v))
		low = low.min(at)
		high = high.max(at)
		depth = maxf(depth, (p as Vector3).dot(n))
	var quad := MeshInstance3D.new()
	var shape := QuadMesh.new()
	shape.size = high - low
	quad.mesh = shape
	quad.material_override = material
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var centre := (low + high) * 0.5
	quad.transform = Transform3D(Basis(u, v, n), u * centre.x + v * centre.y + n * (depth + 0.001))
	quad.visibility_range_begin = mesh.visibility_range_begin
	quad.visibility_range_end = mesh.visibility_range_end
	return quad

## An exterior's sky for one scene on the flat staging floor (M3-8R; on the terrain the provider's rig does this):
## the dated Earth where RoomContract.earth presents it, with the key light turned to the same dated Sun, else the
## black sky, with a faint sparse star field only where the scene's staging asks for one ("stars": intensity), which
## ART_BIBLE section 2 rule 12 allows only in frames with no sunlit ground at all.
static func apply_sky(room: CampaignRoom, scene_id: String, stage: Dictionary) -> void:
	var lighting := room.get_node_or_null("RoomLighting") as Node3D
	if lighting == null or String(Contract.room(room.room_id).get("pressure", "")) != "vacuum":
		return
	var world := lighting.get_node_or_null("RoomEnvironment") as WorldEnvironment
	var key := lighting.get_node_or_null("KeyLight") as DirectionalLight3D
	if world == null or world.environment == null:
		return
	var spec := Contract.earth(room.room_id, scene_id)
	var stars := float(stage.get("lighting", {}).get("stars", 0.0))
	if bool(spec.get("presented", false)):
		var to_sun := Presentation.vector(spec.sun_direction)
		if key != null:
			key.basis = Basis.looking_at(-to_sun, Vector3.UP)
		EarthSky.apply(world.environment, spec, key.light_energy if key != null else 2.0)
	elif stars > 0.0 and (key == null or is_zero_approx(key.light_energy)):
		EarthSky.stars(world.environment, stars)
	else:
		EarthSky.clear(world.environment)
