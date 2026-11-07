## Expedition Journal v1 (M1-48): the pure journal view model and its spoiler
## rules, the "Previously at Aurora" resume card, the four-tab panel, and the
## HUD entry points. Headless; the windowed screenshots come from
## tools/capture_journal_m148.gd.
extends SceneTree

const Director = preload("res://scripts/core/campaign_director.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Content = preload("res://scripts/content/content_loader.gd")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const State = preload("res://scripts/core/campaign_state.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
const Panels: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var checks := 0
var failures := 0
var _journals := {}
var _snapshots := {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	_test_pure_and_spoiler_free()
	_test_gate_flags_and_links()
	_test_legacy_records_and_empty_snapshot()
	await _test_panel()
	await _test_campaign_entry_points()
	print("JOURNAL TABS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

## Mirrors Chapter1Campaign._sync_route_projection for route-only fixtures.
func _sync(director: Director, route: Route) -> void:
	var next := director.snapshot()
	next["scene_id"] = route.current_scene_id()
	next["mission_id"] = route.current_mission_id()
	for scene_id in route.completed_scene_ids():
		if not next.completed_scene_ids.has(scene_id):
			next.completed_scene_ids.append(scene_id)
	director.restore_snapshot(next)

func _record_choice(director: Director, route: Route, scene_id: String, option_id: String) -> bool:
	var query := director.query()
	var result := director.commit({
		"command_id": "test:choice:" + scene_id, "issuer": "test", "owning_mission_id": route.current_mission_id(),
		"owning_scene_id": scene_id, "expected_state_revision": int(query.state_revision), "target_id": scene_id + "-CHOICE",
		"verb": "record_choice", "payload": {"choice_id": scene_id + "-CHOICE", "option_id": option_id},
	})
	return bool(result.get("accepted", false))

func _allowed(snapshot: Dictionary, scene_id: String) -> bool:
	return scene_id == snapshot.scene_id or snapshot.completed_scene_ids.has(scene_id) or snapshot.acquired_evidence_ids.has(scene_id)

func _scene_number(scene_id: String) -> int:
	return int(scene_id.get_slice("-S", 1)) if scene_id.begins_with("EX-CH01-S") else 99

## Every journal entry belongs to a completed, acquired or current scene, and the
## resume card quotes nothing written for a later scene.
func _assert_spoiler_free(label: String, snapshot: Dictionary, journal: Dictionary) -> void:
	var current := _scene_number(String(snapshot.scene_id))
	var entries: Array = journal.get("entries", [])
	_check(entries.all(func(entry): return _allowed(snapshot, String(entry.get("scene_id", "")))), label + ": every entry's scene is completed, acquired or current")
	_check(entries.all(func(entry): return _scene_number(String(entry.get("scene_id", ""))) <= current), label + ": no entry comes from a later scene")
	for tab in ["now", "evidence", "garden", "decisions"]:
		_check(journal.tabs.has(tab) and journal.tabs[tab].get("entries", []) is Array, label + ": tab " + tab + " present")
	var resume: Array = journal.get("resume", [])
	_check(resume.size() <= 6, label + ": resume card has at most six lines")
	var resume_text := "\n".join(resume)
	var leaked := false
	for entry in CampaignKnowledge.journal_text().get("entries", []):
		if _scene_number(String(entry.get("scene_id", ""))) > current and String(entry.get("type", "")) != "resume_template":
			for key in ["title", "body", "objective_text", "completed_text"]:
				var text := String(entry.get(key, "")).strip_edges()
				if text.length() > 12 and resume_text.contains(text):
					leaked = true
					push_error("Resume leaked future text: " + text)
	for scene in Content.load_full().get("scenes", []):
		if _scene_number(String(scene.get("id", ""))) > current and resume_text.contains(String(scene.get("title", "###"))):
			leaked = true
	_check(not leaked, label + ": resume lines contain no text from a future scene")
	_check(not JSON.stringify(journal).contains("Noor"), label + ": journal never spells the gardener's name in Chapter 1")

func _test_pure_and_spoiler_free() -> void:
	var director := Director.new()
	director.new_campaign(Content.EXPECTED_CONTENT_REVISION)
	var route := Route.new(director)
	PlanFixture.prepare(route)
	_sync(director, route)
	var fresh := director.snapshot()
	var before := JSON.stringify(fresh)
	var first := CampaignKnowledge.journal(fresh)
	_check(JSON.stringify(fresh) == before, "journal() never mutates the snapshot")
	_check(JSON.stringify(CampaignKnowledge.journal(fresh)) == JSON.stringify(first), "journal() is deterministic for the same snapshot")
	_check(first.tabs.now.objective.get("scene_title") == "Sunlight We Cannot Keep" and first.tabs.evidence.entries.is_empty() and first.tabs.garden.plants.is_empty() and first.tabs.decisions.entries.is_empty(), "a new expedition shows only its first objective")
	_check(first.resume.size() == 2 and String(first.resume[0]).begins_with("Aurora · Commons · 11 April 2046 · 06:00 UTC") and String(first.resume[1]).begins_with("Now: Trace where the spare sunlight goes"), "new-expedition resume card: where/when and the objective only")
	_check(first.tabs.now.hints.levels == ["Follow the arrow after the battery is full.", "A full store cannot take more; a tank or a lamp can still use it.", "Route the spare to the air tank or to the bay lamp, then compare both with spilling it."], "S01 hint ladder quotes doc 22 §3.1 energy route")
	_assert_spoiler_free("S01 start", fresh, first)
	var scenes := Gates.scene_ids()
	for index in scenes.size():
		var scene_id: String = scenes[index]
		_sync(director, route)
		_check(_record_choice(director, route, scene_id, scene_id + ("-OPT01" if index % 2 == 0 else "-OPT02")), scene_id + " choice recorded for the journal")
		var targets := Gates.targets_for_scene(scene_id)
		if scene_id == "EX-CH01-S03":
			targets.push_back(targets.pop_front())
			var compare: Dictionary = targets.pop_at(3)
			targets.push_back(compare)
		for target in targets:
			if scene_id == "EX-CH01-S05" and target.target_id == "confirm_date_transition":
				var mid := director.snapshot()
				mid["scene_id"] = scene_id
				var mid_journal := CampaignKnowledge.journal(mid)
				_check(not mid_journal.tabs.garden.entries.any(func(entry): return entry.get("id") == "J-CH01-S05-GROWTH-ALO-SPROUT"), "12 April photo waits until the dated transition passes")
			var result: Dictionary = route.perform(String(target.target_id))
			_check(bool(result.get("accepted", false)), scene_id + " performs " + String(target.target_id))
		_sync(director, route)
		var snapshot := director.snapshot()
		var journal := CampaignKnowledge.journal(snapshot)
		_snapshots[scene_id] = snapshot
		_journals[scene_id] = journal
		_assert_spoiler_free(scene_id + " after targets", snapshot, journal)
		_check(journal.tabs.decisions.entries.size() == index + 1, scene_id + " Decisions tab lists one entry per confirmed choice")
		var advanced: Dictionary = route.advance_scene()
		_check(bool(advanced.get("accepted", false)), scene_id + " advances")
	_sync(director, route)
	var complete := director.snapshot()
	var done := CampaignKnowledge.journal(complete)
	_assert_spoiler_free("chapter complete", complete, done)
	# S03: the Evidence board and the first open question.
	var s03: Dictionary = _journals["EX-CH01-S03"]
	var columns: Dictionary = s03.tabs.evidence.columns
	_check(columns.observed.any(func(e): return e.title == "Seed packet" and e.status == "OBSERVED" and e.type == "clue"), "S03 Observed holds the seed packet clue")
	_check(columns.inferred.size() == 1 and columns.inferred[0].title == "Planned two-chamber test", "S03 Inferred holds the two-chamber interpretation")
	_check(columns.unknown.map(func(e): return e.title) == ["Who is N.?", "Why only two seeds?", "Why the name Alo?"], "S03 Unknown lists the three questions in pack order")
	_check(columns.observed[0].links.any(func(link): return link.title == "Who is N.?"), "a clue threads to the question it raises")
	_check(s03.resume.back() == "Open question: Who is N.?", "S03 resume ends on the newest open question")
	_check(s03.tabs.now.completed.size() == 2 and s03.tabs.now.completed[0].scene_id == "EX-CH01-S02", "Now lists the last completed tasks newest first")
	_check(s03.tabs.now.hints.levels == ["Check the instrument before trusting it.", "Use the two reference cups.", "Dry must read 0, wet 100, then fill both to 50."], "S03 hint ladder quotes 08 P-01 word for word")
	_check(s03.tabs.garden.plants.is_empty() and s03.resume.all(func(line): return not String(line).begins_with("Garden:")), "nothing grows in the journal before the planting")
	_check(s03.tabs.decisions.entries[0].chose == "Store air" and s03.tabs.decisions.entries[0].did == "The air gauge rises in this exercise." and s03.tabs.decisions.entries[0].echoes.is_empty(), "D1 shows what we chose and what it did, with no future echo")
	# S04: the Growth Record opens in the chosen layout.
	var s04: Dictionary = _journals["EX-CH01-S04"]
	_check(s04.tabs.garden.layout == "paired_conditions" and s04.tabs.garden.layout_chosen, "D2 OPT02 opens the Growth Record as a paired conditions table")
	_check(s04.tabs.garden.plants.size() == 2 and s04.tabs.garden.records.size() == 1 and s04.tabs.garden.records[0].frames.has("ALO-01") and s04.tabs.garden.records[0].frames.has("TARA-01"), "planting day records both plants")
	_check(s04.tabs.garden.lifecycle.markers == {"ALO-01": 0, "TARA-01": 0} and s04.tabs.garden.lifecycle.stages.back().label == "ripe seeds", "life-cycle markers start at seed and the track ends at seeds")
	# S05: dated photos after the transition; S12: the bloom, the ending, the garden line.
	var s05: Dictionary = _journals["EX-CH01-S05"]
	_check(s05.tabs.garden.records.map(func(r): return r.date) == ["2046-04-11", "2046-04-12", "2046-04-18"], "the 12 and 18 April photos appear once the care montage passes")
	_check(s05.resume.any(func(line): return line == "Garden: Alo in bud, outside; Tara in bud, inside."), "S05 resume garden line uses the stage phrases")
	_check(s05.tabs.now.hints.source == "Mission card steps" and s05.tabs.now.hints.levels.size() == 3, "a scene without authored hints falls back to its mission-card steps")
	var s07: Dictionary = _journals["EX-CH01-S07"]
	_check(s07.tabs.now.hints.levels == CampaignKnowledge.p02_table().hints, "P-02 scenes share the Mission Table's hint text")
	_check(not s07.tabs.evidence.entries.any(func(e): return e.id == "J-CH01-S07-TARGET-P02-STAGE-SHIFT2"), "the preview-only staged shift has no receipt while S07 is open")
	_check(_journals["EX-CH01-S08"].tabs.evidence.entries.any(func(e): return e.id == "J-CH01-S07-TARGET-P02-STAGE-SHIFT2"), "the preview-only staged shift appears once its scene is complete")
	var s12: Dictionary = _journals["EX-CH01-S12"]
	_check(s12.tabs.decisions.outcome.get("ending") == "BLOOM" and s12.tabs.decisions.outcome.get("title") == "BLOOM", "Night One outcome comes from the final P-02 receipt and the table data")
	_check(s12.tabs.evidence.columns.observed.any(func(e): return e.title == "A recording, not a call"), "S12 records the stored message as a clue")
	_check(s12.resume.any(func(line): return line == "Garden: Alo in flower, outside; Tara in bud, inside.") and s12.resume.back() == "Open question: Why does Alo need a friend?", "S12 resume: flower, bud and the newest question")
	_check(String(s12.resume[0]).ends_with("27 April 2046 · dawn after shift 7."), "S12 resume names the dawn after the seventh shift")
	_check(done.tabs.now.objective.state == "complete" and done.resume.any(func(line): return String(line).begins_with("Now: Alo Needs a Friend is complete")), "chapter complete is stated, not hidden")
	_check(String(s12.tabs.garden.records.back().frames["ALO-01"].stage_id) == "bloom", "the bloom photo is the newest Growth Record frame")

func _test_gate_flags_and_links() -> void:
	var pack := {"entries": [
		_entry("T-A", "clue", "OBSERVED", "Visible clue", "EX-CH01-S01", ["T-GATED", "T-FUTURE"], ""),
		_entry("T-GATED", "fact", "VERIFIED", "The gardener's name", "EX-CH01-S01", [], "noor_identity_revealed"),
		_entry("T-FUTURE", "clue", "OBSERVED", "A later clue", "EX-CH01-S02", [], ""),
		_entry("T-KEYWORD", "clue", "OBSERVED", "A noor-shaped word with no gate", "EX-CH01-S01", [], ""),
	]}
	var snapshot := State.new_snapshot()
	snapshot["scene_id"] = "EX-CH01-S01"
	snapshot["completed_scene_ids"] = []
	var journal := CampaignKnowledge.journal(snapshot, pack)
	var ids: Array = journal.entries.map(func(e): return e.id)
	_check(ids == ["T-A", "T-KEYWORD"], "entries are gated by gate_flag, never by keyword: " + str(ids))
	_check(journal.entries[0].links.is_empty(), "links to hidden entries are suppressed")
	snapshot.knowledge_flags.append("noor_identity_revealed")
	journal = CampaignKnowledge.journal(snapshot, pack)
	ids = journal.entries.map(func(e): return e.id)
	_check(ids == ["T-A", "T-GATED", "T-KEYWORD"], "the gated entry appears once its flag is known")
	_check(journal.entries[0].links.map(func(l): return l.id) == ["T-GATED"], "a revealed link is named; a future one still is not")

func _entry(id: String, type: String, status: String, title: String, scene_id: String, links: Array, gate: String) -> Dictionary:
	return {"id": id, "tab": "evidence", "type": type, "status": status, "title": title, "body": "Body of " + title + ".", "date": "2046-04-11 06:00 UTC",
		"scene_id": scene_id, "source": "test", "evidence_label": "Fiction", "links": links, "gate_flag": gate, "superseded_by": "",
		"trigger": {"on": "scene_active", "scene_id": scene_id}, "surface": "journal", "target_id": ""}

func _test_legacy_records_and_empty_snapshot() -> void:
	var snapshot: Dictionary = _snapshots["EX-CH01-S12"].duplicate(true)
	snapshot.acquired_evidence_ids.append("EX-CH02-S01")
	snapshot.knowledge.append({"id": "EX-CH02-S01", "title": "Later record", "evidence_label": "Simulated", "observations": [{"id": "op", "text": "Operation label"}]})
	var journal := CampaignKnowledge.journal(snapshot)
	var record: Array = journal.tabs.evidence.columns.observed.filter(func(e): return e.id == "REC-EX-CH02-S01")
	_check(record.size() == 1 and record[0].type == "record" and record[0].body == "Operation label", "scenes without written entries keep their operation records")
	_check(journal.tabs.evidence.entries.filter(func(e): return e.scene_id == "EX-CH01-S03" and e.type == "record").is_empty(), "written scenes do not duplicate their operation records")
	var empty := CampaignKnowledge.journal({})
	_check(empty.tabs.now.objective.is_empty() and empty.entries.is_empty() and empty.resume.is_empty(), "an empty snapshot yields an empty, well-formed journal")
	_check(CampaignKnowledge.format_date("2046-04-11 10:00 UTC") == "11 April 2046 · 10:00 UTC" and CampaignKnowledge.format_date("2046-04-24 UTC") == "24 April 2046" and CampaignKnowledge.format_date("2046-04-11 late morning UTC") == "11 April 2046 · late morning", "dates read in plain words")

func _test_panel() -> void:
	var panels := Panels.instantiate() as CampaignPanels
	root.add_child(panels)
	panels.set_content_top(226)
	var s03: Dictionary = _journals["EX-CH01-S03"]
	panels.bind_query({"journal_entries": s03, "scene_id": "EX-CH01-S03", "state_revision": 3})
	_check(panels.open_journal("now"), "journal opens on the Now tab")
	await process_frame
	await process_frame
	var tabs := panels._side.find_children("Tab_*", "Button", false, false)
	_check(tabs.size() == 4 and tabs.all(func(tab): return tab.size.y >= 44.0 and tab.size.x >= 44.0), "four tab buttons at least 44 px tall")
	_check(root.gui_get_focus_owner() != null and root.gui_get_focus_owner().name == "Tab_now", "keyboard focus lands on the open tab")
	_check(String(tabs[0].text).begins_with("› "), "the open tab carries a non-colour marker")
	_check(root.get_visible_rect().encloses(panels._panel.get_global_rect()), "journal shell fits 1280x720")
	_check(tabs[0].focus_neighbor_bottom == tabs[1].get_path() and tabs[3].focus_neighbor_bottom == tabs[0].get_path(), "tab focus order runs Now → Evidence → Garden → Decisions and wraps")
	var down := InputEventAction.new()
	down.action = "ui_down"
	down.pressed = true
	Input.parse_input_event(down)
	Input.flush_buffered_events()
	await process_frame
	_check(root.gui_get_focus_owner() != null and root.gui_get_focus_owner().name == "Tab_evidence", "ui_down moves focus to the next tab")
	var reveal := panels._body.get_node_or_null("RevealHint") as Button
	_check(reveal != null and not _text(panels._body).contains("Check the instrument"), "Journal hides every hint until asked")
	reveal.grab_focus()
	reveal.pressed.emit()
	await process_frame
	_check(panels.hint_player.is_open() and panels.hint_player.level == 1 and _text(panels.hint_player).contains("Check the instrument before trusting it.") and not _text(panels.hint_player).contains("Dry must read 0"), "Journal preserves the authored nudge without canonical answer")
	panels.hint_player.close()
	_check(root.gui_get_focus_owner() == reveal, "closing shared hint restores the Journal request button")
	panels.select_journal_tab("evidence")
	await process_frame
	var holder := panels._body.get_node_or_null("EvidenceColumns")
	_check(holder is HBoxContainer and holder.get_child_count() == 3, "Evidence shows Observed, Inferred and Unknown side by side")
	_check(_text(holder.get_node("Column_observed")).contains("• OBSERVED · 12") and _text(holder.get_node("Column_unknown")).contains("Who is N.?"), "column headers carry status words and counts")
	panels.set_accessibility({"large_text": true})
	await process_frame
	await process_frame
	holder = panels._body.get_node_or_null("EvidenceColumns")
	_check(holder is VBoxContainer, "at 150% text the three columns stack for reflow")
	var title: Label = null
	for label in panels._body.find_children("Title", "Label", true, false):
		if label.text == "Seed packet":
			title = label
	_check(title != null and title.get_theme_font_size("font_size") == 24, "clue titles scale to 150%")
	_check(root.get_visible_rect().encloses(panels._panel.get_global_rect()) and root.get_visible_rect().encloses(panels._close_button.get_global_rect()), "large-text journal keeps its shell and close control on screen")
	panels.set_accessibility({"large_text": false})
	panels.close_panel()
	panels.bind_query({"journal_entries": _journals["EX-CH01-S04"], "scene_id": "EX-CH01-S04", "state_revision": 4})
	panels.open_journal("garden")
	await process_frame
	_check(_text(panels._body).contains("GROWTH RECORD · PAIRED CONDITIONS TABLE") and panels._body.get_node_or_null("GrowthTable") is GridContainer, "Garden opens in the chosen table layout")
	var toggle := panels._body.get_node_or_null("GrowthLayoutToggle") as Button
	_check(toggle != null and toggle.text == "VIEW AS PAIRED PHOTOGRAPHS", "the other layout is one tap away")
	toggle.pressed.emit()
	await process_frame
	_check(panels._body.get_node_or_null("GrowthTable") == null and _text(panels._body).contains("GROWTH RECORD · PAIRED PHOTOGRAPHS") and _text(panels._body).contains("ALO · SEED"), "the photo strip shows dated frames per plant")
	_check(_text(panels._body.get_node("LifecycleTrack")).contains("› ALO + TARA ‹") and _text(panels._body.get_node("LifecycleTrack")).contains("ripe seeds"), "life-cycle track marks both plants by name at seed and ends at ripe seeds")
	panels.close_panel()
	panels.open_journal("garden")
	await process_frame
	_check(panels._body.get_node_or_null("GrowthTable") is GridContainer, "reopening returns to the chosen layout")
	panels.close_panel()
	panels.bind_query({"journal_entries": s03, "scene_id": "EX-CH01-S03", "state_revision": 3})
	panels.open_panel("pause")
	await process_frame
	_check(panels._body.get_child(0) is Button and (panels._body.get_child(0) as Button).text == "Resume", "pause leads with Resume (doc 25 §2.2)")
	var card := panels._body.get_node_or_null("ResumeCard")
	_check(card != null and _text(card).contains("PREVIOUSLY AT AURORA") and _text(card).contains("Open question: Who is N.?") and card.find_children("ResumeLine*", "Label", true, false).size() == s03.resume.size(), "pause shows the resume card with every line")
	panels.close_panel()
	panels.open_panel("resume")
	await process_frame
	_check(panels._close_button.text == "Continue" and _text(panels._body).contains("Now: Calibrate the moisture probe"), "the Continue card ends on a continue control")
	var open_journal := _find_button(panels._body, "OPEN THE JOURNAL · NOW")
	_check(open_journal != null, "the Continue card links to the journal")
	open_journal.pressed.emit()
	await process_frame
	_check(panels.active_panel() == "journal_discovery" and panels.journal_tab() == "now", "the Continue card opens the journal on Now")
	var all_tall := true
	for button in panels.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.size.y < 44.0:
			all_tall = false
	_check(all_tall, "every journal control is at least 44 px tall")
	panels.close_panel()
	panels.bind_query({"scene_id": "EX-CH01-S01"})
	_check(panels.open_panel("journal_discovery") and _text(panels._body).contains("Your current objective appears here"), "a query without a journal renders empty states, not errors")
	panels.close_panel()
	panels.queue_free()
	await process_frame

func _test_campaign_entry_points() -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	_check(storage.setup("journal-tabs"), "isolated save directory")
	var runtime := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(runtime)
	root.add_child(runtime)
	await process_frame
	var journal = runtime.query().get("journal_entries", null)
	_check(journal is Dictionary and journal.has("tabs") and journal.has("resume"), "the production query carries the journal view model")
	_check(runtime.hud.panels.active_panel().is_empty(), "a direct fixture never auto-opens the resume card")
	runtime.hud._on_journal_pressed()
	await process_frame
	_check(runtime.hud.panels.active_panel() == "journal_discovery" and _text(runtime.hud.panels._body).contains("Sunlight We Cannot Keep"), "the HUD JOURNAL button opens the live journal")
	runtime.hud.panels.close_panel()
	_check(runtime.hud.show_resume_card() and runtime.hud.panels.active_panel() == "resume" and bool(runtime.director.query().get("paused", false)), "the resume card opens as a pause-safe panel")
	_check(not runtime.hud.show_resume_card(), "a second resume card cannot stack on the first")
	runtime.hud.panels.close_panel()
	_check(not bool(runtime.director.query().get("paused", true)), "closing the resume card resumes the expedition")
	runtime.hud._resume_pending = true
	runtime.hud.refresh_scene()
	await process_frame
	_check(runtime.hud.panels.active_panel() == "resume" and not runtime.hud._resume_pending, "Continue shows the resume card once the scene is ready")
	runtime.hud.panels.close_panel()
	runtime.free()
	storage.cleanup()

func _text(node: Node) -> String:
	var result := String(node.text) + "\n" if node is Label or node is Button else ""
	for child in node.get_children():
		result += _text(child)
	return result

func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child as Button
		var found := _find_button(child, text)
		if found != null:
			return found
	return null

func _check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + reason)
