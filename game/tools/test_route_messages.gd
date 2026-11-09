extends SceneTree

const Director = preload("res://scripts/core/campaign_director.gd")
const Content = preload("res://scripts/content/content_loader.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Host = preload("res://scripts/puzzles/puzzle_host.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for paused in [false, true]:
		var director := Director.new()
		director.new_campaign(Content.EXPECTED_CONTENT_REVISION)
		var route := Route.new(director)
		var checkpoint: Dictionary = route._retry_checkpoint.director.duplicate(true)
		var host := Host.new()
		host.bind(director, "P-02", "EX-M0102", "EX-CH01-S05")
		var plan := {"shifts": [{"heat": "DAY", "air_production": 2, "light": "FULL", "transfer": "HOLD"}]}
		_check(bool(host.preview(plan).get("accepted", false)), "the real shift preview is accepted")
		_check(bool(host.commit("route-message-shift", plan).get("accepted", false)), "real gameplay changes after the route checkpoint")
		_check(director.query().current_shift == 1 and director.snapshot().receipts.has("route-message-shift"), "shift and receipt exist before retry")
		var messages := {"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002"], "read_ids": ["MSG-CH01-001"]}
		_check(bool(director.update_message_metadata(messages).accepted), "messages are delivered and read after the route checkpoint")
		if paused:
			route.pause("messages")
		for attempt in range(2):
			var result: Dictionary = route.retry()
			_check(bool(result.get("accepted", false)), "real route retry succeeds %s/%d" % [paused, attempt])
			_check(director.message_metadata() == messages, "route retry itself keeps delivered and read IDs")
			var expected := checkpoint.duplicate(true)
			expected["paused"] = paused
			_check(_gameplay(director.snapshot()) == _gameplay(expected), "retry restores all gameplay and retains pause state")
			_check(director.query().current_shift == 0 and not director.snapshot().receipts.has("route-message-shift"), "retry rolls back the shift and its receipt")
			_check(director._checkpoint.get("presentation_resume", {}).get("messages", {}) == messages, "the restored director checkpoint also keeps messages")
		var repeated: Dictionary = director.update_message_metadata(messages)
		_check(bool(repeated.accepted) and bool(repeated.duplicate), "retry retained metadata without a duplicate delivery")
	var fresh := Director.new()
	fresh.new_campaign(Content.EXPECTED_CONTENT_REVISION)
	var fresh_route := Route.new(fresh)
	var before: Dictionary = fresh.snapshot()
	_check(bool(fresh_route.retry().get("accepted", false)) and fresh.snapshot() == before, "retry with no messages remains a no-op")
	print("ROUTE MESSAGES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _gameplay(snapshot: Dictionary) -> Dictionary:
	var copy := snapshot.duplicate(true)
	copy.get("presentation_resume", {}).erase("messages")
	return copy

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
