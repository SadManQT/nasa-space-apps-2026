extends SceneTree

const TrainerScene = preload("res://scripts/trainer/mission_trainer.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var failures := 0
var checks := 0

func _init() -> void:
	if not storage.setup("hint-player"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var trainer = TrainerScene.new()
	trainer.results_path = storage.directory.path_join("trainer.json")
	root.add_child(trainer)
	await _test_trainer_first_use(trainer)
	trainer.select_scenario("P-02")
	trainer.open_decision()
	await process_frame
	var hint = trainer.table.find_child("Hint", true, false)
	_check(hint is Button, "actual shared table always offers Hint without opening More")
	if not hint is Button:
		_finish(trainer)
		return
	var player = trainer.panels.hint_player
	if player.is_open():
		_check(player.mode == "how_to", "first available table use teaches with HowToCard")
		player.close()
		DirAccess.remove_absolute(player.seen_path)
	hint.grab_focus()
	var before = trainer.exercise.director().snapshot()
	var plan = trainer.exercise.mission_table().plan_for_gate(trainer.exercise.current_gate()).duplicate(true)
	for level in range(1, 4):
		hint.pressed.emit()
		await process_frame
		_check(player.is_open() and player.level == level, "one request opens level %d" % level)
		var text = _text(player)
		_check(not text.contains("heatCOOL") and not text.contains("Use worked") and not text.contains("Dry must read 0, wet 100, then fill both to 50"), "level %d never leaks own answer or copies a plan" % level)
		if level == 1:
			_check(player.highlight_target != null and player.highlight_target.name.begins_with("Row_"), "nudge highlights the actual shared table control")
		if level == 2:
			_check(player.video.stream != null and player.video.is_playing(), "level two plays an actual registered clip")
			player.toggle_pause()
			_check(player.video.paused, "Pause controls real playback")
			player.replay()
			_check(not player.video.paused and player.video.stream_position < 1.0, "Replay restarts actual clip")
			player.video.paused = true
			player.update_caption(5.0)
			_check(not player.caption.text.is_empty(), "timed registered captions are rendered")
			player.set_settings({"captions": false})
			_check(not player.caption.visible, "captions setting controls clip captions")
			player.set_settings({"captions": true})
		if level == 3:
			_check(text.contains("Different example") and text.contains("9") and text.contains("3"), "worked method labels its different hypothetical numbers")
		for key in [KEY_SPACE]:
			_send_key(key)
			await process_frame
			_check(trainer.table.is_open() and not trainer.table._confirming, "nested Space never locks in a plan")
		_send_pad(JOY_BUTTON_Y)
		await process_frame
		_check(not trainer.table._confirming, "nested controller Y never reaches table")
		_send_pad(JOY_BUTTON_B)
		await process_frame
		_check(not player.is_open() and trainer.table.is_open(), "controller B closes only the hint")
		_check(root.gui_get_focus_owner() == hint, "closing hint restores original table focus")
	_check(trainer.exercise.director().snapshot() == before and trainer.exercise.mission_table().plan_for_gate(trainer.exercise.current_gate()) == plan, "all hint levels preserve station, rewards and plan")
	hint.pressed.emit()
	_check(player.level == 3, "reopening after three requests keeps worked method")
	player.close()
	# A missing registered concept must say so, rather than replay unrelated media.
	player.request_hint("missing", {"nudge": "Look at the reading.", "clip": "absent", "relationship": "Compare before and after.", "example": "Different example: 9 minus 3 leaves 6."})
	player.close()
	player.request_hint("missing", {"nudge": "Look at the reading.", "clip": "absent", "relationship": "Compare before and after.", "example": "Different example: 9 minus 3 leaves 6."})
	_check(player.video.stream == null and _text(player).contains("Clip unavailable") and _text(player).contains("Compare before and after"), "missing clip gives honest teaching text")
	_send_key(KEY_ESCAPE)
	await process_frame
	_check(not player.is_open() and trainer.table.is_open(), "Esc closes only nested hint")
	# Actual legacy More surface must no longer disclose canonical worked plans.
	trainer.exercise.mission_table().next_hint()
	trainer.exercise.mission_table().next_hint()
	trainer.exercise.mission_table().next_hint()
	trainer.table._more = true
	trainer.table._render()
	_check(not _text(trainer.table).contains("Use worked") and not _text(trainer.table).contains("heatCOOL"), "More never exposes the legacy answer ladder")
	for request in 3:
		player.request_hint("probe", HowToCard.lesson("probe"))
		_check(not _text(player).contains("50") and not _text(player).contains("Dry must read 0, wet 100"), "probe level %d excludes its own calibration/planting answer" % (request + 1))
		player.close()
	await _test_action_layout(player)
	await _test_storage_and_still(player)
	await _test_alarm(trainer)
	await _test_campaign()
	_finish(trainer)

func _test_action_layout(player: Control) -> void:
	for large in [false, true]:
		player.set_settings({"large_text": large})
		player.request_hint("layout-%s" % large, HowToCard.lesson("mission_table"))
		await process_frame
		await process_frame
		var next: Button = player.find_child("NextHint", true, false)
		var text_width := next.get_theme_font("font").get_string_size(next.text, HORIZONTAL_ALIGNMENT_LEFT, -1, next.get_theme_font_size("font_size")).x
		_check(next.size.x >= text_width and next.size.y < 80, "request action displays a whole readable line large=%s" % large)
		_check(player._scroll.size.y >= player._body.get_combined_minimum_size().y, "one-line nudge is visible rather than pushed offscreen large=%s" % large)
		player.close()
		player.request_hint("layout-%s" % large, HowToCard.lesson("mission_table"))
		await process_frame
		await process_frame
		for id in ["NextHint", "CloseHint", "PauseClip", "ReplayClip"]:
			var button: Button = player.find_child(id, true, false)
			var width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			_check(button.size.x >= width and button.size.y >= 44 and button.size.y < 80, "%s remains a readable action large=%s" % [id, large])
		var picture: Rect2 = player.video.get_global_rect()
		_check(picture.size.y >= 180 and is_equal_approx(picture.size.x / picture.size.y, 16.0 / 9.0) and player._scroll.get_global_rect().encloses(picture), "whole 16:9 clip is visible in the body large=%s" % large)
		player.close()
	player.show_how_to("mission_table")
	(player.find_child("HowToClip", true, false) as Button).pressed.emit()
	_check(_text(player).contains("Concept - How to plan a shift") and not _text(player).contains("Hint 0 of 3"), "How to concept has an honest heading independent of hint progress")
	player.close()

func _test_storage_and_still(player: Control) -> void:
	var path: String = storage.directory.path_join("how-to.cfg")
	player.seen_path = path
	player.show_how_to("mission_table", true)
	_check(player.is_open() and not player.has_seen("mission_table"), "unseen first-time card is shown")
	player.close()
	_check(player.has_seen("mission_table"), "reading stores a device-only validated seen flag")
	player.show_how_to("mission_table", true)
	_check(not player.is_open(), "seen first-time card does not interrupt again")
	player.show_how_to("mission_table")
	_check(player.is_open(), "How to can always be replayed")
	player.close()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('[seen]\nmission_table="not a boolean"\n')
	file.close()
	var malformed := FileAccess.get_file_as_bytes(path)
	player.show_how_to("mission_table", true)
	player.close()
	_check(not player.has_seen("mission_table") and FileAccess.get_file_as_bytes(path) == malformed, "malformed seen preferences remain preserved and playable")
	player.seen_path = storage.directory.path_join("absent/how-to.cfg")
	player.show_how_to("mission_table", true)
	player.close()
	_check(not player.is_open() and not player.has_seen("mission_table"), "write failure stays playable without falsely marking seen")
	player.seen_path = path
	player.set_settings({"captions": true, "large_text": true, "reduced_motion": true})
	var lesson = HowToCard.lesson("mission_table")
	player.request_hint("still", lesson)
	player.close()
	player.request_hint("still", lesson)
	_check(player._still_target == float(player._entry.captions[0].start), "still target comes from the registered first scientific caption")
	for frame in 8:
		await process_frame
	_check(player.video.modulate.a == 0.0, "headless allocated texture cannot be exposed as a decoded still")
	await create_timer(0.15).timeout
	_check(player.video.paused and player.video.modulate.a == 0.0 and _text(player).contains("Still unavailable"), "failed still decode stays hidden and offers honest text fallback")
	var position = player.video.stream_position
	await create_timer(0.15).timeout
	_check(player.video.stream_position == position and player.find_child("PauseClip", true, false) == null and player.find_child("StillCaptions", true, false) != null, "still remains frozen and caption cards replace motion controls")
	_check(root.get_visible_rect().encloses(player._frame.get_global_rect()) and root.get_visible_rect().encloses(player.find_child("CloseHint", true, false).get_global_rect()), "150 percent reader and fixed close fit 720p: frame=%s close=%s view=%s" % [player._frame.get_global_rect(), player.find_child("CloseHint", true, false).get_global_rect(), root.get_visible_rect()])
	for step in 9:
		var tab := InputEventAction.new()
		tab.action = "ui_focus_next"
		tab.pressed = true
		Input.parse_input_event(tab)
		Input.flush_buffered_events()
		await process_frame
		_check(player.is_ancestor_of(root.gui_get_focus_owner()), "nested keyboard focus stays in hint %d" % step)
	player.set_settings({"captions": false})
	_check(not player.find_child("StillCaptions", true, false).visible, "captions off hides reduced-motion transcript")
	player.close()
	player.set_settings({"large_text": false, "reduced_motion": false, "captions": true})
	DirAccess.remove_absolute(path)

func _test_alarm(trainer: Control) -> void:
	var fixture = preload("res://tools/support/trainer_fixture.gd")
	fixture.prepare(trainer.exercise, "GOLDEN")
	for gate in 3:
		fixture.share(trainer.exercise)
		var id: String = trainer.exercise.current_gate()
		_check(trainer.exercise.commit_gate(id, trainer.exercise.mission_table().plan_for_gate(id), trainer.exercise.director().query().state_revision).accepted, "real prerequisite commit %d" % gate)
	trainer.exercise.mission_table().reset_alarm_task()
	trainer.table.open(trainer.exercise, trainer.exercise.current_gate(), {"timer_free": false})
	trainer.table.choose(5, "action", "PUMP")
	_check(trainer.table.start_task().accepted and trainer.table._task_time_left == 15.0, "real unassisted PUMP starts its fifteen-second alarm clock")
	var clock: float = trainer.table._task_time_left
	var before: Dictionary = trainer.exercise.director().snapshot()
	var checkpoint: Dictionary = trainer.exercise.director().get("_checkpoint").duplicate(true)
	var table_before: Dictionary = trainer.exercise.mission_table().snapshot()
	trainer.table.reveal_hint()
	trainer.table._process(4.0)
	await create_timer(0.1).timeout
	_check(trainer.table._task_time_left == clock, "both real frame time and explicit tick leave nested alarm clock frozen")
	trainer.panels.hint_player.close()
	clock = trainer.table._task_time_left
	trainer.panels.hint_player.show_how_to("mission_table", true)
	_check(trainer.panels.hint_player.is_open() and trainer.panels.hint_player.mode == "how_to", "alarm test actually opens first-use teaching after closing the hint")
	trainer.table._process(4.0)
	await create_timer(0.1).timeout
	_check(trainer.table._task_time_left == clock, "actual How to freezes the alarm clock")
	trainer.panels.hint_player.close()
	trainer.panels.hint_player.show_how_to("mission_table")
	_check(trainer.panels.hint_player.is_open() and trainer.panels.hint_player.mode == "how_to", "alarm test actually replays the same teaching card")
	trainer.table._process(4.0)
	_check(trainer.table._task_time_left == clock, "replayed How to also freezes the alarm clock")
	trainer.panels.hint_player.close()
	_check(trainer.exercise.director().snapshot() == before and trainer.exercise.director().get("_checkpoint") == checkpoint and trainer.exercise.mission_table().snapshot() == table_before, "hint and teaching preserve resources, receipts, rollback checkpoint and alarm state")
	trainer.table._process(1.0)
	_check(trainer.table._task_time_left < clock, "closing hint resumes the table's own clock")
	trainer.table.close()
	DirAccess.remove_absolute(trainer.panels.hint_player.seen_path)

func _test_campaign() -> void:
	CampaignCutscenePlayer.autoplay = false
	var campaign = preload("res://scenes/campaign/chapter1_campaign.tscn").instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	if campaign.loading:
		await campaign.wait_loading()
	await process_frame
	var hud = campaign.hud
	var player = hud.panels.hint_player
	player.seen_path = storage.directory.path_join("campaign-how-to.cfg")
	hud.panels.open_panel("what_now")
	var before: Dictionary = campaign.director.snapshot()
	var checkpoint: Dictionary = campaign.director.get("_checkpoint").duplicate(true)
	var button = hud.find_child("WhatNowHint", true, false)
	button.grab_focus()
	button.pressed.emit()
	await process_frame
	_check(player.is_open() and player.level == 1 and campaign.director.query().paused, "actual What now opens same paused nudge")
	_check(_text(player).contains("Follow the arrow after the battery is full."), "What now preserves the scene's authored safe H1 clue")
	_send_key(KEY_ESCAPE)
	await process_frame
	_check(not player.is_open() and hud.panels.active_panel() == "what_now" and campaign.director.query().paused, "nested Esc keeps What now and authoritative pause")
	_check(root.gui_get_focus_owner() == button, "What now request regains focus")
	hud.panels.close_panel()
	_check(not campaign.director.query().paused, "only last reading surface resumes campaign")
	hud.panels.open_journal("now")
	(hud.panels.find_child("RevealHint", true, false) as Button).pressed.emit()
	_check(player.level == 2 and _text(player).contains("full store") and _text(player).contains("spare"), "S01 Journal H2 explains the full-store spare-power relationship")
	_check(player.video != null and player.video.stream != null and player.video.stream.resource_path.ends_with("sci_solar_power.ogv"), "S01 H2 selects the registered solar-power/battery explainer")
	if player.video != null and player.video.stream != null:
		player.video.paused = true
		# Look the line up in the registry: narration re-times clips, so no fixed second.
		var spill_at := 20.0
		var registry = JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign/content/explainers.json"))
		for clip in registry.get("explainers", []):
			if String(clip.get("id", "")) == "sci_solar_power":
				for line in clip.get("captions", []):
					if String(line.get("text", "")).contains("extra power spills"):
						spill_at = float(line.get("start", 20.0)) + 0.5
		player.update_caption(spill_at)
		_check(player.caption.text.contains("extra power spills"), "S01 registered clip actually explains full-store overflow")
	player.close()
	(hud.panels.find_child("RevealHint", true, false) as Button).pressed.emit()
	var worked := _text(player)
	_check(player.level == 3 and worked.contains("Different example") and worked.contains("12") and worked.contains("5") and worked.contains("3") and worked.contains("2") and worked.contains("battery"), "S01 H3 works through a different full-store routing example")
	_check(not worked.contains("practice lamp is lit") and not worked.contains("air_tank") and not worked.contains("grow_lights") and not worked.contains("20 energy units") and not worked.contains("8 energy units"), "S01 worked method excludes unrelated evidence lesson and canonical settings")
	player.close()
	hud.panels.close_panel()
	campaign.set_ui_paused(true)
	hud.panels.open_panel("what_now")
	button.pressed.emit()
	player.close()
	hud.panels.close_panel()
	_check(campaign.director.query().paused, "pre-existing paused state survives all reading overlays")
	_check(campaign.director.get("_checkpoint") == checkpoint and campaign.director.snapshot().resources == before.resources, "actual campaign reading never resets checkpoint or resources")
	campaign.set_ui_paused(false)
	await _test_campaign_first_use(campaign)
	campaign.free()

func _test_trainer_first_use(trainer: Control) -> void:
	for dismissal in ["Close", "Esc", "B"]:
		trainer.select_scenario("P-02")
		trainer.panels.hint_player.seen_path = storage.directory.path_join("trainer-first-%s.cfg" % dismissal)
		trainer.open_decision()
		await _dismiss_first_use(trainer.panels.hint_player, trainer.table, "trainer " + dismissal, dismissal)
		trainer.table.close()
		DirAccess.remove_absolute(trainer.panels.hint_player.seen_path)

func _test_campaign_first_use(campaign: Node) -> void:
	campaign.route.start_at("EX-CH01-S07")
	campaign._sync_route_projection()
	campaign._refresh_world()
	if campaign.loading:
		await campaign.wait_loading()
	campaign.route.perform("role_cards")
	campaign.hud.refresh_scene()
	for dismissal in ["Close", "Esc", "B"]:
		var player = campaign.hud.panels.hint_player
		player.seen_path = storage.directory.path_join("campaign-first-%s.cfg" % dismissal)
		_check(campaign.hud.open_mission_table("p02_shift1"), "campaign first-use table opens " + dismissal)
		await _dismiss_first_use(player, campaign.hud.mission_table, "campaign " + dismissal, dismissal)
		_check(campaign.director.query().paused, "first-use dismissal preserves open-table authoritative pause " + dismissal)
		campaign.hud.mission_table.close()
		DirAccess.remove_absolute(player.seen_path)

func _dismiss_first_use(player: Control, table: Control, label: String, dismissal: String) -> void:
	await process_frame
	await process_frame
	_check(player.is_open() and player.mode == "how_to", label + " automatic first-use teaching really opens")
	if dismissal == "Close":
		(player.find_child("CloseHint", true, false) as Button).pressed.emit()
	elif dismissal == "Esc":
		_send_key(KEY_ESCAPE)
	else:
		_send_pad(JOY_BUTTON_B)
	await process_frame
	await process_frame
	_check(not player.is_open() and table.is_open() and _table_has_focus(table), label + " dismissal restores visible enabled table focus without a manual grab")
	var initial := root.gui_get_focus_owner()
	var tab := InputEventAction.new()
	tab.action = "ui_focus_next"
	tab.pressed = true
	Input.parse_input_event(tab)
	Input.flush_buffered_events()
	await process_frame
	_check(_table_has_focus(table) and root.gui_get_focus_owner() != initial, label + " keyboard Tab navigates from restored table focus")
	var keyboard := root.gui_get_focus_owner()
	_send_pad(JOY_BUTTON_DPAD_RIGHT)
	await process_frame
	_check(_table_has_focus(table) and root.gui_get_focus_owner() != keyboard, label + " controller direction navigates inside the table")

func _table_has_focus(table: Control) -> bool:
	var focus := root.gui_get_focus_owner()
	return is_instance_valid(focus) and table.is_ancestor_of(focus) and focus.is_visible_in_tree() and focus.focus_mode != Control.FOCUS_NONE and not (focus is BaseButton and focus.disabled)

func _finish(trainer: Control) -> void:
	trainer.free()
	DirAccess.remove_absolute(storage.directory.path_join("trainer.json"))
	storage.cleanup()
	print("HINT PLAYER RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _text(node: Node) -> String:
	var text: String = node.text + "\n" if node is Label or node is Button else ""
	for child in node.get_children():
		if not child is CanvasItem or child.visible:
			text += _text(child)
	return text

func _send_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
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
