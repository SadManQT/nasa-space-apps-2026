## Doc 25 §8.1–8.2 (M1-54): walks every Chapter 1 scene through the flat HUD,
## the shared panels and the 3D room signs, and fails on any visible developer language (scene
## IDs, puzzle codes, single-letter variables, engineering verbs), and checks
## that free movement keeps the centre third of the screen clear.
## Canon dialogue, measured data and a data card's computation trail (meta
## "verbatim") stay word for word, so only internal IDs are checked there. The Mission Table has its own layout (M1-55
## adds it to this walk).
##   Godot --headless --path game --script res://tools/test_player_text.gd
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
const PANELS := ["what_now", "pause", "settings_accessibility", "journal_discovery", "outcome", "puzzle", "dialogue_captions", "sources", "resume", "chapter1_outcome"]
## The HUD pieces that may show while the player walks (doc 25 §2.2).
const FREE_MOVEMENT := ["GoalCard", "TopRight", "Prompt", "GoalMarker"]

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var _patterns: Array[RegEx] = []
var _seen := {}

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	# §8.1's patterns, plus the project's other internal ID prefixes (LOC-02, MSG-CH01-001, CS-03, SFX-…, CUE-…, J-CH01-…).
	for source in ["EX-CH\\d", "\\bP-\\d\\d\\b", "\\b[EAWKSZCRH] ?\\d", "\\b(LOC|MSG|CS|SFX|CUE|J)-[A-Z0-9]{2}", "air_depleted_shift_|exposure_limit_exceeded_shift_|MISSION[ _]STOPPED|BUNK SLOT|Run the STACK task|bundle task|forces COOL", "(?i)\\b(commit\\w*|stage[sd]?|acknowledg\\w*|role constraints?|operations?)\\b"]:
		var regex := RegEx.new()
		regex.compile(source)
		_patterns.append(regex)
	if not storage.setup("M1-54-player-text"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	var hud := campaign.hud
	_check(hud != null and campaign.route != null, "campaign and HUD initialise")
	if hud == null or campaign.route == null:
		_finish()
		return
	await _walk_first_table(campaign)
	PlanFixture.prepare(campaign.route)
	var scenes := Gates.scene_ids()
	for scene_id in scenes:
		await _walk_state(hud, scene_id + " entry")
		var guard := 0
		while (hud.get("_dialogue_bar") as Control).visible and not (hud.get("_next_line") as Button).disabled and guard < 200:
			await _walk_state(hud, scene_id + " dialogue")
			hud.call("_on_next_line")
			guard += 1
		await create_timer(0.5).timeout  # the dialogue bar fades out
		_check_free_movement(hud, scene_id)
		hud.panels.set_accessibility({"large_text": true})
		hud.apply_accessibility()
		await process_frame
		_check_free_movement(hud, scene_id + " at 150% text")
		hud.panels.set_accessibility({"large_text": false})
		hud.apply_accessibility()
		for panel_id in PANELS:
			hud.panels.open_panel(panel_id)
			await _walk_state(hud, "%s panel %s" % [scene_id, panel_id])
			if panel_id == "journal_discovery":
				for hint in 3:
					var reveal := hud.panels.get("_body").get_node_or_null("RevealHint") as Button
					if reveal != null:
						reveal.pressed.emit()
						await _walk_state(hud, "%s journal hint %d" % [scene_id, hint + 1])
						hud.panels.hint_player.close()
				for tab in ["evidence", "garden", "decisions"]:
					hud.panels.select_journal_tab(tab)
					await _walk_state(hud, "%s journal %s" % [scene_id, tab])
				hud.panels.select_journal_tab("now")
			if panel_id == "chapter1_outcome" and hud.show_chapter1_outcome():
				for large in [false, true]:
					hud.panels.set_accessibility({"large_text": large})
					await _walk_state(hud, "ending summary large=%s" % large)
					(hud.panels.find_child("ReviewDecisions", true, false) as Button).pressed.emit()
					for shift in 7:
						await _walk_state(hud, "ending replay %d large=%s" % [shift, large])
						(hud.panels.find_child("ReplayNext", true, false) as Button).pressed.emit()
					for lesson in 3:
						await _walk_state(hud, "science debrief %d large=%s" % [lesson, large])
						if lesson < 2:
							(hud.panels.find_child("DebriefNext", true, false) as Button).pressed.emit()
					hud.show_chapter1_outcome()
				hud.panels.set_accessibility({"large_text": false})
			hud.panels.close_panel()
		var targets := Gates.targets_for_scene(scene_id)
		if scene_id == "EX-CH01-S03":
			targets.push_back(targets.pop_front())
			targets.push_back(targets.pop_at(3))
		for target in targets:
			if P02MissionTable.is_gate(String(target.target_id)):
				await _walk_table(campaign, String(target.target_id))
			var result: Dictionary = campaign.route.perform(String(target.target_id))
			hud.refresh_after_action(result)
			await _walk_state(hud, "%s after %s" % [scene_id, target.target_id])
		if scene_id == scenes[-1]:
			if hud.panels.active_panel() == "chapter1_outcome":
				hud.panels.close_panel()
			var completed: Dictionary = campaign.route.advance_scene()
			campaign._sync_route_projection()
			hud.refresh_scene({"chapter_complete": completed.get("chapter_complete", false)})
			await _walk_state(hud, "chapter complete")
			break
		var advanced: Dictionary = campaign.advance_scene()
		_check(bool(advanced.get("accepted", false)), "advance " + scene_id)
		if campaign.loading:
			await campaign.wait_loading()
	for source_id in hud.panels.science.source_ids():
		hud.panels.open_panel("data_card", {"source_id": source_id})
		await _walk_state(hud, "data card " + String(source_id))
	hud.panels.close_panel()
	await _walk_failed_table()
	_check(_seen.size() > 150, "the walk read many distinct player strings (%d)" % _seen.size())
	_finish()

## Every string the player can read right now, with no developer language in it.
func _walk_state(hud: Control, state: String) -> void:
	await process_frame
	var texts: Array[String] = []
	_visible_text(hud.get("runtime"), texts)  # the HUD, its panels and 3D signs in the world
	var bad: Array[String] = []
	for entry in texts:
		var story := entry.begins_with("\u0001")
		var text := entry.trim_prefix("\u0001")
		_seen[text] = true
		for regex in ([_patterns[0], _patterns[1], _patterns[3]] if story else _patterns):
			var found: RegExMatch = (regex as RegEx).search(text)
			if found != null:
				bad.append("\"%s\" in \"%s\"" % [found.get_string(), text.left(90)])
	_check(bad.is_empty(), "no developer language: %s %s" % [state, "; ".join(bad)])

func _visible_text(node: Node, out: Array[String]) -> void:
	if (node is CanvasItem and not (node as CanvasItem).is_visible_in_tree()) or (node is Node3D and not (node as Node3D).is_visible_in_tree()):
		return
	if node is Label:
		out.append(("\u0001" if node.has_meta("verbatim") else "") + (node as Label).text)
	elif node is Button:
		out.append((node as Button).text)
	elif node is Label3D:
		out.append((node as Label3D).text)
	elif node is RichTextLabel:
		out.append((node as RichTextLabel).get_parsed_text())
	for child in node.get_children():
		_visible_text(child, out)

## §8.2: while walking only the goal card, the top-right toast and strip, the
## prompt and the goal marker show, and none but the prompt and marker (which
## sit on the object itself) reaches into the centre third.
func _check_free_movement(hud: Control, scene_id: String) -> void:
	var view := hud.get_viewport_rect().size
	var centre := Rect2(view / 3.0, view / 3.0)
	var extra: Array[String] = []
	for child in hud.get_children():
		if not child is Control or not (child as Control).is_visible_in_tree():
			continue
		var control := child as Control
		if control == hud.panels:
			if hud.panels.active_panel() != "":
				extra.append("panel " + hud.panels.active_panel())
			continue
		if control.name in FREE_MOVEMENT:
			if control.name in ["GoalCard", "TopRight"] and control.get_global_rect().intersects(centre):
				extra.append("%s covers the centre %s" % [control.name, control.get_global_rect()])
			continue
		if control is MissionTablePanel and not (control as MissionTablePanel).is_open():
			continue
		extra.append(String(control.name))
	_check(extra.is_empty(), "free movement shows only the goal, prompt, toast and strip, centre clear: %s %s" % [scene_id, ", ".join(extra)])

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + label)

