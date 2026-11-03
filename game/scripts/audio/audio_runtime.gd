extends RefCounted
class_name CampaignAudioRuntime

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DialogueScript = preload("res://scripts/dialogue/dialogue_service.gd")
const MEDIA_PATH := "res://resources/campaign/content/presentation_media.json"
const SUPPORTED_AUDIO_EXTENSIONS := ["ogg", "wav"]

var _content: Dictionary = {}
var _dialogue: RefCounted
var _metadata: Dictionary = {}

func _init(content: Dictionary = {}, metadata_override: Dictionary = {}) -> void:
	_content = content if not content.is_empty() else ContentScript.load_full()
	_dialogue = DialogueScript.new(_content)
	_metadata = metadata_override.duplicate(true) if not metadata_override.is_empty() else _read_metadata()

func has_runtime_voice() -> bool:
	return _runtime_audio_files().size() > 0

func has_runtime_music() -> bool:
	return _runtime_metadata_files("music_runtime_files").size() > 0

func has_runtime_sfx() -> bool:
	return _runtime_metadata_files("sfx_runtime_files").size() > 0

func metadata() -> Dictionary:
	return _metadata.duplicate(true)

func voice_plan(line_id: String, acquired_flags: Array = []) -> Dictionary:
	var caption: Dictionary = _dialogue.caption_for_line(line_id, acquired_flags)
	var line: Dictionary = _dialogue.dialogue_by_id(line_id)
	if not bool(caption.get("available", false)):
		return {
			"mode": "locked",
			"line_id": line_id,
			"media_present": false,
			"caption": caption,
			"reason": String(caption.get("reason", "Source not acquired yet.")),
		}
	var runtime_path := _runtime_path(String(line.get("voice_file", "")))
	if _supported_audio_file(runtime_path):
		return {
			"mode": "voice",
			"line_id": line_id,
			"media_present": true,
			"runtime_path": runtime_path,
			"caption": caption,
		}
	return {
		"mode": "captions_only",
		"line_id": line_id,
		"media_present": false,
		"runtime_path": "",
		"caption": caption,
		"reason": "No runtime voice file is installed; exact caption text remains available.",
	}

func _read_metadata() -> Dictionary:
	if not FileAccess.file_exists(MEDIA_PATH):
		return {"audio": {"fallback_mode": "captions_only"}, "available_cutscenes": []}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MEDIA_PATH))
	return parsed as Dictionary if parsed is Dictionary else {"audio": {"fallback_mode": "captions_only"}, "available_cutscenes": []}

func _runtime_audio_files() -> Array:
	var result: Array = []
	for line in _content.get("dialogue", []):
		if not line is Dictionary:
			continue
		var path := _runtime_path(String(line.get("voice_file", "")))
		if _supported_audio_file(path) and not result.has(path):
			result.append(path)
	return result

func _runtime_metadata_files(key: String) -> Array:
	var audio_value = _metadata.get("audio", {})
	if not audio_value is Dictionary:
		return []
	var raw = (audio_value as Dictionary).get(key, [])
	var candidates: Array = raw if raw is Array else [raw]
	var result: Array = []
	for candidate in candidates:
		var path := _runtime_path(String(candidate))
		if _supported_audio_file(path) and not result.has(path):
			result.append(path)
	return result

func _supported_audio_file(path: String) -> bool:
	return not path.is_empty() and path.get_extension().to_lower() in SUPPORTED_AUDIO_EXTENSIONS and FileAccess.file_exists(path)

func _runtime_path(source_path: String) -> String:
	if source_path.begins_with("res://"):
		return source_path
	if source_path.begins_with("game/"):
		return "res://" + source_path.substr(5)
	return ""
