## Windowed M3-94 evidence: the three approved lines as a player sees them in the
## campaign HUD caption bar (voiced since M3-94R, 7 Nov 2026).
## Godot --path game --windowed --script res://tools/capture_m3_94_lines.gd
## Writes production/qa/evidence/M3-94_*.png and M3-94_capture_probes.json. A Godot
## exit code alone is never accepted: the last line must read M3-94 CAPTURE RESULT: PASS.
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const RELAY_FLAGS := ["noor_identity_revealed", "relay_local_verified", "relay_earth_verified"]

var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0
var probes := {}

func _init() -> void:
	# Stay on the caption bar; scene-entry films would cover it.
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("M3-94-capture"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	if campaign.hud == null or campaign.route == null:
		_probe("campaign_initializes", false)
		_finish()
		return
	_enter("EX-CH03-S10", [])
	await _show_line("EX-CH03-S10-L05", "Amara", "Forty-two.", "ch03_s10_amara_forty_two")
	_enter("EX-CH08-S10", ["noor_identity_revealed"])
	var closed: Array = campaign.current_dialogue().map(func(line) -> String: return String(line.get("id", "")))
	_probe("ch08_s10_channel_closed_hides_earth_lines", closed == ["EX-CH08-S10-L02", "EX-CH08-S10-L03", "EX-CH08-S10-L04"])
	_enter("EX-CH08-S10", RELAY_FLAGS)
	await _show_line("EX-CH08-S10-L05", "Rao", "Aurora, Earth. We hear you. Go ahead.", "ch08_s10_rao_channel_open")
	await _show_line("EX-CH08-S10-L06", "Noor", "You finished what we could not.", "ch08_s10_noor_reply")
	_finish()

## Moves the campaign to a scene with exactly these knowledge flags.
func _enter(scene_id: String, flags: Array) -> void:
	var snapshot := campaign.director.snapshot()
	snapshot.knowledge_flags = flags.duplicate()
	campaign.director.restore_snapshot(snapshot)
	campaign._start_extended(scene_id)
	campaign.hud.refresh_scene()

## Puts one line in the HUD caption bar, checks what it reads and screenshots it.
func _show_line(line_id: String, speaker: String, text: String, label: String) -> void:
	var lines: Array = campaign.current_dialogue()
	var index := -1
	for i in lines.size():
		if String(lines[i].get("id", "")) == line_id:
			index = i
	_probe(label + "_line_available", index >= 0)
	if index < 0:
		return
	campaign.hud._dialogue_index = index
	campaign.hud._render_caption()
	await process_frame
	_probe(label + "_caption_text", campaign.hud._caption_line.text == text)
	_probe(label + "_caption_speaker", campaign.hud._caption_speaker.text.begins_with(speaker))
	_probe(label + "_caption_on_screen", campaign.hud.get_viewport_rect().encloses(campaign.hud._caption_line.get_global_rect()))
	await _capture(label)

func _finish() -> void:
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M3-94_capture_probes.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures += 1
	else:
		file.store_string(JSON.stringify(probes, "\t"))
		file.close()
	campaign.free()
	storage.cleanup()
	print("M3-94 CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _probe(label: String, passed: bool) -> void:
	probes[label] = passed
	if not passed:
		failures += 1
	print("M3-94 probe: ", label, " = ", passed)

func _capture(label: String) -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var evidence_path := "production/qa/evidence/M3-94_%s.png" % label
	var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../" + evidence_path))
	if error != OK:
		failures += 1
	print("M3-94 evidence: ", evidence_path, " (", error, ")")
