## Windowed capture of the UI_Kit approval sheet (M1-07): every icon with its word, the
## button states, glass panel and state cards, meters, source chips, role markers,
## key glyphs and the type scale, at 100 % and at 150 % text. Writes
## production/concept/ui_kit/UI_Kit_sheet_v1.png (approval) and the
## production/qa/evidence/M1-07_ui_kit_*.png shots, 1920 wide at the 1080p type reference.
## Needs a window (not --headless).
##   Godot --path game --script res://tools/probe_ui_kit_sheet.gd -- --out <dir>
extends SceneTree

## The sheet is drawn at the 1080p reference size in its own SubViewport, so a laptop screen that clamps
## the window cannot crop it; the height grows to fit the 150 % text version.
const WIDTH := 1920
const REFERENCE_HEIGHT := 1080.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := ProjectSettings.globalize_path("res://../production/qa/evidence")
	if args.has("--out"):
		out = args[args.find("--out") + 1]
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	for pair in [[1.0, "100"], [1.5, "150"]]:
		var view := SubViewport.new()
		view.size = Vector2i(WIDTH, int(REFERENCE_HEIGHT))
		view.transparent_bg = false
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var sheet := _sheet(float(pair[0]))
		view.add_child(sheet)
		for index in 4:
			await process_frame
		# grow the canvas to the laid-out content, then let it settle at that size
		var height := maxi(int(REFERENCE_HEIGHT), int(ceil(sheet.get_child(1).get_combined_minimum_size().y)))
		view.size = Vector2i(WIDTH, height)
		sheet.size = Vector2(WIDTH, height)
		for child in sheet.get_children():
			(child as Control).size = Vector2(WIDTH, height)
		for index in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := view.get_texture().get_image()
		image.save_png(out.path_join("M1-07_ui_kit_sheet_%s.png" % pair[1]))
		if pair[1] == "100":
			image.save_png(ProjectSettings.globalize_path("res://../production/concept/ui_kit/UI_Kit_sheet_v1.png"))
		print("UI KIT SHEET: wrote %s at %d%% text, %dx%d" % [out, int(float(pair[0]) * 100), image.get_width(), image.get_height()])
		view.free()
		await process_frame
	print("UI KIT SHEET RESULT: PASS")
	quit(0)

func _sheet(scale: float) -> Control:
	var page := Control.new()
	page.size = Vector2(WIDTH, REFERENCE_HEIGHT)
	var back := ColorRect.new()
	back.color = UiDesign.colour("ink")
	back.size = page.size
	page.add_child(back)
	var margin := MarginContainer.new()
	margin.size = page.size
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	page.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	column.add_child(head)
	var title := UiDesign.label("Last Light Academy UI kit", "title", "accent")
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(title)
	# Wrapping labels inside an HBox need a width of their own, or they wrap after every letter.
	var subtitle := UiDesign.label("palette ART_BIBLE §3 · type 40/28/20/16 · glass panels · one 24 px line-icon set, every icon with a word · text at %d%%" % int(scale * 100), "caption", "muted")
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(subtitle)
	# icons: a grid of every kind with its word
	column.add_child(UiDesign.label("Icons", "heading"))
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	for kind in UiKit.icon_kinds():
		var cell := UiKit.icon_label(String(kind), "", "caption")
		cell.custom_minimum_size.x = 196.0 * scale  # equal cells, so the set reads as a grid at any text size
		grid.add_child(cell)
	var rows := HBoxContainer.new()
	rows.add_theme_constant_override("separation", 24)
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(rows)
	# left: buttons, states, keys
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_child(left)
	left.add_child(UiDesign.label("Buttons and keys", "heading"))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	left.add_child(buttons)
	for state in [["Rest", "normal"], ["Hover", "hover"], ["Pressed", "pressed"], ["Focus", "focus"], ["Disabled", "disabled"]]:
		var button := UiDesign.button(state[0])
		if state[1] != "normal":
			button.add_theme_stylebox_override("normal", UiKit.theme().get_stylebox(state[1], "Button"))
		if state[1] in ["hover", "pressed"]:
			button.add_theme_color_override("font_color", UiDesign.colour("ink"))
		if state[1] == "disabled":
			button.disabled = true
		buttons.add_child(button)
	var keys := HBoxContainer.new()
	keys.add_theme_constant_override("separation", 10)
	left.add_child(keys)
	for key in ["E", "H", "Esc", "Enter", "Space"]:
		keys.add_child(UiKit.key_glyph(key))
	var keys_note := UiDesign.label("44 px key caps beside the prompt word", "caption", "muted")
	keys_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keys_note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	keys.add_child(keys_note)
	left.add_child(UiDesign.label("Panel states", "heading"))
	var states := GridContainer.new()
	states.columns = 2
	states.add_theme_constant_override("h_separation", 10)
	states.add_theme_constant_override("v_separation", 10)
	left.add_child(states)
	for state in [["empty", "Open the journal after the first job."], ["error", "The gauge did not answer. Try again from the panel."], ["loading", "Reading the station."], ["disabled", "Kai is at the power room until shift 2."]]:
		var card := UiKit.state_card(state[0], state[1])
		card.custom_minimum_size.x = 330
		states.add_child(card)
	left.add_child(UiDesign.label("Type scale", "heading"))
	for token in [["title", "Title 40"], ["heading", "Heading 28"], ["body", "Body 20, at most 60 characters a line"], ["caption", "Caption 16, muted"]]:
		left.add_child(UiDesign.label(token[1], token[0], "muted" if token[0] == "caption" else "ivory"))
	# right: meters, chips, roles in a glass panel
	var right := UiDesign.glass_panel()
	right.custom_minimum_size.x = 640.0 * minf(scale, 1.25)
	rows.add_child(right)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	right.add_child(inner)
	inner.add_child(UiDesign.label("Resource meters", "heading"))
	for meter in [["power", 78.0, 100.0, "%"], ["life", 92.0, 100.0, "%"], ["water", 41.0, 100.0, "%"], ["shielding", 12.0, 100.0, "%"], ["food", 36.0, 72.0, "h"]]:
		inner.add_child(UiKit.meter(meter[0], meter[1], meter[2], meter[3]))
	inner.add_child(UiDesign.label("Source chips", "heading"))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	inner.add_child(chips)
	for origin in ["EARTH LINK", "LOCAL RADIO", "STORED RECORDING", "QUEUED TEXT"]:
		chips.add_child(UiKit.source_chip(origin))
	inner.add_child(UiDesign.label("Role markers", "heading"))
	var roles := GridContainer.new()
	roles.columns = 2
	roles.add_theme_constant_override("h_separation", 24)
	roles.add_theme_constant_override("v_separation", 6)
	inner.add_child(roles)
	for role in ["kai", "amara", "rafi", "mei", "ferreira", "rao"]:
		roles.add_child(UiKit.role_marker(role))
	UiDesign.apply_type(page, REFERENCE_HEIGHT, scale)
	return page
