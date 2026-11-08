extends SceneTree
## M1-102: the session crew setup {mode, players} chosen at New Expedition.
const Director = preload("res://scripts/core/campaign_director.gd")
const State = preload("res://scripts/core/campaign_state.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var rev := "story-data-extended-02-systems-contract"
	# Default New Expedition is Solo/1 and its snapshot restores.
	var d = Director.new()
	var solo: Dictionary = d.new_campaign(rev)
	_check(solo.get("crew") == {"mode": "solo", "players": 1}, "New Expedition defaults to Solo/1")
	_check(d.crew() == {"mode": "solo", "players": 1}, "crew() reads Solo/1")
	_check(State.validate_snapshot(solo).valid, "Solo snapshot validates")
	# Valid Class sizes, including a JSON round trip (numbers load as floats).
	for n in [2, 3, 4]:
		var c = Director.new()
		var snap: Dictionary = c.new_campaign(rev, {"mode": "class", "players": n})
		_check(c.crew() == {"mode": "class", "players": n}, "Class/%d accepted" % n)
		var loaded: Dictionary = JSON.parse_string(JSON.stringify(snap))
		var r = Director.new()
		_check(r.restore_snapshot(loaded, rev).accepted and r.crew() == {"mode": "class", "players": n}, "Class/%d survives a JSON save" % n)
		_check(typeof(r.crew().players) == TYPE_INT, "crew() players is an int")
	# Old saves without the field default to Solo/1.
	var old := solo.duplicate(true)
	old.erase("crew")
	var o = Director.new()
	_check(o.restore_snapshot(old, rev).accepted, "old save without crew restores")
	_check(o.crew() == {"mode": "solo", "players": 1}, "old save reads as Solo/1")
	_check(State.crew_of(old) == {"mode": "solo", "players": 1}, "crew_of defaults old saves")
	# Checkpoint and pause/resume keep the crew; nothing else changes.
	var k = Director.new()
	var class_snap: Dictionary = k.new_campaign(rev, {"mode": "class", "players": 3})
	k.pause()
	k.resume()
	k.restore_checkpoint()
	_check(k.crew() == {"mode": "class", "players": 3}, "checkpoint keeps the crew")
	var plain = Director.new()
	var plain_snap: Dictionary = plain.new_campaign(rev)
	var a := plain_snap.duplicate(true)
	var b := class_snap.duplicate(true)
	a.erase("crew")
	b.erase("crew")
	_check(a == b, "crew is the only difference between Solo and Class starts")
	# Rejections: atomic for both new_campaign and restore_snapshot.
	var bad := [
		null, 3, "solo", [], {}, {"mode": "solo"}, {"players": 1},
		{"mode": "solo", "players": 1, "extra": true},
		{"mode": "duo", "players": 2}, {"mode": "Solo", "players": 1}, {"mode": 1, "players": 1},
		{"mode": "solo", "players": 2}, {"mode": "solo", "players": 0},
		{"mode": "class", "players": 1}, {"mode": "class", "players": 5}, {"mode": "class", "players": -2},
		{"mode": "class", "players": 2.5}, {"mode": "class", "players": NAN}, {"mode": "class", "players": INF},
		{"mode": "class", "players": "3"}, {"mode": "class", "players": true},
	]
	var g = Director.new()
	var before: Dictionary = g.new_campaign(rev, {"mode": "class", "players": 2})
	for crew in bad:
		_check(not State.crew_problem(crew).is_empty(), "crew_problem rejects " + str(crew))
		var tampered := before.duplicate(true)
		tampered["crew"] = crew
		_check(not State.validate_snapshot(tampered).valid, "validate_snapshot rejects " + str(crew))
		_check(not g.restore_snapshot(tampered, rev).get("accepted", true), "restore rejects " + str(crew))
		_check(g.snapshot() == before, "rejected restore leaves state unchanged: " + str(crew))
		if crew is Dictionary:
			_check(g.new_campaign(rev, crew).is_empty(), "new_campaign rejects " + str(crew))
			_check(g.snapshot() == before, "rejected new_campaign leaves state unchanged: " + str(crew))
	print("RESULT test_session_crew: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + message)
