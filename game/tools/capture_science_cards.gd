## M1-44: capture the actual source-card panel in an on-top window, without a save.
## Run production/qa/evidence/M1-44_capture.sh after importing the project.
extends SceneTree

const Panels = preload("res://scenes/ui/campaign_panels.tscn")
var failures := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	var panels := Panels.instantiate()
	root.add_child(panels)
	panels.bind_query({"source_puzzle_ids": ["P-02"]})
	for entry in [
		["jpl_horizons_ch1_sky", "sky_card"],
		["goes13_protons_2017_09", "storm_card"],
		["fast_plants_lifecycle", "plants_card"],
	]:
		panels.open_panel("data_card", {"source_id": entry[0]})
		await _capture(entry[1])
	panels.set_accessibility({"large_text": true})
	panels.open_panel("data_card", {"source_id": "jpl_horizons_ch1_sky"})
	await _capture("sky_card_large_text")
	panels.free()
	print("SCIENCE CARD CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-44_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	print("M1-44 evidence: ", path, " (", error, ")")
