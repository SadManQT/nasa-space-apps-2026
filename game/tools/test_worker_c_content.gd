## Godot --headless --path game --script res://tools/test_worker_c_content.gd
extends SceneTree

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DialogueScript = preload("res://scripts/dialogue/dialogue_service.gd")
const AudioScript = preload("res://scripts/audio/audio_runtime.gd")
const CutsceneScript = preload("res://scripts/cutscenes/cutscene_runtime.gd")
const PanelsScript = preload("res://scripts/ui/campaign_panels.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var content := ContentScript.load_full()
	_check(not content.is_empty(), "full campaign catalog loads")
	var validation := ContentScript.validate_full(content)
	_check(bool(validation.get("valid", false)), "full catalog validates source hashes, counts and predicates: " + "; ".join(validation.get("errors", [])))
	_check(String(content.get("content_revision", "")) == ContentScript.EXPECTED_CONTENT_REVISION and String(content.get("catalog_hash", "")) == ContentScript.EXPECTED_CATALOG_HASH, "campaign catalog revision and hash are frozen")
	_check(content.get("counts", {}).get("chapters", 0) == 8, "catalog contains eight chapters")
	_check(content.get("counts", {}).get("missions", 0) == 32, "catalog contains thirty-two missions")
	_check(content.get("counts", {}).get("scenes", 0) == 96, "catalog contains ninety-six scenes")
	_check(content.get("counts", {}).get("dialogue_lines", 0) == 385, "catalog contains exactly 385 dialogue lines")
	_test_ids_and_order(content)
	_test_dialogue_and_knowledge(content)
	_test_audio_and_cutscenes(content)
	await _test_panels()
	await _test_main_menu_modal_focus()
	_test_content_tamper_fixtures(content)
	print("WORKER C CONTENT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_ids_and_order(content: Dictionary) -> void:
	var chapters: Array = content.get("chapters", [])
	var missions: Array = content.get("missions", [])
	var scenes: Array = content.get("scenes", [])
	var dialogue: Array = content.get("dialogue", [])
	for chapter_index in range(chapters.size()):
		var chapter: Dictionary = chapters[chapter_index]
		_check(String(chapter.get("id", "")) == "CH%02d" % (chapter_index + 1), "chapter %d has stable order ID" % (chapter_index + 1))
		_check(chapter.get("mission_ids", []).size() == 4 and chapter.get("scene_ids", []).size() == 12, "%s declares four missions and twelve scenes" % String(chapter.get("id", "")))
	for mission_index in range(missions.size()):
		var mission: Dictionary = missions[mission_index]
		var expected_mission := "EX-M%02d%02d" % [int(mission.get("chapter_number", 0)), int(mission.get("order", 0))]
		_check(String(mission.get("id", "")) == expected_mission, "mission order remains canonical: " + expected_mission)
		_check(mission.get("scene_ids", []).size() == 3, expected_mission + " has three ordered scene IDs")
	for scene_index in range(scenes.size()):
		var scene: Dictionary = scenes[scene_index]
		var expected_scene := "EX-CH%02d-S%02d" % [int(scene.get("chapter_number", 0)), int(scene.get("order", 0))]
		_check(String(scene.get("id", "")) == expected_scene, "scene order remains canonical: " + expected_scene)
		_check(not String(scene.get("legacy_scene", "")).is_empty(), expected_scene + " retains legacy provenance only")
		_check(not scene.get("source_refs", []).is_empty() and not String(scene.get("evidence_tag", "")).is_empty(), expected_scene + " retains source/evidence labels")
	var nested_count := 0
	for scene in scenes:
		nested_count += scene.get("dialogue", []).size()
	_check(nested_count == 385, "nested scene dialogue totals 385")
	_check(dialogue.size() == 385, "global dialogue order totals 385")
	_check(ContentScript.scene_by_id(content, "EX-CH08-S12").get("title", "") == "What We Grew", "scene lookup resolves the final canonical scene")
	_check(ContentScript.mission_by_id(content, "EX-M0504").get("scene_ids", []).size() == 3, "mission lookup resolves a three-scene mission")

func _test_dialogue_and_knowledge(content: Dictionary) -> void:
	var service = DialogueScript.new(content)
	var exact := service.dialogue_by_id("EX-CH01-S01-L01")
	_check(String(exact.get("text", "")) == "A full battery sounds like a good problem.", "dialogue text is exact")
	_check(String(exact.get("speaker_id", "")) == "kai" and String(exact.get("origin", "")) == "live", "speaker identity and origin are stable")
	var stored := service.dialogue_by_id("EX-CH01-S12-L02")
	_check(String(stored.get("speaker_id", "")) == "n_initial" and String(stored.get("origin_label", "")) == "STORED RECORDING", "N. stays an identified recording origin, not a live call")
	var before_reveal: Array = service.lines_for_scene("EX-CH05-S12", [])
	var after_reveal: Array = service.lines_for_scene("EX-CH05-S12", ["noor_identity_revealed"])
	_check(before_reveal.size() == 3 and after_reveal.size() == 4, "future Noor text is gated by the acquired identity flag")
	var leaked := false
	for line in before_reveal:
		if String(line.get("text", "")).contains("Thank you for asking"):
			leaked = true
	_check(not leaked, "future knowledge text is not exposed before acquisition")
	var live_before_relay: Array = service.lines_for_scene("EX-CH08-S10", ["noor_identity_revealed"])
	var live_after_relay: Array = service.lines_for_scene("EX-CH08-S10", ["noor_identity_revealed", "relay_local_verified", "relay_earth_verified"])
	_check(live_before_relay.size() == 3 and live_after_relay.size() == 4, "first live Noor voice waits for both relay flags")
	var caption := service.caption_for_line("EX-CH08-S10-L01", ["noor_identity_revealed", "relay_local_verified", "relay_earth_verified"])
	_check(String(caption.get("text", "")) == "Hello, Aurora. This is Noor.", "caption service preserves the exact first live line")
	var ack := service.acknowledgement_command("EX-CH01-S01-L01", 0, "EX-M0101", "EX-CH01-S01")
	_check(String(ack.get("verb", "")) == "acknowledge_line" and not bool(ack.get("completes_predicate", true)), "acknowledgement is a dialogue-only command")
	_check(not ack.get("payload", {}).has("knowledge_flag"), "acknowledgement does not grant future knowledge")
	for predicate in content.get("predicates", []):
		_check(not bool(predicate.get("requires_dialogue_acknowledgement", true)), "predicate does not depend on dialogue acknowledgement: " + String(predicate.get("id", "")))

func _test_audio_and_cutscenes(content: Dictionary) -> void:
	# Exercise the missing-file contract even after production VO is installed.
	var missing_voice_fixture := content.duplicate(true)
	for line in missing_voice_fixture.get("dialogue", []):
		if String(line.get("id", "")) == "EX-CH01-S01-L01":
			line["voice_file"] = "res://__missing_test_fixture__/voice.ogg"
	var audio = AudioScript.new(missing_voice_fixture)
	var voice := audio.voice_plan("EX-CH01-S01-L01")
	_check(String(voice.get("mode", "")) == "captions_only" and not bool(voice.get("media_present", true)), "missing runtime voice truthfully falls back to captions")
	var audio_fixture := content.duplicate(true)
	audio_fixture["dialogue"][0]["voice_file"] = "res://assets/cutscenes/CS-01_Arrival.ogv"
	var audio_with_wrong_extension = AudioScript.new(audio_fixture, {"audio": {"voice_runtime_files_present": true, "music_runtime_files_present": true, "sfx_runtime_files_present": true, "music_runtime_files": ["res://missing.mp3"], "sfx_runtime_files": ["res://missing.wav"]}})
	_check(String(audio_with_wrong_extension.voice_plan("EX-CH01-S01-L01").get("mode", "")) == "captions_only", "voice metadata cannot promote a non-audio extension")
	_check(not audio_with_wrong_extension.has_runtime_music() and not audio_with_wrong_extension.has_runtime_sfx(), "music and SFX availability require supported existing files, not metadata booleans")
	var cutscene = CutsceneScript.new(content)
	var available: Array = cutscene.available_cutscenes()
	_check(available.size() == 18, "runtime metadata lists all 18 installed OGVs (CS-01..CS-18)")
	var cs01 := cutscene.playback_plan("CS-01", "EX-CH01-S01")
	_check(String(cs01.get("mode", "")) == "video" and bool(cs01.get("media_present", false)), "installed CS-01 OGV is reported as playable media")
	var cs04 := cutscene.playback_plan("CS-04", "EX-CH02-S12")
	_check(String(cs04.get("mode", "")) == "video" and bool(cs04.get("media_present", false)), "installed CS-04 OGV is reported as playable media")
	var gone = CutsceneScript.new(content, {"available_cutscenes": [{"id": "CS-GONE", "scene_id": "EX-CH02-S12", "runtime_path": "res://assets/cutscenes/CS-GONE.ogv", "runtime_format": "ogv", "media_present": true}]})
	var missing: Dictionary = gone.playback_plan("CS-GONE", "EX-CH02-S12")
	_check(String(missing.get("mode", "")) == "text_fallback" and not bool(missing.get("media_present", true)), "missing cutscene file uses truthful text fallback even when metadata claims it")
	var cutscene_fixture = CutsceneScript.new(content, {"available_cutscenes": [{"id": "CS-BAD", "scene_id": "EX-CH01-S01", "runtime_path": "res://assets/cutscenes/CS-01_Arrival.ogv", "runtime_format": "mp4", "media_present": true}]})
	_check(String(cutscene_fixture.playback_plan("CS-BAD", "EX-CH01-S01").get("mode", "")) == "text_fallback", "cutscene playback requires the supported OGV runtime format")
	var missing_file_fixture = CutsceneScript.new(content, {"available_cutscenes": [{"id": "CS-MISSING", "scene_id": "EX-CH01-S01", "runtime_path": "res://missing.ogv", "runtime_format": "ogv", "media_present": true}]})
	_check(String(missing_file_fixture.playback_plan("CS-MISSING", "EX-CH01-S01").get("mode", "")) == "text_fallback", "cutscene playback requires an existing runtime file")
	var skipped := cutscene.skip("CS-01", "EX-CH01-S01")
	_check(bool(skipped.get("skipped", false)) and not bool(skipped.get("completes_predicate", true)) and not bool(skipped.get("completes_scene", true)), "cutscene skip never completes a predicate")

func _test_panels() -> void:
	var panels = PanelsScript.new()
	get_root().add_child(panels)
	await process_frame
	var query := {
		"state_revision": 4,
		"mission_id": "EX-M0101",
		"scene_id": "EX-CH01-S01",
		"accessibility": {"captions": true, "large_text": false, "timer_free": true, "reduced_motion": false},
	}
	panels.bind_query(query)
	var emitted: Array = []
	panels.command_emitted.connect(func(command: Dictionary) -> void: emitted.append(command))
	var before := panels.query_snapshot()
	var command := panels.emit_command("acknowledge_line", "EX-CH01-S01-L01", {"line_id": "EX-CH01-S01-L01", "dialogue_only": true})
	_check(command.get("expected_state_revision", -1) == 4 and String(command.get("verb", "")) == "acknowledge_line", "UI emits the frozen primitive command fields")
	_check(panels.query_snapshot() == before, "UI command emission does not mutate the read-only query")
	_check(emitted.size() == 1 and not bool(command.get("completes_predicate", false)), "UI emits one dialogue command without a completion claim")
	_check(panels.accessibility_settings().get("captions", false) and panels.accessibility_settings().get("timer_free", false), "captions-on and timer-free accessibility defaults are present")
	for panel_id in PanelsScript.PANEL_IDS:
		_check(panels.open_panel(panel_id), "data-driven panel opens: " + panel_id)
		panels.close_panel()
	panels.set_accessibility({"large_text": true, "reduced_motion": true})
	_check(panels.accessibility_settings().get("large_text", false) and panels.accessibility_settings().get("reduced_motion", false), "large-text and reduced-motion settings are bindable")
	var focus_source := Button.new()
	focus_source.text = "Focus source"
	focus_source.focus_mode = Control.FOCUS_ALL
	get_root().add_child(focus_source)
	focus_source.grab_focus()
	await process_frame
	_check(get_root().gui_get_focus_owner() == focus_source, "panel focus regression has a focused pre-open control")
	_check(panels.open_panel("credits"), "panel opens from a focused control")
	_check(get_root().gui_get_focus_owner() == panels._close_button, "panel moves focus into its modal close control")
	panels.close_panel()
	await process_frame
	_check(get_root().gui_get_focus_owner() == focus_source, "panel close restores the pre-open focus")
	focus_source.free()
	panels.queue_free()
	await process_frame
	await _test_existing_menu(query)

func _test_existing_menu(query: Dictionary) -> void:
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	get_root().add_child(menu)
	await process_frame
	menu.bind_query(query)
	var menu_before: Dictionary = menu.query_snapshot()
	var menu_command: Dictionary = menu.emit_command("open_panel", "credits")
	_check(menu.query_snapshot() == menu_before and String(menu_command.get("issuer", "")) == "main_menu", "existing menu binds a read-only query and emits commands")
	menu.queue_free()
func _test_main_menu_modal_focus() -> void:
	var menu: MainMenu = load("res://scenes/ui/main_menu.tscn").instantiate()
	get_root().add_child(menu)
	await process_frame
	var nested: Button = menu._continue_button
	nested.grab_focus()
	await process_frame
	menu.open_science()
	var science_close: Button = menu._science.get_node("Margin/Content/BackToTitle")
	_check(nested.disabled and nested.focus_mode == Control.FOCUS_NONE, "main menu modal recursively disables nested background controls")
	_check(not science_close.disabled and science_close.focus_mode != Control.FOCUS_NONE, "main menu modal keeps nested modal controls focusable")
	menu.close_science()
	await process_frame
	_check(not nested.disabled and get_root().gui_get_focus_owner() == nested, "main menu modal close restores the prior nested-control focus")
	menu.open_panel("credits")
	_check(nested.disabled and nested.focus_mode == Control.FOCUS_NONE, "campaign panel also traps focus from nested main-menu controls")
	menu.get_node("CampaignPanels").close_panel()
	await process_frame
	_check(not nested.disabled and get_root().gui_get_focus_owner() == nested, "campaign panel close restores main-menu focus safely")
	menu.queue_free()
	await process_frame

func _test_content_tamper_fixtures(content: Dictionary) -> void:
	var tampered := content.duplicate(true)
	tampered["content_revision"] = "tampered-revision"
	_check(not bool(ContentScript.validate_full(tampered).get("valid", true)), "tampered campaign catalog revision is rejected")
	var malformed := content.duplicate(true)
	malformed["chapters"] = null
	_check(not bool(ContentScript.validate_full(malformed).get("valid", true)), "malformed/null campaign JSON types are rejected without trusting stale metadata")
	_check(not bool(ContentScript.validate_full(null).get("valid", true)), "null campaign JSON is rejected safely")
	var dialogue_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign/dialogue_catalog.json")) as Dictionary
	var dialogue_tampered: Dictionary = dialogue_catalog.duplicate(true)
	dialogue_tampered["content_revision"] = "tampered-revision"
	_check(not bool(ContentScript.validate_dialogue_catalog(dialogue_tampered).get("valid", true)), "tampered dialogue catalog revision/hash is rejected")
	_check(not bool(ContentScript.validate_full(content, dialogue_tampered).get("valid", true)), "full validation rejects a tampered dialogue catalog")
	_check(String(dialogue_catalog.get("content_revision", "")) == ContentScript.EXPECTED_CONTENT_REVISION and String(dialogue_catalog.get("catalog_hash", "")) == ContentScript.EXPECTED_DIALOGUE_CATALOG_HASH, "dialogue catalog revision and hash are frozen")
	_check(bool(ContentScript.validate_dialogue_catalog(dialogue_catalog).get("valid", false)), "checked-in dialogue catalog hash and revision validate")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
