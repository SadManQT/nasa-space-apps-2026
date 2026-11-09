class_name CommsPanel
extends Control
## Full-screen modal Messages inbox (`M` key or Pause -> Messages).
## Displays the 5 station threads (Crew, Commander, Earth, Academy, Archive),
## unread counts, message list, and message reader pane in the UiDesign house style.

signal opened
signal closed
signal message_read(message_id: String)

const UiDesign = preload("res://scripts/ui/ui_design.gd")
const CommsServiceScript = preload("res://scripts/comms/comms_service.gd")

var comms_service: RefCounted = null
var active_thread: String = "crew"
var selected_message_id: String = ""
var large_text: bool = false

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
	elif active_thread.is_empty():
		active_thread = "crew"
	if not preferred_message_id.is_empty():
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
	closed.emit()


func set_text_scale(is_large: bool) -> void:
	large_text = is_large
	_apply_font_sizes()
	refresh_view()


func select_thread(thread_id: String) -> void:
	if not CommsServiceScript.THREAD_ORDER.has(thread_id):
		return
	active_thread = thread_id
	selected_message_id = ""
	refresh_view()


func select_message(message_id: String) -> void:
	if comms_service == null:
		return
	var msg: Dictionary = comms_service.message_by_id(message_id)
	if msg.is_empty() or not bool(msg.get("delivered", false)):
		return
	selected_message_id = message_id
	var res: Dictionary = comms_service.mark_read(message_id)
	if bool(res.get("ok", false)):
		message_read.emit(message_id)
	refresh_view()


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
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = UiDesign.colour("scrim", Color(0.02, 0.04, 0.08, 0.78))
	add_child(scrim)

	var outer := MarginContainer.new()
	outer.name = "OuterMargin"
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 64)
	outer.add_theme_constant_override("margin_right", 64)
	outer.add_theme_constant_override("margin_top", 44)
	outer.add_theme_constant_override("margin_bottom", 44)
	add_child(outer)

	var frame := UiDesign.glass_panel(UiDesign.colour("glass_edge", Color(1, 1, 1, 0.18)), 16)
	frame.name = "InboxFrame"
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(frame)

	var root_col := VBoxContainer.new()
	root_col.name = "RootColumn"
	root_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_col.add_theme_constant_override("separation", 16)
	frame.add_child(root_col)

	# Header bar
	var header := HBoxContainer.new()
	header.name = "HeaderBar"
	header.add_theme_constant_override("separation", 16)
	root_col.add_child(header)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 2)
	header.add_child(title_col)

	var kicker := UiDesign.label("STATION COMMUNICATIONS", "caption", "accent")
	kicker.name = "KickerLabel"
	title_col.add_child(kicker)

	_title_label = UiDesign.label("Messages", "title", "ivory")
	_title_label.name = "TitleLabel"
	title_col.add_child(_title_label)

	_unread_summary_label = UiDesign.label("All messages read", "caption", "muted")
	_unread_summary_label.name = "UnreadSummaryLabel"
	_unread_summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_unread_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_unread_summary_label)

	_close_btn = UiDesign.button("Close", 40)
	_close_btn.name = "CloseButton"
	_close_btn.custom_minimum_size = Vector2(108, 40)
	_close_btn.pressed.connect(close_inbox)
	header.add_child(_close_btn)

	# Three-pane body: Threads (left), Message List (middle), Message Reader (right)
	var body_row := HBoxContainer.new()
	body_row.name = "BodyRow"
	body_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_theme_constant_override("separation", 18)
	root_col.add_child(body_row)

	# Left pane: 5 threads
	var thread_pane := UiDesign.glass_panel(Color.TRANSPARENT, 12)
	thread_pane.name = "ThreadPane"
	thread_pane.custom_minimum_size = Vector2(220, 0)
	thread_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(thread_pane)

	var thread_col := VBoxContainer.new()
	thread_col.add_theme_constant_override("separation", 10)
	thread_pane.add_child(thread_col)

	var thread_header := UiDesign.label("CHANNELS", "caption", "muted")
	thread_header.name = "ThreadHeader"
	thread_col.add_child(thread_header)

	_thread_list_box = VBoxContainer.new()
	_thread_list_box.name = "ThreadListBox"
	_thread_list_box.add_theme_constant_override("separation", 8)
	thread_col.add_child(_thread_list_box)

	for tid in CommsServiceScript.THREAD_ORDER:
		var tbtn := UiDesign.button(String(CommsServiceScript.THREAD_LABELS.get(tid, tid.capitalize())), 44)
		tbtn.name = "Thread_" + tid
		tbtn.custom_minimum_size = Vector2(190, 44)
		tbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var captured_tid := String(tid)
		tbtn.pressed.connect(func() -> void: select_thread(captured_tid))
		_thread_list_box.add_child(tbtn)
		_thread_buttons[tid] = tbtn

	# Middle pane: message list for selected thread
	var list_pane := UiDesign.glass_panel(Color.TRANSPARENT, 12)
	list_pane.name = "MessageListPane"
	list_pane.custom_minimum_size = Vector2(340, 0)
	list_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(list_pane)

	var list_col := VBoxContainer.new()
	list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_col.add_theme_constant_override("separation", 10)
	list_pane.add_child(list_col)

	var list_header := UiDesign.label("INBOX", "caption", "muted")
	list_header.name = "ListHeader"
	list_col.add_child(list_header)

	var scroll := ScrollContainer.new()
	scroll.name = "MessageScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_col.add_child(scroll)

	_message_list_box = VBoxContainer.new()
	_message_list_box.name = "MessageListBox"
	_message_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_message_list_box)

	_empty_list_label = UiDesign.label("No messages in this channel yet.", "caption", "muted")
	_empty_list_label.name = "EmptyListLabel"
	_empty_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_list_box.add_child(_empty_list_label)

	# Right pane: message detail reader
	var detail_pane := UiDesign.glass_panel(UiDesign.colour("accent"), 12)
	detail_pane.name = "MessageDetailPane"
	detail_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(detail_pane)

	var detail_col := VBoxContainer.new()
	detail_col.name = "DetailColumn"
	detail_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_col.add_theme_constant_override("separation", 12)
	detail_pane.add_child(detail_col)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 12)
	detail_col.add_child(meta_row)

	_detail_sender_label = UiDesign.label("Station Inbox", "caption", "accent")
	_detail_sender_label.name = "DetailSenderLabel"
	_detail_sender_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_detail_sender_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_row.add_child(_detail_sender_label)

	_detail_time_label = UiDesign.label("", "caption", "muted")
	_detail_time_label.name = "DetailTimeLabel"
	_detail_time_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	meta_row.add_child(_detail_time_label)

	_detail_subject_label = UiDesign.label("Select a message to read", "heading", "ivory")
	_detail_subject_label.name = "DetailSubjectLabel"
	_detail_subject_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_subject_label.set_meta("verbatim", true)
	detail_col.add_child(_detail_subject_label)

	_detail_goal_badge = UiDesign.label("NEXT STEP ON HUD", "caption", "good")
	_detail_goal_badge.name = "DetailGoalBadge"
	_detail_goal_badge.visible = false
	detail_col.add_child(_detail_goal_badge)

	var body_scroll := ScrollContainer.new()
	body_scroll.name = "DetailBodyScroll"
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_col.add_child(body_scroll)

	_detail_body_label = UiDesign.label("Incoming notes from the crew, the Commander, Earth, the Academy, and the station archive appear here as the mission unfolds.", "body", "ivory")
	_detail_body_label.name = "DetailBodyLabel"
	_detail_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_body_label.set_meta("verbatim", true)
	body_scroll.add_child(_detail_body_label)

	_apply_font_sizes()


