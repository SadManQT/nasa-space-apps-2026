extends RefCounted
class_name Curriculum

## M3-69: read-only learning record for the actual campaign. A moment is earned
## only after every scene in its mapped mission is complete. This keeps the
## manual, chapter debrief and cadet record in step with the save's route.

const PATH := "res://resources/campaign/content/curriculum.json"
const Content = preload("res://scripts/content/content_loader.gd")
const Science = preload("res://scripts/science/science_data.gd")
const Explainers = preload("res://scripts/ui/science_explainers.gd")
const STAGES := ["learned", "practised", "proved"]

static var _data: Dictionary = {}
static var _missions: Dictionary = {}
static var _scenes: Dictionary = {}

static func catalog() -> Dictionary:
	return _source().duplicate(true)

static func competencies() -> Array:
	return _source().get("competencies", []).duplicate(true)

static func competency(id: String) -> Dictionary:
	for row in _source().get("competencies", []):
		if String(row.get("id", "")) == id:
			return row.duplicate(true)
	return {}

## Pure events for a verified mission completion hook. The caller should only
## use these after campaign scene-exit validation, then save through its usual
## save API. Replaying a mission yields the same stable IDs.
static func moment_events_for_mission(mission_id: String) -> Array:
	var events: Array = []
	for row in _source().get("competencies", []):
		var moments: Dictionary = row.get("moments", {})
		for stage in STAGES:
			for item in moments.get(stage, []):
				if String(item.get("mission", "")) != mission_id:
					continue
				events.append({
					"id": "%s:%s:%s" % [String(row.id), stage, mission_id],
					"competency_id": String(row.id),
					"stage": stage,
					"mission_id": mission_id,
					"evidence": String(item.get("evidence", "")),
				})
	return events

static func mission_complete(mission_id: String, snapshot: Dictionary) -> bool:
	_index_campaign()
	var mission: Dictionary = _missions.get(mission_id, {})
	var scenes: Array = mission.get("scene_ids", [])
	var completed = snapshot.get("completed_scene_ids", [])
	return completed is Array and not scenes.is_empty() and scenes.all(func(scene_id): return completed.has(scene_id))

## Deterministic cadet-record projection from the authoritative completed-scene
## ledger. No manual progress counter can unlock an unplayed competency.
static func progress(snapshot: Dictionary) -> Array:
	var result: Array = []
	for row in _source().get("competencies", []):
		result.append(progress_for(String(row.id), snapshot))
	return result

static func progress_for(id: String, snapshot: Dictionary) -> Dictionary:
	var row := competency(id)
	if row.is_empty():
		return {}
	var earned: Dictionary = {"learned": [], "practised": [], "proved": []}
	for stage in STAGES:
		for item in row.get("moments", {}).get(stage, []):
			var mission_id := String(item.get("mission", ""))
			if mission_complete(mission_id, snapshot):
				var event: Dictionary = {
					"id": "%s:%s:%s" % [id, stage, mission_id],
					"competency_id": id,
					"stage": stage,
					"mission_id": mission_id,
					"mission_title": String(_missions.get(mission_id, {}).get("title", mission_id)),
					"evidence": String(item.get("evidence", "")),
				}
				earned[stage].append(event)
	var level := 0
	for stage in STAGES:
		if earned[stage].is_empty():
			break
		level += 1
	return {
		"id": id,
		"title": String(row.get("title", id)),
		"level": level,
		"label": ["Ahead", "Learned", "Practised", "Proved"][level],
		"moments": earned,
	}

