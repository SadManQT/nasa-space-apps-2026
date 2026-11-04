extends RefCounted
class_name CampaignAudioRuntime

## Read-only audio plans from presentation_media.json (built by
## production/tools/build_presentation_media.py). Every plan reports a file as
## present only when ResourceLoader can open it; otherwise the caption is the
## presentation. Playback itself lives in CampaignAudioDirector.

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DialogueScript = preload("res://scripts/dialogue/dialogue_service.gd")
const MEDIA_PATH := "res://resources/campaign/content/presentation_media.json"
const SUPPORTED_AUDIO_EXTENSIONS := ["ogg", "wav"]

var _content: Dictionary = {}
var _dialogue: RefCounted
var _metadata: Dictionary = {}
var _sfx_by_id: Dictionary = {}

## Pass the campaign's own dialogue service to avoid a second deep copy of the catalog.
func _init(content: Dictionary = {}, metadata_override: Dictionary = {}, dialogue: RefCounted = null) -> void:
	_content = content if not content.is_empty() or dialogue != null else ContentScript.load_full()
	_dialogue = dialogue if dialogue != null else DialogueScript.new(_content)
	_metadata = metadata_override.duplicate(true) if not metadata_override.is_empty() else read_metadata()
	for row in _audio_rows("sfx"):
		_sfx_by_id[String(row.get("id", ""))] = row

## The media manifest, or a captions-only stub when it is absent or unreadable.
static func read_metadata() -> Dictionary:
	if not FileAccess.file_exists(MEDIA_PATH):
		return {"audio": {"fallback_mode": "captions_only"}, "available_cutscenes": []}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MEDIA_PATH))
	return parsed as Dictionary if parsed is Dictionary else {"audio": {"fallback_mode": "captions_only"}, "available_cutscenes": []}

func has_runtime_voice() -> bool:
	return _runtime_audio_files().size() > 0

func has_runtime_music() -> bool:
	return _runtime_metadata_files("music_runtime_files").size() > 0

func has_runtime_sfx() -> bool:
	return _runtime_metadata_files("sfx_runtime_files").size() > 0

func metadata() -> Dictionary:
	return _metadata.duplicate(true)

## Mix value (dB or seconds) from the manifest's audio.mix block.
func mix(key: String, fallback: float = 0.0) -> float:
	var values = _audio().get("mix", {})
	return float(values.get(key, fallback)) if values is Dictionary else fallback

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

## The score for a scene: {cue_id, runtime_path, loop, media_present, sting_path},
## or {} for meaningful silence. Stemmed cues pick their per-scene variant.
func music_for_scene(scene_id: String) -> Dictionary:
	var cue_id := String(_audio().get("music_by_scene", {}).get(scene_id, ""))
	var cue := _cue(cue_id)
	if cue.is_empty():
		return {}
	var path := String(cue.get("runtime_path", ""))
	var variant := String(_audio().get("music_variant_by_scene", {}).get(scene_id, ""))
	if not variant.is_empty() and cue.get("variants", {}).has(variant):
		path = String(cue.variants[variant])
	var present := _supported_audio_file(path)
	var sting := String(cue.get("sting_path", "")) if String(cue.get("sting_scene", "")) == scene_id else ""
	return {
		"cue_id": cue_id,
		"runtime_path": path if present else "",
		"media_present": present,
		"loop": bool(cue.get("loop", false)),
		"sting_path": sting if _supported_audio_file(sting) else "",
	}

## The end-credits loop, or "" when it is not installed.
func credits_music_path() -> String:
	for cue in _audio_rows("music_cues"):
		var path := String(cue.get("credits_path", ""))
		if _supported_audio_file(path):
			return path
	return ""

## Looping beds for a scene: the scene's own list when it has one, else its room's.
func beds_for_scene(scene_id: String, room_id: String) -> Array:
	var scene_beds = _audio().get("scene_beds", {}).get(scene_id, null)
	var ids = scene_beds if scene_beds is Array else _audio().get("room_beds", {}).get(room_id, [])
	var result: Array = []
	for id in ids:
		var plan := sfx_plan(String(id))
		if bool(plan.loop):
			result.append(plan)
	return result

## One-shots that open a scene (alerts, the quake), in authored order.
func scene_sfx(scene_id: String) -> Array:
	var result: Array = []
	for id in _audio().get("scene_sfx", {}).get(scene_id, []):
		result.append(sfx_plan(String(id)))
	return result

## The effect for a physical operation, matched in authored order against its
## target id and label; accepted operations without a match get the UI confirm.
func operation_sfx(target_id: String, label: String, accepted: bool) -> Dictionary:
	var ui: Dictionary = _audio().get("ui_sfx", {})
	if not accepted:
		return sfx_plan(String(ui.get("rejected", "")))
	var haystack := (target_id + " " + label).to_lower()
	for pair in _audio().get("operation_sfx", []):
		if pair is Array and pair.size() == 2 and haystack.contains(String(pair[0])):
			return sfx_plan(String(pair[1]))
	return sfx_plan(String(ui.get("accepted", "")))

## The channel effect for a voice origin (earth_link, radio, recording), or {}.
func line_sfx(origin: String) -> Dictionary:
	var id := String(_audio().get("line_sfx", {}).get(origin, ""))
	return {} if id.is_empty() else sfx_plan(id)

## One effect by sfx_list.csv id. UI ids play on the UI bus.
func sfx_plan(sfx_id: String) -> Dictionary:
	var row: Dictionary = _sfx_by_id.get(sfx_id, {})
	var path := _runtime_path(String(row.get("runtime_path", "")))
	var present := _supported_audio_file(path)
	return {
		"id": sfx_id,
		"runtime_path": path if present else "",
		"media_present": present,
		"loop": bool(row.get("loop", false)),
		"caption": String(row.get("caption", "")),
		"bus": String(row.get("bus", "UI" if sfx_id.begins_with("SFX_UI_") else "SFX")),
	}

## Every installed file a scene can start with, for background prefetch.
func scene_media_paths(scene_id: String, room_id: String) -> Array:
	var result: Array = []
	var music := music_for_scene(scene_id)
	for path in [music.get("runtime_path", ""), music.get("sting_path", "")]:
		if not String(path).is_empty():
			result.append(path)
	for plan in beds_for_scene(scene_id, room_id) + scene_sfx(scene_id):
		if bool(plan.media_present) and not result.has(plan.runtime_path):
			result.append(plan.runtime_path)
	return result

func _cue(cue_id: String) -> Dictionary:
	for cue in _audio_rows("music_cues"):
		if String(cue.get("id", "")) == cue_id:
			return cue
	return {}

func _audio() -> Dictionary:
	var value = _metadata.get("audio", {})
	return value if value is Dictionary else {}

func _audio_rows(key: String) -> Array:
	var rows = _audio().get(key, [])
	return rows.filter(func(row) -> bool: return row is Dictionary) if rows is Array else []

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
	var raw = _audio().get(key, [])
	var candidates: Array = raw if raw is Array else [raw]
	var result: Array = []
	for candidate in candidates:
		var path := _runtime_path(String(candidate))
		if _supported_audio_file(path) and not result.has(path):
			result.append(path)
	return result

func _supported_audio_file(path: String) -> bool:
	# ResourceLoader, not FileAccess: an exported build keeps only the imported copy.
	return not path.is_empty() and path.get_extension().to_lower() in SUPPORTED_AUDIO_EXTENSIONS and ResourceLoader.exists(path)

func _runtime_path(source_path: String) -> String:
	if source_path.begins_with("res://"):
		return source_path
	if source_path.begins_with("game/"):
		return "res://" + source_path.substr(5)
	return ""
