# Run: Godot --headless --path game --script res://tools/test_hair_springs.gd
extends SceneTree

var _checks := 0
var _failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root := Node3D.new()
	var skeleton := Skeleton3D.new()
	root.add_child(skeleton)
	var head := skeleton.add_bone("mixamorig_Head")
	var neck := skeleton.add_bone("mixamorig_Neck")
	skeleton.set_bone_parent(neck, head)
	var back := skeleton.add_bone("mixamorig_Spine2")
	var pony1 := skeleton.add_bone("mixamorig_Ponytail1")
	var pony2 := skeleton.add_bone("mixamorig_Ponytail2")
	var pony3 := skeleton.add_bone("mixamorig_Ponytail3")
	skeleton.set_bone_parent(pony1, head)
	skeleton.set_bone_parent(pony2, pony1)
	skeleton.set_bone_parent(pony3, pony2)
	var apron := skeleton.add_bone("ApronRoot")
	var strap := skeleton.add_bone("StrapLeft")
	skeleton.set_bone_parent(apron, back)
	skeleton.set_bone_parent(strap, back)
	var springs := HairSprings.new()
	root.add_child(springs)
	get_root().add_child(root)
	var result: Dictionary = springs.build(skeleton)
	_check(int(result["chains"]) == 3, "groups Ponytail, Apron and Strap bones into spring chains")
	_check(springs.simulator != null and springs.simulator.get_setting_count() == 3, "creates one configured SpringBoneSimulator3D setting per chain")
	_check(int(result["collisions"]) == 3 and springs.collisions.size() == 3, "adds head, neck and upper-back collision spheres")
	_check(springs.simulator.get_stiffness(0) >= 0.0 and springs.simulator.get_stiffness(0) <= 1.0, "spring stiffness is bounded for gentle follow-through")
	var missing := HairSprings.new()
	root.add_child(missing)
	var empty: Dictionary = missing.build()
	_check(int(empty["chains"]) == 0, "missing skeleton is harmless")
	print("PASS HairSprings (%d checks, %d chains)" % [_checks, int(result["chains"])])
	root.free()
	quit(1 if _failures > 0 else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  ok ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
