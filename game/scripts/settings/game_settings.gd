extends RefCounted
class_name GameSettings

## Steam-quality persistent player settings (M3-70, doc 25 §2.3 & §11):
## - Display: resolution, window mode, V-sync, frame cap, quality preset, field of view (FOV)
## - Audio: Master, Music, Voice, Effects (SFX) and Interface (UI) volume synced with AudioSettings
## - Controls: full keyboard and controller remapping with matching button glyphs and automatic conflict swap
## - Captions & Assist: captions, subtitle size (Small/Medium/Large/Extra Large), reduced motion, timer-free,
##   and assist modes (Story, Cadet, Expedition) plus Family/Class mode support
## - Cutscenes & Saves: skip any cutscene after the first viewing, pause anywhere, save slots integration

const AudioSettingsScript = preload("res://scripts/audio/audio_settings.gd")

const DEFAULT_PATH := "user://game_settings.cfg"

const RESOLUTIONS := [
	"1280x720",
	"1600x900",
	"1920x1080",
	"2560x1440",
	"3840x2160",
]

const WINDOW_MODES := ["Windowed", "Borderless", "Fullscreen"]
const FRAME_CAPS := [0, 30, 60, 120, 144]
const QUALITY_PRESETS := ["Low", "Medium", "High", "Ultra"]
const SUBTITLE_SIZES := ["Small", "Medium", "Large", "Extra Large"]
const SUBTITLE_SCALES := {
	"Small": 0.9,
	"Medium": 1.0,
	"Large": 1.25,
	"Extra Large": 1.5,
}
const ASSIST_MODES := ["Story", "Cadet", "Expedition"]
const SESSION_MODES := ["Solo", "Family", "Class"]

const REMAPPABLE_ACTIONS := [
	{"id": "move_forward", "label": "Move forward"},
	{"id": "move_back", "label": "Move backward"},
	{"id": "move_left", "label": "Move left"},
	{"id": "move_right", "label": "Move right"},
	{"id": "run", "label": "Run / Sprint"},
	{"id": "interact", "label": "Use / Interact"},
	{"id": "what_now", "label": "What now"},
	{"id": "journal", "label": "Journal"},
	{"id": "messages", "label": "Messages"},
	{"id": "pause", "label": "Pause"},
	{"id": "eva_scanner", "label": "Suit scanner"},
	{"id": "next_line", "label": "Next dialogue line"},
	{"id": "advance", "label": "Next scene"},
]

const DEFAULT_KEYBOARD_BINDINGS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"run": KEY_SHIFT,
	"interact": KEY_E,
	"what_now": KEY_H,
	"journal": KEY_J,
	"messages": KEY_M,
	"pause": KEY_ESCAPE,
	"eva_scanner": KEY_Q,
	"next_line": KEY_SPACE,
	"advance": KEY_ENTER,
}

const DEFAULT_CONTROLLER_BINDINGS := {
	"move_forward": JOY_BUTTON_DPAD_UP,
	"move_back": JOY_BUTTON_DPAD_DOWN,
	"move_left": JOY_BUTTON_DPAD_LEFT,
	"move_right": JOY_BUTTON_DPAD_RIGHT,
	"run": JOY_BUTTON_LEFT_STICK,
	"interact": JOY_BUTTON_A,
	"what_now": JOY_BUTTON_Y,
	"journal": JOY_BUTTON_BACK,
	"messages": JOY_BUTTON_X,
	"pause": JOY_BUTTON_START,
	"eva_scanner": JOY_BUTTON_LEFT_SHOULDER,
	"next_line": JOY_BUTTON_RIGHT_SHOULDER,
	"advance": JOY_BUTTON_B,
}

const CONTROLLER_GLYPHS := {
	JOY_BUTTON_A: "(A) Cross",
	JOY_BUTTON_B: "(B) Circle",
	JOY_BUTTON_X: "(X) Square",
	JOY_BUTTON_Y: "(Y) Triangle",
	JOY_BUTTON_LEFT_SHOULDER: "[LB / L1]",
	JOY_BUTTON_RIGHT_SHOULDER: "[RB / R1]",
	JOY_BUTTON_START: "[Start / Options]",
	JOY_BUTTON_BACK: "[Select / Share]",
	JOY_BUTTON_LEFT_STICK: "[L3 Stick]",
	JOY_BUTTON_RIGHT_STICK: "[R3 Stick]",
	JOY_BUTTON_DPAD_UP: "[D-Pad Up]",
	JOY_BUTTON_DPAD_DOWN: "[D-Pad Down]",
	JOY_BUTTON_DPAD_LEFT: "[D-Pad Left]",
	JOY_BUTTON_DPAD_RIGHT: "[D-Pad Right]",
}