func _apply_font_sizes() -> void:
	var scale := 1.5 if large_text else 1.0
	var vh := 1080.0
	if is_inside_tree():
		vh = get_viewport_rect().size.y
	UiDesign.apply_type(self, vh, scale)


func refresh_view() -> void:
	if _thread_list_box == null:
		return
	var total_unread: int = int(comms_service.unread_count()) if comms_service != null else 0
	if _unread_summary_label != null:
		if total_unread <= 0:
			_unread_summary_label.text = "All messages read"
		elif total_unread == 1:
			_unread_summary_label.text = "1 unread message"
		else:
			_unread_summary_label.text = "%d unread messages" % total_unread

	var threads: Array = comms_service.threads_view() if comms_service != null else []
	for tinfo in threads:
		var tid := String(tinfo.get("id", ""))
		if not _thread_buttons.has(tid):
			continue
		var btn: Button = _thread_buttons[tid]
		var label_str := String(tinfo.get("label", tid.capitalize()))
		var u_count := int(tinfo.get("unread_count", 0))
		var t_count := int(tinfo.get("total_count", 0))
		if u_count > 0:
			btn.text = "%s  ·  %d new" % [label_str, u_count]
		elif t_count > 0:
			btn.text = "%s  (%d)" % [label_str, t_count]
		else:
			btn.text = label_str

	_rebuild_message_list()
	_refresh_detail_pane()
	_apply_font_sizes()


func _rebuild_message_list() -> void:
	_message_buttons.clear()
	for child in _message_list_box.get_children():
		if child != _empty_list_label:
			child.queue_free()

	var msgs: Array = comms_service.messages_for_thread(active_thread) if comms_service != null else []
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
		mbtn.custom_minimum_size = Vector2(300, 48)
		mbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		mbtn.clip_text = true
		mbtn.set_meta("verbatim", true)
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
		return

	var msg: Dictionary = comms_service.message_by_id(selected_message_id)
	if msg.is_empty():
		return

	_detail_sender_label.text = "FROM %s" % String(msg.get("sender", "Station")).to_upper()
	_detail_time_label.text = String(msg.get("formatted_time", ""))
	_detail_subject_label.text = String(msg.get("subject", ""))
	_detail_goal_badge.visible = bool(msg.get("goal", false))
	_detail_body_label.text = String(msg.get("body", ""))
