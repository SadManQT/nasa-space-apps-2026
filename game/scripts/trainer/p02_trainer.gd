extends RefCounted

## One isolated exercise; campaign route supplies the existing plan/view only.
const Director = preload("res://scripts/core/campaign_director.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Simulation = preload("res://scripts/simulation/expedition_simulation.gd")
const Host = preload("res://scripts/puzzles/puzzle_host.gd")
const Table = preload("res://scripts/puzzles/p02_mission_table.gd")
const Debrief = preload("res://scripts/debrief/chapter1_debrief.gd")
var _director: RefCounted
var _route: RefCounted
var _entry: Dictionary
var _last: Dictionary = {}
var _checkpoint: Dictionary = {}

func begin(entry: Dictionary) -> Dictionary:
	_entry = entry.duplicate(true)
	_director = Director.new()
	var state: Dictionary = _director.snapshot()
	var profile := Simulation.new().entry_profile(String(entry.get("profile", "")))
	if profile.is_empty():
		return {"accepted": false, "reason": "Training profile is unavailable."}
	for key in ["resources", "upgrades", "scenario_datetime", "current_shift"]:
		state[key] = profile[key]
	state.merge({"save_id": "mission-trainer", "checkpoint_id": "mission-trainer-entry", "mission_id": entry.mission, "scene_id": entry.scene, "scene_phase": "planning", "status": "active", "paused": false}, true)
	var result: Dictionary = _director.restore_snapshot(state)
	if result.accepted:
		_route = Route.new(_director, true)
		_last = {}
		_checkpoint = {}
	return result

func director() -> RefCounted:
	return _director

func mission_table() -> RefCounted:
	return _route.mission_table()

func mission_table_view(target_id: String) -> Dictionary:
	var view: Dictionary = _route.mission_table_view(target_id)
	view.prerequisite_reason = ""
	return view

func current_gate() -> String:
	if not String(_last.get("ending", "")).is_empty():
		return ""
	var next := int(_director.query().current_shift) + 1
	for id in Table.data().gates:
		var gate: Dictionary = Table.gate_info(id)
		if not bool(gate.get("preview_only", false)) and int(Table.gate_shifts(id)[0]) == next:
			return id
	return ""

func commit_gate(target_id: String, plan: Dictionary, expected_revision: int) -> Dictionary:
	if target_id != current_gate() or target_id.is_empty():
		return {"accepted": false, "reason": "This training step is already finished or out of order."}
	if expected_revision != int(_director.query().state_revision):
		return {"accepted": false, "reason": "The forecast changed. Try the current plan again."}
	var problem: String = mission_table().commit_block_reason(target_id, int(_director.query().current_shift))
	if not problem.is_empty() or plan != mission_table().plan_for_gate(target_id):
		return {"accepted": false, "reason": problem if not problem.is_empty() else "The choices changed. Try the current plan again."}
	var host := Host.new()
	host.bind(_director, "P-02", _entry.mission, _entry.scene)
	var forecast: Dictionary = host.preview(plan)
	if not forecast.accepted:
		return forecast
	var before: Dictionary = _director.snapshot()
	var result: Dictionary = host.commit("trainer:" + target_id, plan)
	if result.accepted:
		_checkpoint = before
		_last = result.duplicate(true)
		mission_table().record_ending(String(result.get("ending", "")))
	return result

func retry() -> Dictionary:
	if _checkpoint.is_empty():
		return {"accepted": false, "reason": "No completed step to retry yet."}
	var result: Dictionary = _director.restore_checkpoint()
	if result.accepted:
		_last = {}
		if int(_director.query().current_shift) < int(Table.data().alarm_shift):
			mission_table().reset_alarm_task()
	return result

func outcome() -> Dictionary:
	if String(_last.get("ending", "")).is_empty():
		return {}
	var view := Debrief.view(_director.snapshot(), {"ending": _last.ending, "chapter_ready": {"safe_ending": _last.ending in ["BLOOM", "GOLDEN"]}, "retry_checkpoint": {"director": _checkpoint}})
	view["trainer"] = true
	return view
