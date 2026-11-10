extends Control
class_name Chapter1CampaignHUD

## The flat campaign HUD (doc 25 §1–§2). While the player moves it shows one
## goal card (goal, why, chapter and story date), a marker on the goal in the
## world with its distance, a prompt on the object in reach, a message toast and
## the compact station strip when a value changes or runs low. Dialogue sits at
## the bottom centre with Next and Auto. H opens What now; Esc opens the pause
## menu; developer IDs appear only in debug builds behind F10.
## Every string the player reads is a player word (ui_text.json); simulation
## values and rules are untouched: this node only presents the runtime.

const Outpost = preload("res://scripts/ui/outpost_status.gd")
const PANELS_SCENE: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")
const MISSION_TABLE_SCENE: PackedScene = preload("res://scenes/ui/mission_table_panel.tscn")
const P01_SCENE: PackedScene = preload("res://scenes/ui/p01_panel.tscn")
const Debrief = preload("res://scripts/debrief/chapter1_debrief.gd")
const MissionTableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
const CHAPTER4_PANEL_SCENE: PackedScene = preload("res://scenes/ui/chapter4_puzzle_panel.tscn")
const Chapter4Script = preload("res://scripts/puzzles/chapter4_puzzles.gd")
const CHAPTER6_PANEL_SCENE: PackedScene = preload("res://scenes/ui/chapter6_puzzle_panel.tscn")
const Chapter6Script = preload("res://scripts/puzzles/chapter6_puzzles.gd")
const CHAPTER8_PANEL_SCENE: PackedScene = preload("res://scenes/ui/chapter8_puzzle_panel.tscn")
const Chapter8Script = preload("res://scripts/puzzles/chapter8_puzzles.gd")
const CommsServiceScript = preload("res://scripts/comms/comms_service.gd")
const CommsPanelScript = preload("res://scripts/ui/comms_panel.gd")
const EvaVisorHudScript = preload("res://scripts/eva/eva_visor_hud.gd")
const Chapter1FeedbackScript = preload("res://scripts/feedback/chapter1_feedback.gd")

var runtime: Chapter1Campaign
var panels: CampaignPanels
var mission_table: MissionTablePanel
var chapter4_panel: Chapter4PuzzlePanel
var chapter6_panel: Chapter6PuzzlePanel
var chapter8_panel: Chapter8PuzzlePanel
var p01_panel: P01Panel
var comms_service: RefCounted
var comms_panel: Control
var outpost: OutpostStatus
var eva_visor: EvaVisorHud
var payload_activity: PayloadStackActivity

# Goal card
var _goal_card: PanelContainer
var _chapter_line: Label
var _title: Label
var _why: Label
var _advance: Button
var _goal_icon: UiDesign.LineIcon
# World marker and prompt
var _marker: Marker
var _prompt: PanelContainer
var _prompt_key: Label
var _prompt_label: Label
# Toast and station strip
var _column: VBoxContainer
var _toast: PanelContainer
var _status: Label
var _toast_timer := 0.0
# Dialogue
var _dialogue_bar: PanelContainer
var _caption_speaker: Label
var _caption_count: Label
var _caption_line: Label
var _next_line: Button
var _auto_button: Button
var _auto_on := false
var _auto_timer := 0.0
# What now (content lives in the HUD; the panel layer shows it)
var _what_now_home: Control
var _what_now: VBoxContainer
var _wn_goal: Label
var _wn_why: Label
var _wn_where: Label
var _wn_hint: Label
var _targets: VBoxContainer
var _retry: Button
var _decision_review: Button
var _last_result_button: Button
var _data_cards_button: Button
# Debug overlay (F10, debug builds only)
var _debug: Label
var _debug_on := false
# State
var _last_outcome: Dictionary = {}
var _forecast: Dictionary = {}
var _forecast_key := ""
var _forecast_cache_key := ""
var _forecast_cache: Dictionary = {}
var _forecast_source := ""
var _pointer_preview := false
var _focus_preview := false
var _modal_button_states := {}
var _modal_reading := false
var _reading_was_paused := false
var _dialogue_index := 0
var _scene_id := ""
## Continue (title → saved checkpoint) opens "Previously at Aurora" once the
## world and any scene-entry film are done; direct fixtures never trigger it.
var _resume_pending := false
var _goal_info: Dictionary = {}
var _done_ids: Dictionary = {}
var _nearby_id := ""
var _marker_node: Node3D
var _chrome_hidden := false
var _pulse: Tween
var _words: Dictionary = {}

## The goal marker drawn over the world: a diamond with the distance under it.
class Marker extends Control:
	var distance_text := ""
	var dimmed := false
	var _label: Label
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(96, 44)
		size = custom_minimum_size
		_label = UiDesign.label("", "caption", "ivory")
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.position = Vector2(0, 22)
		_label.size = Vector2(96, 20)
		_label.add_theme_color_override("font_outline_color", UiDesign.colour("ink"))
		_label.add_theme_constant_override("outline_size", 4)
		add_child(_label)
	func set_distance(text: String) -> void:
		distance_text = text
		_label.text = text
	func _draw() -> void:
		var centre := Vector2(48, 10)
		var r := float(UiDesign.tokens().get("world_marker", {}).get("size_px", 14)) * 0.5
		var tone := UiDesign.colour("accent")
		if dimmed:
			tone.a = 0.6
		draw_colored_polygon(PackedVector2Array([centre + Vector2(0, -r), centre + Vector2(r, 0), centre + Vector2(0, r), centre + Vector2(-r, 0)]), Color(UiDesign.colour("ink"), 0.55))
		draw_polyline(PackedVector2Array([centre + Vector2(0, -r), centre + Vector2(r, 0), centre + Vector2(0, r), centre + Vector2(-r, 0), centre + Vector2(0, -r)]), tone, 2.0, true)
		draw_circle(centre, 2.5, tone)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_words = UiDesign.text().get("hud", {})
	_build()
	resized.connect(_layout)
	set_process(true)

