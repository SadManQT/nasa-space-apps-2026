## P-02 Seven Shifts at the Mission Table (M1-09): the player's plan drives
## every shift, preview and commit agree, the documented witnesses reproduce
## exactly, blackout is only below zero, every ending predicate holds, and the
## PUMP / STACK / WAIT alarm responses behave as the numeric contract says.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const TableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/mission_table_panel.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const RESOURCE_KEYS := ["E", "A", "H", "W", "K", "C", "R", "Z"]

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_model_rules()
	_test_role_cards_and_hints()
	_test_play_path_has_no_default_plan()
	for plan_id in ["bloom", "golden", "pump", "stack"]:
		_test_witness_through_route(plan_id)
	_test_blackout_boundary()
	_test_ending_predicates()
	_test_alarm_responses()
	_test_persistence_and_retry()
	await _test_panel()
	await _test_campaign_integration()
	print("P02 MISSION TABLE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

# --- Model -------------------------------------------------------------------

func _test_model_rules() -> void:
	var table := TableScript.new()
	_check(TableScript.gate_shifts("p02_shifts3_4") == [3, 4] and TableScript.gate_shifts("p02_shift5_alarm") == [5], "gates resolve their exact shifts from the data file")
	_check(not TableScript.fields_for_shift(1).has("heat") and TableScript.fields_for_shift(3).has("heat"), "daylight heat is automatic; night heat is a player choice")
	_check(table.plan_for_gate("p02_shift1").is_empty(), "an unplanned gate has no plan (no hidden default)")
	_check(not bool(table.set_choice(1, "heat", "COZY").accepted), "DAY shifts reject a heat choice")
	_check(not bool(table.set_choice(3, "action", "PUMP").accepted), "PUMP/STACK/WAIT are rejected outside shift 5")
	_check(not bool(table.set_choice(5, "transfer", "FILL").accepted), "shift 5 has no ordinary transfer")
	_check(not bool(table.set_choice(3, "light", "BRIGHT").accepted) and not bool(table.set_choice(3, "air_production", 3).accepted), "illegal light and air values are rejected")
	table.set_choice(1, "air_production", 2)
	table.set_choice(1, "light", "FULL")
	_check(table.plan_for_gate("p02_shift1").is_empty() and table.plan_block_reason("p02_shift1", 0).contains("WATER WALL"), "a partly planned shift names the missing choice")
	table.set_choice(1, "transfer", "HOLD")
	_check(table.plan_for_gate("p02_shift1") == {"shift": {"heat": "DAY", "air_production": 2, "light": "FULL", "transfer": "HOLD"}}, "a complete shift becomes the exact simulation step")
	_check(not bool(table.set_choice(1, "light", "DIM", 1).accepted), "a committed shift is read-only")
	for field in ["heat", "air_production", "light"]:
		table.set_choice(5, field, "COZY" if field == "heat" else (2 if field == "air_production" else "FULL"))
	table.set_choice(5, "action", "STACK")
	var forced := table.selection(5)
	_check(forced.heat == "COOL" and int(forced.air_production) == 0 and forced.light == "OFF", "STACK forces COOL, air maker OFF and light OFF")
	_check(not bool(table.set_choice(5, "heat", "COZY").accepted), "STACK's forced settings cannot be overridden")

func _test_role_cards_and_hints() -> void:
	var table := TableScript.new()
	var cards := table.role_cards(0)
	var arrived := cards.filter(func(card): return bool(card.arrived)).map(func(card): return String(card.role_id))
	_check(arrived == ["kai", "amara"], "Kai and Amara's cards arrive at shift 1")
	var rafi: Dictionary = cards.filter(func(card): return card.role_id == "rafi")[0]
	_check((rafi.facts as Array).is_empty() and String(rafi.quote).is_empty(), "a card that has not arrived reveals no future facts")
	_check(not bool(table.share("rafi", 0).accepted), "an unarrived card cannot be shared")
	_check(table.commit_block_reason("p02_shift1", 0).contains("Kai"), "Mission Table commit waits for shared cards")
	_check(bool(table.share("kai", 0).accepted) and bool(table.share("kai", 0).duplicate), "sharing is recorded once; a repeat is a no-op")
	_check(table.role_cards(1).filter(func(card): return bool(card.arrived)).size() == 3 and table.role_cards(2).filter(func(card): return bool(card.arrived)).size() == 4, "Rafi's card arrives at shift 2 and Mei's at shift 3")
	var hints: Array = []
	for index in 3:
		hints.append(String(table.next_hint().get("text", "")))
	_check(hints == ["Store air while sunlight would overflow.", "Prepare shielding before the alarm, then return the water.", "Open the worked Bloom plan or Guided plan."], "H1-H3 are the canonical hint ladder in order")
	_check(table.unlocked_worked_plans() == ["bloom"], "H3 unlocks the worked Bloom plan")
	_check(not bool(table.next_hint().accepted), "Golden hints stay locked before a first Bloom")
	table.record_ending("BLOOM")
	var g1: Dictionary = table.next_hint()
	var g2: Dictionary = table.next_hint()
	_check(g1.level == "G1" and String(g1.text).begins_with("Golden needs Alo at 5") and g2.text == "Open the worked Golden plan.", "G1/G2 unlock after a first Bloom")
	_check(table.unlocked_worked_plans() == ["bloom", "golden"], "G2 unlocks the worked Golden plan")

func _test_play_path_has_no_default_plan() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/missions/chapter1_route.gd")
	_check(not source.contains("_default_plan"), "the built-in default plan is gone from the route")
	var route := RouteScript.new(DirectorScript.new())
	_reach(route, "EX-CH01-S07")
	route.perform("role_cards")
	var before: Dictionary = route.director().snapshot()
	var rejected: Dictionary = route.perform("p02_shift1")
	_check(not bool(rejected.accepted) and bool(rejected.get("mission_table", false)) and String(rejected.reason).begins_with("Choose") and route.director().snapshot() == before, "an unplanned shift refuses to commit and names the missing choice")

# --- Witnesses ---------------------------------------------------------------

func _test_witness_through_route(plan_id: String) -> void:
	var expected: Dictionary = TableScript.data().worked_plans[plan_id]
	var route := RouteScript.new(DirectorScript.new())
	route.mission_table().apply_worked_plan(plan_id)
	var agreed := true
	for scene_id in GateCatalog.SCENE_ORDER:
		if scene_id == "EX-CH01-S12":
			break
		for target_id in _targets(scene_id):
			if target_id == "p02_shift5_alarm":
				_run_task(route)
			if TableScript.is_gate(target_id) and target_id != "p02_stage_shift2":
				var forecast: Dictionary = route.mission_table_view(target_id).gate_preview
				var result: Dictionary = route.perform(target_id)
				agreed = agreed and bool(result.get("accepted", false)) and _resources(forecast.final_state) == _resources(route.director().snapshot().resources)
			else:
				route.perform(target_id)
		if scene_id != "EX-CH01-S11":
			route.advance_scene()
	var final_state := _resources(route.director().snapshot().resources)
	_check(agreed, plan_id + ": every gate's Mission Table forecast equals its committed state")
	_check(final_state == _resources(expected.expected_final), "%s witness ends exactly %s (got %s)" % [plan_id, JSON.stringify(expected.expected_final), JSON.stringify(final_state)])
	_check(String(route.chapter_ready().ending) == String(expected.expected_ending) and int(route.director().snapshot().get("blackout_count", 0)) == 0, plan_id + " witness reaches " + String(expected.expected_ending) + " with no blackout")

func _run_task(route: RefCounted) -> void:
	var table: RefCounted = route.mission_table()
	if String(table.alarm_state().action) in ["PUMP", "STACK"]:
		table.start_alarm_task(true)
		for index in table.alarm_task_steps():
			table.task_step(index)

# --- Boundaries and endings --------------------------------------------------

func _test_blackout_boundary() -> void:
	var sim := SimulationScript.new()
	var state := sim.entry_profile()
	state.current_shift = 2
	state.resources.E = 3
	var table := TableScript.new()
	table.set_choice(3, "heat", "COZY")
	table.set_choice(3, "air_production", 0)
	table.set_choice(3, "light", "OFF")
	table.set_choice(3, "transfer", "HOLD")
	var exact: Dictionary = sim.preview(state, {"shift": table.step_for_shift(3)})
	var record: Dictionary = exact.trace[0]
	_check(int(exact.final_state.E) == 0 and not bool(record.blackout) and int(exact.snapshot.blackout_count) == 0, "demand of exactly the stored 3 ends at E0 with no blackout")
	_check(int(exact.final_state.A) == 5 and int(exact.final_state.H) == 5, "exactly E0 applies only breathing and the light change, no blackout penalty")
	table.set_choice(3, "light", "DIM")
	var below: Dictionary = sim.preview(state, {"shift": table.step_for_shift(3)})
	_check(bool(below.trace[0].blackout) and int(below.final_state.E) == 0 and int(below.snapshot.blackout_count) == 1, "demand of 4 against 3 (E would be −1) is a blackout and clamps E to 0")
	_check(int(below.final_state.A) == 3 and int(below.final_state.H) == 4 and int(below.final_state.C) == 6, "the −1 blackout applies A−2, H−2 and C−2 before breathing and light")
	_check(bool(TableScript.ending_report(_finish_night(sim, exact.snapshot)).stars.no_blackout), "an E0 shift keeps the no-blackout star")

func _finish_night(sim: RefCounted, snapshot: Dictionary) -> Dictionary:
	var steps: Array = []
	for shift in range(int(snapshot.current_shift) + 1, 8):
		steps.append({"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "WAIT" if shift == 5 else "HOLD"})
	var safe := snapshot.duplicate(true)
	safe.resources.E = 20
	safe.resources.A = 10
	safe.resources.W = 6
	return sim.preview(safe, {"shifts": steps})

func _test_ending_predicates() -> void:
	var sim := SimulationScript.new()
	# ALO_LOST: the crew finishes safely, but Alo reaches 0.
	var state := sim.entry_profile()
	state.current_shift = 6
	state.resources.merge({"E": 10, "A": 5, "H": 1, "W": 0, "Z": 2}, true)
	var lost: Dictionary = sim.preview(state, {"shift": {"heat": "COLD", "air_production": 0, "light": "OFF", "transfer": "HOLD"}})
	var lost_report := TableScript.ending_report(lost)
	_check(lost.ending == "ALO_LOST" and not bool(lost_report.stars.alo_alive) and not bool(lost_report.unlocks_chapter2), "H0 with a safe crew is ALO_LOST and does not unlock Chapter 2")
	# MISSION_STOPPED by air.
	state = sim.entry_profile()
	state.current_shift = 2
	state.resources.A = 1
	var air: Dictionary = sim.preview(state, {"shift": {"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "HOLD"}})
	_check(air.ending == "MISSION_STOPPED" and (air.unsafe_predicates as Array).has("air_depleted_shift_3"), "A<=0 stops the mission with an air cause")
	# GOLDEN needs every star plus H>=5; H4 with every star is only BLOOM.
	state = sim.entry_profile()
	state.current_shift = 6
	state.resources.merge({"E": 10, "A": 5, "H": 4, "W": 0, "Z": 2}, true)
	var bloom: Dictionary = sim.preview(state, {"shift": {"heat": "COZY", "air_production": 0, "light": "DIM", "transfer": "HOLD"}})
	_check(bloom.ending == "BLOOM" and int(TableScript.ending_report(bloom).star_count) == 3, "three stars with H4 is BLOOM, not GOLDEN")
	state.resources.H = 5
	var golden: Dictionary = sim.preview(state, {"shift": {"heat": "COZY", "air_production": 0, "light": "DIM", "transfer": "HOLD"}})
	_check(golden.ending == "GOLDEN" and bool(TableScript.ending_report(golden).unlocks_chapter2), "three stars with H5 is GOLDEN")
	state.blackout_count = 1
	var dimmed: Dictionary = sim.preview(state, {"shift": {"heat": "COZY", "air_production": 0, "light": "DIM", "transfer": "HOLD"}})
	_check(dimmed.ending == "BLOOM" and not bool(TableScript.ending_report(dimmed).stars.no_blackout), "an earlier blackout removes the star and Golden")
	# MISSION_STOPPED by exposure through the real route: WAIT with no wall.
	var route := RouteScript.new(DirectorScript.new())
	var table: RefCounted = route.mission_table()
	table.apply_worked_plan("bloom")
	for shift in [3, 4]:
		table.set_choice(shift, "transfer", "HOLD")
	for shift in [6, 7]:
		table.set_choice(shift, "transfer", "HOLD")
	_play_until(route, "EX-CH01-S11")
	for target_id in ["verify_exposure_order", "return_water", "p02_shifts6_7"]:
		route.perform(target_id)
	var stopped: Dictionary = route.last_result().get("result", {})
	_check(String(stopped.get("ending", "")) == "MISSION_STOPPED" and (stopped.get("unsafe_predicates", []) as Array).has("exposure_limit_exceeded_shift_6") and int(route.director().snapshot().resources.Z) == 6, "an unshielded WAIT exceeds Z3 in shift 6 and flight rules stop the mission")
	_check(not bool(route.chapter_ready().safe_ending) and not bool(route.chapter_ready().ready), "a stopped mission never unlocks Chapter 2")
	var retried: Dictionary = route.retry()
	_check(bool(retried.accepted) and int(route.director().query().current_shift) == 5 and String(route.mission_table().selection(6).get("transfer", "")) == "HOLD", "retry restores the shift-5 checkpoint and keeps the written plan")

func _test_alarm_responses() -> void:
	var table := TableScript.new()
	table.apply_worked_plan("pump")
	_check(table.plan_block_reason("p02_shift5_alarm", 4).contains("PUMP"), "PUMP must be run before its commit")
	_check(not bool(table.task_step(0).accepted), "a task step needs a started task")
	table.start_alarm_task(true)
	_check(not bool(table.task_step(1).accepted), "valves must be confirmed in order")
	table.task_step(0)
	_check(bool(table.task_step(0).duplicate) and table.alarm_progress() == 1, "a repeated valve confirmation counts once")
	table.resolve_alarm_task()
	var sim := SimulationScript.new()
	var state := sim.entry_profile()
	state.current_shift = 4
	state.resources.merge({"E": 12, "A": 6, "W": 2}, true)
	var partial: Dictionary = sim.preview(state, table.plan_for_gate("p02_shift5_alarm"))
	_check(int(partial.final_state.W) == 3 and not bool(partial.trace[0].action_success), "a partial PUMP moves only +1")
	table.reset_alarm_task()
	table.start_alarm_task(true)
	for index in 3:
		table.task_step(index)
	var full: Dictionary = sim.preview(state, table.plan_for_gate("p02_shift5_alarm"))
	_check(int(full.final_state.W) == 4 and bool(full.trace[0].action_success), "three valves move the full +2 and the preview recalculates")
	table.set_choice(5, "action", "STACK")
	_check(table.alarm_progress() == 0 and table.plan_block_reason("p02_shift5_alarm", 4).contains("STACK"), "switching response is exclusive and clears the other task's progress")
	table.start_alarm_task(true)
	table.task_step(3)
	table.task_step(1)
	table.resolve_alarm_task()
	var stack: Dictionary = sim.preview(state, table.plan_for_gate("p02_shift5_alarm"))
	_check(int(stack.final_state.K) == 1 and int(stack.final_state.W) == 2 and int(stack.trace[0].heat) == 1 and int(stack.trace[0].light) == 0, "a partial STACK gives K1, leaves W alone and forces COOL/OFF")
	table.set_choice(5, "action", "WAIT")
	var wait: Dictionary = sim.preview(state, table.plan_for_gate("p02_shift5_alarm"))
	_check(table.plan_block_reason("p02_shift5_alarm", 4).is_empty() and int(wait.final_state.W) == 2 and int(wait.final_state.K) == 0 and int(wait.trace[0].dose) == 2, "WAIT adds no shelter; S2 gives dose 2")
	var timed := TableScript.new()
	timed.apply_worked_plan("stack")
	_check(int(timed.start_alarm_task(false).timer_seconds) == 30 and int(TableScript.new().alarm_state().timer_seconds) == 0, "a timed STACK reports its 30-second limit; assisted mode has none")

func _test_persistence_and_retry() -> void:
	var route := RouteScript.new(DirectorScript.new())
	route.mission_table().apply_worked_plan("golden")
	route.mission_table().share("kai", 0)
	route.mission_table().next_hint()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(route.snapshot()))
	var resumed := RouteScript.new(DirectorScript.new())
	resumed.director().restore_snapshot(JSON.parse_string(JSON.stringify(route.director().snapshot())))
	_check(bool(resumed.restore(saved).accepted) and resumed.mission_table().snapshot() == route.mission_table().snapshot(), "the Mission Table plan, shares and hints survive a JSON save and reload")
	var before: Dictionary = resumed.snapshot()
	var broken := saved.duplicate(true)
	broken.p02_table.selections["3"] = {"heat": "TOASTY"}
	_check(not bool(resumed.restore(broken).accepted) and resumed.snapshot() == before, "an invalid saved plan is rejected without changing the live route")
	var legacy := saved.duplicate(true)
	legacy.erase("p02_table")
	_check(bool(resumed.restore(legacy).accepted) and resumed.mission_table().plan_for_gate("p02_shift1").is_empty(), "an older save without a plan resumes with an empty table, not an invented plan")

# --- UI ----------------------------------------------------------------------

func _test_panel() -> void:
	root.size = Vector2i(1280, 720)
	var route := RouteScript.new(DirectorScript.new())
	_reach(route, "EX-CH01-S07")
	route.perform("role_cards")
	var panel := PanelScene.instantiate() as MissionTablePanel
	root.add_child(panel)
	var emitted: Array = []
	panel.commit_requested.connect(func(target_id: String, plan: Dictionary) -> void: emitted.append([target_id, plan]))
	panel.open(route, "p02_shift1", {"large_text": false, "timer_free": true})
	await process_frame
	var commit := panel.find_child("Commit", true, false) as Button
	_check(commit != null and commit.disabled and String(commit.tooltip_text).contains("Kai"), "Commit is disabled with a visible reason until cards are shared")
	_check(not bool(panel.request_commit().accepted) and emitted.is_empty(), "Space cannot commit an unready plan")
	panel.share_card("kai")
	panel.share_card("amara")
	panel.choose(1, "air_production", 2)
	panel.choose(1, "light", "FULL")
	panel.choose(1, "transfer", "HOLD")
	await process_frame
	_check(String(panel.request_commit().reason).contains("PREVIEW"), "Commit requires a preview of the current plan")
	var preview: Dictionary = panel.preview()
	_check(bool(preview.accepted) and int(preview.forecast.final_state.E) == 15 and int(preview.forecast.final_state.A) == 7 and int(preview.forecast.trace[0].overflow) == 2, "the preview shows the exact shift-1 forecast: E15, A7, 2 lost to overflow")
	panel.choose(1, "light", "DIM")
	_check(String(panel.request_commit().reason).contains("PREVIEW"), "changing the plan invalidates the old preview")
	panel.choose(1, "light", "FULL")
	panel.preview()
	await process_frame
	var too_small: Array = []
	for node in panel.find_children("*", "Button", true, false):
		if (node as Button).is_visible_in_tree() and (node as Button).size.y < 44.0:
			too_small.append(node.name)
	_check(too_small.is_empty(), "every Mission Table button is at least 44 px tall " + str(too_small))
	var space := InputEventKey.new()
	space.pressed = true
	space.physical_keycode = KEY_SPACE
	panel._input(space)
	_check(panel.find_child("ConfirmCommit", true, false) != null and emitted.is_empty(), "Space opens the confirmation without committing")
	panel._input(space)
	_check(emitted.size() == 1 and emitted[0][0] == "p02_shift1" and emitted[0][1] == route.mission_table().plan_for_gate("p02_shift1") and not panel.is_open(), "Space again confirms once, emits the table's plan and closes")
	_check(not bool(panel.confirm_commit().accepted) and emitted.size() == 1, "a duplicate confirm emits nothing")
	_check(int(route.director().query().current_shift) == 0, "the panel itself never commits resources")
	panel.open(route, "p02_shift1", {"large_text": true, "timer_free": true})
	await process_frame
	var large_preview := panel.find_child("Preview", true, false) as Button
	_check(large_preview != null and large_preview.get_theme_font_size("font_size") >= 19, "large text scales Mission Table controls to 150%")
	panel.close()
	panel.free()

func _test_campaign_integration() -> void:
	if not storage.setup("test_p02_mission_table"):
		_check(false, "isolated storage for the campaign integration check")
		return
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	campaign.route.start_at("EX-CH01-S07")
	campaign._sync_route_projection()
	campaign._refresh_world()
	await process_frame
	campaign.route.perform("role_cards")
	campaign.hud.refresh_scene()
	var opened := campaign.hud.open_mission_table("p02_shift1")
	_check(opened and campaign.hud.mission_table.is_open() and bool(campaign.director.query().paused), "USE opens the Mission Table and pauses scenario time")
	var table := campaign.hud.mission_table
	table.share_card("kai")
	table.share_card("amara")
	table.choose(1, "air_production", 1)
	table.choose(1, "light", "DIM")
	table.choose(1, "transfer", "FILL")
	var forecast: Dictionary = table.preview().forecast
	var target := campaign.physical_target("p02_shift1")
	campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	await physics_frame
	await physics_frame
	table.request_commit()
	table.confirm_commit()
	await process_frame
	_check(not bool(campaign.director.query().paused) and int(campaign.director.query().current_shift) == 1, "confirming resumes time and commits shift 1 through the physical operation")
	_check(_resources(campaign.director.snapshot().resources) == _resources(forecast.final_state), "the committed station equals the Mission Table preview (E%d A%d W%d)" % [int(forecast.final_state.E), int(forecast.final_state.A), int(forecast.final_state.W)])
	var saved: Dictionary = campaign.route.snapshot()
	_check(saved.p02_table.selections["1"] == {"air_production": 1, "light": "DIM", "transfer": "FILL"}, "the player's choices are saved with the route")
	campaign.free()
	storage.cleanup()

# --- Helpers -------------------------------------------------------------------

func _reach(route: RefCounted, scene_id: String) -> void:
	while route.current_scene_id() != scene_id:
		for target_id in _targets(route.current_scene_id()):
			route.perform(target_id)
		if not bool(route.advance_scene().get("accepted", false)):
			_check(false, "route reaches " + scene_id + " (stuck at " + route.current_scene_id() + ")")
			return

func _play_until(route: RefCounted, scene_id: String) -> void:
	while route.current_scene_id() != scene_id:
		if route.current_scene_id() == "EX-CH01-S10":
			_run_task(route)
		for target_id in _targets(route.current_scene_id()):
			route.perform(target_id)
		if not bool(route.advance_scene().get("accepted", false)):
			_check(false, "route plays to " + scene_id + " (stuck at " + route.current_scene_id() + ")")
			return

## Catalog order, except S03 where inspecting the packet comes before the
## atmosphere comparison (as in the other Chapter 1 route suites).
func _targets(scene_id: String) -> Array:
	if scene_id == "EX-CH01-S03":
		return ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]
	var ids: Array = []
	for spec in GateCatalog.targets_for_scene(scene_id):
		ids.append(String(spec.target_id))
	return ids

func _resources(values: Dictionary) -> Dictionary:
	var result := {}
	for key in RESOURCE_KEYS:
		result[key] = snappedf(float(values.get(key, 0)), 0.1)
	return result

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
