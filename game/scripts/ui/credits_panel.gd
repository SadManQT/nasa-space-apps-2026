extends Control
class_name CreditsPanel

## M3-90 (UI_16_CREDITS.md & CREDITS.md §9): In-game Credits and Post-Credits
## CS-18 ("The Closed Drawer") screen.
## Exact contract:
## - Slow optional auto-scroll, manual scroll, photo + dedication, return to
##   garden, and skip.
## - Order from CREDITS.md §9:
##   1. Team The Last BrainCell (names and roles from docs/TEAM.md)
##   2. Story, characters, puzzles and science mapping — the team
##   3. Data — "Built on NASA open data" + partner agencies
##   4. Made with AI tools — summary + "every generation is logged with its prompt; see docs/AI_USE.md"
##   5. Engine — "Made with Godot Engine" + runtime Engine.get_license_text() & Engine.get_copyright_info()
##   6. Tools — Blender, FFmpeg
##   7. Disclaimer — "Aurora Station, the cadets and Alo are fiction. The 2017 storm is a historical replay; the 2012 storm is a what-if. NASA does not endorse this game."
## - Exit/edge case: Skip still offers optional post-credits CS-18 ("The Closed Drawer" / MARS drawer); no forced teaser.

signal return_to_garden_requested
signal closed_drawer_inspected
signal panel_closed

var embedded := false
var _scroll_position := 0.0
var auto_scroll := true
var scroll_speed_px_s := 28.0
var drawer_opened := false
var settings: Dictionary = {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}

var _scroll: ScrollContainer
var _content: VBoxContainer
var _auto_btn: Button
var _cs18_card: PanelContainer
var _cs18_status: Label

const TEAM_ROSTER := [
	{"role": "Leader · Build (UI/UX and player-facing systems)", "name": "Nafis Mohtasim Ramim (2405167-hub)"},
	{"role": "Design and build (producer, art and media lead, integrator)", "name": "Khandaker Shadman Sakib Siddiquee (SadManQT)"},
	{"role": "Research (science and accessibility review)", "name": "Md. Asif Iqbal"},
	{"role": "Research (QA and playtest lead)", "name": "Abu Sayem Mohammed Tanvir (SayemTanvir)"},
	{"role": "Presenter · Build (story and 3D modelling)", "name": "Shahariar Rahman Shanto (ShantoNull11)"},
	{"role": "Build (gameplay runtime, Moon systems and builds)", "name": "MD ATIK KHAN (ProgrammerAtik)"}
]

const NASA_DATASETS := [
	"DONKI space-weather records, Sep 2017 and Jul 2012 — NASA GSFC Community Coordinated Modeling Center",
	"STEREO-A IMPACT/HET proton flux — NASA SPDF CDAWeb",
	"LRO CRaTER daily dose rates — CRaTER team, University of New Hampshire; NASA PDS PPI",
	"LRO LOLA polar illumination & topography (Mazarico et al. 2011) — NASA GSFC",
	"JPL Horizons ephemerides (Sun and Earth from the south pole and Mons Malapert) — NASA JPL",
	"Lunar eclipse catalog 2001–2100 (F. Espenak) — NASA GSFC",
	"Life Support Baseline Values and Assumptions Document, Rev 2 (2022) — NASA JSC",
	"Relocatable 10 kW Solar Array & Vertical Solar Array Technology — NASA LaRC",
	"Protecting Astronauts from Space Radiation on the Lunar Surface (Clowdsley 2021) — NASA LaRC",
	"Apollo shallow moonquake catalog (Nakamura 1979) — NASA PDS Geosciences Node",
	"Lunar Impact Monitoring — NASA MSFC Meteoroid Environment Office",
	"LCROSS (Colaprete et al. 2010) — NASA ARC",
	"LRO Diviner (Paige et al. 2010) — NASA LRO / UCLA",
	"VIPER rover slope and instrument specifications — NASA",
	"Open Science Data Repository, OSD-59 and OSD-412 (Brassica rapa on the ISS) — NASA GeneLab",
	"Seed-to-seed Brassica rapa on Mir (Musgrave et al.) — NASA NTRS",
	"Lunar pole illumination and communications maps (Bryant 2009) — NASA JPL IPN"
]

func _ready() -> void:
	name = "CreditsPanel"
	if embedded:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	if bool(settings.get("reduced_motion", false)):
		auto_scroll = false
	_build_ui()

