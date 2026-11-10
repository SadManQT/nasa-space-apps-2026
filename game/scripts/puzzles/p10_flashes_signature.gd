extends RefCounted
class_name P10FlashesSignature

## P-10 — Flashes and a Signature (game-design/08 §P-10, 22 §7.3-7.4).
## Pure rule model: the player compares ten candidates across frames, marks
## the genuine flashes, rejects the two fixed detector artifacts, runs the
## two repairs and the pressure test, files the report with its honest
## blank, then matches N.R. to Dr. Noor Rahman on the signed manifest and
## sends one invitation. The answers live in
## game/resources/campaign/content/p10_flashes_signature.json; the resource
## witness comes from game/resources/campaign/profiles/p10_campaign.json.
## Mistags can be corrected; a hint never changes an ending. Golden: all
## eight genuine flashes with no false report.

const DataScript = preload("res://scripts/puzzles/puzzle_data.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")

var _tags := {}
var _flashes_verified := false
var _cleaned := false
var _shield_verified := false
var _patched := false
var _bumper_verified := false
var _pressure_verified := false
var _phases_done := 0
var _resources := {}
var _report_filed := false
var _identity_matched := false
var _consent_recorded := false
var _founder_confirmed := false
var _invitation := ""
var _committed := false
var _done: Array = []

static func data() -> Dictionary:
	return DataScript.data("P-10")

## The p10 campaign profile, validated the way P-03 validates its profile.
## Returns {} (and reports why) when the profile is missing or malformed.
static func profile() -> Dictionary:
	var rules: Dictionary = SimulationScript.load_profile("p10_campaign")
	if rules.is_empty():
		return {}
	var resources = rules.get("resources", null)
	var capacities = rules.get("capacities", null)
	var problem := ""
	if not resources is Dictionary or not capacities is Dictionary:
		problem = "resources and capacities are required"
	elif int(rules.get("phases", 0)) != 3:
		problem = "three observation/maintenance phases are required"
	else:
		for key in ["daylight_energy", "dust_energy", "basic_energy", "heat", "light", "breathing_air", "food_consumption", "unresolved_leak_air"]:
			if not SimulationScript.is_amount(rules.get(key, null)):
				problem = key + " must be a finite nonnegative number"
		for key in ["E", "A", "H", "C", "R"]:
			if not SimulationScript.is_amount(resources.get(key, null)):
				problem = "resources." + key + " must be a finite nonnegative number"
	if not problem.is_empty():
		push_error("P-10 profile is invalid: " + problem)
		return {}
	return rules

static func candidate_ids() -> Array:
	var result: Array = []
	for candidate in data().get("candidates", []):
		result.append(String(candidate.get("id", "")))
	return result

static func genuine_ids() -> Array:
	var result: Array = []
	for candidate in data().get("candidates", []):
		if bool(candidate.get("genuine", false)):
			result.append(String(candidate.get("id", "")))
	return result

static func artifact_ids() -> Array:
	var result: Array = []
	for candidate in data().get("candidates", []):
		if not bool(candidate.get("genuine", true)):
			result.append(String(candidate.get("id", "")))
	return result

func _init() -> void:
	var entry: Dictionary = profile().get("resources", {})
	_resources = {"E": float(entry.get("E", 14)), "A": float(entry.get("A", 8)), "H": float(entry.get("H", 6)), "C": float(entry.get("C", 8)), "R": float(entry.get("R", 18)), "Z": 0.0}

## Tag one candidate "flash" or "artifact"; "clear" removes the tag.
## Mistags stay correctable and are explained at once.
func tag_candidate(candidate_id: String, tag: String) -> Dictionary:
	if _committed:
		return _reject("The observation is already committed.")
	if not candidate_ids().has(candidate_id):
		return _reject("That candidate is not on the monitor.")
	if tag == "clear":
		_tags.erase(candidate_id)
		return _accept("Cleared the tag on %s." % candidate_id)
	if tag != "flash" and tag != "artifact":
		return _reject("Tag a candidate Flash or Artifact.")
	var candidate := _candidate(candidate_id)
	var genuine := bool(candidate.get("genuine", false))
	_tags[candidate_id] = tag
	if tag == "flash" and not genuine:
		return {"accepted": true, "duplicate": false, "reason": "Tagged as a flash, but this point stays on the same detector pixel in every frame. That is the camera, not the Moon.", "warning": true}
	if tag == "artifact" and genuine:
		return {"accepted": true, "duplicate": false, "reason": "Tagged as an artifact, but a real flash changes between frames. This one appears briefly and then is gone.", "warning": true}
	return _accept("Tagged %s as %s." % [candidate_id, tag])