## One spoiler-gated Academy Manual page. The recorded choices are read from
## story_log, so the page never presents a script option as the cadet's choice.
static func manual_page(id: String, snapshot: Dictionary) -> Dictionary:
	var row := competency(id)
	if row.is_empty():
		return {}
	var status := progress_for(id, snapshot)
	var unlocked: bool = int(status.get("level", 0)) > 0
	var page := {
		"id": id,
		"title": String(row.get("title", id)),
		"unlocked": unlocked,
		"status": status,
		"plain": String(row.get("plain", "")) if unlocked else "Play the campaign to open this Academy Manual page.",
		"data_cards": [],
		"explainers": [],
		"decisions": [],
	}
	if not unlocked:
		return page
	var science := Science.new()
	for source_id in row.get("source_ids", []):
		var card: Dictionary = science.card(String(source_id))
		page.data_cards.append({
			"id": String(source_id),
			"title": String(card.get("title", "Real data")),
			"takeaway": String(card.get("takeaway", "")),
		})
	for explainer_id in row.get("explainer_ids", []):
		var clip: Dictionary = Explainers.find(String(explainer_id))
		if not clip.is_empty():
			page.explainers.append({"id": String(explainer_id), "title": String(clip.get("title", "Science clip"))})
	var seen_scenes := {}
	for stage in STAGES:
		for event in status.moments[stage]:
			var mission: Dictionary = _missions.get(String(event.mission_id), {})
			for scene_id in mission.get("scene_ids", []):
				if seen_scenes.has(scene_id):
					continue
				var replay := _recorded_choice(String(scene_id), snapshot)
				if not replay.is_empty():
					page.decisions.append(replay)
					seen_scenes[scene_id] = true
	if page.decisions.size() > 3:
		page.decisions = page.decisions.slice(-3)
	return page

## Chapter-end page: exactly three takeaways, their real source cards and one
## replayed choice. It appears only after the chapter's S12 has completed.
static func chapter_learning(chapter: int, snapshot: Dictionary) -> Dictionary:
	if chapter < 1 or chapter > 8:
		return {}
	var completed = snapshot.get("completed_scene_ids", [])
	if not completed is Array or not completed.has("EX-CH%02d-S12" % chapter):
		return {}
	var spec: Dictionary = {}
	for row in _source().get("chapter_debriefs", []):
		if int(row.get("chapter", 0)) == chapter:
			spec = row
			break
	if spec.is_empty():
		return {}
	var science := Science.new()
	var things: Array = []
	for item in spec.get("things", []):
		var source_id := String(item.get("source_id", ""))
		var card: Dictionary = science.card(source_id)
		things.append({
			"text": String(item.get("text", "")),
			"source_id": source_id,
			"source_title": String(card.get("title", "Real data")),
			"source_takeaway": String(card.get("takeaway", "")),
		})
	var scene_id := String(spec.get("decision_scene", ""))
	return {
		"chapter": chapter,
		"title": "Chapter %d · %s" % [chapter, String(spec.get("title", ""))],
		"things": things,
		"decision": _recorded_choice(scene_id, snapshot),
		"decision_scene": scene_id,
	}

static func completed_chapter_learning(snapshot: Dictionary) -> Array:
	var result: Array = []
	for chapter in range(1, 9):
		var page := chapter_learning(chapter, snapshot)
		if not page.is_empty():
			result.append(page)
	return result

