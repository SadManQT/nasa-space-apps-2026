## M1-103: Class crew survives the real session/save boundary, while P-02
## physical commits require an exact reviewed plan signed by every role.
extends SceneTree

const MainScript = preload("res://scripts/main.gd")
const CampaignScript = preload("res://scripts/campaign/chapter1_campaign.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const DialogueScript = preload("res://scripts/dialogue/dialogue_service.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var invalid: Array = [
		{"mode": "class", "players": 1},
		{"mode": "class", "players": 2.5},
		{"mode": "squad", "players": 4},
		{"mode": "solo", "players": 1, "extra": true},
	]
	for crew in invalid:
		_check(not bool(MainScript.build_new_expedition_snapshot(crew).get("accepted", false)), "invalid fresh crew is rejected: " + JSON.stringify(crew))
	var fresh: Dictionary = MainScript.build_new_expedition_snapshot({"mode": "class", "players": 4})
	_check(bool(fresh.get("accepted", false)), "Class New Expedition creates a resumable physical route")
	if not bool(fresh.get("accepted", false)):
		_finish()
		return
	var restored: Dictionary = CampaignScript.restore_session(fresh.snapshot)
	_check(bool(restored.get("accepted", false)) and restored.director.crew() == {"mode": "class", "players": 4}, "fresh campaign restore retains Class/4")
	if not bool(restored.get("accepted", false)):
		_finish()
		return
	var campaign: Chapter1Campaign = CampaignScript.new()
	campaign.director = restored.director
	campaign.route = restored.route
	campaign.content = ContentScript.load_full()
	campaign._dialogue = DialogueScript.new(campaign.content)
	var crew_view: Dictionary = campaign.query().get("crew", {})
	_check(crew_view == {"mode": "class", "players": 4} and typeof(crew_view.players) == TYPE_INT, "campaign query exposes a primitive Class/4 crew view")
	crew_view["players"] = 2
	_check(campaign.director.crew().players == 4, "mutating the query crew view cannot change the session crew")
	var route: RefCounted = restored.route
	_reach(route, "EX-CH01-S03")
	campaign._sync_route_projection()
	PlantInput.complete_probe_transfer(route)
	var p01_payload: Dictionary = PlantInput.payload("calibrate_probe")
	var class_view: Dictionary = campaign.class_team_plan_view("calibrate_probe", p01_payload)
	_check(bool(class_view.get("accepted", false)) and class_view.get("required_roles", []).size() == 4, "later puzzle provider exposes four roles and the chosen P-01 input")
	if bool(class_view.get("accepted", false)):
		var before_class: Dictionary = campaign.director.snapshot()
		var unsigned_class: Dictionary = campaign._class_commit_hold("calibrate_probe", p01_payload)
		_check(bool(unsigned_class.get("class_team_plan_required", false)) and campaign.director.snapshot() == before_class, "plain Class puzzle commit holds without changing state")
		var forged_class: Dictionary = class_view.selection.duplicate(true)
		forged_class["state_revision"] = int(forged_class.state_revision) + 1
		_check(not bool(campaign.sign_class_team_plan("kai", "calibrate_probe", p01_payload, forged_class).get("accepted", false)), "forged later-puzzle revision cannot sign")
		_check(not bool(campaign.sign_class_team_plan("unknown", "calibrate_probe", p01_payload, class_view.selection).get("accepted", false)), "unknown later-puzzle role cannot sign")
		var changed_payload: Dictionary = p01_payload.duplicate(true)
		changed_payload["raw_reading"] = 11
		_check(not bool(campaign.sign_class_team_plan("kai", "calibrate_probe", changed_payload, class_view.selection).get("accepted", false)), "a changed later-puzzle input cannot reuse the reviewed choice")
		for role_id in class_view.required_roles:
			_check(bool(campaign.sign_class_team_plan(String(role_id), "calibrate_probe", p01_payload, class_view.selection).get("accepted", false)), String(role_id) + " signs the exact later-puzzle forecast")
		_check(bool(campaign.sign_class_team_plan("kai", "calibrate_probe", p01_payload, class_view.selection).get("duplicate", false)), "repeat later-puzzle signature is idempotent")
		_check(campaign._class_commit_hold("calibrate_probe", p01_payload).is_empty(), "four current signatures permit the later-puzzle commit")
		campaign.cancel_class_team_plan()
		_check(bool(campaign._class_commit_hold("calibrate_probe", p01_payload).get("class_team_plan_required", false)), "cancelling a Class review invalidates every signature")
	campaign.free()
	PlanFixture.prepare(route)
	_reach(route, "EX-CH01-S07")
	_check(route.current_scene_id() == "EX-CH01-S07" and bool(route.perform("role_cards").get("accepted", false)), "Class route reaches the actual P-02 station")
	var view: Dictionary = route.team_plan_view("p02_shift1")
	for card in route.mission_table().role_cards(0):
		if bool(card.arrived):
			route.mission_table().share(String(card.role_id), 0)
	view = route.team_plan_view("p02_shift1")
	_check(bool(view.get("ready", false)) and view.required_roles.size() == 4 and view.selection is Dictionary, "P-02 exposes a complete reviewed plan and four private-card roles")
	var before: Dictionary = route.director().snapshot()
	var unsigned: Dictionary = route.perform("p02_shift1")
	_check(not bool(unsigned.get("accepted", false)) and route.director().snapshot() == before, "plain physical USE cannot commit an unsigned Class plan")
	_check(not bool(route.sign_team_plan("kai", "p02_shift1", {}).get("accepted", false)), "missing reviewed selection is rejected")
	_check(not bool(route.sign_team_plan("unknown", "p02_shift1", view.selection).get("accepted", false)), "unknown role cannot sign")
	var forged: Dictionary = view.selection.duplicate(true)
	forged["state_revision"] = int(forged.state_revision) + 1
	_check(not bool(route.sign_team_plan("kai", "p02_shift1", forged).get("accepted", false)), "forged revision cannot be signed")
	var roles: Array = view.required_roles
	for role_id in roles:
		_check(bool(route.sign_team_plan(String(role_id), "p02_shift1", view.selection).get("accepted", false)), String(role_id) + " signs the exact forecast")
	_check(bool(route.sign_team_plan(String(roles[0]), "p02_shift1", view.selection).get("duplicate", false)), "repeat sign-off is idempotent")
	var signed: Dictionary = route.team_plan_view("p02_shift1")
	_check(signed.signed_roles.size() == 4, "all four sign-offs appear in the current route view")
	var old_light := String(route.mission_table().selection(1).light)
	var changed_light := "FULL" if old_light != "FULL" else "DIM"
	_check(bool(route.mission_table().set_choice(1, "light", changed_light).get("accepted", false)), "a player can change the selected plan")
	var changed: Dictionary = route.team_plan_view("p02_shift1")
	_check(changed.signed_roles.is_empty() and changed.stale_roles.size() == 4, "changed plan invalidates every prior sign-off")
	_check(not bool(route.perform("p02_shift1").get("accepted", false)) and route.director().snapshot() == before, "changed plan cannot commit with stale signatures")
	var save_snapshot: Dictionary = route.director().snapshot()
	# Production projects the physical route's scene into the campaign state
	# before saving. This route-only fixture applies that same primitive shape.
	save_snapshot["scene_id"] = route.current_scene_id()
	save_snapshot["mission_id"] = route.current_mission_id()
	save_snapshot["checkpoint_id"] = route.current_scene_id() + "-CHECKPOINT"
	save_snapshot["completed_scene_ids"] = route.completed_scene_ids()
	save_snapshot["route_runtime"] = route.snapshot()
	var save_path := OS.get_temp_dir().path_join("lla-m1103-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	var service: RefCounted = SaveScript.new()
	service.session_validator = CampaignScript.restore_session
	var saved: Dictionary = service.save(save_snapshot, save_path)
	_check(bool(saved.get("accepted", false)), "Class campaign and route save through the real save service: " + String(saved.get("reason", "")))
	var loaded: Dictionary = service.load(save_path)
	var loaded_crew: Dictionary = loaded.get("snapshot", {}).get("crew", {})
	_check(bool(loaded.get("accepted", false)) and String(loaded_crew.get("mode", "")) == "class" and int(loaded_crew.get("players", 0)) == 4, "Continue loads the same Class crew: " + JSON.stringify(loaded_crew))
	if bool(loaded.get("accepted", false)):
		var resumed: Dictionary = CampaignScript.restore_session(loaded.snapshot)
		_check(bool(resumed.get("accepted", false)) and resumed.director.crew() == {"mode": "class", "players": 4}, "fresh route objects restore Class crew")
		if bool(resumed.get("accepted", false)):
			_check(resumed.route.team_plan_view("p02_shift1").signed_roles.is_empty(), "save/load never persists ephemeral sign-offs")
	_check(service.clear(save_path), "isolated Class save is removed")
	var retry_result: Dictionary = route.retry()
	_check(bool(retry_result.get("accepted", false)) and route.director().crew() == {"mode": "class", "players": 4}, "retry retains the fixed Class crew")
	_reach(route, "EX-CH01-S07")
	_check(route.team_plan_view("p02_shift1").signed_roles.is_empty(), "retry clears prior sign-offs")
	var legacy: Dictionary = MainScript.build_new_expedition_snapshot({"mode": "solo", "players": 1}).snapshot
	legacy.erase("crew")
	var legacy_session: Dictionary = CampaignScript.restore_session(legacy)
	_check(bool(legacy_session.get("accepted", false)) and legacy_session.director.crew() == {"mode": "solo", "players": 1}, "old save without a crew field restores as Solo/1")
	_finish()

func _reach(route: RefCounted, scene_id: String) -> void:
	var attempts := 0
	while route.current_scene_id() != scene_id and attempts < 12:
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

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("  FAIL " + message)

func _finish() -> void:
	print("CLASS SESSION BRIDGE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
