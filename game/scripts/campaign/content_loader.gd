extends RefCounted
class_name CampaignContent

const SLICE_PATH := "res://resources/campaign/ch01_slice.json"
const EXPECTED_SOURCE_SHA := "02fa2dee03d11d455f67406de28a4da3cee97b1f8f19fda2cee0e6c1e895a272"

static func load_slice(path: String = SLICE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Campaign slice content is missing: " + path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Campaign slice content is not a JSON object")
		return {}
	return parsed as Dictionary

static func validate(content: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	if content.get("source_sha256", "") != EXPECTED_SOURCE_SHA:
		errors.append("source_sha256 does not match story-data.json")
	var chapter: Dictionary = content.get("chapter", {})
	if chapter.get("id", "") != "CH01" or chapter.get("title", "") != "Night One":
		errors.append("chapter identity is not CH01 / Night One")
	var scenes: Array = content.get("scenes", [])
	var expected := ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"]
	if scenes.size() != expected.size():
		errors.append("commissioning slice must contain exactly three scenes")
	for index in range(mini(scenes.size(), expected.size())):
		if scenes[index].get("id", "") != expected[index]:
			errors.append("scene order contains " + str(scenes[index].get("id", "")))
		if scenes[index].get("dialogue", []).is_empty():
			errors.append(expected[index] + " has no dialogue")
	return {"valid": errors.is_empty(), "errors": errors}

static func scene_at(content: Dictionary, index: int) -> Dictionary:
	var scenes: Array = content.get("scenes", [])
	if index < 0 or index >= scenes.size():
		return {}
	return scenes[index] as Dictionary
