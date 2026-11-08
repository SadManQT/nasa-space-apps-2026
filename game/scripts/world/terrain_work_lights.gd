## M1-91: the work lights of the Chapter 4 exteriors (rooms/terrain_work_lights.json), on the terrain provider's ground and
## on the flat fallback floor alike. Below the cold-trap rim the dated Sun is under the terrain horizon (the
## EX-CH04-S04 B3, S05 and S06..S08 rows are "dark") and nothing adds ambient fill, so the work area is lit only by the
## lamps the field team brought: the staged VH_Rover (LOC-09.json / LOC-10.json, M3-106) runs its approved EVA-stop state
## (rover_lights.json, M3-8A decision 7: headlights, roof work floods, cabin glow) with its floods turned onto the room's
## work targets, and Kai's PR_HandLight lies by the vault (STORY_FULL EX-CH04-S06 "Kai turns the light", S07 "Kai moves
## the light", S08 "the lit work area"). The suited crew's helmet lamps are CampaignCrew's. Every lamp is a real light on
## an approved prop, hard-shadowed in every renderer. Compatibility uses the authored energy fractions to avoid
## clipping where its shadowed light passes overlap; nothing here adds ambient light, a sky or a second sun.
extends RefCounted

const Presentation = preload("res://scripts/world/room_presentation.gd")
const Geometry = preload("res://scripts/asset_geometry.gd")
const Toon = preload("res://scripts/toon_materials.gd")
## The room's added work-light props (Kai's hand light) stand under VisualRoot/<ROOT_NAME>.
const ROOT_NAME := "WorkLights"
## Every work light carries this meta (its lamp id), so lights() finds the rover's lamps and the added ones alike.
const META := "work_light"
## A prop's own lamp starts this far in front of its lens point, so the prop's shell never shadows it.
const LENS_CLEARANCE_M := 0.04
## Where a scene's staging puts its props (room_staging.gd ROOT_NAME): LOC-11's rover is staged per scene (M4-14).
const STAGING_ROOT := "ChapterStaging"
static var _rigs: Dictionary = {}

## Puts the room's work lights up once its approved props have loaded: the staged rover (spec.rover.prop, a child of
## visual_root) in its rig state with its floods aimed, and each added prop with its lamps: on the terrain at its derived
## pose for the placement (spec.on_ground[segment]; "" is the room's own placement), on the flat floor at its xz and yaw.
## focus_root holds the room's built focus targets ("Focus_<id>", on the terrain already at their published spots), which
## the aims name. toon: the room cel-shades its props (not a site_kit or habitat_kit room). scene_id: the staged scene,
## which picks a staged rover's rig state (rover_state). Returns every work light the room has afterwards.
static func build(spec: Dictionary, segment: String, on_terrain: bool, visual_root: Node3D, focus_root: Node3D, toon: bool, scene_id: String = "") -> Array:
	if spec.is_empty():
		return []
	var method := RenderingServer.get_current_rendering_method()
	var rover := rover_node(visual_root, spec)
	var state := rover_state(spec, scene_id)
	if rover != null and not state.is_empty() and not rover.has_meta(META):
		_rover(rover, spec, state, focus_root, method)
	var poses: Dictionary = spec.get("on_ground", {}).get(segment, {})
	var added := _root(visual_root)
	for prop in spec.get("props", []):
		var id := String(prop.id)
		if added.has_node(id):
			continue
		if on_terrain and not poses.has(id):
			push_warning("TerrainWorkLights: %s has no published terrain pose here (run test_terrain_work_lights.gd -- --write)" % id)
			continue
		var model := Geometry.load_glb(String(prop.path))
		if model == null:
			continue
		model.name = id
		if on_terrain:
			model.position = Presentation.vector(poses[id].position)
			model.rotation_degrees = Presentation.vector(poses[id].rotation_degrees)
		else:
			model.position = Vector3(float(prop.xz[0]), 0.0, float(prop.xz[1]))
			model.rotation_degrees = Vector3(0.0, float(prop.yaw_deg), 0.0)
		model.set_meta("work_light_prop", String(prop.asset_id))
		model.set_meta("asset_path", String(prop.path))
		added.add_child(model)
		if toon:
			Toon.apply_to_tree(model, false, true)
		for lamp in prop.get("lamps", []):
			_lamp(model, lamp, focus_root, energy_scale(spec, method, String(lamp.id)))
	return lights(visual_root)