## Counts against the board: verified genuine, rejected artifacts, false reports.
func counts() -> Dictionary:
	var genuine := 0
	var artifacts := 0
	var false_reports := 0
	for id in _tags.keys():
		var tag := String(_tags[id])
		if tag == "flash":
			if genuine_ids().has(id):
				genuine += 1
			else:
				false_reports += 1
		elif tag == "artifact":
			if artifact_ids().has(id):
				artifacts += 1
			else:
				false_reports += 1
	return {"genuine": genuine, "artifacts_rejected": artifacts, "false_reports": false_reports}

func golden() -> bool:
	var c := counts()
	return int(c.get("genuine", 0)) == 8 and int(c.get("false_reports", 0)) == 0

## The same rule function preview and commit share: at least six genuine,
## both artifacts rejected, no false report. Pure: it never changes state.
func _check_flashes(payload: Dictionary = {}) -> Dictionary:
	var c := counts()
	var genuine := int(payload.get("genuine", c.get("genuine", 0)))
	var artifacts := int(payload.get("artifacts_rejected", c.get("artifacts_rejected", 0)))
	if genuine != int(c.get("genuine", 0)) or artifacts != int(c.get("artifacts_rejected", 0)):
		return _reject("The counts disagree with the board. Tag the candidates first, then verify.")
	if int(c.get("false_reports", 0)) > 0:
		return _reject("A false report is on the board. Compare the frame before and after and correct the mistag.")
	if genuine < 6:
		return _reject("Six verified flashes satisfy the mission. %d are verified so far." % genuine)
	if artifacts != 2:
		return _reject("Both persistent artifacts must be rejected. %d are rejected so far." % artifacts)
	if genuine == 8:
		return _accept("All eight flashes verified with no false report: Golden observation.")
	return _accept("Six genuine flashes verified and both artifacts rejected.")

func verify_flashes(payload: Dictionary = {}) -> Dictionary:
	var check := _check_flashes(payload)
	if not bool(check.get("accepted", false)):
		return check
	_flashes_verified = true
	return check

func clean_panel() -> Dictionary:
	if _cleaned:
		return {"accepted": true, "duplicate": true, "reason": "The panel is already clean."}
	_cleaned = true
	return _accept("Panel cleaned. Solar income returns to 8.")

func verify_dust_shield() -> Dictionary:
	if _shield_verified:
		return {"accepted": true, "duplicate": true, "reason": "The Dust Shield is already verified."}
	_shield_verified = true
	return _accept("Dust Shield verified. It prevents the dust event and supplies this verification task instead.")

func patch_dome_spur() -> Dictionary:
	if _patched:
		return {"accepted": true, "duplicate": true, "reason": "The dome spur is already patched."}
	_patched = true
	return _accept("Dome spur patched from its safe side. The living enclosure was never opened.")

func verify_whipple_bumper() -> Dictionary:
	if _bumper_verified:
		return {"accepted": true, "duplicate": true, "reason": "The Whipple bumper is already verified."}
	_bumper_verified = true
	return _accept("Whipple bumper verified. It prevents the leak event and supplies this verification task instead.")

func maintenance_passed() -> bool:
	return (_cleaned or _shield_verified) and (_patched or _bumper_verified)

func verify_pressure() -> Dictionary:
	if _pressure_verified:
		return {"accepted": true, "duplicate": true, "reason": "Pressure is already verified."}
	if not maintenance_passed():
		return _reject(String(data().get("feedback", {}).get("pressure_first", "Clean and patch before the pressure test.")))
	_pressure_verified = true
	return _accept("Pressure verified after the clean and the patch.")

