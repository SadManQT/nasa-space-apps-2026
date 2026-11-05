extends RefCounted
class_name CampaignKnowledge

## Canonical scene IDs identify acquired records; observations use the owning
## operation's existing label. Never copy a scene's future prose into the journal.
##
## journal(snapshot) is the Expedition Journal view model (doc 24 §6, board
## M1-48). It is a pure function of the saved snapshot plus the static text
## packs under resources/campaign/content (journal_text.json, journal_hints.json,
## story_echoes.json, p02_mission_table.json): same snapshot, same journal.
## Every entry it returns belongs to a scene the player has completed, has
## acquired evidence in, or is standing in; names are gated by each entry's
## gate_flag, never by keyword.
const Content = preload("res://scripts/content/content_loader.gd")
const Chapter1 = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const Chapter2 = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const Extended = preload("res://scripts/missions/extended_gate_catalog.gd")
const Plants = preload("res://scripts/biology/plant_service.gd")
const Rooms = preload("res://scripts/world/room_contract.gd")

const JOURNAL_TEXT_PATH := "res://resources/campaign/content/journal_text.json"
const JOURNAL_HINTS_PATH := "res://resources/campaign/content/journal_hints.json"
const STORY_ECHOES_PATH := "res://resources/campaign/content/story_echoes.json"
const P02_TABLE_PATH := "res://resources/campaign/content/p02_mission_table.json"
const JOURNAL_TABS := ["now", "evidence", "garden", "decisions"]
const RESUME_MAX_LINES := 6
const COMPLETED_SHOWN := 3
const STATION_NAME := "Aurora"
## The Growth Record layout is the D2 choice (doc 24 §5.2).
const GROWTH_LAYOUT_CHOICE := "EX-CH01-S04-CHOICE"
## The P-02 gate whose receipt carries the Night One ending (08 P-02).
const NIGHT_ENDING_GATE := {"scene_id": "EX-CH01-S11", "target_id": "p02_shifts6_7"}
## Life-cycle track (doc 24 §3.8): the far end reads "seeds" from 11 April.
const LIFECYCLE_TRACK := [
	{"id": "seed", "label": "seed"},
	{"id": "sprout", "label": "sprout"},
	{"id": "bud", "label": "bud"},
	{"id": "flower", "label": "flower"},
	{"id": "pods", "label": "pods"},
	{"id": "seeds", "label": "ripe seeds"},
]
## Where each PlantService stage sits on the track; "lost" has no marker.
const STAGE_TRACK := {
	"seed": 0, "sprout": 1, "young": 1, "bud": 2, "alive": 2, "bloom": 3, "pollinated": 3,
	"pod_bearing": 4, "mature_pods": 4, "mature_dry": 5, "archived_petal": 5, "archived_nameplate": 5, "naturally_dead": 5,
}
const PLANT_LABELS := {
	"ALO-01": {"name": "Alo", "chamber": "outer test chamber", "side": "outside"},
	"TARA-01": {"name": "Tara", "chamber": "indoor reference bay", "side": "inside"},
	"COTTON-01": {"name": "Cotton", "chamber": "indoor reference bay", "side": "inside"},
}
const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
const STATUS_COLUMNS := {"UNKNOWN": "unknown", "INFERRED": "inferred"}
const LAYOUT_LABELS := {"paired_photographs": "Paired photographs", "paired_conditions": "Paired conditions table"}

static var _content: Dictionary = {}
static var _scene_index: Dictionary = {}
static var _journal_text: Dictionary = {}
static var _journal_hints: Dictionary = {}
static var _story_echoes: Dictionary = {}
static var _p02_table: Dictionary = {}

static func content() -> Dictionary:
	if _content.is_empty():
		_content = Content.load_full()
	return _content

