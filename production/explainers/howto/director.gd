## How-to clip director (M1-59, doc 25 §7). Plays one spec from production/explainers/howto/specs/ on the game's
## own screens: it builds the real campaign (or Moon Trainer) at the spec's stage, then drives the real UI and 3D
## with scripted input while drawing the arrow, ring, key and caption overlays. Run under Movie Maker by build.py:
##   Godot --path game --resolution 1152x648 --fixed-fps 24 --write-movie <frames>/f.png \
##     -s production/explainers/howto/director.gd -- --spec <spec.json>
## Add --dump (headless is fine) to list the visible named controls after the stage is set, for writing steps.
extends "res://tools/test_player_text.gd"

const FPS := 24.0
const TrainerScene := preload("res://scenes/trainer/moon_trainer.tscn")
const HowTo := preload("res://scripts/ui/how_to_card.gd")
const PlantFixture := preload("res://tools/support/p01_input_fixture.gd")

var spec: Dictionary = {}
var campaign: Chapter1Campaign
var trainer: Control
var care: Control
var activity: Node
var overlay: Overlay
var _released: Array = []   # [time, action]

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--spec")
	spec = JSON.parse_string(FileAccess.get_file_as_string(args[at + 1])) if at >= 0 else {}
	if spec.is_empty():
		push_error("director: no spec")
		quit(2)
		return
	await _stage(spec.get("stage", {}))
	for step in spec.get("setup", []):
		await _do(step)
	for frame in 6:
		await process_frame
	if args.has("--dump"):
		_dump(root, "")
		quit(0)
		return
	if args.has("--still"):   # windowed: one screenshot of the staged screen (QA evidence), no overlay
		for frame in 30:
			await process_frame
		await RenderingServer.frame_post_draw
		print("director: still ", root.get_texture().get_image().save_png(args[args.find("--still") + 1]))
		quit(0)
		return
	await _play()

## ---- stage --------------------------------------------------------------------------------------------------

func _stage(stage: Dictionary) -> void:
	match String(stage.get("kind", "campaign")):
		"trainer":
			trainer = TrainerScene.instantiate()
			trainer.set("results_path", storage.directory.path_join("moon_results.json"))
			root.add_child(trainer)
			for frame in 30:
				await process_frame
			if stage.has("sortie"):
				trainer.call("start_sortie", String(stage.sortie))
				for frame in 60:
					await process_frame
		_:
			await _campaign_at(String(stage.get("scene", "EX-CH01-S01")), stage.get("done", []))
	if stage.has("near"):
		await _near(String(stage.near), stage.get("offset", [0.0, 0.0, 1.0]))
	if String(stage.get("kind", "")) == "care_round":
		_open_care_round()

## The Care Round panel on the route's own visit (moisture from the calibrated probe); the campaign HUD does not
## open it yet, so the clip opens it the way CareRoundRuntime documents. Photos are real frames of the room.
func _open_care_round() -> void:
	var visit: Dictionary = campaign.route.care_round_visit(campaign.route.current_scene_id())
	if visit.is_empty():
		print("director: no care round in " + campaign.route.current_scene_id())
		return
	var readings := {}
	for id in visit.moisture:
		readings[id] = {"moisture": visit.moisture[id], "temperature": float(spec.stage.get("chamber_c", 21.0))}
	care = CarePanel.new()
	campaign.hud.add_child(care)
	var round_runtime = preload("res://scripts/campaign/care_round_runtime.gd").new(campaign.director)
	set_meta("care_runtime", round_runtime)
	var dates: Array = visit.get("dates", [])
	print("director: care round ", round_runtime.open_round(care, String(visit.scene_id), String(dates[0]) if not dates.is_empty() else "", readings, {}, round_runtime.make_viewport_capture(root, care)))  # the game's own capture: hides the panel, photographs the room

func _care_capture(request: Dictionary) -> Dictionary:
	await RenderingServer.frame_post_draw
	# The real Growth Record path, so the panel shows the photo exactly as it does in play.
	var path := ProjectSettings.globalize_path(preload("res://scripts/campaign/care_round_runtime.gd").photo_path(String(request.get("individual_id", "plant")), String(request.get("date", spec.get("stage", {}).get("date", "2046-04-11")))))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return {"accepted": root.get_texture().get_image().save_png(path) == OK, "photo_path": path}