## The authored fraction of a lamp's approved energy in this renderer. Forward+ and Mobile retain the rig's energy;
## Compatibility uses per-lamp fractions from the room contract, retaining the same beam, aim and hard shadows.
static func energy_scale(spec: Dictionary, rendering_method: String, lamp: String) -> float:
	return float(spec.get("compatibility_energy_scale", {}).get(lamp, 1.0)) if rendering_method == "gl_compatibility" else 1.0

## Every work light under visual_root that is switched on and shown: the rover's lamps in their state and the added
## props' lamps, leaving out any lamp whose prop (or the room) is hidden, e.g. by a scene's staging, since a hidden lamp
## lights nothing. Before the room enters the tree nothing is shown, so this is [].
static func lights(visual_root: Node3D) -> Array:
	return visual_root.find_children("*", "Light3D", true, false).filter(func(light): return (light as Node).has_meta(META) and (light as Light3D).is_visible_in_tree() and (light as Light3D).light_energy > 0.0)

## The rover the work lights run: the room's own prop (visual_root/<prop>, LOC-09, LOC-10) or the one a scene's staging
## places (ChapterStaging/<prop>, LOC-11, M4-14); null when neither is there.
static func rover_node(visual_root: Node3D, spec: Dictionary) -> Node3D:
	var id := String(spec.get("rover", {}).get("prop", ""))
	if id.is_empty():
		return null
	var own := visual_root.get_node_or_null(id) as Node3D
	return own if own != null else visual_root.get_node_or_null("%s/%s" % [STAGING_ROOT, id]) as Node3D

## The rover's rig state in a scene: rover.states[scene_id] for a rover whose state the scene's staging sets (LOC-11:
## driving in EX-CH08-S03, eva_stop in S04), else rover.state; "" for none.
static func rover_state(spec: Dictionary, scene_id: String = "") -> String:
	var rover: Dictionary = spec.get("rover", {})
	return String(rover.get("states", {}).get(scene_id, rover.get("state", "")))

## The id of one work light as lamp_ids() lists it: "<prop>/<lamp>" (the rover's lamps and the added props' lamps are
## children of their prop).
static func lamp_id(light: Light3D) -> String:
	return "%s/%s" % [light.get_parent().name, light.name]

## The ids of the lamps a room's work lights switch on in a scene ("VH_Rover/RoofFlood_L", "KaiHandLight/HandLightBeam"),
## for the ready flag; [] for a room without work lights.
static func lamp_ids(spec: Dictionary, scene_id: String = "") -> Array:
	var ids: Array = []
	var rover: Dictionary = spec.get("rover", {})
	if not rover.is_empty():
		for name in _rig(String(spec.get("rover_rig", ""))).get("states", {}).get(rover_state(spec, scene_id), []):
			ids.append("%s/%s" % [rover.prop, name])
	for prop in spec.get("props", []):
		for lamp in prop.get("lamps", []):
			ids.append("%s/%s" % [prop.id, lamp.id])
	return ids

## The rover in its rig state (the approved lamps of rover_lights.json "states"; the others stay off), each lamp at its
## rig energy times its renderer's fraction, hard-shadowed, and the ones in "aim" turned on their mounts onto a focus target of the
## room.
static func _rover(rover: Node3D, spec: Dictionary, state: String, focus_root: Node3D, method: String) -> void:
	var rig := _rig(String(spec.rover_rig))
	var wanted: Array = rig.get("states", {}).get(state, [])
	var aims: Dictionary = spec.rover.get("aim", {})
	for lamp in rig.get("lights", []):
		var light := rover.get_node_or_null(String(lamp.name)) as Light3D
		if light == null:
			continue
		light.visible = wanted.has(String(lamp.name))
		light.light_energy = float(lamp.energy) * energy_scale(spec, method, String(lamp.name))
		light.shadow_enabled = true
		light.set_meta(META, String(lamp.name))
		if light.visible and aims.has(String(lamp.name)):
			var target = _focus_point(focus_root, String(aims[lamp.name]))
			if target != null:
				_aim(light, rover.transform.affine_inverse() * (target as Vector3) - light.position)
	rover.set_meta(META, state)