func setup(value: Chapter1Campaign) -> void:
	runtime = value
	panels = PANELS_SCENE.instantiate() as CampaignPanels
	add_child(panels)
	panels.set_command_sink(Callable(runtime, "handle_ui_command"))
	panels.panel_opened.connect(_on_panel_opened)
	panels.panel_closed.connect(_on_panel_closed)
	panels.ending_retry_requested.connect(func() -> void:
		panels.close_panel()
		runtime.retry_checkpoint())
	panels.ending_continue_requested.connect(func() -> void:
		if not bool(runtime.route.gate_status().get("ready", false)):
			show_chapter1_outcome()
			return
		panels.close_panel()
		runtime.advance_scene())
	panels.set_panel_builder("what_now", _build_what_now)
	panels.set_pause_actions([
		{"label": String(_words.get("what_now", "What now")), "name": "WhatNow", "action": func() -> void: panels.open_panel("what_now")},
		{"label": String(_words.get("messages", "Messages")), "name": "Messages", "action": func() -> void:
			panels.close_panel()
			open_messages()},
		{"label": String(_words.get("journal", "Journal")), "name": "Journal", "action": _on_journal_pressed},
		{"label": String(_words.get("settings", "Settings")), "name": "Settings", "action": func() -> void: panels.open_panel("settings_accessibility")},
		{"label": String(_words.get("save", "Save")), "name": "Save", "action": func() -> void:
			panels.close_panel()
			_on_save_pressed()},
		{"label": String(_words.get("save_and_quit", "Save and quit")), "name": "SaveAndQuit", "action": func() -> void:
			panels.close_panel()
			_on_exit_pressed()},
	])
	panels.set_content_top(float(UiDesign.px(64, get_viewport_rect().size.y)))
	comms_service = CommsServiceScript.new()
	var director_ref = runtime.get("director") if runtime != null else null
	var content_ref: Dictionary = runtime.content if runtime != null and runtime.get("content") is Dictionary else {}
	comms_service.setup(director_ref, content_ref, false)
	comms_panel = CommsPanelScript.new()
	comms_panel.name = "CommsPanel"
	add_child(comms_panel)
	comms_panel.bind_service(comms_service)
	comms_panel.opened.connect(func() -> void: _on_panel_opened("comms"))
	comms_panel.closed.connect(func() -> void: _on_panel_closed("comms"))
	mission_table = MISSION_TABLE_SCENE.instantiate() as MissionTablePanel
	add_child(mission_table)
	mission_table.opened.connect(func(_target: String) -> void: _on_panel_opened("mission_table"))
	mission_table.closed.connect(func(_target: String) -> void:
		if is_instance_valid(payload_activity):
			payload_activity.free()
			payload_activity = null
		_on_panel_closed("mission_table"))
	mission_table.commit_requested.connect(_on_mission_table_commit)
	mission_table.payload_requested.connect(_on_payload_requested)
	mission_table.hint_player = panels.hint_player
	chapter4_panel = CHAPTER4_PANEL_SCENE.instantiate() as Chapter4PuzzlePanel
	add_child(chapter4_panel)
	chapter4_panel.opened.connect(func(_target: String) -> void: _on_panel_opened("chapter4_panel"))
	chapter4_panel.closed.connect(func(_target: String) -> void: _on_panel_closed("chapter4_panel"))
	chapter4_panel.commit_requested.connect(_on_chapter4_commit)
	chapter6_panel = CHAPTER6_PANEL_SCENE.instantiate() as Chapter6PuzzlePanel
	add_child(chapter6_panel)
	chapter6_panel.opened.connect(func(_target: String) -> void: _on_panel_opened("chapter6_panel"))
	chapter6_panel.closed.connect(func(_target: String) -> void: _on_panel_closed("chapter6_panel"))
	chapter6_panel.commit_requested.connect(_on_chapter6_commit)
	chapter8_panel = CHAPTER8_PANEL_SCENE.instantiate() as Chapter8PuzzlePanel
	add_child(chapter8_panel)
	chapter8_panel.opened.connect(func(_target: String) -> void: _on_panel_opened("chapter8_panel"))
	chapter8_panel.closed.connect(func(_target: String) -> void: _on_panel_closed("chapter8_panel"))
	chapter8_panel.commit_requested.connect(_on_chapter8_commit)
	p01_panel = P01_SCENE.instantiate() as P01Panel
	add_child(p01_panel)
	p01_panel.hint_player = panels.hint_player
	p01_panel.opened.connect(func(_target): _on_panel_opened("p01"))
	p01_panel.closed.connect(func(_target): _on_panel_closed("p01"))
	p01_panel.commit_requested.connect(func(target, payload):
		var result := runtime.perform_target(target, payload)
		p01_panel.open(runtime, target)
		p01_panel.show_result(result))
	p01_panel.sources_requested.connect(func():
		var ids: Array = []
		for card in panels.science.cards_for_puzzle("P-01"):
			ids.append(card.source_id)
		panels.open_panel("sources", {"ids": ids}))
	runtime.p01_panel_requested.connect(func(view):
		if mission_table.is_open() or p01_panel.is_open() or not panels.active_panel().is_empty() or panels.hint_player.is_open():
			return
		if p01_panel.open(runtime, String(view.target_id)):
			p01_panel.teach_first_use())
	panels.hint_player.highlight_changed.connect(func(active):
		_marker.z_index = 210 if active else 0
		_update_world_overlay())
	if eva_visor != null and runtime.get("eva_suit") != null:
		eva_visor.bind_suit(runtime.eva_suit)
	_resume_pending = bool(runtime.incremental_loading) and not runtime.initial_snapshot.is_empty()
	_refresh_query()
	refresh_scene({})

## Re-reads the current scene: goal card, jobs, dialogue and the strip.
func refresh_scene(_result: Dictionary = {}, during_loading: bool = false) -> void:
	if runtime == null or (runtime.loading and not during_loading):
		return
	var scene := runtime.current_scene_data()
	var next_scene := String(scene.get("id", ""))
	if next_scene != _scene_id:
		_scene_id = next_scene
		_forecast = {}
		_forecast_key = ""
		_forecast_cache_key = ""
		_forecast_cache = {}
		_done_ids = {}
		_auto_timer = 0.0
	_dialogue_index = _first_unacknowledged_line()
	_decision_review.visible = next_scene.begins_with("EX-CH01-")
	_sync_messages()
	_render_caption()
	_build_targets()
	_refresh_query()
	apply_accessibility()
	_offer_resume_card()
	_flush_message_toasts()

## After any runtime action: refresh what changed and answer back with one line.
func refresh_after_action(result: Dictionary) -> void:
	_forecast = {}
	_forecast_key = ""
	_forecast_cache_key = ""
	_forecast_cache = {}
	var before := _done_ids.duplicate()
	if runtime != null:
		_dialogue_index = _first_unacknowledged_line()
		_sync_messages()
		_render_caption()
		_build_targets()
		_refresh_query()
	var newly_done: Array = []
	for id in _done_ids:
		if not before.has(id):
			newly_done.append(id)
	if result.get("accepted", false):
		var done_id := String(newly_done[0]) if not newly_done.is_empty() else ""
		if done_id.is_empty() and result.get("p01", null) is Dictionary:
			done_id = String((result.get("p01", {}) as Dictionary).get("action", ""))
		var notes_list := _result_notes(result.get("warnings", []) + result.get("ledger_summary", []))
		var fb_dict := {}
		var tension_dict := {}
		var posture_dict := {}
		if _scene_id.begins_with("EX-CH01-") and not done_id.is_empty():
			var snap: Dictionary = runtime.director.snapshot() if runtime != null and runtime.director != null else {}
			var route_snap: Dictionary = runtime.route.snapshot() if runtime != null and runtime.route != null and runtime.route.has_method("snapshot") else {}
			var res: Dictionary = snap.get("resources", {}) if snap.get("resources", {}) is Dictionary else {}
			var live_state := {"p01": route_snap.get("p01", {}), "resources": res}
			fb_dict = Chapter1FeedbackScript.action_feedback(done_id, live_state)
			var shift_idx := clampi(int(res.get("shift_index", 1)), 1, 7)
			var alo_h := int(res.get("H", 6))
			var water_w := int(res.get("W", 0))
			var bloomed := _scene_id == "EX-CH01-S12" and alo_h > 0
			tension_dict = Chapter1FeedbackScript.night_shift_tension(shift_idx)
			posture_dict = Chapter1FeedbackScript.alo_posture(alo_h, water_w, shift_idx, bloomed)
			notes_list.append("What changed: " + String(fb_dict.get("consequence", "")))
			notes_list.append("Why: " + String(fb_dict.get("why", "")))
			notes_list.append("Next step: " + String(fb_dict.get("next_step", "")))
			notes_list.append("Meter tick: " + String(fb_dict.get("meter_tick", "")))
			notes_list.append("%s: \"%s\"" % [String(fb_dict.get("crew_speaker", "Crew")), String(fb_dict.get("crew_reaction", ""))])
			notes_list.append("Alo (%s): %s" % [String(posture_dict.get("stage", "")), String(posture_dict.get("posture_description", ""))])
		_last_outcome = {
			"result": result.get("reason", "Done."),
			"changes": result.get("deltas", []),
			"notes": notes_list,
			"feedback": fb_dict,
			"tension": tension_dict,
			"alo_posture": posture_dict,
		}
		if not newly_done.is_empty() and result.get("result", result).get("unsafe_predicates", []).is_empty():
			var line := _result_line(done_id)
			_last_outcome["result"] = line
			show_status(line)
		if panels != null and runtime != null:
			panels.bind_query(runtime.query().merged({"outcome": _last_outcome}, true))
		if newly_done.has("complete_debrief"):
			show_chapter1_outcome("replay")
		return
	if result.has("reason"):
		show_status(String(result.get("reason", "")))

## Shows one line in the toast (top right, five seconds). Runtime reasons are
## rewritten into player words; "do this first" reasons name the job.
func show_status(text: String) -> void:
	if _status == null:
		return
	var rewrite := UiDesign.toast_rewrite(text)
	var line := String(rewrite.text)
	if not String(rewrite.flag).is_empty():
		line = line % _goal_for_flag(String(rewrite.flag))
	if line.is_empty():
		_hide_toast()
		return
	_status.text = line
	var edge := UiDesign.colour("glass_edge", Color(1, 1, 1, 0.18))
	match String(rewrite.kind):
		"good":
			edge = UiDesign.colour("good")
		"caution":
			edge = UiDesign.colour("caution")
	if text.begins_with("SAVE FAILED") or text.begins_with("AUTOSAVE FAILED"):
		edge = UiDesign.colour("danger")
	_toast.add_theme_stylebox_override("panel", UiDesign.glass_style(edge, Color.TRANSPARENT, 12))
	_toast_timer = float(UiDesign.tokens().get("motion", {}).get("toast_seconds", 5.0))
	if not _chrome_hidden:
		_fade(_toast, true)

