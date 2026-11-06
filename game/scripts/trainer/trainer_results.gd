extends RefCounted

const DEFAULT_PATH := "user://mission_trainer_results.json"
const ENDINGS := ["BLOOM", "GOLDEN", "ALO_LOST", "MISSION_STOPPED"]
const STARS := ["safe_exposure", "no_blackout", "alo_alive"]
var path := DEFAULT_PATH
var results: Dictionary = {}

func load_results() -> Dictionary:
	if not FileAccess.file_exists(path):
		results = {}
		return {"accepted": true}
	var parser := JSON.new()
	var parsed := parser.parse(FileAccess.get_file_as_string(path))
	var raw = parser.data if parsed == OK else null
	if not _valid(raw):
		return {"accepted": false, "reason": "Training results could not be opened. The saved file is preserved."}
	results = raw.results.duplicate(true)
	return {"accepted": true}

func record(scenario_id: String, outcome: Dictionary) -> Dictionary:
	var loaded := load_results()
	if not loaded.accepted:
		return loaded
	var next := results.duplicate(true)
	next[scenario_id] = {"ending": outcome.get("ending"), "stars": outcome.get("stars", {}).duplicate(true), "star_count": outcome.get("star_count")}
	var data := {"schema_version": 1, "results": next}
	if not _valid(data):
		return {"accepted": false, "reason": "These training results are incomplete and could not be saved."}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return {"accepted": false, "reason": "Training results could not be saved. Check that the folder is writable."}
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or not _valid(JSON.parse_string(FileAccess.get_file_as_string(path + ".tmp"))) or DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)) != OK:
		DirAccess.remove_absolute(path + ".tmp")
		return {"accepted": false, "reason": "Training results could not be saved. Your previous results are preserved."}
	results = next
	return {"accepted": true}

func _valid(raw) -> bool:
	if not raw is Dictionary or raw.get("schema_version") != 1 or not raw.get("results") is Dictionary:
		return false
	for id in raw.results:
		# Only the implemented exercise can produce results today.
		if id != "P-02":
			return false
		var row = raw.results[id]
		if not row is Dictionary or not ENDINGS.has(row.get("ending")) or not row.get("stars") is Dictionary or row.stars.size() != STARS.size():
			return false
		for star in STARS:
			if not row.stars.get(star) is bool:
				return false
		if not (row.get("star_count") is int or row.get("star_count") is float) or row.star_count != row.stars.values().count(true):
			return false
	return true