## Validate the authored pack against campaign missions, source fixtures and
## available clips. Every campaign mission is mapped so every puzzle is covered.
static func validate() -> Dictionary:
	_index_campaign()
	var errors: Array[String] = []
	var pack := _source()
	var comps: Array = pack.get("competencies", [])
	var debriefs: Array = pack.get("chapter_debriefs", [])
	if comps.size() != 12:
		errors.append("Expected twelve competencies.")
	if debriefs.size() != 8:
		errors.append("Expected eight chapter debriefs.")
	var seen_ids := {}
	var covered_missions := {}
	var science := Science.new()
	for row in comps:
		if not row is Dictionary:
			errors.append("A competency is not a dictionary.")
			continue
		var id := String(row.get("id", ""))
		if id.is_empty() or seen_ids.has(id):
			errors.append("Duplicate or missing competency ID: " + id)
		seen_ids[id] = true
		if String(row.get("title", "")).is_empty() or String(row.get("plain", "")).is_empty():
			errors.append(id + ": missing manual text")
		var moments: Dictionary = row.get("moments", {})
		var first_indices: Array = []
		for stage in STAGES:
			var entries: Array = moments.get(stage, [])
			if entries.is_empty():
				errors.append(id + ": no " + stage + " moment")
			var first_index := 999
			var seen_stage := {}
			for item in entries:
				if not item is Dictionary:
					errors.append(id + ": invalid moment")
					continue
				var mid := String(item.get("mission", ""))
				if not _missions.has(mid) or seen_stage.has(mid):
					errors.append(id + ": unknown or duplicate mission " + mid)
				seen_stage[mid] = true
				covered_missions[mid] = true
				if String(item.get("evidence", "")).is_empty():
					errors.append(id + ": missing moment evidence " + mid)
				first_index = mini(first_index, _mission_index(mid))
			first_indices.append(first_index)
		if first_indices.size() == 3 and (first_indices[0] > first_indices[1] or first_indices[1] > first_indices[2]):
			errors.append(id + ": learning stages are out of campaign order")
		if row.get("source_ids", []).is_empty() or row.get("explainer_ids", []).is_empty():
			errors.append(id + ": missing data card or explainer")
		for source_id in row.get("source_ids", []):
			if bool(science.card(String(source_id)).get("pending", true)):
				errors.append(id + ": missing source " + String(source_id))
		for explainer_id in row.get("explainer_ids", []):
			if Explainers.find(String(explainer_id)).is_empty():
				errors.append(id + ": missing explainer " + String(explainer_id))
	for mid in _missions:
		if not covered_missions.has(mid):
			errors.append("No competency mapped to " + String(mid))
	var seen_chapters := {}
	for row in debriefs:
		if not row is Dictionary:
			errors.append("Invalid chapter debrief.")
			continue
		var chapter := int(row.get("chapter", 0))
		if chapter < 1 or chapter > 8 or seen_chapters.has(chapter):
			errors.append("Duplicate or invalid chapter debrief: " + str(chapter))
		seen_chapters[chapter] = true
		var scene_id := String(row.get("decision_scene", ""))
		var scene: Dictionary = _scenes.get(scene_id, {})
		if int(scene.get("chapter_number", 0)) != chapter or not scene.get("choice", {}) is Dictionary or scene.get("choice", {}).is_empty():
			errors.append("Chapter %d has no real replay choice." % chapter)
		var things: Array = row.get("things", [])
		if things.size() != 3:
			errors.append("Chapter %d needs exactly three takeaways." % chapter)
		for thing in things:
			if String(thing.get("text", "")).is_empty() or bool(science.card(String(thing.get("source_id", ""))).get("pending", true)):
				errors.append("Chapter %d has an empty takeaway or missing source." % chapter)
	return {"valid": errors.is_empty(), "errors": errors}

static func _source() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data

static func _index_campaign() -> void:
	if not _missions.is_empty() and not _scenes.is_empty():
		return
	var campaign: Dictionary = Content.load_full()
	for mission in campaign.get("missions", []):
		_missions[String(mission.get("id", ""))] = mission
	for scene in campaign.get("scenes", []):
		_scenes[String(scene.get("id", ""))] = scene

static func _mission_index(mission_id: String) -> int:
	var clean := mission_id.trim_prefix("EX-M")
	return int(clean) if _missions.has(mission_id) else 999

static func _recorded_choice(scene_id: String, snapshot: Dictionary) -> Dictionary:
	_index_campaign()
	var scene: Dictionary = _scenes.get(scene_id, {})
	var choice: Dictionary = scene.get("choice", {})
	var choices: Dictionary = snapshot.get("story_log", {}).get("choices", {})
	var entry: Dictionary = choices.get(String(choice.get("id", "")), {})
	var option_id := String(entry.get("option_id", ""))
	if option_id.is_empty() or String(entry.get("scene_id", "")) != scene_id:
		return {}
	for option in choice.get("options", []):
		if String(option.get("id", "")) == option_id:
			return {
				"scene_id": scene_id,
				"prompt": String(choice.get("prompt", "")),
				"choice": String(option.get("label", "")),
				"consequence": String(option.get("consequence", "")),
			}
	return {}
