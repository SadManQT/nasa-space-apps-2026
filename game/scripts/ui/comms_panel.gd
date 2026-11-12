class_name CommsPanel
extends Control
## Full-screen modal Messages inbox (`M` key or Pause -> Messages).
## Displays the 5 station threads (Crew, Commander, Earth, Academy, Archive),
## unread counts, delivered crew notes, and a portrait-led message reader.

signal opened
signal closed
signal message_read(message_id: String)

const UiDesign = preload("res://scripts/ui/ui_design.gd")
const CommsServiceScript = preload("res://scripts/comms/comms_service.gd")

var comms_service: RefCounted = null
var active_thread: String = "crew"
var selected_message_id: String = ""
var large_text: bool = false
var sender_filter: String = ""

var _title_label: Label
var _unread_summary_label: Label
var _thread_list_box: VBoxContainer
var _thread_buttons: Dictionary = {}
var _message_list_box: VBoxContainer
var _message_buttons: Dictionary = {}
var _empty_list_label: Label
var _detail_sender_label: Label
var _detail_time_label: Label
var _detail_subject_label: Label
var _detail_goal_badge: Label
var _detail_body_label: Label
var _close_btn: Button
var _sender_portrait: TextureRect
var _bubble_portrait: TextureRect
var _sender_role_label: Label
var _channel_label: Label
var _crew_notes_list: VBoxContainer
var _crew_buttons: Dictionary = {}
var _all_messages_button: Button
var _goal_subject_label: Label
var _portrait_views: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func _layout() -> void:
	pass


func bind_service(service: RefCounted) -> void:
	comms_service = service
	refresh_view()


func open_inbox(preferred_thread: String = "", preferred_message_id: String = "") -> void:
	if comms_service != null:
		comms_service.sync_from_director(false)
	if not preferred_thread.is_empty():
		active_thread = preferred_thread
		sender_filter = ""
	elif active_thread.is_empty():
		active_thread = "crew"
	if not preferred_message_id.is_empty():
		sender_filter = ""
		var msg: Dictionary = comms_service.message_by_id(preferred_message_id) if comms_service != null else {}
		if not msg.is_empty():
			active_thread = String(msg.get("thread", active_thread))
			selected_message_id = preferred_message_id
	else:
		_pick_initial_thread_if_empty()
	visible = true
	_layout()
	refresh_view()
	opened.emit()
	_grab_initial_focus()


func is_open() -> bool:
	return visible


func close_inbox() -> void:
	if not visible:
		return
	visible = false
	_clear_portraits()
	closed.emit()


func set_text_scale(is_large: bool) -> void:
	large_text = is_large
	_apply_font_sizes()
	refresh_view()


func select_thread(thread_id: String) -> void:
	if not CommsServiceScript.THREAD_ORDER.has(thread_id):
		return
	active_thread = thread_id
	sender_filter = ""
	selected_message_id = ""
	refresh_view()


func select_message(message_id: String) -> void:
	if comms_service == null:
		return
	var msg: Dictionary = comms_service.message_by_id(message_id)
	if msg.is_empty() or not bool(msg.get("delivered", false)):
		return
	active_thread = String(msg.get("thread", active_thread))
	if not sender_filter.is_empty() and String(msg.get("sender", "")) != sender_filter:
		sender_filter = ""
	selected_message_id = message_id
	var res: Dictionary = comms_service.mark_read(message_id)
	if bool(res.get("ok", false)):
		message_read.emit(message_id)
	refresh_view()
	if _message_buttons.has(message_id):
		(_message_buttons[message_id] as Button).grab_focus()


func select_sender(sender: String) -> void:
	sender_filter = sender
	selected_message_id = ""
	refresh_view()
	if _crew_buttons.has(sender):
		(_crew_buttons[sender] as Button).grab_focus()
	else:
		_all_messages_button.grab_focus()


func _pick_initial_thread_if_empty() -> void:
	if comms_service == null:
		return
	var current_msgs: Array = comms_service.messages_for_thread(active_thread)
	if not current_msgs.is_empty():
		return
	for tid in CommsServiceScript.THREAD_ORDER:
		if int(comms_service.unread_count(tid)) > 0:
			active_thread = tid
			return
	for tid in CommsServiceScript.THREAD_ORDER:
		if not (comms_service.messages_for_thread(tid) as Array).is_empty():
			active_thread = tid
			return


