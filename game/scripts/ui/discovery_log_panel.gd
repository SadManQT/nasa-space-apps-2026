extends Control
class_name DiscoveryLogPanel

## M3-90 (UI_08_DISCOVERY_LOG.md): Discovery Log screen/component connected to
## the shared campaign.
## - Evidence cards with Observed, Verified, Inferred, Unknown and Linked badges + timestamps
## - Pin source beside reconstruction; automatically records required evidence
## - Optional scans never block story; spoilers gated by scene knowledge ("Noor"
##   and "Rahman" never appear before EX-CH05-S10; until then she is "N.")

signal panel_closed
signal source_pinned(evidence_id: String, source_id: String)

var scene_id := "EX-CH01-S01"
var pinned_id := ""
var pinned_entry: Dictionary = {}
var filter_status := "ALL"
var settings: Dictionary = {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}

var _evidence_rows: Array = []
var _filter_bar: HBoxContainer
var _list_box: VBoxContainer
var _pin_box: VBoxContainer
var _status_label: Label

const DEFAULT_EVIDENCE := [
	{
		"id": "EV-CH01-LEAF",
		"title": "Chamber One Probe Calibration",
		"status": "VERIFIED",
		"badge": "• VERIFIED · OBSERVED",
		"timestamp": "2046-04-11 21:55 UTC",
		"unlock_scene": "EX-CH01-S02",
		"source": "Chamber One Calibration Log (P-01)",
		"body": "Zero offset +0.2 °C and reference check 22.0 °C verified before trusting the 22.0 °C leaf probe.",
		"linked": ["Alo Commissioning Record"],
		"required": true,
	},
	{
		"id": "EV-CH01-NOTE",
		"title": "Initialed Margin Note ('N.')",
		"status": "OBSERVED",
		"badge": "• OBSERVED · LINKED",
		"timestamp": "2046-04-11 22:15 UTC",
		"unlock_scene": "EX-CH01-S04",
		"source": "Greenhouse Growth Notebook (2034 Archive)",
		"body": "Handwritten note signed 'N.' in the 2034 margin: 'Keep the reserve warm before the dark shifts close.'",
		"body_after_ch05_s10": "Handwritten note by Dr. Noor Rahman ('N.') in the 2034 margin: 'Keep the reserve warm before the dark shifts close.'",
		"linked": ["Recorder Strip Reconstruction"],
		"required": true,
	},
	{
		"id": "EV-CH02-RECORDER",
		"title": "Five-Frame Recorder Strip (2034)",
		"status": "VERIFIED",
		"badge": "• VERIFIED · LINKED",
		"timestamp": "2046-04-13 10:20 UTC",
		"unlock_scene": "EX-CH02-S08",
		"source": "Annex Recorder 2034 (P-04)",
		"body": "Five chronological frames show N. sealing the annex drum and logging the cold-trap bearing before ascent.",
		"body_after_ch05_s10": "Five chronological frames show Dr. Noor Rahman sealing the annex drum and logging the cold-trap bearing before ascent.",
		"linked": ["Initialed Margin Note ('N.')", "Cold-Trap Vault Map"],
		"required": true,
	},
	{
		"id": "EV-CH03-PODS",
		"title": "Forty-Two Mature Pods Counted",
		"status": "VERIFIED",
		"badge": "• VERIFIED · OBSERVED",
		"timestamp": "2046-04-18 14:40 UTC",
		"unlock_scene": "EX-CH03-S09",
		"source": "Greenhouse Harvest Ledger (P-06)",
		"body": "30 founder seeds sealed for the cold-trap vault reserve; 12 active seeds assigned to the next planting tray.",
		"linked": ["Cold-Trap Vault Canister"],
		"required": true,
	},
	{
		"id": "EV-CH04-VAULT",
		"title": "Cold-Trap Vault Canister (−183 °C)",
		"status": "VERIFIED",
		"badge": "• VERIFIED · LINKED",
		"timestamp": "2046-04-22 16:10 UTC",
		"unlock_scene": "EX-CH04-S10",
		"source": "Shackleton Shelf Vault (P-08)",
		"body": "Warmed from −183 °C to +18 °C before unsealing; holds the 2034 cotton seed packet left by N.",
		"body_after_ch05_s10": "Warmed from −183 °C to +18 °C before unsealing; holds the 2034 cotton seed packet left by Dr. Noor Rahman.",
		"linked": ["Five-Frame Recorder Strip (2034)"],
		"required": true,
	},
	{
		"id": "EV-CH05-IDENTITY",
		"title": "Expedition Zero Botanist Identity",
		"status": "UNKNOWN",
		"badge": "• UNKNOWN",
		"timestamp": "2046-04-13 11:00 UTC",
		"unlock_scene": "EX-CH02-S01",
		"source": "Archive Personnel Index",
		"body": "The 2034 botanist signed her notes 'N.' — full name not yet verified in the recovered logs.",
		"status_after_ch05_s10": "VERIFIED",
		"badge_after_ch05_s10": "• VERIFIED · LINKED",
		"body_after_ch05_s10": "Verified at EX-CH05-S10: 'N.' is Dr. Noor Rahman, Expedition Zero botanist who preserved the founder seeds.",
		"linked": ["Initialed Margin Note ('N.')"],
		"required": true,
	},
	{
		"id": "EV-OPT-REGOLITH",
		"title": "Optional Ridge Regolith Scan",
		"status": "INFERRED",
		"badge": "• INFERRED · OPTIONAL SCAN",
		"timestamp": "2046-04-22 12:05 UTC",
		"unlock_scene": "EX-CH01-S01",
		"source": "Field Scanner Pulse (Optional)",
		"body": "Agglutinate glass fraction suggests mature highland regolith; optional field scan never blocks story progress.",
		"linked": [],
		"required": false,
	}
]