## One observation/maintenance phase at COZY heat, DIM light, O0, from the
## p10 profile. The unmodified baseline witness; owned upgrades apply once
## in the campaign simulation and are not re-charged here.
func sample_phase() -> Dictionary:
	if _phases_done >= 3:
		return {"accepted": true, "duplicate": true, "reason": "All three phases are already sampled."}
	if not maintenance_passed():
		return _reject(String(data().get("feedback", {}).get("pressure_first", "Clean and patch before the observation sample.")))
	var rules := profile()
	if rules.is_empty():
		return _reject("The P-10 profile is unavailable.")
	var income := float(rules.get("daylight_energy", 8)) if (_cleaned or _shield_verified) else float(rules.get("dust_energy", 6))
	var cap := float((rules.get("capacities", {}) as Dictionary).get("energy_capacity", 20))
	_resources["E"] = minf(cap, float(_resources["E"]) + income) - float(rules.get("basic_energy", 1)) - float(rules.get("heat", 2)) - float(rules.get("light", 1))
	_resources["A"] = float(_resources["A"]) - float(rules.get("breathing_air", 1.25)) - (0.0 if (_patched or _bumper_verified) else float(rules.get("unresolved_leak_air", 1)))
	_resources["R"] = float(_resources["R"]) - float(rules.get("food_consumption", 1.5))
	_phases_done += 1
	return _accept("Phase %d sampled: E %s, A %s, R %s." % [_phases_done, _resources["E"], _resources["A"], _resources["R"]])

## The three-phase forecast, with immediate maintenance or one phase late.
func forecast(delayed_maintenance: bool = false) -> Dictionary:
	var rules := profile()
	if rules.is_empty():
		return {}
	var entry: Dictionary = rules.get("resources", {})
	var cap := float((rules.get("capacities", {}) as Dictionary).get("energy_capacity", 20))
	var state := {"E": float(entry.get("E", 14)), "A": float(entry.get("A", 8)), "H": float(entry.get("H", 6)), "C": float(entry.get("C", 8)), "R": float(entry.get("R", 18)), "Z": 0.0}
	for phase in 3:
		var cleaned := not delayed_maintenance or phase > 0
		var income := float(rules.get("daylight_energy", 8)) if cleaned else float(rules.get("dust_energy", 6))
		state["E"] = minf(cap, float(state["E"]) + income) - float(rules.get("basic_energy", 1)) - float(rules.get("heat", 2)) - float(rules.get("light", 1))
		state["A"] = float(state["A"]) - float(rules.get("breathing_air", 1.25)) - (0.0 if cleaned else float(rules.get("unresolved_leak_air", 1)))
		state["R"] = float(state["R"]) - float(rules.get("food_consumption", 1.5))
	return state

func file_report(claim: String, column: String) -> Dictionary:
	if claim == "impact_2034_fault" and column == "unsupported":
		_report_filed = true
		return _accept("Filed under Unsupported. Tonight's flashes do not date the old fault.")
	if claim == "impact_2034_fault":
		return _reject("A hazard that exists is not proof it caused this fault. The damage report records no verified strike.")
	return _reject("That claim is not on the evidence table.")

func evidence_passed() -> bool:
	return _flashes_verified and maintenance_passed()

func match_identity(value: String) -> Dictionary:
	if _identity_matched:
		return {"accepted": true, "duplicate": true, "reason": "The identity is already matched."}
	if not evidence_passed():
		return _reject(String(data().get("feedback", {}).get("evidence_first", "Verify the flashes and pass maintenance first.")))
	if not _report_filed:
		return _reject(String(data().get("feedback", {}).get("report_first", "File the report before matching the identity.")))
	if value != String(data().get("expected", {}).get("identity", "")):
		if value == "NOOR_BY_NATIONALITY":
			return _reject(String(data().get("feedback", {}).get("identity_not_from_nationality", "The connection comes from the signed record, not nationality.")))
		return _reject("The signed manifest does not name that person.")
	_identity_matched = true
	return _accept("Dr. Noor Rahman, from the signed page, with permission to share it.")

func record_consent() -> Dictionary:
	if not _identity_matched:
		return _reject("Match the signed identity before recording consent.")
	if _consent_recorded:
		return {"accepted": true, "duplicate": true, "reason": "Consent is already recorded."}
	_consent_recorded = true
	return _accept("Consent recorded: she gave permission to share the page.")

func confirm_founder_role() -> Dictionary:
	if not _identity_matched:
		return _reject("Match the signed identity before confirming the founder role.")
	if _founder_confirmed:
		return {"accepted": true, "duplicate": true, "reason": "The founder role is already confirmed."}
	_founder_confirmed = true
	return _accept("Founder role confirmed from the signed record. Noor is alive and the Academy's founder.")