static func grant_operation(next: Dictionary, command: Dictionary) -> Array:
	var scene_id := String(command.get("owning_scene_id", ""))
	var scene := Content.scene_by_id(content(), scene_id)
	if scene.is_empty() or command.get("verb") == "acknowledge_line":
		return []
	var chapter := int(scene.get("chapter_number", 0))
	var targets: Array = Chapter1.targets_for_scene(scene_id) if chapter == 1 else Chapter2.targets_for_scene(scene_id) if chapter == 2 else Extended.targets_for_scene(scene_id)
	var matches := targets.filter(func(target): return target.get("command_id") == command.get("command_id"))
	if matches.is_empty():
		return []
	var target: Dictionary = matches[0]
	var events: Array = []
	if not next.acquired_evidence_ids.has(scene_id):
		next.acquired_evidence_ids.append(scene_id)
		events.append({"type": "evidence_acquired", "evidence_id": scene_id})
	var record := {}
	for item in next.knowledge:
		if item is Dictionary and item.get("id") == scene_id:
			record = item
	if record.is_empty():
		record = {"id": scene_id, "title": scene.title, "evidence_label": scene.evidence_tag, "observations": []}
		next.knowledge.append(record)
	var observation_id := String(target.target_id)
	if not record.observations.any(func(item): return item.id == observation_id):
		var label := String(target.get("focus_label", "Observation recorded"))
		if label.to_lower().contains("noor") and not next.knowledge_flags.has("noor_identity_revealed"):
			label = "Gardener identity evidence recorded."
		record.observations.append({"id": observation_id, "text": label})
	# Revelation belongs to the final physical evidence step, never a caption.
	if target == targets.back():
		for flag in scene.get("knowledge_reveals", []):
			_grant_flag(next, String(flag), events)
	if observation_id == "p16_confirm_path_records":
		_grant_flag(next, "relay_local_verified", events)
		_grant_flag(next, "relay_earth_verified", events)
	return events

static func _grant_flag(next: Dictionary, flag: String, events: Array) -> void:
	if not next.knowledge_flags.has(flag):
		next.knowledge_flags.append(flag)
		events.append({"type": "knowledge_unlocked", "knowledge_flag": flag})

static func line_allowed(line_id: String, flags: Array, scene_id: String) -> bool:
	var line := Content.dialogue_by_id(content(), line_id)
	if line.is_empty() or line.scene_id != scene_id:
		return false
	for required in line.get("knowledge_required", []):
		if not flags.has(required):
			return false
	return true

## The Chapter 1 journal text pack (M1-50), loaded once. Tests may pass their
## own pack to journal() instead.
static func journal_text() -> Dictionary:
	if _journal_text.is_empty():
		_journal_text = _load_json(JOURNAL_TEXT_PATH)
	return _journal_text

static func journal_hints() -> Dictionary:
	if _journal_hints.is_empty():
		_journal_hints = _load_json(JOURNAL_HINTS_PATH)
	return _journal_hints

static func story_echoes() -> Dictionary:
	if _story_echoes.is_empty():
		_story_echoes = _load_json(STORY_ECHOES_PATH)
	return _story_echoes

static func p02_table() -> Dictionary:
	if _p02_table.is_empty():
		_p02_table = _load_json(P02_TABLE_PATH)
	return _p02_table

## Builds the journal from one saved snapshot and the static text packs:
## {"tabs": {"now", "evidence", "garden", "decisions"}, "resume": [lines],
## "entries": [every shown entry], "counts": {tab: n}, "scene_id": ...}.
## Pure: it reads nothing but its arguments and the content files, and never
## mutates the snapshot.
static func journal(snapshot: Dictionary, pack: Dictionary = {}) -> Dictionary:
	var text := pack if not pack.is_empty() else journal_text()
	var ctx := _context(snapshot)
	var shown: Array = []
	var shown_ids := {}
	var order := 0
	for raw in text.get("entries", []):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if String(entry.get("surface", "journal")) != "journal" or not JOURNAL_TABS.has(String(entry.get("tab", ""))):
			continue
		if not _entry_visible(entry, ctx):
			continue
		var view := entry.duplicate(true)
		view["order"] = order
		order += 1
		shown.append(view)
		shown_ids[String(entry.get("id", ""))] = view
	for view in shown:
		_decorate(view, shown_ids, ctx)
	var tabs := {
		"now": _now_tab(text, ctx, shown),
		"evidence": _evidence_tab(ctx, shown),
		"garden": _garden_tab(text, ctx, shown),
		"decisions": _decisions_tab(ctx, shown),
	}
	var entries: Array = []
	var counts := {}
	for tab in JOURNAL_TABS:
		var tab_entries: Array = tabs[tab].get("entries", [])
		counts[tab] = tab_entries.size()
		entries.append_array(tab_entries)
	return {
		"scene_id": ctx.scene_id,
		"chapter_id": ctx.chapter_id,
		"tabs": tabs,
		"resume": _resume_lines(text, ctx, shown, tabs),
		"entries": entries,
		"counts": counts,
	}

