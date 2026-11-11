## M1-37: Solo / Class crew choice, private role-card hand-off and the team-plan
## sign-off on the real Mission Table panel, wired to the M1-103 route API.
extends SceneTree

const MainScript = preload("res://scripts/main.gd")
const CampaignScript = preload("res://scripts/campaign/chapter1_campaign.gd")
const CrewScript = preload("res://scripts/classmode/crew_modes.gd")
const TableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
const PanelScene = preload("res://scenes/ui/mission_table_panel.tscn")
const ChoiceScene = preload("res://scenes/ui/crew_choice_overlay.tscn")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_data()
	await _check_choice()
	await _check_class_table()
	await _check_solo_table()
	print("CLASS MODE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check_data() -> void:
	var data := CrewScript.data()
	_check(not data.is_empty(), "crew_modes.json loads")
	var raw := FileAccess.get_file_as_string(CrewScript.DATA_PATH) + FileAccess.get_file_as_string("res://resources/campaign/content/p02_mission_table.json")
	var bangla := RegEx.create_from_string("[\\x{0980}-\\x{09FF}]")
	_check(bangla.search(raw) == null, "role data has no Bangla script")
	var card_ids: Array = TableScript.data().get("role_cards", []).map(func(card): return String(card.role_id))
	card_ids.sort()
	var order: Array = CrewScript.ROLE_ORDER.duplicate()
	order.sort()
	_check(card_ids == order, "crew roles match the P-02 role cards")
	for players in [2, 3, 4]:
		var held: Array = []
		var mei_seat := -1
		var rafi_seat := -1
		for seat in CrewScript.seats({"mode": "class", "players": players}):
			held.append_array(seat.role_ids)
			if seat.role_ids.has("mei"):
				mei_seat = seat.seat
			if seat.role_ids.has("rafi"):
				rafi_seat = seat.seat
		held.sort()
		_check(held == order and CrewScript.seats({"mode": "class", "players": players}).size() == players, "%d-player seat plan holds every role exactly once" % players)
		_check(mei_seat != rafi_seat, "%d players: Mei and Rafi never share a seat" % players)
	for section in ["handoff", "table", "team_plan", "menu", "print"]:
		var values: Dictionary = data.get(section, {})
		_check(not values.is_empty() and values.values().all(func(value): return not str(value).is_empty()), "every %s line comes from data" % section)
	_check(CrewScript.holder_label({"mode": "solo", "players": 1}, "rafi") == "You", "Solo holds every role")

func _check_choice() -> void:
	var overlay := ChoiceScene.instantiate() as CrewChoiceOverlay
	root.add_child(overlay)
	await process_frame
	var picked: Array = []
	var cancels: Array = []
	overlay.chosen.connect(func(crew): picked.append(crew))
	overlay.cancelled.connect(func(): cancels.append(true))
	for name in ["Crew_solo_1", "Crew_class_2", "Crew_class_3", "Crew_class_4", "CrewBack"]:
		var button := overlay.find_child(name, true, false) as Button
		_check(button != null and button.size.y >= 44.0, name + " exists with a 44 px target")
		if button != null:
			button.pressed.emit()
	_check(picked == [{"mode": "solo", "players": 1}, {"mode": "class", "players": 2}, {"mode": "class", "players": 3}, {"mode": "class", "players": 4}], "each choice emits its crew: " + JSON.stringify(picked))
	_check(cancels.size() == 1, "Back cancels without choosing")
	for crew in picked:
		_check(bool(MainScript.build_new_expedition_snapshot(crew).get("accepted", false)), "the landed New Expedition contract accepts " + JSON.stringify(crew))
	_check(FileAccess.get_file_as_string("res://scripts/main.gd").contains("new_expedition_requested.connect(_choose_crew)"), "the title's New Expedition opens the crew choice")
	overlay.queue_free()
	await process_frame

func _route_at_p02(crew: Dictionary) -> RefCounted:
	var fresh: Dictionary = MainScript.build_new_expedition_snapshot(crew)
	var restored: Dictionary = CampaignScript.restore_session(fresh.snapshot)
	var route: RefCounted = restored.route
	PlanFixture.prepare(route)
	var attempts := 0
	while route.current_scene_id() != "EX-CH01-S07" and attempts < 12:
		attempts += 1
		var ids: Array = []
		if route.current_scene_id() == "EX-CH01-S03":
			ids = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]
		else:
			for spec in GateCatalog.targets_for_scene(route.current_scene_id()):
				ids.append(String(spec.target_id))
		for target_id in ids:
			if target_id == "calibrate_probe":
				PlantInput.complete_probe_transfer(route)
			route.perform(target_id, PlantInput.payload(target_id))
		if not bool(route.advance_scene().get("accepted", false)):
			break
	route.perform("role_cards")
	return route