var config_path: String = DEFAULT_PATH
var audio_config_path: String = AudioSettingsScript.path

var display: Dictionary = {}
var audio: Dictionary = {}
var accessibility: Dictionary = {}
var keyboard_bindings: Dictionary = {}
var controller_bindings: Dictionary = {}
var seen_cutscenes: Dictionary = {}
var skip_viewed_cutscenes: bool = true
var pause_anywhere: bool = true

func _init(p_config_path: String = DEFAULT_PATH, p_audio_path: String = "") -> void:
	config_path = p_config_path
	if not p_audio_path.is_empty():
		audio_config_path = p_audio_path
	reset_to_defaults(false)
	load_from_disk()

func reset_to_defaults(persist: bool = true) -> void:
	display = {
		"resolution": "1920x1080",
		"window_mode": "Windowed",
		"vsync": true,
		"frame_cap": 60,
		"quality_preset": "High",
		"fov": 75.0,
	}
	audio = {
		"Master": 1.0,
		"Music": 0.85,
		"Voice": 1.0,
		"SFX": 0.9,
		"UI": 0.85,
	}
	accessibility = {
		"captions": true,
		"subtitle_size": "Medium",
		"subtitle_scale": 1.0,
		"large_text": false,
		"timer_free": true,
		"reduced_motion": false,
		"assist_mode": "Cadet",
		"session_mode": "Solo",
		"family_mode": false,
		"class_mode": false,
	}
	keyboard_bindings = DEFAULT_KEYBOARD_BINDINGS.duplicate(true)
	controller_bindings = DEFAULT_CONTROLLER_BINDINGS.duplicate(true)
	skip_viewed_cutscenes = true
	pause_anywhere = true
	apply_all()
	if persist:
		save_to_disk()

func load_from_disk() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(config_path) != OK:
		apply_all()
		return false
	for key in display.keys():
		if cfg.has_section_key("display", key):
			display[key] = cfg.get_value("display", key, display[key])
	_sanitize_display()
	for bus in audio.keys():
		if cfg.has_section_key("audio", bus):
			audio[bus] = clampf(float(cfg.get_value("audio", bus, audio[bus])), 0.0, 1.0)
	for key in accessibility.keys():
		if cfg.has_section_key("accessibility", key):
			accessibility[key] = cfg.get_value("accessibility", key, accessibility[key])
	_sanitize_accessibility()
	for spec in REMAPPABLE_ACTIONS:
		var action_id: String = spec.id
		if cfg.has_section_key("keyboard_bindings", action_id):
			keyboard_bindings[action_id] = int(cfg.get_value("keyboard_bindings", action_id, keyboard_bindings[action_id]))
		if cfg.has_section_key("controller_bindings", action_id):
			controller_bindings[action_id] = int(cfg.get_value("controller_bindings", action_id, controller_bindings[action_id]))
	if cfg.has_section_key("cutscenes", "skip_viewed_cutscenes"):
		skip_viewed_cutscenes = bool(cfg.get_value("cutscenes", "skip_viewed_cutscenes", true))
	if cfg.has_section_key("cutscenes", "pause_anywhere"):
		pause_anywhere = bool(cfg.get_value("cutscenes", "pause_anywhere", true))
	if cfg.has_section_key("cutscenes", "seen_cutscenes"):
		var raw_seen = cfg.get_value("cutscenes", "seen_cutscenes", {})
		if raw_seen is Dictionary:
			seen_cutscenes = (raw_seen as Dictionary).duplicate(true)
	apply_all()
	return true

func save_to_disk() -> bool:
	var cfg := ConfigFile.new()
	for key in display.keys():
		cfg.set_value("display", key, display[key])
	for bus in audio.keys():
		cfg.set_value("audio", bus, audio[bus])
	for key in accessibility.keys():
		cfg.set_value("accessibility", key, accessibility[key])
	for spec in REMAPPABLE_ACTIONS:
		var action_id: String = spec.id
		cfg.set_value("keyboard_bindings", action_id, int(keyboard_bindings.get(action_id, DEFAULT_KEYBOARD_BINDINGS[action_id])))
		cfg.set_value("controller_bindings", action_id, int(controller_bindings.get(action_id, DEFAULT_CONTROLLER_BINDINGS[action_id])))
	cfg.set_value("cutscenes", "skip_viewed_cutscenes", skip_viewed_cutscenes)
	cfg.set_value("cutscenes", "pause_anywhere", pause_anywhere)
	cfg.set_value("cutscenes", "seen_cutscenes", seen_cutscenes.duplicate(true))
	return cfg.save(config_path) == OK

