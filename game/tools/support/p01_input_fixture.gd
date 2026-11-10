extends RefCounted

## Explicit witness inputs for tests/captures only. Never used by the game.

## M1-108: drives the opening probe transfer on a route (retrieve from the
## rack, place at the bench cradle, read the dry zero). The transfer gates
## set_zero, so suites that commit calibrate_probe complete it first.
## Idempotent, and finishes a transfer from any stage: a route restored
## mid-transfer resumes where the probe actually is.
static func complete_probe_transfer(route: RefCounted) -> Dictionary:
	var job: RefCounted = route.probe_job()
	if bool(job.completed()):
		return {"accepted": true, "reason": "Dry zero already set."}
	var result: Dictionary = {}
	if String(job.state()) == "at_rack":
		result = job.retrieve()
		if not bool(result.get("accepted", false)):
			return result
	if String(job.state()) == "held":
		result = job.place_at_bench()
		if not bool(result.get("accepted", false)):
			return result
	if String(job.state()) == "at_bench":
		return job.observe_zero()
	return {"accepted": false, "reason": "Probe transfer is in an unknown state."}

static func payload(target: String) -> Dictionary:
	match target:
		"calibrate_probe", "set_zero": return {"reference": "dry", "raw_reading": 10, "calibrated_reading": 0}
		"span_probe", "set_span": return {"reference": "wet", "raw_reading": 110, "calibrated_reading": 100}
		"recheck_probe", "recheck": return {"dry_reading": 0, "wet_reading": 100}
		"plant_alo": return {"cassette": "alo", "seed_count": 1}
		"plant_tara": return {"cassette": "tara", "seed_count": 1}
		"water_alo", "water_tara": return {"moisture": 50}
		"label_alo", "label_alo_external": return {"label": "EXTERNAL_TEST"}
		"label_tara", "label_tara_indoor": return {"label": "INDOOR_REFERENCE"}
	return {}
