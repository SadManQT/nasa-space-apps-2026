extends Control
class_name SettingsMenu

## Steam-quality Settings, Controls & Saves menu (M3-70, doc 25 §2.3 & §11):
## - Display: resolution, window mode, V-sync, frame cap, quality preset, field of view
## - Audio: Master, Music, Voice, Effects (SFX) and Interface volume sliders
## - Controls: full keyboard & controller remapping with matching button glyphs & conflict swap
## - Captions & Assist: captions, subtitle size, reduced motion, timer-free, Story/Cadet/Expedition + Family/Class modes
## - Saves & Chapters: Continue, 3 manual slots + autosave (SaveSlotsPanel), Chapter Select, Pause Anywhere & Skip Viewed Cutscenes

signal closed
signal settings_changed(snapshot: Dictionary)
signal slot_loaded(slot_id: String, snapshot: Dictionary)
signal slot_saved(slot_id: String, result: Dictionary)
signal chapter_select_requested

const GameSettingsScript = preload("res://scripts/settings/game_settings.gd")
const SaveSlotsScript = preload("res://scripts/save/save_slots.gd")
const SaveSlotsPanelScript = preload("res://scripts/ui/save_slots.gd")
const ChapterSelectScript = preload("res://scripts/ui/chapter_select.gd")

const TABS := [
	["display", "Display"],
	["audio", "Audio"],
	["controls", "Controls"],
	["assist", "Captions & Assist"],
	["saves", "Saves & Chapters"],
]

var game_settings: GameSettings
var save_slots: SaveSlots
var runtime: Node = null
var active_tab: String = "display"

var _listening_action := ""
var _listening_device := ""
var _reset_confirm_pending := false
var _notice_text := ""

var _tab_bar: HBoxContainer
var _status_label: Label
var _scroll: ScrollContainer
var _body: VBoxContainer
var _embedded_slots_panel: SaveSlotsPanel
var _chapter_select_overlay: Control

func _init(p_settings: GameSettings = null, p_slots: SaveSlots = null) -> void:
	game_settings = p_settings if p_settings != null else GameSettingsScript.new()
	save_slots = p_slots if p_slots != null else SaveSlotsScript.new()

func _ready() -> void:
	name = "SettingsMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	_build_shell()
	show_tab(active_tab)

func bind_runtime(p_runtime: Node) -> void:
	runtime = p_runtime
	if runtime != null:
		if runtime.get("game_settings") is GameSettings:
			game_settings = runtime.get("game_settings")
		if runtime.get("save_slots") is SaveSlots:
			save_slots = runtime.get("save_slots")
		elif runtime.get("save_path") is String and not String(runtime.get("save_path")).is_empty():
			var validator := Callable(runtime, "restore_session") if runtime.has_method("restore_session") else Callable()
			save_slots = SaveSlotsScript.new(String(runtime.get("save_path")), validator)
	if is_inside_tree():
		show_tab(active_tab)

func show_tab(tab_id: String) -> void:
	active_tab = tab_id if TABS.any(func(item): return item[0] == tab_id) else "display"
	_listening_action = ""
	_listening_device = ""
	_rebuild_body()