func _process(delta: float) -> void:
	if auto_scroll and _scroll != null and is_visible_in_tree() and not bool(settings.get("reduced_motion", false)):
		if absf(float(_scroll.scroll_vertical) - _scroll_position) > 2.0:
			_scroll_position = float(_scroll.scroll_vertical)
		_scroll_position += scroll_speed_px_s * delta
		_scroll.scroll_vertical = int(_scroll_position)

func populate_into(container: VBoxContainer) -> void:
	_scroll = container.get_parent() as ScrollContainer
	var controls := HFlowContainer.new()
	container.add_child(controls)
	_build_controls(controls)
	_build_sections_into(container)

func skip_to_post_credits() -> void:
	auto_scroll = false
	if _auto_btn != null:
		_auto_btn.text = "Auto-Scroll: OFF"
	if _scroll != null and _cs18_card != null:
		_scroll.ensure_control_visible(_cs18_card)

func inspect_closed_drawer() -> void:
	drawer_opened = true
	if _cs18_status != null:
		_cs18_status.text = "CS-18 · THE CLOSED DRAWER: Inside the archive bench sits an unopened folder stamped 'MARS TRANSIT STUDY — HOLD FOR ACT TWO'. You leave it closed and return to the living garden."
	closed_drawer_inspected.emit()

func _build_ui() -> void:
	var glass := UiDesign.glass_panel()
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(glass)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	glass.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	stack.add_child(header)
	var title := UiDesign.label("Credits · Last Light Academy", "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_build_controls(header)

	_scroll = ScrollContainer.new()
	_scroll.name = "CreditsScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	stack.add_child(_scroll)

	_content = VBoxContainer.new()
	_content.name = "CreditsContent"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	_scroll.add_child(_content)

	_build_sections_into(_content)
	UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if bool(settings.get("large_text", false)) else 1.0)

func _build_controls(header: Container) -> void:
	_auto_btn = UiDesign.button("Auto-Scroll: ON" if auto_scroll else "Auto-Scroll: OFF")
	_auto_btn.name = "ToggleAutoScroll"
	_auto_btn.pressed.connect(func() -> void:
		auto_scroll = not auto_scroll
		_auto_btn.text = "Auto-Scroll: ON" if auto_scroll else "Auto-Scroll: OFF"
	)
	header.add_child(_auto_btn)

	var skip_btn := UiDesign.button("Skip to Post-Credits (CS-18)")
	skip_btn.name = "SkipCreditsButton"
	skip_btn.pressed.connect(skip_to_post_credits)
	header.add_child(skip_btn)

	var garden_btn := UiDesign.button("Return to Garden")
	garden_btn.name = "ReturnToGardenButton"
	garden_btn.pressed.connect(func() -> void:
		return_to_garden_requested.emit()
		panel_closed.emit()
	)
	header.add_child(garden_btn)

