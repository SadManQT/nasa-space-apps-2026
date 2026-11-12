extends Control
class_name ClassSignoffPanel

## M1-37 later puzzles: in a Class expedition every role signs the exact choice
## and forecast before a puzzle locks in (Chapter1Campaign.class_team_plan_view
## and sign_class_team_plan, M1-103). The runtime raises class_team_plan_requested
## when a lock-in is held for signatures; this panel shows each role, lets each
## player sign in turn, and then asks the team to press Lock in again. A changed
## choice or forecast voids earlier signatures inside the runtime itself.

const CrewModesScript = preload("res://scripts/classmode/crew_modes.gd")

signal closed

var _campaign: Object
var _view: Dictionary = {}
var _box: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 210
	hide()

func open_for(campaign: Object, view: Dictionary) -> void:
	_campaign = campaign
	_view = view.duplicate(true)
	_render()
	show()
	var first := find_child("Sign_*", true, false) as Button
	if first != null:
		first.grab_focus.call_deferred()

func close() -> void:
	hide()
	closed.emit()

func signed_roles() -> Array:
	return (_view.get("signed_roles", []) as Array).duplicate()

func sign(role_id: String) -> Dictionary:
	if _campaign == null:
		return {"accepted": false, "reason": "No expedition."}
	var selection: Dictionary = _view.get("selection", {})
	var result: Dictionary = _campaign.sign_class_team_plan(role_id, String(_view.get("target_id", "")), selection.get("payload", {}), selection)
	var fresh: Dictionary = _campaign.class_team_plan_view(String(_view.get("target_id", "")), selection.get("payload", {}))
	if bool(fresh.get("accepted", false)):
		_view = fresh
	_render(String(result.get("reason", "")) if not bool(result.get("accepted", false)) else "")
	return result

func _render(notice: String = "") -> void:
	for child in get_children():
		remove_child(child)  # out of the tree now, so lookups never see the previous render
		child.queue_free()
	var scrim := ColorRect.new()
	scrim.color = UiDesign.colour("scrim", Color(0, 0, 0, 0.8))
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var panel := UiDesign.glass_panel(Color.TRANSPARENT, 24)
	panel.name = "ClassSignoff"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.custom_minimum_size = Vector2(620, 0)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	panel.add_child(_box)
	_box.add_child(UiDesign.label("Team sign-off", "title", "ivory"))
	_box.add_child(UiDesign.label(String(_view.get("focus_label", "This decision")), "subhead", "accent"))
	_box.add_child(UiDesign.label("Each crew member reads the forecast, then signs. Changing the choice clears the signatures.", "caption", "muted"))
	var signed: Array = _view.get("signed_roles", [])
	var crew = _view.get("crew", {})
	for role_id in _view.get("required_roles", []):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var info := CrewModesScript.role_info(String(role_id))
		var who := UiDesign.label("%s · %s" % [String(info.get("name", role_id)), CrewModesScript.holder_label(crew, String(role_id))], "body", "ivory")
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(who)
		var done := signed.has(role_id)
		var button := UiDesign.button("✓ Signed" if done else "Sign", 44, "check" if done else "")
		button.name = "Sign_" + String(role_id)
		button.disabled = done
		button.custom_minimum_size.x = 140
		if not done:
			button.pressed.connect(func() -> void: sign(String(role_id)))
		row.add_child(button)
		_box.add_child(row)
	var all_signed := signed.size() >= (_view.get("required_roles", []) as Array).size()
	var status := UiDesign.label(notice if not notice.is_empty() else ("All signed. Close this and press Lock in again." if all_signed else "%d of %d signed." % [signed.size(), (_view.get("required_roles", []) as Array).size()]), "caption", "good" if all_signed and notice.is_empty() else "muted")
	status.name = "SignoffStatus"
	_box.add_child(status)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	var done_button := UiDesign.button("Back to the decision · Esc" if not all_signed else "Done", 44)
	done_button.name = "SignoffClose"
	if all_signed:
		UiDesign.make_primary(done_button)
	done_button.pressed.connect(close)
	footer.add_child(done_button)
	_box.add_child(footer)
	UiDesign.apply_type(self, get_viewport_rect().size.y if is_inside_tree() else 720.0, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
