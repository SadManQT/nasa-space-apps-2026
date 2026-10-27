extends Node3D

const CharacterSwitcher: Script = preload("res://scripts/player/character_switcher.gd")
const CAST: Array[String] = CharacterSwitcher.CAST

var _hold_label: Label
var _cast_label: Label
var cast_index := 0

func _ready() -> void:
	_box("Floor", Vector3(0.0, -0.25, 0.0), Vector3(60.0, 0.5, 100.0))
	var ramp := _box("Ramp", Vector3(-5.0, 0.6, -5.0), Vector3(3.0, 0.3, 5.0))
	ramp.rotation.x = deg_to_rad(15.0)
	for step in 5:
		_box("Stair%d" % step, Vector3(4.0, (step + 1) * 0.09, -3.0 - step * 0.45), Vector3(2.0, (step + 1) * 0.18, 0.45))
	_box("Landing", Vector3(4.0, 0.45, -5.8), Vector3(2.0, 0.9, 2.0))
	_box("CorridorLeft", Vector3(-1.1, 1.5, -12.0), Vector3(0.3, 3.0, 7.0))
	_box("CorridorRight", Vector3(1.1, 1.5, -12.0), Vector3(0.3, 3.0, 7.0))
	_box("CameraWall", Vector3(0.0, 1.5, 4.0), Vector3(12.0, 3.0, 0.3))
	_box("SideWall", Vector3(7.5, 1.5, 0.0), Vector3(0.3, 3.0, 10.0))
	var door := _box("Door", Vector3(-2.5, 1.0, -2.5), Vector3(0.7, 2.0, 0.2))
	door.add_to_group("interactable")
	door.set_meta("action", "OpenDoor")
	var console := _box("Console", Vector3(2.5, 0.6, 0.0), Vector3(0.8, 1.2, 0.6))
	console.add_to_group("interactable")
	console.set_meta("action", "Inspect")
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.shadow_enabled = true
	add_child(light)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.19, 0.20, 0.22)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.8, 0.82, 0.85)
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	add_child(environment)
	var ui := CanvasLayer.new()
	var label := Label.new()
	label.position = Vector2(20.0, 20.0)
	label.text = "WASD / left stick: walk   Shift / full stick: run   Ctrl + run: sprint\nMouse / right stick: look   E / A: interact   Esc: release mouse\nRamp: left   Stairs: right   Corridor: ahead"
	ui.add_child(label)
	_hold_label = Label.new()
	_hold_label.position = Vector2(20.0, 95.0)
	_hold_label.text = "H: cycle hold — NONE"
	ui.add_child(_hold_label)
	_cast_label = Label.new()
	_cast_label.position = Vector2(20.0, 120.0)
	ui.add_child(_cast_label)
	add_child(ui)
	_update_cast_label()

## Swaps the player for another cast member in the same spot, facing, camera angle and hold.
func switch_character(index: int) -> void:
	CharacterSwitcher.switch_character($Player as PlayerController, index)
	cast_index = index
	_update_cast_label()

func _update_cast_label() -> void:
	var names := PackedStringArray()
	for i in CAST.size():
		var label := "%d %s" % [i + 1, CAST[i].trim_prefix("CH_")]
		names.append("[" + label + "]" if i == cast_index else label)
	_cast_label.text = "Character (1-5, Tab: next):  " + "   ".join(names)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).physical_keycode
	if key >= KEY_1 and key < KEY_1 + CAST.size():
		switch_character(key - KEY_1)
	elif key == KEY_TAB:
		switch_character((cast_index + 1) % CAST.size())
	elif key == KEY_H:
		var player := $Player as PlayerController
		if player.animation != null:
			var mode := (player.animation.hold_mode + 1) % PlayerAnimation.Hold.size()
			player.set_hold(mode as PlayerAnimation.Hold)
			_hold_label.text = "H: cycle hold — " + PlayerAnimation.Hold.keys()[mode]
	else:
		return
	get_viewport().set_input_as_handled()

func _box(label: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.47, 0.49)
	material.roughness = 0.95
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)
	return body
