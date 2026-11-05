extends RefCounted
class_name PayloadStackTask

## Physical STACK adapter; P02MissionTable remains the sole progress ledger
## and ExpeditionSimulation remains the sole authority on shelter rewards.
const Inventory = preload("res://scripts/payload/payload_inventory.gd")
var inventory := Inventory.new()
var table: P02MissionTable
var slots: Dictionary = {}
var time_left := 0.0
var assisted := false
var running := false

func _init(mission_table: P02MissionTable) -> void:
	table = mission_table
	for index in int(table.data().alarm_tasks.STACK.steps):
		var definition: Dictionary = Inventory.rules().stack.bundle.duplicate(true)
		definition.id = "bundle_%d" % index
		definition.label = "%s %d" % [definition.label, index + 1]
		inventory.register_payload(definition)

## True when the accessibility settings remove the clock: the existing
## `timer_free` setting (what Family Mode sets) or a doc 25 assist `mode`
## listed in payload_rules.json (family, story, class).
static func is_untimed(settings: Dictionary) -> bool:
	var modes: Array = Inventory.rules().stack.get("untimed_modes", [])
	return bool(settings.get("timer_free", false)) or String(settings.get("mode", "")).to_lower() in modes

## Starts after the player chooses assistance. Assisted input and the untimed
## settings (`is_untimed`) always remove time pressure; the result is unchanged.
func start(use_assistance: bool, settings: Dictionary = {}) -> Dictionary:
	if running:
		return {"accepted": false, "reason": "The supply task is already running."}
	if String(table.alarm_state().action) != "STACK":
		return {"accepted": false, "reason": "Choose the supply response first."}
	assisted = use_assistance or is_untimed(settings)
	var result := table.start_alarm_task(assisted)
	if bool(result.accepted):
		time_left = float(result.timer_seconds)
		running = true
	return result

## Picks up a single physical bundle, refusing full hands before changing it.
func pickup(index: int) -> Dictionary:
	if not running:
		return {"accepted": false, "reason": "Start carrying supplies first."}
	return inventory.pickup("bundle_%d" % index)

## Delivers the carried bundle to one empty outlined slot, then records the
## placement once in the shared shift ledger. A bare slot click has no effect.
func place(slot: int) -> Dictionary:
	if not running or slot < 0 or slot >= table.alarm_task_steps():
		return {"accepted": false, "reason": "Choose an outlined bunk slot during the task."}
	if slots.has(slot):
		return {"accepted": false, "reason": "That bunk slot already holds a bundle."}
	var held: Array = inventory.load_view("hands").ids
	if held.is_empty():
		return {"accepted": false, "reason": "Pick up a supply bundle first."}
	var result := inventory.deliver(String(held[0]), "bunk")
	if not bool(result.accepted):
		return result
	slots[slot] = held[0]
	result = table.task_step(slot)
	if String(table.alarm_state().state) == table.TASK_RESOLVED:
		running = false
	return result

## Advances only active play time. Briefing and pause cards never consume it.
func advance(seconds: float) -> void:
	if not running or assisted or not is_finite(seconds) or seconds <= 0.0:
		return
	time_left = maxf(0.0, time_left - seconds)
	if time_left == 0.0:
		finish()

## Ends with exactly the placed bundles; carrying a bundle gives no credit.
func finish() -> Dictionary:
	running = false
	time_left = 0.0
	return table.resolve_alarm_task()

## The CH01 S10 to S11 join (doc 24 section 2.9) for the report card. STACK
## never moves garden water, so the "borrowed water" line is only true when
## the wall holds some (`water_units` = W); otherwise 08 needs no drain and
## the line points at the remaining dark shifts instead.
static func bridge_line(water_units: int) -> String:
	var layout: Dictionary = Inventory.rules().stack
	return String(layout.bridge_water) if water_units > 0 else String(layout.bridge_dry)