func _campaign_at(destination: String, done: Array) -> void:
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await campaign.wait_loading()
	var seen := campaign.hud.panels.hint_player
	seen.seen_path = storage.directory.path_join("how_to_seen.cfg")
	for id in HowTo.data().get("cards", {}):
		seen._remember(id)   # clips show only the card they teach
	PlanFixture.prepare(campaign.route)
	if destination.begins_with("EX-CH01"):
		_reach_route(campaign.route, destination)
	else:
		_reach_route(campaign.route, "EX-CH01-S12")
		_perform_all()
		campaign.route.advance_scene()
		campaign._sync_route_projection()
		campaign.choose_upgrade(1, "A")
		for scene_id in Chapter2Gates.scene_ids() + LaterGates.scene_ids():
			if campaign.loading:
				await campaign.wait_loading()
			if scene_id == destination:
				break
			_perform_all()
			var advanced: Dictionary = campaign.route.advance_scene()
			if advanced.get("chapter_complete", false) and not advanced.get("campaign_complete", false):
				campaign._sync_route_projection()
				campaign.choose_upgrade(int(String(scene_id).substr(5, 2)), "A")
			else:
				campaign._sync_route_projection()
	campaign._sync_route_projection()
	if campaign.loading:
		await campaign.wait_loading()
	for target_id in done:
		_perform(String(target_id))
	await _settle_scene()

func _perform_all() -> void:
	for target in campaign.targets_for_current_scene():
		_perform(String(target.target_id))

func _perform(target_id: String) -> Dictionary:
	if target_id == "p05_equip_gauge":
		campaign.hud.refresh_scene()
	for target in campaign.targets_for_current_scene():
		if String(target.target_id) == target_id:
			var payload := _player_payload(target, campaign.director.snapshot())
			if payload.is_empty():
				payload = PlantFixture.payload(target_id)  # P-01 planting choices (cassette, seed count, moisture, label), as the tests use
			var result: Dictionary = campaign.route.perform(target_id, payload)
			if not result.get("accepted", false):
				print("director: %s held: %s" % [target_id, result.get("reason", "")])
			return result
	print("director: no target " + target_id)
	return {}

func _settle_scene() -> void:
	campaign._refresh_world()
	if campaign.loading:
		await campaign.wait_loading()
	for line in campaign.current_dialogue():
		campaign.route.acknowledge_dialogue(String(line.id))
	campaign.hud.refresh_scene()
	for frame in 20:
		await process_frame

func _near(id: String, offset: Array) -> void:
	var target := campaign.physical_target(id)
	if target == null:
		print("director: no physical target " + id)
		return
	var player := campaign._player
	player.global_position = Vector3(target.global_position.x + float(offset[0]), 0.04 + float(offset[1]), target.global_position.z + float(offset[2]))
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	for frame in 4:
		await physics_frame
	var flat := target.global_position - player.global_position
	player.visual.rotation.y = atan2(flat.x, flat.z)
	player.follow_camera.yaw = player.visual.rotation.y - PI
	player.follow_camera.reset_placement()
	for frame in 10:
		await process_frame

## ---- timeline -----------------------------------------------------------------------------------------------

func _play() -> void:
	overlay = Overlay.new()
	overlay.director = self
	overlay.title = String(spec.get("title", ""))
	overlay.captions = spec.get("captions", [])
	overlay.length = float(spec.length_s)
	var layer := CanvasLayer.new()
	layer.layer = 120
	root.add_child(layer)
	layer.add_child(overlay)
	var steps: Array = spec.get("steps", []).duplicate()
	steps.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var total := int(round(float(spec.length_s) * FPS))
	print("HOWTO_START drawn=%d" % Engine.get_frames_drawn())
	for frame in total:
		var t := frame / FPS
		while not steps.is_empty() and float(steps[0][0]) <= t + 0.001:
			var step: Array = steps.pop_front()
			_do(step.slice(1), float(step[0]))
		for item in _released.duplicate():
			if t >= float(item[0]):
				Input.action_release(String(item[1]))
				_released.erase(item)
		overlay.t = t
		overlay.queue_redraw()
		await process_frame
	print("HOWTO_END drawn=%d frames=%d" % [Engine.get_frames_drawn(), total])
	quit(0)