func snapshot() -> Dictionary:
	return {
		"display": display.duplicate(true),
		"audio": audio.duplicate(true),
		"accessibility": accessibility_for_campaign(),
		"keyboard_bindings": keyboard_bindings.duplicate(true),
		"controller_bindings": controller_bindings.duplicate(true),
		"skip_viewed_cutscenes": skip_viewed_cutscenes,
		"pause_anywhere": pause_anywhere,
		"seen_cutscenes": seen_cutscenes.duplicate(true),
	}

func accessibility_for_campaign() -> Dictionary:
	return {
		"captions": bool(accessibility.get("captions", true)),
		"subtitle_size": String(accessibility.get("subtitle_size", "Medium")),
		"subtitle_scale": float(accessibility.get("subtitle_scale", 1.0)),
		"large_text": bool(accessibility.get("large_text", false)),
		"timer_free": bool(accessibility.get("timer_free", true)),
		"reduced_motion": bool(accessibility.get("reduced_motion", false)),
		"assist_mode": String(accessibility.get("assist_mode", "Cadet")),
		"session_mode": String(accessibility.get("session_mode", "Solo")),
		"family_mode": bool(accessibility.get("family_mode", false)),
		"class_mode": bool(accessibility.get("class_mode", false)),
	}

func set_display_option(key: String, value: Variant, persist: bool = true) -> Dictionary:
	if not display.has(key):
		return {"accepted": false, "reason": "Unknown display setting."}
	display[key] = value
	_sanitize_display()
	apply_display()
	if persist:
		save_to_disk()
	return {"accepted": true, "display": display.duplicate(true)}

func set_audio_volume(bus: String, value: float, persist: bool = true) -> Dictionary:
	var canonical := "SFX" if bus == "Effects" else bus
	if not audio.has(canonical):
		return {"accepted": false, "reason": "Unknown audio channel."}
	audio[canonical] = clampf(value, 0.0, 1.0)
	apply_audio()
	if persist:
		save_to_disk()
	return {"accepted": true, "bus": canonical, "volume": audio[canonical]}

func set_accessibility_option(key: String, value: Variant, persist: bool = true) -> Dictionary:
	if key == "assist_mode":
		var mode := String(value)
		if mode in ["Family", "Class"]:
			accessibility["session_mode"] = mode
			accessibility["family_mode"] = mode == "Family"
			accessibility["class_mode"] = mode == "Class"
			accessibility["assist_mode"] = "Story" if mode == "Family" else "Cadet"
			accessibility["timer_free"] = true
		elif mode in ASSIST_MODES:
			accessibility["assist_mode"] = mode
			if mode == "Story":
				accessibility["timer_free"] = true
		else:
			return {"accepted": false, "reason": "Choose Story, Cadet or Expedition assistance."}
	elif key == "session_mode":
		var smode := String(value)
		if not smode in SESSION_MODES:
			return {"accepted": false, "reason": "Choose Solo, Family or Class mode."}
		accessibility["session_mode"] = smode
		accessibility["family_mode"] = smode == "Family"
		accessibility["class_mode"] = smode == "Class"
		if smode in ["Family", "Class"]:
			accessibility["timer_free"] = true
	elif key == "subtitle_size":
		var sz := String(value)
		if not SUBTITLE_SCALES.has(sz):
			return {"accepted": false, "reason": "Choose Small, Medium, Large or Extra Large subtitles."}
		accessibility["subtitle_size"] = sz
		accessibility["subtitle_scale"] = float(SUBTITLE_SCALES[sz])
		accessibility["large_text"] = float(SUBTITLE_SCALES[sz]) >= 1.25
	elif key == "large_text":
		var large := bool(value)
		accessibility["large_text"] = large
		accessibility["subtitle_size"] = "Extra Large" if large else "Medium"
		accessibility["subtitle_scale"] = 1.5 if large else 1.0
	elif accessibility.has(key):
		accessibility[key] = value
	else:
		return {"accepted": false, "reason": "Unknown accessibility setting."}
	_sanitize_accessibility()
	if persist:
		save_to_disk()
	return {"accepted": true, "accessibility": accessibility_for_campaign()}

