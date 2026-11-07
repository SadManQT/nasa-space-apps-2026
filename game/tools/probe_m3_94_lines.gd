## Headless M3-94 evidence probe (no window needed):
## Godot --headless --path game --script res://tools/probe_m3_94_lines.gd
## Prints, for the two scenes that gained approved lines, the exact caption order the
## runtime dialogue service returns before and after the relay flags, and writes the
## same transcript to production/qa/evidence/M3-94_catalog_probe.txt. A Godot exit
## code alone is never accepted: the last line must read M3-94 PROBE RESULT: PASS.
extends SceneTree

const Content = preload("res://scripts/content/content_loader.gd")
const Dialogue = preload("res://scripts/dialogue/dialogue_service.gd")

var _out: Array[String] = []
var _failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var content: Dictionary = Content.load_full()
	var validation: Dictionary = Content.validate_full(content)
	_line("campaign catalog %s, dialogue_lines=%d, valid=%s %s" % [String(content.get("content_revision", "")), int(content.get("counts", {}).get("dialogue_lines", 0)), str(validation.get("valid", false)), str(validation.get("errors", []))])
	_expect(bool(validation.get("valid", false)), "frozen catalog validates")
	var service = Dialogue.new(content)
	_scene(service, "EX-CH03-S10", [], "no flags")
	_scene(service, "EX-CH08-S10", ["noor_identity_revealed"], "identity only (channel still closed)")
	_scene(service, "EX-CH08-S10", ["noor_identity_revealed", "relay_local_verified", "relay_earth_verified"], "identity + both relay legs verified")
	var tally: Dictionary = service.dialogue_by_id("EX-CH03-S10-L05")
	_expect(String(tally.get("text", "")) == "Forty-two." and String(tally.get("speaker_id", "")) == "amara" and int(tally.get("order", 0)) == 5, "EX-CH03-S10-L05 is Amara's tally line, played fifth")
	var rao: Dictionary = service.dialogue_by_id("EX-CH08-S10-L05")
	_expect(String(rao.get("origin_label", "")) == "EARTH LINK" and int(rao.get("order", 0)) == 1 and rao.get("knowledge_required", []) == ["relay_local_verified", "relay_earth_verified"], "EX-CH08-S10-L05 opens the scene on the Earth link and waits for both relay legs")
	var noor: Dictionary = service.dialogue_by_id("EX-CH08-S10-L06")
	_expect(int(noor.get("order", 0)) == 4 and noor.get("knowledge_required", []) == ["noor_identity_revealed", "relay_local_verified", "relay_earth_verified"], "EX-CH08-S10-L06 answers Mei fourth and is identity- and relay-gated")
	for line_id in ["EX-CH03-S10-L05", "EX-CH08-S10-L05", "EX-CH08-S10-L06"]:
		var voice := String(service.dialogue_by_id(line_id).get("voice_file", ""))
		_expect(voice.ends_with("VO_%s.ogg" % line_id) and FileAccess.file_exists("res://" + voice.trim_prefix("game/")), line_id + " is voiced (M3-94R, 7 Nov 2026)")
	for line_id in ["EX-CH08-S10-L01", "EX-CH08-S10-L02", "EX-CH08-S10-L03", "EX-CH08-S10-L04"]:
		_expect(ResourceLoader.exists("res://" + String(service.dialogue_by_id(line_id).get("voice_file", "")).trim_prefix("game/")), line_id + " keeps its recorded voice file")
	_line("M3-94 PROBE RESULT: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	var file := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence/M3-94_catalog_probe.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_out) + "\n")
		file.close()
	quit(0 if _failures == 0 else 1)

func _scene(service, scene_id: String, flags: Array, label: String) -> void:
	_line("")
	_line("%s with %s:" % [scene_id, label])
	for line in service.lines_for_scene(scene_id, flags, true):
		var caption: Dictionary = service.caption_for_line(String(line.get("id", "")), flags)
		var shown: String = ("%s [%s]: %s" % [caption.get("speaker", ""), caption.get("origin_label", ""), caption.get("text", "")]) if bool(caption.get("available", false)) else "(locked: %s)" % String(caption.get("reason", ""))
		_line("  %d. %s  %s" % [int(line.get("order", 0)), String(line.get("id", "")), shown])

func _expect(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
	_line("%s %s" % ["ok  " if condition else "FAIL", label])

func _line(text: String) -> void:
	_out.append(text)
	print(text)
