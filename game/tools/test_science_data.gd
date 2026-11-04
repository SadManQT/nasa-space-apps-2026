extends SceneTree

const Science = preload("res://scripts/science/science_data.gd")
const Host = preload("res://scripts/puzzles/puzzle_host.gd")
const Panels = preload("res://scenes/ui/campaign_panels.tscn")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var science := Science.new()
	var validation := science.validate()
	_check(validation.valid, "all puzzles and fixture provenance validate: " + str(validation.errors))
	_check(validation.fixture_count == 28, "Journal lists all 28 bundled fixtures")
	for number in range(1, 17):
		var cards := science.cards_for_puzzle("P-%02d" % number)
		_check(not cards.is_empty() and not cards.any(func(card): return card.pending), "puzzle has verified cards: P-%02d" % number)
	_check(science.card("not_a_source").pending, "unknown source never gets fabricated evidence")
	for chapter in range(1, 9):
		for mission in range(1, 5):
			var id := "EX-M%02d%02d" % [chapter, mission]
			var mcard := science.mission_card(id)
			_check(not mcard.is_empty() and not String(mcard.get("plain", "")).is_empty(), "mission has a plain-language data card: " + id)
			_check(mcard.get("source_ids", []).all(func(source): return not science.card(source).pending), "mission card sources resolve to verified evidence: " + id)
			_check(mcard.get("visual", {}).get("labels", []).size() <= 3, "mission card chart keeps to three labels: " + id)
	_check(science.mission_card("EX-M9999").is_empty(), "unknown mission gets no invented card")
	var broken := Science.new("user://missing-science-fixture")
	_check(not broken.validate().valid and broken.cards_for_puzzle("P-02")[0].pending, "missing fixtures fail content validation")
	var card := science.card("lro_mazarico_2011_illumination")
	_check(card.visual.values == [36.0] and card.visual.unit == "h", "chart uses the fixture's computed value and unit")
	card.values.longest_darkness_days = 999
	_check(science.card(card.source_id).values.longest_darkness_days == 1.5, "presentation cannot mutate cached evidence")
	var flux := science.card("goes13_protons_2017_09")
	_check(flux.visual.kind == "line" and flux.visual.values[0] == flux.values.hourly[0][1], "line plots measured samples, with original order and field label")
	var host := Host.new()
	host.bind(null, "P-02", "EX-M0103", "EX-CH01-S07")
	_check(host.data_cards().size() == science.cards_for_puzzle("P-02").size(), "puzzle host shares the provenance lookup")
	root.size = Vector2i(1280, 720)
	var source := Button.new()
	root.add_child(source)
	source.grab_focus()
	var panels := Panels.instantiate()
	root.add_child(panels)
	panels.bind_query({"source_puzzle_ids": ["P-02"], "outcome": {"reason": "Recorded result"}})
	panels.set_accessibility({"large_text": true})
	panels.open_panel("journal_discovery")
	_check(_button(panels, "SOURCES · ALL DATASETS") != null, "Journal has a Sources entry")
	panels.open_panel("outcome")
	_check(_button(panels, "DATA CARDS · EVIDENCE BEHIND THESE NUMBERS") != null, "debrief exposes the same source cards")
	panels.open_panel("data_card", {"source_id": "lro_mazarico_2011_illumination"})
	await process_frame
	await process_frame
	_check(root.get_visible_rect().encloses(panels._panel.get_global_rect()), "large-text Data Card shell fits 1280x720")
	_check(_text(panels).contains("WHAT THIS MEANS FOR AURORA") and _text(panels).contains("WHAT THE GAME COMPUTED") and _text(panels).contains("ntrs.nasa.gov"), "card includes explanation, computations and citation")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	panels._unhandled_key_input(cancel)
	_check(panels.active_panel().is_empty() and root.gui_get_focus_owner() == source, "controller Back closes and restores focus")
	if OS.get_cmdline_user_args().has("--evidence"):
		panels.open_panel("data_card", {"source_id": "lro_mazarico_2011_illumination"})
		await _capture("M0-15_data_card")
		panels.open_panel("sources", {"ids": []})
		await _capture("M0-15_journal_sources")
		panels.open_panel("outcome")
		await _capture("M0-15_debrief")
	panels.free()
	source.free()
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	_check(storage.setup("science_data"), "isolate production save")
	var campaign = load("res://scenes/campaign/chapter1_campaign.tscn").instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	var before: Dictionary = campaign.director.snapshot()
	_button(campaign.hud, "DATA CARDS").pressed.emit()
	_check(campaign.hud.panels.active_panel() == "sources" and campaign.director.query().paused, "production Data Cards button opens a paused source list")
	campaign.hud.panels.open_panel("data_card", {"source_id": "fast_plants_lifecycle"})
	campaign.hud.panels.close_panel()
	_check(campaign.director.snapshot() == before, "reading and closing cards preserves the full authoritative state")
	_button(campaign.hud, "OUTCOME").pressed.emit()
	_check(campaign.hud.panels.active_panel() == "outcome", "production HUD exposes the debrief source entry")
	campaign.hud.panels.close_panel()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _capture("M0-15_campaign_hud")
	campaign.free()
	storage.cleanup()
	print("SCIENCE DATA RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/" + id + ".png"))

func _button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var found := _button(child, text)
		if found != null:
			return found
	return null

func _text(node: Node) -> String:
	var result := str(node.text) + "\n" if node is Label else ""
	for child in node.get_children():
		result += _text(child)
	return result

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)
