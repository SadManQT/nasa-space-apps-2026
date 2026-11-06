extends RefCounted

## Test/capture choices only. Never referenced by the production trainer.
static func prepare(exercise: RefCounted, ending: String = "BLOOM") -> void:
	var table: RefCounted = exercise.mission_table()
	var plan: Array = table.data().worked_plans["golden" if ending == "GOLDEN" else "bloom"].shifts
	for index in plan.size():
		for field in plan[index]:
			if field in ["heat", "air_production", "light", "transfer", "action"]:
				table.set_choice(index + 1, field, plan[index][field])
	if ending == "ALO_LOST":
		table.set_choice(7, "heat", "COLD")
	if ending == "MISSION_STOPPED":
		for shift in [3, 4]:
			table.set_choice(shift, "transfer", "HOLD")
	if ending == "GOLDEN":
		table.start_alarm_task(true)
		for index in table.alarm_task_steps():
			table.task_step(index)
		table.resolve_alarm_task()

static func share(exercise: RefCounted) -> void:
	var shift := int(exercise.director().query().current_shift)
	for card in exercise.mission_table().role_cards(shift):
		if card.arrived:
			exercise.mission_table().share(card.role_id, shift)
