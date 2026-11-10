extends SceneTree
## Tests for M1-56: CommsService, CommsPanel, arrival toast suppression during dialogue,
## all 5 unlock triggers (scene_enter, scene_exit, mission_done, job_done, found),
## goal handoff, unread counts across the 5 threads, M key / Pause menu opening,
## and save/load/retry persistence via director.update_message_metadata.

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const CommsServiceScript = preload("res://scripts/comms/comms_service.gd")
const CommsPanelScript = preload("res://scripts/ui/comms_panel.gd")
const CAMPAIGN_SCENE: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var _checks := 0
var _failures := 0


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: %s" % label)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_service_and_unlock_triggers()
	await _test_hud_inbox_toasts_and_persistence()
	if _failures > 0:
		push_error("test_comms: %d/%d checks failed." % [_failures, _checks])
		quit(1)
		return
	print("COMMS RESULT: PASS (%d checks, 0 failures)" % _checks)
	quit(0)


func _test_service_and_unlock_triggers() -> void:
	var content: Dictionary = ContentScript.load_full()
	var director := DirectorScript.new()
	director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	var service := CommsServiceScript.new()
	service.setup(director, content, true)

	_check(service.total_loaded_count() >= 200, "CommsService loads ch00 fixture and all 8 campaign chapter message packs")
	_check(service.message_by_id("MSG-CH02-001").get("chapter", 0) == 2, "ch02.json message pack loaded")
	_check(service.message_by_id("MSG-CH03-001").get("chapter", 0) == 3, "ch03.json message pack loaded")
	_check(service.message_by_id("MSG-CH04-001").get("chapter", 0) == 4, "ch04.json message pack loaded")
	_check(service.is_delivered("MSG-CH00-001"), "ch00 scene_enter message unlocked at EX-CH01-S01")
	_check(service.is_delivered("MSG-CH01-001"), "ch01 scene_enter message MSG-CH01-001 unlocked at EX-CH01-S01")
	_check(not service.is_delivered("MSG-CH01-002"), "scene_exit message MSG-CH01-002 not yet unlocked before S01 exit")
	_check(not service.has_pending_toasts(), "Initial setup does not spam toasts for already-unlocked starting messages")

	# Check 5 threads view
	var threads := service.threads_view()
	_check(threads.size() == 5, "threads_view returns all 5 threads (crew, commander, earth, academy, archive)")
	_check(service.unread_count("academy") >= 1, "academy thread has unread message MSG-CH01-001")
	_check(service.unread_count("commander") >= 1, "commander thread has unread message MSG-CH00-001")

	# Check goal handoff from MSG-CH00-001 (goal=true)
	var goal_msg := service.latest_goal_message()
	_check(String(goal_msg.get("id", "")) == "MSG-CH00-001", "latest_goal_message returns unlocked goal=true message")

	# Test scene_exit unlock + arrival toast + goal handoff update
	var eval_exit := service.evaluate_unlocks({
		"current_scene_id": "EX-CH01-S02",
		"completed_scene_ids": ["EX-CH01-S01"],
	}, true)
	var newly_exit: Array = eval_exit.get("newly_unlocked", [])
	_check(newly_exit.has("MSG-CH00-002"), "scene_exit unlocks MSG-CH00-002")
	_check(newly_exit.has("MSG-CH01-002"), "scene_exit unlocks MSG-CH01-002")
	_check(newly_exit.has("MSG-CH01-003"), "scene_exit unlocks MSG-CH01-003")
	_check(service.has_pending_toasts(), "newly unlocked messages queue arrival toasts")

	var first_toast := service.pop_toast()
	_check(String(first_toast.get("text", "")).begins_with("New message · "), "arrival toast formatted with 'New message · <Sender>: <Subject>'")
	_check(not String(first_toast.get("text", "")).contains("MSG-"), "arrival toast never exposes internal message ID")

	var updated_goal := service.latest_goal_message()
	_check(String(updated_goal.get("id", "")) == "MSG-CH01-002", "latest_goal_message updates to MSG-CH01-002 (Seats first)")

	# Test found trigger (MSG-CH01-008 has unlock: {on: "found", id: "EX-CH01-S03"})
	var eval_found := service.evaluate_unlocks({
		"current_scene_id": "EX-CH01-S03",
		"completed_scene_ids": ["EX-CH01-S01", "EX-CH01-S02"],
		"completed_targets_by_scene": {"EX-CH01-S03": ["inspect_seed_drawer"]},
	}, true)
	_check((eval_found.get("newly_unlocked", []) as Array).has("MSG-CH01-008"), "found trigger unlocks MSG-CH01-008 when S03 evidence target is inspected")

	# Test mission_done trigger (MSG-CH01-011 has unlock: {on: "mission_done", id: "EX-M0101"})
	var eval_mission := service.evaluate_unlocks({
		"current_scene_id": "EX-CH01-S04",
		"completed_scene_ids": ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"],
	}, true)
	_check((eval_mission.get("newly_unlocked", []) as Array).has("MSG-CH01-011"), "mission_done trigger unlocks MSG-CH01-011 when all EX-M0101 scenes complete")

	# Test job_done trigger with synthetic message
	service._messages_by_id["MSG-TEST-JOB"] = {
		"id": "MSG-TEST-JOB",
		"chapter": 0,
		"thread": "crew",
		"sender": "Kai",
		"story_time": "2046-04-11T09:00Z",
		"formatted_time": CommsServiceScript.format_story_time("2046-04-11T09:00Z"),
		"unlock": {"on": "job_done", "id": "job_lamp_check"},
		"join": "",
		"subject": "Lamp clip tightened",
		"body": "Clipped the spare work light by the bench.",
		"goal": false,
	}
	service._ordered_ids.append("MSG-TEST-JOB")
	var eval_job := service.evaluate_unlocks({
		"current_scene_id": "EX-CH01-S04",
		"completed_scene_ids": ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"],
		"completed_jobs": ["job_lamp_check"],
	}, true)
	_check((eval_job.get("newly_unlocked", []) as Array).has("MSG-TEST-JOB"), "job_done trigger unlocks message when job ID is completed")

	# Test mark_read and director persistence
	var unread_before := service.unread_count("crew")
	var mark_res := service.mark_read("MSG-CH01-002")
	_check(bool(mark_res.get("ok", false)), "mark_read succeeds for delivered message MSG-CH01-002")
	_check(service.is_read("MSG-CH01-002"), "is_read returns true after mark_read")
	_check(service.unread_count("crew") == unread_before - 1, "unread_count decrements by 1 after reading")

	var dir_meta: Dictionary = director.message_metadata()
	_check((dir_meta.get("delivered_ids", []) as Array).has("MSG-CH01-002"), "director.message_metadata() persists delivered_ids")
	_check((dir_meta.get("read_ids", []) as Array).has("MSG-CH01-002"), "director.message_metadata() persists read_ids")


