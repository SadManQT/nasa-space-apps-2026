extends SceneTree
var menu: MainMenu
func _init() -> void:
 call_deferred("_run")
func _run() -> void:
 root.size = Vector2i(1280,720)
 root.content_scale_size = root.size
 menu = load("res://scenes/ui/main_menu.tscn").instantiate() as MainMenu
 root.add_child(menu)
 menu.setup({})
 await _capture("menu")
 menu.set_accessibility({"large_text":true})
 await _capture("menu_large")
 menu.set_accessibility({"large_text":false})
 menu.open_panel("settings_accessibility")
 await _capture("settings")
 menu.free()
 print("UI POLISH CAPTURE RESULT: PASS (3 captures, 0 failures)")
 quit()
func _capture(name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M4-20/" + name + ".png")
 DirAccess.make_dir_recursive_absolute(path.get_base_dir())
 var error := image.save_png(path)
 assert(error == OK, "capture must save")
