## M3-3A: the cadet helmet with a role stripe. PR_Helmet_Roles.glb is one helmet (the visually approved PR_Helmet
## with a separate "RoleStripe" material slot, a hinged "Visor" child and the approved flag and Aurora patch decals);
## helmet_roles.json beside it holds every per-cadet value: stripe colour, fit scale and where the helmet sits on that
## cadet's fitted EVA suit (CH_<Name>_EVA), measured by production/tools/fit_helmets_eva.py. Gameplay never bakes a
## colour: apply_role() overrides the stripe surface's material at runtime. equip() seats the helmet on the suit's
## neck ring in the rest pose and lets the Head bone (equip_bone) carry it, so the face stays inside in every clip, and
## tucks a ponytail away.
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
	if AssetGeometry.is_prepared(SCENE_PATH):
		var prepared := AssetGeometry.load_glb(SCENE_PATH)
		if prepared != null:
			return prepared
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

## Where a role's helmet sits on its EVA suit in the rest pose: scale and the base centre (equip_origin_m), in the
## suit's skeleton space (Godot axes). Identity for an unknown role.
static func equip_transform(role_id: String) -> Transform3D:
	var roles: Dictionary = data().roles
	if not roles.has(role_id):
		return Transform3D.IDENTITY
	var origin: Array = roles[role_id].equip_origin_m
	return Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * float(roles[role_id].scale)), Vector3(origin[0], origin[1], origin[2]))

## Puts a (role-coloured) helmet on a cadet's EVA suit: a BoneAttachment3D on equip_bone carries it, offset so that in
## the rest pose it sits at equip_transform(); the bones in tuck_bones (a ponytail) shrink to nothing inside it.
## Returns the attachment (free it to take the helmet off and call untuck()), or null without a skeleton or bone.
static func equip(helmet: Node3D, suit: Node, role_id: String) -> BoneAttachment3D:
	var skeleton := suit.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null or not data().roles.has(role_id):
		return null
	var bone := _bone(skeleton, String(data().get("equip_bone", "Head")))
	if bone < 0:
		return null
	var attachment := BoneAttachment3D.new()
	attachment.name = "HelmetMount"
	skeleton.add_child(attachment)
	attachment.bone_name = skeleton.get_bone_name(bone)
	if helmet.get_parent() != null:
		helmet.get_parent().remove_child(helmet)
	attachment.add_child(helmet)
	helmet.transform = skeleton.get_bone_global_rest(bone).affine_inverse() * equip_transform(role_id)
	for name in data().get("tuck_bones", []):
		var tuck := _bone(skeleton, String(name))
		if tuck >= 0:
			skeleton.set_bone_pose_scale(tuck, Vector3.ONE * 0.001)
	return attachment

## Lets a tucked ponytail out again after the helmet comes off.
static func untuck(suit: Node) -> void:
	var skeleton := suit.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		return
	for name in data().get("tuck_bones", []):
		var tuck := _bone(skeleton, String(name))
		if tuck >= 0:
			skeleton.set_bone_pose_scale(tuck, Vector3.ONE)

static func _bone(skeleton: Skeleton3D, suffix: String) -> int:
	for i in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(i)
		if name == suffix or name.ends_with("_" + suffix) or name.ends_with(":" + suffix):
			return i
	return -1
