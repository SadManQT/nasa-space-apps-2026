## M1-61: integrated caption layout, settings, expiry and UI sound filtering.
## Add -- --capture to save windowed evidence using the same probes and isolated save.
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var checks := 0
var failures := 0
var probes := {}
var capture := false

func _init() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("M1-61-sound-captions"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await _settle()
	var audio := campaign.audio
	var hud := campaign.hud
	_check(audio != null and hud != null, "campaign and audio initialise")
	if audio == null or hud == null:
		_finish()
		return
	var panel := audio.sound_caption.get_parent() as PanelContainer
	_check(panel != null, "sound text has a backing panel")
	_check(panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and audio.sound_caption.mouse_filter == Control.MOUSE_FILTER_IGNORE, "captions never intercept walking input")
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	_check(style != null and style.bg_color == UiDesign.colour("glass"), "panel uses house dark glass")
	_check(style.border_color == UiDesign.colour("glass_edge") and style.corner_radius_top_left == 12, "panel uses house edge and radius")
	_check(audio.sound_caption.get_theme_color("font_color") == UiDesign.colour("ivory"), "caption uses high contrast ivory")
	_check(is_equal_approx(audio.runtime.mix("sound_caption_s"), 3.0), "authored caption duration stays three seconds")
	for row in CampaignAudioRuntime.read_metadata().audio.sfx:
		if row.bus == "UI":
			_check(String(row.caption).is_empty(), String(row.id) + " has no interface caption")
		elif String(row.id).begins_with("SFX_ALERT_") or row.id in ["SFX_DOOR_LATCH", "SFX_FAN_NORMAL", "SFX_RADIO_EARTH_LOST"]:
			_check(not String(row.caption).is_empty(), String(row.id) + " retains essential information")
	await _show_sound("SFX_FAN_NORMAL")
	_check(hud._dialogue_bar.visible, "real dialogue is visible")
	_check_layout("dialogue", true)
	await _screenshot("dialogue")
	var normal_font := audio.sound_caption.get_theme_font_size("font_size")
	hud.panels.set_accessibility({"large_text": true})
	hud.apply_accessibility()
	await _show_sound("SFX_FAN_NORMAL")
	_check(audio.sound_caption.get_theme_font_size("font_size") > normal_font, "caption follows large text setting")
	_check_layout("dialogue_large_text", true)
	await _screenshot("dialogue_large_text")
	var original_line := hud._caption_line.text
	var longest := original_line
	for line in campaign.content.get("dialogue", []):
		if String(line.get("text", "")).length() > longest.length():
			longest = String(line.text)
	hud._caption_line.text = longest
	for id in ["SFX_ALERT_PARTICLE", "SFX_DOOR_LATCH", "SFX_RADIO_EARTH_LOST"]:
		audio.call("_caption", audio.runtime.sfx_plan(id).caption)
	await _settle()
	_check_layout("longest_dialogue_simultaneous_large_text", true)
	hud._caption_line.text = original_line
	hud.panels.set_accessibility({"large_text": false})
	hud.apply_accessibility()
	# Complete only the isolated first scene's authored work, then acknowledge its lines.
	for target in Gates.targets_for_scene(campaign.route.current_scene_id()):
		hud.refresh_after_action(campaign.route.perform(String(target.target_id)))
	var guard := 0
	while hud._dialogue_bar.visible and not hud._next_line.disabled and guard < 20:
		hud._on_next_line()
		guard += 1
	await create_timer(0.3).timeout
	_check(not hud._dialogue_bar.visible, "walking has no dialogue bar")
	await _show_sound("SFX_FAN_NORMAL")
	_check_layout("walking", false)
	await _screenshot("walking")
	# An actual panel open plays confirm; it must not add text, including after closing.
	audio.set("_captions", [])
	hud.panels.open_panel("what_now")
	await _settle()
	_check(not panel.visible, "reading panel suppresses sound panel")
	hud.panels.close_panel()
	await _settle()
	_check((audio.get("_captions") as Array).is_empty() and not panel.visible, "panel confirm never creates a caption")
	for id in ["SFX_UI_CONFIRM", "SFX_UI_SOFT_ERROR", "SFX_UI_SHIFT_COMMIT"]:
		audio.call("_play_oneshot", audio.runtime.sfx_plan(id))
	await _settle()
	_check((audio.get("_captions") as Array).is_empty(), "playing interface sounds produces no captions")
	# Exercise the existing missing-media fallback, retaining the same essential cue.
	var missing := audio.runtime.sfx_plan("SFX_ALERT_PRESSURE")
	missing.media_present = false
	audio.call("_play_oneshot", missing)
	await _settle()
	_check(panel.visible and audio.sound_caption.text == missing.caption, "missing essential sound still has its caption")
	var items: Array = audio.get("_captions")
	var remaining := int(items[0].until) - Time.get_ticks_msec()
	_check(remaining > 2500 and remaining <= 3000, "essential cue receives the three second lifetime")
	hud.panels.set_accessibility({"captions": false})
	hud.apply_accessibility()
	await _settle()
	_check(not panel.visible and not audio.sound_caption.visible, "captions off hides text and glass")
	hud.panels.set_accessibility({"captions": true, "large_text": true})
	hud.apply_accessibility()
	await _show_sound("SFX_FAN_NORMAL")
	_check_layout("walking_large_text", false)
	await _screenshot("walking_large_text")
	for dimensions in [Vector2i(1920, 1080), Vector2i(1024, 768), Vector2i(2560, 1080)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _show_sound("SFX_FAN_NORMAL")
		_check_layout("walking_%dx%d" % [dimensions.x, dimensions.y], false)
	# Multiple simultaneous essential sounds wrap inside the glass at large text.
	for id in ["SFX_ALERT_PARTICLE", "SFX_DOOR_LATCH", "SFX_RADIO_EARTH_LOST"]:
		audio.call("_caption", audio.runtime.sfx_plan(id).caption)
	await _settle()
	_check_layout("simultaneous", false)
	_check(audio.sound_caption.text.contains("[particle warning]") and audio.sound_caption.text.contains("[Earth link lost]"), "simultaneous essential cues are retained")
	audio.set_cinematic(true)
	await _settle()
	_check(not panel.visible, "cinematic suppresses sound panel")
	audio.set_cinematic(false)
	await _show_sound("SFX_FAN_NORMAL")
	await create_timer(3.1).timeout
	_check(not panel.visible and audio.sound_caption.text.is_empty(), "expiry removes both text and backing panel")
	campaign.queue_free()
	await process_frame
	_finish()

func _show_sound(id: String) -> void:
	campaign.audio.set("_captions", [])
	campaign.audio.call("_caption", campaign.audio.runtime.sfx_plan(id).caption)
	await _settle()

func _settle() -> void:
	for frame in 8:
		await process_frame

func _check_layout(label: String, dialogue: bool) -> void:
	var audio := campaign.audio
	var panel := audio.sound_caption.get_parent() as Control
	var rect := panel.get_global_rect()
	var view := root.get_visible_rect().size
	_check(panel.is_visible_in_tree() and rect.size.x > 0 and rect.size.y > 0, label + " visible glass")
	_check(Rect2(Vector2.ZERO, view).encloses(rect), label + " inside viewport")
	_check(not rect.intersects(Rect2(view / 3.0, view / 3.0)), label + " clear centre third")
	_check(rect.encloses(audio.sound_caption.get_global_rect()), label + " text inside glass")
	_check(audio.sound_caption.get_visible_line_count() == audio.sound_caption.get_line_count(), label + " every cue line fits")
	if dialogue:
		var bar := campaign.hud._dialogue_bar.get_global_rect()
		_check(rect.end.y <= bar.position.y - UiDesign.px(8, view.y) + 1, label + " above actual dialogue")
	else:
		_check(absf(rect.end.y - (view.y - campaign.hud._margin())) <= 1, label + " at HUD bottom safe edge")

func _screenshot(label: String) -> void:
	if not capture:
		return
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-61_%s.png" % label)
	_check(root.get_texture().get_image().save_png(path) == OK, label + " screenshot saved")

func _check(ok: bool, label: String) -> void:
	checks += 1
	probes[label] = ok
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func _finish() -> void:
	if capture:
		var file := FileAccess.open("res://../production/qa/evidence/M1-61_probes.json", FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(probes, "\t") + "\n")
			file.close()
		else:
			failures += 1
	storage.cleanup()
	print("SOUND CAPTIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
