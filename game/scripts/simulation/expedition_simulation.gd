extends RefCounted
class_name ExpeditionSimulation

## Pure P-02 transition service.
## `preview` and `commit` both call the same calculation. `commit` only adds
## a receipt/revision to the returned copy; neither method mutates its input.

const SCHEMA_VERSION := 1
const PROFILE_PATH := "res://resources/campaign/profiles/chapter1_base.json"
const BASE_PROFILE_REVISION := "p02-base-v1"
const SHIFT_COUNT := 7
const SHIFT_HOURS := 7.2
const ResultScript = preload("res://scripts/core/command_result.gd")

const UPGRADE_IDS := {
	1: {"A": "taller_mast", "B": "fuel_cell"},
	2: {"A": "red_blue_leds", "B": "insulation_blankets"},
	3: {"A": "moon_dirt_shelter", "B": "flexible_seals"},
	4: {"A": "ice_harvester", "B": "rover_lights_heater"},
	5: {"A": "dust_shield", "B": "whipple_bumper"},
	6: {"A": "storm_early_warning", "B": "bigger_safe_room"},
	7: {"A": "relay_parts_kit", "B": "long_range_battery"},
}

func entry_profile(profile_id: String = "chapter1_base") -> Dictionary:
	var profile := _load_profile(profile_id)
	var resources: Dictionary = profile.get("resources", {}).duplicate(true)
	var capacities: Dictionary = profile.get("capacities", {}).duplicate(true)
	for key in capacities.keys():
		resources[key] = capacities[key]
	return {
		"schema_version": SCHEMA_VERSION,
		"profile_id": profile_id,
		"profile_revision": String(profile.get("profile_revision", BASE_PROFILE_REVISION)),
		"content_revision": String(profile.get("content_revision", "p02-numeric-contract")),
		"scenario_datetime": String(profile.get("scenario_datetime", "2046-04-25 00:00 UTC")),
		"current_shift": 0,
		"resources": resources,
		"upgrades": {"choices": {}, "acquisition_chapter": {}, "applied_profile_revision": String(profile.get("profile_revision", BASE_PROFILE_REVISION))},
		"status": "ready",
	}

func preview(snapshot: Dictionary, plan: Dictionary) -> Dictionary:
	return _transition(snapshot, "", int(snapshot.get("state_revision", 0)), plan, false)

func commit(snapshot: Dictionary, command_id: String, expected_revision: int, plan: Dictionary) -> Dictionary:
	var current_revision := int(snapshot.get("state_revision", 0))
	if command_id.is_empty():
		var missing: Dictionary = ResultScript.empty(current_revision, "planning")
		missing["reason"] = "A committed simulation step needs a command id."
		missing["snapshot"] = snapshot.duplicate(true)
		return missing
	var receipts: Dictionary = snapshot.get("receipts", {})
	if receipts.has(command_id):
		var duplicate: Dictionary = receipts[command_id].duplicate(true)
		duplicate["duplicate"] = true
		duplicate["snapshot"] = snapshot.duplicate(true)
		return duplicate
	if expected_revision != current_revision:
		var stale: Dictionary = ResultScript.empty(current_revision, "planning")
		stale["reason"] = "The simulation revision is stale; preview the current state before committing."
		stale["snapshot"] = snapshot.duplicate(true)
		return stale
	var result := _transition(snapshot, command_id, expected_revision, plan, true)
	if bool(result.get("accepted", false)):
		var next: Dictionary = result.get("snapshot", snapshot).duplicate(true)
		next["state_revision"] = current_revision + 1
		result["output_revision"] = current_revision + 1
		if plan.has("upgrades"):
			next["upgrades"] = _merge_upgrades(next.get("upgrades", {}), plan["upgrades"])
		if not next.has("receipts") or not next["receipts"] is Dictionary:
			next["receipts"] = {}
		result["receipt_id"] = "%s:%d" % [command_id, current_revision + 1]
		result["events"].append({"type": "simulation_committed", "state_revision": current_revision + 1})
		result["snapshot"] = next
		# The receipt must be complete before it is copied into the returned
		# snapshot. Otherwise a direct simulation replay loses receipt_id and
		# the original result fields even though the first commit succeeded.
		var stored_result := result.duplicate(true)
		# Duplicate replay reconstructs the caller's current snapshot; storing a
		# snapshot here would recursively contain the receipt map.
		stored_result.erase("snapshot")
		next["receipts"][command_id] = stored_result
	return result