func _hide_toast() -> void:
	_toast_timer = 0.0
	if _toast != null and _toast.visible:
		_fade(_toast, false)

func _build() -> void:
	var view := get_viewport_rect().size
	var margin := _margin()
	# Goal card, top left.
	_goal_card = UiDesign.glass_panel(Color.TRANSPARENT, 14)
	_goal_card.name = "GoalCard"
	_goal_card.position = Vector2(margin, margin)
	# A container grows with its content but never shrinks on its own: refit when the text gets shorter.
	_goal_card.minimum_size_changed.connect(func() -> void: _goal_card.reset_size.call_deferred())
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 4)
	_goal_card.add_child(card_box)
	_chapter_line = UiDesign.label("", "caption", "muted")
	card_box.add_child(_chapter_line)
	var goal_row := HBoxContainer.new()
	goal_row.add_theme_constant_override("separation", 8)
	card_box.add_child(goal_row)
	_goal_icon = UiDesign.LineIcon.new("goal", UiDesign.colour("accent"))
	_goal_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	goal_row.add_child(_goal_icon)
	_title = UiDesign.label("", "heading", "ivory")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.accessibility_name = "Current goal"
	goal_row.add_child(_title)
	_why = UiDesign.label("", "body", "muted")
	card_box.add_child(_why)
	var what_now_key := UiDesign.label("%s · %s" % [String(_words.get("what_now_key", "H")), String(_words.get("what_now", "What now"))], "caption", "muted")
	what_now_key.name = "WhatNowKey"
	card_box.add_child(what_now_key)
	_advance = UiDesign.button("%s · %s" % [String(_words.get("continue", "Continue")), String(_words.get("continue_key", "Enter"))], 40)
	_advance.name = "Continue"
	_advance.visible = false
	_advance.disabled = true
	_advance.pressed.connect(_on_advance_pressed)
	card_box.add_child(_advance)
	add_child(_goal_card)
	# World marker and the prompt on the object in reach.
	_marker = Marker.new()
	_marker.name = "GoalMarker"
	_marker.visible = false
	add_child(_marker)
	_prompt = UiDesign.glass_panel(UiDesign.colour("accent"), 8)
	_prompt.name = "Prompt"
	_prompt.visible = false
	var prompt_row := HBoxContainer.new()
	prompt_row.add_theme_constant_override("separation", 8)
	_prompt.add_child(prompt_row)
	_prompt_key = UiDesign.label(String(UiDesign.tokens().get("keys", {}).get("interact", "E")), "body", "ink")
	_prompt_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_key.custom_minimum_size = Vector2(28, 0)
	var key_panel := PanelContainer.new()
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = UiDesign.colour("accent")
	key_style.set_corner_radius_all(6)
	key_style.content_margin_left = 6
	key_style.content_margin_right = 6
	key_panel.add_theme_stylebox_override("panel", key_style)
	key_panel.add_child(_prompt_key)
	prompt_row.add_child(key_panel)
	_prompt_label = UiDesign.label("", "body", "ivory")
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	prompt_row.add_child(_prompt_label)
	add_child(_prompt)
	# Toast and station strip, top right.
	_column = VBoxContainer.new()
	_column.name = "TopRight"
	_column.add_theme_constant_override("separation", 8)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)
	_toast = UiDesign.glass_panel(Color.TRANSPARENT, 12)
	_toast.name = "Toast"
	_toast.visible = false
	_toast.set_meta("lla_shown", false)
	_status = UiDesign.label("", "body", "ivory")
	_status.accessibility_name = "Message"
	_toast.add_child(_status)
	_column.add_child(_toast)
	outpost = Outpost.new()
	outpost.name = "OutpostStatus"
	_column.add_child(outpost)
	eva_visor = EvaVisorHudScript.new()
	eva_visor.name = "EvaVisorHud"
	eva_visor.visible = false
	add_child(eva_visor)
	# Dialogue, bottom centre.
	_dialogue_bar = UiDesign.glass_panel(Color.TRANSPARENT, 14)
	_dialogue_bar.name = "Dialogue"
	_dialogue_bar.visible = false
	_dialogue_bar.set_meta("lla_shown", false)
	_dialogue_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 6)
	_dialogue_bar.add_child(dialogue_box)
	var speaker_row := HBoxContainer.new()
	dialogue_box.add_child(speaker_row)
	_caption_speaker = UiDesign.label("", "caption", "accent")
	_caption_speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speaker_row.add_child(_caption_speaker)
	_caption_count = UiDesign.label("", "caption", "muted")
	_caption_count.autowrap_mode = TextServer.AUTOWRAP_OFF
	speaker_row.add_child(_caption_count)
	_caption_line = UiDesign.label("", "body", "ivory")
	_caption_line.set_meta("verbatim", true)  # canon lines stay word for word (STORY_FULL.md)
	dialogue_box.add_child(_caption_line)
	var dialogue_buttons := HBoxContainer.new()
	dialogue_buttons.add_theme_constant_override("separation", 8)
	dialogue_buttons.alignment = BoxContainer.ALIGNMENT_END
	dialogue_box.add_child(dialogue_buttons)
	_auto_button = UiDesign.button(String(_words.get("auto", "Auto")), 36)
	_auto_button.name = "Auto"
	_auto_button.toggle_mode = true
	_auto_button.focus_mode = Control.FOCUS_NONE  # Space is Next's key; a clicked Auto must not take it
	_auto_button.toggled.connect(_on_auto_toggled)
	dialogue_buttons.add_child(_auto_button)
	_next_line = UiDesign.button("%s · %s" % [String(_words.get("next_line", "Next")), String(_words.get("next_line_key", "Space"))], 36)
	_next_line.name = "Next"
	_next_line.focus_mode = Control.FOCUS_NONE  # Space presses it from anywhere
	_next_line.pressed.connect(_on_next_line)
	dialogue_buttons.add_child(_next_line)
	add_child(_dialogue_bar)
	# What now content (shown inside the panel layer on H).
	_what_now_home = Control.new()
	_what_now_home.name = "WhatNowHome"
	_what_now_home.visible = false
	_what_now_home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_what_now_home)
	_what_now = VBoxContainer.new()
	_what_now.name = "WhatNow"
	_what_now.add_theme_constant_override("separation", 10)
	_what_now.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_what_now.set_meta("lla_keep", true)
	_what_now.set_meta("lla_home", _what_now_home)
	_what_now_home.add_child(_what_now)
	_wn_goal = UiDesign.label("", "heading", "ivory")
	_what_now.add_child(_wn_goal)
	_wn_why = UiDesign.label("", "body", "muted")
	_what_now.add_child(_wn_why)
	_wn_where = _icon_line("place", "")
	_what_now.add_child(_wn_where.get_parent())
	_wn_hint = _icon_line("message", "")
	_what_now.add_child(_wn_hint.get_parent())
	var hint := UiDesign.button("Hint - one step at a time")
	hint.name = "WhatNowHint"
	hint.pressed.connect(_request_job_hint)
	_what_now.add_child(hint)
	var how_to := UiDesign.button("How to")
	how_to.name = "WhatNowHowTo"
	how_to.pressed.connect(func():
		panels.hint_player.set_settings(panels.accessibility_settings())
		panels.hint_player.show_how_to(HowToCard.card_id(runtime.query())))
	_what_now.add_child(how_to)
	var jobs_title := UiDesign.label(String(_words.get("jobs_here", "Jobs here")), "caption", "muted")
	_what_now.add_child(jobs_title)
	_targets = VBoxContainer.new()
	_targets.name = "Jobs"
	_targets.add_theme_constant_override("separation", 4)
	_targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_what_now.add_child(_targets)
	var tools := HFlowContainer.new()
	tools.add_theme_constant_override("h_separation", 8)
	tools.add_theme_constant_override("v_separation", 8)
	_what_now.add_child(tools)
	_last_result_button = UiDesign.button(String(_words.get("last_result", "Last result")))
	_last_result_button.name = "LastResult"
	_last_result_button.pressed.connect(func() -> void:
		if not show_chapter1_outcome():
			panels.open_panel("outcome", _last_outcome if not _last_outcome.is_empty() else {"result": String(_words.get("no_result", "Nothing to show yet."))}))
	tools.add_child(_last_result_button)
	_data_cards_button = UiDesign.button(String(_words.get("data_cards", "Data cards")))
	_data_cards_button.name = "DataCards"
	_data_cards_button.pressed.connect(func() -> void:
		var ids: Array = []
		for puzzle_id in runtime.query().get("source_puzzle_ids", []):
			for card in panels.science.cards_for_puzzle(puzzle_id):
				if not ids.has(card.source_id):
					ids.append(card.source_id)
		panels.open_panel("sources", {"ids": ids})
	)
	tools.add_child(_data_cards_button)
	_decision_review = UiDesign.button(String(_words.get("your_choice", "Your choice")))
	_decision_review.name = "DecisionReview"
	_decision_review.pressed.connect(func() -> void: panels.open_panel("puzzle"))
	tools.add_child(_decision_review)
	_retry = UiDesign.button(String(_words.get("retry", "Retry from the last checkpoint")))
	_retry.name = "Retry"
	_retry.pressed.connect(func() -> void:
		panels.close_panel()
		runtime.retry_checkpoint())
	tools.add_child(_retry)
	# Debug overlay (F10): developer IDs never appear elsewhere.
	_debug = UiDesign.label("", "caption", "muted")
	_debug.name = "DebugOverlay"
	_debug.visible = false
	_debug.add_theme_color_override("font_outline_color", UiDesign.colour("ink"))
	_debug.add_theme_constant_override("outline_size", 4)
	add_child(_debug)
	_layout()

