extends SceneTree

## M4-17 (for M3-5U and M3-7U): the after-Chapter-4 pair (ice harvester /
## rover lamps & heater) and the after-Chapter-6 pair (storm early warning /
## bigger Safe Room), end to end: earned only after the chapter, exclusive,
## saved and restored, and each modifier read by the system that applies it.
## Run with `-- --capture` in a window to save the two choice screens.

const ProgressionScript = preload("res://scripts/progression/cadet_progression.gd")
const RecordPanelScript = preload("res://scripts/ui/cadet_record.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const RoverScript = preload("res://scripts/rover/lunar_rover.gd")
const HazardsScript = preload("res://scripts/hazards/lunar_hazards.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_pair(4, "ice_harvester", "rover_lights_heater")
	_test_pair(6, "storm_early_warning", "bigger_safe_room")
	_test_simulation_modifiers()
	_test_rover_reads_saved_choices()
	_check(String(ProgressionScript.UPGRADE_PAIRS[6].A.after).contains("30"), "early-warning choice card states the applied 30-second preparation lead")
	await _test_choice_screens()
	print("UPGRADE PAIRS CH4 CH6 RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_pair(chapter: int, id_a: String, id_b: String) -> void:
	var before: Array = range(1, chapter)
	var done: Array = range(1, chapter + 1)
	var prog := ProgressionScript.new()
	_check(not bool(prog.choose_upgrade(chapter, "A", before).accepted), "after-Ch%d pair is refused before Chapter %d is complete" % [chapter, chapter])
	_check(not bool(prog.choose_upgrade(chapter, "C", done).accepted), "after-Ch%d pair accepts only A or B" % chapter)
	var a := prog.choose_upgrade(chapter, "A", done)
	_check(bool(a.accepted) and String(a.upgrade_id) == id_a, "after-Ch%d Option A is %s" % [chapter, id_a])
	_check(not bool(prog.choose_upgrade(chapter, "B", done).accepted), "after-Ch%d Option B is refused once A is chosen" % chapter)
	_check(bool(prog.choose_upgrade(chapter, "A", done).accepted) and prog.unlocked_upgrades.size() == 1, "after-Ch%d repeat of A stays one acquisition" % chapter)
	var restored := ProgressionScript.new()
	restored.restore(prog.snapshot())
	_check(String(restored.unlocked_upgrades.get(str(chapter), "")) == "A" and not bool(restored.choose_upgrade(chapter, "B", done).accepted), "after-Ch%d choice survives save and load and stays exclusive" % chapter)
	var other := ProgressionScript.new()
	var b := other.choose_upgrade(chapter, "B", done)
	_check(bool(b.accepted) and String(b.upgrade_id) == id_b, "after-Ch%d Option B is %s" % [chapter, id_b])
	# The campaign stores the upgrade id; a fresh model syncs back to the same option.
	var synced := ProgressionScript.new()
	synced.sync_upgrades_from_snapshot({"upgrades": {"choices": {str(chapter): id_b}}})
	_check(String(synced.unlocked_upgrades.get(str(chapter), "")) == "B", "after-Ch%d choice syncs from the campaign snapshot" % chapter)
	var gear_ids: Array = []
	for item in other.available_gear():
		gear_ids.append(String(item.get("id", "")))
	_check(gear_ids.has(id_b) and not gear_ids.has(id_a), "after-Ch%d: only the chosen option appears as station gear" % chapter)

func _snapshot_with(choices: Dictionary) -> Dictionary:
	var snap := StateScript.new_snapshot()
	snap["upgrades"]["choices"] = choices
	return snap

func _test_simulation_modifiers() -> void:
	var sim := SimulationScript.new()
	var none := sim.campaign_modifiers(_snapshot_with({}))
	_check(not bool(none.ice_harvester) and not bool(none.rover_lights_heater) and not bool(none.storm_early_warning) and not bool(none.bigger_safe_room), "no choice: no Chapter 4 or 6 modifier is active")
	var base_crates := int(none.crate_capacity)
	var a := sim.campaign_modifiers(_snapshot_with({"4": "ice_harvester", "6": "storm_early_warning"}))
	_check(bool(a.ice_harvester) and not bool(a.rover_lights_heater), "ice harvester alone is active after choosing 4A")
	_check(bool(a.storm_early_warning) and not bool(a.bigger_safe_room) and int(a.crate_capacity) == base_crates, "early warning is recorded and adds no crate capacity and no energy")
	_check(int(a.energy_capacity) == int(none.energy_capacity), "early warning invents no solar income or capacity")
	var b := sim.campaign_modifiers(_snapshot_with({"4": "rover_lights_heater", "6": "bigger_safe_room"}))
	_check(bool(b.rover_lights_heater) and not bool(b.ice_harvester), "rover lamps and heater alone is active after choosing 4B")
	_check(bool(b.bigger_safe_room) and int(b.crate_capacity) == 3, "bigger Safe Room raises the crate cap to K3")
	var profile := sim.entry_profile("chapter1_base")
	profile["upgrades"] = {"choices": {"4": "ice_harvester"}}
	_check(int(sim.outpost_readouts(profile).get("separate_shelter_water", -1)) == 2, "ice harvester shows 2 separate shelter water units")
	profile["upgrades"] = {"choices": {"4": "rover_lights_heater"}}
	_check(int(sim.outpost_readouts(profile).get("separate_shelter_water", -1)) == 0, "without the harvester the separate reserve is 0")

func _test_rover_reads_saved_choices() -> void:
	# The campaign hands the rover director.snapshot().upgrades, not flat flags.
	var saved: Dictionary = _snapshot_with({"4": "rover_lights_heater", "7": "long_range_battery"}).upgrades
	var rover = RoverScript.new()
	rover.apply_preset("ch08_relay", saved)
	_check(rover.heater_upgrade, "rover reads rover_lights_heater from the saved campaign choices")
	_check(rover.long_range_battery_upgrade and is_equal_approx(rover.battery_capacity, 18.0), "rover reads long_range_battery from the saved choices (14 -> 18)")
	var plain = RoverScript.new()
	plain.apply_preset("ch08_relay", _snapshot_with({"4": "ice_harvester", "7": "relay_parts_kit"}).upgrades)
	_check(not plain.heater_upgrade and not plain.long_range_battery_upgrade and is_equal_approx(plain.battery_capacity, 14.0), "the other options leave the rover standard")
	var flat = RoverScript.new()
	flat.apply_preset("ch04_survey", {"rover_lights_heater": true})
	_check(flat.heater_upgrade, "flat upgrade flags still work")
	var hazards = HazardsScript.new("Cadet", false)
	var base_draw := float(hazards.step_cold_shadow(true, 10.0, plain.heater_upgrade).get("heater_power_multiplier", 0.0))
	var upgraded_draw := float(HazardsScript.new("Cadet", false).step_cold_shadow(true, 10.0, rover.heater_upgrade).get("heater_power_multiplier", 0.0))
	_check(is_equal_approx(base_draw, 1.8) and is_equal_approx(upgraded_draw, 1.45), "cold-shadow heater draw is 1.8x standard and 1.45x with the upgrade")

func _test_choice_screens() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	var prog := ProgressionScript.new()
	var panel := RecordPanelScript.new()
	root.add_child(panel)
	panel.bind_progression(prog)
	for item in [{"ch": 4, "file": "M3-5U_upgrade_after_ch04.png"}, {"ch": 6, "file": "M3-7U_upgrade_after_ch06.png"}]:
		panel.open_tab("upgrades", int(item.ch))
		await process_frame
		await process_frame
		_check(panel._title_label.text.contains("Chapter %d" % int(item.ch)), "choice screen shows the after-Chapter-%d pair" % int(item.ch))
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/" + String(item.file)))
	panel.free()
	await process_frame

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("  FAIL: ", message)