func _build_shell() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.05, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	var glass := UiDesign.glass_panel()
	margin.add_child(glass)

	var root_col := VBoxContainer.new()
	root_col.add_theme_constant_override("separation", 12)
	glass.add_child(root_col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_col.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)
	title_box.add_child(UiDesign.label("Settings, Controls & Saves", "title", "accent"))
	title_box.add_child(UiDesign.label("Display, audio volumes, keyboard and controller bindings, captions, assist modes and save slots.", "caption", "muted"))

	var reset_btn := UiDesign.button("Reset to Defaults")
	reset_btn.name = "ResetSettingsButton"
	reset_btn.pressed.connect(_on_reset_pressed)
	header.add_child(reset_btn)

	var close_btn := UiDesign.button("Back (Esc)")
	close_btn.name = "CloseSettingsButton"
	close_btn.pressed.connect(func() -> void: closed.emit())
	header.add_child(close_btn)

	_tab_bar = HBoxContainer.new()
	_tab_bar.name = "SettingsTabs"
	_tab_bar.add_theme_constant_override("separation", 8)
	root_col.add_child(_tab_bar)
	for spec in TABS:
		var tid: String = spec[0]
		var tlabel: String = spec[1]
		var btn := UiDesign.button(tlabel)
		btn.name = "Tab_" + tid
		btn.pressed.connect(func() -> void:
			_reset_confirm_pending = false
			show_tab(tid))
		_tab_bar.add_child(btn)

	_status_label = UiDesign.label("All changes save automatically to this machine.", "body", "accent")
	_status_label.name = "SettingsStatusLabel"
	root_col.add_child(_status_label)

	var sep := HSeparator.new()
	root_col.add_child(sep)

	_scroll = ScrollContainer.new()
	_scroll.name = "SettingsScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	root_col.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.name = "SettingsBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	_scroll.add_child(_body)

func _rebuild_body() -> void:
	if _body == null:
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.free()
	_embedded_slots_panel = null
	if not _notice_text.is_empty():
		_status_label.text = _notice_text
	match active_tab:
		"display":
			_build_display_tab()
		"audio":
			_build_audio_tab()
		"controls":
			_build_controls_tab()
		"assist":
			_build_assist_tab()
		"saves":
			_build_saves_tab()
	var scale := float(game_settings.accessibility.get("subtitle_scale", 1.0)) if game_settings != null else 1.0
	UiDesign.apply_type(self, get_viewport_rect().size.y if is_inside_tree() else 720.0, scale)

