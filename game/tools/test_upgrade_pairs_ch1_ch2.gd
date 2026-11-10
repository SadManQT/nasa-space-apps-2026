extends SceneTree

## M3-2U and M3-3U: the after-Chapter-1 pair (taller mast / fuel cell) and the
## after-Chapter-2 pair (red-blue LEDs / insulation blankets): earned only after
## the chapter, exclusive, saved and restored, shown with the numbers the
## simulation really applies, and each modifier changes the simulation by
## exactly its spec. Run with `-- --capture` in a window to save the choice screens.

const ProgressionScript = preload("res://scripts/progression/cadet_progression.gd")
const RecordPanelScript = preload("res://scripts/ui/cadet_record.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const LedgerScript = preload("res://scripts/simulation/campaign_ledger_simulation.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_pair(1, "taller_mast", "fuel_cell")
	_test_pair(2, "red_blue_leds", "insulation_blankets")
	_test_modifier_effects()
	_test_fuel_cell_entry()
	_test_cards_match_rules()
	await _test_choice_screens()
	print("UPGRADE PAIRS CH1 CH2 RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
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
	_check(String(other.choose_upgrade(chapter, "B", done).upgrade_id) == id_b, "after-Ch%d Option B is %s" % [chapter, id_b])
	var synced := ProgressionScript.new()
	synced.sync_upgrades_from_snapshot({"upgrades": {"choices": {str(chapter): id_b}}})
	_check(String(synced.unlocked_upgrades.get(str(chapter), "")) == "B", "after-Ch%d choice syncs from the campaign snapshot" % chapter)
	var gear: Array = []
	for item in other.available_gear():
		gear.append(String(item.get("id", "")))
	_check(gear.has(id_b) and not gear.has(id_a), "after-Ch%d: only the chosen option appears as station gear" % chapter)

func _snapshot_with(choices: Dictionary) -> Dictionary:
	var snap := StateScript.new_snapshot()
	snap["upgrades"]["choices"] = choices
	return snap

func _phase(choices: Dictionary, settings: Dictionary) -> Dictionary:
	var snap := _snapshot_with(choices)
	snap["resources"]["E"] = 10
	snap["resources"]["energy_capacity"] = 20
	snap["resources"]["H"] = 6
	snap["resources"]["W"] = 0
	var base := {"daylight_energy": 0, "basic_energy": 1, "heat": 2, "light": 1, "fraction": 1.0, "breathing_air": 0.0, "food_consumption": 0.0}
	base.merge(settings, true)
	var result := SimulationScript.new().sampled_phase(snap, base)
	return result.get("snapshot", {}).get("resources", {})

func _test_modifier_effects() -> void:
	# Taller mast: +2 daylight income per full sampled shift, and none at night.
	var day := {"daylight_energy": 8}
	var plain := _phase({}, day)
	var mast := _phase({"1": "taller_mast"}, day)
	_check(is_equal_approx(float(plain.E), 14.0) and is_equal_approx(float(mast.E), 16.0), "taller mast adds exactly +2 daylight energy (14 -> 16)")
	_check(is_equal_approx(float(_phase({"1": "taller_mast"}, {"daylight_energy": 0}).E), float(_phase({}, {"daylight_energy": 0}).E)), "taller mast gives no night energy")
	var capped := _phase({"1": "taller_mast"}, {"daylight_energy": 8, "basic_energy": 0, "heat": 0, "light": 0, "fraction": 1.0})
	_check(float(capped.E) <= 20.0, "taller mast income never passes the battery capacity")
	# Fuel cell does not touch income; red-blue LEDs: FULL costs 1 instead of 2.
	var full_plain := _phase({}, {"light": 2})
	var full_led := _phase({"2": "red_blue_leds"}, {"light": 2})
	_check(is_equal_approx(float(full_plain.E), 10.0 - 5.0) and is_equal_approx(float(full_led.E), 10.0 - 4.0), "red-blue LEDs make FULL cost 1 instead of 2 (E 5 -> 6)")
	_check(is_equal_approx(float(_phase({"2": "red_blue_leds"}, {"light": 1}).E), float(_phase({}, {"light": 1}).E)), "red-blue LEDs leave DIM unchanged")
	# Insulation blankets: COOL causes no plant cold damage; COLD still does.
	var cool_plain := _phase({}, {"heat": 1})
	var cool_blanket := _phase({"2": "insulation_blankets"}, {"heat": 1})
	_check(is_equal_approx(float(cool_plain.H), 5.0) and is_equal_approx(float(cool_blanket.H), 6.0), "insulation blankets remove the COOL cold damage (H 5 -> 6)")
	_check(is_equal_approx(float(_phase({"2": "insulation_blankets"}, {"heat": 0}).H), float(_phase({}, {"heat": 0}).H)), "insulation blankets do not hide COLD damage")

func _test_fuel_cell_entry() -> void:
	var sim := SimulationScript.new()
	var plain := sim.campaign_modifiers(_snapshot_with({}))
	var cell := sim.campaign_modifiers(_snapshot_with({"1": "fuel_cell"}))
	_check(int(plain.energy_capacity) == 20 and int(cell.energy_capacity) == 26, "fuel cell raises the energy cap from 20 to 26 (+6)")
	var other := sim.campaign_modifiers(_snapshot_with({"1": "taller_mast"}))
	_check(int(other.energy_capacity) == 20, "taller mast leaves the energy cap at 20")
	# Entry charge +4 through the real chapter-entry projection.
	var ledger_plain: Dictionary = LedgerScript.new().project_scene(_snapshot_with({}), "EX-CH03-S01").get("snapshot", {}).get("resources", {})
	var ledger_cell: Dictionary = LedgerScript.new().project_scene(_snapshot_with({"1": "fuel_cell"}), "EX-CH03-S01").get("snapshot", {}).get("resources", {})
	_check(int(ledger_cell.get("energy_capacity", 0)) >= 26, "fuel cell cap holds at the next chapter entry")
	_check(int(ledger_cell.get("E", 0)) == mini(int(ledger_cell.get("energy_capacity", 0)), int(ledger_plain.get("E", 0)) + 4), "fuel cell adds +4 entry charge (capped by capacity)")

func _test_cards_match_rules() -> void:
	var pair1: Dictionary = ProgressionScript.UPGRADE_PAIRS[1]
	_check(String(pair1.B.after).contains("capacity 26") and String(pair1.B.after).contains("start 18"), "fuel cell card states the applied numbers (start 18 / capacity 26)")
	_check(String(pair1.A.after).contains("+10") and String(pair1.A.before).contains("+8"), "taller mast card states +8 to +10 daylight income")
	var pair2: Dictionary = ProgressionScript.UPGRADE_PAIRS[2]
	_check(String(pair2.A.after).contains("1 battery") and String(pair2.A.before).contains("2 battery"), "LED card states FULL 2 -> 1")
	_check(String(pair2.B.after).contains("-0"), "blanket card states COOL damage -0")

func _test_choice_screens() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	var panel := RecordPanelScript.new()
	root.add_child(panel)
	panel.bind_progression(ProgressionScript.new())
	for item in [{"ch": 1, "file": "M3-2U_upgrade_after_ch01.png"}, {"ch": 2, "file": "M3-3U_upgrade_after_ch02.png"}]:
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
