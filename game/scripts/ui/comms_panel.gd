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
	_close_btn.pressed.connect(close_inbox)
	for label in shell.find_children("*", "Label", true, false):
		UiDesign.style_label(label, String(label.get_meta("lla_type", "body")), "accent" if label == _detail_sender_label else "ivory")
	for pane_name in ["ThreadPane", "MessageListPane", "MessageDetailPane"]:
		var pane := shell.find_child(pane_name, true, false) as PanelContainer
		pane.add_theme_stylebox_override("panel", UiDesign.glass_style(Color.TRANSPARENT, Color.TRANSPARENT, 12))
	for tid in CommsServiceScript.THREAD_ORDER:
		var button := UiDesign.button(String(CommsServiceScript.THREAD_LABELS.get(tid, tid.capitalize())))
		button.name = "Thread_" + tid
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var channel := String(tid)
		button.pressed.connect(func(): select_thread(channel))
		_thread_list_box.add_child(button)
		_thread_buttons[tid] = button
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
		mbtn.custom_minimum_size = Vector2(0, 64)
		mbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		mbtn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
