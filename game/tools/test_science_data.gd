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
	_test_fixture_corrections(science)
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
	_check(_button(panels, "Sources · all data cards") != null, "Journal has a Sources entry")
	panels.open_panel("outcome")
	_check(_button(panels, "Data cards · the evidence behind these numbers") != null, "debrief exposes the same source cards")
	panels.open_panel("data_card", {"source_id": "lro_mazarico_2011_illumination"})
	await process_frame
	await process_frame
	_check(root.get_visible_rect().encloses(panels._panel.get_global_rect()), "large-text Data Card shell fits 1280x720")
	_check(_text(panels).contains("What this means for Aurora") and _text(panels).contains("What the game computed") and _text(panels).contains("ntrs.nasa.gov"), "card includes explanation, computations and citation")
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
	await campaign.wait_loading()   # the campaign now builds in stages behind the loading card (perf round 3)
	var before: Dictionary = campaign.director.snapshot()
	_button(campaign.hud, "Data cards").pressed.emit()
	_check(campaign.hud.panels.active_panel() == "sources" and campaign.director.query().paused, "production Data Cards button opens a paused source list")
	campaign.hud.panels.open_panel("data_card", {"source_id": "fast_plants_lifecycle"})
	campaign.hud.panels.close_panel()
	_check(campaign.director.snapshot() == before, "reading and closing cards preserves the full authoritative state")
	_button(campaign.hud, "Last result").pressed.emit()
	_check(campaign.hud.panels.active_panel() == "outcome", "production HUD exposes the debrief source entry")
	campaign.hud.panels.close_panel()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _capture("M0-15_campaign_hud")
	campaign.free()
	storage.cleanup()
	print("SCIENCE DATA RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_fixture_corrections(science: ScienceData) -> void:
	var sky := science.card("jpl_horizons_ch1_sky")
	_check(science.cards_for_puzzle("P-02").any(func(c): return c.source_id == sky.source_id), "P-02 exposes the Chapter 1 sky card")
	_check(sky.visual.kind == "line" and sky.visual.label == "earth_elevation_deg", "Chapter 1 sky visual plots Earth elevation")
	var rows: Array = sky.values.six_hourly
	_check(sky.visual.values == rows.map(func(row): return float(row[1])), "every sky point uses the elevation column in sample order")
	var crossings: Array[String] = []
	for index in range(1, rows.size()):
		var before: Array = rows[index - 1]
		var after: Array = rows[index]
		if (float(before[1]) < 0) == (float(after[1]) < 0):
			continue
		# Fixtures use minute precision; Time requires an explicit seconds field.
		var start := Time.get_unix_time_from_datetime_string(String(before[0]).trim_suffix("Z") + ":00")
		var end := Time.get_unix_time_from_datetime_string(String(after[0]).trim_suffix("Z") + ":00")
		var fraction := -float(before[1]) / (float(after[1]) - float(before[1]))
		crossings.append(Time.get_datetime_string_from_unix_time(int(start + (end - start) * fraction)).left(10) + (" rise" if float(after[1]) > float(before[1]) else " set"))
	_check(crossings.has("2046-04-15 set") and crossings.has("2046-04-28 rise"), "plotted elevation crosses the horizon on 15 and 28 April 2046: " + str(crossings))
	var relay := science.card("jpl_horizons_ch8_relay")
	_check(relay.visual.label == "earth_elevation_deg" and relay.visual.values == relay.values.malapert_15min.map(func(row): return float(row[1])), "Chapter 8 source visual also plots elevation")
	for pair in [["EX-M0704", "pole_6hourly"], ["EX-M0803", "malapert_15min"]]:
		_check(science.mission_card(pair[0]).visual.values == relay.values[pair[1]].map(func(row): return row[1]), "rebuilt mission card preserves elevation after column reorder: " + pair[0])
	var osdr := science.card("osdr_brassica_rapa_iss").values["OSD-412"] as Dictionary
	_check(osdr.photoperiod_16_8 == true and osdr.temperature_23C == true, "OSD-412 ground protocol reports 16/8 hours and 23 C")
	var flux := science.card("goes13_protons_2017_09")
	var derived: Dictionary = {}
	for entry in flux.derived:
		derived[entry.name] = entry.value
	_check(absf(float(derived.gt10MeV_peak) - 1490.0) / 1490.0 < 0.01, "east detector peak agrees with NOAA's official 1490 pfu within 1%")
	_check(derived.gt10MeV_peak == 1493.5 and String(flux.fields_used[1]).contains("ZPGT10E"), "peak and chart identify the same east-facing channel")
	_check(derived.storm_level_end == "2017-09-14T17:25Z", "storm-level end extends beyond the 48-hour chart")
	_check([derived.storm_shift1_mean_gt10MeV, derived.storm_shift2_mean_gt10MeV, derived.storm_shift3_mean_gt10MeV, derived.storm_shift4_mean_gt10MeV] == [707.1, 1153.1, 1256.9, 937.9], "four consecutive 7.2-hour means match the east-channel source")
	_check(is_equal_approx(float(derived.shift2_over_shift1), 1.63), "second storm block ratio is recomputed without changing the game table")
	var storm := science.mission_card("EX-M0104")
	_check(storm.visual.values == flux.visual.values and String(storm.visual.labels[2]).contains("East-facing"), "mission storm chart uses the east-channel samples and label")
	var plants := science.card("fast_plants_lifecycle")
	_check(plants.visual.label == "days to flower" and plants.visual.values == [14.0] and String(plants.visual.axis).begins_with("Published fixture"), "plant chart uses the published flowering time instead of a story date")
	_check(plants.derived[0].value == 16, "authored bloom date remains available in the story-qualified metadata")

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