func _icon_line(kind: String, text: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := UiDesign.LineIcon.new(kind, UiDesign.colour("accent"))
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var label := UiDesign.label(text, "body", "ivory")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return label

func _margin() -> int:
	var view := get_viewport_rect().size
	var grid := int(UiDesign.tokens().get("panel", {}).get("grid", 8))
	var margin := UiDesign.px(float(UiDesign.tokens().get("panel", {}).get("safe_margin", 64)), view.y)
	return maxi(grid, int(round(float(margin) / grid)) * grid)

## Places every HUD element on the 8 px grid inside the safe margin.
func _layout() -> void:
	if _goal_card == null:
		return
	var view := get_viewport_rect().size
	var margin := _margin()
	var goal_width := minf(float(UiDesign.px(600, view.y)), view.x / 3.0 - margin - 8.0)
	_goal_card.position = Vector2(margin, margin)
	_goal_card.custom_minimum_size = Vector2(goal_width, 0)
	_goal_card.size = Vector2(goal_width, 0)
	var column_width := float(UiDesign.px(540, view.y))
	_column.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_column.grow_vertical = Control.GROW_DIRECTION_END
	_column.offset_left = -margin - column_width
	_column.offset_right = -margin
	_column.offset_top = margin
	_column.offset_bottom = margin
	var dialogue_width := float(UiDesign.px(1080, view.y))
	_dialogue_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dialogue_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dialogue_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_dialogue_bar.offset_left = -dialogue_width * 0.5
	_dialogue_bar.offset_right = dialogue_width * 0.5
	_dialogue_bar.offset_bottom = -margin
	_dialogue_bar.offset_top = -margin
	_debug.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_debug.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug.offset_left = margin
	_debug.offset_bottom = -8
	_debug.offset_top = -8
	_debug.offset_right = margin + float(UiDesign.px(900, view.y))

## Works out the one goal for the current scene state and rebuilds the jobs list.
func _build_targets() -> void:
	if _targets == null or runtime == null:
		return
	for child in _targets.get_children():
		_targets.remove_child(child)
		child.queue_free()
	var gate: Dictionary = runtime.route.gate_status()
	var complete := runtime.is_chapter_complete()
	var flags: Dictionary = gate.get("physical_flags", {})
	var targets := runtime.targets_for_current_scene()
	var current: Dictionary = {}
	var fallback: Dictionary = {}
	_done_ids = {}
	for raw_target in targets:
		if not raw_target is Dictionary:
			continue
		var target: Dictionary = raw_target
		var id := String(target.get("target_id", ""))
		var done := runtime.target_completed(target)
		if done:
			_done_ids[id] = true
			continue
		if fallback.is_empty():
			fallback = target
		var missing := false
		for flag in target.get("required_flags", []):
			if not bool(flags.get(flag, false)):
				missing = true
		if not missing and current.is_empty():
			current = target
	if current.is_empty():
		current = fallback
	for raw_target in targets:
		if not raw_target is Dictionary:
			continue
		var target: Dictionary = raw_target
		var id := String(target.get("target_id", ""))
		var state := "later"
		if _done_ids.has(id):
			state = "done"
		elif id == String(current.get("target_id", "")):
			state = "now"
		_targets.add_child(_job_row(target, state))
	_goal_info = _goal_for_state(current, gate, complete)
	_apply_goal()
	_retry.disabled = complete or runtime.route.snapshot().get("retry_checkpoint", {}).is_empty()
	_update_debug(gate)
	if panels != null and not panels.active_panel().is_empty():
		_set_modal_buttons(true)
	apply_accessibility()

func _job_row(target: Dictionary, state: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var word := String(_words.get("job_" + state, state.capitalize()))
	var mark := String({"done": "✓", "now": "▸", "later": "·"}.get(state, "·"))
	var state_label := UiDesign.label("%s %s" % [mark, word], "caption", "muted" if state != "now" else "accent")
	state_label.custom_minimum_size.x = 72
	row.add_child(state_label)
	var text := UiDesign.label(_goal_text(target), "body", "ivory" if state != "done" else "muted")
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	return row

## The authored text for one job, or a plain-word fallback for later chapters.
func _target_text(target: Dictionary) -> Dictionary:
	var authored = UiDesign.text().get("targets", {}).get(String(target.get("target_id", "")), null)
	if authored is Dictionary:
		return authored
	var label := UiDesign.player_words(String(target.get("focus_label", "")).get_slice(" · ", 0))  # drop trailing codes such as "E1/A1"
	return {"goal": String(_words.get("fallback_goal", "Do the next job: %s")) % label.to_lower(), "why": String(_words.get("fallback_why", "")), "prompt": label, "result": "", "hint": ""}

func _goal_text(target: Dictionary) -> String:
	return String(_target_text(target).get("goal", ""))

func _goal_for_state(current: Dictionary, gate: Dictionary, complete: bool) -> Dictionary:
	var info := {"goal": "", "why": "", "hint": "", "target_id": "", "place": "", "ready": false, "complete": complete}
	if complete:
		var done: Dictionary = _words.get("chapter_complete", {})
		info.goal = String(done.get("goal", "Chapter complete"))
		info.why = String(done.get("why", ""))
		return info
	if not current.is_empty():
		var text := _target_text(current)
		info.goal = String(text.get("goal", ""))
		info.why = String(text.get("why", ""))
		info.hint = String(text.get("hint", ""))
		info.target_id = String(current.get("target_id", ""))
		var node := runtime.physical_target(info.target_id)
		info.place = String(node.get_meta("focus_label", "")) if node != null and node.has_meta("focus_label") else ""
		return info
	var scene_text: Dictionary = UiDesign.text().get("scenes", {}).get(_scene_id, {})
	if bool(gate.get("ready", false)):
		info.ready = true
		var next: Dictionary = scene_text.get("next", {})
		info.goal = String(next.get("goal", String(_words.get("continue", "Continue"))))
		info.why = String(next.get("why", ""))
		if info.why.is_empty() and comms_service != null:
			var goal_msg: Dictionary = comms_service.latest_goal_message()
			if not goal_msg.is_empty():
				info.why = String(goal_msg.get("subject", ""))
		return info
	info.goal = "Finish the jobs here"
	return info

func _apply_goal() -> void:
	var changed := _title.text != String(_goal_info.get("goal", ""))
	_title.text = String(_goal_info.get("goal", ""))
	_why.text = String(_goal_info.get("why", ""))
	_why.visible = not _why.text.is_empty()
	_chapter_line.text = _chapter_text()
	var complete := bool(_goal_info.get("complete", false))
	var ready := bool(_goal_info.get("ready", false))
	_advance.visible = ready and not complete
	_advance.disabled = complete or not ready
	_marker_node = runtime.physical_target(String(_goal_info.get("target_id", ""))) if not String(_goal_info.get("target_id", "")).is_empty() else null
	_wn_goal.text = _title.text
	_wn_why.text = _why.text
	_wn_why.visible = _why.visible
	_wn_hint.text = String(_goal_info.get("hint", ""))
	_wn_hint.get_parent().hide()
	_update_where()
	if changed and not _title.text.is_empty():
		_pulse_goal()

func _chapter_text() -> String:
	var chapter_id := String(runtime.query().get("chapter_id", "CH01"))
	var number := int(chapter_id.trim_prefix("CH"))
	var parts: Array[String] = [String(_words.get("chapter_label", "Chapter %d")) % number]
	var name := String(_words.get("chapter_names", {}).get(chapter_id, ""))
	if not name.is_empty():
		parts.append(name)
	var scene_text: Dictionary = UiDesign.text().get("scenes", {}).get(_scene_id, {})
	var date := String(scene_text.get("date", ""))
	if date.is_empty():
		var scene := runtime.current_scene_data()
		date = UiDesign.player_words(String(scene.get("storyTime", scene.get("story_time", ""))))
	if not date.is_empty():
		parts.append(date)
	return " · ".join(parts)

func _update_where() -> void:
	var place := String(_goal_info.get("place", ""))
	if place.is_empty():
		_wn_where.get_parent().visible = false
		return
	_wn_where.get_parent().visible = true
	var distance := _distance_to(_marker_node)
	_wn_where.text = "%s · %s" % [place, UiDesign.distance_text(distance)] if distance >= 0.0 else place

func _distance_to(node: Node3D) -> float:
	if not is_instance_valid(node) or not node.is_inside_tree() or runtime == null:
		return -1.0
	var player: Node3D = runtime.get("_player") as Node3D
	if not is_instance_valid(player) or not player.is_inside_tree():
		return -1.0
	var a := player.global_position
	var b := node.global_position
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

## The goal of the job whose flag a "do this first" reason names.
func _goal_for_flag(flag: String) -> String:
	var candidates := runtime.targets_for_current_scene()
	if not candidates.any(func(target): return String(target.get("physical_flag", "")) == flag):
		for catalog in [preload("res://scripts/missions/chapter2_gate_catalog.gd"), preload("res://scripts/missions/extended_gate_catalog.gd")]:
			for scene_id in catalog.scene_ids():
				if String(scene_id) <= _scene_id:
					candidates.append_array(catalog.targets_for_scene(scene_id))
	for raw_target in candidates:
		if raw_target is Dictionary and String(raw_target.get("physical_flag", "")) == flag:
			var goal := _goal_text(raw_target)
			return goal[0].to_lower() + goal.substr(1) if goal.length() > 1 else goal
	return "finish the earlier jobs here"

## Ledger measurements keep their values; only internal resource letters change.
func _result_notes(notes: Array) -> Array:
	var translated: Array = []
	for note in notes:
		var line := str(note)
		for key in UiDesign.text().get("station", {}).get("fields", {}):
			var regex := RegEx.new()
			regex.compile("\\b" + String(key) + "\\s*(?=[=+−-]?\\d)")
			line = regex.sub(line, String(UiDesign.text().station.fields[key].word) + " ", true)
		translated.append(UiDesign.player_words(line))
	return translated

func _request_job_hint() -> void:
	var id := String(_goal_info.get("target_id", ""))
	if _scene_id.begins_with("EX-CH01-") or id.is_empty():
		panels.request_hint()
		return
	var lesson := HowToCard.lesson(HowToCard.card_id(runtime.query()))
	lesson.nudge = String(_goal_info.get("hint", ""))
	panels.hint_player.set_settings(panels.accessibility_settings())
	panels.hint_player.request_hint(_scene_id + ":" + id, lesson, _marker)

func _result_line(target_id: String) -> String:
	var authored = UiDesign.text().get("targets", {}).get(target_id, {})
	var line := String(authored.get("result", "")) if authored is Dictionary else ""
	if line.is_empty():
		for raw_target in runtime.targets_for_current_scene():
			if raw_target is Dictionary and String(raw_target.get("target_id", "")) == target_id:
				line = "Done: " + _goal_text(raw_target)
	return line

func _pulse_goal() -> void:
	if runtime == null or UiDesign.reduced_motion(runtime.query().get("accessibility", {})) or not is_inside_tree():
		return
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_goal_card.self_modulate = Color.WHITE
	_pulse = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).set_loops(int(UiDesign.tokens().get("motion", {}).get("pulse_count", 2)))
	_pulse.tween_property(_goal_card, "self_modulate", Color(1.18, 1.18, 1.18), 0.22)  # the dialogue dim lives on modulate.a
	_pulse.tween_property(_goal_card, "self_modulate", Color.WHITE, 0.26)

func _update_debug(gate: Dictionary) -> void:
	if not OS.is_debug_build():
		_debug.visible = false
		return
	var scene := runtime.current_scene_data()
	var query := runtime.query()
	_debug.text = "%s · %s · %s · %s · rev %d · missing: %s · goal: %s" % [
		String(_words.get("debug_hint", "Developer view")), _scene_id, String(scene.get("location", "")), String(scene.get("storyTime", scene.get("story_time", ""))),
		int(query.get("state_revision", 0)), ", ".join(gate.get("missing", []).map(func(f): return String(f))), String(_goal_info.get("target_id", "-"))]
	_debug.visible = _debug_on

## Fills the What now panel body with the HUD's own content (kept, not freed).
func _build_what_now(body: VBoxContainer) -> void:
	_update_where()
	_last_result_button.visible = true
	_data_cards_button.visible = not runtime.query().get("source_puzzle_ids", []).is_empty()
	if _what_now.get_parent() != null:
		_what_now.get_parent().remove_child(_what_now)
	body.add_child(_what_now)

## Opens the P-02 Mission Table for one shift gate. Reading and planning pause
## the expedition; the physical commit happens only after the table closes.
func open_mission_table(target_id: String) -> bool:
	if runtime == null or mission_table == null or runtime.is_chapter_complete() or not MissionTableScript.is_gate(target_id):
		return false
	if runtime.is_cutscene_active() or mission_table.is_open() or p01_panel.is_open():
		return false
	if panels != null and not panels.active_panel().is_empty():
		return false
	mission_table.open(runtime.route, target_id, runtime.query().get("accessibility", {}))
	mission_table.teach_first_use()
	return true

## Opens the Chapter 4 puzzle panel (P-07 / P-08) for one operation.
func open_chapter4_panel(target_id: String) -> bool:
	if runtime == null or chapter4_panel == null or runtime.is_chapter_complete() or not Chapter4Script.is_step(target_id):
		return false
	if runtime.is_cutscene_active() or chapter4_panel.is_open() or (chapter6_panel != null and chapter6_panel.is_open()) or (chapter8_panel != null and chapter8_panel.is_open()) or (mission_table != null and mission_table.is_open()) or (p01_panel != null and p01_panel.is_open()):
		return false
	if panels != null and not panels.active_panel().is_empty():
		return false
	if not runtime.route.has_method("chapter4_view"):
		return false
	var settings: Dictionary = runtime.query().get("accessibility", {}).duplicate(true)
	chapter4_panel.open(runtime.route, target_id, settings)
	return true

func _on_chapter4_commit(target_id: String, payload: Dictionary) -> void:
	if runtime == null:
		return
	var result := runtime.perform_target(target_id, payload)
	if not bool(result.get("accepted", false)):
		show_status("HELD · " + String(result.get("reason", "The operation was not recorded.")))
		return
	var title := Chapter4Script.focus_label(target_id)
	_last_outcome = {"result": "%s · locked in" % title, "changes": result.get("deltas", []), "notes": result.get("warnings", []) + result.get("ledger_summary", [])}
	show_status("%s · locked in. %s" % [title, String(result.get("reason", ""))])
	panels.open_panel("outcome", _last_outcome)

## Opens the Chapter 6 puzzle panel (P-11 / P-12) for one operation.
func open_chapter6_panel(target_id: String) -> bool:
	if runtime == null or chapter6_panel == null or runtime.is_chapter_complete() or not Chapter6Script.is_step(target_id):
		return false
	if runtime.is_cutscene_active() or chapter6_panel.is_open() or (chapter4_panel != null and chapter4_panel.is_open()) or (chapter8_panel != null and chapter8_panel.is_open()) or (mission_table != null and mission_table.is_open()) or (p01_panel != null and p01_panel.is_open()):
		return false
	if panels != null and not panels.active_panel().is_empty():
		return false
	if not runtime.route.has_method("chapter6_view"):
		return false
	var settings: Dictionary = runtime.query().get("accessibility", {}).duplicate(true)
	chapter6_panel.open(runtime.route, target_id, settings)
	return true

func _on_chapter6_commit(target_id: String, payload: Dictionary) -> void:
	if runtime == null:
		return
	var result := runtime.perform_target(target_id, payload)
	if not bool(result.get("accepted", false)):
		show_status("HELD · " + String(result.get("reason", "The operation was not recorded.")))
		return
	var title := Chapter6Script.focus_label(target_id)
	_last_outcome = {"result": "%s · locked in" % title, "changes": result.get("deltas", []), "notes": result.get("warnings", []) + result.get("ledger_summary", [])}
	show_status("%s · locked in. %s" % [title, String(result.get("reason", ""))])
	panels.open_panel("outcome", _last_outcome)

## Opens the Chapter 8 puzzle panel (P-15 / P-16) for one operation. Reading
## and deciding pause the expedition; the physical commit happens only after
## the panel closes with LOCK IN.
func open_chapter8_panel(target_id: String) -> bool:
	if runtime == null or chapter8_panel == null or runtime.is_chapter_complete() or not Chapter8Script.is_step(target_id):
		return false
	if runtime.is_cutscene_active() or chapter8_panel.is_open() or (chapter4_panel != null and chapter4_panel.is_open()) or (chapter6_panel != null and chapter6_panel.is_open()) or (mission_table != null and mission_table.is_open()) or (p01_panel != null and p01_panel.is_open()):
		return false
	if panels != null and not panels.active_panel().is_empty():
		return false
	if not runtime.route.has_method("chapter8_view"):
		return false
	var settings: Dictionary = runtime.query().get("accessibility", {}).duplicate(true)
	chapter8_panel.open(runtime.route, target_id, settings)
	return true

func _on_chapter8_commit(target_id: String, payload: Dictionary) -> void:
	if runtime == null:
		return
	var result := runtime.perform_target(target_id, payload)
	if not bool(result.get("accepted", false)):
		show_status("HELD · " + String(result.get("reason", "The operation was not recorded.")))
		return
	var title := Chapter8Script.focus_label(target_id)
	_last_outcome = {"result": "%s · locked in" % title, "changes": result.get("deltas", []), "notes": result.get("warnings", []) + result.get("ledger_summary", [])}
	show_status("%s · locked in. %s" % [title, String(result.get("reason", ""))])
	panels.open_panel("outcome", _last_outcome)

func _on_mission_table_commit(target_id: String, plan: Dictionary) -> void:
	if runtime == null:
		return
	var result := runtime.perform_target(target_id, {"plan": plan})
	if not bool(result.get("accepted", false)):
		return
	var actual: Dictionary = result.get("result", result)
	var causes: Array = actual.get("unsafe_predicates", [])
	if not causes.is_empty():
		var notes: Array = []
		for cause in causes:
			notes.append(MissionTablePanel.display_text(String(cause)))
		var line := "Attempt stopped safely. " + String(notes[0]) + ". Retry the last shift to change the plan."
		_last_outcome = {"result": line, "changes": actual.get("deltas", []), "notes": notes}
		panels.bind_query(runtime.query().merged({"outcome": _last_outcome}, true))
		show_status(line)
	show_chapter1_outcome()

## Hosts the physical shift-5 STACK activity (doc 25 §4.3) over the paused
## Mission Table. The job is staged in the Safe Room; anywhere else the table
## keeps its button flow and the cadet is told where to go.
func _on_payload_requested(settings: Dictionary) -> void:
	if runtime == null or is_instance_valid(payload_activity):
		return
	if runtime.route.current_room_id() != "LOC-04":
		show_status("Carry the supplies from the Safe Room response controls.")
		return
	payload_activity = PayloadStackActivity.launch(runtime, settings)
	payload_activity.closed.connect(func() -> void: payload_activity = null)

## Reads only the existing route ending, complete receipts and checkpoint. The
## route remains responsible for every retry and physical scene/Chapter 2 gate.
func show_chapter1_outcome(page: String = "summary") -> bool:
	if runtime == null or not runtime.route.current_scene_id().begins_with("EX-CH01-"):
		return false
	var data := Debrief.view(runtime.director.snapshot(), runtime.route.snapshot())
	if data.is_empty():
		return false
	data["can_continue"] = bool(runtime.route.gate_status().get("ready", false))
	if not data.can_continue:
		_build_targets()
		data["continue_reason"] = "Close this review, then follow this goal:\n" + String(_goal_info.goal)
		if not String(_goal_info.place).is_empty():
			data.continue_reason += "\nFind it at " + String(_goal_info.place) + "."
	return panels.open_chapter1_outcome(data, page)

func _render_caption() -> void:
	if runtime == null:
		return
	var lines := runtime.current_dialogue()
	runtime.present_dialogue(lines[_dialogue_index] if _dialogue_index < lines.size() else {})
	if lines.is_empty() or _dialogue_index >= lines.size():
		_next_line.disabled = true
		_next_line.text = String(_words.get("next_line", "Next"))
		_caption_count.text = ""
		_set_dialogue_visible(false)
		return
	_dialogue_index = clampi(_dialogue_index, 0, lines.size() - 1)
	var line: Dictionary = lines[_dialogue_index]
	var speaker := String(line.get("speaker", "Crew"))
	var origins: Dictionary = UiDesign.text().get("dialogue", {}).get("origins", {})
	var origin := String(origins.get(String(line.get("origin_label", line.get("delivery", ""))), ""))
	_caption_speaker.text = speaker + (" · " + origin if not origin.is_empty() else "")
	var tone := String(UiDesign.text().get("dialogue", {}).get("speaker_colours", {}).get(speaker, "accent"))
	_caption_speaker.add_theme_color_override("font_color", UiDesign.colour(tone, UiDesign.colour("accent")))
	_caption_line.text = String(line.get("text", line.get("line", "")))
	_caption_count.text = "%d of %d" % [_dialogue_index + 1, lines.size()]
	_next_line.disabled = false
	_next_line.text = "%s · %s" % [String(_words.get("next_line", "Next")), String(_words.get("next_line_key", "Space"))]
	var motion: Dictionary = UiDesign.tokens().get("motion", {})
	_auto_timer = float(motion.get("auto_dialogue_base_seconds", 2.2)) + float(motion.get("auto_dialogue_seconds_per_character", 0.05)) * _caption_line.text.length()
	_set_dialogue_visible(true)

func _set_dialogue_visible(shown: bool) -> void:
	if _chrome_hidden and shown:
		return
	var current_shown := bool(_dialogue_bar.get_meta("lla_shown", _dialogue_bar.visible)) if _dialogue_bar.has_meta("lla_shown") else _dialogue_bar.visible
	if shown != current_shown:  # mid-fade, `visible` is still the old state
		_fade(_dialogue_bar, shown)
	_goal_card.modulate.a = 0.6 if shown else 1.0

## Resumes the caption where the saved acknowledgements stopped, so a reload
## does not replay lines the player already read.
func _first_unacknowledged_line() -> int:
	var acknowledged: Array = runtime.route.gate_status().get("dialogue_acknowledged", [])
	var lines := runtime.current_dialogue()
	for index in lines.size():
		if not acknowledged.has(String(lines[index].get("id", ""))):
			return index
	return lines.size()

func _on_next_line() -> void:
	if runtime == null:
		return
	var lines := runtime.current_dialogue()
	if lines.is_empty() or _dialogue_index >= lines.size():
		return
	var result := runtime.acknowledge_dialogue(String(lines[_dialogue_index].get("id", "")))
	if bool(result.get("accepted", false)):
		_dialogue_index = _first_unacknowledged_line()
	_render_caption()
	_flush_message_toasts()

func _on_auto_toggled(pressed: bool) -> void:
	_auto_on = pressed
	_auto_button.text = String(_words.get("auto_on", "Auto on")) if pressed else String(_words.get("auto", "Auto"))

func _on_advance_pressed() -> void:
	if runtime != null:
		runtime.advance_scene()

func _on_journal_pressed() -> void:
	if runtime != null and panels != null:
		_refresh_query()
		panels.open_journal("now")

## Opens the full-screen Messages inbox (5 threads: Crew, Commander, Earth, Academy, Archive).
func open_messages(preferred_thread: String = "", preferred_message_id: String = "") -> bool:
	if runtime == null or comms_panel == null:
		return false
	if runtime.is_cutscene_active() or (mission_table != null and mission_table.is_open()) or (p01_panel != null and p01_panel.is_open()):
		return false
	if panels != null and not panels.active_panel().is_empty():
		return false
	_sync_messages()
	comms_panel.open_inbox(preferred_thread, preferred_message_id)
	return true

func _sync_messages() -> void:
	if comms_service == null or runtime == null:
		return
	var extra := {}
	if runtime.get("route") != null and runtime.route.has_method("gate_status"):
		var gate: Dictionary = runtime.route.gate_status()
		extra["physical_flags"] = gate.get("physical_flags", {})
	comms_service.sync_from_director(true, extra)
	if comms_panel != null and comms_panel.is_open():
		comms_panel.refresh_view()

func _is_dialogue_active() -> bool:
	if _dialogue_bar != null and (bool(_dialogue_bar.get_meta("lla_shown", _dialogue_bar.visible)) if _dialogue_bar.has_meta("lla_shown") else _dialogue_bar.visible):
		return true
	if runtime != null and _first_unacknowledged_line() < runtime.current_dialogue().size():
		return true
	return false

func _flush_message_toasts() -> void:
	if comms_service == null or not bool(comms_service.has_pending_toasts()):
		return
	if _chrome_hidden or _is_dialogue_active():
		return
	if _toast_timer > 0.0 and _toast != null and _toast.visible:
		return
	var next_toast: Dictionary = comms_service.pop_toast()
	if not next_toast.is_empty():
		show_status(String(next_toast.get("text", "")))

## Opens the "Previously at Aurora" resume card (doc 24 §6.6) over the live
## scene. Returns false while another panel, the Mission Table or a film is up.
func show_resume_card() -> bool:
	if runtime == null or panels == null or not panels.active_panel().is_empty():
		return false
	if (mission_table != null and mission_table.is_open()) or (p01_panel != null and p01_panel.is_open()) or runtime.is_cutscene_active():
		return false
	_refresh_query()
	return panels.open_panel("resume")

func _offer_resume_card() -> void:
	if not _resume_pending or runtime == null or runtime.loading:
		return
	if runtime.is_cutscene_active():
		if not runtime.cutscene_closed.is_connected(_on_resume_cutscene_closed):
			runtime.cutscene_closed.connect(_on_resume_cutscene_closed, CONNECT_ONE_SHOT)
		return
	_resume_pending = false
	show_resume_card()

func _on_resume_cutscene_closed(_result: Dictionary) -> void:
	_offer_resume_card.call_deferred()

func _on_save_pressed() -> void:
	if runtime != null:
		runtime.save_campaign()

func _on_exit_pressed() -> void:
	if runtime != null:
		runtime.exit_to_title()

func _refresh_query() -> void:
	if panels != null and runtime != null:
		var query := runtime.query()
		panels.bind_query(query)
		if outpost != null:
			outpost.set_settings(query.get("accessibility", {}))
			outpost.bind_query(query, _forecast)

## Applies captions and large text to every HUD element (panels do their own).
func apply_accessibility() -> void:
	if runtime == null:
		return
	var settings: Dictionary = runtime.query().get("accessibility", {})
	var captions := bool(settings.get("captions", true))
	_caption_speaker.visible = captions
	_caption_line.visible = captions
	_caption_count.visible = captions
	var scale := 1.5 if bool(settings.get("large_text", false)) else 1.0
	UiDesign.apply_type(self, get_viewport_rect().size.y, scale, [panels, mission_table, chapter4_panel, chapter6_panel, chapter8_panel, p01_panel, comms_panel])
	if comms_panel != null:
		comms_panel.set_text_scale(bool(settings.get("large_text", false)))
	if runtime.audio != null:
		runtime.audio.set_caption_layout(_dialogue_bar, settings)
	if outpost != null:
		outpost.set_settings(settings)

func _on_panel_opened(_panel_id: String) -> void:
	if p01_panel != null and p01_panel.is_open() and _panel_id != "p01":
		p01_panel.set_covered(true)
	if not _modal_reading:
		_reading_was_paused = bool(runtime.query().get("paused", false))
		_modal_reading = true
	runtime.set_ui_paused(true)
	_set_modal_buttons(true)
	_set_chrome_hidden(true)
	_ui_sound("SFX_UI_CONFIRM")

func _on_panel_closed(_panel_id: String) -> void:
	if p01_panel != null and p01_panel.is_open():
		p01_panel.set_covered(not panels.active_panel().is_empty() or panels.hint_player.is_open())
	var reading: bool = not panels.active_panel().is_empty() or mission_table.is_open() or (chapter4_panel != null and chapter4_panel.is_open()) or (chapter6_panel != null and chapter6_panel.is_open()) or (chapter8_panel != null and chapter8_panel.is_open()) or (p01_panel != null and p01_panel.is_open()) or (comms_panel != null and bool(comms_panel.is_open())) or panels.hint_player.is_open()
	runtime.set_ui_paused(reading or _reading_was_paused)
	_modal_reading = reading
	_set_modal_buttons(reading)
	_set_chrome_hidden(reading)
	_render_caption()
	_flush_message_toasts()

## Hides the flat HUD while a panel or instrument has the screen (doc 25 §2.2).
func _set_chrome_hidden(hidden: bool) -> void:
	_chrome_hidden = hidden
	_goal_card.visible = not hidden
	_marker.visible = _marker.visible and not hidden
	_prompt.visible = _prompt.visible and not hidden
	if eva_visor != null and hidden:
		eva_visor.visible = false
	if hidden:
		_dialogue_bar.visible = false
		_toast.visible = false
		outpost.hide_now()
	elif _toast_timer > 0.0:
		_fade(_toast, true)

func _set_modal_buttons(disabled: bool, node: Node = self) -> void:
	if not disabled:
		for button in _modal_button_states:
			if is_instance_valid(button):
				button.disabled = bool(_modal_button_states[button])
		_modal_button_states.clear()
		return
	for child in node.get_children():
		if child == panels or child == mission_table or child == chapter4_panel or child == chapter6_panel or child == chapter8_panel or child == p01_panel or child == comms_panel or child == _what_now_home:
			continue
		if child is BaseButton:
			if not _modal_button_states.has(child):
				_modal_button_states[child] = child.disabled
			child.disabled = true
		_set_modal_buttons(true, child)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).physical_keycode
	var free: bool = panels != null and not panels.hint_player.is_open() and panels.active_panel().is_empty() and (mission_table == null or not mission_table.is_open()) and (chapter4_panel == null or not chapter4_panel.is_open()) and (chapter6_panel == null or not chapter6_panel.is_open()) and (chapter8_panel == null or not chapter8_panel.is_open()) and (p01_panel == null or not p01_panel.is_open()) and (comms_panel == null or not bool(comms_panel.is_open()))
	if key == KEY_ESCAPE and free:
		panels.open_panel("pause")
		get_viewport().set_input_as_handled()
	elif key == KEY_M:
		if free:
			open_messages()
			get_viewport().set_input_as_handled()
		elif comms_panel != null and bool(comms_panel.is_open()):
			comms_panel.close_inbox()
			get_viewport().set_input_as_handled()
	elif key == KEY_H:
		if free:
			panels.open_panel("what_now")
			get_viewport().set_input_as_handled()
		elif panels != null and panels.active_panel() == "what_now":
			panels.close_panel()
			get_viewport().set_input_as_handled()
	elif (key == KEY_ENTER or key == KEY_KP_ENTER) and free and _advance.visible and not _advance.disabled:
		_on_advance_pressed()
		get_viewport().set_input_as_handled()
	elif key == KEY_SPACE and free and _dialogue_bar.visible and not _next_line.disabled:
		_on_next_line()
		get_viewport().set_input_as_handled()
	elif key == KEY_F10 and OS.is_debug_build():
		_debug_on = not _debug_on
		_debug.visible = _debug_on
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if runtime == null or runtime.loading:
		return
	if _toast_timer > 0.0 and _toast.visible:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_fade(_toast, false)
	if (_toast_timer <= 0.0 or not _toast.visible) and comms_service != null and comms_service.has_pending_toasts():
		_flush_message_toasts()
	if _auto_on and _dialogue_bar.visible and not _next_line.disabled and not _chrome_hidden and not runtime.is_cutscene_active():
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			_on_next_line()
	if eva_visor != null:
		var suit = runtime.get("eva_suit")
		if suit != null and eva_visor.suit != suit:
			eva_visor.bind_suit(suit)
		var show_visor: bool = suit != null and (not bool(suit.get("indoor")) or bool(suit.get("scanner_pulse_active"))) and not _chrome_hidden and not runtime.is_cutscene_active()
		eva_visor.visible = show_visor
		if show_visor:
			eva_visor.refresh()
	_update_world_overlay()

