extends RefCounted
class_name CampaignCutsceneRuntime

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DialogueScript = preload("res://scripts/dialogue/dialogue_service.gd")
const MEDIA_PATH := "res://resources/campaign/content/presentation_media.json"
const SUPPORTED_RUNTIME_FORMAT := "ogv"

var _content: Dictionary = {}
var _dialogue: RefCounted
var _metadata: Dictionary = {}

## Pass the campaign's own dialogue service to avoid a second deep copy of the catalog.
func _init(content: Dictionary = {}, metadata_override: Dictionary = {}, dialogue: RefCounted = null) -> void:
	_content = content if not content.is_empty() or dialogue != null else ContentScript.load_full()
	_dialogue = dialogue if dialogue != null else DialogueScript.new(_content)
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
			"choice_card": _choice_card_from(metadata),
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
		"choice_card": _choice_card_from(metadata),
		"reason": "Cutscene media is not installed; exact dialogue/caption text is the runtime presentation.",
		"skip_completes_predicate": false,
	}

## Playback plans for the cutscenes bound to a scene beat, in manifest order.
## trigger is "scene_enter" (the scene opens) or "campaign_complete" (post-credits).
func plans_for_scene(scene_id: String, trigger: String, acquired_flags: Array = []) -> Array:
	var result: Array = []
	for item in available_cutscenes():
		if String(item.get("scene_id", "")) == scene_id and String(item.get("trigger", "scene_enter")) == trigger:
			var plan := playback_plan(String(item.get("id", "")), scene_id, acquired_flags)
			plan["title"] = String(item.get("title", ""))
			result.append(plan)
	return result

## Scene lines the film has already spoken by position_s (from its caption cues),
## so the HUD shows them afterwards without voicing them a second time.
func heard_line_ids(cutscene_id: String, position_s: float) -> Array:
	var result: Array = []
	for cue in metadata_for_id(cutscene_id).get("caption_cues", []):
		if cue is Dictionary and float(cue.get("at", INF)) <= position_s:
			result.append(String(cue.get("line_id", "")))
	return result

## The save-dependent words a film closes on (manifest choice_card): timing and
## type from the manifest, the words from the catalog label of the named choice
## option, never retyped. {} when the cutscene has no card or the catalog has no
## such option. The player shows it only when the save recorded that option.
func choice_card(cutscene_id: String) -> Dictionary:
	return _choice_card_from(metadata_for_id(cutscene_id))

func _choice_card_from(metadata: Dictionary) -> Dictionary:
	var spec: Variant = metadata.get("choice_card", {})
	if not spec is Dictionary or (spec as Dictionary).is_empty():
		return {}
	var card: Dictionary = (spec as Dictionary).duplicate(true)
	card.erase("note")
	var text := _option_label(String(card.get("choice_id", "")), String(card.get("option_id", "")))
	if text.is_empty():
		return {}
	card["text"] = text
	return card

## Seconds a skip input must be held (manifest cutscene_controls.skip_hold_s).
func skip_hold_seconds() -> float:
	var controls = _metadata.get("cutscene_controls", {})
	return float(controls.get("skip_hold_s", 1.0)) if controls is Dictionary else 1.0

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

func _option_label(choice_id: String, option_id: String) -> String:
	var content := _content if _content.has("scenes") else ContentScript.load_full()
	for scene in content.get("scenes", []):
		var choice: Variant = (scene as Dictionary).get("choice", {}) if scene is Dictionary else {}
		if not choice is Dictionary or String((choice as Dictionary).get("id", "")) != choice_id:
			continue
		for option in (choice as Dictionary).get("options", []):
			if option is Dictionary and String((option as Dictionary).get("id", "")) == option_id:
				return String((option as Dictionary).get("label", ""))
	return ""

func _read_metadata() -> Dictionary:
	if not FileAccess.file_exists(MEDIA_PATH):
		return {"available_cutscenes": [], "not_installed_cutscene_ids": []}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MEDIA_PATH))
	return parsed as Dictionary if parsed is Dictionary else {"available_cutscenes": [], "not_installed_cutscene_ids": []}

func _video_file_present(metadata: Dictionary) -> bool:
	var runtime_path := String(metadata.get("runtime_path", ""))
	var runtime_format := String(metadata.get("runtime_format", "")).to_lower().trim_prefix(".")
	return runtime_format == SUPPORTED_RUNTIME_FORMAT and runtime_path.get_extension().to_lower() == SUPPORTED_RUNTIME_FORMAT and FileAccess.file_exists(runtime_path)
