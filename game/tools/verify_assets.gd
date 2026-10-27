# Loads every GLB under res://assets and prints one JSON line per asset with what Godot sees:
# triangles, bones, animation clips (and how many loop), size (metres, Y up), lowest point, largest texture,
# and any load failure.
#   Godot --headless --path game --script res://tools/verify_assets.gd
# production/tools/verify_gate.py compares these numbers with each asset's spec.
extends SceneTree

func _init() -> void:
	for path in _glbs("res://assets"):
		var r := {"file": path.get_file().get_basename(), "loaded": false}
		var packed := load(path) as PackedScene
		if packed != null:
			var root := packed.instantiate()
			var tris := 0
			var max_tex := 0
			var box := AABB()
			var first := true
			for m in root.find_children("*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				var xf := _global_xform(mi)
				var aabb := xf * mi.get_aabb()
				box = aabb if first else box.merge(aabb)
				first = false
				for s in mi.mesh.get_surface_count():
					tris += mi.mesh.surface_get_array_index_len(s) / 3
					var mat := mi.mesh.surface_get_material(s) as BaseMaterial3D
					if mat:
						for t in [mat.albedo_texture, mat.normal_texture, mat.roughness_texture, mat.metallic_texture, mat.orm_texture if mat is ORMMaterial3D else null]:
							if t:
								max_tex = max(max_tex, max(t.get_width(), t.get_height()))
			var bones := 0
			for sk in root.find_children("*", "Skeleton3D", true, false):
				bones += (sk as Skeleton3D).get_bone_count()
			var anims := 0
			var loops := 0
			for ap in root.find_children("*", "AnimationPlayer", true, false):
				for n in (ap as AnimationPlayer).get_animation_list():
					anims += 1
					if (ap as AnimationPlayer).get_animation(n).loop_mode != Animation.LOOP_NONE:
						loops += 1
			r = {"file": r.file, "loaded": not first, "tris": tris, "bones": bones, "anims": anims, "loops": loops,
				"size": [snappedf(box.size.x, 0.001), snappedf(box.size.y, 0.001), snappedf(box.size.z, 0.001)],
				"min_y": snappedf(box.position.y, 0.001), "max_tex": max_tex}
			root.free()
		print("ASSET ", JSON.stringify(r))
	quit()

func _global_xform(n: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p is Node3D:
		xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf

func _glbs(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".glb"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_glbs(dir.path_join(d)))
	return out
