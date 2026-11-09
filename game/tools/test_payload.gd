extends SceneTree

## Capacity/condition contracts, physical STACK receipts and the production
## campaign handoff. Uses isolated storage; never reads/writes a player's save.
const Inventory = preload("res://scripts/payload/payload_inventory.gd")
const Task = preload("res://scripts/payload/stack_task.gd")
const Table = preload("res://scripts/puzzles/p02_mission_table.gd")
const Simulation = preload("res://scripts/simulation/expedition_simulation.gd")
const Campaign = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_capacity()
	_conditions()
	_stack_results()
	await _campaign()
	await process_frame
	await process_frame
	print("PAYLOAD RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _capacity() -> void:
	var inventory := Inventory.new()
	for index in 5:
		_check(bool(inventory.register_payload(_definition(str(index))).accepted), "register payload %d" % index)
	_check(bool(inventory.pickup("0").accepted), "one payload fits in hands")
	var before := inventory.item("1")
	var refusal := inventory.pickup("1")
	_check(not bool(refusal.accepted) and String(refusal.reason).contains("Hands full") and inventory.item("1") == before, "full hands refuse before pickup with a reason")
	_check(not bool(inventory.pickup("0", "back").accepted), "cannot duplicate an already-carried payload")
	for id in ["1", "2", "3"]:
		_check(bool(inventory.pickup(id, "back").accepted), "back frame accepts small payload " + id)
	_check(not bool(inventory.pickup("4", "back").accepted) and int(inventory.load_view("back").count) == 3, "back frame refuses a fourth small payload")
	_check(inventory.personal_mass() == 8.0 and float(inventory.load_view("hands").mass_kg) == 2.0, "load readout includes count and total mass")
	_check(is_equal_approx(float(inventory.load_view("hands").weight_n), 2.0 * 1.62), "weight is mass times lunar g; mass itself is unchanged")
	var detached := inventory.item("0")
	detached.place = "delivered"
	_check(inventory.item("0").place == "hands", "readouts cannot mutate ownership")
	_check(bool(inventory.set_down("0").accepted), "payload can be set down without losing condition")
	var medium := _definition("medium", 4.0)
	medium.size = "medium"
	inventory.register_payload(medium)
	_check(String(inventory.pickup("medium", "back").reason).contains("small"), "back frame gives the size refusal")
	var heavy := Inventory.new()
	heavy.register_payload(_definition("too_heavy", 13.0))
	var overweight := heavy.pickup("too_heavy")
	_check(not bool(overweight.accepted) and String(overweight.reason).contains("12") and heavy.item("too_heavy").place == "ground", "hands enforce mass before pickup")
	heavy.register_payload(_definition("a", 3.1))
	heavy.register_payload(_definition("b", 3.1))
	heavy.register_payload(_definition("c", 3.1))
	heavy.pickup("a", "back")
	heavy.pickup("b", "back")
	var back_limit := heavy.pickup("c", "back")
	_check(not bool(back_limit.accepted) and String(back_limit.reason).contains("9"), "back frame enforces aggregate mass")
	var total := Inventory.new()
	total.register_payload(_definition("hands", 12.0))
	total.pickup("hands")
	for id in ["a", "b", "c"]:
		total.register_payload(_definition(id, 3.0))
	total.pickup("a", "back")
	total.pickup("b", "back")
	var personal_limit := total.pickup("c", "back")
	_check(not bool(personal_limit.accepted) and String(personal_limit.reason).contains("18"), "personal mass combines hands and back")
	for chapter in [1, 3, 4]:
		var hooks := Inventory.new(chapter, ["sled", "trailer"])
		hooks.register_payload(_definition("cargo"))
		_check(bool(hooks.can_pickup("cargo", "sled").accepted) == (chapter >= 3), "sled chapter hook %d" % chapter)
		_check(bool(hooks.can_pickup("cargo", "trailer").accepted) == (chapter >= 4), "trailer chapter hook %d" % chapter)
	var unattached := Inventory.new(4)
	unattached.register_payload(_definition("cargo"))
	_check(not bool(unattached.pickup("cargo", "sled").accepted), "later carry places still require attached equipment")
	var malformed := _definition("bad", -2.0)
	_check(not bool(unattached.register_payload(malformed).accepted), "invalid payload definitions refused")

func _conditions() -> void:
	var inventory := Inventory.new()
	var definition := _definition("sample")
	definition.handling = ["fragile", "sealed", "keep_cold"]
	definition.max_temperature_c = -10.0
	inventory.register_payload(definition)
	_check(not bool(inventory.deliver("sample", "marked_bay").accepted), "delivery needs a carried payload")
	inventory.pickup("sample")
	_check(not bool(inventory.deliver("sample", "wrong_bay").accepted) and inventory.item("sample").place == "hands", "wrong destination cannot consume payload")
	_check(bool(inventory.deliver("sample", "marked_bay").accepted), "correct destination accepts intact sealed cold payload")
	_check(not bool(inventory.deliver("sample", "marked_bay").accepted), "duplicate delivery refused")
	for condition in ["intact", "seal_intact", "temperature_c"]:
		var damaged := Inventory.new()
		damaged.register_payload(definition)
		damaged.pickup("sample")
		var reading := {condition: 0.0 if condition == "temperature_c" else false}
		damaged.update_condition("sample", reading)
		_check(not bool(damaged.deliver("sample", "marked_bay").accepted) and damaged.item("sample").place == "hands", "delivery checks " + condition)
		if condition == "temperature_c":
			damaged.update_condition("sample", {"temperature_c": -20.0})
			_check(not bool(damaged.deliver("sample", "marked_bay").accepted), "cooling again does not erase a cold-chain excursion")
		else:
			damaged.update_condition("sample", {condition: true})
			_check(not bool(damaged.deliver("sample", "marked_bay").accepted), "damage cannot be cleared by a later reading")
		_check(bool(damaged.set_down("sample").accepted), "failed delivery remains recoverable")
	var invalid := Inventory.new()
	invalid.register_payload(definition)
	var before := invalid.item("sample")
	_check(not bool(invalid.update_condition("sample", {"intact": false, "invalid": true}).accepted) and invalid.item("sample") == before, "malformed condition update is atomic")

func _stack_results() -> void:
	for count in range(5):
		var table := Table.new()
		table.apply_worked_plan("stack")
		var task := Task.new(table)
		_check(not bool(task.place(0).accepted), "slot cannot count before starting")
		_check(bool(task.start(false).accepted) and task.time_left == 30.0, "STACK timer is exactly 30 seconds")
		_check(not bool(task.place(0).accepted), "slot cannot count without carrying")
		for index in count:
			_check(bool(task.pickup(index).accepted), "pick up bundle %d for %d placements" % [index, count])
			_check(bool(task.place(3 - index).accepted), "place in any empty slot")
			if task.running:
				_check(not bool(task.place(3 - index).accepted), "occupied slot cannot score twice")
		if task.running:
			task.advance(30.0)
		var simulation := Simulation.new()
		var state := simulation.entry_profile()
		state.current_shift = 4
		state.resources.merge({"E": 12, "A": 6, "W": 2}, true)
		var result := simulation.preview(state, table.plan_for_gate("p02_shift5_alarm"))
		var expected := 2 if count == 4 else 1 if count > 0 else 0
		_check(int(result.final_state.K) == expected and int(result.final_state.W) == 2, "%d placed yields K%d without moving water" % [count, expected])
		_check(int(result.trace[0].heat) == 1 and int(result.trace[0].light) == 0, "STACK keeps the published COOL / OFF costs")
		_check(not bool(task.pickup(0).accepted), "expired/resolved task rejects further pickups")
		var restored := Table.new()
		_check(bool(restored.restore(JSON.parse_string(JSON.stringify(table.snapshot()))).accepted) and restored.alarm_progress() == count, "physical delivery progress survives the existing save ledger")
	var timer := Table.new()
	timer.apply_worked_plan("stack")
	var timed := Task.new(timer)
	timed.start(false)
	timed.pickup(0)
	timed.advance(29.5)
	_check(timed.running and timed.time_left == 0.5, "timer stays active up to the boundary")
	timed.advance(0.5)
	_check(not timed.running and timer.alarm_progress() == 0, "held but undelivered bundle earns K0 at expiry")
	for settings in [{"timer_free": true}, {"mode": "Family"}, {"mode": "Class"}, {"mode": "Story"}]:
		var table := Table.new()
		table.apply_worked_plan("stack")
		var task := Task.new(table)
		_check(Task.is_untimed(settings), "untimed settings recognised: " + str(settings))
		task.start(false, settings)
		task.advance(300.0)
		_check(task.running and task.assisted and task.time_left == 0.0, "Family/Story/timer-free has no clock: " + str(settings))
	for settings in [{}, {"timer_free": false}, {"mode": "Expedition"}, {"mode": "Cadet", "timer_free": false}]:
		var table := Table.new()
		table.apply_worked_plan("stack")
		var task := Task.new(table)
		task.start(false, settings)
		_check(not Task.is_untimed(settings) and not task.assisted and task.time_left == 30.0, "timed settings keep the 30-second clock: " + str(settings))
	# The S10 to S11 join (doc 24 section 2.9): crates never move garden water, so the
	# "borrowed water" line is only shown when the wall holds some (08: no drain needed otherwise).
	_check(Task.bridge_line(2).begins_with("The alarm eases.") and Task.bridge_line(2).contains("borrowed water") and Task.bridge_line(2).contains("garden"), "bridge line with water in the wall points at returning it")
	_check(Task.bridge_line(0).begins_with("The alarm eases.") and not Task.bridge_line(0).contains("still holds") and Task.bridge_line(0).contains("No garden water was borrowed") and Task.bridge_line(0).contains("dark shifts"), "bridge line with an empty wall never claims borrowed water")
	_check(Task.bridge_line(6) == Task.bridge_line(1) and Task.bridge_line(-1) == Task.bridge_line(0), "bridge line depends only on whether water was borrowed")
	var scoring := String(Inventory.rules().stack.scoring)
	_check(scoring.contains("crates 2") and scoring.contains("crates 1") and scoring.contains("never move garden water") and not scoring.contains("shelter wall"), "briefing scoring names crates (K), not the water wall")
	var assisted_table := Table.new()
	assisted_table.apply_worked_plan("stack")
	var assisted := Task.new(assisted_table)
	assisted.start(true)
	assisted.advance(300.0)
	for index in 4:
		assisted.pickup(index)
		assisted.place(index)
	_check(assisted_table.alarm_progress() == 4 and not assisted.running, "assisted carry-and-place earns the same full result")

func _campaign() -> void:
	_check(storage.setup("M1-58-payload"), "isolated save storage")
	CampaignCutscenePlayer.autoplay = false
	var campaign := Campaign.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	campaign.route.mission_table().apply_worked_plan("golden")
	for role_id in ["kai", "amara", "rafi", "mei"]:
		campaign.route.mission_table().share(role_id, 3)
	while campaign.route.current_scene_id() != "EX-CH01-S10":
		var current: String = campaign.route.current_scene_id()
		var ids: Array = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"] if current == "EX-CH01-S03" else Gates.targets_for_scene(current).map(func(spec): return String(spec.target_id))
		for id in ids:
			campaign.route.perform(id, PlantInput.payload(id))
		if not bool(campaign.route.advance_scene().get("accepted", false)):
			_check(false, "reach the actual alarm scene (stuck " + current + ")")
			campaign.free()
			storage.cleanup()
			return
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	campaign.route.perform("confirm_four_sheltered")
	_check(campaign.hud.open_mission_table("p02_shift5_alarm"), "supply job opens through the real response table")
	var close_hint := campaign.hud.panels.hint_player.find_child("CloseHint", true, false) as Button
	if close_hint != null and close_hint.is_visible_in_tree():
		close_hint.pressed.emit()
	var table := campaign.hud.mission_table
	table.choose(5, "action", "STACK")
	var before: Dictionary = campaign.director.snapshot().resources.duplicate(true)
	var prior_controlled: bool = campaign._player.controlled
	var carry_button := table.find_child("StartPayload", true, false) as Button
	_check(carry_button != null and carry_button.is_visible_in_tree(), "Mission Table shows the shift-5 STACK physical carry button")
	carry_button.pressed.emit()
	var activity := campaign.hud.payload_activity
	# Freed without returning (room change, exit): the HUD, table, cadet and pile come back.
	_check(activity != null and not campaign.hud.visible and not campaign.hud.mission_table.visible, "activity hides the HUD and the table while the cadet carries")
	activity.begin(true)
	var pile_hidden := activity._hidden.size()
	activity.free()
	_check(not is_instance_valid(activity) and campaign.hud.visible and campaign.hud.mission_table.visible and campaign._player.controlled == prior_controlled and campaign._player.animation.hold_mode == PlayerAnimation.Hold.NONE, "freeing the activity restores the HUD, table and cadet")
	for child in campaign._room.visual_root.get_children():
		if String(child.name) == "PR_SupplyBundles":
			_check(child.visible or pile_hidden == 0, "freeing the activity shows the original supply pile again")
	campaign.route.mission_table().reset_alarm_task()
	table.refresh_payload_result()
	table.start_payload_activity()
	activity = campaign.hud.payload_activity
	_check(activity != null and campaign.route.mission_table().alarm_state().state == "idle", "briefing appears before the timer or progress starts")
	activity.begin(false)
	_check(not activity._assistance and activity._player.controlled, "timer-free manual mode keeps movement controls")
	activity._player.global_position = Vector3(3, 0, 2)
	_check(not bool(activity.pickup_bundle(0).accepted), "physical pickup refuses an out-of-reach source")
	activity._player.global_position = Vector3(1.15, 0, -1.4)
	_check(bool(activity.pickup_bundle(0).accepted), "physical pickup accepts a nearby source")
	_check(activity._held.prop.find_children("*", "CollisionObject3D", true, false).is_empty() and activity._world.find_children("*", "CollisionObject3D", true, false).is_empty(), "carried and staged cases have no colliders to push the cadet or block reach")
	_check(not bool(activity.place_bundle(0).accepted), "physical delivery refuses an out-of-reach slot")
	activity._player.global_position = Vector3(-1.35, 0, -0.15)
	_check(bool(activity.place_bundle(0).accepted), "physical delivery snaps a nearby carried bundle")
	activity.pause_task()
	var time_before := activity.task.time_left
	activity._physics_process(10.0)
	_check(activity.task.time_left == time_before, "reading pause freezes the physical clock")
	activity.finish_task()
	var water := int(campaign.director.snapshot().resources.get("W", 0))
	var report_lines: Array = activity._card.find_children("*", "Label", true, false).map(func(label): return String(label.text))
	_check(water > 0 and report_lines.has(Task.bridge_line(water)) and not report_lines.has(Task.bridge_line(0)), "report card shows the S10 to S11 water line for the station's real wall (W%d)" % water)
	activity.return_to_plan()
	await process_frame
	_check(activity == null or not is_instance_valid(activity), "activity releases its scene and input")
	campaign.route.mission_table().reset_alarm_task()
	table.refresh_payload_result()
	table.start_payload_activity()
	activity = campaign.hud.payload_activity
	activity.begin(true)
	activity.set_physics_process(false)
	_check(activity._player.follow_camera.camera.current and not activity._player.controlled, "assisted input retains a live camera with movement disabled")
	for index in 4:
		# Real joypad events must reach the GUI; A also maps to world interact.
		(activity._assist_rows.get_node("Select_%d" % index) as Button).grab_focus()
		await _accept_button()
		_check(activity._selection == index, "joypad A selects a bundle")
		await _accept_button()
		_check(activity._held.prop != null and activity._player.animation.hold_mode == PlayerAnimation.Hold.BOX, "assisted pickup reuses HeldProp and BOX pose")
		(activity._assist_rows.get_node("Select_%d" % index) as Button).grab_focus()
		await _accept_button()
		_check(activity._selection == index, "joypad A selects a destination")
		await _accept_button()
	_check(campaign.route.mission_table().alarm_progress() == 4 and activity._reported, "assisted controls deliver all four bundles and show a report")
	_check(campaign.director.snapshot().resources == before, "carrying spends no base air, battery or water")
	activity.return_to_plan()
	await process_frame
	_check(campaign.hud.payload_activity == null and table.is_open() and campaign._ui_paused, "report returns to the paused plan, not an automatic shift commit")
	_check(not bool(table.task_step(0).accepted), "Mission Table slot clicks cannot bypass resolved physical delivery")
	if OS.get_cmdline_user_args().has("--capture") and root.get_texture() != null and root.get_texture().get_image() != null:
		var shot_path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-112_shift5_stack_table.png")
		_check(root.get_texture().get_image().save_png(shot_path) == OK, "capture shift-5 STACK Mission Table result")
	var preview := table.preview()
	_check(bool(preview.accepted) and int(preview.forecast.final_state.K) == 2, "physical progress produces the exact K2 forecast")
	await physics_frame
	await physics_frame
	table.request_commit()
	var committed := table.confirm_commit()
	await process_frame
	_check(bool(committed.accepted) and int(campaign.director.query().current_shift) == 5 and int(campaign.director.snapshot().resources.K) == 2, "real proximity gate commits the delivered supplies exactly once")
	var advanced: Dictionary = campaign.advance_scene()
	_check(bool(advanced.accepted) and campaign.route.current_scene_id() == "EX-CH01-S11", "alarm joins the canonical garden water-return scene")
	_check(bool(campaign.route.perform("verify_exposure_order").accepted) and bool(campaign.route.perform("return_water").accepted), "borrowed wall water can be returned after the STACK shift")
	campaign.free()
	storage.cleanup()

func _accept_button() -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func _definition(id: String, mass: float = 2.0) -> Dictionary:
	return {"id": id, "label": "Sample " + id, "mass_kg": mass, "size": "small", "handling": [], "destination": "marked_bay"}

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + message)
