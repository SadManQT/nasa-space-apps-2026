## Windowed M1-63 evidence: plays each registered science explainer in Godot and saves what the player sees.
##   Godot --path game --windowed --script res://tools/capture_explainers_m163.gd
extends SceneTree

const REGISTRY := "res://resources/campaign/content/explainers.json"
const TIMES := [3.0, 10.0, 20.0, 30.0, 42.0]
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(back)
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY)).get("explainers", [])
	for entry: Dictionary in entries:
		var player := VideoStreamPlayer.new()
		player.stream = load(String(entry["path"]))
		player.expand = true
		player.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(player)
		player.play()
		for t in TIMES:
			if t >= float(entry["length_s"]):
				continue
			var waited := 0
			while player.is_playing() and player.stream_position < t and waited < 24 * 60:
				await process_frame
				waited += 1
			await RenderingServer.frame_post_draw
			var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-63_%s_%02ds.png" % [entry["id"], int(t)])
			if root.get_texture().get_image().save_png(path) != OK:
				failures += 1
			print("M1-63 evidence: ", path)
		player.queue_free()
		await process_frame
	print("M1-63 CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
