extends Node3D
class_name PayloadStackActivity

## Safe Room extension of the established navy/mustard UI. One goal at top
## left, load at bottom left, action at right; the moving player's centre stays
## clear. Briefing, assistance and a paused report protect reading time.
signal closed
const Task = preload("res://scripts/payload/stack_task.gd")
const CASE_PATH := "res://assets/props/PR_VaultCase/PR_VaultCase.glb"
const NAVY := Color("#0B1426")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const ACCENT := Color("#F2C230")
var task: PayloadStackTask
var _campaign: Chapter1Campaign
var _settings: Dictionary
var _layout: Dictionary
var _player: PlayerController
var _held: HeldProp
var _case: PackedScene
var _bundles: Array[Node3D] = []
var _slots: Array[Node3D] = []
var _placed: Dictionary = {}
var _hidden: Array[Node3D] = []
var _canvas: CanvasLayer
var _world: Node3D
var _ui: Control
var _goal: Label
var _load: Label
var _prompt: Label
var _timer: Label
var _notice: Label
var _card: PanelContainer
var _assist_panel: PanelContainer
var _assist_rows: VBoxContainer
var _assistance := false
var _paused := true
var _started := false
var _reported := false
var _finished := false
var _selection := -1
var _selected_kind := ""
var _nearest := -1
var _near_kind := ""
var _prior_transform: Transform3D
var _prior_process: int
var _prior_controlled: bool
var _prior_mouse: int
var _prior_camera_current: bool
var _layout_queued := false

## Creates, parents and sets up the activity over the paused Safe Room plan.
static func launch(campaign: Chapter1Campaign, settings: Dictionary) -> PayloadStackActivity:
	var activity := PayloadStackActivity.new()
	campaign.add_child(activity)
	activity.setup(campaign, settings)
	return activity

## Attaches to the actual campaign's player, room and shared shift ledger.
func setup(campaign: Chapter1Campaign, settings: Dictionary) -> void:
	_campaign = campaign
	_settings = settings.duplicate(true)
	_layout = PayloadInventory.rules().stack
	_player = campaign._player
	_prior_transform = _player.global_transform
	_prior_process = _player.process_mode
	_prior_controlled = _player.controlled
	_prior_mouse = Input.mouse_mode
	_prior_camera_current = _player.follow_camera.camera.current
	task = Task.new(campaign.route.mission_table())
	_case = load(CASE_PATH) as PackedScene
	_held = HeldProp.new()
	add_child(_held)
	campaign.hud.hide()
	campaign.hud.mission_table.hide()
	# Retain the route's reading pause: carrying never advances a shift or
	# secretly spends base oxygen/battery. Only this player's body wakes up.
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_set_carry_control(false)
	for child in campaign._room.visual_root.get_children():
		if String(child.name) == "PR_SupplyBundles" and child.visible:
			_hidden.append(child)
			child.hide()
	var previous := campaign._room.get_node_or_null("PayloadStackSet")
	if previous != null:
		previous.free()
	_world = Node3D.new()
	_world.name = "PayloadStackSet"
	add_child(_world)
	_build_world()
	_build_ui()
	_show_brief()

