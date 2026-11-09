extends SceneTree
const Model = preload("res://scripts/missions/p01_commission_plant.gd")
const Director = preload("res://scripts/core/campaign_director.gd")
const Content = preload("res://scripts/content/content_loader.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const Inputs = preload("res://tools/support/p01_input_fixture.gd")
const SETUP := ["set_zero", "set_span", "recheck", "scan_packet", "plant_alo", "plant_tara", "water_alo", "water_tara"]
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for row in [{"action": "label_alo_external", "field": "alo_label", "target": "label_alo", "right": "EXTERNAL_TEST", "wrong": "INDOOR_REFERENCE"}, {"action": "label_tara_indoor", "field": "tara_label", "target": "label_tara", "right": "INDOOR_REFERENCE", "wrong": "EXTERNAL_TEST"}]:
		var model := _ready_model()
		var before: Dictionary = model.snapshot()
		for bad in [{}, {"label": row.wrong}, {"label": ""}, {"label": "UNKNOWN"}, {"label": null}, {"label": 1}, {"label": true}, {"label": []}, {"label": {}}]:
			_check(bool(model.restore(before).accepted), "restore unchanged label-ready model")
			var preview: Dictionary = model.preview(row.action, bad)
			_check(not bool(preview.get("accepted", false)) and model.snapshot() == before, "missing/wrong/malformed label forecast rejects without writes")
			var result: Dictionary = model.commit(row.action, "bad-label", bad)
			_check(not bool(result.get("accepted", false)) and model.snapshot() == before, "missing/wrong/malformed label cannot commit or spend a receipt")
		model.restore(before)
		var predicted: Dictionary = model.preview(row.action, {"label": row.right})
		_check(bool(predicted.get("accepted", false)) and predicted.state[row.field] == row.right and model.snapshot() == before, "correct label forecast shows the chosen label without writes")
		var result: Dictionary = model.commit(row.action, "chosen-label", {"label": row.right})
		_check(bool(result.get("accepted", false)) and result.state[row.field] == row.right and model.snapshot().receipts.size() == before.receipts.size() + 1, "commit applies exactly the selected label and one receipt")
		var stable: Dictionary = model.snapshot()
		var duplicate: Dictionary = model.commit(row.action, "chosen-label", {})
		_check(bool(duplicate.get("duplicate", false)) and model.snapshot() == stable, "old receipt replay needs no new choice and changes nothing")
		var old := before.duplicate(true)
		old[row.field] = row.right
		old.receipts["legacy-label"] = {"accepted": true, "command_id": "legacy-label", "action": row.action}
		var restored := Model.new()
		_check(bool(restored.restore(JSON.parse_string(JSON.stringify(old))).accepted) and restored.snapshot()[row.field] == row.right, "legacy primitive labelled state restores without a new payload")
		_check(bool(restored.commit(row.action, "legacy-label").get("duplicate", false)), "legacy labelled receipt still replays idempotently")
	_test_real_route()
	print("P01 LABELS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _ready_model() -> RefCounted:
	var model := Model.new()
	for action in SETUP:
		_check(bool(model.commit(action, action, Inputs.payload(action)).accepted), "real label setup " + action)
	return model

func _test_real_route() -> void:
	var director := Director.new()
	director.new_campaign(Content.EXPECTED_CONTENT_REVISION)
	var route := Route.new(director)
	for scene in ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"]:
		var ids: Array = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"] if scene.ends_with("S03") else Gates.targets_for_scene(scene).map(func(spec): return String(spec.target_id))
		for id in ids:
			_check(bool(route.perform(id, Inputs.payload(id)).get("accepted", false)), "real route setup " + id)
		_check(bool(route.advance_scene().accepted), "real route advance " + scene)
	for id in ["plant_alo", "plant_tara", "water_alo", "water_tara"]:
		_check(bool(route.perform(id, Inputs.payload(id)).accepted), "real planting setup " + id)
	for row in [{"target": "label_alo", "field": "alo_label", "right": "EXTERNAL_TEST", "wrong": "INDOOR_REFERENCE", "flag": "alo_labelled"}, {"target": "label_tara", "field": "tara_label", "right": "INDOOR_REFERENCE", "wrong": "EXTERNAL_TEST", "flag": "tara_labelled"}]:
		var before: Dictionary = route.snapshot()
		var state: Dictionary = director.snapshot()
		var rejected: Dictionary = route.perform(row.target, {"label": row.wrong})
		_check(not bool(rejected.get("accepted", false)) and route.snapshot() == before and director.snapshot() == state, "real route rejects wrong label with no flags/resources/receipts")
		route.restore(before)
		director.restore_snapshot(state)
		var chosen: Dictionary = route.perform(row.target, {"label": row.right})
		_check(bool(chosen.get("accepted", false)) and route.snapshot().p01[row.field] == row.right and bool(route.current_flags().get(row.flag, false)), "real route commits chosen label and its authoritative flag")
		var stable: Dictionary = route.snapshot()
		var stable_state: Dictionary = director.snapshot()
		_check(bool(route.perform(row.target, {"label": row.right}).get("accepted", false)) and route.snapshot() == stable and director.snapshot() == stable_state, "real duplicate label has no second cost or receipt")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