## A focus target's built position in the room (Focus_<id>, on its published terrain spot on the terrain), or null.
static func _focus_point(focus_root: Node3D, target_id: String) -> Variant:
	var node := focus_root.get_node_or_null("Focus_" + target_id) as Node3D
	return node.position if node != null else null

static func _rig(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	if not _rigs.has(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		_rigs[path] = parsed if parsed is Dictionary else {}
	return _rigs[path]

## One lamp on an added prop: a hard-shadowed SpotLight3D just in front of its lens ("at", in the
## prop's frame), along its "axis" or turned onto the focus target "aim", with a lit lens that casts no shadow.
static func _lamp(prop: Node3D, spec: Dictionary, focus_root: Node3D, scale: float) -> SpotLight3D:
	var at := Presentation.vector(spec.at)
	var direction := Presentation.vector(spec.get("axis", [0, 0, -1])).normalized()
	if spec.has("aim"):
		var target = _focus_point(focus_root, String(spec.aim))
		if target != null:
			direction = (prop.transform.affine_inverse() * (target as Vector3) - at).normalized()
	var spot := SpotLight3D.new()
	spot.name = String(spec.id)
	_aim(spot, direction)
	spot.position = at + direction * LENS_CLEARANCE_M
	spot.spot_range = float(spec.range_m)
	spot.spot_angle = float(spec.angle_deg)
	spot.spot_angle_attenuation = float(spec.get("edge", 1.0))
	if spec.has("decay"):
		spot.spot_attenuation = float(spec.decay)
	spot.light_color = Color(String(spec.color))
	spot.light_energy = float(spec.energy) * scale
	spot.light_size = 0.0
	spot.shadow_enabled = true
	spot.set_meta(META, String(spec.id))
	prop.add_child(spot)
	if spec.has("lens"):
		var lens := _lens(spec, spot.light_color)
		# the lens disc faces the beam, 6 mm proud of the lens point
		var place := Transform3D(Basis.looking_at(direction, _up(direction)) * Basis(Vector3.RIGHT, PI * 0.5), at + direction * 0.006)
		lens.transform = spot.transform.affine_inverse() * place
		spot.add_child(lens)
	return spot

## Turns a light (whose beam is its -Z) to shine along direction, in its parent's frame.
static func _aim(light: Light3D, direction: Vector3) -> void:
	light.basis = Basis.looking_at(direction.normalized(), _up(direction))

static func _up(direction: Vector3) -> Vector3:
	return Vector3.UP if absf(direction.normalized().y) < 0.98 else Vector3.BACK

## The lit lens of a lamp: a disc ("lens.radius"), glowing in the lamp's colour. It casts no shadow, so it can never
## block its own lamp.
static func _lens(spec: Dictionary, color: Color) -> MeshInstance3D:
	var lens := MeshInstance3D.new()
	lens.name = "Lens"
	var disc := CylinderMesh.new()
	disc.top_radius = float(spec.lens.radius)
	disc.bottom_radius = float(spec.lens.radius)
	disc.height = 0.008
	disc.radial_segments = 24
	disc.rings = 1
	lens.mesh = disc
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.BLACK
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = float(spec.lens.get("glow", 4.0))
	material.roughness = 0.3
	lens.material_override = material
	return lens

static func _root(parent: Node3D) -> Node3D:
	var existing := parent.get_node_or_null(ROOT_NAME) as Node3D
	if existing != null:
		return existing
	var node := Node3D.new()
	node.name = ROOT_NAME
	parent.add_child(node)
	return node
