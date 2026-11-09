class_name CommsService
extends RefCounted
## Loads authored campaign message packs (`res://resources/campaign/content/messages/ch*.json`),
## evaluates unlock triggers against `CampaignDirector` / route snapshots, tracks read/delivered
## state via `director.update_message_metadata`, queues arrival toasts, and exposes the latest
## goal-handoff message.

const CampaignContentFull = preload("res://scripts/content/content_loader.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const Knowledge = preload("res://scripts/dialogue/knowledge_service.gd")

const MESSAGES_DIR := "res://resources/campaign/content/messages"
const THREAD_ORDER := ["crew", "commander", "earth", "academy", "archive"]
const THREAD_LABELS := {
	"crew": "Crew",
	"commander": "Commander",
	"earth": "Earth",
	"academy": "Academy",
	"archive": "Archive",
}

var _director = null
var _content: Dictionary = {}
var _messages_by_id: Dictionary = {}
var _ordered_ids: Array[String] = []
var _delivered_ids: Array[String] = []
var _read_ids: Array[String] = []
var _toast_queue: Array[Dictionary] = []
var _latest_goal_id: String = ""
var _initialized: bool = false


func setup(director = null, content: Dictionary = {}, include_test_fixture: bool = false) -> void:
	_director = director
	_content = content
	if _content.is_empty() and _director != null and _director.get("content") is Dictionary:
		_content = _director.content
	load_packs(include_test_fixture)
	sync_from_director(false)


func load_packs(include_test_fixture: bool = false) -> void:
	_messages_by_id.clear()
	_ordered_ids.clear()
	var chapters: Array[int] = []
	if include_test_fixture:
		chapters.append(0)
	for ch in range(1, 9):
		chapters.append(ch)
	for ch in chapters:
		var path := "%s/ch%02d.json" % [MESSAGES_DIR, ch]
		load_pack_file(path)


func load_pack_file(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var raw := FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return 0
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return 0
	var doc: Dictionary = parsed
	var ch_num := int(doc.get("chapter", 0))
	var entries: Array = doc.get("messages", [])
	var loaded := 0
	for item in entries:
		if not (item is Dictionary):
			continue
		var entry: Dictionary = (item as Dictionary).duplicate(true)
		var msg_id := String(entry.get("id", "")).strip_edges()
		if msg_id.is_empty():
			continue
		entry["chapter"] = ch_num
		entry["formatted_time"] = format_story_time(String(entry.get("story_time", "")))
		if not _messages_by_id.has(msg_id):
			_ordered_ids.append(msg_id)
		_messages_by_id[msg_id] = entry
		loaded += 1
	return loaded


static func format_story_time(iso_time: String) -> String:
	var cleaned := iso_time.strip_edges()
	if cleaned.is_empty():
		return ""
	var normalized := cleaned.replace("T", " ")
	if normalized.ends_with("Z"):
		normalized = normalized.substr(0, normalized.length() - 1) + " UTC"
	return Knowledge.format_date(normalized)


func sync_from_director(emit_toasts_for_new: bool = true, extra_state: Dictionary = {}) -> Dictionary:
	var snap: Dictionary = {}
	if _director != null and _director.has_method("snapshot"):
		snap = _director.snapshot()
	if not extra_state.is_empty():
		for k in extra_state.keys():
			snap[k] = extra_state[k]
	var emit_toasts := emit_toasts_for_new and _initialized
	var res := evaluate_unlocks(snap, emit_toasts)
	_initialized = true
	return res


func evaluate_unlocks(snapshot: Dictionary, emit_toasts: bool = true) -> Dictionary:
	var meta: Dictionary = {}
	if snapshot.has("message_metadata") and snapshot.get("message_metadata") is Dictionary:
		meta = snapshot.get("message_metadata")
	elif _director != null and _director.has_method("message_metadata"):
		meta = _director.message_metadata()
	else:
		meta = StateScript.message_metadata(snapshot)
	if meta is Dictionary:
		for raw_id in meta.get("delivered_ids", []):
			var did := String(raw_id)
			if not did.is_empty() and _messages_by_id.has(did) and not _delivered_ids.has(did):
				_delivered_ids.append(did)
		for raw_read in meta.get("read_ids", []):
			var rid := String(raw_read)
			if not rid.is_empty() and _messages_by_id.has(rid) and not _read_ids.has(rid):
				_read_ids.append(rid)

	var newly_unlocked: Array[String] = []
	for msg_id in _ordered_ids:
		if _delivered_ids.has(msg_id):
			continue
		var msg: Dictionary = _messages_by_id.get(msg_id, {})
		if _is_message_unlocked(msg, snapshot):
			_delivered_ids.append(msg_id)
			newly_unlocked.append(msg_id)
			if bool(msg.get("goal", false)):
				_latest_goal_id = msg_id
			if emit_toasts:
				_enqueue_toast(msg)

	if _latest_goal_id.is_empty():
		for i in range(_delivered_ids.size() - 1, -1, -1):
			var candidate_id := _delivered_ids[i]
			var candidate: Dictionary = _messages_by_id.get(candidate_id, {})
			if bool(candidate.get("goal", false)):
				_latest_goal_id = candidate_id
				break

	if not newly_unlocked.is_empty() and _director != null and _director.has_method("update_message_metadata"):
		_director.update_message_metadata({"delivered_ids": newly_unlocked})

	return {
		"newly_unlocked": newly_unlocked.duplicate(),
		"delivered_count": _delivered_ids.size(),
		"unread_count": unread_count(),
	}


func _is_message_unlocked(msg: Dictionary, snapshot: Dictionary) -> bool:
	var unlock: Dictionary = msg.get("unlock", {})
	if not (unlock is Dictionary):
		return false
	var on_kind := String(unlock.get("on", "")).strip_edges()
	var target_id := String(unlock.get("id", "")).strip_edges()
	if on_kind.is_empty() or target_id.is_empty():
		return false

	var current_scene_id := String(snapshot.get("current_scene_id", snapshot.get("scene_id", "")))
	var completed_scenes_raw: Variant = snapshot.get("completed_scene_ids", [])
	var completed_scenes: Array = completed_scenes_raw if completed_scenes_raw is Array else []
	var evidence_raw: Variant = snapshot.get("acquired_evidence_ids", [])
	var evidence_ids: Array = evidence_raw if evidence_raw is Array else []
	var flags_raw: Variant = snapshot.get("knowledge_flags", [])
	var knowledge_flags: Array = flags_raw if flags_raw is Array else []
	var receipts_raw: Variant = snapshot.get("receipts", {})
	var mission_receipts_raw: Variant = snapshot.get("mission_receipts", {})
	var interaction_receipts_raw: Variant = snapshot.get("interaction_receipts", {})
	var completed_targets_raw: Variant = snapshot.get("completed_targets_by_scene", {})
	var completed_targets: Dictionary = completed_targets_raw if completed_targets_raw is Dictionary else {}
	var physical_flags_raw: Variant = snapshot.get("physical_flags", {})
	var physical_flags: Dictionary = physical_flags_raw if physical_flags_raw is Dictionary else {}
	var jobs_raw: Variant = snapshot.get("completed_jobs", [])
	var job_ids: Array = jobs_raw if jobs_raw is Array else []
	var found_raw: Variant = snapshot.get("found_ids", [])
	var found_ids: Array = found_raw if found_raw is Array else []

	match on_kind:
		"scene_enter":
			return current_scene_id == target_id or completed_scenes.has(target_id)
		"scene_exit":
			return completed_scenes.has(target_id)
		"mission_done":
			if _has_receipt(receipts_raw, target_id) or _has_receipt(receipts_raw, "mission:" + target_id) or _has_receipt(mission_receipts_raw, target_id):
				return true
			var completed_missions_raw: Variant = snapshot.get("completed_missions", [])
			if completed_missions_raw is Array and (completed_missions_raw as Array).has(target_id):
				return true
			if not _content.is_empty():
				var mission: Dictionary = CampaignContentFull.mission_by_id(_content, target_id)
				var m_scenes: Array = mission.get("scene_ids", [])
				if not m_scenes.is_empty():
					for sid in m_scenes:
						if not completed_scenes.has(String(sid)):
							return false
					return true
			return false
		"job_done":
			if job_ids.has(target_id) or bool(physical_flags.get(target_id, false)):
				return true
			if _has_receipt(receipts_raw, target_id) or _has_receipt(receipts_raw, "job:" + target_id) or _has_receipt(receipts_raw, "interaction:" + target_id) or _has_receipt(receipts_raw, "p01:" + target_id) or _has_receipt(interaction_receipts_raw, target_id):
				return true
			for scene_key in completed_targets.keys():
				var t_arr: Variant = completed_targets.get(scene_key, [])
				if t_arr is Array and (t_arr as Array).has(target_id):
					return true
			return false
		"found":
			if found_ids.has(target_id) or evidence_ids.has(target_id) or knowledge_flags.has(target_id) or _has_receipt(receipts_raw, "found:" + target_id) or _has_receipt(interaction_receipts_raw, target_id):
				return true
			if target_id.begins_with("EX-CH"):
				if completed_scenes.has(target_id):
					return true
				if current_scene_id == target_id:
					var scene_targets: Variant = completed_targets.get(target_id, [])
					if scene_targets is Array and not (scene_targets as Array).is_empty():
						return true
					for flag_key in physical_flags.keys():
						if bool(physical_flags.get(flag_key, false)):
							return true
			return false
		_:
			return false


func _has_receipt(container: Variant, key: String) -> bool:
	if container is Dictionary:
		return (container as Dictionary).has(key)
	if container is Array:
		return (container as Array).has(key)
	return false


func _enqueue_toast(msg: Dictionary) -> void:
	var sender := String(msg.get("sender", "Station")).strip_edges()
	var subject := String(msg.get("subject", "New message")).strip_edges()
	var msg_id := String(msg.get("id", ""))
	for item in _toast_queue:
		if String(item.get("id", "")) == msg_id:
			return
	_toast_queue.append({
		"id": msg_id,
		"thread": String(msg.get("thread", "crew")),
		"sender": sender,
		"subject": subject,
		"text": "New message · %s: %s" % [sender, subject],
	})


func has_pending_toasts() -> bool:
	return not _toast_queue.is_empty()


func pop_toast() -> Dictionary:
	if _toast_queue.is_empty():
		return {}
	return _toast_queue.pop_front()


func peek_toasts() -> Array[Dictionary]:
	return _toast_queue.duplicate(true)


func clear_toasts() -> void:
	_toast_queue.clear()


func mark_read(message_id: String) -> Dictionary:
	var clean_id := message_id.strip_edges()
	if clean_id.is_empty() or not _messages_by_id.has(clean_id):
		return {"ok": false, "reason": "unknown_message"}
	if not _delivered_ids.has(clean_id):
		return {"ok": false, "reason": "not_delivered"}
	if not _read_ids.has(clean_id):
		_read_ids.append(clean_id)
		if _director != null and _director.has_method("update_message_metadata"):
			_director.update_message_metadata({"read_ids": [clean_id]})
	return {"ok": true, "id": clean_id, "unread_count": unread_count()}


func is_read(message_id: String) -> bool:
	return _read_ids.has(message_id)


func is_delivered(message_id: String) -> bool:
	return _delivered_ids.has(message_id)


func unread_count(thread_id: String = "") -> int:
	var clean_thread := thread_id.strip_edges()
	var count := 0
	for msg_id in _delivered_ids:
		if _read_ids.has(msg_id):
			continue
		if not clean_thread.is_empty():
			var msg: Dictionary = _messages_by_id.get(msg_id, {})
			if String(msg.get("thread", "")) != clean_thread:
				continue
		count += 1
	return count


func threads_view() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for tid in THREAD_ORDER:
		var msgs := messages_for_thread(tid)
		out.append({
			"id": tid,
			"label": String(THREAD_LABELS.get(tid, tid.capitalize())),
			"total_count": msgs.size(),
			"unread_count": unread_count(tid),
		})
	return out


func messages_for_thread(thread_id: String, delivered_only: bool = true) -> Array[Dictionary]:
	var clean_thread := thread_id.strip_edges()
	var list: Array[Dictionary] = []
	var source_ids: Array[String] = _delivered_ids if delivered_only else _ordered_ids
	for i in range(source_ids.size() - 1, -1, -1):
		var msg_id := source_ids[i]
		var msg: Dictionary = _messages_by_id.get(msg_id, {})
		if msg.is_empty():
			continue
		if not clean_thread.is_empty() and String(msg.get("thread", "")) != clean_thread:
			continue
		var view := msg.duplicate(true)
		view["delivered"] = _delivered_ids.has(msg_id)
		view["read"] = _read_ids.has(msg_id)
		list.append(view)
	return list


func message_by_id(message_id: String) -> Dictionary:
	var clean_id := message_id.strip_edges()
	if not _messages_by_id.has(clean_id):
		return {}
	var view: Dictionary = (_messages_by_id[clean_id] as Dictionary).duplicate(true)
	view["delivered"] = _delivered_ids.has(clean_id)
	view["read"] = _read_ids.has(clean_id)
	return view


func latest_goal_message() -> Dictionary:
	if _latest_goal_id.is_empty() or not _messages_by_id.has(_latest_goal_id):
		return {}
	return message_by_id(_latest_goal_id)


func delivered_ids() -> Array[String]:
	return _delivered_ids.duplicate()


func read_ids() -> Array[String]:
	return _read_ids.duplicate()


func total_loaded_count() -> int:
	return _ordered_ids.size()
