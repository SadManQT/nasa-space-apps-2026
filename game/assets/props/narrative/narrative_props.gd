## M3-99: the narrative props (label holders, named mugs, gear-wheel tool tag, drawer-lid note, working-stock
## envelope) and their words. The GLBs carry no text (ART_BIBLE §7); this helper draws every word from
## narrative_props_content.json as lit Label3D ink on the `Text_*` anchors, or letter by letter around a mug's
## `NameArc`, and applies a variant's band colour and tape. It only dresses props: scenes and rooms decide where
## they stand and when a variant changes (for example the mugs gaining names at the end of EX-CH01-S12).
extends RefCounted

const CATALOG_PATH := "res://assets/props/narrative/narrative_props.json"
const CONTENT_PATH := "res://assets/props/narrative/narrative_props_content.json"
const TEXT_ROOT := "NarrativeText"
const VARIANT_META := "narrative_variant"
static var _catalog: Dictionary = {}
static var _content: Dictionary = {}
static var _fonts: Dictionary = {}

## The generated catalogue (production/concept/narrative_props/build_runtime_assets.py): plants and props with
## path, triangles, size, anchors and the mug's arc radius.
static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return _catalog

## The authored words, fonts, colours and variants.
static func content() -> Dictionary:
	if _content.is_empty():
		_content = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	return _content

## Every narrative prop id, in catalogue order.
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for entry in catalog().props:
		out.append(String(entry.id))
	return out

## The catalogue entry of a prop or stage-variant plant, or an empty dictionary.
static func entry(id: String) -> Dictionary:
	for group in ["props", "plants"]:
		for item in catalog().get(group, []):
			if String(item.id) == id:
				return item
	return {}

## The variant ids of a prop, in authored order (the first is not always the default; see default_variant).
static func variant_ids(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for v in content().props.get(id, {}).get("variants", []):
		out.append(String(v.id))
	return out

## The variant a fresh instance shows.
static func default_variant(id: String) -> String:
	return String(content().props.get(id, {}).get("default", ""))

## The authored lines of one variant, exactly as they are drawn.
static func text_lines(id: String, variant: String) -> PackedStringArray:
	var out := PackedStringArray()
	for line in _variant(id, variant).get("lines", []):
		out.append(String(line.text))
	return out

## Loads a prop through the shared room loader and applies a variant (default when empty). Null if unknown.
static func instance(id: String, variant: String = "") -> Node3D:
	var item := entry(id)
	if item.is_empty() or String(item.get("kind", "")) != "prop":
		push_error("Unknown narrative prop: " + id)
		return null
	var node := AssetGeometry.load_glb(String(item.path))
	if node == null:
		return null
	node.name = id
	node.set_meta("narrative_prop", id)
	apply_variant(node, variant if not variant.is_empty() else default_variant(id))
	return node

## Re-dresses an instanced prop: removes its old words, shows the variant's tape, colours its band and draws its
## lines. Returns false for an unknown variant (the prop keeps what it showed).
static func apply_variant(node: Node3D, variant: String) -> bool:
	var id := String(node.get_meta("narrative_prop", node.name))
	var spec: Dictionary = content().props.get(id, {})
	var v := _variant(id, variant)
	if spec.is_empty() or v.is_empty():
		push_error("Unknown narrative prop variant: %s/%s" % [id, variant])
		return false
	var anchor := node.find_child(String(spec.anchor), true, false) as Node3D
	if anchor == null:
		push_error("Narrative prop %s has no anchor %s" % [id, spec.anchor])
		return false
	var old := anchor.get_node_or_null(TEXT_ROOT)
	if old != null:
		anchor.remove_child(old)
		old.free()
	for tape in node.find_children("Tape_*", "MeshInstance3D", true, false):
		(tape as MeshInstance3D).visible = String(tape.name) == String(v.get("tape", ""))
	if spec.has("band_node"):
		var band := node.find_child(String(spec.band_node), true, false) as MeshInstance3D
		if band != null:
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(String(v.get("band", "#FFFFFF")))
			material.roughness = 0.5
			band.material_override = material
	var root := Node3D.new()
	root.name = TEXT_ROOT
	anchor.add_child(root)
	var lines: Array = v.get("lines", [])
	for i in lines.size():
		if bool(spec.get("arc", false)):
			_draw_arc(root, lines[i], entry(id))
		else:
			var label := _label(lines[i], String(lines[i].text))
			label.name = "Ink_%d" % i
			root.add_child(label)
	node.set_meta(VARIANT_META, variant)
	return true

## The variant a prop instance currently shows.
static func current_variant(node: Node3D) -> String:
	return String(node.get_meta(VARIANT_META, ""))

## The font for "hand" (Gochi Hand) or "print" (Barlow Semi Condensed); both SIL OFL 1.1, licences beside them.
static func font(kind: String) -> Font:
	if not _fonts.has(kind):
		_fonts[kind] = load(String(content().fonts[kind]))
	return _fonts[kind]

## World width of a line of text in metres, as drawn.
static func line_width_m(line: Dictionary) -> float:
	var px := int(content().font_px)
	return font(String(line.font)).get_string_size(String(line.text), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * float(line.size_m) / px

static func _variant(id: String, variant: String) -> Dictionary:
	for v in content().props.get(id, {}).get("variants", []):
		if String(v.id) == variant:
			return v
	return {}

static func _label(line: Dictionary, text: String) -> Label3D:
	var px := int(content().font_px)
	var label := Label3D.new()
	label.name = "Ink"
	label.text = text
	label.font = font(String(line.font))
	label.font_size = px
	label.pixel_size = float(line.size_m) / px
	label.outline_size = 0
	label.modulate = Color(String(line.color))
	label.shaded = true  # ink on a surface takes the room's light; it never glows
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS  # depth-sorted with the prop, no transparent sorting
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if String(line.get("align", "center")) == "left" else HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var offset: Array = line.get("offset", [0.0, 0.0])
	label.position = Vector3(float(offset[0]), float(offset[1]), float(content().lift_m))
	label.rotation.z = deg_to_rad(float(line.get("rotation_deg", 0.0)))
	return label

## Lays one line letter by letter around the mug wall: each glyph sits on the arc radius at its own angle, faces
## outwards and keeps the font's advance (kerning included), so long names like FERREIRA follow the curve.
static func _draw_arc(root: Node3D, line: Dictionary, item: Dictionary) -> void:
	var text := String(line.text)
	var px := int(content().font_px)
	var scale := float(line.size_m) / px
	var f := font(String(line.font))
	var radius := float(item.arc_radius_m) + float(content().lift_m)
	var tilt := -atan(float(item.get("arc_slope", 0.0)))
	var total := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * scale
	for i in text.length():
		var start := f.get_string_size(text.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * scale
		var advance := f.get_string_size(text.substr(0, i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * scale - start
		var angle := (start + advance * 0.5 - total * 0.5) / radius
		var glyph := _label(line, text[i])
		glyph.name = "Ink_%d" % i  # unique names: find_children("Ink*") must see every letter
		glyph.position = Vector3(radius * sin(angle), 0.0, radius * cos(angle))
		glyph.rotation = Vector3(tilt, angle, 0.0)
		root.add_child(glyph)