func _transition(snapshot: Dictionary, command_id: String, expected_revision: int, plan: Dictionary, should_commit: bool) -> Dictionary:
	var current_revision := int(snapshot.get("state_revision", 0))
	var next_phase := String(snapshot.get("scene_phase", "planning"))
	var result: Dictionary = ResultScript.empty(current_revision, next_phase)
	result["snapshot"] = snapshot.duplicate(true)
	result["trace"] = []
	result["final_state"] = {}
	if not snapshot.has("resources"):
		result["reason"] = "A P-02 snapshot must contain primitive resources."
		return result
	var shifts := _extract_shifts(plan)
	if shifts.is_empty():
		result["reason"] = "A P-02 plan must provide one shift or a seven-shift array."
		return result
	var starting_shift := int(snapshot.get("current_shift", 0))
	if starting_shift < 0 or starting_shift >= SHIFT_COUNT:
		result["reason"] = "The current shift is outside the seven-shift contract."
		return result
	if starting_shift + shifts.size() > SHIFT_COUNT:
		result["reason"] = "A plan cannot commit beyond shift seven."
		return result

	var working: Dictionary = snapshot.duplicate(true)
	var resources: Dictionary = _normalise_resources(working.get("resources", {}))
	working["resources"] = resources
	var modifiers := _modifiers(working, plan)
	if bool(modifiers.get("fuel_cell", false)) and starting_shift == 0:
		resources["energy_capacity"] = int(modifiers["energy_capacity"])
		resources["E"] = mini(int(resources.get("E", 14)) + 4, int(resources["energy_capacity"]))
	resources["energy_capacity"] = int(modifiers["energy_capacity"])
	resources["crate_capacity"] = int(modifiers["crate_capacity"])

	var stopped := false
	var blackout_count := 0
	for offset in range(shifts.size()):
		var shift_number := starting_shift + offset + 1
		var raw_step = shifts[offset]
		if not raw_step is Dictionary:
			result["reason"] = "Each P-02 shift must be a primitive Dictionary."
			return result
		var step: Dictionary = raw_step.duplicate(true)
		if step.has("shift"):
			shift_number = int(step.get("shift", shift_number))
		if shift_number != starting_shift + offset + 1:
			result["reason"] = "P-02 shifts must be committed in order."
			return result
		var validated := _validate_step(step, shift_number)
		if not bool(validated.get("accepted", false)):
			result["reason"] = String(validated.get("reason", "Invalid P-02 settings."))
			return result
		var action := String(validated.get("action", ""))
		var heat := int(validated.get("heat", 2))
		var oxygen := int(validated.get("oxygen", 0))
		var light := int(validated.get("light", 0))
		var is_day := bool(validated.get("is_day", false))
		if action == "STACK":
			heat = 1
			oxygen = 0
			light = 0
		var before := resources.duplicate(true)
		var overflow := 0
		var water_before_alarm := int(resources.get("W", 0))
		var crate_before_alarm := int(resources.get("K", 0))
		var action_success := true
		var action_progress := 0

		# Shift seven clears the temporary crate rail before any remaining step.
		var crates_removed := false
		if shift_number == 7:
			resources["K"] = 0
			crates_removed = crate_before_alarm > 0

		# The alarm choice resolves before the economic update.
		if shift_number == 5:
			if action == "PUMP":
				action_progress = clampi(int(validated.get("pump_confirmations", 3)), 0, 3)
				var pump_amount := 2 if action_progress >= 3 else 1 if action_progress > 0 else 0
				var pump_target := mini(6, int(resources.get("W", 0)) + pump_amount)
				resources["W"] = pump_target
				action_success = action_progress >= 3
			elif action == "STACK":
				action_progress = clampi(int(validated.get("stack_slots", 4)), 0, 4)
				var stack_amount := 3 if bool(modifiers.get("bigger_safe_room", false)) and action_progress >= 4 else 2 if action_progress >= 4 else 1 if action_progress > 0 else 0
				resources["K"] = mini(int(modifiers["crate_capacity"]), stack_amount)
				action_success = action_progress >= 4
			else:
				action_progress = 0
		var pre_energy := int(resources.get("E", 0))
		var day_income := 8
		if is_day and bool(modifiers.get("taller_mast", false)):
			day_income += 2
		if is_day:
			var charged := mini(int(modifiers["energy_capacity"]), pre_energy + day_income)
			overflow = maxi(0, pre_energy + day_income - charged)
			resources["E"] = charged
		else:
			overflow = 0

		var pre_air := int(resources.get("A", 0))
		var air_with_production := mini(int(resources.get("air_capacity", 10)), pre_air + oxygen)
		resources["A"] = air_with_production

		var sheltered := bool(validated.get("sheltered", true))
		var shelter := 0
		if sheltered:
			shelter = mini(6, int(resources.get("W", 0)) + int(resources.get("K", 0)) + int(modifiers.get("shelter_bonus", 0)))
		var dose := 0
		if shift_number == 5 or shift_number == 6:
			dose = _dose_for_shelter(shelter)
			resources["Z"] = int(resources.get("Z", 0)) + dose

		# The ordinary water transfer follows exposure scoring. This ordering is
		# the key P-02 boundary: shift six drains only after its dose is known.
		if shift_number != 5:
			var transfer := String(validated.get("transfer", "HOLD"))
			if transfer == "FILL":
				resources["W"] = mini(6, int(resources.get("W", 0)) + 2)
			elif transfer == "DRAIN":
				resources["W"] = maxi(0, int(resources.get("W", 0)) - 2)

		var energy_cost := 1
		if not is_day:
			energy_cost += heat
		energy_cost += oxygen
		energy_cost += _light_cost(light, modifiers)
		var energy_after_spend := int(resources.get("E", 0)) - energy_cost
		var blackout := energy_after_spend < 0
		if blackout:
			blackout_count += 1
			resources["E"] = 0
			resources["A"] = int(resources.get("A", 0)) - 2
			resources["H"] = int(resources.get("H", 0)) - 2
			resources["C"] = int(resources.get("C", 0)) - 2
		else:
			resources["E"] = energy_after_spend

		# Breathing is after the cap and after the energy bus decision.
		resources["A"] = maxi(0, int(resources.get("A", 0)) - 1)

		# Plant effects use post-transfer W. Light affects both health and crop;
		# insulation blankets remove the declared COOL Alo cold damage. COLD
		# remains damaging, and COOL/COZY do not damage crop condition.
		var light_delta: int = [-1, 0, 1][light]
		var health_delta: int = light_delta
		var crop_delta: int = light_delta
		if not is_day:
			if heat == 0:
				health_delta -= 2
				crop_delta -= 1
			elif heat == 1 and not bool(modifiers.get("insulation_blankets", false)):
				health_delta -= 1
		if int(resources.get("W", 0)) >= 4:
			health_delta -= 1
			crop_delta -= 1
		resources["H"] = _apply_non_resurrecting(int(resources.get("H", 0)), health_delta, 10)
		resources["C"] = _apply_non_resurrecting(int(resources.get("C", 0)), crop_delta, 10)
		resources["R"] = _round_tenth(float(resources.get("R", 0.0)) - 1.2)

		var causes: Array = []
		if blackout:
			causes.append("blackout: demand exceeded available energy")
		if light_delta != 0:
			causes.append("light:%d" % light)
		if int(resources.get("W", 0)) >= 4:
			causes.append("thirst:post-transfer-water>=4")
		if not is_day and heat == 0:
			causes.append("cold")
		if not sheltered and (shift_number == 5 or shift_number == 6):
			causes.append("crew-not-sheltered")
		if dose > 0:
			causes.append("exposure-dose:%d" % dose)

		var trace_record := {
			"shift": shift_number,
			"before": before,
			"after": resources.duplicate(true),
			"overflow": overflow,
			"shelter": shelter,
			"dose": dose,
			"heat": heat,
			"air_production": oxygen,
			"light": light,
			"transfer": action if shift_number == 5 else String(validated.get("transfer", "HOLD")),
			"action": action,
			"action_progress": action_progress,
			"action_success": action_success,
			"blackout": blackout,
			"crates_removed": crates_removed,
			"causes": causes,
		}
		result["trace"].append(trace_record)
		if blackout:
			result["warnings"].append("Energy reached zero after a below-zero demand; the blackout penalty was applied.")
		if not sheltered and (shift_number == 5 or shift_number == 6):
			stopped = true
			result["unsafe_predicates"].append("crew_shelter_breach_shift_%d" % shift_number)
		if int(resources.get("A", 0)) <= 0:
			stopped = true
			result["unsafe_predicates"].append("air_depleted_shift_%d" % shift_number)
		if int(resources.get("H", 0)) <= 0:
			result["warnings"].append("Alo is terminal within this attempt; later care cannot resurrect the plant.")
		working["current_shift"] = shift_number
		if stopped:
			break

	working["resources"] = resources
	working["blackout_count"] = blackout_count
	working["status"] = "mission_stopped" if stopped else "active"
	var ending := ""
	if stopped:
		ending = "MISSION_STOPPED"
		result["next_phase"] = "retry_review"
	elif int(working.get("current_shift", 0)) >= SHIFT_COUNT:
		if int(resources.get("H", 0)) <= 0:
			ending = "ALO_LOST"
		elif int(resources.get("H", 0)) >= 5 and blackout_count == 0 and int(resources.get("Z", 0)) <= 3:
			ending = "GOLDEN"
		else:
			ending = "BLOOM"
		result["next_phase"] = "sunrise"
	else:
		result["next_phase"] = "planning"
	result["accepted"] = true
	result["reason"] = "Preview ready. Commit is explicit." if not should_commit else "P-02 transition committed once."
	result["deltas"] = _resource_deltas(snapshot.get("resources", {}), resources)
	result["events"] = [{"type": "simulation_preview" if not should_commit else "simulation_transition", "state_revision": current_revision}]
	result["ending"] = ending
	result["final_state"] = resources.duplicate(true)
	result["snapshot"] = working
	if not should_commit:
		result["warnings"].append("PREVIEW ONLY · no state, receipt, date, inventory or world side effects")
	return result