func remap_keyboard(action_id: String, physical_keycode: int, persist: bool = true) -> Dictionary:
	if not keyboard_bindings.has(action_id):
		return {"accepted": false, "reason": "Unknown control action."}
	if physical_keycode <= 0:
		return {"accepted": false, "reason": "Choose a valid keyboard key."}
	var previous_key := int(keyboard_bindings.get(action_id, DEFAULT_KEYBOARD_BINDINGS[action_id]))
	var swapped_with := ""
	for other_id in keyboard_bindings.keys():
		if other_id != action_id and int(keyboard_bindings[other_id]) == physical_keycode:
			keyboard_bindings[other_id] = previous_key
			swapped_with = String(other_id)
			break
	keyboard_bindings[action_id] = physical_keycode
	apply_controls()
	if persist:
		save_to_disk()
	return {
		"accepted": true,
		"action": action_id,
		"keycode": physical_keycode,
		"glyph": keyboard_glyph(action_id),
		"swapped_with": swapped_with,
	}

func remap_controller(action_id: String, joy_button: int, persist: bool = true) -> Dictionary:
	if not controller_bindings.has(action_id):
		return {"accepted": false, "reason": "Unknown control action."}
	if joy_button < 0:
		return {"accepted": false, "reason": "Choose a valid controller button."}
	var previous_btn := int(controller_bindings.get(action_id, DEFAULT_CONTROLLER_BINDINGS[action_id]))
	var swapped_with := ""
	for other_id in controller_bindings.keys():
		if other_id != action_id and int(controller_bindings[other_id]) == joy_button:
			controller_bindings[other_id] = previous_btn
			swapped_with = String(other_id)
			break
	controller_bindings[action_id] = joy_button
	apply_controls()
	if persist:
		save_to_disk()
	return {
		"accepted": true,
		"action": action_id,
		"joy_button": joy_button,
		"glyph": controller_glyph(action_id),
		"swapped_with": swapped_with,
	}

func keyboard_glyph(action_id: String) -> String:
	var code := int(keyboard_bindings.get(action_id, DEFAULT_KEYBOARD_BINDINGS.get(action_id, KEY_NONE)))
	return keycode_glyph(code)

static func keycode_glyph(code: int) -> String:
	match code:
		KEY_ESCAPE:
			return "Esc"
		KEY_ENTER, KEY_KP_ENTER:
			return "Enter"
		KEY_SPACE:
			return "Space"
		KEY_SHIFT:
			return "Shift"
		KEY_TAB:
			return "Tab"
		KEY_UP:
			return "Up"
		KEY_DOWN:
			return "Down"
		KEY_LEFT:
			return "Left"
		KEY_RIGHT:
			return "Right"
		_:
			var text := OS.get_keycode_string(code)
			return text if not text.is_empty() else "Key"

func controller_glyph(action_id: String) -> String:
	var btn := int(controller_bindings.get(action_id, DEFAULT_CONTROLLER_BINDINGS.get(action_id, JOY_BUTTON_A)))
	return joy_button_glyph(btn)

static func joy_button_glyph(btn: int) -> String:
	if CONTROLLER_GLYPHS.has(btn):
		return String(CONTROLLER_GLYPHS[btn])
	return "Pad %d" % btn

func mark_cutscene_seen(cutscene_id: String, persist: bool = true) -> void:
	if cutscene_id.is_empty():
		return
	seen_cutscenes[cutscene_id] = true
	if persist:
		save_to_disk()

func has_seen_cutscene(cutscene_id: String) -> bool:
	return bool(seen_cutscenes.get(cutscene_id, false))

func can_skip_cutscene_immediately(cutscene_id: String) -> bool:
	return skip_viewed_cutscenes and has_seen_cutscene(cutscene_id)

func effective_cutscene_skip_hold_s(cutscene_id: String, default_hold_s: float = 1.0) -> float:
	if can_skip_cutscene_immediately(cutscene_id):
		return 0.02
	return maxf(0.05, default_hold_s)

func apply_all(camera: Camera3D = null) -> void:
	apply_display(camera)
	apply_audio()
	apply_controls()

func apply_display(camera: Camera3D = null) -> void:
	_sanitize_display()
	var cap := int(display.get("frame_cap", 60))
	Engine.max_fps = cap if cap > 0 else 0
	if DisplayServer.get_name() != "headless":
		var vsync_on := bool(display.get("vsync", true))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_on else DisplayServer.VSYNC_DISABLED)
		var mode := String(display.get("window_mode", "Windowed"))
		if mode == "Fullscreen":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif mode == "Borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			var res := parse_resolution(String(display.get("resolution", "1920x1080")))
			DisplayServer.window_set_size(res)
	if camera != null:
		camera.fov = float(display.get("fov", 75.0))