## Dates in the packs read "2046-04-11 10:00 UTC", "2046-04-11 UTC" or
## "2046-04-11 late morning UTC"; players read "11 April 2046 · 10:00 UTC".
static func format_date(raw: String) -> String:
	var text := raw.strip_edges()
	if not _looks_like_date(text.substr(0, 10)):
		return text
	var year := int(text.substr(0, 4))
	var month := int(text.substr(5, 2))
	var day := int(text.substr(8, 2))
	if month < 1 or month > 12 or day < 1:
		return text
	var label := "%d %s %d" % [day, MONTHS[month - 1], year]
	var rest := text.substr(10).strip_edges()
	if rest.is_empty():
		return label
	var has_clock := rest.length() >= 5 and rest.substr(2, 1) == ":" and rest.substr(0, 2).is_valid_int()
	if not has_clock:
		rest = rest.trim_suffix("UTC").strip_edges()
	return label if rest.is_empty() else "%s · %s" % [label, rest]

static func _looks_like_date(text: String) -> bool:
	return text.length() == 10 and text.substr(4, 1) == "-" and text.substr(7, 1) == "-" and text.substr(0, 4).is_valid_int() and text.substr(5, 2).is_valid_int() and text.substr(8, 2).is_valid_int()

static func _context(snapshot: Dictionary) -> Dictionary:
	var story_log: Dictionary = snapshot.get("story_log", {}) if snapshot.get("story_log", {}) is Dictionary else {}
	var plants := {}
	for plant in snapshot.get("plants", []):
		if plant is Dictionary:
			plants[String(plant.get("individual_id", ""))] = plant
	var datetime := String(snapshot.get("scenario_datetime", ""))
	return {
		"scene_id": String(snapshot.get("scene_id", "")),
		"chapter_id": String(snapshot.get("chapter_id", "")),
		"completed": snapshot.get("completed_scene_ids", []) if snapshot.get("completed_scene_ids", []) is Array else [],
		"acquired": snapshot.get("acquired_evidence_ids", []) if snapshot.get("acquired_evidence_ids", []) is Array else [],
		"flags": snapshot.get("knowledge_flags", []) if snapshot.get("knowledge_flags", []) is Array else [],
		"receipts": snapshot.get("receipts", {}) if snapshot.get("receipts", {}) is Dictionary else {},
		"knowledge": snapshot.get("knowledge", []) if snapshot.get("knowledge", []) is Array else [],
		"choices": story_log.get("choices", {}) if story_log.get("choices", {}) is Dictionary else {},
		"moments": story_log.get("moments", []) if story_log.get("moments", []) is Array else [],
		"plants": plants,
		"datetime": datetime,
		"date": datetime.substr(0, 10),
		"shift": int(snapshot.get("current_shift", 0)),
		"status": String(snapshot.get("status", "active")),
		"actors": snapshot.get("actors", {}) if snapshot.get("actors", {}) is Dictionary else {},
		"inventories": snapshot.get("inventories", {}) if snapshot.get("inventories", {}) is Dictionary else {},
	}

## A scene the player completed, acquired evidence in, or is standing in.
static func _scene_allowed(scene_id: String, ctx: Dictionary) -> bool:
	return not scene_id.is_empty() and (scene_id == ctx.scene_id or ctx.completed.has(scene_id) or ctx.acquired.has(scene_id))

static func _entry_visible(entry: Dictionary, ctx: Dictionary) -> bool:
	var gate := String(entry.get("gate_flag", ""))
	if not gate.is_empty() and not ctx.flags.has(gate):
		return false
	if not _scene_allowed(String(entry.get("scene_id", "")), ctx):
		return false
	var trigger: Dictionary = entry.get("trigger", {}) if entry.get("trigger", {}) is Dictionary else {}
	match String(trigger.get("on", "")):
		"target":
			var scene_id := String(trigger.get("scene_id", entry.get("scene_id", "")))
			if ctx.completed.has(scene_id):
				return true
			return ctx.receipts.has(_target_command_id(scene_id, String(trigger.get("target_id", ""))))
		"scene_complete":
			return ctx.completed.has(String(trigger.get("scene_id", entry.get("scene_id", ""))))
		"scene_active":
			return String(trigger.get("scene_id", entry.get("scene_id", ""))) == ctx.scene_id
		"choice_confirmed":
			var recorded: Dictionary = ctx.choices.get(String(trigger.get("choice_id", "")), {})
			return recorded is Dictionary and String(recorded.get("option_id", "")) == String(trigger.get("option_id", ""))
		"moment":
			return ctx.moments.has(String(trigger.get("moment_id", "")))
		"photo":
			return _photo_taken(trigger, ctx)
	return false

