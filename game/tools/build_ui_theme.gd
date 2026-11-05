## Writes res://resources/ui/lla_theme.tres from UiKit.theme() so the saved Theme
## resource always equals the one the runtime builds from the design tokens (M1-07).
##   Godot --headless --path game --script res://tools/build_ui_theme.gd
extends SceneTree

func _init() -> void:
	var error := ResourceSaver.save(UiKit.theme(), UiKit.THEME_PATH)
	print("UI THEME RESULT: %s (%s)" % ["PASS" if error == OK else "FAIL", UiKit.THEME_PATH])
	quit(0 if error == OK else 1)