## Starts only from the pre-task briefing; assistance is locked for this run.
func begin(assistance: bool) -> Dictionary:
	var result := task.start(assistance, _settings)
	if not bool(result.accepted):
		return result
	_assistance = assistance
	_started = true
	_paused = false
	_card.hide()
	_player.global_position = _vector(_layout.start_position)
	_player.velocity = Vector3.ZERO
	_player.reset_placement()
	_set_carry_control(not _assistance)
	_player.face_towards(_slots[0].global_position)
	_player.follow_camera.yaw = PI / 2.0
	_update_camera(1.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_assist_panel.visible = _assistance
	_refresh()
	return result

## Physical pickup; assisted selection uses the same inventory and condition
## checks, with movement supplied by the accessible input instead of dexterity.
func pickup_bundle(index: int) -> Dictionary:
	if _paused or index < 0 or index >= _bundles.size():
		return _refusal("Choose a supply bundle during the task.")
	if not _assistance and not _in_reach(_bundles[index]):
		return _refusal("Move closer to the supply bundle.")
	var result := task.pickup(index)
	if bool(result.accepted):
		_bundles[index].hide()
		if _assistance:
			_player.global_position = _bundles[index].global_position + Vector3(-0.8, -_bundles[index].global_position.y, 0.0)
		_player.set_hold(PlayerAnimation.Hold.BOX)
		_held.setup(_player.animation.skeleton, PlayerAnimation.Hold.BOX, _case, false)
		_player.face_towards(_slots[0].global_position)
		_update_camera(1.0)
	_answer(result)
	return result

## Snaps a carried bundle into an empty bunk slot after proximity/condition
## checks. There are no rigid bodies or falling-crate physics.
func place_bundle(slot: int) -> Dictionary:
	if _paused or slot < 0 or slot >= _slots.size():
		return _refusal("Choose an outlined bunk slot during the task.")
	if not _assistance and not _in_reach(_slots[slot]):
		return _refusal("Move closer to the bunk slot.")
	var held: Array = task.inventory.load_view("hands").ids
	var result := task.place(slot)
	if bool(result.accepted):
		var index := int(String(held[0]).trim_prefix("bundle_"))
		_bundles[index].global_position = _slots[slot].global_position
		_bundles[index].show()
		_placed[slot] = index
		if _assistance:
			_player.global_position = Vector3(_slots[slot].global_position.x + 1.2, 0.0, _slots[slot].global_position.z)
		_player.face_towards(_slots[slot].global_position)
		_update_camera(1.0)
		_clear_hold()
	_answer(result)
	if not task.running:
		_show_report()
	return result

## Opens a reading pause; the timer and locomotion stop until resumed.
func pause_task() -> void:
	if not _started or _reported:
		return
	_paused = true
	_set_carry_control(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var rows := _card_rows("Supplies paused", "Reading never uses your carrying time.")
	_add_button(rows, "Resume carrying", "Resume", _resume).grab_focus()
	_add_button(rows, "Finish with placed supplies", "FinishPartial", finish_task)
	_card.show()

## Explicitly finishes the physical task with its actual partial progress.
func finish_task() -> void:
	if task.running:
		task.finish()
	_show_report()

## Restores normal campaign input and the existing forecast/confirmation flow.
## The cadet returns to the response controls, so confirming still passes the
## campaign's real proximity gate. No shift is committed by this activity.
func return_to_plan() -> void:
	if _finished:
		return
	if not _started:
		_player.global_transform = _prior_transform
	else:
		if task.running:
			task.finish()
		# Stand 1 m in front of the real response controls so the shift
		# confirmation passes the campaign's own proximity and sight check.
		var controls := _campaign.physical_target("p02_shift5_alarm")
		_player.global_position = _vector(_layout.return_position) if controls == null else Vector3(controls.global_position.x, 0.0, controls.global_position.z + 1.0)
	_finished = true
	_clear_hold()
	_player.process_mode = _prior_process
	_player.set_controlled(_prior_controlled)
	_player.follow_camera.camera.current = _prior_camera_current
	_player.velocity = Vector3.ZERO
	if _started:
		# Leave the delivered supplies in their real bunk slots until the
		# chapter changes rooms; the old full pile must not reappear.
		_world.reparent(_campaign._room)
	else:
		for item in _hidden:
			if is_instance_valid(item):
				item.show()
	Input.mouse_mode = _prior_mouse
	_campaign.hud.show()
	_campaign.hud.mission_table.show()
	# M1-58 hook for Ramim's Mission Table (board task): refresh its forecast when it exists.
	if _campaign.hud.mission_table.has_method("refresh_payload_result"):
		_campaign.hud.mission_table.call("refresh_payload_result")
	_campaign.save_campaign()
	closed.emit()
	queue_free()

## Freed without `return_to_plan` (room change, campaign exit): give the
## cadet, the HUD, the table and the original pile back exactly as found.
func _exit_tree() -> void:
	if is_instance_valid(_held):
		_held.clear()
	if _finished:
		return
	if is_instance_valid(_player):
		_player.set_hold(PlayerAnimation.Hold.NONE)
		_player.process_mode = _prior_process
		_player.set_controlled(_prior_controlled)
		_player.follow_camera.camera.current = _prior_camera_current
	for item in _hidden:
		if is_instance_valid(item):
			item.show()
	if is_instance_valid(_campaign) and is_instance_valid(_campaign.hud):
		_campaign.hud.show()
		_campaign.hud.mission_table.show()
	Input.mouse_mode = _prior_mouse
	_finished = true
	closed.emit()

func _physics_process(delta: float) -> void:
	if is_instance_valid(_player) and not _player.controlled:
		_update_camera(delta)
	if not _started or _paused or _reported:
		return
	task.advance(delta)
	if not task.running:
		_show_report()
		return
	_update_nearest()
	_refresh_readouts()

func _input(event: InputEvent) -> void:
	if _finished:
		return
	# Godot's UI actions in this project are keyboard-only. Keep pad routing
	# local to this activity so A and the D-pad work in reading/assisted UI
	# without changing any global bindings or swallowing manual world input.
	if event is InputEventJoypadButton and event.pressed and (_paused or _assistance):
		var focused := get_viewport().gui_get_focus_owner()
		if focused != null and _ui.is_ancestor_of(focused):
			if event.button_index == JOY_BUTTON_A and focused is Button and not focused.disabled:
				focused.pressed.emit()
				get_viewport().set_input_as_handled()
				return
			var side := {JOY_BUTTON_DPAD_UP: SIDE_TOP, JOY_BUTTON_DPAD_DOWN: SIDE_BOTTOM, JOY_BUTTON_DPAD_LEFT: SIDE_LEFT, JOY_BUTTON_DPAD_RIGHT: SIDE_RIGHT}
			if side.has(event.button_index):
				var neighbor := focused.find_valid_focus_neighbor(int(side[event.button_index]))
				if neighbor != null:
					neighbor.grab_focus()
				get_viewport().set_input_as_handled()
				return
	var back: bool = event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	if back:
		if not _started or _reported:
			return_to_plan()
		elif _paused:
			_resume()
		else:
			pause_task()
		get_viewport().set_input_as_handled()
		return
	if _paused or _reported:
		return
	if not _assistance and event.is_action_pressed("interact") and not event.is_echo():
		if _nearest >= 0:
			if _near_kind == "bundle":
				pickup_bundle(_nearest)
			else:
				place_bundle(_nearest)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_player.follow_camera.look(event.screen_relative * _player.follow_camera.mouse_sensitivity)
		get_viewport().set_input_as_handled()

func _build_world() -> void:
	for index in _layout.source_positions.size():
		var bundle := _case.instantiate() as Node3D
		HeldProp.strip_collision(bundle)
		bundle.name = "SupplyBundle%d" % (index + 1)
		_world.add_child(bundle)
		var bounds := AssetGeometry.bounds(bundle)
		var scale_factor := float(_layout.bundle_size_m[0]) / bounds.size.x
		bundle.scale = Vector3.ONE * scale_factor
		bundle.position = _vector(_layout.source_positions[index]) - bounds.get_center() * scale_factor
		# A centring wrapper gives proximity and snapping a stable destination.
		var anchor := Node3D.new()
		_world.add_child(anchor)
		anchor.position = _vector(_layout.source_positions[index])
		bundle.reparent(anchor, true)
		_bundles.append(anchor)
		_world_label(anchor, str(index + 1), 0.28)
	for index in _layout.slot_positions.size():
		var slot := Node3D.new()
		_world.add_child(slot)
		slot.position = _vector(_layout.slot_positions[index])
		_slots.append(slot)
		var size_m := _vector(_layout.bundle_size_m) + Vector3(0.1, 0.08, 0.1)
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				_edge(slot, Vector3(0, y * size_m.y / 2, z * size_m.z / 2), Vector3(size_m.x, 0.012, 0.012))
			for x in [-1.0, 1.0]:
				_edge(slot, Vector3(x * size_m.x / 2, y * size_m.y / 2, 0), Vector3(0.012, 0.012, size_m.z))
		for x in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				_edge(slot, Vector3(x * size_m.x / 2, 0, z * size_m.z / 2), Vector3(0.012, size_m.y, 0.012))
		_world_label(slot, "Bunk %d" % (index + 1), 0.35)

func _edge(parent: Node3D, at: Vector3, dimensions: Vector3) -> void:
	var line := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	line.mesh = mesh
	line.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = ACCENT
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = material
	parent.add_child(line)

func _world_label(parent: Node3D, text: String, height: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.position.y = height
	label.font_size = 32
	label.pixel_size = 0.003
	label.outline_size = 12
	label.modulate = IVORY
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)

func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 30
	add_child(_canvas)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = load("res://resources/ui/lla_theme.tres")
	_canvas.add_child(_ui)
	var goal_panel := _panel("Goal", Vector2(32, 32), Vector2(430, 112))
	var rows := _rows(goal_panel)
	_goal = _label(String(_layout.goal), 28, IVORY)
	rows.add_child(_goal)
	rows.add_child(_label(String(_layout.why), 20, MUTED))
	var load_panel := _panel("Load", Vector2(32, -150), Vector2(350, 118), true)
	rows = _rows(load_panel)
	_load = _label("", 20, IVORY)
	rows.add_child(_load)
	_timer = _label("", 20, ACCENT)
	rows.add_child(_timer)
	var action_panel := _panel("Action", Vector2(-426, -180), Vector2(394, 148), true, true)
	rows = _rows(action_panel)
	_prompt = _label("", 20, IVORY)
	rows.add_child(_prompt)
	_notice = _label("", 16, MUTED)
	rows.add_child(_notice)
	_add_button(rows, "Pause / help · Esc or B", "Pause", pause_task)
	_assist_panel = _panel("AssistedInput", Vector2(-426, 32), Vector2(394, 390), false, true)
	var scroll := ScrollContainer.new()
	_assist_panel.add_child(scroll)
	_assist_rows = VBoxContainer.new()
	_assist_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_assist_rows.add_theme_constant_override("separation", 8)
	scroll.add_child(_assist_rows)
	_assist_panel.hide()
	_card = _panel("ReadingCard", Vector2.ZERO, Vector2(720, 500))
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()

func _layout_ui() -> void:
	_layout_queued = false
	var viewport := get_viewport().get_visible_rect().size
	for panel in _ui.get_children():
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var goal_panel := _ui.get_node("Goal") as PanelContainer
	goal_panel.position = Vector2(32, 32)
	goal_panel.size = Vector2(430, maxf(112, goal_panel.get_combined_minimum_size().y))
	var load_panel := _ui.get_node("Load") as PanelContainer
	var load_height := maxf(118, load_panel.get_combined_minimum_size().y)
	load_panel.size = Vector2(350, load_height)
	load_panel.position = Vector2(32, viewport.y - 32 - load_height)
	var action_panel := _ui.get_node("Action") as PanelContainer
	var action_height := maxf(148, action_panel.get_combined_minimum_size().y)
	action_panel.size = Vector2(394, action_height)
	action_panel.position = Vector2(viewport.x - 426, viewport.y - 32 - action_height)
	_assist_panel.position = Vector2(viewport.x - 426, 32)
	_assist_panel.size = Vector2(394, action_panel.position.y - 64)
	_card.size = Vector2(minf(760, viewport.x - 64), viewport.y - 64)
	_card.position = (viewport - _card.size) * 0.5

func _queue_layout() -> void:
	if not _layout_queued and is_instance_valid(_card):
		_layout_queued = true
		_layout_ui.call_deferred()

func _show_brief() -> void:
	var rows := _card_rows("Carry supplies to the bunks", String(_layout.brief))
	for index in _layout.steps.size():
		rows.add_child(_label("%d. %s" % [index + 1, _layout.steps[index]], 20, IVORY))
	rows.add_child(_label(String(_layout.scoring), 20, MUTED))
	var untimed := Task.is_untimed(_settings)
	rows.add_child(_label("Family / timer-free: no countdown." if untimed else "%d seconds; the clock starts after this card." % int(task.table.data().alarm_tasks.STACK.timer_seconds), 20, ACCENT))
	_add_button(rows, "Carry with movement · %s" % ("no timer" if untimed else "%d seconds" % int(task.table.data().alarm_tasks.STACK.timer_seconds)), "StartCarry", func() -> void: begin(false)).grab_focus()
	_add_button(rows, "Assisted · select and confirm · no timer", "StartAssisted", func() -> void: begin(true))
	_add_button(rows, "Back to the night plan", "Cancel", return_to_plan)
	_prompt.text = "Choose your controls before starting."
	_load.text = "Hands: empty · 0 kg"
	_timer.text = "Ready · timer has not started"
	_card.show()

func _show_report() -> void:
	if _reported:
		return
	_reported = true
	_paused = true
	for id in task.inventory.load_view("hands").ids:
		task.inventory.set_down(String(id))
		_bundles[int(String(id).trim_prefix("bundle_"))].show()
	_clear_hold()
	_set_carry_control(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_assist_panel.hide()
	var progress := task.table.alarm_progress()
	var rows := _card_rows("Supplies placed", "%d of %d bundles secured in the bunks." % [progress, task.table.alarm_task_steps()])
	rows.add_child(_label("Review the forecast before locking in this shift.\nCarrying supplies has used no base air or battery.", 20, IVORY))
	rows.add_child(_label(bridge_text(), 20, MUTED))
	_add_button(rows, "Review the night plan", "ReturnToPlan", return_to_plan).grab_focus()
	_card.show()
	_refresh_readouts()

## The S10 to S11 join shown on the report card, chosen from the station's
## actual water wall (W) because carrying crates never moves garden water.
func bridge_text() -> String:
	return Task.bridge_line(int(_campaign.director.snapshot().get("resources", {}).get("W", 0)))

func _resume() -> void:
	_paused = false
	_card.hide()
	_set_carry_control(not _assistance)

func _set_carry_control(value: bool) -> void:
	_player.set_controlled(value)
	_player.follow_camera.camera.current = true

func _update_camera(delta: float) -> void:
	_player.follow_camera.camera.current = true
	_player.follow_camera.update_camera(delta, _player.visual.global_rotation.y, 0.0)

func _refresh() -> void:
	_refresh_readouts()
	if not _assistance or _reported:
		return
	for child in _assist_rows.get_children():
		_assist_rows.remove_child(child)
		child.queue_free()
	_assist_rows.add_child(_label("Assisted carrying", 28, IVORY))
	var carrying: bool = not task.inventory.load_view("hands").ids.is_empty()
	_assist_rows.add_child(_label("Choose an empty bunk slot." if carrying else "Choose a bundle to pick up.", 20, MUTED))
	for index in _slots.size():
		if carrying and _placed.has(index):
			continue
		if not carrying and task.inventory.item("bundle_%d" % index).place != "ground":
			continue
		var i := index
		var text := "Bunk slot %d" % (index + 1) if carrying else "Supply bundle %d · %s kg" % [index + 1, String.num(float(_layout.bundle.mass_kg), 1)]
		var button := _add_button(_assist_rows, text, "Select_%d" % index, func() -> void:
			_selection = i
			_selected_kind = "slot" if carrying else "bundle"
			_refresh()
		)
		button.toggle_mode = true
		button.button_pressed = index == _selection
	var confirm := _add_button(_assist_rows, "Confirm placement" if carrying else "Confirm pickup", "ConfirmPayload", func() -> void:
		if _selected_kind == "slot":
			place_bundle(_selection)
		else:
			pickup_bundle(_selection)
	)
	confirm.disabled = _selection < 0
	if _selection >= 0:
		confirm.grab_focus()
	else:
		for child in _assist_rows.get_children():
			if child is Button and not child.disabled:
				child.grab_focus()
				break

func _refresh_readouts() -> void:
	var load := task.inventory.load_view("hands")
	var back := task.inventory.load_view("back")
	_load.text = "Hands: %d of %d · %s of %s kg\nBack frame: %d of %d · %s kg\nMoon weight %s N" % [int(load.count), int(load.slots), String.num(float(load.mass_kg), 1), String.num(float(load.limit_kg), 1), int(back.count), int(back.slots), String.num(float(back.mass_kg), 1), String.num(float(load.weight_n) + float(back.weight_n), 1)]
	_timer.text = "%d of %d placed · %s" % [task.table.alarm_progress(), task.table.alarm_task_steps(), "no timer" if task.assisted else "%d s left" % ceili(task.time_left)]
	if _assistance:
		_prompt.text = "Choose, then confirm. No movement timing."
	elif _nearest >= 0:
		_prompt.text = "E / A · %s %d" % ["Pick up bundle" if _near_kind == "bundle" else "Place in bunk slot", _nearest + 1]
	else:
		_prompt.text = "Walk to a bundle." if int(load.count) == 0 else "Carry it to an outlined bunk slot."

func _answer(result: Dictionary) -> void:
	_notice.text = String(result.get("reason", ""))
	_notice.modulate = Color.WHITE if bool(result.accepted) else ACCENT
	if _campaign.audio != null:
		_campaign.audio.play_operation("payload_place", "Supply bundle", bool(result.accepted))
	_selection = -1
	_selected_kind = ""
	_refresh()

func _refusal(reason: String) -> Dictionary:
	var result := {"accepted": false, "reason": reason}
	_answer(result)
	return result

func _clear_hold() -> void:
	_held.clear()
	_player.set_hold(PlayerAnimation.Hold.NONE)

func _in_reach(target: Node3D) -> bool:
	var offset := target.global_position - _player.global_position
	offset.y = 0.0
	if offset.length() > float(_layout.reach_m):
		return false
	# Bunk slots sit behind the crew seats; the cadet reaches over a seat
	# back, so slots need distance only. Bundles still need a clear line.
	if target in _slots:
		return true
	var ray := PhysicsRayQueryParameters3D.create(_player.global_position + Vector3.UP, target.global_position, 1, [_player.get_rid()])
	return _player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _update_nearest() -> void:
	_nearest = -1
	var carrying: bool = not task.inventory.load_view("hands").ids.is_empty()
	_near_kind = "slot" if carrying else "bundle"
	var candidates := _slots if carrying else _bundles
	var distance := INF
	for index in candidates.size():
		if (carrying and _placed.has(index)) or (not carrying and task.inventory.item("bundle_%d" % index).place != "ground"):
			continue
		if _in_reach(candidates[index]):
			var next_distance := _player.global_position.distance_squared_to(candidates[index].global_position)
			if next_distance < distance:
				distance = next_distance
				_nearest = index

func _card_rows(title: String, body: String) -> VBoxContainer:
	for child in _card.get_children():
		_card.remove_child(child)
		child.queue_free()
	var scroll := ScrollContainer.new()
	_card.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 16)
	scroll.add_child(rows)
	rows.add_child(_label(title, 40, IVORY))
	rows.add_child(_label(body, 20, MUTED))
	return rows

func _panel(id: String, at: Vector2, dimensions: Vector2, bottom: bool = false, right: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = id
	_ui.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT if bottom and right else Control.PRESET_BOTTOM_LEFT if bottom else Control.PRESET_TOP_RIGHT if right else Control.PRESET_TOP_LEFT)
	panel.position = at
	panel.size = dimensions
	var style := StyleBoxFlat.new()
	style.bg_color = Color(NAVY, 0.97)
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color("#52617A")
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.minimum_size_changed.connect(_queue_layout)
	return panel

func _rows(parent: Node) -> VBoxContainer:
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	parent.add_child(rows)
	return rows

func _label(value: String, pixels: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", roundi(pixels * (1.5 if bool(_settings.get("large_text", false)) else 1.0)))
	label.add_theme_color_override("font_color", color)
	return label

func _add_button(parent: Node, text: String, id: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = text
	button.custom_minimum_size.y = 48
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 24 if bool(_settings.get("large_text", false)) else 20)
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_pressed_color", IVORY)
	button.add_theme_color_override("font_hover_color", Color("#05060A"))
	button.add_theme_color_override("font_focus_color", IVORY)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _button_style(Color("#1F2A44"), Color("#52617A"), 1))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#1F2A44"), ACCENT, 2))
	button.add_theme_stylebox_override("hover", _button_style(ACCENT, Color("#05060A"), 2))
	button.add_theme_stylebox_override("focus", _button_style(Color(0, 0, 0, 0), IVORY, 3))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#151C2C"), Color("#40475C"), 1))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _button_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(7)
	style.set_border_width_all(width)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

static func _vector(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