func _finish() -> void:
	storage.cleanup()
	print("PLAYER TEXT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _walk_first_table(campaign: Chapter1Campaign) -> void:
	var route = preload("res://scripts/missions/chapter1_route.gd").new(preload("res://scripts/core/campaign_director.gd").new())
	_reach_route(route, "EX-CH01-S07")
	route.perform("role_cards")
	var table := campaign.hud.mission_table
	table.open(route, "p02_shift1")
	await _walk_state(campaign.hud, "Mission Table guide air")
	table.choose(1, "air_production", 2)
	await _walk_state(campaign.hud, "Mission Table guide light")
	table.choose(1, "light", "FULL")
	await _walk_state(campaign.hud, "Mission Table guide try")
	for id in ["kai", "amara"]:
		table.share_card(id)
		(table.find_child("More_" + id, true, false) as Button).pressed.emit()
		await _walk_state(campaign.hud, "Mission Table full note " + id)
	(table.find_child("TableMore", true, false) as Button).pressed.emit()
	await _walk_state(campaign.hud, "Mission Table More")
	table.preview()
	table.request_commit()
	await _walk_state(campaign.hud, "Mission Table first confirmation")
	table.cancel_confirm()
	table.close()

func _walk_table(campaign: Chapter1Campaign, id: String) -> void:
	var table := campaign.hud.mission_table
	for card in campaign.route.mission_table().role_cards(int(campaign.director.query().current_shift)):
		if card.arrived:
			campaign.route.mission_table().share(card.role_id, int(campaign.director.query().current_shift))
	table.open(campaign.route, id)
	await _walk_state(campaign.hud, "Mission Table " + id)
	if id == "p02_shift5_alarm":
		await _walk_alarm_text(table, campaign.hud)
	for card in table.view().cards:
		if card.arrived:
			(table.find_child("More_" + String(card.role_id), true, false) as Button).pressed.emit()
	await _walk_state(campaign.hud, "Mission Table all arrived notes " + id)
	(table.find_child("TableMore", true, false) as Button).pressed.emit()
	for hint in 3:
		table.reveal_hint()
		await _walk_state(campaign.hud, "Mission Table hint %d %s" % [hint + 1, id])
		campaign.hud.panels.hint_player.close()
	campaign.hud.panels.hint_player.show_how_to("mission_table")
	await _walk_state(campaign.hud, "Mission Table How to " + id)
	campaign.hud.panels.hint_player.close()
	await _walk_state(campaign.hud, "Mission Table More " + id)
	table.preview()
	table.request_commit()
	await _walk_state(campaign.hud, "Mission Table confirmation " + id)
	table.cancel_confirm()
	table.close()

func _walk_alarm_text(table: MissionTablePanel, hud: Control) -> void:
	var saved: Dictionary = table._table().snapshot()
	for action in ["PUMP", "STACK", "WAIT"]:
		table.choose(5, "action", action)
		await _walk_state(hud, "Mission Table alarm choice " + action)
		if action == "WAIT":
			continue
		table.start_task()
		table.task_step(0)
		await _walk_state(hud, "Mission Table running task " + action)
		table.end_task()
		await _walk_state(hud, "Mission Table partial task " + action)
		table._table().reset_alarm_task()
		table.start_task()
		for index in table._table().alarm_task_steps():
			table.task_step(index)
		table.end_task()
		await _walk_state(hud, "Mission Table complete task " + action)
	_check(table._table().restore(saved).accepted, "text walk restores the actual written alarm plan")
	table._render()

func _walk_failed_table() -> void:
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	PlanFixture.prepare(campaign.route)
	campaign.route.mission_table().set_choice(1, "air_production", 0)
	_reach_route(campaign.route, "EX-CH01-S11")
	campaign._sync_route_projection()
	campaign._refresh_world()
	await campaign.wait_loading()
	campaign.route.perform("verify_exposure_order")
	campaign.route.perform("return_water")
	campaign.hud.refresh_scene()
	_check(campaign.hud.open_mission_table("p02_shifts6_7"), "a failing plan opens through the real campaign HUD")
	if campaign.hud.panels.hint_player.is_open():
		await _walk_state(campaign.hud, "Mission Table first-time How to")
		campaign.hud.panels.hint_player.close()
	var table := campaign.hud.mission_table
	for card in table.view().cards:
		if card.arrived:
			table.share_card(String(card.role_id))
	var prediction: Dictionary = table.preview()
	_check(prediction.accepted and not prediction.forecast.unsafe_predicates.is_empty(), "the failed plan has a real unsafe forecast")
	await _walk_state(campaign.hud, "Mission Table failing forecast")
	table.request_commit()
	await _walk_state(campaign.hud, "Mission Table failing confirmation")
	var target := campaign.physical_target("p02_shifts6_7")
	campaign._player.global_position = Vector3(target.global_position.x, 0, target.global_position.z + 1)
	await physics_frame
	await physics_frame
	table.confirm_commit()
	await _walk_state(campaign.hud, "failed plan actual toast and ending")
	_check(String(campaign.route.chapter_ready().ending) == "MISSION_STOPPED", "real failed lock-in reaches stopped attempt")
	_check(String(campaign.hud._status.text).contains("Air reached zero"), "actual toast explains the failed plan")
	campaign.hud.panels.close_panel()
	await _walk_state(campaign.hud, "failed plan actual visible toast")
	_check(campaign.hud._status.is_visible_in_tree(), "failed plan toast is visible after closing its report")
	campaign.hud.panels.open_panel("outcome", campaign.hud._last_outcome)
	await _walk_state(campaign.hud, "failed plan actual Last result")
	_check(String(campaign.hud._last_outcome.result).contains("Air reached zero"), "actual Last result keeps the helpful cause")
	campaign.free()

func _reach_route(route: RefCounted, destination: String) -> void:
	while route.current_scene_id() != destination:
		var scene_id: String = route.current_scene_id()
		var ids: Array = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"] if scene_id == "EX-CH01-S03" else Gates.targets_for_scene(scene_id).map(func(spec): return String(spec.target_id))
		for id in ids:
			route.perform(id)
		if not route.advance_scene().accepted:
			_check(false, "text walk reaches " + destination + " from " + scene_id)
			return