func _grab_initial_focus() -> void:
	if not selected_message_id.is_empty() and _message_buttons.has(selected_message_id):
		var mbtn: Button = _message_buttons[selected_message_id]
		if is_instance_valid(mbtn):
			mbtn.grab_focus()
			return
	if _thread_buttons.has(active_thread):
		var tbtn: Button = _thread_buttons[active_thread]
		if is_instance_valid(tbtn):
			tbtn.grab_focus()
			return
	if _close_btn != null:
		_close_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_M:
			close_inbox()
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var shell: Control = self
	if not has_node("OuterMargin"):
		shell = load("res://scenes/ui/comms_panel.tscn").instantiate()
		shell.set_script(null)
		add_child(shell)
	theme = UiKit.theme()
	_title_label = shell.find_child("TitleLabel", true, false)
	_unread_summary_label = shell.find_child("UnreadSummaryLabel", true, false)
	_thread_list_box = shell.find_child("ThreadListBox", true, false)
	_message_list_box = shell.find_child("MessageListBox", true, false)
	_empty_list_label = shell.find_child("EmptyListLabel", true, false)
	_detail_sender_label = shell.find_child("DetailSenderLabel", true, false)
	_detail_time_label = shell.find_child("DetailTimeLabel", true, false)
	_detail_subject_label = shell.find_child("DetailSubjectLabel", true, false)
	_detail_goal_badge = shell.find_child("DetailGoalBadge", true, false)
	_detail_body_label = shell.find_child("DetailBodyLabel", true, false)
	_close_btn = shell.find_child("CloseButton", true, false)
	_sender_portrait = shell.find_child("SenderPortrait", true, false)
	_bubble_portrait = shell.find_child("BubblePortrait", true, false)
	_sender_role_label = shell.find_child("SenderRoleLabel", true, false)
	_channel_label = shell.find_child("ChannelLabel", true, false)
	_crew_notes_list = shell.find_child("CrewNotesList", true, false)
	_all_messages_button = shell.find_child("AllMessagesButton", true, false)
	_goal_subject_label = shell.find_child("GoalSubjectLabel", true, false)
	var reader_scroll := shell.find_child("DetailBodyScroll", true, false) as ScrollContainer
	reader_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	_close_btn.pressed.connect(close_inbox)
	_all_messages_button.pressed.connect(func(): select_sender(""))
	for label in shell.find_children("*", "Label", true, false):
		UiDesign.style_label(label, String(label.get_meta("lla_type", "body")), "ivory")
	for compact_name in ["ThreadHeader", "ListHeader"]:
		(shell.find_child(compact_name, true, false) as Label).autowrap_mode = TextServer.AUTOWRAP_OFF
	for tid in CommsServiceScript.THREAD_ORDER:
		var button := shell.find_child("Thread_" + tid, true, false) as Button
		var channel := String(tid)
		button.pressed.connect(func(): select_thread(channel))
		_thread_buttons[tid] = button
	_apply_font_sizes()


func _apply_font_sizes() -> void:
	var scale := 1.5 if large_text else 1.0
	var vh := 1080.0
	if is_inside_tree():
		vh = get_viewport_rect().size.y
	UiDesign.apply_type(self, vh, scale)
	for label in [_title_label, _detail_sender_label]:
		label.add_theme_font_size_override("font_size", roundi(UiDesign.font_px("title", vh, scale) * 1.25))
	_detail_body_label.add_theme_font_size_override("font_size", roundi(UiDesign.font_px("body", vh, scale) * 1.4))
	_sender_role_label.add_theme_font_size_override("font_size", roundi(UiDesign.font_px("body", vh, scale) * 1.25))