func _do(step: Array, t: float = 0.0) -> void:
	var verb := String(step[0])
	match verb:
		"hold":   # action, seconds, keycap
			Input.action_press(String(step[1]))
			_released.append([t + float(step[2]), String(step[1])])
			if step.size() > 3:
				overlay.keys.append({"text": String(step[3]), "from": t, "to": t + float(step[2])})
		"key":   # key name, keycap
			_key_event(String(step[1]))
			overlay.keys.append({"text": String(step[2]) if step.size() > 2 else String(step[1]), "from": t, "to": t + 0.9})
		"click":   # control name: the pointer glides there, then the real button is pressed
			var control := _control(String(step[1]))
			if control == null:
				print("director: click target missing " + String(step[1]))
				return
			var to := control.get_global_rect().get_center()
			overlay.cursor_moves.append({"from": t, "to": t + 0.5, "a": overlay.cursor, "b": to})
			await _after(0.5)
			overlay.clicks.append({"at": overlay.t, "p": to})
			if control is BaseButton:
				control.grab_focus()
				if (control as BaseButton).toggle_mode:
					(control as BaseButton).button_pressed = not (control as BaseButton).button_pressed
				control.pressed.emit()
		"ring", "arrow":   # target, seconds, optional label
			overlay.marks.append({"kind": verb, "target": step[1], "from": t, "to": t + float(step[2]), "label": String(step[3]) if step.size() > 3 else ""})
		"look":   # yaw degrees, seconds
			var camera = campaign._player.follow_camera
			var tween := campaign.create_tween()
			tween.tween_property(camera, "yaw", camera.yaw + deg_to_rad(float(step[1])), float(step[2])).set_trans(Tween.TRANS_SINE)
		"call":   # object, method, args...
			var object = _object(String(step[1]))
			if object == null or not object.has_method(String(step[2])):
				print("director: cannot call %s.%s" % [step[1], step[2]])
				return
			var result = object.callv(String(step[2]), step.slice(3))
			if result is PayloadStackActivity:
				activity = result
		"payload":   # the real carry-and-stack activity from the open Mission Table; then "call", "activity", ...
			activity = PayloadStackActivity.launch(campaign, campaign.hud.mission_table._settings)
		"near":   # walk-in shortcut between steps: place the cadet in reach of a target
			await _near(String(step[1]), step[2] if step.size() > 2 else [0.0, 0.0, 1.0])
		"perform":
			var result := _perform(String(step[1]))
			if campaign.hud != null:
				campaign.hud.refresh_after_action(result.get("result", result))
		"set":   # object, property, value
			var object = _object(String(step[1]))
			if object != null:
				object.set(String(step[2]), step[3])
		"scroll_to":   # bring a named control into view inside its scroll container
			var control := _control(String(step[1]))
			var scroll := control.get_parent() if control != null else null
			while scroll != null and not scroll is ScrollContainer:
				scroll = scroll.get_parent()
			if scroll != null:
				await process_frame
				(scroll as ScrollContainer).ensure_control_visible(control)
		"wait":
			await _after(float(step[1]))
		_:
			print("director: unknown verb " + verb)

func _after(seconds: float) -> void:
	for frame in int(round(seconds * FPS)):
		await process_frame

func _key_event(name: String) -> void:
	var code := OS.find_keycode_from_string(name)
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.unicode = name.unicode_at(0) if name.length() == 1 else 0
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func _object(path: String) -> Object:
	var parts := path.split(".")
	var object: Object = {"campaign": campaign, "hud": campaign.hud if campaign != null else null, "trainer": trainer, "care": care,
		"activity": activity, "route": campaign.route if campaign != null else null, "player": campaign._player if campaign != null else null}.get(parts[0])
	for part in parts.slice(1):
		if object == null:
			return null
		object = object.get(part) as Object
	return object

## A visible control by node name, last match wins (later siblings draw on top).
func _control(name: String) -> Control:
	var found: Control = null
	for node in root.find_children(name, "Control", true, false):
		if (node as Control).is_visible_in_tree():
			found = node
	return found

