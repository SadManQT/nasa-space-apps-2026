# Godot --headless --path game --script res://tools/test_how_to_clips.gd
## M1-59 / M3-66 / M3-76 (doc 25 §7, §8.3): every registered mechanic has a first-time card (title, purpose,
## at most three steps, a guided first use), a how-to clip that is registered and plays, and a moment that
## shows the card the first time it is needed. Puzzle first-time cards point only at registered mechanics.
extends SceneTree

const HowTo = preload("res://scripts/ui/how_to_card.gd")
const Explainers = preload("res://scripts/ui/science_explainers.gd")
## Doc 25 §7's list, one card id per mechanic (moving and looking share one clip).
const EXPECTED := ["move", "look", "use", "goal", "station_strip", "messages", "mission_table", "lock_shift", "payload_carrying",
	"care_photo", "evidence", "pollination_route", "recorder_history", "reference_gauge", "harvest_ledger", "eva_suit_scanner",
	"survey_markers_network", "rover_route_planner", "impact_flash", "energy_budget", "storm_shelter", "repeaters_coverage", "controller_links"]
## Cards the code itself raises on first use rather than through a goal target.
const CODE_TRIGGERS := ["move", "look", "use", "mission_table"]
const PUZZLE_FILES := ["p03_pollination", "p04_recorder_reconstruction", "p05_falling_pressure", "p06_harvest_future", "chapter4_puzzles", "chapter6_puzzles", "chapter8_puzzles"]

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var mechanics := HowTo.mechanics()
	# Clips listed under pending_render have a spec and await their final render (after the M4-20 UI polish).
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Explainers.REGISTRY))
	var pending: Array = registry.get("pending_render", [])
	for clip_id in pending:
		_check(FileAccess.file_exists(ProjectSettings.globalize_path("res://../production/explainers/howto/specs/%s.json" % clip_id)), "pending clip %s has its spec" % clip_id)
	for id in EXPECTED:
		_check(mechanics.has(id), "doc 25 mechanic %s is registered" % id)
	var clips := {}
	for id in mechanics:
		var card := HowTo.lesson(String(id))
		_check(not card.is_empty(), "%s has a card" % id)
		_check(not String(card.get("title", "")).is_empty() and not String(card.get("purpose", "")).is_empty(), "%s card has a title and purpose" % id)
		var steps: Array = card.get("steps", [])
		_check(steps.size() >= 1 and steps.size() <= 3, "%s card has one to three steps" % id)
		_check(not String(card.get("nudge", "")).is_empty(), "%s card has a guided first use" % id)
		_check(int(card.get("chapter", 0)) >= 1 and int(card.get("chapter", 0)) <= 8, "%s card names its chapter" % id)
		_check(CODE_TRIGGERS.has(id) or not card.get("first_targets", []).is_empty(), "%s card has a first-use moment" % id)
		var entry := Explainers.find(String(card.get("how_clip", "")))
		_check(entry.get("kind") == "how_to" or pending.has(String(card.get("how_clip", ""))), "%s has a registered (or pending-render) how-to clip" % id)
		if entry.get("kind") == "how_to":
			clips[entry.id] = entry
	for clip_id in clips:
		var entry: Dictionary = clips[clip_id]
		var length := float(entry.get("length_s", 0.0))
		_check(length >= 8.0 and length <= 20.5, "%s is 8-20 s" % clip_id)
		_check(not entry.get("captions", []).is_empty(), "%s has captions" % clip_id)
		_check(String(entry.path) == "res://assets/explainers/%s.ogv" % clip_id and ResourceLoader.exists(entry.path), "%s file exists" % clip_id)
		var stream := load(String(entry.path)) as VideoStream
		_check(stream != null, "%s loads as a video" % clip_id)
		if stream != null:
			var player := VideoStreamPlayer.new()
			player.stream = stream
			root.add_child(player)
			player.play()
			await process_frame
			_check(player.is_playing() and absf(player.get_stream_length() - length) < 0.5, "%s plays for its registered length" % clip_id)
			player.queue_free()
	for file in PUZZLE_FILES:
		var text := FileAccess.get_file_as_string("res://resources/campaign/content/%s.json" % file)
		_check(not text.contains("clip pending"), "%s has no pending clip" % file)
		for match in RegEx.create_from_string('"how_to": "([a-z_]+)"').search_all(text):
			_check(mechanics.has(match.get_string(1)), "%s first-time card names a registered mechanic" % file)
	_check(HowTo.first_time_for("p03_scan_tara").has("pollination_route"), "a goal target raises its mechanic's first-time card")
	_check(HowTo.reached(1).has("goal") and not HowTo.reached(1).has("controller_links"), "Journal How to lists only mechanics already reached")
	print("HOW TO CLIPS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", label)