func refresh_view() -> void:
	if _thread_list_box == null:
		return
	_rebuild_message_list()
	var total_unread: int = int(comms_service.unread_count()) if comms_service != null else 0
	if _unread_summary_label != null:
		if total_unread <= 0:
			_unread_summary_label.text = "All messages read"
		elif total_unread == 1:
			_unread_summary_label.text = "1 unread message"
		else:
			_unread_summary_label.text = "%d unread messages" % total_unread

	var threads: Array = comms_service.threads_view() if comms_service != null else []
	for tid in _thread_buttons:
		var button: Button = _thread_buttons[tid]
		var active: bool = tid == active_thread
		button.toggle_mode = true
		button.button_pressed = active
		UiDesign.nav_item(button, active)  # Deep Space sidebar: leading bar, no solid block
		button.add_theme_color_override("icon_normal_color", UiDesign.colour("ink" if active else "ivory"))
	for tinfo in threads:
		var tid := String(tinfo.get("id", ""))
		if not _thread_buttons.has(tid):
			continue
		var btn: Button = _thread_buttons[tid]
		var label_str := String({"earth": "Earth link", "archive": "Recordings"}.get(tid, tinfo.get("label", tid.capitalize())))
		var u_count := int(tinfo.get("unread_count", 0))
		var t_count := int(tinfo.get("total_count", 0))
		if u_count > 0:
			btn.text = "%s  ·  %d new" % [label_str, u_count]
		elif t_count > 0:
			btn.text = "%s  (%d)" % [label_str, t_count]
		else:
			btn.text = label_str

	_refresh_detail_pane()
	_rebuild_crew_notes()
	_apply_font_sizes()


func _rebuild_message_list() -> void:
	_message_buttons.clear()
	for child in _message_list_box.get_children():
		if child != _empty_list_label:
			_message_list_box.remove_child(child)
			child.queue_free()

	var msgs: Array = comms_service.messages_for_thread(active_thread) if comms_service != null else []
	if not sender_filter.is_empty():
		msgs = msgs.filter(func(msg): return String(msg.get("sender", "")) == sender_filter)
	_all_messages_button.text = "All messages" if sender_filter.is_empty() else "All messages · clear filter"
	_all_messages_button.button_pressed = sender_filter.is_empty()
	if msgs.is_empty():
		_empty_list_label.visible = true
		selected_message_id = ""
		return

	_empty_list_label.visible = false
	var found_selected := false
	for msg in msgs:
		if String(msg.get("id", "")) == selected_message_id:
			found_selected = true
			break
	if not found_selected:
		selected_message_id = String(msgs[0].get("id", ""))
		if visible and comms_service != null and not bool(msgs[0].get("read", false)):
			var res: Dictionary = comms_service.mark_read(selected_message_id)
			if bool(res.get("ok", false)):
				msgs[0]["read"] = true
				message_read.emit(selected_message_id)

	for msg in msgs:
		var msg_id := String(msg.get("id", ""))
		var sender := String(msg.get("sender", "Station"))
		var subject := String(msg.get("subject", ""))
		var is_msg_read := bool(msg.get("read", false))
		var prefix := "● " if not is_msg_read else ""
		var mbtn := UiDesign.button("%s%s — %s" % [prefix, sender, subject], 48)
		mbtn.name = "MsgItem_" + msg_id
		mbtn.custom_minimum_size = Vector2(0, 64)
		mbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		mbtn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mbtn.set_meta("verbatim", true)
		mbtn.toggle_mode = true
		mbtn.button_pressed = msg_id == selected_message_id
		var captured_id := msg_id
		mbtn.pressed.connect(func() -> void: select_message(captured_id))
		_message_list_box.add_child(mbtn)
		_message_buttons[msg_id] = mbtn


func _refresh_detail_pane() -> void:
	if comms_service == null or selected_message_id.is_empty():
		_detail_sender_label.text = String(CommsServiceScript.THREAD_LABELS.get(active_thread, "Channel")).to_upper()
		_detail_time_label.text = ""
		_detail_subject_label.text = "No message selected"
		_detail_goal_badge.visible = false
		_detail_body_label.text = "When messages arrive on this channel, select one from the inbox list to read it."
		_sender_role_label.text = "Station inbox"
		_channel_label.text = "STORED MESSAGES"
		_sender_portrait.texture = null
		_bubble_portrait.texture = null
		_sender_portrait.visible = false
		_bubble_portrait.visible = false
		_goal_subject_label.text = "No next step received on this channel."
		return

	var msg: Dictionary = comms_service.message_by_id(selected_message_id)
	if msg.is_empty():
		return

	var sender := String(msg.get("sender", "Station"))
	_detail_sender_label.text = sender
	_sender_role_label.text = _sender_role(sender)
	_sender_role_label.add_theme_color_override("font_color", UiDesign.colour(sender.to_lower(), UiDesign.colour("muted")))
	_channel_label.text = "STORED RECORDING" if active_thread == "archive" else "STORED MESSAGE"
	var portrait := _portrait_for_sender(sender)
	_sender_portrait.texture = portrait
	_bubble_portrait.texture = portrait
	_sender_portrait.visible = true
	_bubble_portrait.visible = true
	_detail_time_label.text = String(msg.get("formatted_time", ""))
	_detail_subject_label.text = String(msg.get("subject", ""))
	_detail_goal_badge.visible = bool(msg.get("goal", false))
	_detail_body_label.text = String(msg.get("body", ""))
	var goal: Dictionary = comms_service.latest_goal_message()
	_goal_subject_label.text = String(goal.get("subject", "No next step received."))


