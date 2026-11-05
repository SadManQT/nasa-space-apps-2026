## M3-6A: the Chapter 6 eclipse power props, catalogue and instancing helper.
## Reads eclipse_props.json (geometry facts written by production/tools/build_eclipse_props.py) and
## eclipse_props_content.json (authored label text, lamp words, variants and state presets), builds a prop as a
## two-LOD node like the habitat kit, puts a Label3D on every blank plate, and drives lamps, moving parts, the guide
## and flood lights, and the live screens. It only poses the props: the puzzles (P-11, P-12) own every rule.
extends RefCounted

const CATALOG_PATH := "res://assets/props/eclipse_power/eclipse_props.json"
const CONTENT_PATH := "res://assets/props/eclipse_power/eclipse_props_content.json"
const MONITOR_SCREEN := "res://assets/props/eclipse_power/monitor/eclipse_monitor_screen.gd"
const SCREEN_MATERIAL := "Screen"
const LABEL_FONT_SIZE := 64
const STATE_META := "eclipse_prop_state"
static var _catalog: Dictionary = {}
static var _content: Dictionary = {}
static var _scenes: Dictionary = {}
static var _lamp_materials: Dictionary = {}

# ----------------------------------------------------------------------------------------------- catalogue

## The generated catalogue: conventions and one entry per prop (lods, triangles, size, anchor, parts, lamps, ...).
static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return _catalog

## The authored content: lamp states, label text, variants, lights and state presets.
static func content() -> Dictionary:
	if _content.is_empty():
		_content = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	return _content

## Every prop id in catalogue order.
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for entry in catalog().props:
		out.append(entry.id)
	return out

## The catalogue entry for one prop, or an empty dictionary for an unknown id.
static func prop(id: String) -> Dictionary:
	for entry in catalog().props:
		if entry.id == id:
			return entry
	return {}

## The authored content for one prop (labels, states, variants), or an empty dictionary.
static func prop_content(id: String) -> Dictionary:
	return content().props.get(id, {})

## The height a prop is lifted to on a kit wall (0 for floor and loose props).
static func mount_y(id: String) -> float:
	return float(prop(id).get("mount_y", 0.0))