## Projects the goal marker (with distance) and the prompt on the object in reach.
func _update_world_overlay() -> void:
	var player: Node3D = runtime.get("_player") as Node3D if runtime != null else null
	if not is_instance_valid(player) or not player.is_inside_tree():
		_marker.visible = false
		_prompt.visible = false
		return
	if (_chrome_hidden and not (panels.hint_player.is_open() and panels.hint_player.mode == "hint" and panels.hint_player.level == 1)) or runtime.is_cutscene_active():
		_marker.visible = false
		_prompt.visible = false
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_marker.visible = false
		_prompt.visible = false
		return
	var view := get_viewport_rect().size
	var margin := float(_margin())
	var marker_tokens: Dictionary = UiDesign.tokens().get("world_marker", {})
	var lift := Vector3.UP * float(marker_tokens.get("height_m", 1.35))
	var nearby_node: Node3D = runtime.physical_target(_nearby_id) if not _nearby_id.is_empty() else null
	if is_instance_valid(nearby_node) and nearby_node.is_inside_tree():
		_prompt_label.text = _prompt_text(_nearby_id)
		var point := _project(camera, nearby_node.global_position + lift * 0.6, view, margin)
		_prompt.size = Vector2.ZERO
		_prompt.position = (point - Vector2(_prompt.size.x * 0.5, -8)).clamp(Vector2(margin, margin), view - _prompt.size - Vector2(margin, margin))
		_clear_of_cards(_prompt)
		_prompt.visible = true
	else:
		_prompt.visible = false
	if _marker_node == null or not is_instance_valid(_marker_node) or not _marker_node.is_inside_tree() or (nearby_node != null and nearby_node == _marker_node and not panels.hint_player.is_open()):
		_marker.visible = false
		return
	var distance := _distance_to(_marker_node)
	var fade := float(marker_tokens.get("fade_within_m", 3.0))
	var alpha := clampf((distance - fade) / 1.5, 0.35, 1.0)
	var behind := camera.is_position_behind(_marker_node.global_position + lift)
	var point := _project(camera, _marker_node.global_position + lift, view, margin)
	var inside := not behind and point.x > margin and point.x < view.x - margin and point.y > margin and point.y < view.y - margin
	_marker.dimmed = not inside
	_marker.set_distance(UiDesign.distance_text(distance))
	_marker.position = point - _marker.size * Vector2(0.5, 0.25)
	_clear_of_cards(_marker)
	_marker.modulate.a = alpha if inside else 0.6
	_marker.visible = true
	_marker.queue_redraw()
	if panels != null and panels.active_panel() == "what_now":
		_update_where()

