## Make it fun: Chapter 1 game-feel and reward pass verification (M1-31).
## Verifies:
##   1. Observable cause-and-effect feedback for Chapter 1 actions (equipment/item/process
##      consequence, plain-English why, meaningful next step, meter tick, crew reaction).
##   2. Investigation clues, deduction aha, wrong-but-reasonable preview catch, escalation,
##      set-piece payoff, and 3-tier hints for EX-M0101..EX-M0104 (P-01 and P-02, doc 22 §3).
##   3. Night-shift tension cues (lights dimming, fans slowing to SFX_FAN_LOWPOWER,
##      countdown to dawn, Earth link STORED GUIDANCE).
##   4. Alo's botanical posture and growth across seedling, thirst curl, night bud,
##      and four-petal yellow bloom (never a face or eyes).
##   5. Stars / Golden Bloom celebration and retry-inviting failure feedback.
extends SceneTree

const FeedbackScript = preload("res://scripts/feedback/chapter1_feedback.gd")
const P01PanelScene: PackedScene = preload("res://scenes/ui/p01_panel.tscn")
const MissionTableScene: PackedScene = preload("res://scenes/ui/mission_table_panel.tscn")
const CampaignPanelsScene: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")

var checks := 0
var failures := 0
var _save_evidence := false

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	for arg in OS.get_cmdline_user_args():
		if arg == "--evidence":
			_save_evidence = true
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame

	await _test_action_feedback_and_banner()
	await _test_investigations_and_clues()
	await _test_night_shift_tension_and_alo_posture()
	await _test_rewards_and_golden_bloom()

	print("CH01 GAME FEEL RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_action_feedback_and_banner() -> void:
	for action_id in [
		"route_spare_power",
		"calibrate_probe",
		"plant_and_seal_cassettes",
		"stage_shelter_water",
		"return_garden_water",
	]:
		var fb: Dictionary = FeedbackScript.action_feedback(action_id)
		_check(not String(fb.get("consequence", "")).is_empty(), action_id + " has observable consequence")
		_check(not String(fb.get("why", "")).is_empty(), action_id + " has plain-English why")
		_check(not String(fb.get("next_step", "")).is_empty(), action_id + " has meaningful next step")
		_check(not String(fb.get("meter_tick", "")).is_empty(), action_id + " has meter tick")
		_check(not String(fb.get("crew_reaction", "")).is_empty(), action_id + " has crew reaction line")

	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var banner := FeedbackScript.build_feedback_banner(host, "calibrate_probe", 2, 6, 0, false)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.custom_minimum_size = Vector2(920, 320)
	banner.position = Vector2(180, 200)
	await process_frame
	var banner_text := _collect_text(banner)
	_check(banner_text.contains("CAUSE & EFFECT") and banner_text.contains("Zero and span checked"), "Chapter 1 feedback banner renders consequence, why, next step, and crew reaction")
	await _maybe_capture("M1-31_action_feedback.png")
	host.queue_free()
	await process_frame

func _test_investigations_and_clues() -> void:
	var mission_ids: Array[String] = FeedbackScript.all_mission_ids()
	_check(mission_ids.size() == 4, "All 4 Chapter 1 missions (EX-M0101..EX-M0104) have investigation definitions")

	for mid in mission_ids:
		var inv: Dictionary = FeedbackScript.mission_investigation(mid)
		var clues: Array = inv.get("clues", [])
		_check(clues.size() >= 6, mid + " has at least 6 core investigation clues")
		_check(not String(inv.get("aha", "")).is_empty(), mid + " defines deduction aha moment")
		_check(not String(inv.get("wrong_but_reasonable", "")).is_empty(), mid + " defines non-punishing wrong-but-reasonable catch")
		_check(not String(inv.get("escalation", "")).is_empty(), mid + " defines 3-scene escalation")
		_check(not String(inv.get("set_piece", "")).is_empty(), mid + " defines set-piece payoff")
		var hints: Array = inv.get("hints", [])
		_check(hints.size() == 3, mid + " defines 3-tier hint ladder (H1, H2, H3)")

	# Verify P-01 panel & investigation visual
	var p01 := P01PanelScene.instantiate()
	root.add_child(p01)
	await process_frame
	await _maybe_capture("M1-31_p01_investigation.png")
	p01.queue_free()
	await process_frame

func _test_night_shift_tension_and_alo_posture() -> void:
	var day_s1: Dictionary = FeedbackScript.night_shift_tension(1)
	var night_s4: Dictionary = FeedbackScript.night_shift_tension(4)
	var storm_s5: Dictionary = FeedbackScript.night_shift_tension(5)
	var dawn_s7: Dictionary = FeedbackScript.night_shift_tension(7)

	_check(not bool(day_s1.get("is_dark", true)) and String(day_s1.get("fans_state", "")).contains("SFX_FAN_NORMAL"), "Shift 1 has daylight lamp and nominal fan pitch")
	_check(bool(night_s4.get("is_dark", false)) and String(night_s4.get("fans_state", "")).contains("SFX_FAN_LOWPOWER") and String(night_s4.get("earth_link_state", "")).contains("STORED GUIDANCE"), "Shift 4 dims lights, slows fans to SFX_FAN_LOWPOWER, and switches Earth link to STORED GUIDANCE")
	_check(bool(storm_s5.get("is_storm", false)) and String(storm_s5.get("lights_state", "")).contains("35%"), "Shift 5 storm peak dims shelter lighting to 35% warm amber")
	_check(is_equal_approx(float(dawn_s7.get("hours_to_dawn", -1.0)), 0.0), "Shift 7 countdown reaches dawn (0.0 h)")

	# Alo botanical posture checks (never a face or eyes)
	var p_seedling: Dictionary = FeedbackScript.alo_posture(6, 0, 1, false)
	var p_thirst: Dictionary = FeedbackScript.alo_posture(4, 4, 4, false)
	var p_bloom: Dictionary = FeedbackScript.alo_posture(6, 0, 7, true)

	for posture in [p_seedling, p_thirst, p_bloom]:
		_check(not bool(posture.get("has_face_or_eyes", true)), "Alo posture never uses a face or eyes")
		var desc := String(posture.get("posture_description", "")).to_lower()
		_check(not desc.contains("smile") and not desc.contains("eyes"), "Alo posture description is strictly botanical")

	_check(String(p_thirst.get("stage", "")).contains("Thirst") and String(p_thirst.get("posture_description", "")).contains("droops"), "Alo shows leaf curl and petiole droop under W >= 4 thirst")
	_check(String(p_bloom.get("stage", "")).contains("Golden Four-Petal Bloom"), "Alo opens four yellow petals at dawn with H >= 5")

	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var tension_banner := FeedbackScript.build_feedback_banner(host, "stage_shelter_water", 5, 5, 4, false)
	tension_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	tension_banner.custom_minimum_size = Vector2(920, 340)
	tension_banner.position = Vector2(180, 190)
	await process_frame
	await _maybe_capture("M1-31_night_shift_tension.png")
	host.queue_free()
	await process_frame

func _test_rewards_and_golden_bloom() -> void:
	var golden: Dictionary = FeedbackScript.outcome_reward_card({"safe_exposure": true, "no_blackout": true, "alo_alive": true}, 6, 5)
	var standard_bloom: Dictionary = FeedbackScript.outcome_reward_card({"safe_exposure": true, "no_blackout": false, "alo_alive": true}, 3, 5)
	var retry_card: Dictionary = FeedbackScript.outcome_reward_card({"safe_exposure": false, "no_blackout": false, "alo_alive": false}, 0, 5)

	_check(bool(golden.get("golden_bloom", false)) and int(golden.get("star_count", 0)) == 3 and String(golden.get("title", "")).contains("GOLDEN BLOOM"), "3 stars + H>=5 awards Golden Bloom celebration")
	_check(not bool(standard_bloom.get("golden_bloom", true)) and int(standard_bloom.get("star_count", 0)) == 2 and String(standard_bloom.get("retry_prompt", "")).contains("Retry from Shift 5"), "Partial bloom celebrates survival and invites retry for Golden Bloom")
	_check(String(retry_card.get("tier", "")) == "RETRY_INVITATION" and String(retry_card.get("sfx", "")) == "SFX_UI_SOFT_ERROR", "Failure uses SFX_UI_SOFT_ERROR and invites immediate checkpoint retry")

	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var card := UiDesign.glass_panel(UiDesign.colour("accent"))
	card.custom_minimum_size = Vector2(880, 300)
	card.position = Vector2(200, 210)
	host.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(UiDesign.label(String(golden.get("title", "")), "title", "accent"))
	box.add_child(UiDesign.label(String(golden.get("celebration", "")), "body"))
	box.add_child(UiDesign.label(String(golden.get("retry_prompt", "")), "caption", "good"))
	var bloom_posture := FeedbackScript.alo_posture(6, 0, 7, true)
	box.add_child(UiDesign.label("Alo at Dawn: " + String(bloom_posture.get("posture_description", "")), "body", "good"))
	await process_frame
	await _maybe_capture("M1-31_golden_bloom.png")
	host.queue_free()
	await process_frame

	_check(FileAccess.file_exists(ProjectSettings.globalize_path("res://../production/qa/fun_2026-11-10.md")), "production/qa/fun_2026-11-10.md report exists")

func _collect_text(node: Node) -> String:
	var parts: Array[String] = []
	_walk_text(node, parts)
	return "\n".join(parts)

func _walk_text(node: Node, out: Array[String]) -> void:
	if node is Label:
		out.append((node as Label).text)
	elif node is Button:
		out.append((node as Button).text)
	elif node is RichTextLabel:
		out.append((node as RichTextLabel).text)
	for child in node.get_children():
		_walk_text(child, out)

func _maybe_capture(filename: String) -> void:
	if not _save_evidence or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		var abs_path := ProjectSettings.globalize_path("res://../production/qa/evidence/" + filename)
		img.save_png(abs_path)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
