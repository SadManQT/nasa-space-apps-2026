extends Control
class_name SaveSlotsPanel

## M3-71: Save slots UI panel presenting the autosave checkpoint and three
## manual slots (slot_1, slot_2, slot_3) with chapter, story date, play time,
## and thumbnail preview. Detects corrupt primary save files and offers backup
## recovery explicitly before loading, or allows saving/copying/clearing slots.
## Styled with UiDesign and UiKit using strictly player-facing text.

signal exit_requested
signal slot_loaded(slot_id: String, snapshot: Dictionary, metadata: Dictionary)
signal slot_saved(slot_id: String, metadata: Dictionary)
signal slot_recovered(slot_id: String, snapshot: Dictionary, metadata: Dictionary)
signal slot_cleared(slot_id: String)

const SlotsScript = preload("res://scripts/save/save_slots.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const CampaignScript = preload("res://scripts/campaign/chapter1_campaign.gd")

var save_path: String = SaveScript.DEFAULT_PATH
var session_validator: Callable = Callable()
var current_snapshot_source: Callable = Callable()
var settings: Dictionary = {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}
var allow_save_current := false

var _slots: RefCounted
var _status_label: Label
var _scroll: ScrollContainer
var _body: VBoxContainer
var _pending_clear_slot := ""

func _init(p_slots: RefCounted = null) -> void:
	if p_slots != null:
		_slots = p_slots
		if "base_save_path" in p_slots:
			save_path = String(p_slots.base_save_path)
		if "session_validator" in p_slots and (p_slots.session_validator as Callable).is_valid():
			session_validator = p_slots.session_validator

func bind_snapshot_provider(provider: Callable) -> void:
	current_snapshot_source = provider
	allow_save_current = provider.is_valid()
	if is_inside_tree():
		refresh()

func _ready() -> void:
	name = "SaveSlotsPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	if not session_validator.is_valid():
		session_validator = func(snap: Dictionary) -> Dictionary: return CampaignScript.restore_session(snap)
	if _slots == null:
		_slots = SlotsScript.new(save_path, session_validator)
	_build_ui()
	refresh()

func slots_manager() -> RefCounted:
	if _slots == null or _slots.base_save_path != save_path:
		if not session_validator.is_valid():
			session_validator = func(snap: Dictionary) -> Dictionary: return CampaignScript.restore_session(snap)
		_slots = SlotsScript.new(save_path, session_validator)
	return _slots

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = UiDesign.colour("ink")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var glass := UiDesign.glass_panel()
	margin.add_child(glass)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	glass.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	stack.add_child(header)

	var title_row := UiKit.icon_label("save", "Expedition Save Slots & Autosave", "title")
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_row)

	var close_btn := UiDesign.button("Back")
	close_btn.name = "SaveSlotsExit"
	close_btn.pressed.connect(func() -> void: exit_requested.emit())
	header.add_child(close_btn)

	_status_label = UiDesign.label(
		"Autosave writes at every scene transition and mission completion. Three manual slots let you keep separate checkpoints.",
		"body",
		"accent"
	)
	_status_label.name = "SaveSlotsStatus"
	stack.add_child(_status_label)

	_scroll = ScrollContainer.new()
	_scroll.name = "SaveSlotsScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	stack.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.name = "SaveSlotsBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	_scroll.add_child(_body)

	get_viewport().size_changed.connect(_scale)

func refresh(status_override: String = "") -> void:
	if _body == null:
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	if not status_override.is_empty() and _status_label != null:
		_status_label.text = status_override

	var all_meta: Array[Dictionary] = slots_manager().all_slot_metadata()
	for meta in all_meta:
		_body.add_child(_build_slot_card(meta))

	_scale()

