extends SceneTree
## Temporary M1-37 parse probe (deleted before done).
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var crew = load("res://scripts/crew/crew_modes.gd")
	var table_script = load("res://scripts/puzzles/p02_mission_table.gd")
	var state_script = load("res://scripts/core/campaign_state.gd")
	var ok := crew != null and table_script != null and state_script != null
	if ok:
		var table = table_script.new()
		table.apply_worked_plan("bloom")
		var r1: Dictionary = table.mark_read("kai", 0)
		var r2: Dictionary = table.share("rafi", 0, true)
		var r3: Dictionary = table.sign_off("kai", "p02_shift1", 0)
		var signed: Array = table.signed_roles("p02_shift1", 0)
		var snap: Dictionary = table.snapshot()
		var restored: Dictionary = table_script.new().restore(snap)
		var seats: Array = crew.seats({"mode": "class", "players": 3})
		var valid: Dictionary = state_script.validate_snapshot(state_script.new_snapshot())
		var with_crew: Dictionary = state_script.new_snapshot()
		with_crew["crew"] = {"mode": "class", "players": 4}
		var valid2: Dictionary = state_script.validate_snapshot(with_crew)
		with_crew["crew"] = {"mode": "network", "players": 4}
		var invalid: Dictionary = state_script.validate_snapshot(with_crew)
		print("PROBE read=%s share_unread=%s sign=%s signed=%s restore=%s seats=%d valid=%s valid2=%s invalid=%s label=%s" % [str(r1.accepted), str(r2.accepted), str(r3.accepted), str(signed), str(restored.accepted), seats.size(), str(valid.valid), str(valid2.valid), str(invalid.valid), crew.mode_label({"mode": "class", "players": 4})])
		print("PROBE seatplan=", crew.seat_plan_text({"mode": "class", "players": 2}), " | holder=", crew.holder_label({"mode": "class", "players": 2}, "rafi"), " | text=", crew.text("handoff", "reveal_button", {"name": "Kai"}))
	print("PROBE RESULT: ", "PASS" if ok else "FAIL")
	quit(0)