func send_invitation(option: String) -> Dictionary:
	if _invitation != "":
		return {"accepted": true, "duplicate": true, "reason": "An invitation is already sent once."}
	if not _identity_matched or not _consent_recorded or not _founder_confirmed:
		return _reject(String(data().get("feedback", {}).get("invitation_first", "Match the identity and record consent first.")))
	var valid := false
	for item in data().get("choices", {}).get("invitation", {}).get("options", []):
		if String(item.get("value", "")) == option and bool(item.get("correct", false)):
			valid = true
	if not valid:
		return _reject("Choose one of the three authored invitations.")
	_invitation = option
	return _accept("Invitation sent once, with its receipt kept. A delivery receipt confirms transport; it is not a reply.")

func hint(tier: int) -> String:
	var hints: Array = data().get("hints", {}).get("observation", [])
	if tier < 1 or tier > hints.size():
		return ""
	return String(hints[tier - 1])

## Clear only the candidate tags (free re-tagging); everything else stays.
func clear_tags() -> Dictionary:
	if _committed:
		return _reject("A committed observation cannot be undone here.")
	_tags = {}
	return _accept("Tags cleared. The candidates stay on the monitor.")

## Return the working board to its fresh state. A committed observation
## cannot be undone here; the route's checkpoint retry is the way back.
func reset() -> Dictionary:
	if _committed:
		return _reject("A committed observation cannot be undone here.")
	_tags = {}
	_flashes_verified = false
	_cleaned = false
	_shield_verified = false
	_patched = false
	_bumper_verified = false
	_pressure_verified = false
	_phases_done = 0
	var entry: Dictionary = profile().get("resources", {})
	_resources = {"E": float(entry.get("E", 14)), "A": float(entry.get("A", 8)), "H": float(entry.get("H", 6)), "C": float(entry.get("C", 8)), "R": float(entry.get("R", 18)), "Z": 0.0}
	_report_filed = false
	_identity_matched = false
	_consent_recorded = false
	_founder_confirmed = false
	_invitation = ""
	_done = []
	return _accept("Choices cleared. The evidence has not changed.")

func preview_action(action: String, payload: Dictionary = {}) -> Dictionary:
	if _done.has(action):
		return {"accepted": true, "duplicate": true, "reason": "P-10 action already has a receipt."}
	match action:
		"p10_document_young_trial", "p10_exclude_flower_claim", "p10_save_source_scope":
			return _accept("The young trial is documented as seedlings only.")
		"p10_acknowledge_ferreira_facts", "p10_acknowledge_personal_question", "p10_preserve_safety_facts":
			return _accept("The conversation facts are acknowledged and kept visible.")
		"p10_compare_dust_repair", "p10_compare_leak_repair", "p10_keep_spare_present":
			return _accept("The repair comparison is ready; the spare stays packed.")
		"p10_verify_flashes":
			return _check_flashes(payload)
		"p10_clean_panel":
			if String(payload.get("repair", "")) == "shield":
				return _accept("Dust Shield verification is ready.")
			if String(payload.get("repair", "")) == "clean":
				return _accept("Panel cleaning is ready.")
			return _reject("Choose cleaning or the Dust Shield verification.")
		"p10_patch_dome_spur":
			if String(payload.get("repair", "")) == "bumper":
				return _accept("Whipple bumper verification is ready.")
			if String(payload.get("repair", "")) == "patch":
				return _accept("Dome spur patching is ready.")
			return _reject("Choose patching or the Whipple bumper verification.")
		"p10_verify_pressure":
			if not maintenance_passed():
				return _reject(String(data().get("feedback", {}).get("pressure_first", "Clean and patch before the pressure test.")))
			return _accept("Pressure test is ready.")
		"p10_exclude_unsupported_impact_claim":
			if String(payload.get("column", "")) == "supported":
				return _reject("A hazard that exists is not proof it caused this fault. The damage report records no verified strike.")
			if String(payload.get("column", "")) != "unsupported":
				return _reject("Choose which column the claim belongs in.")
			return _accept("The impact claim files under Unsupported.")
		"p10_save_report":
			if not _report_filed:
				return _reject("File the unsupported impact claim before saving the report.")
			return _accept("The report saves with its honest blank.")
		"p10_match_noor_identity":
			var identity := String(payload.get("identity", ""))
			if identity == "NOOR_BY_NATIONALITY":
				return _reject(String(data().get("feedback", {}).get("identity_not_from_nationality", "The connection comes from the signed record, not nationality.")))
			if identity == "INITIALS_ONLY":
				return _reject("The manifest signature is N.R. The signed page is the record that expands it.")
			if identity != String(data().get("expected", {}).get("identity", "")):
				return _reject("Choose who the signed manifest names." if identity.is_empty() else "The signed manifest does not name that person.")
			if not evidence_passed():
				return _reject(String(data().get("feedback", {}).get("evidence_first", "Verify the flashes and pass maintenance first.")))
			if not _report_filed:
				return _reject(String(data().get("feedback", {}).get("report_first", "File the report before matching the identity.")))
			return _accept("The signed manifest names Dr. Noor Rahman.")
		"p10_record_consent":
			if not _identity_matched:
				return _reject("Match the signed identity before recording consent.")
			return _accept("Consent is ready to record.")
		"p10_confirm_founder_role":
			if not _identity_matched:
				return _reject("Match the signed identity before confirming the founder role.")
			return _accept("The founder role is ready to confirm.")
		"p10_send_invitation":
			if not _identity_matched or not _consent_recorded or not _founder_confirmed:
				return _reject(String(data().get("feedback", {}).get("invitation_first", "Match the identity and record consent first.")))
			if String(payload.get("invitation", "")).is_empty():
				return _reject("Choose one invitation to send.")
			var valid := false
			for item in data().get("choices", {}).get("invitation", {}).get("options", []):
				if String(item.get("value", "")) == String(payload.get("invitation", "")) and bool(item.get("correct", false)):
					valid = true
			if not valid:
				return _reject("Choose one of the three authored invitations.")
			return _accept("One invitation is ready to send.")
		"p10_plant_cotton", "p10_protect_eleven_vault", "p10_protect_founder_reserve":
			return _accept("The vault and founder ledgers stay separate.")
	return _reject("Unknown P-10 action: " + action)