func _check_class_table() -> void:
	var route := _route_at_p02({"mode": "class", "players": 4})
	_check(route.current_scene_id() == "EX-CH01-S07", "Class route reaches the P-02 station")
	var panel := PanelScene.instantiate() as MissionTablePanel
	root.add_child(panel)
	await process_frame
	var commits: Array = []
	panel.commit_requested.connect(func(target, plan): commits.append([target, plan]))
	panel.open(route, "p02_shift1")
	await process_frame
	_check(panel.class_mode() and panel.crew() == {"mode": "class", "players": 4}, "the table reads the Class crew from the route")
	var kai_fact := String(TableScript.data().role_cards[0].facts[0])
	_check(not _shows(panel, kai_fact), "private notes are hidden on the shared table")
	_check(panel.find_child("Read_kai", true, false) != null and panel.find_child("Share_kai", true, false) == null, "a note must be read privately before it can be shared")
	_check(not bool(panel.share_card("kai").accepted), "sharing an unread note is refused")
	var handoff := panel.handoff()
	_check(panel.read_card(), "the notes round opens the privacy hand-off")
	var arrived := 0
	while handoff.is_open():
		var state := handoff.state()
		_check(state.stage == "cover" and not _shows(handoff, kai_fact), "cover for %s shows no facts" % state.role_id)
		handoff.reveal()
		var card: Dictionary = TableScript.data().role_cards.filter(func(item): return String(item.role_id) == String(state.role_id))[0]
		_check(_shows(handoff, String(card.facts[0])), "%s's revealed note shows its own fact" % state.role_id)
		handoff.hide_card()
		arrived += 1
	await process_frame
	_check(arrived == 2, "shift 1 passes the two arrived notes (Kai, Amara) round")
	for role_id in ["kai", "amara"]:
		_check(bool(panel.share_card(role_id).accepted), role_id + " shares after the private read")
	_check(bool(panel.preview().accepted), "the forecast previews the complete plan")
	_check(bool(panel.request_commit().accepted), "Lock in opens the team plan")
	await process_frame
	_check(panel.find_child("SignOffs", true, false) != null, "the team plan shows four sign-off rows")
	_check((panel.find_child("ConfirmCommit", true, false) as Button).disabled, "operator lock-in is disabled before sign-off")
	var before: Dictionary = route.director().snapshot()
	_check(not bool(panel.confirm_commit().accepted) and commits.is_empty(), "operator cannot lock in with missing signatures")
	for role_id in CrewScript.ROLE_ORDER:
		_check(bool(panel.sign_off(role_id).accepted), role_id + " signs through route.sign_team_plan")
	_check(route.team_plan_view("p02_shift1").signed_roles.size() == 4, "the route holds four signatures")
	await process_frame
	_check(not (panel.find_child("ConfirmCommit", true, false) as Button).disabled, "lock-in is enabled after four signatures")
	_check(route.director().snapshot() == before, "signing changes no simulation state")
	_check(bool(panel.confirm_commit().accepted) and commits.size() == 1, "operator locks in the signed plan")
	if commits.size() == 1:
		_check(bool(route.perform(commits[0][0], {"plan": commits[0][1]}).get("accepted", false)), "the route commits the signed Class plan")
	panel.queue_free()
	await process_frame

func _check_solo_table() -> void:
	var route := _route_at_p02({"mode": "solo", "players": 1})
	var panel := PanelScene.instantiate() as MissionTablePanel
	root.add_child(panel)
	await process_frame
	var commits: Array = []
	panel.commit_requested.connect(func(target, plan): commits.append([target, plan]))
	panel.open(route, "p02_shift1")
	await process_frame
	_check(not panel.class_mode() and panel.find_child("Share_kai", true, false) != null and panel.find_child("Read_kai", true, false) == null, "Solo keeps the public crew notes")
	for role_id in ["kai", "amara"]:
		_check(bool(panel.share_card(role_id).accepted), "Solo shares " + role_id + " without a hand-off")
	panel.preview()
	panel.request_commit()
	await process_frame
	_check(panel.find_child("SignOffs", true, false) == null, "Solo has no sign-off round")
	_check(bool(panel.confirm_commit().accepted) and commits.size() == 1, "Solo locks in directly")
	if commits.size() == 1:
		_check(bool(route.perform(commits[0][0], {"plan": commits[0][1]}).get("accepted", false)), "the route commits the Solo plan")
	panel.queue_free()
	await process_frame

func _shows(node: Node, text: String) -> bool:
	for label in node.find_children("*", "Label", true, false):
		if (label as Label).is_visible_in_tree() and (label as Label).text.contains(text.left(30)):
			return true
	return false

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("  FAIL " + message)
