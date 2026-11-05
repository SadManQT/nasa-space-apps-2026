extends RefCounted

## Test fixture: fills a Chapter 1 route's Mission Table with a documented
## worked plan (08_PUZZLE_DESIGNS.md witnesses) the way a player would, and
## completes the shift-5 PUMP/STACK task in assisted mode. Gameplay never
## calls this; it replaces the old built-in default plan for suites that drive
## P-02 gates without opening the table.

static func prepare(route: RefCounted, plan_id: String = "bloom") -> void:
	prepare_p01(route)
	if route == null or not route.has_method("mission_table"):
		return
	var table: RefCounted = route.mission_table()
	var committed := int(route.director().query().get("current_shift", 0))
	table.apply_worked_plan(plan_id, committed)
	var alarm: Dictionary = table.alarm_state()
	if String(alarm.get("action", "")) in ["PUMP", "STACK"] and String(alarm.get("state", "")) == "idle":
		table.start_alarm_task(true)
		for index in table.alarm_task_steps():
			table.task_step(index)

static func prepare_p01(route: RefCounted) -> void:
	if route != null and route.has_method("p01_puzzle") and route.p01_puzzle() != null:
		route.p01_puzzle().apply_canonical_setup()
