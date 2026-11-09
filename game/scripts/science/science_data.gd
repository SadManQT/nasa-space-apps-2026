extends RefCounted
class_name ScienceData

## Read-only, offline provenance boundary shared by puzzles, outcomes and Journal.
## Numeric displays come from bundled fixtures; training units remain qualified.
const DATA_ROOT := "res://resources/data/nasa"
## Plain-language briefing/debrief card per campaign mission (M1-30), built from the fixtures by production/tools/build_mission_cards.py.
const MISSION_CARDS := "res://resources/campaign/content/mission_data_cards.json"
const TAKEAWAYS := {
	"apollo_shallow_moonquakes": "The Moon has shallow quakes, so Aurora must inspect and secure equipment.",
	"bvad_2022_metabolic": "Crew consume oxygen, water and food, so Aurora must budget for everyone aboard.",
	"chandrayaan1_m3_ice": "Surface ice is patchy, so Aurora must survey before choosing a collection route.",
	"change4_cotton": "Cotton germinated on the Moon, so Aurora can compare seedlings without claiming an earlier lunar harvest.",
	"change4_lnd_surface_dose": "Radiation was measured on the lunar surface, so Aurora checks instruments before an excursion.",
	"clowdsley_2021_shielding": "More shielding can reduce storm exposure, so Aurora weighs water storage against protection.",
	"crater_dose_2012_07": "A lunar-orbit instrument recorded changing dose, so Aurora compares measured exposure with its training model.",
	"diviner_cold_traps": "Some polar traps are extremely cold, so Aurora must protect equipment as it searches for ice.",
	"donki_2012_07": "A major solar eruption missed Earth in 2012, so Aurora uses a labelled counterfactual to practise sheltering.",
	"donki_2017_09": "Solar activity in September 2017 is recorded evidence, so Aurora labels its storm exercise as a historical replay.",
	"esa_moonlight_relay": "Terrain can block a direct Earth link, so Aurora needs a verified relay path.",
	"fast_plants_lifecycle": "Fast Plants need compatible pollination, so Aurora cares for both Alo and Tara.",
	"goes13_protons_2017_09": "Measured proton flux rose during the 2017 event, so Aurora practises sheltering before the peak.",
	"jpl_horizons_ch1_sky": "In the computed April 2046 sky, Earth is below the exact pole's horizon and rising all night, so Aurora's shift-4 Earth-link cutoff is an authored training event.",
	"jpl_horizons_ch8_relay": "Earth bearing changes with time, so Aurora must verify pointing and terrain clearance separately.",
	"jpl_horizons_pole_season": "The polar Sun stays low and changes with season, so Aurora cannot assume continuous power.",
	"jpl_ipn_42_176_dte": "Polar sites differ in Earth visibility, so Aurora checks communication access as well as sunlight.",
	"kaguya_shackleton_floor": "Shackleton's floor is very cold, so Aurora treats an expedition there as a protected operation.",
	"lcross_water_2009": "LCROSS found water in impact material, so Aurora uses evidence rather than assuming every cold trap is rich in ice.",
	"lro_mazarico_2011_illumination": "Even a well-lit polar site has dark periods, so Aurora must store energy for the night.",
	"lro_lola_south_pole_terrain": "The exteriors stand on LOLA's real south-pole terrain, so Aurora's slopes, shadows and horizon come from measurements, not invention.",
	"meo_lunar_impact_flashes": "Two telescopes help verify an impact flash, so Aurora rejects single-camera artifacts.",
	"mir_brassica_seed_to_seed": "Brassica completed a seed cycle in space, so Aurora can study a garden across generations.",
	"nasa_eclipse_2047_01_12": "An eclipse has predictable phases, so Aurora compares a filtered camera view with a labelled conceptual diagram.",
	"osdr_brassica_rapa_iss": "Space-grown Brassica needs controlled conditions, so Aurora keeps its plants inside a pressurised habitat.",
	"stereo_a_het_2012_07": "STEREO-A measured the 2012 particle event, so Aurora distinguishes that observation from a fictional local storm.",
	"usgs_gazetteer_south_pole": "Named lunar features have mapped positions, so Aurora checks distance before committing provisions.",
	"viper_slope_limit": "Rovers have incline limits, so Aurora chooses a route its vehicle can handle.",
	"vsat_relocatable_array": "Solar arrays have finite output, so Aurora balances charging against immediate loads.",
}

static var _cached_mapping: Dictionary = {}
static var _cached_fixtures: Dictionary = {}

var _root: String
var _mapping: Dictionary
var _fixtures: Dictionary = {}

func _init(data_root: String = DATA_ROOT) -> void:
	_root = data_root
	if data_root == DATA_ROOT and not _cached_fixtures.is_empty():
		_mapping = _cached_mapping
		_fixtures = _cached_fixtures
		return
	_mapping = _read_json(_root.path_join("puzzle_sources.json"))
	for file in DirAccess.get_files_at(_root) if DirAccess.dir_exists_absolute(_root) else []:
		if file.ends_with(".json") and file != "puzzle_sources.json":
			_fixtures[file.get_basename()] = _read_json(_root.path_join(file))
	if data_root == DATA_ROOT:
		_cached_mapping = _mapping
		_cached_fixtures = _fixtures

