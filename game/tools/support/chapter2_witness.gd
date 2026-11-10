extends RefCounted

## Test fixture: the accepted P-03 prediction and P-04 token choices (from their
## content data) as the inputs a player would choose at the Chapter 2 panel.
## Gameplay never calls this; suites that walk the Chapter 2 handoff use it
## because the route no longer pre-fills these decisions.

const P03_CONTENT := "res://resources/campaign/content/p03_pollination.json"
const P04_CONTENT := "res://resources/campaign/content/p04_recorder_reconstruction.json"

static func payload(action: String) -> Dictionary:
	if action == "p03_record_prediction":
		var p03 = JSON.parse_string(FileAccess.get_file_as_string(P03_CONTENT))
		var fields: Dictionary = p03.get("choices", {}).get("prediction", {}).get("fields", {}) if p03 is Dictionary else {}
		var chosen := {}
		for field in ["prediction", "reason", "future_test"]:
			for option in fields.get(field, []):
				if bool(option.get("correct", false)):
					chosen[field] = String(option.get("value", ""))
					break
		return chosen
	if action.begins_with("p04_assign_"):
		var p04 = JSON.parse_string(FileAccess.get_file_as_string(P04_CONTENT))
		var expected: Dictionary = p04.get("expected", {}) if p04 is Dictionary else {}
		return {"value": String(expected.get(action.trim_prefix("p04_assign_"), ""))}
	return {}
