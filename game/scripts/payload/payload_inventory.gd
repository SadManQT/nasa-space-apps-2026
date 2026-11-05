extends RefCounted
class_name PayloadInventory

## Payload ownership and handling ledger. Presentation calls the same preflight
## used by pickup; refusal never moves an item. No base resource is spent here.
const RULES_PATH := "res://scripts/payload/payload_rules.json"
const PERSONAL := ["hands", "back"]
const HANDLING := ["fragile", "sealed", "keep_cold"]
static var _rules: Dictionary = {}
var _items: Dictionary = {}
var _chapter: int
var _hooks: Array

func _init(chapter: int = 1, attached_hooks: Array = []) -> void:
	_chapter = chapter
	_hooks = attached_hooks.duplicate()

## Returns data-owned capacities and the Chapter 1 activity layout.
static func rules() -> Dictionary:
	if _rules.is_empty():
		_rules = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH)) as Dictionary
	return _rules

## Registers a unique payload definition; all dimensions/handling are explicit.
func register_payload(definition: Dictionary) -> Dictionary:
	for key in ["id", "label", "size", "destination"]:
		if not definition.get(key) is String or String(definition[key]).strip_edges().is_empty():
			return _reject("Payload needs a readable " + key + ".")
	var id := String(definition.id)
	if _items.has(id):
		return _reject("That payload is already registered.")
	if not _number(definition.get("mass_kg")) or float(definition.mass_kg) <= 0.0:
		return _reject("Payload mass must be positive.")
	if not definition.size in ["small", "medium", "large"] or not definition.get("handling") is Array:
		return _reject("Payload size or handling needs are missing.")
	for need in definition.handling:
		if not need in HANDLING:
			return _reject("Unknown payload handling need.")
	if definition.handling.has("keep_cold") and not _number(definition.get("max_temperature_c")):
		return _reject("A cold payload needs a temperature limit.")
	var temperature := float(definition.get("max_temperature_c", 20.0))
	_items[id] = {"definition": definition.duplicate(true), "place": "ground", "condition": {"intact": true, "seal_intact": true, "temperature_c": temperature, "cold_chain_ok": true}}
	return _accept("%s ready for pickup." % definition.label)

## Read-only preflight, including count, size, weight and unlocked equipment.
func can_pickup(id: String, place: String = "hands") -> Dictionary:
	if not _items.has(id):
		return _reject("That payload is unavailable.")
	if _items[id].place != "ground":
		return _reject("That payload is already carried or delivered.")
	var places: Dictionary = rules().places
	if not places.has(place):
		return _reject("Choose a carry place.")
	var limit: Dictionary = places[place]
	if _chapter < int(limit.chapter) or (place in ["sled", "trailer"] and not _hooks.has(place)):
		return _reject("%s needs its attached hook from chapter %d." % [limit.label, int(limit.chapter)])
	var definition: Dictionary = _items[id].definition
	if not limit.sizes.has(definition.size):
		return _reject("%s accepts %s payloads only." % [limit.label, ", ".join(limit.sizes)])
	var load := load_view(place)
	if int(load.count) >= int(limit.slots):
		return _reject("%s full: %d of %d. Place a payload first." % [limit.label, int(load.count), int(limit.slots)])
	if float(load.mass_kg) + float(definition.mass_kg) > float(limit.mass_kg):
		return _reject("%s limit is %s kg; this load would weigh %s kg." % [limit.label, String.num(float(limit.mass_kg), 1), String.num(float(load.mass_kg) + float(definition.mass_kg), 1)])
	if place in PERSONAL and personal_mass() + float(definition.mass_kg) > float(rules().personal_mass_kg):
		return _reject("Carry limit is %s kg; place some of your load first." % String.num(float(rules().personal_mass_kg), 1))
	return _accept("Pick up %s · %s kg." % [definition.label, String.num(float(definition.mass_kg), 1)])

## Moves an eligible payload into one carry place, atomically after preflight.
func pickup(id: String, place: String = "hands") -> Dictionary:
	var result := can_pickup(id, place)
	if bool(result.accepted):
		_items[id].place = place
	return result

## Sets a carried payload down safely; its condition and destination persist.
func set_down(id: String) -> Dictionary:
	if not _items.has(id) or not rules().places.has(_items[id].place):
		return _reject("Carry the payload before setting it down.")
	_items[id].place = "ground"
	return _accept("Payload set down safely.")

## Records handling readings. Damage and a cold-chain excursion cannot be
## undone by cooling again or submitting a later healthy reading.
func update_condition(id: String, reading: Dictionary) -> Dictionary:
	if not _items.has(id) or _items[id].place == "delivered":
		return _reject("That payload cannot be inspected here.")
	for key in reading:
		if key in ["intact", "seal_intact"]:
			if not reading[key] is bool:
				return _reject("Handling checks must be true or false.")
		elif key != "temperature_c" or not _number(reading[key]):
			return _reject("Unknown or invalid handling reading.")
	var condition: Dictionary = _items[id].condition
	for key in ["intact", "seal_intact"]:
		condition[key] = bool(condition[key]) and bool(reading.get(key, true))
	if reading.has("temperature_c"):
		condition.temperature_c = float(reading.temperature_c)
	var definition: Dictionary = _items[id].definition
	if definition.handling.has("keep_cold") and float(condition.temperature_c) > float(definition.max_temperature_c):
		condition.cold_chain_ok = false
	return _accept("Payload condition checked.")

## Checks the marked destination and handling before accepting delivery.
## A rejected delivery keeps the payload in its carry place for recovery.
func deliver(id: String, destination: String) -> Dictionary:
	if not _items.has(id):
		return _reject("That payload is unavailable.")
	var item: Dictionary = _items[id]
	if item.place == "delivered":
		return _reject("That payload has already been delivered.")
	if not rules().places.has(item.place):
		return _reject("Pick up the payload before delivery.")
	if String(item.definition.destination) != destination:
		return _reject("Deliver %s to %s." % [item.definition.label, item.definition.destination])
	for need in item.definition.handling:
		if need == "fragile" and not bool(item.condition.intact):
			return _reject("Fragile payload damaged: set it down for inspection.")
		if need == "sealed" and not bool(item.condition.seal_intact):
			return _reject("Seal broken: set it down for inspection.")
		if need == "keep_cold" and not bool(item.condition.cold_chain_ok):
			return _reject("Cold limit exceeded: set it down for inspection.")
	item.place = "delivered"
	return _accept("%s delivered · condition checked." % item.definition.label)

## Returns a detached item record so presentation cannot mutate ownership.
func item(id: String) -> Dictionary:
	return _items.get(id, {}).duplicate(true)

## Count, mass and limits for one carry place, suitable for a visor readout.
func load_view(place: String) -> Dictionary:
	var ids: Array = []
	var mass := 0.0
	for id in _items:
		if _items[id].place == place:
			ids.append(id)
			mass += float(_items[id].definition.mass_kg)
	var limit: Dictionary = rules().places.get(place, {})
	return {"ids": ids, "count": ids.size(), "mass_kg": mass, "slots": int(limit.get("slots", 0)), "limit_kg": float(limit.get("mass_kg", 0.0))}

## Combined mass on the cadet; towed loads have their own equipment limit.
func personal_mass() -> float:
	return float(load_view("hands").mass_kg) + float(load_view("back").mass_kg)

static func _number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _accept(reason: String) -> Dictionary:
	return {"accepted": true, "reason": reason}

static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
