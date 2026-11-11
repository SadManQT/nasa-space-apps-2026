extends SceneTree
var failures := 0
var checks := 0
func _init() -> void:
 call_deferred("_run")
func _run() -> void:
 var theme := UiKit.theme()
 _check(theme.default_font != null, "shared body font is bundled")
 _check(theme.has_font("font", "TitleLabel"), "display headings have a separate bundled font")
 var button := UiDesign.button("Focus")
 var focus := button.get_theme_stylebox("focus") as StyleBoxFlat
 button.free()
 _check(not focus.draw_center and focus.border_width_left >= 2, "keyboard focus does not obscure state fill")
 for kind in ["CheckButton", "CheckBox"]:
  var pressed := theme.get_stylebox("pressed",kind) as StyleBoxFlat
  _check(UiKit.contrast_ratio(Color("#ECEEF0"), pressed.bg_color) >= 4.5, "checked row supports existing ivory-label overrides")
 _check(theme.get_stylebox("panel", "HeroPanel") is GoStyleBoxCut, "authored hero uses the Gohud sci-fi surface")
 var menu := load("res://scenes/ui/main_menu.tscn").instantiate() as MainMenu
 _check(menu.get_node_or_null("Page") != null, "title composition exists before ready")
 root.size = Vector2i(1280,720)
 root.add_child(menu)
 menu.setup({})
 await process_frame
 for large in [false,true]:
  menu.set_accessibility({"large_text":large})
  await process_frame
  _check(menu._begin_button.get_global_rect().size.y >= 44, "primary action target at both text scales")
  _check(menu._continue_button.disabled, "unavailable Continue stays disabled")
  var nav := menu.get_node("Page/Body/Navigation") as ScrollContainer
  var chapters := menu.find_child("ChapterSelectEntry",true,false) as Button
  chapters.grab_focus()
  await process_frame
  await process_frame
  _check(nav.get_global_rect().encloses(chapters.get_global_rect()), "keyboard can reveal the final navigation action without clipping")
  var settings := menu.find_child("SettingsEntry",true,false) as Button
  _check(settings != null, "settings has a clearly named entry")
  if settings != null:
   settings.grab_focus()
   await process_frame
   _check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(settings.get_global_rect()), "settings remains reachable at both text scales")
 menu.set_accessibility({"large_text":false})
 menu._begin_button.grab_focus()
 menu._show_briefing()
 await _escape()
 _check(not menu._briefing.visible, "Escape closes the new-expedition briefing")
 menu.open_science()
 await _escape()
 _check(not menu._science.visible, "Escape closes Science and returns focus")
 menu.free()
 print("UI POLISH RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL",checks,failures])
 quit(0 if failures == 0 else 1)
func _escape() -> void:
 for pressed in [true,false]:
  var event := InputEventKey.new()
  event.keycode = KEY_ESCAPE
  event.physical_keycode = KEY_ESCAPE
  event.pressed = pressed
  Input.parse_input_event(event)
  Input.flush_buffered_events()
 await process_frame
func _check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
