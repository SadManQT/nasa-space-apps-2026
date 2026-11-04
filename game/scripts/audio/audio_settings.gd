## Player volume settings: one linear 0..1 value per bus, saved per machine in
## user://audio_settings.cfg (not in the expedition save; volume is not progress).
class_name AudioSettings

const BUSES := ["Master", "Voice", "Music", "SFX", "UI"]
const LABELS := {"Master": "Master volume", "Voice": "Dialogue volume", "Music": "Music volume", "SFX": "Effects volume", "UI": "Interface volume"}
static var path := "user://audio_settings.cfg"
static var _loaded := false
static var _values := {}

## Linear volume 0..1 for a bus (default 1).
static func volume(bus: String) -> float:
	_load()
	return float(_values.get(bus, 1.0))

## Sets, applies and saves one bus volume.
static func set_volume(bus: String, value: float) -> void:
	_load()
	_values[bus] = clampf(value, 0.0, 1.0)
	_apply(bus)
	var config := ConfigFile.new()
	for name in _values:
		config.set_value("volume", name, _values[name])
	config.save(path)

## Applies every saved volume to the AudioServer buses.
static func apply_all() -> void:
	_load()
	for bus in BUSES:
		_apply(bus)

## Forgets the cached values so the next read comes from `path` again (tests).
static func forget_cache() -> void:
	_loaded = false
	_values = {}

static func _apply(bus: String) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var value := volume(bus)
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for bus in BUSES:
		if config.has_section_key("volume", bus):
			_values[bus] = clampf(float(config.get_value("volume", bus)), 0.0, 1.0)
