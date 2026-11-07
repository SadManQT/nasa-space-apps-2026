## M3-8A: catalogue and instancing helpers for the Chapter 8 pieces (EN_MalapertSummit and EN_RelayRoad).
## The catalogues (malapert_summit.json, relay_road.json) are written by production/tools/build_chapter8_assets.py.
##   var deck := Chapter8Assets.instance("EN_MalapertSummit_RelayDeck")   # LOD0 + LOD1 with visibility ranges
##   Chapter8Assets.set_lamp(housing, "Lamp_Status_0", Color(1.0, 0.55, 0.1))   # amber; Color.BLACK = off
## Presentation only: no gameplay values live here.
extends RefCounted

const CATALOGUES := {
	"EN_MalapertSummit": "res://assets/environment/EN_MalapertSummit/malapert_summit.json",
	"EN_RelayRoad": "res://assets/environment/EN_RelayRoad/relay_road.json",
}

static func catalog(set_name: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(CATALOGUES[set_name])
	var data: Variant = JSON.parse_string(text)
	return data if data is Dictionary else {}

static func entry(id: String) -> Dictionary:
	var set_name := "EN_MalapertSummit" if id.begins_with("EN_MalapertSummit") else "EN_RelayRoad"
	for piece in catalog(set_name).get("pieces", []):
		if piece.id == id:
			return piece
	return {}

## A Node3D holding LOD0 (near, with collision) and LOD1 (far, no collision) that meet at the catalogue distance.
static func instance(id: String) -> Node3D:
	var item := entry(id)
	var holder := Node3D.new()
	holder.name = id
	var distance := float(item.get("lod_distance_m", 25.0))
	for lod in 2:
		var scene := load(item.lods[lod]) as PackedScene
		var node := scene.instantiate() as Node3D
		node.name = "LOD%d" % lod
		holder.add_child(node)
		for mesh in node.find_children("*", "MeshInstance3D", true, false):
			var mi := mesh as MeshInstance3D
			mi.visibility_range_begin = 0.0 if lod == 0 else distance
			mi.visibility_range_end = distance if lod == 0 else 0.0
	return holder

## Every surface (mesh, index) whose material is named slot, across both LODs.
static func surfaces(node: Node, slot: String) -> Array:
	var out := []
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s)
			if mat != null and mat.resource_name == slot:
				out.append([mi, s])
	return out

## Lights or darkens a lamp slot (Color.BLACK = off); returns how many surfaces changed.
static func set_lamp(node: Node, slot: String, colour: Color, strength: float = 4.0) -> int:
	var found := surfaces(node, slot)
	for pair in found:
		var mi: MeshInstance3D = pair[0]
		var base := mi.mesh.surface_get_material(pair[1]) as StandardMaterial3D
		var mat := base.duplicate() as StandardMaterial3D
		mat.emission_enabled = colour != Color.BLACK
		mat.emission = colour
		mat.emission_energy_multiplier = strength
		mi.set_surface_override_material(pair[1], mat)
	return found.size()

## Puts a texture (a SubViewport's, for live UI) on a screen slot; returns how many surfaces changed.
static func set_screen(node: Node, slot: String, texture: Texture2D) -> int:
	var found := surfaces(node, slot)
	for pair in found:
		var mi: MeshInstance3D = pair[0]
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = texture
		mat.emission_enabled = true
		mat.emission_texture = texture
		mat.emission_energy_multiplier = 1.2
		mi.set_surface_override_material(pair[1], mat)
	return found.size()

## Unit vector toward azimuth/elevation in a room whose -Z is local north and +X local east (Moon sites).
static func sky_direction(az_deg: float, el_deg: float) -> Vector3:
	var az := deg_to_rad(az_deg)
	var el := deg_to_rad(el_deg)
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
