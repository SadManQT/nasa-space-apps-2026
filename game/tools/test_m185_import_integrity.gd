## Real imported font sanity check; no campaign state, save or cache bypass.
extends SceneTree

var _checks := 0
var _failures := 0

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("M1-85 import check: " + label)

func _run() -> void:
	var path := "res://assets/props/narrative/fonts/GochiHand-Regular.ttf"
	_check(FileAccess.file_exists(path), "source font exists")
	_check(FileAccess.file_exists(path + ".import"), "import metadata exists")
	_check(ResourceLoader.exists(path), "imported resource is registered")
	var font := load(path) as Font
	_check(font != null, "font loads from normal importer output")
	_check(font != null and font.get_height(16) > 0.0, "font has usable metrics")
	font = null
	await process_frame
	print("M185 IMPORT INTEGRITY RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)
