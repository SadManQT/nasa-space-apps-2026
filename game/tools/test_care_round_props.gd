## M3-99 narrative props in place (M3-101): each prop appears in its scene
## with its canon words and not before. Headless; data only, via
## RoomContract.staged_layout and NarrativeProps.text_lines (pure JSON), so
## the LFS-stub copy can verify every prop without loading a GLB.
extends SceneTree

const RoomContract = preload("res://scripts/world/room_contract.gd")
const NarrativeProps = preload("res://assets/props/narrative/narrative_props.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: " + label)

func _layout(room_id: String, scene_id: String, choices: Dictionary = {}, moments: Array = []) -> Dictionary:
	return RoomContract.staged_layout(room_id, scene_id, choices, moments)

func _prop(layout: Dictionary, prop_id: String) -> Dictionary:
	for prop in layout.get("props", []):
		if String(prop.get("id", "")) == prop_id:
			return prop
	return {}

func _sign(layout: Dictionary, sign_id: String) -> Dictionary:
	for sign in layout.get("signs", []):
		if String(sign.get("id", "")) == sign_id:
			return sign
	return {}

func _at(prop: Dictionary, expected: Vector3) -> bool:
	if prop.is_empty():
		return false
	var at := Vector3(float(prop.get("position", [0, 0, 0])[0]), float(prop.get("position", [0, 0, 0])[1]), float(prop.get("position", [0, 0, 0])[2]))
	return at.distance_to(expected) < 0.001

func _rotated(prop: Dictionary, expected: Vector3) -> bool:
	if prop.is_empty():
		return false
	var rot: Array = prop.get("rotation_degrees", [0, 0, 0])
	var at := Vector3(float(rot[0]), float(rot[1]), float(rot[2]))
	return at.distance_to(expected) < 0.001