func commit_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var check := preview_action(action, payload)
	if not bool(check.get("accepted", false)):
		return check
	if bool(check.get("duplicate", false)):
		return check
	var result := _apply_action(action, payload)
	if bool(result.get("accepted", false)) and not _done.has(action):
		_done.append(action)
	return result

func _apply_action(action: String, payload: Dictionary) -> Dictionary:
	match action:
		"p10_verify_flashes":
			var verified := verify_flashes(payload)
			if not bool(verified.get("accepted", false)):
				return verified
			return verified
		"p10_clean_panel":
			if String(payload.get("repair", "")) == "shield":
				if not _shield_verified:
					return verify_dust_shield()
				return _accept("Dust Shield already verified.")
			if not _cleaned:
				return clean_panel()
			return _accept("Panel already clean.")
		"p10_patch_dome_spur":
			if String(payload.get("repair", "")) == "bumper":
				if not _bumper_verified:
					return verify_whipple_bumper()
				return _accept("Whipple bumper already verified.")
			if not _patched:
				return patch_dome_spur()
			return _accept("Dome spur already patched.")
		"p10_verify_pressure":
			if not _pressure_verified:
				var tested := verify_pressure()
				if not bool(tested.get("accepted", false)):
					return tested
			return sample_phase()
		"p10_exclude_unsupported_impact_claim":
			return file_report(String(payload.get("claim", "impact_2034_fault")), String(payload.get("column", "unsupported")))
		"p10_save_report":
			return sample_phase()
		"p10_match_noor_identity":
			if _identity_matched:
				return _accept("Identity already matched.")
			return match_identity(String(payload.get("identity", "")))
		"p10_record_consent":
			return record_consent()
		"p10_confirm_founder_role":
			return confirm_founder_role()
		"p10_send_invitation":
			if _invitation == "":
				var sent := send_invitation(String(payload.get("invitation", "")))
				if not bool(sent.get("accepted", false)):
					return sent
			var sampled := sample_phase()
			if not bool(sampled.get("accepted", false)) and not bool(sampled.get("duplicate", false)):
				return sampled
			return _accept("Invitation sent once, with its receipt kept.")
	return _accept("P-10 action recorded once.")