func _load_profile(profile_id: String) -> Dictionary:
	if profile_id == "chapter1_base" and FileAccess.file_exists(PROFILE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
		if parsed is Dictionary:
			return parsed as Dictionary
	return {
		"profile_revision": BASE_PROFILE_REVISION,
		"content_revision": "p02-numeric-contract",
		"scenario_datetime": "2046-04-25 00:00 UTC",
		"resources": {"E": 14, "A": 6, "H": 6, "W": 0, "K": 0, "C": 8, "R": 12.0, "Z": 0},
		"capacities": {"energy_capacity": 20, "air_capacity": 10, "health_capacity": 10, "water_capacity": 6, "crate_capacity": 2, "crop_capacity": 10},
	}

func _normalise_resources(source: Dictionary) -> Dictionary:
	var result := {
		"E": source.get("E", source.get("energy", 14)),
		"A": source.get("A", source.get("air", 6)),
		"H": source.get("H", source.get("alo_health", 6)),
		"W": source.get("W", source.get("water_shielding", 0)),
		"K": source.get("K", source.get("crate_shielding", 0)),
		"C": source.get("C", source.get("crop_condition", 8)),
		"R": source.get("R", source.get("rations", 12.0)),
		"Z": source.get("Z", source.get("exposure", 0)),
		"energy_capacity": source.get("energy_capacity", 20),
		"air_capacity": source.get("air_capacity", 10),
		"health_capacity": source.get("health_capacity", 10),
		"water_capacity": source.get("water_capacity", 6),
		"crate_capacity": source.get("crate_capacity", 2),
		"crop_capacity": source.get("crop_capacity", 10),
	}
	result["E"] = int(result["E"])
	result["A"] = int(result["A"])
	result["H"] = int(result["H"])
	result["W"] = int(result["W"])
	result["K"] = int(result["K"])
	result["C"] = int(result["C"])
	result["Z"] = int(result["Z"])
	result["R"] = float(result["R"])
	return result

func _extract_shifts(plan: Dictionary) -> Array:
	if plan.has("shifts") and plan["shifts"] is Array:
		return (plan["shifts"] as Array).duplicate(true)
	if plan.has("shift") and plan["shift"] is Dictionary:
		return [plan["shift"].duplicate(true)]
	if plan.has("step") and plan["step"] is Dictionary:
		return [plan["step"].duplicate(true)]
	return []

func _validate_step(step: Dictionary, shift_number: int) -> Dictionary:
	var result := {"accepted": false, "reason": "", "heat": 2, "oxygen": 0, "light": 0, "transfer": "HOLD", "action": "", "sheltered": true, "is_day": shift_number <= 2, "pump_confirmations": 3, "stack_slots": 4}
	if shift_number < 1 or shift_number > SHIFT_COUNT:
		result["reason"] = "Shift must be between one and seven."
		return result
	var raw_heat = step.get("heat", "DAY" if shift_number <= 2 else 2)
	var heat_result := _heat_value(raw_heat, shift_number)
	if not bool(heat_result.get("accepted", false)):
		result["reason"] = String(heat_result.get("reason", "Invalid heat setting."))
		return result
	result["heat"] = int(heat_result.get("value", 2))
	result["is_day"] = bool(heat_result.get("is_day", shift_number <= 2))
	var oxygen = int(step.get("air_production", step.get("oxygen", step.get("O", 0))))
	var light = _light_value(step.get("light", step.get("L", 0)))
	if oxygen < 0 or oxygen > 2:
		result["reason"] = "Air production O must be 0, 1 or 2."
		return result
	if light < 0:
		result["reason"] = "Garden light L must be OFF, DIM or FULL."
		return result
	result["oxygen"] = oxygen
	result["light"] = light
	result["sheltered"] = bool(step.get("sheltered", step.get("crew_sheltered", true)))
	var transfer := String(step.get("transfer", step.get("ordinary_transfer", "HOLD"))).to_upper()
	var action := String(step.get("alarm_action", transfer if shift_number == 5 else "")).to_upper()
	if shift_number == 5:
		if not ["PUMP", "STACK", "WAIT"].has(action):
			result["reason"] = "Shift five requires exactly one of PUMP, STACK or WAIT."
			return result
		result["action"] = action
		result["pump_confirmations"] = int(step.get("pump_confirmations", step.get("progress", 3)))
		result["stack_slots"] = int(step.get("stack_slots", step.get("bundles_placed", step.get("progress", 4))))
	else:
		if not ["FILL", "HOLD", "DRAIN"].has(transfer):
			result["reason"] = "PUMP, STACK and WAIT are exclusive to shift five."
			return result
		result["transfer"] = transfer
		if step.has("alarm_action"):
			result["reason"] = "An alarm action is only valid at shift five."
			return result
	result["accepted"] = true
	return result

func _heat_value(value, shift_number: int) -> Dictionary:
	if shift_number <= 2:
		return {"accepted": true, "value": 2, "is_day": true}
	if value is String:
		var text := String(value).to_upper()
		if text == "DAY":
			return {"accepted": false, "reason": "DAY heat is only valid in shifts one and two."}
		if text == "COLD":
			return {"accepted": true, "value": 0, "is_day": false}
		if text == "COOL":
			return {"accepted": true, "value": 1, "is_day": false}
		if text == "COZY":
			return {"accepted": true, "value": 2, "is_day": false}
		return {"accepted": false, "reason": "Night heat must be COLD, COOL or COZY."}
	var number := int(value)
	if number < 0 or number > 2:
		return {"accepted": false, "reason": "Night heat must be 0, 1 or 2."}
	return {"accepted": true, "value": number, "is_day": false}

func _light_value(value) -> int:
	if value is String:
		match String(value).to_upper():
			"OFF": return 0
			"DIM": return 1
			"FULL": return 2
			_: return -1
	return int(value) if int(value) >= 0 and int(value) <= 2 else -1

func _dose_for_shelter(shelter: int) -> int:
	if shelter >= 6:
		return 0
	if shelter >= 4:
		return 1
	if shelter >= 2:
		return 2
	return 3

func _light_cost(light: int, modifiers: Dictionary) -> int:
	if light == 2 and bool(modifiers.get("red_blue_leds", false)):
		return 1
	return light

func _apply_non_resurrecting(value: int, delta: int, cap: int) -> int:
	if value <= 0:
		return 0
	return clampi(value + delta, 0, cap)

func _resource_deltas(before_source: Dictionary, after: Dictionary) -> Array:
	var before := _normalise_resources(before_source)
	var deltas: Array = []
	for key in ["E", "A", "H", "W", "K", "C", "R", "Z"]:
		var old_value = before.get(key, 0)
		var new_value = after.get(key, 0)
		if old_value != new_value:
			deltas.append({"resource": key, "from": old_value, "to": new_value, "delta": new_value - old_value})
	return deltas

func _round_tenth(value: float) -> float:
	return float(round(value * 10.0) / 10.0)

func _modifiers(snapshot: Dictionary, plan: Dictionary) -> Dictionary:
	var choices := _upgrade_choices(_merge_upgrades(snapshot.get("upgrades", {}), plan.get("upgrades", {})))
	var modifiers := {
		"taller_mast": false,
		"fuel_cell": false,
		"red_blue_leds": false,
		"insulation_blankets": false,
		"moon_dirt_shelter": false,
		"flexible_seals": false,
		"ice_harvester": false,
		"rover_lights_heater": false,
		"dust_shield": false,
		"whipple_bumper": false,
		"storm_early_warning": false,
		"bigger_safe_room": false,
		"relay_parts_kit": false,
		"long_range_battery": false,
		"energy_capacity": 20,
		"crate_capacity": 2,
		"shelter_bonus": 0,
	}
	for chapter in range(1, 8):
		var choice := String(choices.get(str(chapter), choices.get(chapter, "")))
		if choice.is_empty():
			continue
		if modifiers.has(choice):
			modifiers[choice] = true
	if bool(modifiers["fuel_cell"]):
		modifiers["energy_capacity"] = 26
	if bool(modifiers["moon_dirt_shelter"]):
		modifiers["shelter_bonus"] = 1
	if bool(modifiers["bigger_safe_room"]):
		modifiers["crate_capacity"] = 3
	return modifiers

func _merge_upgrades(existing_raw, incoming_raw) -> Dictionary:
	var merged: Dictionary = existing_raw.duplicate(true) if existing_raw is Dictionary else {}
	var choices: Dictionary = {}
	var acquisition: Dictionary = {}
	if merged.get("choices", null) is Dictionary:
		choices = merged["choices"].duplicate(true)
	if merged.get("acquisition_chapter", null) is Dictionary:
		acquisition = merged["acquisition_chapter"].duplicate(true)

	# Keep legacy snapshots usable when only one of the two persistent maps was
	# written. Existing insertion order is retained; missing companion entries
	# are appended in that same order.
	for key in acquisition.keys():
		if not choices.has(key):
			choices[key] = acquisition[key]
	for key in choices.keys():
		if not acquisition.has(key):
			acquisition[key] = choices[key]

	if incoming_raw is Array:
		var array_incoming := {"choices": {}}
		for item in incoming_raw:
			var stable_id := String(item)
			for chapter in UPGRADE_IDS.keys():
				if UPGRADE_IDS[chapter].values().has(stable_id):
					array_incoming["choices"][str(chapter)] = stable_id
			incoming_raw = array_incoming
	if incoming_raw is Dictionary:
		var incoming: Dictionary = incoming_raw
		var incoming_acquisition: Dictionary = {}
		var incoming_choices: Dictionary = {}
		if incoming.get("acquisition_chapter", null) is Dictionary:
			incoming_acquisition = incoming["acquisition_chapter"]
		if incoming.get("choices", null) is Dictionary:
			incoming_choices = incoming["choices"]
		elif incoming_acquisition.is_empty():
			# Accept a compact {chapter: choice} plan as a persistent partial plan.
			for key in incoming.keys():
				if key not in ["applied_profile_revision", "profile_revision", "schema_version"]:
					incoming_choices[key] = incoming[key]

		# An explicit acquisition map defines order. New choices without one are
		# appended below in the order supplied by the plan.
		for key in incoming_acquisition.keys():
			if not acquisition.has(key):
				acquisition[key] = incoming_acquisition[key]
			if not choices.has(key):
				choices[key] = incoming_acquisition[key]
		for key in incoming_choices.keys():
			if not choices.has(key):
				choices[key] = incoming_choices[key]
			if not acquisition.has(key):
				acquisition[key] = choices[key]
		for key in incoming.keys():
			if key in ["choices", "acquisition_chapter"]:
				continue
			if not merged.has(key) or String(merged.get(key, "")).is_empty():
				merged[key] = incoming[key]

	merged["choices"] = choices
	merged["acquisition_chapter"] = acquisition
	return merged

func _upgrade_choices(raw) -> Dictionary:
	var result := {}
	if raw is Array:
		for item in raw:
			var id := String(item)
			for chapter in UPGRADE_IDS.keys():
				if UPGRADE_IDS[chapter].values().has(id):
					result[str(chapter)] = id
		return result
	if not raw is Dictionary:
		return result
	var source: Dictionary = raw
	if source.has("choices") and source["choices"] is Dictionary:
		source = source["choices"]
	elif source.has("acquisition_chapter") and source["acquisition_chapter"] is Dictionary:
		source = source["acquisition_chapter"]
	for chapter in range(1, 8):
		var key_options := [str(chapter), chapter, "chapter_%d" % chapter, "CH%02d" % chapter]
		for key in key_options:
			if source.has(key):
				var raw_choice := String(source[key])
				var upper := raw_choice.to_upper()
				if upper == "A" or upper == "B":
					result[str(chapter)] = UPGRADE_IDS[chapter][upper]
				else:
					result[str(chapter)] = raw_choice
				break
	return result