func _run() -> void:
	_test_words()
	_test_holders_at_plants()
	_test_named_mugs()
	_test_fifth_mug()
	_test_drawer_lid_note()
	_test_tool_tag()
	_test_working_stock()
	_test_n_holder()
	print("CARE ROUND PROPS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

## Every prop's words are the canon lines, English in Latin letters only.
func _test_words() -> void:
	var expected := {
		"PR_LabelHolder/alo": ["ALO", "ALO-01  |  purple stem"],
		"PR_LabelHolder/tara": ["TARA", "TARA-01  |  green stem"],
		"PR_LabelHolder/n": ["N."],
		"PR_Mug_Named/unnamed": [],
		"PR_Mug_Named/KAI": ["KAI"],
		"PR_Mug_Named/AMARA": ["AMARA"],
		"PR_Mug_Named/MEI": ["MEI"],
		"PR_Mug_Named/RAFI": ["RAFI"],
		"PR_Mug_Named/FERREIRA": ["FERREIRA"],
		"PR_DrawerLidNote/default": ["Seed 1: outer chamber.", "Seed 2: inside, for comparison.", "Water at"],
		"PR_ToolTag_Gear/default": ["ENG-07"],
		"PR_WorkingStockEnvelope/default": ["Working stock", "Tara × Alo"],
	}
	for key in expected:
		var parts := String(key).split("/")
		var lines: PackedStringArray = NarrativeProps.text_lines(parts[0], parts[1])
		_check(Array(lines) == expected[key], "%s draws its canon words %s" % [key, expected[key]])
		for line in lines:
			var latin := true
			for i in line.length():
				var code := line.unicode_at(i)
				if code >= 0x0980 and code <= 0x09FF:
					latin = false
			_check(latin, "%s line is English in Latin letters only: %s" % [key, line])

## Mei presses both names on in EX-CH01-S04; each holder stays at its plant
## until its nameplate moves to the lineage board.
func _test_holders_at_plants() -> void:
	var before := _layout("LOC-03", "EX-CH01-S03")
	_check(_prop(before, "alo_holder").is_empty() and _prop(before, "tara_holder").is_empty(),
		"holders: no nameplates before EX-CH01-S04")
	var s04 := _layout("LOC-03", "EX-CH01-S04")
	var alo := _prop(s04, "alo_holder")
	var tara := _prop(s04, "tara_holder")
	_check(String(alo.get("path", "")) == "res://assets/props/narrative/PR_LabelHolder.glb"
		and String(alo.get("variant", "")) == "alo", "holders: Alo's holder is the M3-99 prop, variant alo")
	_check(String(tara.get("path", "")) == "res://assets/props/narrative/PR_LabelHolder.glb"
		and String(tara.get("variant", "")) == "tara", "holders: Tara's holder is the M3-99 prop, variant tara")
	_check(_at(alo, Vector3(2.4, 0.65, 2.8)) and _rotated(alo, Vector3(90, 180, 0)),
		"holders: Alo's holder mounts on the bench face below the sealed glove port")
	_check(_at(tara, Vector3(-3.2, 0.65, -0.95)) and _rotated(tara, Vector3(90, 0, 0)),
		"holders: Tara's holder mounts on the reference bench face")
	var s05 := _layout("LOC-03", "EX-CH01-S05")
	_check(not _prop(s05, "alo_holder").is_empty() and not _prop(s05, "tara_holder").is_empty(),
		"holders: both holders stay for the second care day")
	var ch02 := _layout("LOC-03", "EX-CH02-S01")
	_check(not _prop(ch02, "alo_holder").is_empty() and not _prop(ch02, "tara_holder").is_empty(),
		"holders: both holders are still at the plants in Chapter 2")
	var s08 := _layout("LOC-03", "EX-CH03-S08")
	_check(not _prop(s08, "alo_holder").is_empty() and not _prop(s08, "tara_holder").is_empty(),
		"holders: both holders are still at the plants in EX-CH03-S08")
	var s10 := _layout("LOC-03", "EX-CH03-S10")
	_check(_prop(s10, "alo_holder").is_empty() and not _prop(s10, "tara_holder").is_empty(),
		"holders: Alo's holder leaves the plant in EX-CH03-S10, Tara's stays")
	_check(String(_prop(s10, "alo_nameplate").get("variant", "")) == "alo",
		"holders: Alo's nameplate is on the lineage board in EX-CH03-S10")
	var s11 := _layout("LOC-03", "EX-CH03-S11")
	_check(not _prop(s11, "tara_holder").is_empty(), "holders: Tara's holder is still at the bay in EX-CH03-S11")
	var s12 := _layout("LOC-03", "EX-CH03-S12")
	_check(_prop(s12, "tara_holder").is_empty(), "holders: Tara's holder leaves the bay on 31 May")
	_check(String(_prop(s12, "tara_nameplate").get("variant", "")) == "tara",
		"holders: Tara's nameplate is on the lineage board in EX-CH03-S12")

## The four commons mugs gain their names at the end of EX-CH01-S12, once
## the CH01-MUGS-NAMED moment is recorded — and not before.
func _test_named_mugs() -> void:
	var named := {"commons_mug_kai": "KAI", "commons_mug_amara": "AMARA", "commons_mug_mei": "MEI", "commons_mug_rafi": "RAFI"}
	var unnamed := _layout("LOC-01", "EX-CH01-S12")
	for mug_id in named:
		_check(_prop(unnamed, mug_id).is_empty(), "mugs: %s is nameless before the moment" % mug_id)
	var with_moment := _layout("LOC-01", "EX-CH01-S12", {}, ["CH01-MUGS-NAMED"])
	for mug_id in named:
		var mug := _prop(with_moment, mug_id)
		_check(String(mug.get("path", "")) == "res://assets/props/narrative/PR_Mug_Named.glb"
			and String(mug.get("variant", "")) == named[mug_id],
			"mugs: %s is PR_Mug_Named variant %s once the moment is recorded" % [mug_id, named[mug_id]])
	var too_early := _layout("LOC-01", "EX-CH01-S11", {}, ["CH01-MUGS-NAMED"])
	for mug_id in named:
		_check(_prop(too_early, mug_id).is_empty(), "mugs: %s does not gain its name before EX-CH01-S12" % mug_id)

## Ferreira's fifth mug is the named prop from the clip onward, wherever it stands.
func _test_fifth_mug() -> void:
	var cases := [
		["EX-CH04-S12", Vector3(0.0, 2.212, -0.55)],
		["EX-CH05-S01", Vector3(0.0, 2.212, -0.55)],
		["EX-CH05-S02", Vector3(-0.22, 0.762, -0.6)],
		["EX-CH05-S11", Vector3(-0.22, 0.762, -0.6)],
		["EX-CH07-S02", Vector3(0.66, 0.762, 0.08)],
		["EX-CH08-S01", Vector3(2.3, 0.74, -5.5)],
		["EX-CH08-S11", Vector3(0.66, 0.762, 0.08)],
	]
	for item in cases:
		var layout := _layout("LOC-01", String(item[0]))
		var mug := _prop(layout, "commons_mug_5")
		_check(String(mug.get("path", "")) == "res://assets/props/narrative/PR_Mug_Named.glb"
			and String(mug.get("variant", "")) == "FERREIRA" and _at(mug, item[1]),
			"fifth mug: Ferreira's named mug in %s" % item[0])
	_check(_prop(_layout("LOC-01", "EX-CH04-S11"), "commons_mug_5").is_empty(),
		"fifth mug: no fifth mug before EX-CH04-S12")
	_check(_prop(_layout("LOC-01", "EX-CH05-S06"), "commons_mug_5").is_empty(),
		"fifth mug: her mug is at the corridor watch in EX-CH05-S06, not at the table")
	var clip := _layout("LOC-01", "EX-CH04-S12")
	_check(String(_sign(clip, "mug_clip_tag_text").get("text", "")) == "FERREIRA",
		"fifth mug: the clip tag still reads FERREIRA beside the named mug")

## The pencil note under the dry-storage drawer lid, from EX-CH01-S03.
func _test_drawer_lid_note() -> void:
	var s03 := _layout("LOC-01", "EX-CH01-S03")
	var note := _prop(s03, "drawer_lid_note")
	_check(String(note.get("path", "")) == "res://assets/props/narrative/PR_DrawerLidNote.glb",
		"lid note: the M3-99 prop is under the drawer lid in EX-CH01-S03")
	_check(_at(note, Vector3(-5.0, 1.38, -4.8)) and _rotated(note, Vector3(180, 0, 0)),
		"lid note: mounted under the lid, writing side down")
	_check(_prop(_layout("LOC-01", "EX-CH01-S02"), "drawer_lid_note").is_empty(),
		"lid note: no note before the inspection camera in EX-CH01-S03")
	_check(not _prop(_layout("LOC-01", "EX-CH01-S04"), "drawer_lid_note").is_empty(),
		"lid note: the note stays under the lid after S03")

## The gear-wheel tool tag on the annex warm-side bench, EX-CH03-S07 only.
func _test_tool_tag() -> void:
	var s07 := _layout("LOC-07", "EX-CH03-S07")
	var attached: Array = s07.get("stage", {}).get("kit_attach", {}).get("annex_station", [])
	var tag := {}
	for item in attached:
		if String(item.get("id", "")) == "tool_tag":
			tag = item
	_check(String(tag.get("narrative", "")) == "PR_ToolTag_Gear"
		and String(tag.get("socket", "")) == "Socket_ToolTag",
		"tool tag: the M3-99 gear-wheel tag is on the annex station in EX-CH03-S07")
	var s06 := _layout("LOC-07", "EX-CH03-S06")
	_check(s06.get("stage", {}).get("kit_attach", {}).get("annex_station", []).is_empty(),
		"tool tag: no tag before EX-CH03-S07")
	var s09 := _layout("LOC-07", "EX-CH03-S09")
	_check(s09.get("stage", {}).get("kit_attach", {}).get("annex_station", []).is_empty(),
		"tool tag: the tag leaves with the bench after EX-CH03-S08")

## Tara's harvest: the sealed working-stock envelope, EX-CH03-S12 only.
func _test_working_stock() -> void:
	var s12 := _layout("LOC-03", "EX-CH03-S12")
	var envelope := _prop(s12, "working_stock")
	_check(String(envelope.get("path", "")) == "res://assets/props/narrative/PR_WorkingStockEnvelope.glb",
		"working stock: the M3-99 envelope is at Tara's harvest in EX-CH03-S12")
	_check(_prop(_layout("LOC-03", "EX-CH03-S11"), "working_stock").is_empty(),
		"working stock: no envelope before the harvest")

## D10 option 2: the real "n" holder at the table, and the stand-in is gone.
func _test_n_holder() -> void:
	var opt02 := {"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}}
	var opt01 := {"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT01"}}
	var s11 := _layout("LOC-01", "EX-CH05-S11", opt02)
	var holder := _prop(s11, "n_holder")
	_check(String(holder.get("path", "")) == "res://assets/props/narrative/PR_LabelHolder.glb"
		and String(holder.get("variant", "")) == "n",
		"n holder: the M3-99 prop, variant n, sits at the table for D10 option 2")
	_check(_at(holder, Vector3(0.0, 0.77, 0.78)), "n holder: it stands where the stand-in card stood")
	for fixture_id in ["n_holder_base", "n_holder_card"]:
		_check(s11.get("fixtures", []).all(func(f): return String(f.get("id", "")) != fixture_id),
			"n holder: the %s stand-in fixture is gone" % fixture_id)
	_check(_sign(s11, "n_holder_text").is_empty(), "n holder: the N. stand-in sign is gone")
	_check(_prop(_layout("LOC-01", "EX-CH05-S11", opt01), "n_holder").is_empty(),
		"n holder: no holder for D10 option 1")
	_check(_prop(_layout("LOC-01", "EX-CH05-S11", {}), "n_holder").is_empty(),
		"n holder: no holder without the recorded choice")
	_check(_prop(_layout("LOC-01", "EX-CH05-S10", opt02), "n_holder").is_empty(),
		"n holder: no holder before EX-CH05-S11")
	_check(not _prop(_layout("LOC-01", "EX-CH08-S10", opt02), "n_holder").is_empty(),
		"n holder: the holder still waits at the table in EX-CH08-S10")
