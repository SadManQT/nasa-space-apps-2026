## M3-6R: builds a room's chapter staging (RoomContract.staging for the staged scene) on top of the base Chapter 1
## assembly: dated furniture and fixtures, the M3-6A eclipse props in the scene's state, prints, signs and screens,
## per-scene practical-light levels, collision for every floor-standing addition and the staged focus stations.
## clear() puts the base room back exactly. Presentation only: puzzles, missions and the director own every rule.
extends RefCounted

const Presentation = preload("res://scripts/world/room_presentation.gd")
const Habitat = preload("res://scripts/world/habitat_room_builder.gd")
const Geometry = preload("res://scripts/asset_geometry.gd")
const EclipseProps = preload("res://assets/props/eclipse_power/eclipse_props.gd")
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
static var _lines: Dictionary = {}
static var _solar_shader: Shader

## Builds stage into room (base nodes named in "hide" are hidden, everything else is added under ChapterStaging
## roots) and returns the visual root of the additions.
static func build(room: CampaignRoom, stage: Dictionary, layout: Dictionary) -> Node3D:
	var visuals := _root(room.visual_root)
	var colliders := _root(room.collision_root)
	var habitat: bool = layout.get("assembly") == "habitat_kit"
	for node in room.visual_root.get_children():
		if node is Node3D and node.visible and (String(node.name) in stage.hide or (node is Label3D and String(node.text) in stage.hide_signs)):
			node.hide()
			node.set_meta("staging_hidden", true)
	for body in room.collision_root.get_children():
		if String(body.name) in stage.hide:
			for shape in body.find_children("*", "CollisionShape3D", true, false):
				(shape as CollisionShape3D).disabled = true
			body.set_meta("staging_disabled", true)
	for spec in stage.fixtures:
		Presentation.fixture(visuals, spec, habitat)
	for spec in stage.props:
		var model := Geometry.load_glb(String(spec.path))
		if model == null:
			continue
		model.name = String(spec.id)
		model.position = Presentation.vector(spec.position)
		model.rotation_degrees = Presentation.vector(spec.get("rotation_degrees", [0, 0, 0]))
		model.scale = Presentation.vector(spec.get("scale", [1, 1, 1]))
		visuals.add_child(model)
	for spec in stage.eclipse_props:
		_eclipse_prop(visuals, spec)
	for spec in stage.prints:
		_print(visuals, spec)
	for spec in stage.signs:
		var shown: Dictionary = spec.duplicate()
		if spec.has("line"):
			shown.text = String(spec.text).replace("{line}", line_text(String(spec.line)))
		var label := Presentation.wall_sign(visuals, shown, layout)
		label.name = String(spec.get("id", "Sign"))
		label.outline_size = int(spec.get("outline", 12))
	for spec in stage.obstacles:
		Habitat.collider(colliders, String(spec.id), Presentation.vector(spec.position), Presentation.vector(spec.size))
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
			lamp.shadow_enabled = false
			lamps.add_child(lamp)
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
	set_light_level(room, {})

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
## once from the M3-6A monitor screen at the authored phase.
static func _print(parent: Node3D, spec: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = String(spec.id)
	holder.position = Presentation.vector(spec.position)
	holder.rotation_degrees.y = float(spec.get("yaw", 0))
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
