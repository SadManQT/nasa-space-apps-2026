extends RefCounted
class_name CampaignProgressionFlow

## M3-64, M3-4U, M3-6U, M3-8U: Authoritative runtime bridge between
## Chapter1Campaign, CadetProgression, CampaignFieldSystems and the Safe Room
## bunk / Station Jobs Board. Ensures upgrades require completed chapter
## evidence, Safe Room bunk rest requires standing in LOC-04, and optional jobs
## require physical in-world interaction before filing a report card.

const CadetProgressionScript = preload("res://scripts/progression/cadet_progression.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const INTERACT_RANGE_M := 3.5

var model: CadetProgression
var _runtime: Node
var _active_job_id := ""
var _job_state: Dictionary = {}
var _job_marker: Node3D
var _marker_room_id := ""
var _recorded_missions: Dictionary = {}

func _init(runtime: Node) -> void:
	_runtime = runtime
	model = CadetProgressionScript.new()
	if _runtime != null and _runtime.get("director") != null:
		model.sync_upgrades_from_snapshot(_runtime.director.snapshot())

func restore(resume: Dictionary) -> void:
	if resume.get("cadet_progression") is Dictionary:
		model.restore(resume.get("cadet_progression", {}))
	if _runtime != null and _runtime.get("director") != null:
		model.sync_upgrades_from_snapshot(_runtime.director.snapshot())
	if resume.get("active_job_id") is String:
		_active_job_id = String(resume.get("active_job_id", ""))
	if resume.get("job_state") is Dictionary:
		_job_state = (resume.get("job_state", {}) as Dictionary).duplicate(true)
	if resume.get("recorded_missions") is Dictionary:
		_recorded_missions = (resume.get("recorded_missions", {}) as Dictionary).duplicate(true)
	_restore_active_job_payload()

func snapshot() -> Dictionary:
	return {
		"cadet_progression": model.snapshot(),
		"active_job_id": _active_job_id,
		"job_state": _job_state.duplicate(true),
		"recorded_missions": _recorded_missions.duplicate(true),
	}

func completed_chapters() -> Array:
	var out: Array = []
	if _runtime == null or _runtime.get("director") == null:
		return out
	var completed_scenes: Array = _runtime.director.snapshot().get("completed_scene_ids", [])
	if _runtime.get("route") != null and _runtime.route.has_method("completed_scene_ids"):
		for sid in _runtime.route.completed_scene_ids():
			if not completed_scenes.has(sid):
				completed_scenes.append(sid)
	for ch in range(1, 9):
		var s12 := "EX-CH%02d-S12" % ch
		if completed_scenes.has(s12):
			out.append(ch)
	return out

func available_upgrade_chapter() -> int:
	var done := completed_chapters()
	for ch in done:
		var c := int(ch)
		if c >= 1 and c <= 7 and not model.unlocked_upgrades.has(str(c)):
			return c
	return 0

func choose_upgrade(chapter: int, option: String) -> Dictionary:
	var done := completed_chapters()
	var result := model.choose_upgrade(chapter, option, done)
	if not bool(result.get("accepted", false)):
		return result
	if _runtime != null and _runtime.get("director") != null:
		var snap: Dictionary = _runtime.director.snapshot()
		var upgrades: Dictionary = snap.get("upgrades", {}).duplicate(true)
		var choices: Dictionary = upgrades.get("choices", {}).duplicate(true)
		var acq: Dictionary = upgrades.get("acquisition_chapter", {}).duplicate(true)
		choices[str(chapter)] = String(result.get("upgrade_id", ""))
		acq[str(chapter)] = "CH%02d" % chapter
		upgrades["choices"] = choices
		upgrades["acquisition_chapter"] = acq
		snap["upgrades"] = upgrades
		_runtime.director.restore_snapshot(snap)
	var saved := save_progression()
	result["persisted"] = bool(saved.get("accepted", false))
	return result

func rest_at_bunk() -> Dictionary:
	if _runtime == null or _runtime.get("_room") == null:
		return {"accepted": false, "reason": "Safe Room bunk is unavailable right now."}
	var room_id := String(_runtime._room.room_id)
	if room_id != "LOC-04":
		return {"accepted": false, "reason": "Walk to the Safe Room bunks (LOC-04) to rest and save."}
	var unread := 0
	if _runtime.get("hud") != null and _runtime.hud.get("comms_service") != null and _runtime.hud.comms_service.has_method("unread_count"):
		unread = int(_runtime.hud.comms_service.unread_count())
	var plants: Array = _runtime.director.snapshot().get("plants", []) if _runtime.get("director") != null else []
	var result := model.rest_at_bunk(unread, maxi(2, plants.size()))
	var saved: Dictionary = _runtime.save_campaign()
	result["persisted"] = bool(saved.get("accepted", false))
	return result

func record_mission(mission_id: String) -> void:
	if mission_id.is_empty() or _recorded_missions.has(mission_id):
		return
	_recorded_missions[mission_id] = true
	var ch: int = int(_runtime._chapter_number()) if _runtime != null and _runtime.has_method("_chapter_number") else 1
	var skills := ["life_support", "observation", "repair", "navigation", "handling"]
	var skill_id: String = skills[(ch - 1) % skills.size()]
	var reserve_pct := float(_runtime.eva_suit.oxygen) if _runtime != null and _runtime.get("eva_suit") != null else 35.0
	model.record_sortie_report({
		"id": mission_id,
		"title": "Mission %s" % mission_id,
		"chapter": ch,
		"skill": skill_id,
		"xp": 1,
		"measured_metrics": {
			"elapsed_seconds": 60.0,
			"reserve_kept_pct": snappedf(reserve_pct, 0.1),
		},
	})

func begin_job(job_id: String) -> Dictionary:
	var spec := model._job_spec(job_id)
	if spec.is_empty():
		return {"accepted": false, "reason": "Unknown job: " + job_id}
	if model.completed_jobs.has(job_id):
		return {"accepted": false, "reason": "Job already completed."}
	var max_ch := _max_unlocked_chapter()
	var job_ch := int(spec.get("chapter", 1))
	if job_ch > max_ch:
		return {"accepted": false, "reason": "Reach Chapter %d to unlock %s." % [job_ch, String(spec.get("title", job_id))]}
	var plan := _job_plan(spec)
	_active_job_id = job_id
	_job_state[job_id] = {
		"job_id": job_id,
		"kind": String(spec.get("kind", "maintenance")),
		"phase": "pickup" if String(spec.get("kind", "")) == "delivery" else "work",
		"pickup_room": String(plan.get("pickup_room", "LOC-01")),
		"pickup_pos": plan.get("pickup_pos", [2.0, 0.0, 0.0]),
		"dest_room": String(plan.get("dest_room", "LOC-04")),
		"dest_pos": plan.get("dest_pos", [-2.0, 0.0, 0.0]),
		"elapsed_seconds": 0.0,
		"complete": false,
		"observations": [],
		"payload_condition": "intact",
	}
	if String(spec.get("kind", "")) == "delivery":
		_register_delivery_payload(job_id, spec, String(plan.get("dest_room", "LOC-04")))
	_rebuild_job_marker()
	return {
		"accepted": true,
		"job_id": job_id,
		"title": String(spec.get("title", job_id)),
		"reason": "Job started: %s. Walk to the marked station fixture and press E." % String(spec.get("title", job_id)),
	}

func job_target() -> Node3D:
	if not is_instance_valid(_job_marker) or not _job_marker.is_inside_tree():
		_rebuild_job_marker()
	return _job_marker if is_instance_valid(_job_marker) and _job_marker.is_inside_tree() else null

func step(delta: float) -> void:
	if _active_job_id.is_empty() or not _job_state.has(_active_job_id):
		return
	var st: Dictionary = _job_state[_active_job_id]
	if not bool(st.get("complete", false)):
		st["elapsed_seconds"] = snappedf(float(st.get("elapsed_seconds", 0.0)) + maxf(0.0, delta), 0.1)
	var current_room := String(_runtime._room.room_id) if _runtime != null and _runtime.get("_room") != null else ""
	var expected_room := _expected_room_for_state(st)
	if current_room != _marker_room_id or (expected_room == current_room and not is_instance_valid(_job_marker)):
		_rebuild_job_marker()

func interact_job() -> Dictionary:
	if _active_job_id.is_empty() or not _job_state.has(_active_job_id):
		return {"accepted": false, "handled": false, "reason": "No active station job."}
	var st: Dictionary = _job_state[_active_job_id]
	if bool(st.get("complete", false)):
		return {"accepted": false, "handled": false, "reason": "Field work already complete. File the report on the Jobs Board."}
	var target := job_target()
	if target == null or _runtime == null or _runtime.get("_player") == null:
		return {"accepted": false, "handled": false, "reason": "No job fixture in this room."}
	var distance: float = _runtime._player.global_position.distance_to(target.global_position)
	if distance > INTERACT_RANGE_M:
		return {"accepted": false, "handled": false, "reason": "Move within %.1f m of the job marker." % INTERACT_RANGE_M}
	var payload_id := "job:" + _active_job_id
	var phase := String(st.get("phase", "work"))
	if phase == "pickup":
		var inv = _runtime.field_systems.inventory if _runtime.get("field_systems") != null else null
		if inv == null:
			return {"accepted": false, "handled": true, "reason": "Payload inventory unavailable."}
		if inv.item(payload_id).is_empty():
			var spec := model._job_spec(_active_job_id)
			_register_delivery_payload(_active_job_id, spec, String(st.get("dest_room", "LOC-04")))
		var picked: Dictionary = inv.pickup(payload_id, "hands")
		if not bool(picked.get("accepted", false)):
			return {"accepted": false, "handled": true, "reason": String(picked.get("reason", "Could not pick up payload."))}
		st["phase"] = "deliver"
		_rebuild_job_marker()
		return {"accepted": true, "handled": true, "phase": "deliver", "reason": String(picked.get("reason", "Picked up job payload."))}
	elif phase == "deliver":
		var inv = _runtime.field_systems.inventory if _runtime.get("field_systems") != null else null
		if inv == null:
			return {"accepted": false, "handled": true, "reason": "Payload inventory unavailable."}
		var dest_room := String(st.get("dest_room", "LOC-04"))
		var delivered: Dictionary = inv.deliver(payload_id, dest_room)
		if not bool(delivered.get("accepted", false)):
			return {"accepted": false, "handled": true, "reason": String(delivered.get("reason", "Could not deliver payload here."))}
		var item_cond: Dictionary = inv.item(payload_id).get("condition", {})
		st["payload_condition"] = "intact" if bool(item_cond.get("intact", true)) and bool(item_cond.get("seal_intact", true)) else "scuffed"
		st["complete"] = true
		st["phase"] = "complete"
		_clear_job_marker()
		return {"accepted": true, "handled": true, "complete": true, "reason": String(delivered.get("reason", "Payload delivered. File your report on the Jobs Board."))}
	else:
		var res_snap: Dictionary = _runtime.director.snapshot().get("resources", {}) if _runtime.get("director") != null else {}
		var obs: Array = st.get("observations", [])
		obs.append({
			"room_id": String(_runtime._room.room_id),
			"battery": float(res_snap.get("E", 14.0)),
			"oxygen_pct": snappedf(float(_runtime.eva_suit.oxygen) if _runtime.get("eva_suit") != null else 100.0, 0.1),
		})
		st["observations"] = obs
		st["complete"] = true
		st["phase"] = "complete"
		_clear_job_marker()
		return {"accepted": true, "handled": true, "complete": true, "reason": "Field check logged. File your report on the Jobs Board."}

func job_metrics(job_id: String) -> Dictionary:
	if not _job_state.has(job_id):
		return {"job_id": job_id, "complete": false, "ready": false}
	var st: Dictionary = _job_state[job_id]
	var complete := bool(st.get("complete", false))
	var reserve_pct := snappedf(float(_runtime.eva_suit.oxygen) if _runtime != null and _runtime.get("eva_suit") != null else 100.0, 0.1)
	var measured := {
		"elapsed_seconds": maxf(0.1, float(st.get("elapsed_seconds", 1.0))),
		"payload_condition": String(st.get("payload_condition", "intact")),
		"reserve_kept_pct": reserve_pct,
	}
	var obs: Array = st.get("observations", [])
	if not obs.is_empty():
		measured["observations"] = obs.duplicate(true)
	return {
		"job_id": job_id,
		"complete": complete,
		"ready": complete,
		"measured_metrics": measured,
	}

func complete_job(job_id: String, _client_performance: Dictionary = {}) -> Dictionary:
	if model.completed_jobs.has(job_id):
		return {"accepted": false, "reason": "Job already completed."}
	if not _job_state.has(job_id) or not bool(_job_state[job_id].get("complete", false)):
		return {"accepted": false, "reason": "Complete the physical job in the station or field before filing its report."}
	var authoritative := job_metrics(job_id)
	var result := model.complete_job(job_id, _max_unlocked_chapter(), {
		"measured_metrics": authoritative.get("measured_metrics", {}),
	})
	if bool(result.get("accepted", false)):
		if _active_job_id == job_id:
			_active_job_id = ""
		var saved := save_progression()
		result["persisted"] = bool(saved.get("accepted", false))
	return result

func save_progression() -> Dictionary:
	if _runtime != null and _runtime.has_method("_save_campaign"):
		return _runtime._save_campaign()
	return {"accepted": false, "reason": "Campaign save unavailable."}

func _max_unlocked_chapter() -> int:
	var ch: int = int(_runtime._chapter_number()) if _runtime != null and _runtime.has_method("_chapter_number") else 1
	for c in completed_chapters():
		ch = maxi(ch, mini(8, int(c) + 1))
	return clampi(ch, 1, 8)

func _job_plan(spec: Dictionary) -> Dictionary:
	var current_room := String(_runtime._room.room_id) if _runtime != null and _runtime.get("_room") != null else "LOC-01"
	var kind := String(spec.get("kind", "maintenance"))
	var job_id := String(spec.get("id", ""))
	if job_id == "JOB-CH01-03":
		return {
			"pickup_room": "LOC-01",
			"pickup_pos": [2.2, 0.0, -1.2],
			"dest_room": "LOC-04",
			"dest_pos": [-1.8, 0.0, 1.0],
		}
	if kind == "delivery":
		var dest := "LOC-03" if current_room != "LOC-03" else "LOC-04"
		return {
			"pickup_room": current_room,
			"pickup_pos": [2.0, 0.0, -1.0],
			"dest_room": dest,
			"dest_pos": [-1.8, 0.0, 1.0],
		}
	return {
		"pickup_room": current_room,
		"pickup_pos": [1.8, 0.0, -1.0],
		"dest_room": current_room,
		"dest_pos": [1.8, 0.0, -1.0],
	}

func _register_delivery_payload(job_id: String, spec: Dictionary, dest_room: String) -> void:
	if _runtime == null or _runtime.get("field_systems") == null:
		return
	var inv = _runtime.field_systems.inventory
	var payload_id := "job:" + job_id
	if not inv.item(payload_id).is_empty():
		return
	inv.register_payload({
		"id": payload_id,
		"label": String(spec.get("title", job_id)),
		"size": "small",
		"mass_kg": 2.0,
		"destination": dest_room,
		"handling": ["sealed"],
	})

func _restore_active_job_payload() -> void:
	if _active_job_id.is_empty() or not _job_state.has(_active_job_id):
		return
	var st: Dictionary = _job_state[_active_job_id]
	var spec := model._job_spec(_active_job_id)
	if String(st.get("kind", "")) == "delivery" and not spec.is_empty():
		_register_delivery_payload(_active_job_id, spec, String(st.get("dest_room", "LOC-04")))
		if String(st.get("phase", "")) == "deliver" and _runtime != null and _runtime.get("field_systems") != null:
			_runtime.field_systems.inventory.pickup("job:" + _active_job_id, "hands")

func _expected_room_for_state(st: Dictionary) -> String:
	if bool(st.get("complete", false)):
		return ""
	var phase := String(st.get("phase", "work"))
	return String(st.get("dest_room", "LOC-04")) if phase == "deliver" else String(st.get("pickup_room", "LOC-01"))

func _clear_job_marker() -> void:
	if is_instance_valid(_job_marker):
		_job_marker.queue_free()
	_job_marker = null
	_marker_room_id = ""

func _rebuild_job_marker() -> void:
	_clear_job_marker()
	if _active_job_id.is_empty() or not _job_state.has(_active_job_id):
		return
	if _runtime == null or _runtime.get("_room") == null or not is_instance_valid(_runtime._room):
		return
	var st: Dictionary = _job_state[_active_job_id]
	if bool(st.get("complete", false)):
		return
	var current_room := String(_runtime._room.room_id)
	var expected_room := _expected_room_for_state(st)
	if current_room != expected_room:
		return
	var coords: Array = st.get("dest_pos", [-1.8, 0.0, 1.0]) if String(st.get("phase", "")) == "deliver" else st.get("pickup_pos", [2.2, 0.0, -1.2])
	var marker := MeshInstance3D.new()
	marker.name = "JobMarker_" + _active_job_id
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.34
	mesh.height = 0.9
	marker.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#20B8C9") if String(st.get("phase", "")) != "deliver" else Color("#F2C230")
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.35
	marker.material_override = mat
	_runtime._room.add_child(marker)
	marker.position = Vector3(float(coords[0]), float(coords[1]) + 0.45, float(coords[2]))
	_job_marker = marker
	_marker_room_id = current_room