## The variant ids of a prop with variants (segment cards, service tags), in authored order.
static func variant_ids(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for v in prop_content(id).get("variants", []):
		out.append(v.id)
	return out

static func _variant(id: String, variant: String) -> Dictionary:
	for v in prop_content(id).get("variants", []):
		if v.id == variant:
			return v
	return {}

static func _scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load(path)
	return _scenes[path]

# ----------------------------------------------------------------------------------------------- instancing

## Builds a prop: a Node3D named after the id holding one child per LOD (visibility ranges meet at the catalogue's
## lod_distance_m, no fade, so it works in Compatibility). LOD0 keeps the GLB's collision unless with_collision is
## false; max_lod 0 forces the game LOD. variant picks a card or tag variant; the default state preset is applied.
static func instance(id: String, with_collision: bool = true, max_lod: int = 1, variant: String = "") -> Node3D:
	var entry := prop(id)
	if entry.is_empty():
		push_error("EclipseProps: unknown prop " + id)
		return null
	var node := Node3D.new()
	node.name = id if variant == "" else "%s_%s" % [id, variant]
	node.set_meta("eclipse_prop", id)
	node.set_meta("eclipse_variant", variant)
	node.set_meta(STATE_META, {"lamps": {}, "parts": {}})
	var switch := float(entry.get("lod_distance_m", 12.0))
	var lods: Array = entry.lods
	var last := mini(max_lod, lods.size() - 1)
	for lod in range(last + 1):
		var packed := _scene(lods[lod])
		if packed == null:
			push_error("EclipseProps: missing " + String(lods[lod]))
			continue
		var child := packed.instantiate() as Node3D
		child.name = "LOD%d" % lod
		for mesh in child.find_children("*", "GeometryInstance3D", true, false):
			var geometry := mesh as GeometryInstance3D
			geometry.visibility_range_begin = switch if lod > 0 else 0.0
			geometry.visibility_range_end = switch if (lod == 0 and last > 0) else 0.0
			geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		if lod > 0 or not with_collision:
			for body in child.find_children("*", "StaticBody3D", true, false):
				body.get_parent().remove_child(body)
				body.free()
		node.add_child(child)
	_apply_labels(node, id, variant, switch if last > 0 else 0.0)
	var v := _variant(id, variant)
	if v.has("band"):
		set_tint(node, "Band", Color(v.band))
	var initial: String = prop_content(id).get("default_state", "")
	if initial != "":
		apply_state(node, initial)
	return node

## Instances a prop under parent. For a wall prop, position is the kit wall's grid position on the floor (the wall
## face plane) and the prop is lifted by its mount height; floor props stand on position. Yaw in degrees.
static func place(parent: Node3D, id: String, position: Vector3, yaw_degrees: float = 0.0, variant: String = "", with_collision: bool = true, max_lod: int = 1) -> Node3D:
	var node := instance(id, with_collision, max_lod, variant)
	if node == null:
		return null
	node.position = position + Vector3(0.0, mount_y(id), 0.0)
	node.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	parent.add_child(node)
	return node

## Every node with this exact name in every LOD of the prop (parts, lamps and screens exist in both LODs).
static func nodes_named(node: Node3D, name: String) -> Array[Node]:
	var out: Array[Node] = []
	for lod in node.get_children():
		var found := lod.find_child(name, true, false)
		if found != null:
			out.append(found)
	return out

## The LOD0 socket node Socket_<socket_id> (card slots, tag cells, light sockets, run joins), or null.
static func socket(node: Node3D, socket_id: String) -> Node3D:
	var lod0 := node.get_node_or_null("LOD0")
	return null if lod0 == null else lod0.find_child("Socket_" + socket_id, true, false) as Node3D

## The Label3D on plate label_id (LOD0), or null when the prop has no such label.
static func label(node: Node3D, label_id: String) -> Label3D:
	var lod0 := node.get_node_or_null("LOD0")
	if lod0 == null:
		return null
	var holder := lod0.find_child("Label_" + label_id, true, false)
	return null if holder == null else holder.get_node_or_null("Text") as Label3D

# ----------------------------------------------------------------------------------------------- labels

static func _apply_labels(node: Node3D, id: String, variant: String, range_end: float) -> void:
	var entry := prop(id)
	var authored: Dictionary = prop_content(id).get("labels", {})
	var overrides: Dictionary = _variant(id, variant).get("labels", {})
	var lod0 := node.get_node_or_null("LOD0")
	if lod0 == null:
		return
	for label_id in entry.get("labels", {}):
		var holder := lod0.find_child("Label_" + label_id, true, false) as Node3D
		if holder == null:
			continue
		var spec = authored.get(label_id, "")
		var text: Label3D = Label3D.new()
		text.name = "Text"
		text.font_size = LABEL_FONT_SIZE
		text.outline_size = 0
		text.shaded = true
		text.double_sided = false
		text.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
		text.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.rotation_degrees = Vector3(0, 180, 0)  # plates face -Z; a Label3D reads towards +Z
		text.visibility_range_end = range_end
		text.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		var ink := "dark"
		if spec is Dictionary:
			ink = spec.get("ink", "dark")
		text.modulate = Color(content().ink[ink])
		text.set_meta("plate_m", entry.labels[label_id].plate_m)
		text.set_meta("base", overrides.get(label_id, spec.get("text", "") if spec is Dictionary else String(spec)))
		holder.add_child(text)
		_render_label(node, label_id)

## The words a label shows: its base text, then the bound lamp's or part's word on a second line.
static func _label_text(node: Node3D, label_id: String, base: String) -> String:
	var spec = prop_content(node.get_meta("eclipse_prop")).get("labels", {}).get(label_id, "")
	if not (spec is Dictionary) or not spec.has("bind"):
		return base
	var state: Dictionary = node.get_meta(STATE_META)
	var word := ""
	if spec.bind.has("lamp"):
		var lamp_state: String = state.lamps.get(spec.bind.lamp, "")
		if lamp_state != "":
			word = spec.get("words", {}).get(lamp_state, content().lamp_states[lamp_state].word)
	elif spec.bind.has("part"):
		var position: String = str(state.parts.get(spec.bind.part, ""))
		word = spec.get("words", {}).get(position, position.to_upper())
	if base == "":
		return word
	return base if word == "" else base + "\n" + word

static func _render_label(node: Node3D, label_id: String) -> void:
	var text := label(node, label_id)
	if text == null:
		return
	var shown := _label_text(node, label_id, text.get_meta("base"))
	text.text = shown
	_fit(text, shown)

## Sizes a Label3D to its plate: lines fill about 75 % of the plate height, narrowed when a line would overrun.
static func _fit(text: Label3D, shown: String) -> void:
	var plate: Array = text.get_meta("plate_m")
	var lines := shown.split("\n")
	var longest := 1
	for line in lines:
		longest = maxi(longest, line.length())
	var by_height := float(plate[1]) * 0.75 / (lines.size() * LABEL_FONT_SIZE * 1.15)
	var by_width := float(plate[0]) * 0.9 / (longest * LABEL_FONT_SIZE * 0.62)
	text.pixel_size = minf(by_height, by_width)

## Replaces the base text of one label (a preset or the puzzle may rename a plate); bound words still follow it.
static func set_label(node: Node3D, label_id: String, text: String) -> void:
	var l := label(node, label_id)
	if l != null:
		l.set_meta("base", text)
		_render_label(node, label_id)

## Shows or hides the text on one plate (the blank plate itself stays).
static func set_label_visible(node: Node3D, label_id: String, shown: bool) -> void:
	var l := label(node, label_id)
	if l != null:
		l.visible = shown

# ----------------------------------------------------------------------------------------------- lamps and parts

static func _lamp_material(state: String) -> StandardMaterial3D:
	if not _lamp_materials.has(state):
		var spec: Dictionary = content().lamp_states[state]
		var mat := StandardMaterial3D.new()
		mat.resource_name = "Lamp_" + state
		var color := Color(spec.color)
		mat.roughness = 0.25
		if float(spec.energy) > 0.0:
			mat.albedo_color = color.lerp(Color.WHITE, 0.15)
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = float(spec.energy)
		else:
			mat.albedo_color = color
		_lamp_materials[state] = mat
	return _lamp_materials[state]

## Lights lamp lamp_id with a state from the content's lamp_states (off, ok, warn, fault, info, rec) in both LODs,
## and updates every label bound to it, so the state is always words as well as colour.
static func set_lamp(node: Node3D, lamp_id: String, state: String) -> void:
	if not content().lamp_states.has(state):
		push_error("EclipseProps: unknown lamp state " + state)
		return
	for lamp in nodes_named(node, "Lamp_" + lamp_id):
		(lamp as GeometryInstance3D).material_override = _lamp_material(state)
	node.get_meta(STATE_META).lamps[lamp_id] = state
	_refresh_bound(node, "lamp", lamp_id)

## The lamp's current state name ("" before any was set).
static func lamp_state(node: Node3D, lamp_id: String) -> String:
	return node.get_meta(STATE_META).lamps.get(lamp_id, "")

## Moves part part_id to a named position from the catalogue (or a raw value in degrees or metres) in both LODs:
## rot_x / rot_y / rot_z set that rotation, move_z offsets the part from its rest position.
static func set_part(node: Node3D, part_id: String, position) -> void:
	var meta: Dictionary = prop(node.get_meta("eclipse_prop")).get("parts", {}).get(part_id, {})
	if meta.is_empty():
		push_error("EclipseProps: unknown part " + part_id)
		return
	var value := 0.0
	if position is String:
		if not meta.positions.has(position):
			push_error("EclipseProps: part %s has no position %s" % [part_id, position])
			return
		value = float(meta.positions[position])
	else:
		value = float(position)
	for part in nodes_named(node, part_id):
		var p := part as Node3D
		if not p.has_meta("rest_position"):
			p.set_meta("rest_position", p.position)
		match String(meta.axis):
			"rot_x":
				p.rotation_degrees = Vector3(value, 0, 0)
			"rot_y":
				p.rotation_degrees = Vector3(0, value, 0)
			"rot_z":
				p.rotation_degrees = Vector3(0, 0, value)
			"move_z":
				p.position = p.get_meta("rest_position") + Vector3(0, 0, value)
	node.get_meta(STATE_META).parts[part_id] = position
	_refresh_bound(node, "part", part_id)

## The part's current named position (or raw value) as last set.
static func part_position(node: Node3D, part_id: String):
	return node.get_meta(STATE_META).parts.get(part_id, "")

static func _refresh_bound(node: Node3D, kind: String, id: String) -> void:
	var labels: Dictionary = prop_content(node.get_meta("eclipse_prop")).get("labels", {})
	for label_id in labels:
		var spec = labels[label_id]
		if spec is Dictionary and spec.has("bind") and spec.bind.get(kind, "") == id:
			_render_label(node, label_id)

## Shows or hides a named part (Kai's marker tape, a run's end cap) in both LODs.
static func set_part_visible(node: Node3D, part_id: String, shown: bool) -> void:
	for part in nodes_named(node, part_id):
		(part as Node3D).visible = shown

## Tints a part's mesh (the card and tag bands) while keeping the kit textures: albedo colour multiplies them.
static func set_tint(node: Node3D, part_id: String, color: Color) -> void:
	for part in nodes_named(node, part_id):
		for mesh in part.find_children("*", "MeshInstance3D", true, false):
			var mi := mesh as MeshInstance3D
			for s in mi.mesh.get_surface_count():
				var base := mi.mesh.surface_get_material(s) as StandardMaterial3D
				if base != null:
					var tinted := base.duplicate() as StandardMaterial3D
					tinted.albedo_color = color
					mi.set_surface_override_material(s, tinted)

# ----------------------------------------------------------------------------------------------- lights

## Turns a guide-light or flood prop on or off: the lens part glows and real lights are added (guide: small omni
## lights along the channel; flood: a spot light at Socket_Light). Other props ignore it.
static func set_light(node: Node3D, on: bool) -> void:
	var id: String = node.get_meta("eclipse_prop")
	var kind: String = prop_content(id).get("light", "")
	if kind == "":
		return
	var spec: Dictionary = content().lights[kind]
	var lens_part := "Diffuser" if kind == "guide" else "Lens"
	for part in nodes_named(node, lens_part):
		for mesh in part.find_children("*", "MeshInstance3D", true, false):
			var mi := mesh as MeshInstance3D
			if on:
				var glow := StandardMaterial3D.new()
				glow.resource_name = "LightLens_on"
				glow.albedo_color = Color(spec.lens_color)
				glow.emission_enabled = true
				glow.emission = Color(spec.lens_color)
				glow.emission_energy_multiplier = float(spec.lens_energy)
				mi.material_override = glow
			else:
				mi.material_override = null
	# take away what an earlier call added: the guide's light row, the flood's spot
	var holder := node.get_node_or_null("Lights")
	if holder != null:
		node.remove_child(holder)
		holder.free()
	var at := socket(node, "Light")
	var old_spot := at.get_node_or_null("FloodSpot") if at != null else null
	if old_spot != null:
		at.remove_child(old_spot)
		old_spot.free()
	node.set_meta("light_on", on)
	if not on:
		return
	if kind == "guide":
		# small amber omni lights spaced along the diffuser (its mesh gives the length and the line's position)
		holder = Node3D.new()
		holder.name = "Lights"
		node.add_child(holder)
		var lod0 := node.get_node_or_null("LOD0")
		var diffuser: Node3D = lod0.find_child("Diffuser", true, false) as Node3D if lod0 != null else null
		if diffuser == null or diffuser.get_child_count() == 0:
			return
		var lens: MeshInstance3D = diffuser.get_child(0) as MeshInstance3D
		var to_prop: Transform3D = node.global_transform.affine_inverse() * lens.global_transform if node.is_inside_tree() else _local_transform(lens, node)
		var strip: AABB = to_prop * lens.get_aabb()
		var count := maxi(1, int(round(strip.size.x / float(spec.spacing_m))))
		for k in count:
			var omni := OmniLight3D.new()
			omni.light_color = Color(spec.omni_color)
			omni.light_energy = float(spec.omni_energy)
			omni.omni_range = float(spec.omni_range_m)
			omni.shadow_enabled = false
			omni.position = Vector3(strip.position.x + strip.size.x * (k + 0.5) / count, strip.get_center().y, strip.position.z - 0.06)
			holder.add_child(omni)
	elif at != null:
		var spot := SpotLight3D.new()
		spot.name = "FloodSpot"
		spot.light_color = Color(spec.spot_color)
		spot.light_energy = float(spec.spot_energy)
		spot.spot_range = float(spec.spot_range_m)
		spot.spot_angle = float(spec.spot_angle_deg)
		spot.shadow_enabled = true
		# the socket is a child of the tilted head, whose -Z looks out of the lens; a SpotLight3D shines along -Z
		at.add_child(spot)

static func _local_transform(leaf: Node3D, ancestor: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var current: Node = leaf
	while current != null and current != ancestor:
		if current is Node3D:
			xf = (current as Node3D).transform * xf
		current = current.get_parent()
	return xf

# ----------------------------------------------------------------------------------------------- presets

## The preset names of a prop, in authored order.
static func states(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for name in prop_content(id).get("states", {}):
		out.append(name)
	return out

## Applies a named visual preset (lamps, part positions, visibility, label visibility and text, light on/off, and
## the words on any attached text screen).
static func apply_state(node: Node3D, state_name: String) -> void:
	var preset: Dictionary = prop_content(node.get_meta("eclipse_prop")).get("states", {}).get(state_name, {})
	if preset.is_empty():
		push_error("EclipseProps: unknown state " + state_name)
		return
	for lamp_id in preset.get("lamps", {}):
		set_lamp(node, lamp_id, preset.lamps[lamp_id])
	for part_id in preset.get("parts", {}):
		set_part(node, part_id, preset.parts[part_id])
	for part_id in preset.get("visible", {}):
		set_part_visible(node, part_id, bool(preset.visible[part_id]))
	for label_id in preset.get("label_visible", {}):
		set_label_visible(node, label_id, bool(preset.label_visible[label_id]))
	for label_id in preset.get("labels", {}):
		set_label(node, label_id, preset.labels[label_id])
	if preset.has("light"):
		set_light(node, bool(preset.light))
	for screen_id in preset.get("screens", {}):
		set_screen_text(node, screen_id, preset.screens[screen_id])
	node.set_meta("eclipse_state", state_name)

# ----------------------------------------------------------------------------------------------- board

## Fills an allocation board: the five segment cards in their slots (precharge to recovery, left to right) and,
## for a named layout from the content (e.g. the P-11 accepted plan), one service tag per listed cell. Returns the
## cards and tags it placed. The board's segment lamps follow the layout's state preset when one has the same name.
static func populate_board(board: Node3D, layout_name: String = "") -> Array[Node3D]:
	var placed: Array[Node3D] = []
	var cards := variant_ids("PR_SegmentCard")
	for k in cards.size():
		var slot := socket(board, "Card_%d" % (k + 1))
		if slot != null:
			var card := instance("PR_SegmentCard", false, 1, cards[k])
			slot.add_child(card)
			placed.append(card)
	if layout_name == "":
		return placed
	var layout: Dictionary = prop_content("PR_EclipseBoard").get("layouts", {}).get(layout_name, {})
	for cell in layout.get("tags", {}):
		var at := socket(board, cell)
		if at != null:
			var tag := instance("PR_ServiceTag", false, 1, layout.tags[cell])
			at.add_child(tag)
			placed.append(tag)
	if prop_content("PR_EclipseBoard").get("states", {}).has(layout_name):
		apply_state(board, layout_name)
	return placed

# ----------------------------------------------------------------------------------------------- screens

## The live-UI surfaces of a prop: [{mesh, surface, name}] for every surface whose material is named Screen*;
## name is the screen id (Main, Forecast, F2Current) taken from the Screen_<id> node.
static func screen_surfaces(node: Node3D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mesh in node.find_children("Screen_*", "MeshInstance3D", true, false):
		var mi := mesh as MeshInstance3D
		for surface in mi.mesh.get_surface_count():
			var material := mi.get_active_material(surface)
			if material != null and material.resource_name.begins_with(SCREEN_MATERIAL):
				out.append({"mesh": mi, "surface": surface, "name": String(mi.name).trim_prefix("Screen_")})
	return out

## Shows a SubViewport's picture on screen screen_id in every LOD: unshaded, so it reads as a lit display.
static func show_viewport(node: Node3D, screen_id: String, viewport: SubViewport) -> void:
	var mat := StandardMaterial3D.new()
	mat.resource_name = "Screen_live"
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = viewport.get_texture()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for slot in screen_surfaces(node):
		if slot.name == screen_id:
			(slot.mesh as MeshInstance3D).set_surface_override_material(slot.surface, mat)

## A plain text display on screen screen_id (status rows, a forecast line, a current readout): light text on the
## navy console colour, rendered once into a SubViewport sized to the screen's aspect. Returns the Label to update
## (call refresh_text_screen after changing it).
static func attach_text_screen(node: Node3D, screen_id: String, text: String, height_px: int = 256) -> Label:
	var meta: Dictionary = prop(node.get_meta("eclipse_prop")).get("screens", {}).get(screen_id, {})
	if meta.is_empty():
		push_error("EclipseProps: unknown screen " + screen_id)
		return null
	var aspect := float(meta.size_m[0]) / float(meta.size_m[1])
	var viewport := SubViewport.new()
	viewport.name = "ScreenView_" + screen_id
	viewport.size = Vector2i(int(height_px * aspect), height_px)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var back := ColorRect.new()
	back.color = Color("#0b1220")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(back)
	var text_label := Label.new()
	text_label.name = "Text"
	text_label.text = text
	text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_label.offset_left = height_px * 0.08
	text_label.offset_right = -height_px * 0.08
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_color_override("font_color", Color("#d9f2ff"))
	text_label.add_theme_font_size_override("font_size", _screen_font_px(text, viewport.size))
	text_label.add_theme_constant_override("line_spacing", 0)
	viewport.add_child(text_label)
	node.add_child(viewport)
	show_viewport(node, screen_id, viewport)
	if not node.has_meta("text_screens"):
		node.set_meta("text_screens", {})
	node.get_meta("text_screens")[screen_id] = text_label
	return text_label

## Replaces the words on an attached text screen and re-renders it.
static func set_screen_text(node: Node3D, screen_id: String, text: String) -> void:
	var text_label: Label = node.get_meta("text_screens", {}).get(screen_id)
	if text_label != null:
		text_label.text = text
		refresh_text_screen(text_label)

## Re-renders a text screen after its Label changed (and refits the font to the new text).
static func refresh_text_screen(text_label: Label) -> void:
	var viewport := text_label.get_parent() as SubViewport
	if viewport != null:
		text_label.add_theme_font_size_override("font_size", _screen_font_px(text_label.text, viewport.size))
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

## The largest font size at which every line fits the screen: by height (lines) and by width (longest line).
static func _screen_font_px(text: String, area: Vector2i) -> int:
	var lines := text.split("\n")
	var longest := 1
	for line in lines:
		longest = maxi(longest, line.length())
	var by_height := area.y * 0.78 / (lines.size() * 1.25)
	var by_width := area.x * 0.84 / (longest * 0.58)
	return maxi(8, int(minf(by_height, by_width)))

## The monitor's live picture: the filtered camera view with the labelled Earth-limb inset
## (monitor/eclipse_monitor_screen.gd) in a 1152 x 648 SubViewport on Screen_Main. Returns the screen Control,
## whose set_phase / set_mode / set_logged / show_inset calls drive it.
static func attach_monitor_screen(monitor: Node3D, size: Vector2i = Vector2i(1152, 648)) -> Control:
	var viewport := SubViewport.new()
	viewport.name = "MonitorView"
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var screen := (load(MONITOR_SCREEN) as GDScript).new() as Control
	screen.name = "EclipseMonitorScreen"
	screen.size = Vector2(size)
	viewport.add_child(screen)
	monitor.add_child(viewport)
	show_viewport(monitor, "Main", viewport)
	return screen