## Sorted IDs of every bundled source, for the Journal source list.
func source_ids() -> Array:
	var ids := _fixtures.keys()
	ids.sort()
	return ids

## Return presentation copies of the puzzle's sources, or an explicit pending card.
func cards_for_puzzle(puzzle_id: String) -> Array:
	var cards: Array = []
	for id in _mapping.get("puzzles", {}).get(puzzle_id, []):
		cards.append(card(String(id)))
	if cards.is_empty():
		cards.append(_pending(puzzle_id))
	return cards

## Return an isolated source record with a fixture-derived visual and takeaway.
func card(source_id: String) -> Dictionary:
	var data: Dictionary = _fixtures.get(source_id, {})
	if data.is_empty():
		return _pending(source_id)
	var result := data.duplicate(true)
	result["takeaway"] = TAKEAWAYS.get(source_id, "Source pending: a plain-language explanation is still needed.")
	result["visual"] = _visual(data)
	result["pending"] = false
	return result

## Check source coverage and required provenance without network access.
func validate() -> Dictionary:
	var errors: Array[String] = []
	for number in range(1, 17):
		var puzzle_id := "P-%02d" % number
		var ids: Array = _mapping.get("puzzles", {}).get(puzzle_id, [])
		if ids.is_empty():
			errors.append(puzzle_id + ": source pending")
		for id in ids:
			if not _fixtures.has(id):
				errors.append(puzzle_id + ": missing fixture " + String(id))
	for id in source_ids():
		var data: Dictionary = _fixtures[id]
		for field in ["source_id", "title", "agency", "dataset_id", "url", "citation", "licence", "retrieved", "evidence_label", "boundary"]:
			if String(data.get(field, "")).is_empty():
				errors.append(String(id) + ": missing " + field)
		if data.get("source_id") != id or not String(data.get("url", "")).begins_with("https://"):
			errors.append(String(id) + ": invalid identity or URL")
		if not TAKEAWAYS.has(id) or _visual(data).is_empty() or data.get("fields_used", []).is_empty() or data.get("derived", []).is_empty():
			errors.append(String(id) + ": missing explanation, visual or processing metadata")
	return {"valid": errors.is_empty(), "errors": errors, "fixture_count": _fixtures.size()}

func _visual(data: Dictionary) -> Dictionary:
	# Preserve each series' real field labels and sample spacing. The chart uses
	# row indices (not a fictitious uniform UTC axis) with first/last timestamps.
	var values: Dictionary = data.get("values", {})
	var columns: Array = values.get("hourly_columns", values.get("columns", []))
	if columns.size() >= 2:
		for key in values:
			var rows = values[key]
			if key.ends_with("columns") or not rows is Array or rows.is_empty() or not rows[0] is Array:
				continue
			var points: Array = []
			for row in rows:
				if row.size() >= 2 and (row[1] is float or row[1] is int):
					points.append(float(row[1]))
			if not points.is_empty():
				return {"kind": "line", "label": String(columns[1]), "values": points, "start": str(rows[0][0]), "end": str(rows[-1][0]), "axis": "Bundled samples in order"}
	for derived in data.get("derived", []):
		# Authored dates remain in the record, but must not look like measurements.
		if String(derived.get("formula", "")).to_lower().contains("story"):
			continue
		var value = derived.get("value")
		if value is float or value is int:
			return {"kind": "bar", "label": String(derived.get("name", "")).replace("_", " "), "values": [float(value)], "unit": derived.get("unit", ""), "axis": "Computed from fixture; zero baseline"}
	for key in values:
		var value = values[key]
		if value is float or value is int:
			return {"kind": "bar", "label": String(key).replace("_", " "), "values": [float(value)], "unit": "See measured field", "axis": "Published fixture value; zero baseline"}
	for key in values:
		if values[key] is bool:
			return {"kind": "gauge", "label": String(key).replace("_", " "), "values": [1.0 if values[key] else 0.0], "unit": "Yes" if values[key] else "No", "axis": "Recorded fact; not a numerical measurement"}
	return {}

## Format measured inputs and processing metadata for the card's text equivalent.
static func describe(value) -> String:
	if value is Dictionary:
		var rows: Array[String] = []
		for key in value:
			rows.append(String(key).replace("_", " ") + ": " + describe(value[key]))
		return "\n".join(rows)
	if value is Array and not value.is_empty() and value[0] is Dictionary:
		var rows: Array[String] = []
		for item in value:
			rows.append(describe(item))
		return "\n\n".join(rows)
	if value is Array and value.size() > 8:
		return "%d entries; first %s; last %s" % [value.size(), JSON.stringify(value[0]), JSON.stringify(value[-1])]
	return JSON.stringify(value) if value is Array or value is bool else str(value)

func _pending(id: String) -> Dictionary:
	return {"source_id": id, "title": "Source pending" if OS.is_debug_build() else "Source unavailable", "takeaway": "A verified source is not available for this display.", "pending": true}

## The mission's data card (plain text, one simple visual, what it means for Aurora, limits, sources), or {} if none.
func mission_card(mission_id: String) -> Dictionary:
	return _read_json(MISSION_CARDS).get("missions", {}).get(mission_id, {}).duplicate(true)

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