## A dated growth photo exists once the plant was planted in the story, the
## date has passed and the plant has reached (or passed) that stage.
static func _photo_taken(trigger: Dictionary, ctx: Dictionary) -> bool:
	var plant: Dictionary = ctx.plants.get(String(trigger.get("plant_id", "")), {})
	if plant.is_empty() or not _plant_planted(plant):
		return false
	if ctx.date < String(trigger.get("date", "9999-12-31")):
		return false
	var wanted := int(STAGE_TRACK.get(String(trigger.get("stage", "")), 99))
	var reached := int(STAGE_TRACK.get(String(plant.get("stage", "")), -1))
	if String(plant.get("stage", "")) == "lost":
		reached = Plants.STAGES.size()
	return reached >= wanted

static func _plant_planted(plant: Dictionary) -> bool:
	var history = plant.get("care_history", [])
	return (history is Array and not history.is_empty()) or not PLANT_LABELS.has(String(plant.get("individual_id", "")))

static func _target_command_id(scene_id: String, target_id: String) -> String:
	var chapter := _chapter_of(scene_id)
	var targets: Array = Chapter1.targets_for_scene(scene_id) if chapter == 1 else Chapter2.targets_for_scene(scene_id) if chapter == 2 else Extended.targets_for_scene(scene_id)
	for target in targets:
		if target is Dictionary and String(target.get("target_id", "")) == target_id:
			return String(target.get("command_id", "physical:" + target_id))
	return "physical:" + target_id

static func _chapter_of(scene_id: String) -> int:
	return int(scene_id.substr(5, 2)) if scene_id.begins_with("EX-CH") and scene_id.length() >= 7 else 0

static func _scene_order(scene_id: String) -> int:
	if _scene_index.is_empty():
		var index := 0
		for scene in content().get("scenes", []):
			_scene_index[String(scene.get("id", ""))] = index
			index += 1
	return int(_scene_index.get(scene_id, -1))

static func _scene_title(scene_id: String) -> String:
	return String(Content.scene_by_id(content(), scene_id).get("title", scene_id))

## "Mission EX-M0102" or "EX-M0102" reads as the mission's title.
static func _mission_label(source: String) -> String:
	var mission_id := source.trim_prefix("Mission ").strip_edges()
	var title := String(Content.mission_by_id(content(), mission_id).get("title", ""))
	return "Mission · " + title if not title.is_empty() else source

## Links are shown only to entries already shown; a superseding record is named.
static func _decorate(view: Dictionary, shown_ids: Dictionary, _ctx: Dictionary) -> void:
	var links: Array = []
	for link_id in view.get("links", []):
		if shown_ids.has(String(link_id)) and String(link_id) != String(view.get("id", "")):
			links.append({"id": String(link_id), "title": String(shown_ids[String(link_id)].get("title", link_id))})
	view["links"] = links
	var superseded := String(view.get("superseded_by", ""))
	view["updated"] = not superseded.is_empty() and shown_ids.has(superseded)
	view["superseded_title"] = String(shown_ids[superseded].get("title", "")) if view["updated"] else ""
	view["date_label"] = format_date(String(view.get("date", "")))
	view["scene_title"] = _scene_title(String(view.get("scene_id", "")))
	view["scene_order"] = _scene_order(String(view.get("scene_id", "")))

static func _newest_first(a: Dictionary, b: Dictionary) -> bool:
	if int(a.scene_order) != int(b.scene_order):
		return int(a.scene_order) > int(b.scene_order)
	return int(a.order) < int(b.order)

static func _oldest_first(a: Dictionary, b: Dictionary) -> bool:
	if int(a.scene_order) != int(b.scene_order):
		return int(a.scene_order) < int(b.scene_order)
	return int(a.order) < int(b.order)

