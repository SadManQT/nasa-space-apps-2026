extends RefCounted

## Test/capture-only route fixture. Plays the authored gates and documented
## plans; the failure variants change actual choices, never the ending label.
static func play(ending: String) -> RefCounted:
	var director := preload("res://scripts/core/campaign_director.gd").new()
	director.new_campaign(preload("res://scripts/content/content_loader.gd").EXPECTED_CONTENT_REVISION)
	var route := preload("res://scripts/missions/chapter1_route.gd").new(director)
	var table: RefCounted = route.mission_table()
	preload("res://tools/support/p02_plan_fixture.gd").prepare(route, "golden" if ending == "GOLDEN" else "bloom")
	if ending == "ALO_LOST":
		table.set_choice(7, "heat", "COLD")
	if ending == "MISSION_STOPPED":
		for shift in [3, 4]:
			table.set_choice(shift, "transfer", "HOLD")
	for scene_id in preload("res://scripts/missions/chapter1_gate_catalog.gd").SCENE_ORDER:
		if scene_id == "EX-CH01-S12":
			break
		for role in table.role_cards(int(route.director().query().current_shift)):
			if role.arrived:
				table.share(String(role.role_id), int(route.director().query().current_shift))
		var targets: Array = preload("res://scripts/missions/chapter1_gate_catalog.gd").targets_for_scene(scene_id).map(func(target): return String(target.target_id))
		if scene_id == "EX-CH01-S03":
			targets = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]
		for target in targets:
			if target == "review_outcome":
				break
			var result: Dictionary = route.perform(target)
			if not result.get("accepted", false):
				push_error("Outcome fixture rejected %s: %s" % [target, str(result)])
				return route
		if scene_id != "EX-CH01-S11":
			var advanced: Dictionary = route.advance_scene()
			if not advanced.get("accepted", false):
				push_error("Outcome fixture stuck at " + String(scene_id))
				return route
	return route