func _build_slot_card(meta: Dictionary) -> Control:
	var slot_id := String(meta.get("slot_id", "autosave"))
	var is_corrupt := bool(meta.get("corrupt", false))
	var is_valid := bool(meta.get("valid", false))
	var backup_available := bool(meta.get("backup_available", false))
	var border_col := UiDesign.colour("danger") if is_corrupt else (UiDesign.colour("accent") if is_valid else UiDesign.colour("border"))
	var card := UiDesign.glass_panel(border_col)
	card.name = "SlotCard_" + slot_id

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	# Thumbnail preview
	var thumb_frame := PanelContainer.new()
	thumb_frame.name = "SlotThumbnail_" + slot_id
	thumb_frame.custom_minimum_size = Vector2(160, 96)
	var thumb_style := UiDesign.glass_style(border_col, UiDesign.colour("navy").darkened(0.35), 4)
	thumb_frame.add_theme_stylebox_override("panel", thumb_style)
	row.add_child(thumb_frame)

	var thumb_path := String(meta.get("thumbnail_path", ""))
	if (is_valid or (is_corrupt and backup_available)) and not thumb_path.is_empty() and ResourceLoader.exists(thumb_path):
		var tex_rect := TextureRect.new()
		tex_rect.name = "ThumbnailImage_" + slot_id
		tex_rect.texture = load(thumb_path) as Texture2D
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.custom_minimum_size = Vector2(152, 88)
		thumb_frame.add_child(tex_rect)
	else:
		var empty_lbl := UiDesign.label("NO IMAGE" if not is_corrupt else "DAMAGED", "caption", "muted" if not is_corrupt else "danger")
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		thumb_frame.add_child(empty_lbl)

	# Details column
	var info_col := VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 4)
	row.add_child(info_col)

	var heading := UiDesign.label(String(meta.get("slot_label", slot_id)), "heading", "accent" if is_valid else ("danger" if is_corrupt else "ivory"))
	heading.name = "SlotHeading_" + slot_id
	info_col.add_child(heading)

	if is_valid:
		var ch_line := "%s  ·  %s" % [String(meta.get("chapter_title", "Chapter 1")), String(meta.get("scene_title", "Aurora Station"))]
		var ch_lbl := UiDesign.label(ch_line, "body", "ivory")
		ch_lbl.name = "SlotChapter_" + slot_id
		info_col.add_child(ch_lbl)

		var meta_line := "Story date: %s  ·  Play time: %s  ·  Completed scenes: %d" % [
			String(meta.get("story_date", "")),
			String(meta.get("play_time", "0s")),
			int(meta.get("completed_scenes", 0)),
		]
		var meta_lbl := UiDesign.label(meta_line, "caption", "muted")
		meta_lbl.name = "SlotMeta_" + slot_id
		info_col.add_child(meta_lbl)

		var status_line := String(meta.get("status_label", "Saved expedition"))
		if bool(meta.get("backup_available", false)):
			status_line += " · Backup ready"
		info_col.add_child(UiDesign.label(status_line, "caption", "good"))
	elif is_corrupt:
		var corrupt_msg := "Primary save file is damaged."
		if backup_available:
			corrupt_msg += " A verified backup checkpoint is available (" + String(meta.get("chapter_title", "Chapter 1")) + " · " + String(meta.get("story_date", "")) + ")."
		else:
			corrupt_msg += " No verified backup file was found for this slot."
		var corrupt_lbl := UiDesign.label(corrupt_msg, "body", "danger")
		corrupt_lbl.name = "SlotCorruptNotice_" + slot_id
		info_col.add_child(corrupt_lbl)
	else:
		var empty_desc := UiDesign.label("Empty slot · Ready to store a checkpoint.", "body", "muted")
		empty_desc.name = "SlotEmptyNotice_" + slot_id
		info_col.add_child(empty_desc)

	# Action buttons
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	row.add_child(actions)

	if is_corrupt and backup_available:
		var recover_btn := UiDesign.button("Restore Backup")
		recover_btn.name = "RecoverSlot_" + slot_id
		recover_btn.pressed.connect(func() -> void: trigger_recover_backup(slot_id))
		actions.add_child(recover_btn)

	var load_btn := UiDesign.button("Load Slot")
	load_btn.name = "LoadSlot_" + slot_id
	load_btn.disabled = not is_valid
	load_btn.pressed.connect(func() -> void: trigger_load_slot(slot_id))
	actions.add_child(load_btn)

	if slot_id != SlotsScript.AUTOSAVE_SLOT:
		var can_save := allow_save_current or current_snapshot_source.is_valid() or bool(slots_manager().inspect_slot(SlotsScript.AUTOSAVE_SLOT).get("valid", false))
		var save_btn := UiDesign.button("Save Here")
		save_btn.name = "SaveSlot_" + slot_id
		save_btn.disabled = not can_save
		save_btn.pressed.connect(func() -> void: trigger_save_slot(slot_id))
		actions.add_child(save_btn)

		if is_valid or is_corrupt:
			var clear_label := "Confirm Delete" if _pending_clear_slot == slot_id else "Delete Slot"
			var clear_btn := UiDesign.button(clear_label)
			clear_btn.name = "ClearSlot_" + slot_id
			clear_btn.pressed.connect(func() -> void: trigger_clear_slot(slot_id))
			actions.add_child(clear_btn)

	return card