static func _now_entry(text: Dictionary, scene_id: String) -> Dictionary:
	for entry in text.get("entries", []):
		if entry is Dictionary and String(entry.get("type", "")) == "objective" and String(entry.get("scene_id", "")) == scene_id:
			return entry
	return {}

static func _now_tab(text: Dictionary, ctx: Dictionary, shown: Array) -> Dictionary:
	var entries: Array = shown.filter(func(view): return String(view.get("tab", "")) == "now")
	var objective := {}
	var current := _now_entry(text, ctx.scene_id)
	if not current.is_empty():
		var objective_text := String(current.get("objective_text", current.get("body", "")))
		objective = {
			"scene_id": ctx.scene_id,
			"scene_title": String(current.get("title", _scene_title(ctx.scene_id))),
			"objective_text": objective_text,
			"why": String(current.get("body", "")).trim_prefix(objective_text).strip_edges(),
			"mission": _mission_label(String(current.get("source", ""))),
			"date_label": format_date(String(current.get("date", ""))),
			"state": "complete" if ctx.completed.has(ctx.scene_id) else "active",
		}
	elif not ctx.scene_id.is_empty():
		var scene := Content.scene_by_id(content(), ctx.scene_id)
		objective = {
			"scene_id": ctx.scene_id,
			"scene_title": String(scene.get("title", ctx.scene_id)),
			"objective_text": " ".join(scene.get("player_actions", [])),
			"why": "",
			"mission": _mission_label(String(scene.get("mission_id", ""))),
			"date_label": format_date(String(scene.get("story_time", ""))),
			"state": "complete" if ctx.completed.has(ctx.scene_id) else "active",
		}
	var completed: Array = []
	var completed_ids: Array = ctx.completed.duplicate()
	completed_ids.reverse()
	for scene_id in completed_ids:
		if completed.size() >= COMPLETED_SHOWN:
			break
		var entry := _now_entry(text, String(scene_id))
		if entry.is_empty():
			continue
		completed.append({
			"scene_id": String(scene_id),
			"scene_title": String(entry.get("title", "")),
			"completed_text": String(entry.get("completed_text", "")),
			"date_label": format_date(String(entry.get("date", ""))),
		})
	return {"objective": objective, "completed": completed, "hints": hints_for_scene(ctx.scene_id), "entries": entries}

## The What now? ladder for one scene: {"scene_id", "source", "levels": [H1, H2, H3],
## "level_labels": [...]}. Authored text comes from journal_hints.json (08 and 22
## quoted word for word); other scenes fall back to their mission-card steps.
static func hints_for_scene(scene_id: String) -> Dictionary:
	var data := journal_hints()
	var labels: Array = []
	for level in data.get("levels", []):
		labels.append(level if level is Dictionary else {"id": str(level), "label": ""})
	var authored: Dictionary = data.get("scenes", {}).get(scene_id, {})
	var levels: Array = []
	var source := String(authored.get("source", ""))
	if String(authored.get("from", "")) == "p02_mission_table":
		for hint in p02_table().get("hints", []):
			levels.append(String(hint))
	elif authored.has("hints"):
		for hint in authored.get("hints", []):
			levels.append(String(hint))
	else:
		var fallback: Dictionary = data.get("fallback", {})
		source = String(fallback.get("source", "Mission card steps"))
		var scene := Content.scene_by_id(content(), scene_id)
		for action in scene.get("player_actions", []):
			if levels.size() < 3:
				levels.append(String(action))
		var exit_condition := String(scene.get("exit_condition", ""))
		if levels.size() < 3 and not exit_condition.is_empty():
			levels.append(exit_condition)
	return {"scene_id": scene_id, "source": source, "levels": levels, "level_labels": labels}