func _build_display_tab() -> void:
	_body.add_child(UiDesign.label("Display & Graphics", "heading"))
	_body.add_child(UiDesign.label("Choose resolution, window mode, vertical sync, frame rate limit, rendering preset and camera field of view.", "caption", "muted"))

	# Resolution
	var res_card := UiDesign.glass_panel()
	_body.add_child(res_card)
	var res_col := VBoxContainer.new()
	res_col.add_theme_constant_override("separation", 6)
	res_card.add_child(res_col)
	var cur_res := String(game_settings.display.get("resolution", "1920x1080"))
	res_col.add_child(UiDesign.label("Resolution · Current: %s" % cur_res, "body", "ivory"))
	var res_row := HFlowContainer.new()
	res_row.add_theme_constant_override("h_separation", 8)
	res_row.add_theme_constant_override("v_separation", 8)
	res_col.add_child(res_row)
	for res_opt in GameSettingsScript.RESOLUTIONS:
		var btn := UiDesign.button((res_opt + " (Selected)") if res_opt == cur_res else res_opt)
		btn.name = "Res_" + res_opt
		btn.pressed.connect(func() -> void:
			game_settings.set_display_option("resolution", res_opt)
			_apply_and_notify("Resolution set to %s." % res_opt))
		res_row.add_child(btn)

	# Window Mode
	var win_card := UiDesign.glass_panel()
	_body.add_child(win_card)
	var win_col := VBoxContainer.new()
	win_col.add_theme_constant_override("separation", 6)
	win_card.add_child(win_col)
	var cur_win := String(game_settings.display.get("window_mode", "Windowed"))
	win_col.add_child(UiDesign.label("Window Mode · Current: %s" % cur_win, "body", "ivory"))
	var win_row := HBoxContainer.new()
	win_row.add_theme_constant_override("separation", 8)
	win_col.add_child(win_row)
	for mode_opt in GameSettingsScript.WINDOW_MODES:
		var btn := UiDesign.button((mode_opt + " (Selected)") if mode_opt == cur_win else mode_opt)
		btn.name = "WindowMode_" + mode_opt
		btn.pressed.connect(func() -> void:
			game_settings.set_display_option("window_mode", mode_opt)
			_apply_and_notify("Window mode set to %s." % mode_opt))
		win_row.add_child(btn)

	# V-Sync & Frame Cap
	var sync_card := UiDesign.glass_panel()
	_body.add_child(sync_card)
	var sync_col := VBoxContainer.new()
	sync_col.add_theme_constant_override("separation", 8)
	sync_card.add_child(sync_col)
	var vsync_on := bool(game_settings.display.get("vsync", true))
	var vsync_btn := UiDesign.button("Vertical Sync: ON (Prevents screen tearing)" if vsync_on else "Vertical Sync: OFF")
	vsync_btn.name = "VsyncToggle"
	vsync_btn.pressed.connect(func() -> void:
		var next_on := not bool(game_settings.display.get("vsync", true))
		game_settings.set_display_option("vsync", next_on)
		_apply_and_notify("Vertical Sync %s." % ("enabled" if next_on else "disabled")))
	sync_col.add_child(vsync_btn)

	var cur_cap := int(game_settings.display.get("frame_cap", 60))
	var cap_word := "Unlimited" if cur_cap <= 0 else ("%d FPS" % cur_cap)
	sync_col.add_child(UiDesign.label("Frame Rate Cap · Current: %s" % cap_word, "body", "ivory"))
	var cap_row := HBoxContainer.new()
	cap_row.add_theme_constant_override("separation", 8)
	sync_col.add_child(cap_row)
	for cap_opt in GameSettingsScript.FRAME_CAPS:
		var label_txt := "Unlimited" if cap_opt == 0 else ("%d FPS" % cap_opt)
		var btn := UiDesign.button((label_txt + " (Selected)") if cap_opt == cur_cap else label_txt)
		btn.name = "FrameCap_%d" % cap_opt
		btn.pressed.connect(func() -> void:
			game_settings.set_display_option("frame_cap", cap_opt)
			_apply_and_notify("Frame rate limit set to %s." % label_txt))
		cap_row.add_child(btn)

	# Quality Preset & Field of View
	var qual_card := UiDesign.glass_panel()
	_body.add_child(qual_card)
	var qual_col := VBoxContainer.new()
	qual_col.add_theme_constant_override("separation", 8)
	qual_card.add_child(qual_col)
	var cur_qual := String(game_settings.display.get("quality_preset", "High"))
	qual_col.add_child(UiDesign.label("Quality Preset · Current: %s" % cur_qual, "body", "ivory"))
	var qual_row := HBoxContainer.new()
	qual_row.add_theme_constant_override("separation", 8)
	qual_col.add_child(qual_row)
	for q_opt in GameSettingsScript.QUALITY_PRESETS:
		var btn := UiDesign.button((q_opt + " (Selected)") if q_opt == cur_qual else q_opt)
		btn.name = "Quality_" + q_opt
		btn.pressed.connect(func() -> void:
			game_settings.set_display_option("quality_preset", q_opt)
			_apply_and_notify("Graphics quality set to %s." % q_opt))
		qual_row.add_child(btn)

	var cur_fov := float(game_settings.display.get("fov", 75.0))
	var fov_lbl := UiDesign.label("Field of View (FOV): %d°" % int(round(cur_fov)), "body", "ivory")
	fov_lbl.name = "FovValueLabel"
	qual_col.add_child(fov_lbl)
	var fov_slider := HSlider.new()
	fov_slider.name = "FovSlider"
	fov_slider.min_value = 60.0
	fov_slider.max_value = 100.0
	fov_slider.step = 1.0
	fov_slider.value = cur_fov
	fov_slider.custom_minimum_size.y = 28
	fov_slider.value_changed.connect(func(v: float) -> void:
		fov_lbl.text = "Field of View (FOV): %d°" % int(round(v))
		game_settings.set_display_option("fov", v)
		if runtime != null:
			game_settings.apply_to_campaign(runtime)
		_notice_text = "Field of view set to %d°." % int(round(v))
		_status_label.text = _notice_text
		settings_changed.emit(game_settings.snapshot()))
	qual_col.add_child(fov_slider)

