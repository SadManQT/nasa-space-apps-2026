extends Node3D

## Player-facing bridge to the existing saved probe job. E performs only
## the next physical step, in reach; observation never commits P-01 itself.
signal closed(completed: bool)
const Job = preload("res://scripts/payload/probe_calibration_job.gd")
const REACH_M := 3.0
var campaign: Chapter1Campaign
var job: RefCounted
var rack: Node3D
var cradle: Node3D
var _probe: Node3D
var _held: HeldProp
var _action: Button
var _notice: Label
var _prior_hud_process: int
var _finished := false

func setup(value: Chapter1Campaign) -> void:
	campaign = value
	job = campaign.route.probe_job()
	_prior_hud_process = campaign.hud.process_mode
	campaign.hud.hide()
	campaign.hud.process_mode = Node.PROCESS_MODE_DISABLED
	var bench := campaign.physical_target("calibrate_probe")
	rack = Node3D.new()
	rack.name = "ProbeRack"
	add_child(rack)
	rack.global_position = bench.global_position + Vector3(0.65, 0.1, 0)
	cradle = Node3D.new()
	cradle.name = "DryReferenceCradle"
	add_child(cradle)
	cradle.global_position = bench.global_position + Vector3(-0.65, 0.1, 0)
	for pair in [[rack, "MOISTURE PROBE · RACK"], [cradle, "DRY REFERENCE · BENCH"]]:
		var label := Label3D.new()
		label.text = pair[1]
		label.font_size = 30
		label.pixel_size = 0.003
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position.y = 0.55
		pair[0].add_child(label)
	var scene := load(Job.PROP_SCENE_PATH) as PackedScene
	_probe = scene.instantiate()
	HeldProp.strip_collision(_probe)
	add_child(_probe)
	_held = HeldProp.new()
	add_child(_held)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiDesign.glass_style(UiDesign.colour("glass_edge"), UiDesign.colour("navy")))
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	card.offset_left = 28
	card.offset_right = -28
	card.offset_top = -220
	card.offset_bottom = -28
	canvas.add_child(card)
	var rows := VBoxContainer.new()
	card.add_child(rows)
	rows.add_child(UiDesign.label("Set the probe’s dry zero at the bench", "heading"))
	_notice = UiDesign.label("", "body")
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(_notice)
	var buttons := HBoxContainer.new()
	rows.add_child(buttons)
	_action = UiDesign.button("")
	_action.pressed.connect(interact)
	buttons.add_child(_action)
	var close := UiDesign.button("Close (Esc)")
	close.pressed.connect(cancel)
	buttons.add_child(close)
	UiDesign.apply_type(card, get_viewport().get_visible_rect().size.y, 1.5 if campaign.query().get("accessibility", {}).get("large_text", false) else 1.0)
	_refresh()

func target() -> Node3D:
	return rack if job.state() == "at_rack" else cradle

func interact() -> Dictionary:
	if _finished or campaign.loading or campaign._ui_paused or campaign.is_cutscene_active():
		return {"accepted": false}
	var point := target().global_position
	var player := campaign._player
	if Vector2(player.global_position.x - point.x, player.global_position.z - point.z).length() > REACH_M:
		_notice.text = "Walk closer to the marked rack or dry-reference cradle. WASD moves; E uses it."
		return {"accepted": false}
	var ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, point, player.collision_mask, [player.get_rid()])
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		_notice.text = "Walk around the furniture to reach the marked equipment."
		return {"accepted": false}
	var result: Dictionary
	match job.state():
		"at_rack": result = job.retrieve()
		"held": result = job.place_at_bench()
		"at_bench": result = job.observe_zero()
		_: return {"accepted": false}
	if result.get("accepted", false):
		campaign.save_campaign()
		_refresh()
		if job.completed():
			finish()
	return result

func _refresh() -> void:
	var carried: bool = job.held()
	_probe.visible = not carried
	_probe.global_position = (rack if job.state() == "at_rack" else cradle).global_position
	campaign._player.set_hold(PlayerAnimation.Hold.RIGHT if carried else PlayerAnimation.Hold.NONE)
	if carried and _held.prop == null:
		_held.setup(campaign._player.animation.skeleton, PlayerAnimation.Hold.RIGHT, load(Job.PROP_SCENE_PATH), false)
	elif not carried:
		_held.clear()
	_notice.text = job.prompt() + "\nWASD moves · Mouse looks · E uses the marked equipment. No timer."
	_action.text = {"at_rack": "E · Take probe", "held": "E · Place on dry reference", "at_bench": "E · Read dry zero"}.get(job.state(), "Dry zero observed: 10 → 0")

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()

func cancel() -> void:
	job.cancel() # carried returns to rack; a placed probe remains at the bench
	campaign.save_campaign()
	finish()

func finish() -> void:
	if _finished:
		return
	_finished = true
	_restore()
	closed.emit(job.completed())
	queue_free()

func _restore() -> void:
	if is_instance_valid(_held):
		_held.clear()
	if is_instance_valid(campaign):
		if is_instance_valid(campaign._player):
			campaign._player.set_hold(PlayerAnimation.Hold.NONE)
		if is_instance_valid(campaign.hud):
			campaign.hud.process_mode = _prior_hud_process
			campaign.hud.show()

func _exit_tree() -> void:
	_restore()