static func _evidence_tab(ctx: Dictionary, shown: Array) -> Dictionary:
	var entries: Array = shown.filter(func(view): return String(view.get("tab", "")) == "evidence")
	var covered := {}
	for view in entries:
		covered[String(view.get("scene_id", ""))] = true
	# Scenes without written entries (later chapters) keep their operation records.
	var order := 100000
	for record in ctx.knowledge:
		if not record is Dictionary:
			continue
		var scene_id := String(record.get("id", ""))
		if covered.has(scene_id) or not ctx.acquired.has(scene_id) or not _scene_allowed(scene_id, ctx):
			continue
		var lines: Array = []
		for observation in record.get("observations", []):
			if observation is Dictionary:
				lines.append(String(observation.get("text", "")))
		var scene := Content.scene_by_id(content(), scene_id)
		var view := {
			"id": "REC-" + scene_id, "tab": "evidence", "type": "record", "status": "OBSERVED",
			"title": String(record.get("title", scene_id)), "body": "\n".join(lines),
			"date": String(scene.get("story_time", "")), "date_label": format_date(String(scene.get("story_time", ""))),
			"scene_id": scene_id, "scene_title": String(scene.get("title", scene_id)), "scene_order": _scene_order(scene_id),
			"source": "Operation record", "evidence_label": String(record.get("evidence_label", "")),
			"links": [], "gate_flag": "", "superseded_by": "", "updated": false, "superseded_title": "", "order": order,
		}
		order += 1
		entries.append(view)
	entries.sort_custom(_newest_first)
	var columns := {"observed": [], "inferred": [], "unknown": []}
	for view in entries:
		columns[String(STATUS_COLUMNS.get(String(view.get("status", "")), "observed"))].append(view)
	return {"columns": columns, "entries": entries}

static func _growth_templates(text: Dictionary) -> Array:
	var templates: Array = []
	for entry in text.get("entries", []):
		if entry is Dictionary and String(entry.get("type", "")) == "growth_template":
			templates.append(entry)
	return templates

static func _garden_tab(text: Dictionary, ctx: Dictionary, shown: Array) -> Dictionary:
	var entries: Array = shown.filter(func(view): return String(view.get("tab", "")) == "garden")
	entries.sort_custom(_oldest_first)
	var templates := _growth_templates(text)
	var layouts: Array = []
	var lifecycle_template := {}
	for template in templates:
		var layout_id := String(template.get("layout_id", ""))
		if layout_id == "lifecycle_track":
			lifecycle_template = template
		elif not layout_id.is_empty():
			layouts.append({"id": layout_id, "label": String(LAYOUT_LABELS.get(layout_id, layout_id.replace("_", " ").capitalize())), "option_id": String(template.get("option_id", ""))})
	var chosen_option := String(ctx.choices.get(GROWTH_LAYOUT_CHOICE, {}).get("option_id", ""))
	var layout := String(layouts[0].id) if not layouts.is_empty() else "paired_photographs"
	for candidate in layouts:
		if not chosen_option.is_empty() and String(candidate.option_id) == chosen_option:
			layout = String(candidate.id)
	var stage_labels: Dictionary = lifecycle_template.get("placeholders", {}).get("stage_label", {})
	var plants: Array = []
	var markers := {}
	for plant_id in ctx.plants:
		var plant: Dictionary = ctx.plants[plant_id]
		if not _plant_planted(plant):
			continue
		var labels: Dictionary = PLANT_LABELS.get(plant_id, {"name": plant_id, "chamber": String(plant.get("enclosure", "")).replace("_", " "), "side": "inside"})
		var stage := String(plant.get("stage", ""))
		var stage_label := String(stage_labels.get(stage, stage.replace("_", " ")))
		var track := int(STAGE_TRACK.get(stage, -1))
		var caption := String(lifecycle_template.get("body", "{plant_name} is now in the {stage_label} phase.")).replace("{plant_name}", String(labels.name)).replace("{stage_label}", stage_label)
		plants.append({
			"id": plant_id, "name": String(labels.name), "chamber": String(labels.chamber), "side": String(labels.side),
			"stage": stage, "stage_label": stage_label, "alive": bool(plant.get("alive", true)), "track_index": track, "caption": caption,
		})
		if track >= 0:
			markers[plant_id] = track
	plants.sort_custom(func(a, b): return String(a.id) < String(b.id))
	var records: Array = []
	var by_date := {}
	for view in entries:
		if String(view.get("type", "")) != "growth_photo":
			continue
		var key := String(view.get("date", "")).substr(0, 10)
		if not by_date.has(key):
			by_date[key] = {"date": key, "date_label": format_date(key), "frames": {}}
			records.append(by_date[key])
		by_date[key].frames[String(view.get("plant_id", ""))] = view
	var ledger: Array = []
	var founders: Dictionary = ctx.inventories.get("founder_seed42", {}) if ctx.inventories.get("founder_seed42", {}) is Dictionary else {}
	if int(founders.get("total", 0)) > 0:
		ledger.append("Founder seeds: %d = %d planted + %d sealed." % [int(founders.get("total", 0)), int(founders.get("allocated", 0)), int(founders.get("reserve", 0))])
	return {
		"layout": layout, "layouts": layouts, "layout_chosen": not chosen_option.is_empty(),
		"plants": plants, "records": records,
		"lifecycle": {"stages": LIFECYCLE_TRACK, "markers": markers},
		"ledger": ledger, "entries": entries,
	}

