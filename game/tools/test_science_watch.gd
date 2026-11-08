extends SceneTree

const Knowledge = preload("res://scripts/dialogue/knowledge_service.gd")
const Content = preload("res://scripts/content/content_loader.gd")
const Campaign = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var capture := false

func _init() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("science-watch") or (capture and not storage.prepare_rendering_cache()):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	_test_selection()
	_test_unlocks()
	await _test_campaign()
	storage.cleanup()
	print("SCIENCE WATCH RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _ids(entries: Array) -> Array:
	return entries.map(func(entry): return entry.id)

func _test_selection() -> void:
	var path := "res://scripts/ui/science_explainers.gd"
	_check(FileAccess.file_exists(path), "shared registered science selection exists")
	if not FileAccess.file_exists(path):
		return
	var clips = load(path)
	var required := ["sci_crew_needs", "sci_polar_sun", "sci_solar_power"]
	_check(_ids(clips.matching(["EX-M0101"], ["jpl_horizons_pole_season"])) == required, "EX-M0101 matches exactly three required explainers, deduplicated")
	_check(_ids(clips.matching([], ["bvad_2022_metabolic"])) == ["sci_crew_needs"], "fixture source overlap works without current mission injection")
	_check(clips.matching(["unknown"], ["missing"]).is_empty() and clips.matching().is_empty(), "unknown and empty cards show no invented clips")
	_check(_ids(clips.matching(["P-01"])).has("sci_plant_growth"), "puzzle references match the registry")
	var copy: Array = clips.matching(["EX-M0101"])
	copy[0].title = "changed"
	_check(clips.matching(["EX-M0101"])[0].title != "changed", "registry callers cannot mutate cached records")

func _test_unlocks() -> void:
	for snapshot in [{}, {"scene_id": "EX-CH99-S99", "mission_id": "EX-M0804"}, {"scene_id": "bad", "completed_scene_ids": "bad", "acquired_evidence_ids": ["EX-CH99-S99"]}]:
		_check(Knowledge.journal(snapshot).tabs.get("science", {}).get("entries", []).is_empty(), "unknown/malformed scene IDs unlock no science")
	var snapshot := {"scene_id": "EX-CH01-S01"}
	var before := snapshot.duplicate(true)
	var journal: Dictionary = Knowledge.journal(snapshot)
	var entries: Array = journal.tabs.get("science", {}).get("entries", [])
	_check(_ids(entries) == ["sci_crew_needs", "sci_plant_growth", "sci_polar_sun", "sci_solar_power"], "reached mission unlocks its explicit and puzzle clips only")
	_check(journal.tabs.get("science", {}).get("chapters", []).size() == 1 and journal.counts.get("science", 0) == 4, "science groups and counts reached Chapter 1")
	_check(snapshot == before and Knowledge.journal(snapshot) == journal, "Journal Science is pure and deterministic")
	snapshot = {"scene_id": "EX-CH08-S01", "completed_scene_ids": ["EX-CH01-S01"], "acquired_evidence_ids": ["EX-CH04-S04"]}
	journal = Knowledge.journal(snapshot)
	var chapters: Array = journal.tabs.get("science", {}).get("chapters", [])
	_check(chapters.map(func(chapter): return chapter.number) == [1, 4, 8], "current, completed and acquired scenes unlock actual reached chapters without filling gaps")
	entries = journal.tabs.get("science", {}).get("entries", [])
	_check(_ids(entries).count("sci_solar_power") == 1 and not _ids(entries).has("sci_cotton_moon"), "clips deduplicate across missions while future clips remain hidden")
	_check(not JSON.stringify(journal.tabs.get("science", {})).contains("sci_red_ring"), "unreached chapter names remain hidden even with later current scene")
	var all_scenes: Array = Content.load_full().scenes.map(func(scene): return scene.id)
	entries = Knowledge.journal({"completed_scene_ids": all_scenes}).tabs.get("science", {}).get("entries", [])
	_check(entries.size() == 18 and not _ids(entries).has("sci_low_gravity"), "all reached missions unlock all 18 mission-linked science clips, excluding trainer-only clip")

func _test_campaign() -> void:
	var campaign = Campaign.instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	if campaign.loading:
		await campaign.wait_loading()
	await process_frame
	var panels = campaign.hud.panels
	var player = panels.hint_player
	player.seen_path = storage.directory.path_join("seen.cfg")
	panels.open_panel("sources")
	var mission_button = panels.find_child("MissionDataCard", true, false)
	_check(mission_button is Button, "real Sources offers the current mission data card")
	if not mission_button is Button:
		campaign.free()
		return
	mission_button.pressed.emit()
	await process_frame
	_check(panels.active_panel() == "data_card" and _text(panels).contains("Give the Station a Crew") and not _text(panels).contains("Source pending"), "Sources opens the real mission card")
	var buttons: Array = panels._body.find_children("Watch_*", "Button", true, false)
	_check(buttons.size() == 3, "real EX-M0101 card has its three Watch buttons")
	for large in [false, true]:
		panels.set_accessibility({"large_text": large, "reduced_motion": false})
		await process_frame
		await process_frame
		await _shot("mission_card" + ("_150" if large else ""))
		var watch = panels.find_child("Watch_sci_polar_sun", true, false)
		watch.grab_focus()
		var before: Dictionary = campaign.director.snapshot()
		var checkpoint = campaign.director.get("_checkpoint").duplicate(true)
		var position_before: Vector3 = campaign._player.global_position
		var levels: Dictionary = player._levels.duplicate(true)
		if large:
			_click(watch)
		else:
			_send_key(KEY_ENTER)
		await process_frame
		_check(player.is_open() and player.mode == "watch" and player.video.stream.resource_path.ends_with("sci_polar_sun.ogv"), "Watch opens registered polar Sun media at large=%s" % large)
		_check(player.find_child("NextHint", true, false) == null and player.find_child("BackToHowTo", true, false) == null, "Watch has no hint or teaching navigation")
		_check(not panels._panel.visible and campaign.director.query().paused, "Watch owns the visible modal while campaign stays paused")
		if capture:
			await _wait_video(player, 5.0)
			await _shot("playing" + ("_150" if large else ""))
		player.toggle_pause()
		var position: float = player.video.stream_position
		await create_timer(0.15).timeout
		_check(player.video.paused and player.video.stream_position == position, "Pause freezes real playback")
		await _shot("paused" + ("_150" if large else ""))
		player.replay()
		_check(not player.video.paused and player.video.is_playing(), "Replay restarts the real stream")
		_send_key(KEY_TAB)
		await process_frame
		_check(player.is_ancestor_of(root.gui_get_focus_owner()), "keyboard stays in Watch")
		_send_pad(JOY_BUTTON_DPAD_DOWN)
		await process_frame
		_check(player.is_ancestor_of(root.gui_get_focus_owner()), "controller focus stays in Watch")
		_check(root.get_visible_rect().encloses(player._frame.get_global_rect()), "Watch frame fits at both text scales")
		for button in player._frame.find_children("*", "Button", true, false):
			_check(button.size.x >= 44 and button.size.y >= 44, "Watch controls meet house target size")
		_send_key(KEY_E)
		_send_key(KEY_SPACE)
		Input.action_press("move_forward")
		await create_timer(0.15).timeout
		Input.action_release("move_forward")
		_check(campaign._player.global_position.is_equal_approx(position_before), "held movement cannot move the avatar through Watch")
		_send_key(KEY_ESCAPE)
		await process_frame
		_check(not player.is_open() and panels.active_panel() == "data_card" and panels._panel.visible and campaign.director.query().paused, "Esc returns to the still-paused card")
		_check(root.gui_get_focus_owner() == watch, "closing Watch restores its source button")
		_check(player._levels == levels and not FileAccess.file_exists(player.seen_path), "Watch never changes hint progress or HowTo persistence")
		_check(campaign.director.snapshot() == before and campaign.director.get("_checkpoint") == checkpoint, "reading and blocked game input preserve all campaign state and checkpoint")
	panels.set_accessibility({"large_text": true, "reduced_motion": true})
	panels.find_child("Watch_sci_polar_sun", true, false).pressed.emit()
	await create_timer(0.2).timeout
	_check(player.find_child("PauseClip", true, false) == null and player.find_child("StillCaptions", true, false) != null, "reduced motion uses still and transcript without motion controls")
	if capture:
		var deadline := Time.get_ticks_msec() + 12000
		while player._still_pending and Time.get_ticks_msec() < deadline:
			await process_frame
		_check(player.video.paused and player.video.modulate.a == 1.0 and player._has_visible_frame(), "native reduced motion exposes a real decoded science still")
		await _shot("still_150")
	_send_pad(JOY_BUTTON_B)
	await process_frame
	_check(not player.is_open() and panels.active_panel() == "data_card", "controller B returns from reduced motion to card")
	panels.set_accessibility({"large_text": false, "reduced_motion": false})
	panels.open_journal("science")
	await process_frame
	_check(panels.journal_tab() == "science" and panels.find_child("Tab_science", true, false) != null, "Journal exposes Science alongside the four original tabs")
	var watch = panels.find_child("Watch_sci_solar_power", true, false)
	_check(watch is Button and _text(panels).contains("Chapter 1") and not _text(panels).contains("Chapter 2"), "Journal shows reached chapter and watchable clips, hiding future chapters")
	var seen := ConfigFile.new()
	seen.set_value("seen", "mission_table", true)
	_check(seen.save(player.seen_path) == OK, "existing house teaching preference fixture saves")
	var teaching_before := FileAccess.get_file_as_string(player.seen_path)
	watch.grab_focus()
	watch.pressed.emit()
	_send_key(KEY_ESCAPE)
	await process_frame
	_check(root.gui_get_focus_owner() == watch and panels.journal_tab() == "science" and campaign.director.query().paused, "Journal Watch returns focus to same Science entry while paused")
	_check(FileAccess.get_file_as_string(player.seen_path) == teaching_before and player.has_seen("mission_table"), "Journal Watch preserves existing HowTo preference bytes")
	DirAccess.remove_absolute(player.seen_path)
	await _shot("journal")
	if capture:
		var snapshot: Dictionary = campaign.director.snapshot()
		snapshot.completed_scene_ids = ["EX-CH01-S01", "EX-CH04-S01", "EX-CH08-S01"]
		panels.open_journal("science", Knowledge.journal(snapshot))
		await process_frame
		await _shot("journal_chapters")
		panels.set_accessibility({"large_text": true})
		await _shot("journal_chapters_150")
		panels._scroll.scroll_vertical = int(panels._scroll.get_v_scroll_bar().max_value)
		await _shot("journal_chapters_end_150")
	for mission_id in ["EX-M0702", "EX-M0803"]:
		panels.open_panel("data_card", {"mission_id": mission_id})
		var words := _text(panels._body)
		_check(not words.contains("S6") and not words.contains("E3") and not words.contains("L2"), "mission prose uses plain shielding and bearing names " + mission_id)
		if mission_id == "EX-M0702":
			_check(words.contains("Four units of water plus two crate units give the best shelter, shielding level 6."), "shielding prose preserves level six")
		else:
			_check(words.contains("lock the local bearing 2 and the Earth bearing 3") and words.contains("local link (2) and the Earth link (3)"), "relay prose preserves both numbered bearing presets")
	panels.close_panel()
	player.watch("unregistered")
	_check(not player.is_open(), "unknown clip does not open an invented player")
	_check(not campaign.director.query().paused, "closing final reader resumes campaign")
	campaign.free()

func _wait_video(player: Control, time: float) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while player.video.stream_position < time and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(player.video.stream_position >= time, "native decoder reaches requested science content")

func _shot(label: String) -> void:
	if not capture:
		return
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-72_%s.png" % label)
	_check(root.get_texture().get_image().save_png(path) == OK, "native screenshot " + label)
	print("M1-72 SCREENSHOT: ", path)

func _text(node: Node) -> String:
	var text: String = node.text + "\n" if node is Label or node is Button else ""
	for child in node.get_children():
		if not child is CanvasItem or child.visible:
			text += _text(child)
	return text

func _click(button: Control) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_rect().get_center()
	event.button_index = MOUSE_BUTTON_LEFT
	for pressed in [true, false]:
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func _send_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	for pressed in [true, false]:
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func _send_pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + label)