## Keeps a projected marker or prompt from drawing over the goal card or the
## top-right column (large text makes both taller): it drops just below them.
func _clear_of_cards(control: Control) -> void:
	for card: Control in [_goal_card, _column]:
		if card.visible and card.get_rect().intersects(Rect2(control.position, control.size)):
			control.position.y = card.get_rect().end.y + 8.0

func _project(camera: Camera3D, world_point: Vector3, view: Vector2, margin: float) -> Vector2:
	var point := camera.unproject_position(world_point)
	if camera.is_position_behind(world_point):
		point = Vector2(view.x - point.x, view.y - margin)
	return point.clamp(Vector2(margin, margin), view - Vector2(margin, margin))

func _prompt_text(target_id: String) -> String:
	for raw_target in runtime.targets_for_current_scene():
		if raw_target is Dictionary and String(raw_target.get("target_id", "")) == target_id:
			return String(_target_text(raw_target).get("prompt", ""))
	return ""

func _fade(control: Control, shown: bool) -> void:
	var settings: Dictionary = runtime.query().get("accessibility", {}) if runtime != null else {}
	var seconds := UiDesign.motion_seconds("show_seconds" if shown else "hide_seconds", settings)
	if seconds <= 0.0 or not is_inside_tree():
		control.visible = shown
		control.modulate.a = 1.0
		control.set_meta("lla_shown", shown)
		return
	var previous = control.get_meta("lla_fade") if control.has_meta("lla_fade") else null
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()  # a late hide callback must not hide what was just shown
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	control.set_meta("lla_fade", tween)
	control.set_meta("lla_shown", shown)
	if shown:
		control.modulate.a = 0.0
		control.visible = true
		tween.tween_property(control, "modulate:a", 1.0, seconds)
	else:
		tween.tween_property(control, "modulate:a", 0.0, seconds)
		tween.tween_callback(func() -> void:
			control.visible = false
			control.modulate.a = 1.0)