func trigger_load_slot(slot_id: String) -> Dictionary:
	_pending_clear_slot = ""
	var result: Dictionary = slots_manager().load_slot(slot_id, false)
	if not bool(result.get("accepted", false)):
		if bool(result.get("corrupt", false)) and bool(result.get("backup_available", false)):
			refresh("Primary file for %s is damaged. Choose Restore Backup to recover the verified backup." % SlotsScript.slot_label(slot_id))
		else:
			refresh("Could not open %s." % SlotsScript.slot_label(slot_id))
		return result
	var meta: Dictionary = result.get("metadata", {})
	refresh("Loaded %s (%s)." % [SlotsScript.slot_label(slot_id), String(meta.get("chapter_title", "Chapter 1"))])
	slot_loaded.emit(slot_id, result.get("snapshot", {}), meta)
	return result

func trigger_recover_backup(slot_id: String) -> Dictionary:
	_pending_clear_slot = ""
	var result: Dictionary = slots_manager().recover_slot_from_backup(slot_id)
	if bool(result.get("accepted", false)):
		var meta: Dictionary = result.get("metadata", {})
		refresh("Recovered %s from verified backup (%s)." % [SlotsScript.slot_label(slot_id), String(meta.get("chapter_title", "Chapter 1"))])
		slot_recovered.emit(slot_id, result.get("snapshot", {}), meta)
	else:
		refresh("Backup recovery failed for %s." % SlotsScript.slot_label(slot_id))
	return result

func trigger_save_slot(slot_id: String) -> Dictionary:
	_pending_clear_slot = ""
	var snap: Dictionary = {}
	if current_snapshot_source.is_valid():
		var supplied = current_snapshot_source.call()
		if supplied is Dictionary:
			snap = (supplied as Dictionary).duplicate(true)
	if snap.is_empty():
		var auto_loaded: Dictionary = slots_manager().load_slot(SlotsScript.AUTOSAVE_SLOT, true)
		if bool(auto_loaded.get("accepted", false)) and auto_loaded.get("snapshot") is Dictionary:
			snap = (auto_loaded["snapshot"] as Dictionary).duplicate(true)
	if snap.is_empty():
		refresh("No active checkpoint available to save into %s." % SlotsScript.slot_label(slot_id))
		return {"accepted": false, "slot_id": slot_id, "reason": "No active snapshot available."}
	var saved: Dictionary = slots_manager().save_slot(slot_id, snap, "manual")
	if bool(saved.get("accepted", false)):
		var meta: Dictionary = saved.get("metadata", {})
		refresh("Saved checkpoint to %s (%s)." % [SlotsScript.slot_label(slot_id), String(meta.get("chapter_title", "Chapter 1"))])
		slot_saved.emit(slot_id, meta)
	else:
		refresh("Could not save to %s." % SlotsScript.slot_label(slot_id))
	return saved

func trigger_clear_slot(slot_id: String, confirmed: bool = false) -> bool:
	if not confirmed and _pending_clear_slot != slot_id:
		_pending_clear_slot = slot_id
		refresh("Press Confirm Delete on %s to remove its saved files." % SlotsScript.slot_label(slot_id))
		return false
	_pending_clear_slot = ""
	var ok: bool = slots_manager().clear_slot(slot_id)
	if ok:
		refresh("Cleared %s." % SlotsScript.slot_label(slot_id))
		slot_cleared.emit(slot_id)
	return ok

func _unhandled_input(event: InputEvent) -> void:
	var back_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if (event.is_action_pressed("ui_cancel") or back_pad) and not event.is_echo():
		exit_requested.emit()
		get_viewport().set_input_as_handled()

func _scale() -> void:
	if not is_inside_tree():
		return
	var scale_val := float(settings.get("subtitle_scale", 1.5 if bool(settings.get("large_text", false)) else 1.0))
	UiDesign.apply_type(self, get_viewport_rect().size.y, scale_val)