func _build_sections_into(target: VBoxContainer) -> void:
	# Photo + Dedication card
	var ded_card := UiDesign.glass_panel(UiDesign.colour("accent"))
	ded_card.name = "PhotoDedicationCard"
	target.add_child(ded_card)
	var ded_box := VBoxContainer.new()
	ded_box.add_theme_constant_override("separation", 6)
	ded_card.add_child(ded_box)
	ded_box.add_child(UiDesign.label("ARCHIVAL PHOTOGRAPH · ALO, TARA & THE FIRST LUNAR COTTON FLOWER", "heading", "accent"))
	ded_box.add_child(UiDesign.label("Dedicated to every student, teacher and mission operator who tends life in hard places.", "body"))

	# 1. Team The Last BrainCell (from docs/TEAM.md)
	var s1 := UiDesign.glass_panel()
	s1.name = "CreditsSection1_Team"
	target.add_child(s1)
	var b1 := VBoxContainer.new()
	b1.add_theme_constant_override("separation", 4)
	s1.add_child(b1)
	b1.add_child(UiDesign.label("1. Team The Last BrainCell (Dhaka · NASA Space Apps Challenge 2026)", "heading", "accent"))
	for member in TEAM_ROSTER:
		b1.add_child(UiDesign.label("• %s — %s" % [String(member.name), String(member.role)], "body"))

	# 2. Story, characters, puzzles and science mapping
	var s2 := UiDesign.glass_panel()
	s2.name = "CreditsSection2_Story"
	target.add_child(s2)
	var b2 := VBoxContainer.new()
	b2.add_theme_constant_override("separation", 4)
	s2.add_child(b2)
	b2.add_child(UiDesign.label("2. Story, Characters, Puzzles and Science Mapping", "heading", "accent"))
	b2.add_child(UiDesign.label("The story (96 scenes), characters, dialogue, puzzle rules and numbers, science mapping, art direction and every approval are the work of Team The Last BrainCell.", "body"))

	# 3. Data — Built on NASA open data
	var s3 := UiDesign.glass_panel()
	s3.name = "CreditsSection3_Data"
	target.add_child(s3)
	var b3 := VBoxContainer.new()
	b3.add_theme_constant_override("separation", 4)
	s3.add_child(b3)
	b3.add_child(UiDesign.label("3. Built on NASA Open Data", "heading", "accent"))
	for ds in NASA_DATASETS:
		b3.add_child(UiDesign.label("• " + ds, "caption"))
	b3.add_child(UiDesign.label("With data from NOAA, USGS/IAU, ESA, ISRO, JAXA, CNSA and the Wisconsin Fast Plants Program.", "body", "good"))

	# 4. Made with AI tools
	var s4 := UiDesign.glass_panel()
	s4.name = "CreditsSection4_AI"
	target.add_child(s4)
	var b4 := VBoxContainer.new()
	b4.add_theme_constant_override("separation", 4)
	s4.add_child(b4)
	b4.add_child(UiDesign.label("4. Made with AI Tools", "heading", "accent"))
	b4.add_child(UiDesign.label("Tripo AI, Meshy, ElevenLabs, Google Nano Banana Pro, ByteDance Seedance 2.5, Google Veo 3.1, OpenAI GPT Image 2.5, Topaz Image Upscale, Claude Code, OpenAI Codex — every generation is logged with its prompt; see docs/AI_USE.md.", "body"))

	# 5. Engine — Made with Godot Engine + runtime license & copyright info
	var s5 := UiDesign.glass_panel()
	s5.name = "CreditsSection5_Engine"
	target.add_child(s5)
	var b5 := VBoxContainer.new()
	b5.add_theme_constant_override("separation", 4)
	s5.add_child(b5)
	b5.add_child(UiDesign.label("5. Made with Godot Engine", "heading", "accent"))
	var license_text := Engine.get_license_text().strip_edges()
	var copy_info := Engine.get_copyright_info()
	b5.add_child(UiDesign.label("Godot Engine MIT Licence (%d third-party copyright notices loaded at runtime; includes Open Sans SIL OFL 1.1):\n%s" % [copy_info.size(), license_text], "caption", "muted"))

	# 6. Tools
	var s6 := UiDesign.glass_panel()
	s6.name = "CreditsSection6_Tools"
	target.add_child(s6)
	var b6 := VBoxContainer.new()
	b6.add_theme_constant_override("separation", 4)
	s6.add_child(s6_box(b6))

	# 7. Disclaimer
	var s7 := UiDesign.glass_panel()
	s7.name = "CreditsSection7_Disclaimer"
	target.add_child(s7)
	var b7 := VBoxContainer.new()
	b7.add_theme_constant_override("separation", 4)
	s7.add_child(b7)
	b7.add_child(UiDesign.label("7. Disclaimer", "heading", "accent"))
	var disc := UiDesign.label("Aurora Station, the cadets and Alo are fiction. The 2017 storm is a historical replay; the 2012 storm is a what-if. NASA does not endorse this game.", "body")
	disc.name = "CreditsDisclaimerText"
	b7.add_child(disc)

	# Post-credits CS-18 still: "The Closed Drawer" (optional MARS drawer; no forced teaser)
	_cs18_card = UiDesign.glass_panel(UiDesign.colour("accent"))
	_cs18_card.name = "PostCreditsCS18Card"
	target.add_child(_cs18_card)
	var cs_box := VBoxContainer.new()
	cs_box.add_theme_constant_override("separation", 6)
	_cs18_card.add_child(cs_box)
	cs_box.add_child(UiDesign.label("Post-Credits Still · CS-18 · The Closed Drawer", "heading", "accent"))
	_cs18_status = UiDesign.label("Act One is complete in the Aurora greenhouse. A quiet metal drawer under the archive bench is marked 'MARS'. Opening it is optional; there is no forced cliffhanger.", "body")
	_cs18_status.name = "CS18StatusLabel"
	cs_box.add_child(_cs18_status)
	var drawer_btn := UiDesign.button("Optional: Inspect the MARS Drawer (CS-18)")
	drawer_btn.name = "InspectMarsDrawerButton"
	drawer_btn.pressed.connect(inspect_closed_drawer)
	cs_box.add_child(drawer_btn)

func s6_box(b6: VBoxContainer) -> VBoxContainer:
	b6.add_child(UiDesign.label("6. Tools", "heading", "accent"))
	b6.add_child(UiDesign.label("Blender, FFmpeg, Python standard library.", "body"))
	return b6
