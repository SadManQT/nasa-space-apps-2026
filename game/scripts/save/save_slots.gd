extends RefCounted
class_name SaveSlots

## M3-71: Three manual save slots (slot_1, slot_2, slot_3) plus the automatic
## checkpoint slot (autosave) at every scene join and mission end.
## Wraps SaveService so every write uses a validated temporary file + atomic
## rename and one verified backup (.bak), preserves forward migrations from
## schema 1/2/3 (keeping story_log schema 3 readable), detects corrupt primary
## files while offering backup recovery without silent destruction, and exposes
## a strictly read-only save metadata API for menus (chapter, story_date,
## play_time, thumbnail_path).

const SaveScript = preload("res://scripts/save/save_service.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const AchievementsScript = preload("res://scripts/ui/achievements.gd")

const AUTOSAVE_SLOT := "autosave"
const MANUAL_SLOTS := ["slot_1", "slot_2", "slot_3"]
const ALL_SLOTS := ["autosave", "slot_1", "slot_2", "slot_3"]
const SLOT_META_KEY := "slot_metadata"
const SLOT_META_VERSION := 1

const SLOT_LABELS := {
	"autosave": "Autosave Checkpoint",
	"slot_1": "Manual Slot 1",
	"slot_2": "Manual Slot 2",
	"slot_3": "Manual Slot 3",
}

const CHAPTER_THUMBNAILS := {
	1: "res://assets/ui/screens/EN_EarthDesk.png",
	2: "res://assets/ui/portraits/CH_Noor_live.png",
	3: "res://assets/ui/screens/EN_EarthDesk_archive.png",
	4: "res://assets/ui/portraits/CH_Ferreira_screen.png",
	5: "res://assets/ui/screens/EN_NoorRooftop.png",
	6: "res://assets/ui/portraits/CH_Rao_screen.png",
	7: "res://assets/ui/portraits/CH_Noor_2034_portrait.png",
	8: "res://assets/ui/screens/EN_NoorRooftop_noon.png",
}

var base_save_path: String = SaveScript.DEFAULT_PATH
var session_validator: Callable = Callable()
var _service: RefCounted
static var _catalog: Dictionary = {}

func _init(save_path: String = SaveScript.DEFAULT_PATH, validator: Callable = Callable()) -> void:
	base_save_path = save_path if not save_path.is_empty() else SaveScript.DEFAULT_PATH
	session_validator = validator
	_service = SaveScript.new()
	_service.session_validator = session_validator

func service() -> RefCounted:
	_service.session_validator = session_validator
	return _service

static func valid_slot_id(slot_id: String) -> bool:
	return ALL_SLOTS.has(slot_id)

static func slot_label(slot_id: String) -> String:
	return String(SLOT_LABELS.get(slot_id, slot_id.capitalize()))

func slot_path(slot_id: String) -> String:
	if slot_id == AUTOSAVE_SLOT or slot_id.is_empty():
		return base_save_path
	var dir := base_save_path.get_base_dir()
	var prefix := base_save_path.get_file().get_basename()
	if prefix.is_empty():
		prefix = "last_light_expedition_v2"
	return dir.path_join("%s_%s.json" % [prefix, slot_id])

## Saves a snapshot to a named slot ("autosave", "slot_1", "slot_2", "slot_3")
## using SaveService's atomic temp-then-rename and one-backup contract.
func save_slot(slot_id: String, snapshot: Dictionary, trigger: String = "manual", extra_meta: Dictionary = {}) -> Dictionary:
	if not valid_slot_id(slot_id):
		return {"accepted": false, "slot_id": slot_id, "reason": "Unknown save slot: " + slot_id}
	var path := slot_path(slot_id)
	var prepared := _prepare_slot_snapshot(snapshot, slot_id, trigger, extra_meta, path)
	var result: Dictionary = service().save(prepared, path)
	result["slot_id"] = slot_id
	result["trigger"] = trigger
	if bool(result.get("accepted", false)):
		result["metadata"] = extract_metadata(result.get("snapshot", prepared), slot_id, path)
	return result

## Autosaves at every scene join ("scene_join") or mission end ("mission_end").
func autosave_scene_join(snapshot: Dictionary, scene_id: String = "", play_time_seconds: float = -1.0) -> Dictionary:
	var extra := {"scene_id": scene_id}
	if play_time_seconds >= 0.0:
		extra["play_time_seconds"] = play_time_seconds
	return save_slot(AUTOSAVE_SLOT, snapshot, "scene_join", extra)

func autosave_mission_end(snapshot: Dictionary, mission_id: String = "", play_time_seconds: float = -1.0) -> Dictionary:
	var extra := {"mission_id": mission_id}
	if play_time_seconds >= 0.0:
		extra["play_time_seconds"] = play_time_seconds
	return save_slot(AUTOSAVE_SLOT, snapshot, "mission_end", extra)

## Loads a slot. When `allow_auto_recover` is false and the primary file is
## corrupt while a valid backup exists, returns `corrupt_primary_backup_offered`
## so the UI can explicitly offer backup recovery to the player.
func load_slot(slot_id: String, allow_auto_recover: bool = true) -> Dictionary:
	if not valid_slot_id(slot_id):
		return {"accepted": false, "slot_id": slot_id, "reason": "Unknown save slot: " + slot_id}
	var path := slot_path(slot_id)
	if not allow_auto_recover:
		var info := inspect_slot(slot_id)
		if bool(info.get("corrupt", false)):
			return {
				"accepted": false,
				"slot_id": slot_id,
				"path": path,
				"corrupt": true,
				"backup_available": bool(info.get("backup_available", false)),
				"reason": "corrupt_primary_backup_offered" if bool(info.get("backup_available", false)) else "save_corrupt_no_valid_backup",
				"metadata": info,
			}
	var loaded: Dictionary = service().load(path)
	loaded["slot_id"] = slot_id
	if bool(loaded.get("accepted", false)) and loaded.get("snapshot") is Dictionary:
		var snap := _upgrade_slot_metadata(loaded["snapshot"] as Dictionary, slot_id)
		loaded["snapshot"] = snap
		loaded["metadata"] = extract_metadata(snap, slot_id, path, bool(loaded.get("recovered", false)), bool(loaded.get("migrated", false)))
	return loaded

## Explicitly recovers a corrupt slot from its verified .bak file and repairs the primary.
func recover_slot_from_backup(slot_id: String) -> Dictionary:
	if not valid_slot_id(slot_id):
		return {"accepted": false, "slot_id": slot_id, "reason": "Unknown save slot: " + slot_id}
	var path := slot_path(slot_id)
	var recovered: Dictionary = service().load(path)
	recovered["slot_id"] = slot_id
	if bool(recovered.get("accepted", false)) and recovered.get("snapshot") is Dictionary:
		var snap := _upgrade_slot_metadata(recovered["snapshot"] as Dictionary, slot_id)
		recovered["snapshot"] = snap
		recovered["metadata"] = extract_metadata(snap, slot_id, path, bool(recovered.get("recovered", false)), bool(recovered.get("migrated", false)))
	return recovered

## Copies a valid save from one slot to another (e.g. copying Autosave to Manual Slot 1).
func copy_slot(from_slot_id: String, to_slot_id: String) -> Dictionary:
	var loaded := load_slot(from_slot_id, true)
	if not bool(loaded.get("accepted", false)):
		return {"accepted": false, "from_slot": from_slot_id, "to_slot": to_slot_id, "reason": String(loaded.get("reason", "Source slot is empty or unreadable."))}
	return save_slot(to_slot_id, loaded["snapshot"], "manual_copy")

func clear_slot(slot_id: String) -> bool:
	if not valid_slot_id(slot_id):
		return false
	return service().clear(slot_path(slot_id))

func clear_all() -> bool:
	var ok := true
	for slot_id in ALL_SLOTS:
		ok = clear_slot(slot_id) and ok
	return ok

## Strictly read-only inspection of all 4 slots (autosave + slot_1..slot_3).
## Never writes, repairs, or mutates any file on disk.
func all_slot_metadata() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for slot_id in ALL_SLOTS:
		rows.append(inspect_slot(slot_id))
	return rows

## Strictly read-only inspection of one named slot.
func inspect_slot(slot_id: String) -> Dictionary:
	if not valid_slot_id(slot_id):
		return _empty_metadata(slot_id, "")
	var path := slot_path(slot_id)
	return inspect_path(path, slot_id)

## Strictly read-only inspection of any save file path (and its .bak).
func inspect_path(path: String, slot_id: String = AUTOSAVE_SLOT) -> Dictionary:
	var resolved_slot := slot_id if not slot_id.is_empty() else AUTOSAVE_SLOT
	var primary_exists := FileAccess.file_exists(path)
	var backup_path := path + ".bak"
	var backup_exists := FileAccess.file_exists(backup_path)
	var primary := _inspect_candidate_readonly(path)
	var backup := _inspect_candidate_readonly(backup_path)
	var primary_ok := bool(primary.get("accepted", false))
	var backup_ok := bool(backup.get("accepted", false))
	if primary_ok:
		var snap: Dictionary = _upgrade_slot_metadata(primary["snapshot"], resolved_slot)
		var meta := extract_metadata(snap, resolved_slot, path, false, bool(primary.get("migrated", false)))
		meta["from_schema"] = int(primary.get("from_schema", SaveScript.SCHEMA_VERSION))
		meta["to_schema"] = int(primary.get("to_schema", SaveScript.SCHEMA_VERSION))
		meta["backup_available"] = backup_ok
		meta["corrupt"] = false
		return meta
	if primary_exists or backup_exists:
		var meta := _empty_metadata(resolved_slot, path)
		meta["exists"] = true
		meta["empty"] = false
		meta["corrupt"] = true
		meta["valid"] = false
		meta["backup_available"] = backup_ok
		meta["primary_reason"] = String(primary.get("reason", "missing" if not primary_exists else "corrupt"))
		if backup_ok:
			var backup_snap: Dictionary = _upgrade_slot_metadata(backup["snapshot"], resolved_slot)
			var backup_meta := extract_metadata(backup_snap, resolved_slot, backup_path, true, bool(backup.get("migrated", false)))
			meta["backup_metadata"] = backup_meta
			meta["chapter"] = backup_meta["chapter"]
			meta["chapter_id"] = backup_meta["chapter_id"]
			meta["chapter_title"] = backup_meta["chapter_title"]
			meta["mission_id"] = backup_meta["mission_id"]
			meta["mission_title"] = backup_meta["mission_title"]
			meta["scene_id"] = backup_meta["scene_id"]
			meta["scene_title"] = backup_meta["scene_title"]
			meta["story_date"] = backup_meta["story_date"]
			meta["play_time_seconds"] = backup_meta["play_time_seconds"]
			meta["play_time"] = backup_meta["play_time"]
			meta["thumbnail_path"] = backup_meta["thumbnail_path"]
			meta["status_label"] = "Primary file is damaged · Verified backup ready to restore"
		else:
			meta["status_label"] = "Saved file is damaged and no verified backup is available"
		return meta
	return _empty_metadata(resolved_slot, path)

## Returns the most recent or primary active slot metadata for Continue on the title screen.
func continue_candidate() -> Dictionary:
	for slot_id in ALL_SLOTS:
		var info := inspect_slot(slot_id)
		if bool(info.get("valid", false)) or (bool(info.get("corrupt", false)) and bool(info.get("backup_available", false))):
			return info
	return inspect_slot(AUTOSAVE_SLOT)

## Pure read-only metadata extractor from a validated or migrated snapshot.
static func extract_metadata(snapshot: Dictionary, slot_id: String = AUTOSAVE_SLOT, path: String = "", recovered: bool = false, migrated: bool = false) -> Dictionary:
	var chapter_num := AchievementsScript.chapter_number(snapshot)
	var chapter_id := "CH%02d" % chapter_num
	var scene_id := String(snapshot.get("scene_id", "EX-CH01-S01"))
	var mission_id := String(snapshot.get("mission_id", "EX-M0101"))
	var story_date := String(snapshot.get("scenario_datetime", "2046-04-25 00:00 UTC"))
	var resume: Dictionary = snapshot.get("presentation_resume", {}) if snapshot.get("presentation_resume") is Dictionary else {}
	var stored_meta: Dictionary = resume.get(SLOT_META_KEY, {}) if resume.get(SLOT_META_KEY) is Dictionary else {}
	var play_seconds := float(stored_meta.get("play_time_seconds", _estimate_play_time_seconds(snapshot)))
	var thumb := String(stored_meta.get("thumbnail_path", ""))
	if thumb.is_empty() or not ResourceLoader.exists(thumb):
		thumb = thumbnail_for_chapter(chapter_num)
	var ch_title := _chapter_title(chapter_num)
	var m_title := _mission_title(mission_id)
	var sc_title := _scene_title(scene_id)
	var trigger := String(stored_meta.get("trigger", "autosave" if slot_id == AUTOSAVE_SLOT else "manual"))
	var saved_at := String(stored_meta.get("saved_at_utc", story_date))
	return {
		"slot_id": slot_id,
		"slot_label": slot_label(slot_id),
		"path": path,
		"exists": true,
		"empty": false,
		"valid": true,
		"corrupt": false,
		"recovered": recovered,
		"migrated": migrated,
		"backup_available": not path.is_empty() and FileAccess.file_exists(path + ".bak"),
		"schema_version": int(snapshot.get("schema_version", SaveScript.SCHEMA_VERSION)),
		"slot_meta_version": int(stored_meta.get("version", SLOT_META_VERSION)),
		"chapter": chapter_num,
		"chapter_id": chapter_id,
		"chapter_title": ch_title,
		"mission_id": mission_id,
		"mission_title": m_title,
		"scene_id": scene_id,
		"scene_title": sc_title,
		"story_date": story_date,
		"scenario_datetime": story_date,
		"play_time_seconds": int(round(maxf(0.0, play_seconds))),
		"play_time": format_play_time(play_seconds),
		"thumbnail_path": thumb,
		"trigger": trigger,
		"saved_at_utc": saved_at,
		"completed_scenes": (snapshot.get("completed_scene_ids", []) as Array).size() if snapshot.get("completed_scene_ids") is Array else 0,
		"achievements_unlocked": AchievementsScript.unlocked_count(snapshot),
		"status_label": "Recovered from backup" if recovered else ("Autosaved checkpoint" if slot_id == AUTOSAVE_SLOT else "Saved expedition"),
	}

static func thumbnail_for_chapter(chapter_num: int) -> String:
	var candidate := String(CHAPTER_THUMBNAILS.get(clampi(chapter_num, 1, 8), CHAPTER_THUMBNAILS[1]))
	return candidate if ResourceLoader.exists(candidate) else "res://assets/ui/screens/EN_EarthDesk.png"

static func format_play_time(seconds: float) -> String:
	var total := maxi(0, int(round(seconds)))
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var secs := total % 60
	if hours > 0:
		return "%dh %02dm" % [hours, minutes]
	if minutes > 0:
		return "%dm %02ds" % [minutes, secs]
	return "%ds" % secs

## Enriches a snapshot with `presentation_resume.slot_metadata` without writing to disk.
func enrich_snapshot(snapshot: Dictionary, slot_id: String = AUTOSAVE_SLOT, trigger: String = "checkpoint", play_time_seconds: float = -1.0) -> Dictionary:
	var extra := {}
	if play_time_seconds >= 0.0:
		extra["play_time_seconds"] = play_time_seconds
	return _prepare_slot_snapshot(snapshot, slot_id, trigger, extra, slot_path(slot_id))

func _prepare_slot_snapshot(snapshot: Dictionary, slot_id: String, trigger: String, extra_meta: Dictionary, path: String) -> Dictionary:
	var copy := snapshot.duplicate(true)
	var resume: Dictionary = copy.get("presentation_resume", {}).duplicate(true) if copy.get("presentation_resume") is Dictionary else {}
	var prev_meta: Dictionary = resume.get(SLOT_META_KEY, {}).duplicate(true) if resume.get(SLOT_META_KEY) is Dictionary else {}
	if prev_meta.is_empty() and FileAccess.file_exists(path):
		var existing := _inspect_candidate_readonly(path)
		if bool(existing.get("accepted", false)):
			var old_resume: Dictionary = existing["snapshot"].get("presentation_resume", {}) if existing["snapshot"].get("presentation_resume") is Dictionary else {}
			if old_resume.get(SLOT_META_KEY) is Dictionary:
				prev_meta = (old_resume.get(SLOT_META_KEY) as Dictionary).duplicate(true)
	var ch_num := AchievementsScript.chapter_number(copy)
	var play_seconds := float(extra_meta.get("play_time_seconds", prev_meta.get("play_time_seconds", _estimate_play_time_seconds(copy))))
	var thumb := String(extra_meta.get("thumbnail_path", prev_meta.get("thumbnail_path", thumbnail_for_chapter(ch_num))))
	if thumb.is_empty() or not ResourceLoader.exists(thumb):
		thumb = thumbnail_for_chapter(ch_num)
	var story_date := String(copy.get("scenario_datetime", "2046-04-25 00:00 UTC"))
	var meta_record := {
		"version": SLOT_META_VERSION,
		"slot_id": slot_id,
		"trigger": trigger,
		"chapter": ch_num,
		"story_date": story_date,
		"play_time_seconds": int(round(maxf(0.0, play_seconds))),
		"thumbnail_path": thumb,
		"saved_at_utc": String(extra_meta.get("saved_at_utc", Time.get_datetime_string_from_system(true, true) + " UTC")),
	}
	if extra_meta.has("scene_id") and not String(extra_meta.scene_id).is_empty():
		meta_record["trigger_scene_id"] = String(extra_meta.scene_id)
	if extra_meta.has("mission_id") and not String(extra_meta.mission_id).is_empty():
		meta_record["trigger_mission_id"] = String(extra_meta.mission_id)
	resume[SLOT_META_KEY] = meta_record
	copy["presentation_resume"] = resume
	return copy

## Upgrades an older schema 1/2/3 save without `presentation_resume.slot_metadata`
## so its slot metadata (chapter, story_date, play_time, thumbnail_path) is always populated,
## while keeping `story_log` and all schema 3 fields intact.
static func _upgrade_slot_metadata(snapshot: Dictionary, slot_id: String = AUTOSAVE_SLOT) -> Dictionary:
	var copy := snapshot.duplicate(true)
	var resume: Dictionary = copy.get("presentation_resume", {}).duplicate(true) if copy.get("presentation_resume") is Dictionary else {}
	var existing: Dictionary = resume.get(SLOT_META_KEY, {}).duplicate(true) if resume.get(SLOT_META_KEY) is Dictionary else {}
	var ch_num := AchievementsScript.chapter_number(copy)
	var story_date := String(copy.get("scenario_datetime", "2046-04-25 00:00 UTC"))
	var play_seconds := float(existing.get("play_time_seconds", _estimate_play_time_seconds(copy)))
	var thumb := String(existing.get("thumbnail_path", thumbnail_for_chapter(ch_num)))
	if thumb.is_empty() or not ResourceLoader.exists(thumb):
		thumb = thumbnail_for_chapter(ch_num)
	existing["version"] = int(existing.get("version", SLOT_META_VERSION))
	existing["slot_id"] = String(existing.get("slot_id", slot_id))
	existing["trigger"] = String(existing.get("trigger", "migrated_schema3" if not resume.has(SLOT_META_KEY) else "manual"))
	existing["chapter"] = ch_num
	existing["story_date"] = story_date
	existing["play_time_seconds"] = int(round(maxf(0.0, play_seconds)))
	existing["thumbnail_path"] = thumb
	existing["saved_at_utc"] = String(existing.get("saved_at_utc", story_date))
	resume[SLOT_META_KEY] = existing
	copy["presentation_resume"] = resume
	return copy

func _inspect_candidate_readonly(path: String) -> Dictionary:
	return service()._load_candidate(path)

static func _estimate_play_time_seconds(snapshot: Dictionary) -> float:
	var completed: Array = snapshot.get("completed_scene_ids", []) if snapshot.get("completed_scene_ids") is Array else []
	var revision := maxi(0, int(snapshot.get("state_revision", 0)))
	return float(completed.size() * 180 + revision * 15)

static func _ensure_catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = ContentScript.load_full()
	return _catalog

static func _chapter_title(chapter_num: int) -> String:
	for row in _ensure_catalog().get("chapters", []):
		if row is Dictionary and int(row.get("number", 0)) == chapter_num:
			return "Chapter %d · %s" % [chapter_num, String(row.get("title", ""))]
	return "Chapter %d" % chapter_num

static func _mission_title(mission_id: String) -> String:
	for row in _ensure_catalog().get("missions", []):
		if row is Dictionary and String(row.get("id", "")) == mission_id:
			return String(row.get("title", "Expedition Mission"))
	return "Expedition Mission"

static func _scene_title(scene_id: String) -> String:
	for row in _ensure_catalog().get("scenes", []):
		if row is Dictionary and String(row.get("id", "")) == scene_id:
			return String(row.get("title", "Aurora Station"))
	return "Aurora Station"

static func _empty_metadata(slot_id: String, path: String) -> Dictionary:
	return {
		"slot_id": slot_id,
		"slot_label": slot_label(slot_id),
		"path": path,
		"exists": false,
		"empty": true,
		"valid": false,
		"corrupt": false,
		"recovered": false,
		"migrated": false,
		"backup_available": false,
		"schema_version": SaveScript.SCHEMA_VERSION,
		"slot_meta_version": SLOT_META_VERSION,
		"chapter": 0,
		"chapter_id": "",
		"chapter_title": "Empty Slot",
		"mission_id": "",
		"mission_title": "",
		"scene_id": "",
		"scene_title": "",
		"story_date": "",
		"scenario_datetime": "",
		"play_time_seconds": 0,
		"play_time": "0s",
		"thumbnail_path": thumbnail_for_chapter(1),
		"trigger": "",
		"saved_at_utc": "",
		"completed_scenes": 0,
		"achievements_unlocked": 0,
		"status_label": "Empty save slot",
	}
