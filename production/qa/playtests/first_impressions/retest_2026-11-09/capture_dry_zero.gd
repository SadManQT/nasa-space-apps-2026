extends "res://tools/test_campaign_interaction_input.gd"

# Reuse the reviewed production-input fixture. Redirect its evidence only;
# never overwrite another owner's M1-107 screenshots or trace.
func _capture(id: String) -> void:
	if not _capture_enabled():
		return
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var name := "M1-65_retest_" + id + ".png"
	var path := OS.get_environment("TEST_LOG_DIR").path_join(name)
	_check(root.get_texture().get_image().save_png(path) == OK, "capture " + name)
	shots.append(name)

func _finish() -> void:
	var path := OS.get_environment("TEST_LOG_DIR").path_join("input_trace.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "write QA input trace")
	if file != null:
		file.store_string(JSON.stringify({"trace": trace, "ui_input": ui_input, "captures": shots, "checks": checks, "failures": failures}, " "))
		file.close()
	storage.cleanup()
	print("CAMPAIGN INTERACTION INPUT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