func _test_hud_inbox_toasts_and_persistence() -> void:
	CampaignCutscenePlayer.autoplay = false
	var campaign := CAMPAIGN_SCENE.instantiate() as Chapter1Campaign
	root.add_child(campaign)
	await process_frame
	await process_frame

	var hud := campaign.hud
	_check(hud != null and hud.comms_service != null and hud.comms_panel != null, "Chapter1CampaignHUD instantiates comms_service and comms_panel")
	_check(not hud.comms_panel.is_open(), "comms_panel is closed during free movement")

	# Verify dialogue suppression of arrival toasts
	_check(hud._is_dialogue_active(), "dialogue is active at scene start before lines are acknowledged")
	hud.comms_service._enqueue_toast({
		"id": "MSG-CH01-002",
		"thread": "crew",
		"sender": "Rafi",
		"subject": "Seats first",
	})
	hud._flush_message_toasts()
	_check(hud.comms_service.has_pending_toasts(), "arrival toast is suppressed while dialogue bar is active")

	# Acknowledge all dialogue lines in S01
	var guard := 0
	while hud._is_dialogue_active() and guard < 20:
		hud._on_next_line()
		guard += 1
	await process_frame

	_check(not hud._is_dialogue_active(), "all S01 dialogue lines acknowledged")
	_check(not hud.comms_service.has_pending_toasts(), "queued arrival toast flushed automatically once dialogue finishes")
	_check(hud._toast.visible and hud._status.text.contains("Rafi: Seats first"), "toast banner displays 'New message · Rafi: Seats first'")

	var capture_screenshots := OS.get_cmdline_user_args().has("--capture")
	if capture_screenshots:
		await process_frame
		await process_frame
		var toast_img := root.get_texture().get_image()
		if toast_img != null:
			var toast_path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-56_toast.png")
			toast_img.save_png(toast_path)

	# Unlock S01 exit messages so Crew and Academy both have messages for the inbox test
	hud.comms_service.evaluate_unlocks({
		"current_scene_id": "EX-CH01-S02",
		"completed_scene_ids": ["EX-CH01-S01"],
	}, false)

	# Open inbox via M key
	var m_event := InputEventKey.new()
	m_event.pressed = true
	m_event.physical_keycode = KEY_M
	m_event.keycode = KEY_M
	hud._unhandled_key_input(m_event)
	await process_frame

	_check(hud.comms_panel.is_open(), "pressing M opens CommsPanel")
	hud.comms_panel.select_thread("crew")
	await process_frame
	_check(hud.comms_panel.active_thread == "crew", "selecting crew thread switches active_thread to crew")
	_check(hud.comms_panel._detail_subject_label.text == "Re: Seats first" or hud.comms_panel._detail_subject_label.text == "Seats first", "detail pane shows selected crew message subject")
	_check(hud.comms_service.is_read(hud.comms_panel.selected_message_id), "selecting message in CommsPanel marks it read")

	if capture_screenshots:
		await process_frame
		await process_frame
		var inbox_img := root.get_texture().get_image()
		if inbox_img != null:
			var inbox_path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-56_inbox.png")
			inbox_img.save_png(inbox_path)

		# Capture Chapter 2, 3, and 4 message inbox views for M3-2T, M3-3T, M3-4T
		hud.comms_service.evaluate_unlocks({
			"current_scene_id": "EX-CH04-S02",
			"completed_scene_ids": ["EX-CH01-S01", "EX-CH02-S01", "EX-CH03-S01", "EX-CH04-S01"],
		}, false)
		for ch_pair in [
			{"id": "MSG-CH02-002", "path": "res://../production/qa/evidence/M3-2T_ch02_inbox.png"},
			{"id": "MSG-CH03-002", "path": "res://../production/qa/evidence/M3-3T_ch03_inbox.png"},
			{"id": "MSG-CH04-002", "path": "res://../production/qa/evidence/M3-4T_ch04_inbox.png"},
		]:
			hud.comms_panel.select_message(String(ch_pair.id))
			await process_frame
			await process_frame
			var ch_img := root.get_texture().get_image()
			if ch_img != null:
				ch_img.save_png(ProjectSettings.globalize_path(String(ch_pair.path)))

	# Close inbox via Escape
	var esc_event := InputEventKey.new()
	esc_event.pressed = true
	esc_event.physical_keycode = KEY_ESCAPE
	esc_event.keycode = KEY_ESCAPE
	hud.comms_panel._unhandled_input(esc_event)
	await process_frame
	_check(not hud.comms_panel.is_open(), "pressing Escape closes CommsPanel")

	# Verify Pause menu has Messages button that opens CommsPanel
	hud.panels.open_panel("pause")
	await process_frame
	var pause_messages_btn := hud.panels.find_child("Messages", true, false) as Button
	_check(pause_messages_btn != null, "Pause menu includes 'Messages' button")
	if pause_messages_btn != null:
		pause_messages_btn.pressed.emit()
		await process_frame
		_check(hud.comms_panel.is_open(), "Pause -> Messages opens CommsPanel")
		hud.comms_panel.close_inbox()
		await process_frame

	# Verify save/load + retry checkpoint preserves delivered_ids and read_ids
	var read_id := "MSG-CH01-001"
	hud.comms_service.mark_read(read_id)
	var saved_snap: Dictionary = campaign.director.snapshot()
	campaign.retry_checkpoint()
	await process_frame
	hud._sync_messages()
	_check(hud.comms_service.is_delivered("MSG-CH01-001"), "delivered_ids survive retry_checkpoint")
	_check(hud.comms_service.is_read(read_id), "read_ids survive retry_checkpoint")

	var restored_director := DirectorScript.new()
	restored_director.restore_snapshot(saved_snap)
	var restored_service := CommsServiceScript.new()
	restored_service.setup(restored_director, campaign.content, false)
	_check(restored_service.is_delivered("MSG-CH01-002"), "restored director snapshot preserves delivered_ids")
	_check(restored_service.is_read(read_id), "restored director snapshot preserves read_ids")

	campaign.queue_free()
	await process_frame