func _build_audio_tab() -> void:
	_body.add_child(UiDesign.label("Audio Mixing & Volumes", "heading"))
	_body.add_child(UiDesign.label("Adjust Master, Music, Dialogue Voice, Sound Effects and Interface volume levels.", "caption", "muted"))

	var audio_card := UiDesign.glass_panel()
	_body.add_child(audio_card)
	var audio_col := VBoxContainer.new()
	audio_col.add_theme_constant_override("separation", 12)
	audio_card.add_child(audio_col)

	var channels := [
		["Master", "Master volume"],
		["Music", "Music volume"],
		["Voice", "Voice & dialogue volume"],
		["SFX", "Effects volume"],
		["UI", "Interface volume"],
	]
	for entry in channels:
		var bus: String = entry[0]
		var title: String = entry[1]
		var current_val := float(game_settings.audio.get(bus, 1.0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		audio_col.add_child(row)

		var lbl := UiDesign.label("%s: %d%%" % [title, int(round(current_val * 100.0))], "body", "ivory")
		lbl.name = "VolumeLabel_" + bus
		lbl.custom_minimum_size.x = 280
		row.add_child(lbl)

		var slider := HSlider.new()
		slider.name = "Volume_" + bus
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 28
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = current_val
		slider.value_changed.connect(func(v: float) -> void:
			lbl.text = "%s: %d%%" % [title, int(round(v * 100.0))]
			game_settings.set_audio_volume(bus, v)
			_notice_text = "%s set to %d%%." % [title, int(round(v * 100.0))]
			_status_label.text = _notice_text
			settings_changed.emit(game_settings.snapshot()))
		row.add_child(slider)

func _build_controls_tab() -> void:
	_body.add_child(UiDesign.label("Keyboard & Controller Remapping", "heading"))
	_body.add_child(UiDesign.label("Select any keyboard key or controller button to rebind it. Duplicate bindings automatically swap with the other action.", "caption", "muted"))

	for spec in GameSettingsScript.REMAPPABLE_ACTIONS:
		var action_id: String = spec.id
		var label_text: String = spec.label
		var card := UiDesign.glass_panel()
		card.name = "BindRow_" + action_id
		_body.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		var action_lbl := UiDesign.label(label_text, "body", "ivory")
		action_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(action_lbl)

		# Keyboard glyph + rebind button
		var kb_glyph_txt := game_settings.keyboard_glyph(action_id)
		row.add_child(UiKit.key_glyph(kb_glyph_txt))
		var kb_listening := _listening_action == action_id and _listening_device == "keyboard"
		var kb_btn := UiDesign.button("Press any key..." if kb_listening else ("Key: " + kb_glyph_txt))
		kb_btn.name = "RebindKey_" + action_id
		kb_btn.pressed.connect(func() -> void:
			_listening_action = action_id
			_listening_device = "keyboard"
			_notice_text = "Press a keyboard key for %s (or Esc to keep %s)." % [label_text, kb_glyph_txt]
			_rebuild_body())
		row.add_child(kb_btn)

		# Controller glyph + rebind button
		var pad_glyph_txt := game_settings.controller_glyph(action_id)
		row.add_child(UiKit.key_glyph(pad_glyph_txt))
		var pad_listening := _listening_action == action_id and _listening_device == "controller"
		var pad_btn := UiDesign.button("Press controller button..." if pad_listening else ("Pad: " + pad_glyph_txt))
		pad_btn.name = "RebindPad_" + action_id
		pad_btn.pressed.connect(func() -> void:
			_listening_action = action_id
			_listening_device = "controller"
			_notice_text = "Press a controller button for %s." % label_text
			_rebuild_body())
		row.add_child(pad_btn)

func _build_assist_tab() -> void:
	_body.add_child(UiDesign.label("Captions, Subtitles & Assist Modes", "heading"))
	_body.add_child(UiDesign.label("Story canon and real lunar math stay identical in every mode; assist modes change only guidance and timer pressure.", "caption", "muted"))

	# Captions & Subtitle Size
	var cap_card := UiDesign.glass_panel()
	_body.add_child(cap_card)
	var cap_col := VBoxContainer.new()
	cap_col.add_theme_constant_override("separation", 8)
	cap_card.add_child(cap_col)

	var captions_on := bool(game_settings.accessibility.get("captions", true))
	var cap_toggle := UiDesign.button("Dialogue and sound captions: ON" if captions_on else "Dialogue and sound captions: OFF")
	cap_toggle.name = "CaptionsToggle"
	cap_toggle.pressed.connect(func() -> void:
		var next_on := not bool(game_settings.accessibility.get("captions", true))
		game_settings.set_accessibility_option("captions", next_on)
		_apply_and_notify("Captions %s." % ("enabled" if next_on else "disabled")))
	cap_col.add_child(cap_toggle)

	var cur_sub_size := String(game_settings.accessibility.get("subtitle_size", "Medium"))
	cap_col.add_child(UiDesign.label("Subtitle & Text Size · Current: %s (%d%%)" % [cur_sub_size, int(round(float(game_settings.accessibility.get("subtitle_scale", 1.0)) * 100.0))], "body", "ivory"))
	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 8)
	cap_col.add_child(sub_row)
	for sz_opt in GameSettingsScript.SUBTITLE_SIZES:
		var btn := UiDesign.button((sz_opt + " (Selected)") if sz_opt == cur_sub_size else sz_opt)
		btn.name = "SubtitleSize_" + sz_opt.replace(" ", "")
		btn.pressed.connect(func() -> void:
			game_settings.set_accessibility_option("subtitle_size", sz_opt)
			_apply_and_notify("Subtitle and text size set to %s." % sz_opt))
		sub_row.add_child(btn)

	var motion_on := bool(game_settings.accessibility.get("reduced_motion", false))
	var motion_toggle := UiDesign.button("Reduced motion: ON (Steady camera and instant menu transitions)" if motion_on else "Reduced motion: OFF")
	motion_toggle.name = "ReducedMotionToggle"
	motion_toggle.pressed.connect(func() -> void:
		var next_on := not bool(game_settings.accessibility.get("reduced_motion", false))
		game_settings.set_accessibility_option("reduced_motion", next_on)
		_apply_and_notify("Reduced motion %s." % ("enabled" if next_on else "disabled")))
	cap_col.add_child(motion_toggle)

	var timer_on := bool(game_settings.accessibility.get("timer_free", true))
	var timer_toggle := UiDesign.button("Timer-free play: ON (Take as long as you need on every decision)" if timer_on else "Timer-free play: OFF")
	timer_toggle.name = "TimerFreeToggle"
	timer_toggle.pressed.connect(func() -> void:
		var next_on := not bool(game_settings.accessibility.get("timer_free", true))
		game_settings.set_accessibility_option("timer_free", next_on)
		_apply_and_notify("Timer-free play %s." % ("enabled" if next_on else "disabled")))
	cap_col.add_child(timer_toggle)

	# Assist Modes (Story, Cadet, Expedition) + Session Modes (Solo, Family, Class)
	var assist_card := UiDesign.glass_panel()
	_body.add_child(assist_card)
	var assist_col := VBoxContainer.new()
	assist_col.add_theme_constant_override("separation", 8)
	assist_card.add_child(assist_col)

	var cur_assist := String(game_settings.accessibility.get("assist_mode", "Cadet"))
	assist_col.add_child(UiDesign.label("Assist Mode · Current: %s" % cur_assist, "body", "ivory"))
	var assist_descriptions := {
		"Story": "Story: Full hints and no timer pressure for enjoying the narrative and science.",
		"Cadet": "Cadet: Balanced guidance with standard station alerts and optional hints.",
		"Expedition": "Expedition: Minimal prompts for players who want to read the instruments directly.",
	}
	for mode_id in GameSettingsScript.ASSIST_MODES:
		var btn := UiDesign.button((mode_id + " (Selected) — " + assist_descriptions[mode_id]) if mode_id == cur_assist else (mode_id + " — " + assist_descriptions[mode_id]))
		btn.name = "AssistMode_" + mode_id
		btn.pressed.connect(func() -> void:
			game_settings.set_accessibility_option("assist_mode", mode_id)
			_apply_and_notify("Assist mode set to %s." % mode_id))
		assist_col.add_child(btn)

	var cur_session := String(game_settings.accessibility.get("session_mode", "Solo"))
	assist_col.add_child(UiDesign.label("Group & Classroom Session Mode · Current: %s" % cur_session, "body", "ivory"))
	var session_row := HBoxContainer.new()
	session_row.add_theme_constant_override("separation", 8)
	assist_col.add_child(session_row)
	for smode in GameSettingsScript.SESSION_MODES:
		var btn := UiDesign.button((smode + " Mode (Selected)") if smode == cur_session else (smode + " Mode"))
		btn.name = "SessionMode_" + smode
		btn.pressed.connect(func() -> void:
			game_settings.set_accessibility_option("session_mode", smode)
			_apply_and_notify("Session mode set to %s." % smode))
		session_row.add_child(btn)

	# Cutscene & Pause rules
	var cut_card := UiDesign.glass_panel()
	_body.add_child(cut_card)
	var cut_col := VBoxContainer.new()
	cut_col.add_theme_constant_override("separation", 6)
	cut_card.add_child(cut_col)
	cut_col.add_child(UiDesign.label("Cutscenes & Pause Rules", "body", "ivory"))

	var skip_on := game_settings.skip_viewed_cutscenes
	var skip_toggle := UiDesign.button("Skip any cutscene immediately after the first viewing: ON" if skip_on else "Skip any cutscene immediately after the first viewing: OFF")
	skip_toggle.name = "SkipViewedCutscenesToggle"
	skip_toggle.pressed.connect(func() -> void:
		var next_on := not game_settings.skip_viewed_cutscenes
		game_settings.skip_viewed_cutscenes = next_on
		game_settings.save_to_disk()
		_apply_and_notify("Instant skip for viewed cutscenes %s." % ("enabled" if next_on else "disabled")))
	cut_col.add_child(skip_toggle)

	var pause_lbl := UiDesign.label("Pause Anywhere: Active — Press Esc or Start at any moment during free movement, puzzles or films to pause.", "caption", "good")
	pause_lbl.name = "PauseAnywhereStatus"
	cut_col.add_child(pause_lbl)

func _build_saves_tab() -> void:
	_body.add_child(UiDesign.label("Save Slots, Continue & Chapter Select", "heading"))
	_body.add_child(UiDesign.label("Autosaves happen at every scene join and mission end. Three manual slots keep independent backups.", "caption", "muted"))

	var top_card := UiDesign.glass_panel()
	_body.add_child(top_card)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_card.add_child(top_row)

	var candidate := save_slots.continue_candidate()
	var has_continue := bool(candidate.get("valid", false)) or bool(candidate.get("backup_valid", false))
	var cont_text := "Continue Latest (%s · %s)" % [String(candidate.get("slot_label", "Autosave")), String(candidate.get("chapter_title", "Chapter 1"))] if has_continue else "Continue Latest (No saved game yet)"
	var cont_btn := UiDesign.button(cont_text)
	cont_btn.name = "ContinueLatestButton"
	cont_btn.disabled = not has_continue
	cont_btn.pressed.connect(func() -> void:
		var slot_id := String(candidate.get("slot_id", SaveSlotsScript.AUTOSAVE_SLOT))
		var loaded := save_slots.load_slot(slot_id, true)
		if bool(loaded.get("accepted", false)):
			if runtime != null and runtime.has_method("load_from_slot"):
				runtime.call("load_from_slot", slot_id)
			slot_loaded.emit(slot_id, loaded.get("snapshot", {}))
			_notice_text = "Loaded %s." % String(candidate.get("slot_label", slot_id))
			_rebuild_body())
	top_row.add_child(cont_btn)

	var ch_btn := UiDesign.button("Open Chapter Select & Achievements")
	ch_btn.name = "OpenChapterSelectButton"
	ch_btn.pressed.connect(_open_chapter_select_overlay)
	top_row.add_child(ch_btn)

	_embedded_slots_panel = SaveSlotsPanelScript.new(save_slots)
	_embedded_slots_panel.name = "EmbeddedSaveSlotsPanel"
	_embedded_slots_panel.custom_minimum_size = Vector2(0, 520)
	_embedded_slots_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_embedded_slots_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if runtime != null and runtime.has_method("_save_snapshot"):
		_embedded_slots_panel.bind_snapshot_provider(Callable(runtime, "_save_snapshot"))
	_embedded_slots_panel.slot_loaded.connect(func(slot_id: String, snap: Dictionary, _meta: Dictionary) -> void:
		if runtime != null and runtime.has_method("load_from_slot"):
			runtime.call("load_from_slot", slot_id)
		slot_loaded.emit(slot_id, snap))
	_embedded_slots_panel.slot_saved.connect(func(slot_id: String, meta: Dictionary) -> void:
		slot_saved.emit(slot_id, meta))
	_body.add_child(_embedded_slots_panel)

func _open_chapter_select_overlay() -> void:
	chapter_select_requested.emit()
	if is_instance_valid(_chapter_select_overlay):
		_chapter_select_overlay.queue_free()
	var panel := ChapterSelectScript.new()
	panel.save_path = save_slots.base_save_path
	panel.z_index = 120
	panel.exit_requested.connect(func() -> void:
		if is_instance_valid(_chapter_select_overlay):
			_chapter_select_overlay.queue_free()
			_chapter_select_overlay = null)
	_chapter_select_overlay = panel
	add_child(panel)

func _on_reset_pressed() -> void:
	if not _reset_confirm_pending:
		_reset_confirm_pending = true
		_notice_text = "Press Reset to Defaults again to restore all display, audio, control and assist defaults."
		_status_label.text = _notice_text
		return
	_reset_confirm_pending = false
	game_settings.reset_to_defaults(true)
	_apply_and_notify("All settings restored to defaults.")

func _apply_and_notify(message: String) -> void:
	_notice_text = message
	if runtime != null:
		game_settings.apply_to_campaign(runtime)
	else:
		game_settings.apply_all()
	settings_changed.emit(game_settings.snapshot())
	_rebuild_body()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not _listening_action.is_empty():
		if _listening_device == "keyboard" and event is InputEventKey and event.pressed and not event.echo:
			var key_ev := event as InputEventKey
			var code := int(key_ev.physical_keycode if key_ev.physical_keycode != KEY_NONE else key_ev.keycode)
			var act := _listening_action
			_listening_action = ""
			_listening_device = ""
			var res := game_settings.remap_keyboard(act, code)
			var swapped := String(res.get("swapped_with", ""))
			if not swapped.is_empty():
				_notice_text = "Bound %s to [%s] (swapped with %s)." % [act.replace("_", " "), String(res.get("glyph", "")), swapped.replace("_", " ")]
			else:
				_notice_text = "Bound %s to [%s]." % [act.replace("_", " "), String(res.get("glyph", ""))]
			settings_changed.emit(game_settings.snapshot())
			_rebuild_body()
			get_viewport().set_input_as_handled()
			return
		elif _listening_device == "controller" and event is InputEventJoypadButton and event.pressed:
			var joy_ev := event as InputEventJoypadButton
			var btn := int(joy_ev.button_index)
			var act := _listening_action
			_listening_action = ""
			_listening_device = ""
			var res := game_settings.remap_controller(act, btn)
			var swapped := String(res.get("swapped_with", ""))
			if not swapped.is_empty():
				_notice_text = "Bound %s to %s (swapped with %s)." % [act.replace("_", " "), String(res.get("glyph", "")), swapped.replace("_", " ")]
			else:
				_notice_text = "Bound %s to %s." % [act.replace("_", " "), String(res.get("glyph", ""))]
			settings_changed.emit(game_settings.snapshot())
			_rebuild_body()
			get_viewport().set_input_as_handled()
			return
	var back: bool = event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	if back and not event.is_echo():
		if is_instance_valid(_chapter_select_overlay):
			_chapter_select_overlay.queue_free()
			_chapter_select_overlay = null
		else:
			closed.emit()
		get_viewport().set_input_as_handled()