func _ready() -> void:
	name = "DiscoveryLogPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	_build_ui()
	configure(scene_id)

static func is_noor_revealed(current_scene_id: String) -> bool:
	# Canon gate: "Noor" and "Rahman" never appear before EX-CH05-S10.
	if not current_scene_id.begins_with("EX-CH"):
		return false
	var parts := current_scene_id.trim_prefix("EX-CH").split("-S")
	if parts.size() < 2:
		return false
	var ch := int(parts[0])
	var sc := int(parts[1])
	return ch > 5 or (ch == 5 and sc >= 10)

func configure(current_scene_id: String, extra_entries: Array = []) -> void:
	scene_id = current_scene_id if not current_scene_id.is_empty() else "EX-CH01-S01"
	var reveal := is_noor_revealed(scene_id)
	_evidence_rows.clear()
	for raw in DEFAULT_EVIDENCE + extra_entries:
		if not (raw is Dictionary):
			continue
		var entry: Dictionary = (raw as Dictionary).duplicate(true)
		if reveal and entry.has("body_after_ch05_s10"):
			entry["body"] = entry["body_after_ch05_s10"]
		if reveal and entry.has("status_after_ch05_s10"):
			entry["status"] = entry["status_after_ch05_s10"]
		if reveal and entry.has("badge_after_ch05_s10"):
			entry["badge"] = entry["badge_after_ch05_s10"]
		if not reveal:
			entry["title"] = String(entry.get("title", "")).replace("Noor", "N.").replace("Rahman", "")
			entry["body"] = String(entry.get("body", "")).replace("Noor", "N.").replace("Rahman", "")
		_evidence_rows.append(entry)
	if pinned_id.is_empty() and not _evidence_rows.is_empty():
		pin_source(String(_evidence_rows[0].get("id", "")))
	else:
		_refresh()

func pin_source(evidence_id: String) -> Dictionary:
	for row in _evidence_rows:
		if String(row.get("id", "")) == evidence_id:
			pinned_id = evidence_id
			pinned_entry = row.duplicate(true)
			source_pinned.emit(evidence_id, String(row.get("source", "")))
			_refresh()
			return pinned_entry
	return {}

func set_filter(status_key: String) -> void:
	filter_status = status_key.to_upper()
	_refresh()

