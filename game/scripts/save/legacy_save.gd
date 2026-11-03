extends RefCounted
class_name LegacyCampaignSave

## The retired commissioning slot is preserved until the player explicitly
## chooses New Expedition and confirms replacement. Never migrate partial
## slice progress into a full campaign without physical-route evidence.
const SAVE_PATH := "user://last_light_expedition.json"

static func clear_save(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
