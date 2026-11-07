extends VBoxContainer
class_name HowToCard

## Reusable teaching content; movement/look/use onboarding belongs to M1-18.
signal clip_requested
const PATH := "res://resources/campaign/content/how_to.json"

static func data() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

static func card_id(query: Dictionary) -> String:
	return String(data().get("scenes", {}).get(String(query.get("scene_id", "")), "evidence"))

static func lesson(id: String) -> Dictionary:
	return data().get("cards", {}).get(id, {}).duplicate(true)

func show_lesson(content: Dictionary) -> void:
	add_theme_constant_override("separation", 12)
	add_child(UiDesign.label(String(content.get("purpose", "")), "body"))
	var steps: Array = content.get("steps", [])
	for index in mini(3, steps.size()):
		add_child(UiDesign.label("%d. %s" % [index + 1, String(steps[index])], "body"))
	var clip := UiDesign.button("Watch the concept")
	clip.name = "HowToClip"
	clip.pressed.connect(func(): clip_requested.emit())
	add_child(clip)