static func _decisions_tab(ctx: Dictionary, shown: Array) -> Dictionary:
	var entries: Array = shown.filter(func(view): return String(view.get("tab", "")) == "decisions")
	var echo_table: Dictionary = story_echoes().get("choices", {}) if story_echoes().get("choices", {}) is Dictionary else {}
	for view in entries:
		var choice_id := String(view.get("choice_id", ""))
		var option_id := String(view.get("option_id", ""))
		var recorded: Dictionary = ctx.choices.get(choice_id, {}) if ctx.choices.get(choice_id, {}) is Dictionary else {}
		var scene := Content.scene_by_id(content(), String(view.get("scene_id", "")))
		var choice: Dictionary = scene.get("choice", {}) if scene.get("choice", {}) is Dictionary else {}
		view["prompt"] = String(choice.get("prompt", ""))
		view["chose"] = ""
		view["did"] = ""
		for option in choice.get("options", []):
			if option is Dictionary and String(option.get("id", "")) == option_id:
				view["chose"] = String(option.get("label", option_id))
				view["did"] = String(option.get("consequence", ""))
		view["recorded"] = String(recorded.get("scenario_datetime", ""))
		view["recorded_label"] = format_date(view["recorded"])
		view["revision"] = int(recorded.get("state_revision", 0))
		var echoes: Array = []
		for echo in echo_table.get(choice_id, {}).get(option_id, []):
			if echo is Dictionary and _scene_allowed(String(echo.get("scene_id", "")), ctx):
				echoes.append({"id": String(echo.get("id", "")), "scene_id": String(echo.get("scene_id", "")), "scene_title": _scene_title(String(echo.get("scene_id", ""))), "text": String(echo.get("text", echo.get("body", "")))})
		view["echoes"] = echoes
	entries.sort_custom(func(a, b): return int(a.revision) < int(b.revision) if int(a.revision) != int(b.revision) else _oldest_first(a, b))
	var outcome := {}
	var gate := _target_command_id(String(NIGHT_ENDING_GATE.scene_id), String(NIGHT_ENDING_GATE.target_id))
	if ctx.receipts.has(gate) and ctx.receipts[gate] is Dictionary:
		var ending := String(ctx.receipts[gate].get("ending", ""))
		var endings: Dictionary = p02_table().get("endings", {})
		if not ending.is_empty() and endings.has(ending):
			var dated := ""
			for raw in journal_text().get("entries", []):
				if raw is Dictionary and String(raw.get("trigger", {}).get("target_id", "")) == String(NIGHT_ENDING_GATE.target_id):
					dated = String(raw.get("date", ""))
			outcome = {
				"ending": ending,
				"title": String(endings[ending].get("title", ending)),
				"summary": String(endings[ending].get("summary", "")),
				"scene_id": String(NIGHT_ENDING_GATE.scene_id),
				"date_label": format_date(dated if not dated.is_empty() else String(ctx.datetime)),
			}
	return {"entries": entries, "outcome": outcome}

## "Previously at Aurora" (doc 24 §6.6): at most six lines from the saved
## snapshot only. A line whose facts are missing is left out, never invented.
static func _resume_lines(text: Dictionary, ctx: Dictionary, shown: Array, tabs: Dictionary) -> Array:
	var templates: Array = []
	for entry in text.get("entries", []):
		if entry is Dictionary and String(entry.get("type", "")) == "resume_template":
			templates.append(entry)
	templates.sort_custom(func(a, b): return int(a.get("line_slot", 0)) < int(b.get("line_slot", 0)))
	var lines: Array = []
	for template in templates:
		if lines.size() >= RESUME_MAX_LINES:
			break
		var values := _resume_values(String(template.get("slot_name", "")), template, ctx, shown, tabs)
		if values.is_empty():
			continue
		var body := String(template.get("body", ""))
		var complete := true
		for key in values:
			body = body.replace("{%s}" % key, String(values[key]))
		if body.contains("{") and body.contains("}"):
			complete = false
		if complete and not body.strip_edges().is_empty():
			lines.append(body)
	return lines