func _build_ui() -> void:
	var glass := UiDesign.glass_panel()
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(glass)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	glass.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	stack.add_child(header)
	var title := UiDesign.label("Discovery Log · Evidence & Source Reconstruction", "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := UiDesign.button("Close (Esc)")
	close_btn.name = "CloseDiscoveryLog"
	close_btn.pressed.connect(func() -> void: panel_closed.emit())
	header.add_child(close_btn)

	_status_label = UiDesign.label("Required evidence records automatically. Optional scans never block story progress.", "caption", "accent")
	stack.add_child(_status_label)

	_filter_bar = HBoxContainer.new()
	_filter_bar.name = "DiscoveryFilterBar"
	_filter_bar.add_theme_constant_override("separation", 8)
	stack.add_child(_filter_bar)
	for f in ["ALL", "OBSERVED", "VERIFIED", "INFERRED", "UNKNOWN"]:
		var btn := UiDesign.button(f.capitalize())
		btn.name = "Filter_" + f
		btn.pressed.connect(func() -> void: set_filter(f))
		_filter_bar.add_child(btn)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	stack.add_child(split)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.name = "EvidenceListBox"
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_list_box)

	var pin_panel := UiDesign.glass_panel(UiDesign.colour("accent"))
	pin_panel.name = "PinnedSourceBesideReconstruction"
	pin_panel.custom_minimum_size = Vector2(400, 0)
	split.add_child(pin_panel)

	_pin_box = VBoxContainer.new()
	_pin_box.add_theme_constant_override("separation", 8)
	pin_panel.add_child(_pin_box)

func _refresh() -> void:
	if _list_box == null or _pin_box == null:
		return
	for c in _list_box.get_children():
		_list_box.remove_child(c)
		c.queue_free()
	for c in _pin_box.get_children():
		_pin_box.remove_child(c)
		c.queue_free()

	for row in _evidence_rows:
		var st := String(row.get("status", "OBSERVED")).to_upper()
		if filter_status != "ALL" and st != filter_status:
			continue
		var eid := String(row.get("id", ""))
		var card := UiDesign.glass_panel(UiDesign.colour("accent" if eid == pinned_id else "border"))
		card.name = "EvidenceCard_" + eid
		_list_box.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		card.add_child(box)
		box.add_child(UiDesign.label(String(row.get("title", "")), "heading"))
		box.add_child(UiDesign.label("%s  ·  %s" % [String(row.get("badge", "• OBSERVED")), String(row.get("timestamp", ""))], "caption", "accent"))
		box.add_child(UiDesign.label(String(row.get("body", "")), "body"))
		var linked: Array = row.get("linked", [])
		if not linked.is_empty():
			box.add_child(UiDesign.label("Linked: " + " · ".join(linked), "caption", "muted"))
		var pin_btn := UiDesign.button("Pin Source Beside Reconstruction")
		pin_btn.name = "Pin_" + eid
		pin_btn.pressed.connect(func() -> void: pin_source(eid))
		box.add_child(pin_btn)

	_pin_box.add_child(UiDesign.label("Pinned Source & Reconstruction", "heading", "accent"))
	if pinned_entry.is_empty():
		_pin_box.add_child(UiDesign.label("Select any evidence card on the left to pin its source beside your reconstruction.", "body", "muted"))
	else:
		_pin_box.add_child(UiDesign.label(String(pinned_entry.get("title", "")), "heading"))
		_pin_box.add_child(UiDesign.label("Source: " + String(pinned_entry.get("source", "")), "body", "good"))
		_pin_box.add_child(UiDesign.label("Timestamp: " + String(pinned_entry.get("timestamp", "")), "caption", "muted"))
		_pin_box.add_child(UiDesign.label("Status Badge: " + String(pinned_entry.get("badge", "")), "caption", "accent"))
		_pin_box.add_child(UiDesign.label(String(pinned_entry.get("body", "")), "body"))
		var req := bool(pinned_entry.get("required", true))
		_pin_box.add_child(UiDesign.label(
			"Recorded automatically in campaign log." if req else "Optional field scan — never blocks story progression.",
			"caption",
			"muted"
		))
	UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if bool(settings.get("large_text", false)) else 1.0)
