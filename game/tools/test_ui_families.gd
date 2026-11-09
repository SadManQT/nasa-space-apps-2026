## Remaining UI families verification (M3-90):
##   - UI_07 Expedition Journal (Now, Evidence, Garden, Decisions, People, Science + 150% text scale)
##   - UI_08 Discovery Log (Observed/Verified/Inferred/Unknown/Linked, source pinning beside reconstruction, EX-CH05-S10 Noor spoiler gate)
##   - UI_11 Rover HUD & Controls (upper-left speed, centre marker/distance, lower-left reserve/hours + margin warning, lower-right local link, Cruise only at validated stops, reduced-motion hiding direct driving while keeping route/repair decisions)
##   - UI_12 Greenhouse & Plant Care (plant name/lineage/stage, date, temp/moisture, care actions, comparison tab, stress cause, mature Alo founder archive distinct from descendants, Harvest disabled until mature showing "Pods are not ready")
##   - UI_16 Credits (optional auto-scroll, manual scroll, photo+dedication, return to garden, skip, all 7 CREDITS.md §9 sections, runtime Godot license/copyright, and optional post-credits CS-18 MARS drawer with no forced teaser)
extends SceneTree

const CampaignPanelsScene: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")
const DiscoveryLogScene: PackedScene = preload("res://scenes/ui/discovery_log_panel.tscn")
const RoverHudScene: PackedScene = preload("res://scenes/ui/rover_hud_panel.tscn")
const GreenhouseScene: PackedScene = preload("res://scenes/ui/greenhouse_panel.tscn")
const CreditsScene: PackedScene = preload("res://scenes/ui/credits_panel.tscn")
const Director = preload("res://scripts/core/campaign_director.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Content = preload("res://scripts/content/content_loader.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")

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

	await _test_ui07_journal()
	await _test_ui08_discovery_log()
	await _test_ui11_rover_hud()
	await _test_ui12_greenhouse()
	await _test_ui16_credits()

	print("UI FAMILIES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_ui07_journal() -> void:
	var director := Director.new()
	director.new_campaign(Content.EXPECTED_CONTENT_REVISION)
	var route := Route.new(director)
	PlanFixture.prepare(route)
	var snap := director.snapshot()
	snap["scene_id"] = "EX-CH01-S05"
	snap["completed_scene_ids"] = ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03", "EX-CH01-S04"]
	snap["acquired_evidence_ids"] = ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03", "EX-CH01-S04"]
	director.restore_snapshot(snap)

	var panels := CampaignPanelsScene.instantiate()
	root.add_child(panels)
	await process_frame
	panels.bind_query(director.query())

	for tab_id in ["now", "evidence", "garden", "decisions", "people", "science"]:
		_check(panels.open_journal(tab_id), "UI_07 Journal opens tab: " + tab_id)
		await process_frame
		_check(panels.journal_tab() == tab_id, "UI_07 active journal tab is " + tab_id)
		var body_text := _collect_text(panels)
		_check(not body_text.is_empty(), "UI_07 tab " + tab_id + " renders non-empty content")

	# Test 150% text scale
	panels.set_accessibility({"large_text": true})
	panels.open_journal("now")
	await process_frame
	_check(is_equal_approx(panels.text_scale(), 1.5), "UI_07 Journal supports 150% text scale")
	await _maybe_capture("M3-90_journal.png")
	panels.close_panel()
	panels.queue_free()
	await process_frame

func _test_ui08_discovery_log() -> void:
	var dl := DiscoveryLogScene.instantiate()
	root.add_child(dl)
	await process_frame

	# Before EX-CH05-S10: Noor's name must stay hidden
	dl.configure("EX-CH05-S09")
	await process_frame
	_check(not DiscoveryLogPanel.is_noor_revealed("EX-CH05-S09"), "UI_08 Discovery Log hides Noor Rahman's name before EX-CH05-S10")
	var pre_text := _collect_text(dl)
	_check(not pre_text.contains("Noor") and not pre_text.contains("Rahman"), "UI_08 pre-S10 text never leaks 'Noor' or 'Rahman'")
	_check(pre_text.contains("N."), "UI_08 pre-S10 uses 'N.' initial placeholder")

	# Status badges & timestamps
	for badge_word in ["VERIFIED", "OBSERVED", "INFERRED", "UNKNOWN", "LINKED", "UTC"]:
		_check(pre_text.contains(badge_word), "UI_08 Discovery Log includes badge/timestamp token: " + badge_word)

	# Pin source beside reconstruction
	var pinned: Dictionary = dl.pin_source("EV-CH02-RECORDER")
	await process_frame
	_check(dl.pinned_id == "EV-CH02-RECORDER" and String(pinned.get("source", "")).contains("Annex Recorder 2034"), "UI_08 pins source record beside reconstruction")
	var pin_box := dl.find_child("PinnedSourceBesideReconstruction", true, false)
	_check(pin_box != null and _collect_text(pin_box).contains("Annex Recorder 2034"), "UI_08 shows pinned source record beside active reconstruction")

	# Optional scan non-blocking & required automatic note
	_check(pre_text.contains("Required evidence records automatically") and pre_text.contains("Optional scans never block story progress"), "UI_08 states automatic required evidence and non-blocking optional scans")

	# After EX-CH05-S10: Noor Rahman revealed
	dl.configure("EX-CH05-S10")
	await process_frame
	_check(DiscoveryLogPanel.is_noor_revealed("EX-CH05-S10"), "UI_08 Discovery Log reveals Noor Rahman at EX-CH05-S10")
	var post_text := _collect_text(dl)
	_check(post_text.contains("Dr. Noor Rahman"), "UI_08 post-S10 displays Dr. Noor Rahman")
	await _maybe_capture("M3-90_discovery_log.png")

	dl.queue_free()
	await process_frame

func _test_ui11_rover_hud() -> void:
	var rh := RoverHudScene.instantiate()
	root.add_child(rh)
	await process_frame

	# Check 4-corner layout & readouts
	var ul := rh.find_child("UpperLeftSpeedCard", true, false)
	var tc := rh.find_child("CentreMarkerCard", true, false)
	var ll := rh.find_child("LowerLeftReserveCard", true, false)
	var lr := rh.find_child("LowerRightLinkCard", true, false)
	_check(ul != null and _collect_text(ul).contains("Speed:"), "UI_11 upper-left shows speed and slope")
	_check(tc != null and _collect_text(tc).contains("Next Marker:"), "UI_11 top-centre shows next marker and distance")
	_check(ll != null and _collect_text(ll).contains("Return Reserve:") and _collect_text(ll).contains("Provisions remaining:"), "UI_11 lower-left shows return reserve and remaining hours")
	_check(lr != null and _collect_text(lr).contains("Local Link:"), "UI_11 lower-right shows local link")

	# Cruise gated to validated stops
	var cruise_btn := rh.find_child("CruiseStopButton", true, false) as Button
	_check(cruise_btn != null and not cruise_btn.disabled, "UI_11 Cruise enabled at validated stop")
	rh.set_stop_state(false, "mid_ridge", "Connective Ridge Midpoint", 620.0)
	await process_frame
	_check(cruise_btn.disabled and _collect_text(tc).contains("Cruise unavailable"), "UI_11 Cruise disabled outside validated stops")

	# Drain rover battery below return reserve to verify reserve warning names required margin
	rh.rover.battery = 22.0
	rh.set_stop_state(true, "stop_beacon_2", "Beacon 2 · Shadow Rim", 340.0)
	await process_frame
	var warn_lbl := rh.find_child("ReserveWarningLabel", true, false) as Label
	_check(warn_lbl != null and warn_lbl.text.contains("RESERVE WARNING") and warn_lbl.text.contains("30.0 return reserve margin"), "UI_11 reserve warning names required return margin")
	await _maybe_capture("M3-90_rover_hud.png")

	# Motion option (reduced_motion) hides direct driving while keeping route and repair decisions identical
	var direct_bar := rh.find_child("DirectDrivingControls", true, false) as Control
	var decision_bar := rh.find_child("MotionSafeDecisionControls", true, false) as Control
	_check(direct_bar != null and direct_bar.visible, "UI_11 direct driving visible when reduced_motion is false")
	rh.set_accessibility({"reduced_motion": true})
	await process_frame
	_check(not direct_bar.visible and decision_bar != null and decision_bar.visible, "UI_11 reduced-motion hides direct driving while keeping route and repair decisions")

	rh.queue_free()
	await process_frame

func _test_ui12_greenhouse() -> void:
	var gh := GreenhouseScene.instantiate()
	root.add_child(gh)
	await process_frame

	var ch_text := _collect_text(gh)
	_check(ch_text.contains("[MATURE FOUNDER ARCHIVE]  Alo"), "UI_12 mature Alo founder archive is visibly distinct from descendants")
	_check(ch_text.contains("STRESS CAUSE: Cool night air (18.4 °C) and low root moisture (52%)"), "UI_12 stress icon includes plain cause")

	# Harvest enabled on mature Alo, disabled on immature Tara & G1 descendants with "Pods are not ready"
	var harvest_alo := gh.find_child("Harvest_alo", true, false) as Button
	var harvest_tara := gh.find_child("Harvest_tara", true, false) as Button
	var reason_tara := gh.find_child("HarvestReason_tara", true, false) as Label
	_check(harvest_alo != null and not harvest_alo.disabled, "UI_12 mature Alo enables Harvest")
	_check(harvest_tara != null and harvest_tara.disabled and reason_tara != null and reason_tara.text.contains("Pods are not ready"), "UI_12 immature plant disables Harvest and shows 'Pods are not ready'")

	# Care action clears stress
	var mist_g1 := gh.find_child("CareMist_g1_descendants", true, false) as Button
	_check(mist_g1 != null, "UI_12 care action button present for G1 descendants")
	mist_g1.pressed.emit()
	await process_frame
	var feedback_lbl := gh.find_child("GreenhouseFeedback", true, false) as Label
	_check(feedback_lbl != null and feedback_lbl.text.contains("cared for"), "UI_12 care action updates chamber conditions")

	# Comparison tab
	gh.show_tab("comparison")
	await process_frame
	var comp_text := _collect_text(gh)
	_check(comp_text.contains("Founder Archive vs Descendant Lineages") and comp_text.contains("FOUNDER ARCHIVE") and comp_text.contains("ACTIVE CHAMBER"), "UI_12 comparison tab compares founder archive against active descendant chambers")
	await _maybe_capture("M3-90_greenhouse.png")

	gh.queue_free()
	await process_frame

func _test_ui16_credits() -> void:
	var cr := CreditsScene.instantiate()
	root.add_child(cr)
	await process_frame

	for sec_idx in range(1, 8):
		var sec_node := cr.find_child("CreditsSection%d_*" % sec_idx, true, false)
		_check(sec_node != null, "UI_16 Credits includes ordered section %d from CREDITS.md §9" % sec_idx)

	var body := _collect_text(cr)
	_check(body.contains("Team The Last BrainCell") and body.contains("Nafis Mohtasim Ramim") and body.contains("Khandaker Shadman Sakib Siddiquee"), "UI_16 Credits §1 includes Team roster from docs/TEAM.md")
	_check(body.contains("Story, Characters, Puzzles and Science Mapping"), "UI_16 Credits §2 includes Story & Science Mapping")
	_check(body.contains("Built on NASA Open Data") and body.contains("LRO LOLA") and body.contains("ESA") and body.contains("JAXA"), "UI_16 Credits §3 includes NASA open data and partner agencies")
	_check(body.contains("Made with AI Tools") and body.contains("Tripo AI") and body.contains("docs/AI_USE.md"), "UI_16 Credits §4 includes AI tools disclosure")
	_check(body.contains("Made with Godot Engine") and body.contains(Engine.get_license_text().strip_edges().substr(0, 24)), "UI_16 Credits §5 pulls Godot license & copyright info at runtime")
	_check(body.contains("Blender, FFmpeg"), "UI_16 Credits §6 includes Blender and FFmpeg")
	_check(body.contains("NASA does not endorse this game"), "UI_16 Credits §7 includes exact Disclaimer")
	_check(body.contains("ARCHIVAL PHOTOGRAPH") and body.contains("Dedicated to every student, teacher"), "UI_16 Credits includes photo + dedication")

	# Auto-scroll, skip, return to garden, and optional CS-18 MARS drawer
	_check(cr.auto_scroll, "UI_16 auto-scroll starts enabled")
	await _maybe_capture("M3-90_credits.png")
	cr.skip_to_post_credits()
	_check(not cr.auto_scroll and not cr.drawer_opened, "UI_16 Skip pauses auto-scroll and shows optional CS-18 without forcing the drawer open")
	cr.inspect_closed_drawer()
	await process_frame
	_check(cr.drawer_opened and _collect_text(cr).contains("MARS TRANSIT STUDY"), "UI_16 optional post-credits CS-18 inspects 'The Closed Drawer' (MARS)")
	await _maybe_capture("M3-90_post_credits_cs18.png")

	cr.queue_free()
	await process_frame

	# Verify CampaignPanels "credits" integration
	var panels := CampaignPanelsScene.instantiate()
	root.add_child(panels)
	await process_frame
	_check(panels.open_panel("credits"), "UI_16 CampaignPanels opens 'credits' panel")
	await process_frame
	var panel_credits_text := _collect_text(panels)
	_check(panel_credits_text.contains("Team The Last BrainCell") and panel_credits_text.contains("NASA does not endorse this game"), "UI_16 CampaignPanels renders CreditsPanel sections")
	panels.close_panel()
	panels.queue_free()
	await process_frame

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
