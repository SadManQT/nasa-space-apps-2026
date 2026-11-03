extends RefCounted
class_name CampaignCutsceneRuntime

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DialogueScript = preload("res://scripts/dialogue/dialogue_service.gd")
const MEDIA_PATH := "res://resources/campaign/content/presentation_media.json"
const SUPPORTED_RUNTIME_FORMAT := "ogv"

var _content: Dictionary = {}
var _dialogue: RefCounted
var _metadata: Dictionary = {}

func _init(content: Dictionary = {}, metadata_override: Dictionary = {}) -> void:
	_content = content if not content.is_empty() else ContentScript.load_full()
	_dialogue = DialogueScript.new(_content)
	_metadata = metadata_override.duplicate(true) if not metadata_override.is_empty() else _read_metadata()

func available_cutscenes() -> Array:
	var result: Array = []
	var available = _metadata.get("available_cutscenes", [])
	if not available is Array:
		return result
	for raw in available as Array:
		if raw is Dictionary:
			var item: Dictionary = raw.duplicate(true)
			item["media_present"] = _video_file_present(item)
			result.append(item)
	return result

func metadata_for_id(cutscene_id: String) -> Dictionary:
	for item in available_cutscenes():
		if String(item.get("id", "")) == cutscene_id:
			return item
	return {
		"id": cutscene_id,
		"status": "not_installed",
		"media_present": false,
		"runtime_path": "",
		"caption_fallback": true,
		"skip_completes_predicate": false,
	}

func playback_plan(cutscene_id: String, scene_id: String = "", acquired_flags: Array = []) -> Dictionary:
	var metadata := metadata_for_id(cutscene_id)
	var resolved_scene_id := scene_id if not scene_id.is_empty() else String(metadata.get("scene_id", ""))
	var lines: Array = _dialogue.lines_for_scene(resolved_scene_id, acquired_flags)
	var line_ids: Array = []
	for line in lines:
		if line is Dictionary:
			line_ids.append(String(line.get("id", "")))
	var media_present := _video_file_present(metadata)
	if media_present:
		return {
			"mode": "video",
			"cutscene_id": cutscene_id,
			"scene_id": resolved_scene_id,
			"runtime_path": String(metadata.get("runtime_path", "")),
			"media_present": true,
			"caption_line_ids": line_ids,
			"caption_fallback": true,
			"skip_completes_predicate": false,
		}
	return {
		"mode": "text_fallback",
		"cutscene_id": cutscene_id,
		"scene_id": resolved_scene_id,
		"runtime_path": "",
		"media_present": false,
		"caption_line_ids": line_ids,
		"captions": lines,
		"caption_fallback": true,
		"reason": "Cutscene media is not installed; exact dialogue/caption text is the runtime presentation.",
		"skip_completes_predicate": false,
	}

func skip(cutscene_id: String, scene_id: String = "") -> Dictionary:
	## Skipping changes presentation only. It deliberately emits no scene,
	## mission, puzzle, evidence or knowledge completion event.
	return {
		"accepted": true,
		"cutscene_id": cutscene_id,
		"scene_id": scene_id,
		"skipped": true,
		"media_present": _video_file_present(metadata_for_id(cutscene_id)),
		"events": [{"type": "cutscene_skipped", "cutscene_id": cutscene_id, "scene_id": scene_id}],
		"completes_predicate": false,
		"completes_scene": false,
		"completes_mission": false,
		"warnings": ["A cutscene skip never satisfies a physical operation or scene exit predicate."],
	}

func _read_metadata() -> Dictionary:
	if not FileAccess.file_exists(MEDIA_PATH):
		return {"available_cutscenes": [], "not_installed_cutscene_ids": []}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MEDIA_PATH))
	return parsed as Dictionary if parsed is Dictionary else {"available_cutscenes": [], "not_installed_cutscene_ids": []}

func _video_file_present(metadata: Dictionary) -> bool:
	var runtime_path := String(metadata.get("runtime_path", ""))
	var runtime_format := String(metadata.get("runtime_format", "")).to_lower().trim_prefix(".")
	return runtime_format == SUPPORTED_RUNTIME_FORMAT and runtime_path.get_extension().to_lower() == SUPPORTED_RUNTIME_FORMAT and FileAccess.file_exists(runtime_path)