func flags() -> Dictionary:
	var c := counts()
	return {
		"p10_genuine_verified": int(c.get("genuine", 0)),
		"p10_artifacts_rejected": int(c.get("artifacts_rejected", 0)),
		"p10_false_reports": int(c.get("false_reports", 0)),
		"p10_flashes_verified": _flashes_verified,
		"p10_golden": golden(),
		"p10_maintenance_passed": maintenance_passed(),
		"p10_pressure_verified": _pressure_verified,
		"p10_phases_done": _phases_done,
		"p10_report_filed": _report_filed,
		"p10_identity_matched": _identity_matched,
		"p10_invitation_sent": _invitation != "",
		"p10_complete": _flashes_verified and maintenance_passed() and _pressure_verified and _phases_done == 3 and _identity_matched and _invitation != "",
		"noor_identity_revealed": _identity_matched,
		"noor_contact_consented": _consent_recorded,
	}

func snapshot() -> Dictionary:
	return {"schema_version": 1, "tags": _tags.duplicate(true), "flashes_verified": _flashes_verified, "cleaned": _cleaned, "shield_verified": _shield_verified, "patched": _patched, "bumper_verified": _bumper_verified, "pressure_verified": _pressure_verified, "phases_done": _phases_done, "resources": _resources.duplicate(true), "report_filed": _report_filed, "identity_matched": _identity_matched, "consent_recorded": _consent_recorded, "founder_confirmed": _founder_confirmed, "invitation": _invitation, "committed": _committed, "done": _done.duplicate()}

func restore(state: Dictionary) -> Dictionary:
	var version = state.get("schema_version", 1)
	if not (version is int or version is float) or float(version) != 1.0:
		return _reject("P-10 snapshot is incompatible.")
	if not state.get("tags", {}) is Dictionary or not state.get("resources", {}) is Dictionary:
		return _reject("P-10 tags and resources must be dictionaries.")
	for id in (state.get("tags", {}) as Dictionary).keys():
		if not candidate_ids().has(String(id)) or not String(state.tags[id]) in ["flash", "artifact"]:
			return _reject("P-10 tags must name known candidates as flash or artifact.")
	for key in ["flashes_verified", "cleaned", "shield_verified", "patched", "bumper_verified", "pressure_verified", "report_filed", "identity_matched", "consent_recorded", "founder_confirmed", "committed"]:
		if not state.get(key, null) is bool:
			return _reject("P-10 evidence must be boolean.")
	if not (state.get("phases_done", null) is int or state.get("phases_done", null) is float) or int(state.get("phases_done", -1)) < 0 or int(state.get("phases_done", 99)) > 3:
		return _reject("P-10 phases must be 0 to 3.")
	for key in ["E", "A", "H", "C", "R", "Z"]:
		if not SimulationScript.is_amount((state.get("resources", {}) as Dictionary).get(key, null)):
			return _reject("P-10 resources must be finite nonnegative numbers.")
	if not state.get("invitation", "") is String:
		return _reject("P-10 invitation must be a string.")
	if not state.get("done", []) is Array:
		return _reject("P-10 receipts must be an array.")
	for action in state.get("done", []):
		if not action is String:
			return _reject("P-10 receipts must be strings.")
	_tags = state.get("tags", {}).duplicate(true)
	_flashes_verified = bool(state.get("flashes_verified", false))
	_cleaned = bool(state.get("cleaned", false))
	_shield_verified = bool(state.get("shield_verified", false))
	_patched = bool(state.get("patched", false))
	_bumper_verified = bool(state.get("bumper_verified", false))
	_pressure_verified = bool(state.get("pressure_verified", false))
	_phases_done = int(state.get("phases_done", 0))
	_resources = state.get("resources", {}).duplicate(true)
	_report_filed = bool(state.get("report_filed", false))
	_identity_matched = bool(state.get("identity_matched", false))
	_consent_recorded = bool(state.get("consent_recorded", false))
	_founder_confirmed = bool(state.get("founder_confirmed", false))
	_invitation = String(state.get("invitation", ""))
	_committed = bool(state.get("committed", false))
	_done.assign(state.get("done", []))
	return _accept("P-10 restored.")

func _candidate(candidate_id: String) -> Dictionary:
	for candidate in data().get("candidates", []):
		if String(candidate.get("id", "")) == candidate_id:
			return candidate
	return {}

func _accept(reason: String) -> Dictionary:
	return {"accepted": true, "duplicate": false, "reason": reason}

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason}
