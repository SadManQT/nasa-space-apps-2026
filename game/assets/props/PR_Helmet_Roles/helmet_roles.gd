## M3-3A: the cadet helmet with a role stripe. PR_Helmet_Roles.glb is one helmet (the visually approved PR_Helmet
## with a separate "RoleStripe" material slot, a hinged "Visor" child and the approved flag and Aurora patch decals);
## helmet_roles.json beside it holds every per-cadet value: stripe colour, fit scale and the offset from the Head bone.
## Gameplay never bakes a colour: apply_role() overrides the stripe surface's material at runtime.
extends RefCounted

const SCENE_PATH := "res://assets/props/PR_Helmet_Roles/PR_Helmet_Roles.glb"
const DATA_PATH := "res://assets/props/PR_Helmet_Roles/helmet_roles.json"
static var _data: Dictionary = {}

## The whole data file: stripe material name, visor node and angle, sockets, interior clearance and the roles table.
static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _data

## The role ids in file order (kai, amara, mei, rafi, ferreira).
static func role_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for key in data().roles:
		out.append(key)
	return out

## Instances the helmet scene; returns null (with an error) if the GLB is missing.
static func instance() -> Node3D:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("HelmetRoles: missing " + SCENE_PATH)
		return null
	return packed.instantiate() as Node3D

## The stripe surfaces of a helmet node: [{mesh: MeshInstance3D, surface: int}] for every surface whose material is
## named after data().stripe_material ("RoleStripe").
static func stripe_surfaces(node: Node3D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var wanted := String(data().get("stripe_material", "RoleStripe"))
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var instance_mesh := mesh as MeshInstance3D
		if instance_mesh.mesh == null:
			continue
		for surface in instance_mesh.mesh.get_surface_count():
			var material := instance_mesh.get_active_material(surface)
			if material != null and material.resource_name.begins_with(wanted):
				out.append({"mesh": instance_mesh, "surface": surface})
	return out

## Colours the stripe for a role and scales the helmet to that cadet's fit (helmet_roles.json). Returns false for an
## unknown role id. The scale keeps the pivot at the helmet base, so a stored helmet still stands on its shelf.
static func apply_role(node: Node3D, role_id: String) -> bool:
	var roles: Dictionary = data().roles
	if not roles.has(role_id):
		push_error("HelmetRoles: unknown role " + role_id)
		return false
	var role: Dictionary = roles[role_id]
	var rgb: Array = role.stripe_rgb
	var material := StandardMaterial3D.new()
	material.resource_name = String(data().get("stripe_material", "RoleStripe")) + "_" + role_id
	material.albedo_color = Color(rgb[0], rgb[1], rgb[2])
	material.roughness = 0.45
	for slot in stripe_surfaces(node):
		slot.mesh.set_surface_override_material(slot.surface, material)
	node.scale = Vector3.ONE * float(role.scale)
	node.set_meta("role_id", role_id)
	return true

## Lowers (1) or raises (0) the sun visor: the Visor child rotates about its hinge (+X) by the data file's angle.
static func set_visor_closed(node: Node3D, fraction: float) -> void:
	var angle := float(data().get("visor_closed_rotation_deg_x", 78.0))
	for visor in node.find_children(String(data().get("visor_node", "Visor")), "Node3D", true, false):
		(visor as Node3D).rotation_degrees = Vector3(angle * clampf(fraction, 0.0, 1.0), 0.0, 0.0)

## The transform that parents a role's helmet to a cadet's Head bone: the base of the neck ring sits 3 cm below the
## Neck bone and the shell is centred on the head (measured on the installed v8 bodies; values in helmet_roles.json).
static func equip_transform(role_id: String) -> Transform3D:
	var roles: Dictionary = data().roles
	if not roles.has(role_id):
		return Transform3D.IDENTITY
	var offset: Array = roles[role_id].equip_offset_from_head_bone_m
	var scale := float(roles[role_id].scale)
	return Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), Vector3(offset[0], offset[1], offset[2]))