## Where a mark points, in the root canvas: a control's rectangle, a 3D target or a fixed point.
func target_rect(target) -> Rect2:
	if target is Array:
		return Rect2(Vector2(float(target[0]), float(target[1])), Vector2(float(target[2]) if target.size() > 2 else 0.0, float(target[3]) if target.size() > 3 else 0.0))
	var name := String(target)
	if name.begins_with("@") or name == "player":
		var lift := 1.0 if name == "player" else 0.4
		if trainer != null:   # the trainer draws its 3D field in a SubViewport inside its own layout
			var field: SubViewport = trainer.get("_sub_viewport")
			var box: Control = trainer.get("_viewport_container")
			var cadet: Node3D = trainer.get("player")
			if field == null or box == null or cadet == null or field.get_camera_3d() == null:
				return Rect2()
			var q := field.get_camera_3d().unproject_position(cadet.global_position + Vector3.UP * lift)
			var at := box.get_global_rect().position + q * box.get_global_rect().size / Vector2(field.size)
			return Rect2(at - Vector2(46, 46), Vector2(92, 92))
		var node: Node3D = campaign._player if name == "player" else campaign.physical_target(name.substr(1))
		var camera := root.get_camera_3d()
		if node == null or camera == null or camera.is_position_behind(node.global_position):
			return Rect2()
		var p := camera.unproject_position(node.global_position + Vector3.UP * lift)
		return Rect2(p - Vector2(46, 46), Vector2(92, 92))
	var control := _control(name)
	return control.get_global_rect() if control != null else Rect2()

func _dump(node: Node, indent: String) -> void:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return
	if node is Control and not String(node.name).begins_with("@"):
		var text := ""
		if node is Button:
			text = (node as Button).text
		elif node is Label:
			text = (node as Label).text
		var rect := (node as Control).get_global_rect()
		print("%s%s [%s] %s %s" % [indent, node.name, node.get_class(), rect, text.substr(0, 60).replace("\n", " / ")])
	for child in node.get_children():
		_dump(child, indent + " " if node is Control else indent)

## ---- overlay ------------------------------------------------------------------------------------------------

