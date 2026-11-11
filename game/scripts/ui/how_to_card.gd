extends VBoxContainer
class_name HowToCard

## Reusable teaching content (doc 25 §7): title, one-line purpose, at most three
## steps, the mechanic's how-to clip, then a guided first use. Movement/look/use
## onboarding belongs to M1-18.
const PATH := "res://resources/campaign/content/how_to.json"

static func data() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

static func card_id(query: Dictionary) -> String:
	return String(data().get("scenes", {}).get(String(query.get("scene_id", "")), "evidence"))

static func lesson(id: String) -> Dictionary:
	return data().get("cards", {}).get(id, {}).duplicate(true)

## The registered mechanics (doc 25 §7 and §8.3), in the order a player meets them.
static func mechanics() -> Array:
	return data().get("mechanics", []).duplicate()

## Mechanics whose first use is this goal target: their first-time card is due.
static func first_time_for(target_id: String) -> Array:
	var due: Array = []
	if target_id.is_empty():
		return due
	var cards: Dictionary = data().get("cards", {})
	for id in mechanics():
		if cards.get(id, {}).get("first_targets", []).has(target_id):
			due.append(id)
	return due

## Mechanics met by this chapter, for Journal → How to (no later spoilers).
static func reached(chapter: int) -> Array:
	var cards: Dictionary = data().get("cards", {})
	return mechanics().filter(func(id): return int(cards.get(id, {}).get("chapter", 99)) <= chapter)

func show_lesson(content: Dictionary) -> void:
	add_theme_constant_override("separation", 12)
	add_child(UiDesign.label(String(content.get("purpose", "")), "body"))
	var steps: Array = content.get("steps", [])
	for index in mini(3, steps.size()):
		add_child(UiDesign.label("%d. %s" % [index + 1, String(steps[index])], "body"))
