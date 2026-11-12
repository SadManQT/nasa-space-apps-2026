## M1-22: the anonymous playtest log is off by default and, when on, writes one
## JSON line per event with in-game play time and nothing personal.
extends SceneTree

var checks := 0
var failures := 0

func _init() -> void:
	_check(not PlaytestLog.enabled(), "the playtest log is off without --playtest")
	PlaytestLog.event("action", {"accepted": true})
	_check(PlaytestLog._path.is_empty(), "nothing is written while it is off")
	PlaytestLog._on = true
	PlaytestLog._path = "user://playtest_test_%d.jsonl" % OS.get_process_id()
	PlaytestLog.event("scene", {"scene": "EX-CH01-S01"}, 12.34)
	PlaytestLog.event("try", {"puzzle": "P-02"}, 30.0)
	var lines := FileAccess.get_file_as_string(PlaytestLog._path).strip_edges().split("\n")
	var first: Dictionary = JSON.parse_string(lines[0])
	_check(lines.size() == 2 and first.event == "scene" and is_equal_approx(float(first.t_play), 12.3) and first.scene == "EX-CH01-S01", "each event is one JSON line with rounded play time")
	_check(not first.has("name") and not first.has("text"), "no personal fields are stored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PlaytestLog._path))
	print("PLAYTEST LOG RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + label)
