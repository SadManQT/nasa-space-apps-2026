extends RefCounted
class_name PlaytestLog

## M1-22 learner playtest: an anonymous, local-only event log. It is OFF unless
## the game is launched with `--playtest` (the facilitator's launcher passes it).
## Each line of user://playtest/session_<start>.jsonl is one event with the
## in-game play time; it never stores names, input text, audio or images.
## production/qa/playtests/learner_kit/summarise.py turns the files into the
## M1-22 metrics (time to first objective, P-01/P-02 attempts, hints, ending).

static var _path := ""
static var _checked := false
static var _on := false

static func enabled() -> bool:
	if not _checked:
		_checked = true
		_on = OS.get_cmdline_user_args().has("--playtest") or OS.get_cmdline_args().has("--playtest")
	return _on

static func event(kind: String, data: Dictionary = {}, play_seconds: float = -1.0) -> void:
	if not enabled():
		return
	if _path.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://playtest"))
		_path = "user://playtest/session_%s.jsonl" % Time.get_datetime_string_from_system(true).replace(":", "-")
	var line := {"t_wall": Time.get_unix_time_from_system(), "t_play": snappedf(play_seconds, 0.1), "event": kind}
	line.merge(data)
	var file := FileAccess.open(_path, FileAccess.READ_WRITE if FileAccess.file_exists(_path) else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(line))
	file.close()