func _rebuild_crew_notes() -> void:
	_crew_buttons.clear()
	for child in _crew_notes_list.get_children():
		_crew_notes_list.remove_child(child)
		child.queue_free()
	var senders: Dictionary = {}
	var msgs: Array = comms_service.messages_for_thread(active_thread) if comms_service != null else []
	for msg in msgs:
		var sender := String(msg.get("sender", "Station"))
		if not senders.has(sender):
			senders[sender] = 0
		senders[sender] += 1
	for sender in senders:
		var button := UiDesign.button("%s\n%s · %d notes" % [sender, _sender_role(sender), senders[sender]], 60)
		button.name = "CrewNote_" + String(sender).validate_node_name()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.icon = _portrait_for_sender(sender)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 44)
		button.toggle_mode = true
		button.button_pressed = sender_filter == sender
		var tint := UiDesign.colour(String(sender).to_lower(), UiDesign.colour("glass_edge"))
		var selected: bool = sender_filter == sender
		var style := UiDesign.glass_style(tint if selected else UiDesign.colour("glass_edge"), UiDesign.colour("navy").lightened(0.1) if selected else UiDesign.colour("navy"), 8)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_color_override("font_pressed_color", UiDesign.colour("ivory"))
		button.pressed.connect(select_sender.bind(String(sender)))
		_crew_notes_list.add_child(button)
		_crew_buttons[sender] = button
	if senders.is_empty():
		_crew_notes_list.add_child(UiDesign.label("Crew notes appear when messages arrive.", "caption", "muted"))


func _sender_role(sender: String) -> String:
	return String({"Kai": "Power & heat", "Amara": "Atmosphere & measurement", "Mei": "Horticulture", "Rafi": "Space weather", "Ferreira": "Station commander", "Commander": "Station commander", "Rao": "Earth flight desk"}.get(sender, "Station communications"))


func _portrait_for_sender(sender: String) -> Texture2D:
	var id := sender.to_lower()
	if id in ["ferreira", "commander", "rao"]:
		return load("res://assets/ui/portraits/CH_%s_screen.png" % ("Rao" if id == "rao" else "Ferreira")) as Texture2D
	# N. and Noor keep a neutral mark; a delivered message never grants a portrait reveal.
	if id not in ["kai", "amara", "mei", "rafi"] or not visible or DisplayServer.get_name() == "headless":
		return load("res://assets/ui/branding/aurora_mark.svg") as Texture2D
	if _portrait_views.has(id):
		return (_portrait_views[id] as SubViewport).get_texture()
	var person := "CH_" + id.capitalize()
	var actor := AssetGeometry.load_glb("res://assets/characters/%s/%s.glb" % [person, person])
	if actor == null:
		return load("res://assets/ui/branding/aurora_mark.svg") as Texture2D
	var view := SubViewport.new()
	view.name = "CommsPortrait_" + id
	view.size = Vector2i(192, 216)
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(view)
	view.add_child(actor)
	var bounds := AssetGeometry.bounds(actor)
	var camera := Camera3D.new()
	view.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(bounds.size.y * 0.42, 0.01)
	var face := Vector3(bounds.get_center().x, bounds.position.y + bounds.size.y * 0.82, bounds.get_center().z)
	camera.position = face + Vector3(0, 0, maxf(bounds.size.y, 1.0))
	camera.look_at(face)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -25, 0)
	light.light_energy = 1.5
	view.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	view.add_child(environment)
	_portrait_views[id] = view
	return view.get_texture()


func _clear_portraits() -> void:
	_sender_portrait.texture = null
	_bubble_portrait.texture = null
	for button in _crew_buttons.values():
		(button as Button).icon = null
	for view in _portrait_views.values():
		(view as SubViewport).queue_free()
	_portrait_views.clear()
