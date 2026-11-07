extends RefCounted

## Explicit witness inputs for tests/captures only. Never used by the game.
static func payload(target: String) -> Dictionary:
	match target:
		"calibrate_probe", "set_zero": return {"reference": "dry", "raw_reading": 10, "calibrated_reading": 0}
		"span_probe", "set_span": return {"reference": "wet", "raw_reading": 110, "calibrated_reading": 100}
		"recheck_probe", "recheck": return {"dry_reading": 0, "wet_reading": 100}
		"plant_alo": return {"cassette": "alo", "seed_count": 1}
		"plant_tara": return {"cassette": "tara", "seed_count": 1}
		"water_alo", "water_tara": return {"moisture": 50}
	return {}
