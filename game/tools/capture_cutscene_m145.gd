## Windowed M1-45 evidence: plays the rebuilt CS-01 and CS-02 films through the campaign's own
## cutscene player and saves what the player sees at the exterior shot's timestamps.
## Run after the .ogv files are rebuilt (production/qa/evidence/M1-45_capture.sh does both):
##   Godot --path game --windowed --script res://tools/capture_cutscene_m145.gd
extends SceneTree

const FILMS := [
	["CS-01", "res://assets/cutscenes/CS-01_Arrival.ogv", [3.0, 6.0]],
	["CS-02", "res://assets/cutscenes/CS-02_The_Horizon_Closes_One_Door.ogv", [2.0, 5.0]],
]
var player: CampaignCutscenePlayer
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	player = CampaignCutscenePlayer.new()
	root.add_child(player)
	await process_frame
	for film in FILMS:
		if not ResourceLoader.exists(String(film[1])):
			print("M1-45 capture: missing ", film[1])
			failures += 1
			continue
		player.play({"mode": "video", "runtime_path": String(film[1]), "cutscene_id": String(film[0]), "title": ""})
		for t in film[2]:
			var waited := 0
			while player.is_active() and player.position_s() < float(t) and waited < 24 * 30:
				await process_frame
				waited += 1
			await _capture("%s_ingame_%ds" % [String(film[0]), int(t)])
		player.skip()
		await process_frame
	player.free()
	print("M1-45 CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-45_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	print("M1-45 evidence: ", path, " (", error, ")")
