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
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

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
	await _test_live_campaign_feedback_integration()
	_test_truthful_feedback()

	print("CH01 GAME FEEL RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_action_feedback_and_banner() -> void:
	for action_id in [
		"route_spare_power",
		"calibrate_probe",
		"span_probe",
		"recheck_probe",
		"inspect_packet",
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

	# Step-specific calibration feedback checks: set_zero must NOT claim wet-span or verification is already done
	var fb_zero := FeedbackScript.action_feedback("calibrate_probe", {"probe_zeroed": true, "probe_spanned": false, "probe_rechecked": false})
	_check(String(fb_zero.get("canonical_id", "")) == "set_zero", "calibrate_probe maps to set_zero step feedback")
	_check(String(fb_zero.get("consequence", "")).contains("10 to 0") and not String(fb_zero.get("consequence", "")).contains("spanned on the wet"), "set_zero consequence reports only dry zero (10->0), not wet span")
	_check(String(fb_zero.get("next_step", "")).contains("wet reference span") and not String(fb_zero.get("next_step", "")).contains("Fill Alo"), "set_zero next_step directs player to set wet reference span, not water cassettes")

	var fb_span := FeedbackScript.action_feedback("span_probe", {"probe_zeroed": true, "probe_spanned": true, "probe_rechecked": false})
	_check(String(fb_span.get("canonical_id", "")) == "set_span" and String(fb_span.get("next_step", "")).contains("Recheck"), "span_probe reports wet span (110->100) and directs player to recheck both references")

	var fb_recheck := FeedbackScript.action_feedback("recheck_probe", {"probe_zeroed": true, "probe_spanned": true, "probe_rechecked": true, "packet_scanned": false})
	_check(String(fb_recheck.get("canonical_id", "")) == "recheck" and String(fb_recheck.get("next_step", "")).contains("seed packet"), "recheck_probe confirms two-point verification and directs player to inspect the seed packet")

	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var banner := FeedbackScript.build_feedback_banner(host, "recheck_probe", 2, 6, 0, false)
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

func _test_night_shift_tension_and_alo_posture() -> void:
	var day_s1: Dictionary = FeedbackScript.night_shift_tension(1)
	var night_s4: Dictionary = FeedbackScript.night_shift_tension(4)
	var storm_s5: Dictionary = FeedbackScript.night_shift_tension(5)
	var dawn_s7: Dictionary = FeedbackScript.night_shift_tension(7)

	_check(not bool(day_s1.get("is_dark", true)) and String(day_s1.get("fans_sfx", "")).contains("SFX_FAN_NORMAL"), "Shift 1 has daylight lamp and nominal fan pitch")
	_check(bool(night_s4.get("is_dark", false)) and String(night_s4.get("fans_sfx", "")).contains("SFX_FAN_LOWPOWER") and String(night_s4.get("earth_link_state", "")).contains("STORED GUIDANCE"), "Shift 4 dims lights, slows fans to SFX_FAN_LOWPOWER, and switches Earth link to STORED GUIDANCE")
	_check(bool(storm_s5.get("is_storm", false)) and String(storm_s5.get("lights_state", "")).contains("35%"), "Shift 5 storm peak dims shelter lighting to 35% warm amber")
	_check(not String(day_s1.get("fans_state", "")).contains("SFX_") and not String(night_s4.get("fans_state", "")).contains("SFX_"), "the fan line players read carries no sound IDs")
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

func _test_live_campaign_feedback_integration() -> void:
	var temp_save := "user://test_ch01_feel_campaign.save"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_save))
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	campaign.save_path = temp_save
	root.add_child(campaign)
	await process_frame
	await process_frame

	# 1. Perform real Chapter 1 S01 action (commission_route) and verify HUD _last_outcome + outcome panel
	var target_node := campaign.physical_target("commission_route")
	if target_node != null and campaign._player != null:
		campaign._player.global_position = target_node.global_position + Vector3(0.0, 0.0, 1.2)
		campaign._player.look_at(target_node.global_position, Vector3.UP)
	await physics_frame
	var res := campaign.perform_target("commission_route")
	_check(bool(res.get("accepted", false)), "Live campaign perform_target('commission_route') succeeds")
	var last_outcome: Dictionary = campaign.hud._last_outcome
	_check(last_outcome.has("feedback") and String(last_outcome.feedback.get("canonical_id", "")) == "route_spare_power", "Chapter1CampaignHUD.refresh_after_action attaches Chapter1Feedback for 'commission_route'")
	_check(last_outcome.has("alo_posture") and not bool(last_outcome.alo_posture.get("has_face_or_eyes", true)), "Chapter1CampaignHUD attaches non-anthropomorphic Alo botanical posture")
	campaign.hud.panels.open_panel("outcome", last_outcome)
	await process_frame
	var outcome_text := _collect_text(campaign.hud.panels)
	_check(outcome_text.contains("What changed:") and outcome_text.contains("Flow traced"), "CampaignPanels 'outcome' view renders Chapter1Feedback consequence, why, next step, and crew reaction")
	campaign.hud.panels.close_panel()

	# 2. Advance through S01/S02 to EX-CH01-S03 and verify P01Panel shows Chapter1Feedback on real step completion
	var Gates := preload("res://scripts/missions/chapter1_gate_catalog.gd")
	var Inputs := preload("res://tools/support/p01_input_fixture.gd")
	while campaign.route.current_scene_id() != "EX-CH01-S03":
		for spec in Gates.targets_for_scene(campaign.route.current_scene_id()):
			campaign.route.perform(String(spec.target_id), Inputs.payload(String(spec.target_id)))
		campaign.route.advance_scene()
	_check(bool(Inputs.complete_probe_transfer(campaign.route).get("accepted", false)), "Opening probe is retrieved, placed and observed before calibration feedback")
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene({})
	await process_frame
	await physics_frame
	var probe_node := campaign.physical_target("calibrate_probe")
	if probe_node != null and campaign._player != null:
		campaign._player.global_position = probe_node.global_position + Vector3(0.0, 0.0, 1.0)
		campaign._player.velocity = Vector3.ZERO
	await physics_frame
	if probe_node != null and campaign._player != null:
		campaign._player.get_viewport().get_camera_3d().look_at(probe_node.global_position)
	await physics_frame
	var opened_p01 := campaign.hud.p01_panel.open(campaign, "calibrate_probe")
	_check(opened_p01, "P01Panel opens on 'calibrate_probe' in live EX-CH01-S03 scene")
	for key in Inputs.payload("calibrate_probe"):
		campaign.hud.p01_panel.choose(key, Inputs.payload("calibrate_probe")[key])
	campaign.hud.p01_panel.preview()
	campaign.hud.p01_panel.request_commit()
	campaign.hud.p01_panel.confirm_commit()
	await process_frame
	var p01_text := _collect_text(campaign.hud.p01_panel)
	_check(p01_text.contains("What changed:") and p01_text.contains("Dry cup zeroed at 0") and p01_text.contains("wet reference span") and not p01_text.contains("Fill Alo"), "After dry-zero ('calibrate_probe'), P01Panel feedback reports only dry zero and directs to wet span (never claims wet-span/verification or watering yet)")
	campaign.hud.p01_panel.discard()

	# Also verify span_probe and recheck_probe step-by-step in live campaign
	campaign.hud.p01_panel.open(campaign, "span_probe")
	for key in Inputs.payload("span_probe"):
		campaign.hud.p01_panel.choose(key, Inputs.payload("span_probe")[key])
	campaign.hud.p01_panel.preview()
	campaign.hud.p01_panel.request_commit()
	campaign.hud.p01_panel.confirm_commit()
	await process_frame
	var span_text := _collect_text(campaign.hud.p01_panel)
	_check(span_text.contains("110 to 100") and span_text.contains("Recheck both"), "After wet-span ('span_probe'), P01Panel feedback reports 110->100 and directs to recheck both references")
	campaign.hud.p01_panel.discard()

	campaign.hud.p01_panel.open(campaign, "recheck_probe")
	for key in Inputs.payload("recheck_probe"):
		campaign.hud.p01_panel.choose(key, Inputs.payload("recheck_probe")[key])
	campaign.hud.p01_panel.preview()
	campaign.hud.p01_panel.request_commit()
	campaign.hud.p01_panel.confirm_commit()
	await process_frame
	var recheck_text := _collect_text(campaign.hud.p01_panel)
	_check(recheck_text.contains("Zero and span checked against both cups") and recheck_text.contains("seed packet"), "After two-point recheck ('recheck_probe'), P01Panel feedback confirms verification and directs to seed packet")
	campaign.hud.p01_panel.discard()

	# 3. Jump to EX-CH01-S07 and verify MissionTablePanel renders night_shift_tension and alo_posture
	campaign.route.start_at("EX-CH01-S07")
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene({})
	await process_frame
	var opened_mt := campaign.hud.open_mission_table("p02_shift1")
	_check(opened_mt, "MissionTablePanel opens for 'p02_shift1' in live EX-CH01-S07 scene")
	await process_frame
	var mt_text := _collect_text(campaign.hud.mission_table)
	_check(mt_text.contains("Atmosphere ·") and mt_text.contains("Alo posture ("), "MissionTablePanel displays Chapter1Feedback shift tension and Alo botanical posture")
	campaign.hud.mission_table.close()

	# 4. Verify CampaignPanels._render_chapter1_outcome includes outcome_reward_card and alo_posture
	var debrief_data := {
		"title": "GOLDEN_BLOOM",
		"summary": "Golden Bloom achieved.",
		"safe_ending": true,
		"ending": "GOLDEN_BLOOM",
		"star_count": 3,
		"retry_shift": 5,
		"can_retry": true,
		"retry_reason": "",
		"can_continue": true,
		"continue_reason": "",
		"resources": {"E": 6, "A": 5, "H": 6, "C": 8, "R": 10, "W": 0, "K": 2, "Z": 0},
		"stars": {"safe_exposure": true, "no_blackout": true, "alo_alive": true},
		"replay": [],
		"lessons": [],
	}
	campaign.hud.panels.open_chapter1_outcome(debrief_data, "summary")
	await process_frame
	var ch1_out_text := _collect_text(campaign.hud.panels)
	_check(ch1_out_text.contains("GOLDEN BLOOM") and ch1_out_text.contains("Alo botanical posture"), "CampaignPanels chapter1_outcome summary renders Chapter1Feedback reward celebration and Alo posture")
	campaign.hud.panels.close_panel()

	campaign.free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_save))

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

func _test_truthful_feedback() -> void:
	var initial := FeedbackScript.action_feedback("commission_route", {"resources": {"E": 14, "A": 6, "H": 6, "W": 0, "Z": 0}})
	_check(not String(initial.meter_tick).contains("+2") and not String(initial.meter_tick).contains("20/20"), "Opening verification never claims resource changes the phase action does not make")
	var stopped := FeedbackScript.outcome_reward_card({"safe_exposure": false, "no_blackout": false, "alo_alive": true}, 6, 5)
	_check(stopped.tier == "RETRY_INVITATION", "A living Alo in a stopped mission cannot announce a safe blooming ending")
	var ordinary := FeedbackScript.alo_posture(1, 0, 7, true)
	_check(ordinary.stage == "First Open Flower", "An ordinary low-health bloom is not labelled Golden Bloom")
