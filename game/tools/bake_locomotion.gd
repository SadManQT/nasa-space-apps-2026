## Rebuild exact gait calibration after changing cast GLBs or measurement code.
## Godot --headless --path game --script res://tools/bake_locomotion.gd
extends SceneTree

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for id in ["Kai", "Amara", "Mei", "Rafi", "Ferreira", "Kai_EVA", "Amara_EVA", "Mei_EVA", "Rafi_EVA", "Ferreira_EVA"]:
		var path := "res://assets/characters/CH_%s/CH_%s.glb" % [id, id]
		var actor := AssetGeometry.load_glb(path)
		if actor == null:
			quit(1)
			return
		root.add_child(actor)
		var player := actor.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var skeleton := actor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var clips := LocomotionClips.new()
		# No source_path: deliberately run the reference analysis, never a bake.
		if not clips.prepare(player, skeleton):
			actor.free()
			quit(1)
			return
		var data := {"version": LocomotionClips.BAKE_VERSION, "source_sha256": FileAccess.get_sha256(path), "measurements": {}}
		for gait in clips.gaits:
			data.measurements[gait] = clips.measurements[gait]
		var output := FileAccess.open("res://resources/player/gaits/ch_%s.json" % id.to_lower(), FileAccess.WRITE)
		if output == null:
			actor.free()
			quit(1)
			return
		output.store_string(JSON.stringify(data, "\t", true, true) + "\n")
		actor.free()
		print("BAKE ", id, " OK")
	print("LOCOMOTION BAKE RESULT: PASS (10 characters)")
	quit()