class Overlay extends Control:
	const ACCENT := Color("#FF4F8B")  # neon rose: how-to marks stand apart from the cerulean UI
	const IVORY := Color("#EEF1F8")
	const INK := Color("#05060A")
	var director
	var t := 0.0
	var length := 10.0
	var title := ""
	var captions: Array = []
	var marks: Array = []
	var keys: Array = []
	var clicks: Array = []
	var cursor_moves: Array = []
	var cursor := Vector2(640, 400)
	var _cursor_seen := false

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var view := get_viewport_rect().size
		# Chip: what this clip teaches.
		var chip := "HOW TO  ·  " + title.to_upper()
		var chip_size := font.get_string_size(chip, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		var chip_rect := Rect2(Vector2((view.x - chip_size.x) * 0.5 - 14, 10), Vector2(chip_size.x + 28, 30))
		draw_style_box(_box(Color(INK, 0.78), ACCENT), chip_rect)
		draw_string(font, chip_rect.position + Vector2(14, 21), chip, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ACCENT)
		for mark in marks:
			if t < float(mark.from) or t > float(mark.to):
				continue
			var rect: Rect2 = director.target_rect(mark.target)
			if rect.size == Vector2.ZERO and rect.position == Vector2.ZERO:
				continue
			var appear := clampf((t - float(mark.from)) / 0.3, 0.0, 1.0)
			var pulse := 0.5 + 0.5 * sin((t - float(mark.from)) * TAU * 0.9)
			if mark.kind == "ring":
				var grown := rect.grow(6.0 + 4.0 * pulse + (1.0 - appear) * 30.0)
				draw_style_box(_ring(Color(ACCENT, appear), 4), grown)
				if mark.label != "":
					_label(font, mark.label, Vector2(grown.get_center().x, grown.end.y + 26) if grown.end.y < view.y - 150 else Vector2(grown.get_center().x, grown.position.y - 14), appear)
			else:
				var tip := _edge_point(rect, view)
				var dir := (tip - view * 0.5).normalized() if tip.distance_to(view * 0.5) > 1.0 else Vector2.DOWN
				var back := tip - dir * (90.0 + 10.0 * pulse)
				tip -= dir * (6.0 + 6.0 * pulse)
				draw_line(back, tip - dir * 14, Color(ACCENT, appear), 7.0, true)
				var side := dir.orthogonal() * 14
				draw_colored_polygon(PackedVector2Array([tip, tip - dir * 24 + side, tip - dir * 24 - side]), Color(ACCENT, appear))
				if mark.label != "":
					_label(font, mark.label, back - dir * 20 + Vector2(0, 6), appear)
		# Keys being pressed, bottom left above the caption.
		var x := 24.0
		for key in keys:
			if t < float(key.from) or t > float(key.to):
				continue
			var size := font.get_string_size(key.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
			var rect := Rect2(Vector2(x, view.y - 168), Vector2(maxf(48, size.x + 26), 48))
			draw_style_box(_box(Color(IVORY, 0.95), ACCENT, 3), rect)
			draw_string(font, rect.position + Vector2((rect.size.x - size.x) * 0.5, 32), key.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
			x += rect.size.x + 10
		# Pointer and click ripples.
		for move in cursor_moves:
			if t >= float(move.from) and t <= float(move.to) + 0.05:
				var k := clampf((t - float(move.from)) / maxf(0.01, float(move.to) - float(move.from)), 0.0, 1.0)
				cursor = (move.a as Vector2).lerp(move.b, k * k * (3.0 - 2.0 * k))
				_cursor_seen = true
		for click in clicks:
			var age := t - float(click.at)
			if age >= 0.0 and age < 0.5:
				draw_arc(click.p, 10.0 + age * 70.0, 0, TAU, 32, Color(ACCENT, 1.0 - age * 2.0), 3.0, true)
		if _cursor_seen:
			var c := cursor
			var arrow := PackedVector2Array([c, c + Vector2(0, 26), c + Vector2(7, 20), c + Vector2(13, 31), c + Vector2(18, 29), c + Vector2(12, 18), c + Vector2(21, 18)])
			draw_colored_polygon(arrow, IVORY)
			draw_polyline(arrow + PackedVector2Array([c]), INK, 2.0, true)
		# Caption on a scrim, bottom centre.
		for caption in captions:
			if t >= float(caption[0]) and t < float(caption[1]):
				var width := minf(980.0, view.x - 80)
				var lines := font.get_multiline_string_size(String(caption[2]), HORIZONTAL_ALIGNMENT_CENTER, width, 26)
				var box := Rect2(Vector2((view.x - width) * 0.5 - 20, view.y - 108 - lines.y * 0.5), Vector2(width + 40, lines.y + 26))
				draw_style_box(_box(Color(INK, 0.82), Color.TRANSPARENT), box)
				draw_multiline_string(font, box.position + Vector2(20, 13 + font.get_ascent(26)), String(caption[2]), HORIZONTAL_ALIGNMENT_CENTER, width, 26, -1, IVORY)
		# Progress along the bottom edge.
		draw_rect(Rect2(0, view.y - 5, view.x * clampf(t / length, 0.0, 1.0), 5), Color(ACCENT, 0.9))

	func _label(font: Font, text: String, centre: Vector2, alpha: float) -> void:
		var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		var rect := Rect2(centre - Vector2(size.x * 0.5 + 12, 22), Vector2(size.x + 24, 32))
		rect.position.x = clampf(rect.position.x, 8, get_viewport_rect().size.x - rect.size.x - 8)
		draw_style_box(_box(Color(ACCENT, alpha), Color.TRANSPARENT), rect)
		draw_string(font, rect.position + Vector2(12, 23), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(INK, alpha))

	func _edge_point(rect: Rect2, view: Vector2) -> Vector2:
		# The arrow comes from the screen centre side and stops at the nearest edge of the target.
		var centre := rect.get_center()
		var from := view * 0.5
		if rect.size == Vector2.ZERO:
			return centre
		var dir := (centre - from)
		if dir.length() < 1.0:
			return Vector2(centre.x, rect.position.y)
		var half := rect.size * 0.5
		var scale := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		return centre - dir * minf(scale, 1.0)

	func _box(fill: Color, edge: Color, width: int = 2) -> StyleBoxFlat:
		var box := StyleBoxFlat.new()
		box.bg_color = fill
		box.set_corner_radius_all(10)
		if edge.a > 0.0:
			box.border_color = edge
			box.set_border_width_all(width)
		return box

	func _ring(edge: Color, width: int) -> StyleBoxFlat:
		var box := _box(Color.TRANSPARENT, edge, width)
		box.set_corner_radius_all(14)
		return box