func _ui_sound(sfx_id: String) -> void:
	if runtime == null or runtime.audio == null:
		return
	var audio = runtime.audio
	if audio.runtime != null and audio.has_method("_play_oneshot"):
		audio._play_oneshot(audio.runtime.sfx_plan(sfx_id))

## Forecast of one job for the station strip ("Battery 14 → 15 if you do this").
func show_target_forecast(target_id: String, source: String = "ui") -> void:
	if runtime == null or target_id.is_empty():
		return
	var key := "%s:%s:%s" % [runtime.route.current_scene_id(), target_id, runtime.director.query().state_revision]
	if key == _forecast_key:
		return
	_forecast_key = key
	_forecast_source = source
	if key == _forecast_cache_key and not _forecast_cache.is_empty():
		_forecast = _forecast_cache.duplicate(true)
	else:
		_forecast = runtime.forecast_target(target_id)
		_forecast_cache_key = key
		_forecast_cache = _forecast.duplicate(true)
	outpost.bind_query(runtime.query(), _forecast)
	outpost.tooltip_text = "What this job would change. Nothing changes until you do it." if bool(_forecast.get("accepted", false)) else UiDesign.player_words(String(_forecast.get("reason", "Do the earlier jobs first to see this forecast.")))

## Called every physics frame by the campaign with the job in reach (or "").
func show_nearby_forecast(target_id: String) -> void:
	_nearby_id = target_id
	if _pointer_preview or _focus_preview:
		return
	if not target_id.is_empty():
		show_target_forecast(target_id, "nearby")
	elif _forecast_source == "nearby":
		_clear_unselected_forecast()

func _clear_unselected_forecast() -> void:
	if _pointer_preview or _focus_preview or runtime == null:
		return
	_forecast = {}
	_forecast_key = ""
	_forecast_source = ""
	outpost.bind_query(runtime.query())
