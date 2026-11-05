extends SceneTree
const Director = preload("res://scripts/core/campaign_director.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Extended = preload("res://scripts/missions/extended_campaign_route.gd")
const Gate = preload("res://scripts/missions/extended_gate_catalog.gd")
const Dialogue = preload("res://scripts/dialogue/dialogue_service.gd")
const Save = preload("res://scripts/save/save_service.gd")
const Content = preload("res://scripts/content/content_loader.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	_check(storage.setup("knowledge"), "isolated save directory")
	var director := Director.new()
	director.new_campaign(Content.EXPECTED_CONTENT_REVISION)
	var route := Route.new(director)
	route.start_at("EX-CH01-S03")
	var before := director.snapshot()
	_check(not route.perform("inspect_packet").accepted and director.snapshot() == before, "unready evidence operation grants nothing")
	route.p01_puzzle().apply_canonical_setup()
	for target in ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet"]:
		_check(route.perform(target).accepted, "owning evidence operation " + target)
	var acquired := director.snapshot()
	_check(acquired.acquired_evidence_ids.has("EX-CH01-S03"), "record uses its canonical content ID")
	var entries := CampaignKnowledge.journal(acquired)
	var record: Dictionary = entries.filter(func(item): return item.get("id") == "EX-CH01-S03")[0]
	_check(record.observations.any(func(item): return item.id == "inspect_packet"), "packet observation enters the journal")
	_check(not JSON.stringify(entries).contains("Noor"), "early journal exposes no future identity")
	route.perform("inspect_packet")
	_check(director.snapshot().knowledge == acquired.knowledge, "duplicate evidence does not duplicate journal observations")
	route.focus("compare_atmosphere")
	route.inspect()
	route.use()
	var previous := director.snapshot()
	_check(route.preview().accepted and director.snapshot() == previous, "preview grants no evidence or knowledge")
	var snapshot := director.snapshot()
	snapshot["scene_id"] = route.current_scene_id()
	snapshot["mission_id"] = route.current_mission_id()
	snapshot["route_runtime"] = route.snapshot()
	snapshot.route_runtime["chapter"] = 1
	var save := Save.new()
	_check(save.save(snapshot, storage.path).accepted, "evidence saves to real JSON")
	var loaded: Dictionary = save.load(storage.path)
	_check(loaded.accepted and loaded.snapshot.knowledge == snapshot.knowledge and loaded.snapshot.acquired_evidence_ids == snapshot.acquired_evidence_ids, "JSON load preserves all acquired observations")
	var session := Chapter1Campaign.restore_session(loaded.snapshot)
	_check(session.accepted and session.director.snapshot().knowledge == acquired.knowledge, "fresh route/director reconstruction preserves discoveries")
	var dialogue := Dialogue.new()
	_check(not _has(dialogue.lines_for_scene("EX-CH05-S12", []), "EX-CH05-S12-L01"), "Noor line hidden before identity evidence")
	_check(dialogue.transcript([], []).is_empty(), "backlog never lists unseen later lines")
	var backlog := dialogue.transcript([], ["EX-CH01-S01-L01"])
	_check(backlog.size() == 1 and backlog[0].text == "A full battery sounds like a good problem.", "backlog preserves exact acquired dialogue")
	var extended := Extended.new(director)
	extended.start_at("EX-CH05-S10")
	for target in Gate.targets_for_scene("EX-CH05-S10"):
		_check(extended.perform(target.target_id, target.get("payload_defaults", {})).accepted, "identity evidence " + target.target_id)
		if target.target_id != "p10_confirm_founder_role":
			_check(not director.snapshot().knowledge_flags.has("noor_identity_revealed"), "identity waits for complete consent/founder evidence")
	_check(director.snapshot().knowledge_flags.has("noor_identity_revealed"), "canonical scene reveal grants identity once")
	_check(_has(dialogue.lines_for_scene("EX-CH05-S12", director.snapshot().knowledge_flags), "EX-CH05-S12-L01"), "acquired identity unlocks exact stored text")
	_check(not _has(dialogue.lines_for_scene("EX-CH08-S10", director.snapshot().knowledge_flags), "EX-CH08-S10-L01"), "identity alone never unlocks the live voice")
	var locked := extended.acknowledge_dialogue("EX-CH05-S10-L01")
	_check(locked.accepted, "current available line acknowledges normally")
	var state := director.snapshot()
	var forbidden := director.commit({"command_id": "test:locked-live", "issuer": "test", "owning_mission_id": "EX-M0804", "owning_scene_id": "EX-CH08-S10", "expected_state_revision": state.state_revision, "target_id": "EX-CH08-S10-L01", "verb": "acknowledge_line", "payload": {"line_id": "EX-CH08-S10-L01"}})
	_check(not forbidden.accepted and director.snapshot() == state, "direct acknowledgement cannot bypass a knowledge gate")
	# Bounded relay-entry fixture: earlier source tasks delivered the compatible
	# spare and verified the four-hop surface chain. P-16 must still perform
	# the real isolation/replacement/power/bearing/echo sequence.
	var relay_entry := director.snapshot()
	relay_entry.inventories["relay_controllers"] = 1
	relay_entry.route.local_hops = ["Aurora-R1", "R1-R2", "R2-R3", "R3-summit"]
	director.restore_snapshot(relay_entry)
	for scene_id in ["EX-CH08-S07", "EX-CH08-S08", "EX-CH08-S09"]:
		extended.start_at(scene_id)
		for target in Gate.targets_for_scene(scene_id):
			_check(extended.perform(target.target_id, target.get("payload_defaults", {})).accepted, "relay evidence " + target.target_id)
	_check(director.snapshot().knowledge_flags.has("relay_local_verified") and director.snapshot().knowledge_flags.has("relay_earth_verified"), "both verified path records persist as canonical flags")
	_check(_has(dialogue.lines_for_scene("EX-CH08-S10", director.snapshot().knowledge_flags), "EX-CH08-S10-L01"), "first live Noor line unlocks after both records")
	var roundtrip: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
	var copy := Director.new()
	_check(copy.restore_snapshot(roundtrip).accepted and copy.snapshot().knowledge_flags == director.snapshot().knowledge_flags, "late knowledge flags survive JSON reconstruction")
	await _runtime_journal(loaded.snapshot)
	storage.cleanup()
	print("CAMPAIGN KNOWLEDGE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _runtime_journal(snapshot: Dictionary) -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	storage.setup("journal-runtime")
	root.size = Vector2i(1280, 720)
	var runtime := preload("res://scenes/campaign/chapter1_campaign.tscn").instantiate() as Chapter1Campaign
	storage.configure(runtime)
	runtime.initial_snapshot = snapshot
	root.add_child(runtime)
	await process_frame
	_check(runtime.query().journal_entries.any(func(entry): return entry.get("observations", []).any(func(item): return item.id == "inspect_packet")), "production query refreshes Journal from saved acquisitions")
	for large in [false, true]:
		var next := runtime.director.snapshot()
		next.accessibility.large_text = large
		runtime.director.restore_snapshot(next)
		runtime.hud.apply_accessibility()
		runtime.hud.panels.bind_query(runtime.query())
		runtime.hud.panels.open_panel("journal_discovery")
		for i in 8:
			await process_frame
		var labels := _text(runtime.hud.panels)
		_check(labels.contains("Inspect sealed packet and record") and not labels.contains("Noor"), "journal shows acquired English observations at text size " + str(large))
		var packet: Label
		for label in runtime.hud.panels._body.find_children("*", "Label", true, false):
			if label.text == "Inspect sealed packet and record":
				packet = label
		var scroll := runtime.hud.panels._body.get_parent() as ScrollContainer
		scroll.ensure_control_visible(packet)
		await process_frame
		await process_frame
		_check(scroll.get_global_rect().encloses(packet.get_global_rect()), "packet observation can be fully revealed by keyboard scrolling")
		if OS.get_cmdline_user_args().has("--evidence"):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-26_journal_%d.png" % (150 if large else 100)))
		runtime.hud.panels.close_panel()
	runtime.free()
	storage.cleanup()

func _text(node: Node) -> String:
	var result := String(node.text) + "\n" if node is Label else ""
	for child in node.get_children():
		result += _text(child)
	return result

func _has(lines: Array, id: String) -> bool:
	return lines.any(func(line): return line.id == id)

func _check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + reason)
