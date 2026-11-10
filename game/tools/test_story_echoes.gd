## Story echoes (M3-95, doc 24 section 5.2 D4-D13): the echo pack's lookup
## maps match its entries, echoes_for_scene fires each D-row only in its later
## scene and only when its choice / moment / required scene is recorded, the
## Decisions tab still gates echoes on the scene, and the new LOC-08 staging
## layers gate on the recorded choice. Headless; data only.
extends SceneTree

const CampaignKnowledge = preload("res://scripts/dialogue/knowledge_service.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: " + label)

func _ids(rows: Array) -> Array:
	var out: Array = []
	for row in rows:
		if row is Dictionary:
			out.append(String(row.get("id", "")))
	return out

func _snap(choices: Dictionary = {}, moments: Array = [], completed: Array = []) -> Dictionary:
	return {
		"scene_id": "",
		"completed_scene_ids": completed,
		"story_log": {"choices": choices, "moments": moments},
	}

func _fired(snapshot: Dictionary, scene_id: String) -> Array:
	return _ids(CampaignKnowledge.echoes_for_scene(snapshot, scene_id))

func _find(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and String(item.get("id", "")) == item_id:
			return item
	return {}

func _run() -> void:
	var pack: Dictionary = CampaignKnowledge.story_echoes()
	_test_pack_identity(pack)
	_test_choice_echoes()
	_test_scene_gated()
	_test_moment_echo()
	_test_decisions_tab_rewire()
	_test_staging()
	print("STORY ECHOES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

## The pack's lookup maps hold exactly the rows listed in entries, every
## decision's echo ids resolve, and every echo sits after its source scene
## (except the same-scene D13 dedication, flagged same_scene).
func _test_pack_identity(pack: Dictionary) -> void:
	var decision_ids: Array = []
	for decision in pack.get("decisions", []):
		decision_ids.append(String(decision.get("id", "")))
	_check(decision_ids == ["D1", "D2", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11", "D12", "D13"],
		"pack: decisions are exactly D1, D2 and D4-D13")
	var entries: Array = pack.get("entries", [])
	_check(entries.size() == 52, "pack: 52 echo rows (19 Chapter 1 + 33 Chapters 2-8)")
	var by_id := {}
	for row in entries:
		if row is Dictionary:
			by_id[String(row.get("id", ""))] = row
	_check(by_id.size() == entries.size(), "pack: no duplicate echo ids")
	var nested: Array = []
	for opts in pack.get("choices", {}).values():
		for rows in opts.values():
			nested.append_array(rows)
	for rows in pack.get("moments", {}).values():
		nested.append_array(rows)
	for rows in pack.get("scene_gated", {}).values():
		nested.append_array(rows)
	_check(nested.size() == entries.size(), "pack: lookup maps hold exactly the entries rows")
	var maps_match := nested.size() == entries.size()
	for row in nested:
		if not row is Dictionary or not by_id.has(String(row.get("id", ""))) or by_id[String(row.get("id", ""))] != row:
			maps_match = false
	_check(maps_match, "pack: every map row equals its entries row")
	var row_ids := by_id.keys()
	for decision in pack.get("decisions", []):
		for opt in decision.get("options", {}).values():
			for echo_id in opt.get("echo_ids", []):
				_check(row_ids.has(echo_id), "pack: %s echo %s resolves" % [decision.get("id", ""), echo_id])
	_check(not by_id.values().any(func(row): return String(row.get("decision_id", "")) == "D8"),
		"pack: D8 (chapter upgrade) has no scene echo rows")
	for row in entries:
		var scene_id := String(row.get("scene_id", ""))
		var source_id := String(row.get("source_scene_id", ""))
		_check(RoomContract.scene_order(scene_id) > 0 and RoomContract.scene_order(source_id) > 0,
			"pack: %s has canon scene ids" % row.get("id", ""))
		if bool(row.get("same_scene", false)):
			_check(scene_id == source_id, "pack: %s same_scene echo is in its source scene" % row.get("id", ""))
		else:
			_check(RoomContract.scene_order(scene_id) > RoomContract.scene_order(source_id),
				"pack: %s echo is after its source scene" % row.get("id", ""))
		for key in ["id", "decision_id", "scene_id", "source_scene_id", "kind", "target_id", "title", "text"]:
			_check(not String(row.get(key, "")).is_empty(), "pack: %s has %s" % [row.get("id", ""), key])
		_check(String(row.get("kind", "")) in ["object", "journal", "photo", "staging"],
			"pack: %s kind is known" % row.get("id", ""))
		_check(String(row.get("text", "")).find("Noor") == -1 and String(row.get("title", "")).find("Noor") == -1,
			"pack: %s carries no banned name" % row.get("id", ""))
	var d7: Dictionary = _find(entries, "ECHO-D7-CH08-S02")
	_check(String(d7.get("requires_completed_scene", "")) == "EX-CH04-S04",
		"pack: D7 echo is gated on completed EX-CH04-S04 (P-07 beacon placement)")
	_check(pack.get("scene_gated", {}).get("EX-CH04-S04", []).size() == 1,
		"pack: scene_gated map holds the D7 row under EX-CH04-S04")

## Each D-row fires only in its later scene and only for its recorded option.
func _test_choice_echoes() -> void:
	var cases := [
		{"choice": "EX-CH02-S06-CHOICE", "option": "EX-CH02-S06-OPT01", "other": "ECHO-D4-OPT02-CH04-S01",
			"present": [["EX-CH04-S01", "ECHO-D4-OPT01-CH04-S01"]],
			"absent": [["EX-CH02-S06", "ECHO-D4-OPT01-CH04-S01"]]},
		{"choice": "EX-CH02-S10-CHOICE", "option": "EX-CH02-S10-OPT02", "other": "ECHO-D5-OPT01-CH05-S03",
			"present": [["EX-CH05-S03", "ECHO-D5-OPT02-CH05-S03"]],
			"absent": [["EX-CH02-S10", "ECHO-D5-OPT02-CH05-S03"]]},
		{"choice": "EX-CH03-S11-DEDICATION", "option": "EX-CH03-S11-DEDICATION-OPT03", "other": "ECHO-D6-OPT01-CH04-S01",
			"present": [["EX-CH04-S01", "ECHO-D6-OPT03-CH04-S01"], ["EX-CH08-S12", "ECHO-D6-OPT03-CH08-S12"]],
			"absent": [["EX-CH03-S11", "ECHO-D6-OPT03-CH04-S01"]]},
		{"choice": "EX-CH05-S05-CHOICE", "option": "EX-CH05-S05-OPT01", "other": "ECHO-D9-OPT02-CH05-S06",
			"present": [["EX-CH05-S06", "ECHO-D9-OPT01-CH05-S06"], ["EX-CH08-S12", "ECHO-D9-OPT01-CH08-S12"]],
			"absent": [["EX-CH05-S05", "ECHO-D9-OPT01-CH05-S06"]]},
		{"choice": "EX-CH05-S11-CHOICE", "option": "EX-CH05-S11-OPT01", "other": "ECHO-D10-OPT02-CH05-S12",
			"present": [["EX-CH06-S12", "ECHO-D10-OPT01-CH06-S12"], ["EX-CH07-S10", "ECHO-D10-OPT01-CH07-S10"], ["EX-CH08-S12", "ECHO-D10-OPT01-CH08-S12"]],
			"absent": [["EX-CH05-S11", "ECHO-D10-OPT01-CH06-S12"]]},
		{"choice": "EX-CH05-S11-CHOICE", "option": "EX-CH05-S11-OPT02", "other": "ECHO-D10-OPT01-CH06-S12",
			"present": [["EX-CH05-S12", "ECHO-D10-OPT02-CH05-S12"], ["EX-CH08-S10", "ECHO-D10-OPT02-CH08-S10"], ["EX-CH08-S12", "ECHO-D10-OPT02-CH08-S12"]],
			"absent": [["EX-CH05-S11", "ECHO-D10-OPT02-CH05-S12"]]},
		{"choice": "EX-CH06-S01-CHOICE", "option": "EX-CH06-S01-OPT02", "other": "ECHO-D11-OPT01-CH06-S10",
			"present": [["EX-CH06-S10", "ECHO-D11-OPT02-CH06-S10"], ["EX-CH08-S01", "ECHO-D11-OPT02-CH08-S01"]],
			"absent": [["EX-CH06-S01", "ECHO-D11-OPT02-CH06-S10"]]},
		{"choice": "EX-CH06-S08-CHOICE", "option": "EX-CH06-S08-OPT01", "other": "ECHO-D12-OPT02-CH07-S12",
			"present": [["EX-CH07-S12", "ECHO-D12-OPT01-CH07-S12"], ["EX-CH08-S03", "ECHO-D12-OPT01-CH08-S03"], ["EX-CH08-S07", "ECHO-D12-OPT01-CH08-S07"]],
			"absent": [["EX-CH06-S08", "ECHO-D12-OPT01-CH07-S12"]]},
		{"choice": "EX-CH08-S12-CHOICE", "option": "EX-CH08-S12-OPT01", "other": "ECHO-D13-OPT02-CH08-S12",
			"present": [["EX-CH08-S12", "ECHO-D13-OPT01-CH08-S12"]],
			"absent": []},
		{"choice": "EX-CH01-S01-CHOICE", "option": "EX-CH01-S01-OPT01", "other": "ECHO-D1-OPT02-CH08-S05",
			"present": [["EX-CH08-S05", "ECHO-D1-OPT01-CH08-S05"], ["EX-CH08-S12", "ECHO-D1-OPT01-CH08-S12"]],
			"absent": [["EX-CH01-S01", "ECHO-D1-OPT01-CH08-S05"]]},
	]
	for item in cases:
		var snap := _snap({String(item.choice): {"option_id": String(item.option)}})
		for pair in item.present:
			_check(_fired(snap, String(pair[0])).has(String(pair[1])),
				"echo: %s fires in %s for %s" % [pair[1], pair[0], item.option])
		for pair in item.absent:
			_check(not _fired(snap, String(pair[0])).has(String(pair[1])),
				"echo: %s does not fire in %s" % [pair[1], pair[0]])
		for pair in item.present:
			_check(not _fired(snap, String(pair[0])).has(String(item.other)),
				"echo: the other option's row %s stays silent for %s" % [item.other, item.option])
		var empty := _snap()
		for pair in item.present:
			_check(not _fired(empty, String(pair[0])).has(String(pair[1])),
				"echo: %s does not fire with nothing recorded" % pair[1])

## D7 fires only once the beacon scene is complete; D8 has no scene echo.
func _test_scene_gated() -> void:
	var done := _snap({}, [], ["EX-CH04-S04"])
	_check(_fired(done, "EX-CH08-S02").has("ECHO-D7-CH08-S02"),
		"echo: D7 fires in EX-CH08-S02 once EX-CH04-S04 is complete")
	_check(not _fired(_snap(), "EX-CH08-S02").has("ECHO-D7-CH08-S02"),
		"echo: D7 does not fire before the beacons are placed")
	_check(not _fired(_snap({}, [], ["EX-CH04-S12"]), "EX-CH08-S02").has("ECHO-D7-CH08-S02"),
		"echo: D7 gate is the beacon scene EX-CH04-S04, not the chapter debrief")
	_check(not _fired(done, "EX-CH08-S01").has("ECHO-D7-CH08-S02"),
		"echo: D7 does not fire in the wrong scene")

## The mugs moment echo fires only with the moment recorded.
func _test_moment_echo() -> void:
	var with_moment := _snap({}, ["CH01-MUGS-NAMED"])
	_check(_fired(with_moment, "EX-CH04-S12").has("ECHO-MOMENT-MUGS-CH04-S12"),
		"echo: mugs moment fires in EX-CH04-S12")
	_check(not _fired(_snap(), "EX-CH04-S12").has("ECHO-MOMENT-MUGS-CH04-S12"),
		"echo: mugs moment does not fire without the moment")
	_check(not _fired(_snap({}, ["CH05-HATCH-PAUSE"]), "EX-CH04-S12").has("ECHO-MOMENT-MUGS-CH04-S12"),
		"echo: a different moment does not fire the mugs echo")

## The Decisions tab still shows D1 echoes only for allowed scenes, through
## the shared trigger check.
func _test_decisions_tab_rewire() -> void:
	var snap := _snap(
		{"EX-CH01-S01-CHOICE": {"option_id": "EX-CH01-S01-OPT01", "scenario_datetime": "2046-04-11 10:00 UTC", "state_revision": 1}},
		[], ["EX-CH01-S01"])
	snap["scene_id"] = "EX-CH08-S05"
	var journal: Dictionary = CampaignKnowledge.journal(snap)
	var found := false
	for entry in journal["tabs"]["decisions"]["entries"]:
		if String(entry.get("choice_id", "")) != "EX-CH01-S01-CHOICE":
			continue
		if String(entry.get("option_id", "")) != "EX-CH01-S01-OPT01":
			continue
		found = true
		var echo_ids := _ids(entry.get("echoes", []))
		_check(echo_ids.has("ECHO-D1-OPT01-CH08-S05"),
			"tab: D1 air-gauge echo is listed in EX-CH08-S05")
		_check(not echo_ids.has("ECHO-D1-OPT01-CH08-S12"),
			"tab: D1 final-board echo stays hidden until EX-CH08-S12 is reached")
	_check(found, "tab: D1 decision entry is present with its option recorded")
	var unrecorded: Dictionary = CampaignKnowledge.journal(_snap({}, [], ["EX-CH01-S01"]))
	var listed := false
	for entry in unrecorded["tabs"]["decisions"]["entries"]:
		if String(entry.get("choice_id", "")) == "EX-CH01-S01-CHOICE":
			listed = true
	_check(not listed, "tab: no D1 decision entry without the choice recorded")

## The new LOC-08 layers and the existing D-row staging gate on the choice.
func _test_staging() -> void:
	var beacon := RoomContract.staged_layout("LOC-08", "EX-CH08-S02", {}, [])
	_check(beacon.get("stage", {}).get("layers", []).has("ch08_d7_beacon_layer"),
		"staging: October beacon layer is active in EX-CH08-S02")
	var beacon_sign: Dictionary = _find(beacon.get("signs", []), "october_beacons_text")
	_check(String(beacon_sign.get("text", "")).contains("OCTOBER BEACONS"),
		"staging: beacon layer captions the faint older layer")
	for beacon_id in ["october_beacon_1", "october_beacon_2", "october_beacon_3"]:
		_check(not _find(beacon.get("fixtures", []), beacon_id).is_empty(),
			"staging: beacon mark %s is on the route board" % beacon_id)
	var rafi := RoomContract.staged_layout("LOC-08", "EX-CH08-S01",
		{"EX-CH06-S01-CHOICE": {"option_id": "EX-CH06-S01-OPT01"}}, [])
	_check(rafi.get("stage", {}).get("layers", []).has("ch08_d11_rafi_clip"),
		"staging: Rafi clip layer is active in EX-CH08-S01 for OPT01")
	_check(not rafi.get("stage", {}).get("layers", []).has("ch08_d11_amara_clip"),
		"staging: Amara clip layer stays off for OPT01")
	_check(rafi.get("stage", {}).get("carried", {}).get("kai", {}).get("path", "") == "res://assets/props/PR_HandLight/PR_HandLight.glb",
		"staging: Rafi clips the hand light onto Kai's suit")
	_check(rafi.get("anchors", {}).get("rover_rafi", []) == [-0.35, 0.0, -1.55],
		"staging: Rafi stands beside Kai for the clip")
	var amara := RoomContract.staged_layout("LOC-08", "EX-CH08-S01",
		{"EX-CH06-S01-CHOICE": {"option_id": "EX-CH06-S01-OPT02"}}, [])
	_check(amara.get("stage", {}).get("layers", []).has("ch08_d11_amara_clip"),
		"staging: Amara clip layer is active in EX-CH08-S01 for OPT02")
	_check(not amara.get("stage", {}).get("layers", []).has("ch08_d11_rafi_clip"),
		"staging: Rafi clip layer stays off for OPT02")
	_check(amara.get("stage", {}).get("carried", {}).get("kai", {}).get("path", "") == "res://assets/props/PR_HandLight/PR_HandLight.glb",
		"staging: Amara clips the hand light onto Kai's suit")
	_check(amara.get("anchors", {}).get("rover_amara", []) == [-1.65, 0.0, -1.55],
		"staging: Amara stands beside Kai at the airlock side")
	var neither := RoomContract.staged_layout("LOC-08", "EX-CH08-S01", {}, [])
	_check(not neither.get("stage", {}).get("layers", []).has("ch08_d11_rafi_clip")
		and not neither.get("stage", {}).get("layers", []).has("ch08_d11_amara_clip"),
		"staging: no clip layer without a recorded companion choice")
	var shoulder := RoomContract.staged_layout("LOC-02", "EX-CH06-S10",
		{"EX-CH06-S01-CHOICE": {"option_id": "EX-CH06-S01-OPT01"}}, [])
	_check(shoulder.get("anchors", {}).get("service_rafi", []) == [-4.35, 0.0, 2.5],
		"staging: Rafi is at Kai's shoulder in EX-CH06-S10 for OPT01")
	var bunk := RoomContract.staged_layout("LOC-08", "EX-CH07-S12",
		{"EX-CH06-S08-CHOICE": {"option_id": "EX-CH06-S08-OPT01"}}, [])
	var bunk_sign: Dictionary = _find(bunk.get("signs", []), "kai_family_copy_text")
	_check(String(bunk_sign.get("text", "")).contains("RING DIAGRAM"),
		"staging: Kai's ring-diagram copy is pinned at his bunk for OPT01")
	var count := RoomContract.staged_layout("LOC-03", "EX-CH04-S01", {}, [])
	_check(count.get("stage", {}).get("layers", []).has("ch04_what_grew"),
		"staging: October count layer is active in EX-CH04-S01")
	var plaque := RoomContract.staged_layout("LOC-03", "EX-CH08-S12",
		{"EX-CH08-S12-CHOICE": {"option_id": "EX-CH08-S12-OPT01"}}, [])
	_check(plaque.get("stage", {}).get("layers", []).has("ch08_d13_plaque_opt01"),
		"staging: dedication plaque layer is active in EX-CH08-S12 for OPT01")