static func _resume_values(slot: String, template: Dictionary, ctx: Dictionary, shown: Array, tabs: Dictionary) -> Dictionary:
	match slot:
		"where_and_when":
			if ctx.datetime.length() < 10:
				return {}
			var room_id := Rooms.room_for_scene(ctx.scene_id)
			var room_name := String(Rooms.room(room_id).get("name", "")) if not room_id.is_empty() else ""
			return {
				"location": STATION_NAME if room_name.is_empty() else "%s · %s" % [STATION_NAME, room_name],
				"scenario_date": format_date(ctx.date),
				"shift_label": _shift_label(ctx),
			}
		"who_is_where":
			return _crew_split(ctx)
		"last_completed":
			var completed: Array = tabs.now.get("completed", [])
			if completed.is_empty() or String(completed[0].get("completed_text", "")).is_empty():
				return {}
			return {"last_completed_text": String(completed[0].completed_text)}
		"current_objective":
			var objective: Dictionary = tabs.now.get("objective", {})
			if objective.is_empty():
				return {}
			if String(objective.get("state", "")) == "complete":
				return {"current_objective": "%s is complete. Advance when the next chapter is ready." % String(objective.get("scene_title", "This scene"))}
			return {"current_objective": String(objective.get("objective_text", ""))}
		"garden_state":
			var phrases: Dictionary = template.get("placeholders", {}).get("stage_phrase", {})
			var alo: Dictionary = ctx.plants.get("ALO-01", {})
			var tara: Dictionary = ctx.plants.get("TARA-01", {})
			if alo.is_empty() or tara.is_empty() or not _plant_planted(alo) or not _plant_planted(tara):
				return {}
			return {"alo_stage_phrase": _stage_phrase(alo, phrases), "tara_stage_phrase": _stage_phrase(tara, phrases)}
		"open_question":
			var questions: Array = tabs.evidence.get("columns", {}).get("unknown", [])
			for view in questions:
				if String(view.get("type", "")) == "question" and not bool(view.get("updated", false)):
					return {"open_question": String(view.get("title", ""))}
			return {}
	return {}

static func _stage_phrase(plant: Dictionary, phrases: Dictionary) -> String:
	var stage := String(plant.get("stage", ""))
	return String(phrases.get(stage, stage.replace("_", " ")))

## The P-02 night (Chapter 1) names its shifts from the table data; every
## other moment reads the clock.
static func _shift_label(ctx: Dictionary) -> String:
	var shift := int(ctx.shift)
	if shift <= 0 or _chapter_of(String(ctx.scene_id)) != 1:
		var clock := String(ctx.datetime).substr(10).strip_edges()
		return clock if not clock.is_empty() else "shift 0"
	if ctx.status == "complete":
		return "dawn after shift %d" % shift
	var day_shifts: Array = p02_table().get("day_shifts", [1, 2])
	return ("daylight shift %d" if day_shifts.has(shift) else "dark shift %d") % shift

static func _crew_split(ctx: Dictionary) -> Dictionary:
	var home: Array = []
	var away: Array = []
	var away_location := ""
	for actor_id in ctx.actors:
		var actor: Dictionary = ctx.actors[actor_id] if ctx.actors[actor_id] is Dictionary else {}
		var name := String(actor_id).capitalize()
		if String(actor.get("team_id", "base")) == "base":
			home.append(name)
		else:
			away.append(name)
			away_location = String(Rooms.room(String(actor.get("physical_location_id", ""))).get("name", String(actor.get("physical_location_id", "away"))))
	if away.is_empty() or home.is_empty():
		return {}
	return {"away_team": _join_names(away), "away_location": away_location, "home_team": _join_names(home)}

static func _join_names(names: Array) -> String:
	if names.size() <= 1:
		return "" if names.is_empty() else String(names[0])
	return "%s and %s" % [", ".join(names.slice(0, names.size() - 1)), String(names[names.size() - 1])]

static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Journal content missing: " + path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