func apply_to_campaign(campaign: Node) -> void:
	if campaign == null:
		return
	var player = campaign.get("_player")
	if player != null and player.get("follow_camera") != null and player.follow_camera.get("camera") is Camera3D:
		apply_display(player.follow_camera.camera as Camera3D)
	else:
		apply_display()
	apply_audio()
	apply_controls()
	if campaign.has_method("handle_ui_command"):
		campaign.call("handle_ui_command", {"verb": "set_accessibility", "payload": accessibility_for_campaign()})

func apply_audio() -> void:
	var prev_path: String = AudioSettingsScript.path
	AudioSettingsScript.path = audio_config_path
	AudioSettingsScript.forget_cache()
	for bus in ["Master", "Music", "Voice", "SFX", "UI"]:
		if audio.has(bus):
			AudioSettingsScript.set_volume(bus, float(audio[bus]))
	AudioSettingsScript.path = prev_path

func apply_controls() -> void:
	for spec in REMAPPABLE_ACTIONS:
		var action_id: String = spec.id
		if not InputMap.has_action(action_id):
			InputMap.add_action(action_id)
		InputMap.action_erase_events(action_id)
		var keycode := int(keyboard_bindings.get(action_id, DEFAULT_KEYBOARD_BINDINGS[action_id]))
		var key_ev := InputEventKey.new()
		key_ev.physical_keycode = keycode as Key
		key_ev.keycode = keycode as Key
		InputMap.action_add_event(action_id, key_ev)
		var joy_btn := int(controller_bindings.get(action_id, DEFAULT_CONTROLLER_BINDINGS[action_id]))
		var joy_ev := InputEventJoypadButton.new()
		joy_ev.button_index = joy_btn as JoyButton
		InputMap.action_add_event(action_id, joy_ev)
	# Keep "sprint" synchronized with "run" so PlayerController and EvaSuit see the same binding.
	if not InputMap.has_action("sprint"):
		InputMap.add_action("sprint")
	InputMap.action_erase_events("sprint")
	for ev in InputMap.action_get_events("run"):
		InputMap.action_add_event("sprint", ev)

static func parse_resolution(res_text: String) -> Vector2i:
	var parts := res_text.split("x")
	if parts.size() == 2:
		var w := int(parts[0])
		var h := int(parts[1])
		if w >= 640 and h >= 360:
			return Vector2i(w, h)
	return Vector2i(1920, 1080)

func _sanitize_display() -> void:
	if not String(display.get("resolution", "")) in RESOLUTIONS:
		display["resolution"] = "1920x1080"
	if not String(display.get("window_mode", "")) in WINDOW_MODES:
		display["window_mode"] = "Windowed"
	display["vsync"] = bool(display.get("vsync", true))
	var cap := int(display.get("frame_cap", 60))
	if not cap in FRAME_CAPS:
		display["frame_cap"] = 60
	else:
		display["frame_cap"] = cap
	if not String(display.get("quality_preset", "")) in QUALITY_PRESETS:
		display["quality_preset"] = "High"
	display["fov"] = clampf(float(display.get("fov", 75.0)), 60.0, 100.0)

func _sanitize_accessibility() -> void:
	accessibility["captions"] = bool(accessibility.get("captions", true))
	var sz := String(accessibility.get("subtitle_size", "Medium"))
	if not SUBTITLE_SCALES.has(sz):
		sz = "Extra Large" if bool(accessibility.get("large_text", false)) else "Medium"
	accessibility["subtitle_size"] = sz
	accessibility["subtitle_scale"] = float(SUBTITLE_SCALES[sz])
	accessibility["large_text"] = float(accessibility["subtitle_scale"]) >= 1.25
	accessibility["timer_free"] = bool(accessibility.get("timer_free", true))
	accessibility["reduced_motion"] = bool(accessibility.get("reduced_motion", false))
	var mode := String(accessibility.get("assist_mode", "Cadet"))
	if not mode in ASSIST_MODES:
		mode = "Cadet"
	accessibility["assist_mode"] = mode
	var smode := String(accessibility.get("session_mode", "Solo"))
	if not smode in SESSION_MODES:
		smode = "Solo"
	accessibility["session_mode"] = smode
	accessibility["family_mode"] = smode == "Family" or bool(accessibility.get("family_mode", false))
	accessibility["class_mode"] = smode == "Class" or bool(accessibility.get("class_mode", false))
