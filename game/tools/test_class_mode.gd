## Class mode (M1-37): the Solo / Class crew setting, private crew notes with a
## privacy hand-off, sharing only after a private read, and the team plan
## where every role signs the exact plan before the operator locks it in.
## Solo keeps every note public and its one-step confirmation.
extends SceneTree

const CrewScript = preload("res://scripts/crew/crew_modes.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const TableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/mission_table_panel.tscn")
const HandoffScene: PackedScene = preload("res://scenes/ui/role_card_handoff.tscn")
const MenuScene: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const CLASS4 := {"mode": "class", "players": 4}
const SOLO := {"mode": "solo", "players": 1}
const KAI_FACT := "The battery holds 20."
const AMARA_QUOTE := "We can keep air we make now."

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	_test_crew_data()
	_test_state_validation()
	_test_table_receipts_and_sign_offs()
	_test_persistence()
	await _test_handoff_control()
	await _test_panel_class_mode()
	await _test_panel_solo_unchanged()
	await _test_main_menu_choice()
	await _test_campaign_integration()
	print("CLASS MODE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

# --- Data --------------------------------------------------------------------

func _test_crew_data() -> void:
	var data: Dictionary = CrewScript.data()
	_check(not data.is_empty() and int(data.schema_version) == 1, "crew_modes.json loads with schema 1")
	_check(CrewScript.default_crew() == SOLO, "the default crew is Solo with one player")
	_check(not CrewScript.problem({}).is_empty() and not CrewScript.problem("x").is_empty(), "an empty or non-Dictionary crew is rejected")
	_check(CrewScript.problem(CLASS4).is_empty() and CrewScript.problem({"mode": "class", "players": 2}).is_empty(), "Class takes 2 to 4 players")
	_check(not CrewScript.problem({"mode": "class", "players": 1}).is_empty() and not CrewScript.problem({"mode": "class", "players": 5}).is_empty(), "Class rejects 1 and 5 players")
	_check(not CrewScript.problem({"mode": "solo", "players": 2}).is_empty(), "Solo is one player")
	_check(not CrewScript.problem({"mode": "network", "players": 4}).is_empty(), "no network mode exists or is implied")
	_check(not CrewScript.problem({"mode": "class", "players": 2.5}).is_empty(), "a fractional player count is rejected")
	_check(CrewScript.normalise({"mode": "class"}) == {"mode": "class", "players": 2} and CrewScript.normalise("x") == SOLO and CrewScript.normalise({"mode": "class", "players": 9}) == CLASS4, "normalise fills the minimum, clamps the maximum and falls back to Solo")
	for players in [2, 3, 4]:
		var crew := {"mode": "class", "players": players}
		var seats: Array = CrewScript.seats(crew)
		var covered: Array = []
		var mei_with_rafi := false
		for seat in seats:
			for role_id in seat.role_ids:
				covered.append(role_id)
			if seat.role_ids.has("mei") and seat.role_ids.has("rafi"):
				mei_with_rafi = true
		covered.sort()
		_check(seats.size() == players and covered == ["amara", "kai", "mei", "rafi"], "%d players: every role sits exactly once" % players)
		_check(not mei_with_rafi, "%d players: Mei and Rafi never share a seat (combined-evidence decision)" % players)
	_check(CrewScript.holder_label(CLASS4, "mei") == "Player 3" and CrewScript.holder_label(SOLO, "mei") == "You", "holder labels name the seat in Class and the player in Solo")
	_check(CrewScript.mode_label(CLASS4) == "CLASS · 4 PLAYERS" and CrewScript.mode_label(SOLO) == "SOLO", "mode labels")
	_check(CrewScript.text("handoff", "reveal_button", {"name": "Kai"}) == "I HOLD KAI'S ROLE · SHOW MY NOTE", "copy substitutions upper-case {NAME}")
	_check(CrewScript.seat_plan_text({"mode": "class", "players": 2}) == "Player 1: Kai and Mei · Player 2: Amara and Rafi", "the two-player seat plan reads as one line")
	var missing: Array = []
	var bangla := false
	for section in ["handoff", "table", "team_plan", "menu", "settings", "print"]:
		for key in data.get(section, {}):
			var value = data[section][key]
			var texts: Array = value if value is Array else [value]
			for text in texts:
				if not text is String or String(text).strip_edges().is_empty():
					missing.append(section + "." + String(key))
				for index in String(text).length():
					var code := String(text).unicode_at(index)
					if code >= 0x0980 and code <= 0x09FF:
						bangla = true
	_check(missing.is_empty(), "every copy line in crew_modes.json is a non-empty string " + str(missing))
	_check(not bangla, "no Bangla script in the crew copy (English only)")
	_check(CrewScript.role_color("kai") != CrewScript.role_color("mei"), "roles carry distinct accents")

func _test_state_validation() -> void:
	var plain: Dictionary = StateScript.new_snapshot()
	_check(bool(StateScript.validate_snapshot(plain).valid) and StateScript.crew_of(plain) == SOLO, "a snapshot without a crew setting is valid and reads as Solo")
	var with_crew: Dictionary = StateScript.new_snapshot()
	with_crew["crew"] = CLASS4
	_check(bool(StateScript.validate_snapshot(with_crew).valid) and StateScript.crew_of(with_crew) == CLASS4, "a Class crew setting validates and reads back")
	with_crew["crew"] = {"mode": "class", "players": 7}
	_check(not bool(StateScript.validate_snapshot(with_crew).valid), "an out-of-range crew setting is rejected")
	with_crew["crew"] = "class"
	_check(not bool(StateScript.validate_snapshot(with_crew).valid), "a non-Dictionary crew setting is rejected")
	var director := DirectorScript.new()
	director.new_campaign()
	var next: Dictionary = director.snapshot()
	next["crew"] = CLASS4
	_check(bool(director.restore_snapshot(next).accepted) and director.snapshot().get("crew", {}) == CLASS4, "the director keeps the crew setting")
	var service := SaveScript.new()
	var migrated: Dictionary = service.migrate(director.snapshot())
	_check(bool(migrated.accepted) and migrated.snapshot.get("crew", {}) == CLASS4, "the save service accepts and keeps the crew setting")

# --- Model -------------------------------------------------------------------

func _test_table_receipts_and_sign_offs() -> void:
	var table := TableScript.new()
	_check(table.role_cards(0).all(func(card): return not bool(card.read)), "no note starts read")
	_check(not bool(table.mark_read("rafi", 0).accepted), "a note that has not arrived cannot be read")
	var first: Dictionary = table.mark_read("kai", 0)
	var again: Dictionary = table.mark_read("kai", 0)
	_check(bool(first.accepted) and not bool(first.duplicate) and bool(again.duplicate), "a private read is recorded once; a repeat is a no-op")
	_check(not bool(table.share("amara", 0, true).accepted), "Class sharing needs a private read first")
	_check(bool(table.share("amara", 0).accepted), "Solo sharing does not need a read receipt")
	table.mark_read("amara", 0)
	_check(bool(table.share("amara", 0, true).accepted) and bool(table.share("amara", 0, true).duplicate), "after a read, Class sharing works and repeats are no-ops")
	var blocked: Dictionary = table.sign_off("kai", "p02_shift1", 0)
	_check(not bool(blocked.accepted) and String(blocked.reason).begins_with("Choose"), "nobody can sign an incomplete plan")
	table.set_choice(1, "air_production", 2)
	table.set_choice(1, "light", "FULL")
	table.set_choice(1, "transfer", "HOLD")
	var signed: Dictionary = table.sign_off("kai", "p02_shift1", 0)
	_check(bool(signed.accepted) and table.signed_roles("p02_shift1", 0) == ["kai"] and bool(table.sign_off("kai", "p02_shift1", 0).duplicate), "a role signs the complete plan once")
	_check(not bool(table.sign_off("zed", "p02_shift1", 0).accepted), "an unknown role cannot sign")
	for role_id in ["amara", "mei", "rafi"]:
		table.sign_off(role_id, "p02_shift1", 0)
	_check(table.signed_roles("p02_shift1", 0) == ["kai", "amara", "rafi", "mei"], "all four signatures are listed in card order")
	table.set_choice(1, "light", "DIM")
	_check(table.signed_roles("p02_shift1", 0).is_empty() and table.stale_sign_offs("p02_shift1", 0).size() == 4, "changing the plan makes every signature stale")
	table.sign_off("mei", "p02_shift1", 0)
	_check(table.signed_roles("p02_shift1", 0) == ["mei"] and table.stale_sign_offs("p02_shift1", 0).size() == 3, "signing the changed plan replaces that role's old signature")
	_check(table.plan_key("p02_shift1", 0) != table.plan_key("p02_shift1", 1), "a retry (different committed shift) changes the plan key")
	var record: Dictionary = table.communication_record()
	_check(record.read == ["kai", "amara"] and record.shared == ["amara"] and record.sign_offs.size() == 4, "the communication record separates read, shared and signed")
	table.clear_sign_offs()
	_check(table.signed_roles("p02_shift1", 0).is_empty() and table.stale_sign_offs("p02_shift1", 0).is_empty() and table.communication_record().read.size() == 2, "clearing signatures keeps the read receipts")

func _test_persistence() -> void:
	var table := TableScript.new()
	table.apply_worked_plan("bloom")
	table.mark_read("kai", 0)
	table.sign_off("kai", "p02_shift1", 0)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(table.snapshot()))
	var restored := TableScript.new()
	_check(bool(restored.restore(saved).accepted) and restored.snapshot() == table.snapshot() and restored.signed_roles("p02_shift1", 0) == ["kai"], "read receipts and signatures survive a JSON round trip")
	var legacy := saved.duplicate(true)
	legacy.erase("read")
	legacy.erase("sign_offs")
	var older := TableScript.new()
	_check(bool(older.restore(legacy).accepted) and older.communication_record().read.is_empty() and older.signed_roles("p02_shift1", 0).is_empty(), "a save from before Class mode restores with empty receipts")
	var bad_read := saved.duplicate(true)
	bad_read.read = {"kai": "yes"}
	var bad_sign := saved.duplicate(true)
	bad_sign.sign_offs = {"kai": 7}
	_check(not bool(TableScript.new().restore(bad_read).accepted) and not bool(TableScript.new().restore(bad_sign).accepted), "invalid receipt types are rejected")
	var route := RouteScript.new(DirectorScript.new())
	route.mission_table().apply_worked_plan("bloom")
	route.mission_table().mark_read("amara", 0)
	route.mission_table().sign_off("amara", "p02_shift1", 0)
	var resumed := RouteScript.new(DirectorScript.new())
	resumed.director().restore_snapshot(JSON.parse_string(JSON.stringify(route.director().snapshot())))
	_check(bool(resumed.restore(JSON.parse_string(JSON.stringify(route.snapshot()))).accepted) and resumed.mission_table().communication_record() == route.mission_table().communication_record(), "the route carries the receipts through its own snapshot")

# --- Hand-off control -------------------------------------------------------

func _test_handoff_control() -> void:
	var handoff := HandoffScene.instantiate() as RoleCardHandoff
	root.add_child(handoff)
	await process_frame
	var reads: Array = []
	var finished: Array = []
	var cancelled := [0]
	handoff.card_read.connect(func(role_id: String) -> void: reads.append(role_id))
	handoff.finished.connect(func(read: Array) -> void: finished.append(read))
	handoff.cancelled.connect(func() -> void: cancelled[0] += 1)
	_check(not handoff.open([], CLASS4) and not handoff.is_open(), "nothing to pass round keeps the hand-off closed")
	var cards: Array = TableScript.new().role_cards(0).filter(func(card): return bool(card.arrived))
	_check(handoff.open(cards, CLASS4) and handoff.is_open(), "the hand-off opens with the delivered notes")
	await process_frame
	var state: Dictionary = handoff.state()
	var cover := _text(handoff)
	_check(state.stage == "cover" and state.role_id == "kai" and state.total == 2, "it starts on Kai's cover")
	_check(cover.contains("Player 1") and cover.contains("look away") and not cover.contains(KAI_FACT) and handoff.find_child("Fact", true, false) == null, "the cover names the holder and shows no fact")
	_check((handoff.get_node("PrivacyBackdrop") as ColorRect).color.a >= 0.95, "the backdrop is opaque enough to hide the table behind it")
	_check(bool(handoff.reveal().accepted) and reads == ["kai"], "reveal records a read receipt for Kai")
	await process_frame
	_check(_text(handoff).contains(KAI_FACT) and handoff.state().stage == "reveal", "the revealed note shows Kai's facts")
	var hidden: Dictionary = handoff.hide_card()
	await process_frame
	_check(bool(hidden.accepted) and not bool(hidden.finished) and handoff.state().role_id == "amara" and _text(handoff).contains("Player 2") and not _text(handoff).contains(AMARA_QUOTE), "hiding moves to Amara's cover without her note")
	handoff.reveal()
	var last: Dictionary = handoff.hide_card()
	_check(bool(last.finished) and finished == [["kai", "amara"]] and not handoff.is_open(), "hiding the last note finishes with the read list")
	handoff.open(cards, CLASS4)
	handoff.cancel()
	_check(cancelled[0] == 1 and not handoff.is_open(), "NOT NOW on a cover cancels without a read")
	handoff.open(cards, CLASS4)
	await process_frame
	var space := InputEventKey.new()
	space.pressed = true
	space.physical_keycode = KEY_SPACE
	handoff._input(space)
	_check(handoff.state().stage == "reveal", "Space reveals the note for the holder")
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.physical_keycode = KEY_ESCAPE
	handoff._input(escape)
	_check(handoff.state().stage == "cover" and handoff.state().role_id == "amara", "Esc hides a shown note and passes on")
	handoff._input(escape)
	_check(not handoff.is_open() and finished.size() == 2, "Esc on a cover leaves; notes already read stay read")
	handoff.open(cards, CLASS4, {"large_text": true})
	await process_frame
	var reveal_button := handoff.find_child("Reveal", true, false) as Button
	_check(reveal_button != null and reveal_button.get_theme_font_size("font_size") >= 21 and reveal_button.size.y >= 44.0, "large text scales the hand-off controls; targets stay at least 44 px")
	handoff.cancel()
	handoff.free()

# --- Mission Table panel ---------------------------------------------------

func _test_panel_class_mode() -> void:
	var route := RouteScript.new(DirectorScript.new())
	_reach(route, "EX-CH01-S07")
	route.perform("role_cards")
	var panel := PanelScene.instantiate() as MissionTablePanel
	root.add_child(panel)
	var emitted: Array = []
	panel.commit_requested.connect(func(target_id: String, plan: Dictionary) -> void: emitted.append([target_id, plan]))
	panel.open(route, "p02_shift1", {"large_text": false, "timer_free": true, "crew": CLASS4})
	await process_frame
	var chip := panel.find_child("CrewModeChip", true, false) as Label
	_check(chip != null and chip.text.contains("CLASS · 4 PLAYERS"), "the table shows the Class mode chip")
	var public := _text(panel)
	_check(not public.contains(KAI_FACT) and not public.contains(AMARA_QUOTE), "Class mode keeps every fact and quote off the shared table")
	_check(public.contains("PLAYER 1") and public.contains("NOT READ YET"), "each note names its holder and read state")
	_check(panel.find_child("Read_kai", true, false) != null and panel.find_child("Share_kai", true, false) == null, "an unread note offers READ PRIVATELY, not sharing")
	var refused: Dictionary = panel.share_card("kai")
	_check(not bool(refused.accepted) and String(refused.reason).contains("Player 1"), "sharing an unread note is refused and names the holder")
	_check(panel.read_card("kai") and panel.handoff().is_open() and _text(panel.handoff()).contains("Player 1"), "READ PRIVATELY opens the hand-off cover for Kai's holder")
	var commit_before := panel.find_child("Commit", true, false) as Button
	var blocked_space := InputEventKey.new()
	blocked_space.pressed = true
	blocked_space.physical_keycode = KEY_SPACE
	panel._input(blocked_space)
	_check(not panel._confirming, "table keys are ignored while the hand-off is open")
	panel.handoff().reveal()
	_check(bool(route.mission_table().role_cards(0).filter(func(card): return card.role_id == "kai")[0].read), "revealing records the read receipt on the route's table")
	panel.handoff().hide_card()
	await process_frame
	await process_frame
	var status := panel.find_child("Status_kai", true, false) as Label
	_check(status != null and status.text == "✓ READ PRIVATELY" and panel.find_child("Share_kai", true, false) != null, "after the private read the table offers sharing")
	_check(bool(panel.share_card("kai").accepted), "Kai's note can be marked shared after the read")
	await process_frame
	status = panel.find_child("Status_kai", true, false) as Label
	_check(status != null and status.text.begins_with("✓ SHARED") and not _text(panel).contains(KAI_FACT), "a shared note still shows no facts on the shared screen")
	panel.read_card("amara")
	panel.handoff().reveal()
	panel.handoff().hide_card()
	panel.share_card("amara")
	panel.choose(1, "air_production", 2)
	panel.choose(1, "light", "FULL")
	panel.choose(1, "transfer", "HOLD")
	_check(bool(panel.preview().accepted), "the Class plan previews like Solo")
	_check(bool(panel.request_commit().accepted) and panel.find_child("SignOff_kai", true, false) != null and panel.find_child("SignOff_rafi", true, false) != null and panel.find_child("SoloNote", true, false) == null, "commit opens the team plan with one signature per role")
	await process_frame
	var lock := panel.find_child("ConfirmCommit", true, false) as Button
	_check(lock != null and lock.disabled, "the operator lock-in waits for the signatures")
	var early: Dictionary = panel.confirm_commit()
	_check(not bool(early.accepted) and String(early.reason).contains("of 4") and emitted.is_empty(), "the operator cannot lock in before every role signs")
	_check(bool(panel.sign_off("kai").accepted) and (panel.find_child("SignStatus_kai", true, false) as Label).text == "✓ SIGNED", "a role signs from the team plan")
	for role_id in ["amara", "mei", "rafi"]:
		panel.sign_off(role_id)
	await process_frame
	lock = panel.find_child("ConfirmCommit", true, false) as Button
	_check(panel.signed_roles().size() == 4 and lock != null and not lock.disabled, "four signatures enable the operator lock-in")
	panel.cancel_confirm()
	panel.choose(1, "light", "DIM")
	panel.preview()
	panel.request_commit()
	await process_frame
	var stale := panel.find_child("SignStatus_kai", true, false) as Label
	_check(stale != null and stale.text.contains("PLAN CHANGED") and not bool(panel.confirm_commit().accepted), "a changed plan needs fresh signatures")
	for role_id in CrewScript.ROLE_ORDER:
		panel.sign_off(String(role_id))
	var space := InputEventKey.new()
	space.pressed = true
	space.physical_keycode = KEY_SPACE
	panel._input(space)
	_check(emitted.size() == 1 and emitted[0][0] == "p02_shift1" and emitted[0][1] == route.mission_table().plan_for_gate("p02_shift1") and not panel.is_open(), "Space locks in the signed plan once and closes the table")
	_check(int(route.director().query().current_shift) == 0, "the panel itself never commits resources")
	panel.free()

func _test_panel_solo_unchanged() -> void:
	var route := RouteScript.new(DirectorScript.new())
	_reach(route, "EX-CH01-S07")
	route.perform("role_cards")
	var panel := PanelScene.instantiate() as MissionTablePanel
	root.add_child(panel)
	var emitted: Array = []
	panel.commit_requested.connect(func(target_id: String, plan: Dictionary) -> void: emitted.append([target_id, plan]))
	panel.open(route, "p02_shift1", {"large_text": false, "timer_free": true})
	await process_frame
	_check(panel.find_child("CrewModeChip", true, false) == null and _text(panel).contains(KAI_FACT) and panel.find_child("Share_kai", true, false) != null, "Solo shows every delivered fact and shares in one click")
	panel.share_card("kai")
	panel.share_card("amara")
	panel.choose(1, "air_production", 2)
	panel.choose(1, "light", "FULL")
	panel.choose(1, "transfer", "HOLD")
	panel.preview()
	panel.request_commit()
	await process_frame
	_check(panel.find_child("ConfirmCommit", true, false) != null and panel.find_child("SoloNote", true, false) != null and panel.find_child("SignOff_kai", true, false) == null, "Solo keeps the one-step confirmation and says why no sign-off is needed")
	_check(bool(panel.confirm_commit().accepted) and emitted.size() == 1, "Solo confirms without signatures")
	panel.free()

# --- Title ------------------------------------------------------------------

func _test_main_menu_choice() -> void:
	var menu := MenuScene.instantiate() as MainMenu
	root.add_child(menu)
	await process_frame
	var commands: Array = []
	menu.command_emitted.connect(func(command: Dictionary) -> void: commands.append(command))
	_check(menu.crew_settings() == SOLO, "New Expedition defaults to Solo")
	var class3 := menu.find_child("Crew_class_3", true, false) as Button
	_check(class3 != null and class3.custom_minimum_size.y >= 44.0, "the Class 3 choice is a 44 px control")
	class3.pressed.emit()
	await process_frame
	_check(menu.crew_settings() == {"mode": "class", "players": 3} and class3.button_pressed and class3.text.begins_with("● "), "choosing Class 3 selects it with a text cue")
	_check((menu.get("_crew_seats") as Label).text.contains("Player 1: Kai and Amara · Player 2: Mei · Player 3: Rafi"), "the three-player seat plan is shown")
	menu.set_crew({"mode": "bogus", "players": 3})
	_check(menu.crew_settings() == SOLO, "an invalid crew falls back to Solo")
	menu.set_crew(CLASS4)
	menu._show_briefing()
	await process_frame
	await process_frame
	var briefing := menu.get("_briefing") as Control
	_check(briefing != null and Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(briefing.get_global_rect()), "the briefing with the crew choice fits 1280x720")
	(menu.get("_briefing_start_button") as Button).pressed.emit()
	var started: Array = commands.filter(func(command): return String(command.verb) == "new_campaign")
	_check(started.size() == 1 and started[0].payload.get("crew", {}) == CLASS4, "ENTER AURORA carries the crew choice in the new_campaign command")
	menu.free()

# --- Campaign ---------------------------------------------------------------

func _test_campaign_integration() -> void:
	if not storage.setup("test_class_mode"):
		_check(false, "isolated storage for the campaign integration check")
		return
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_crew = CLASS4
	root.add_child(campaign)
	await process_frame
	_check(campaign.query().get("crew", {}) == CLASS4, "a new expedition starts with the chosen crew")
	var button := campaign.hud.get("_crew_button") as Button
	_check(button != null and button.visible and button.text.contains("CLASS · 4 PLAYERS"), "the HUD shows CREW NOTES in Class mode")
	campaign.route.start_at("EX-CH01-S07")
	campaign._sync_route_projection()
	campaign._refresh_world()
	await process_frame
	campaign.route.perform("role_cards")
	campaign.hud.refresh_scene()
	_check(campaign.hud.open_crew_notes() and campaign.hud.crew_cards.is_open() and bool(campaign.director.query().paused), "CREW NOTES passes the delivered notes round and pauses time")
	campaign.hud.crew_cards.reveal()
	campaign.hud.crew_cards.hide_card()
	campaign.hud.crew_cards.reveal()
	campaign.hud.crew_cards.hide_card()
	await process_frame
	var cards: Array = campaign.route.mission_table().role_cards(0)
	_check(not campaign.hud.crew_cards.is_open() and not bool(campaign.director.query().paused) and cards[0].read and cards[1].read, "both holders read their notes and time resumes")
	_check(campaign.hud.open_mission_table("p02_shift1") and campaign.hud.mission_table.crew() == CLASS4, "the Mission Table opens in Class mode")
	var table := campaign.hud.mission_table
	table.share_card("kai")
	table.share_card("amara")
	table.choose(1, "air_production", 1)
	table.choose(1, "light", "DIM")
	table.choose(1, "transfer", "FILL")
	var forecast: Dictionary = table.preview().forecast
	table.request_commit()
	for role_id in CrewScript.ROLE_ORDER:
		table.sign_off(String(role_id))
	var target := campaign.physical_target("p02_shift1")
	campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	await physics_frame
	await physics_frame
	table.confirm_commit()
	await process_frame
	_check(int(campaign.director.query().current_shift) == 1 and int(campaign.director.snapshot().resources.E) == int(forecast.final_state.E), "the signed plan commits exactly its preview through the physical operation")
	_check(bool(campaign.save_campaign().accepted), "the Class expedition saves")
	var loaded: Dictionary = SaveScript.new().load(storage.path)
	_check(bool(loaded.accepted) and loaded.snapshot.get("crew", {}) == CLASS4 and loaded.snapshot.route_runtime.p02_table.read.get("kai", false) and bool(Chapter1Campaign.restore_session(loaded.snapshot).accepted), "the save keeps the crew and the read receipts and can resume")
	var set_solo: Dictionary = campaign.handle_ui_command({"verb": "set_crew", "payload": SOLO})
	_check(bool(set_solo.accepted) and campaign.query().crew == SOLO and not button.visible, "Settings can switch back to Solo and the CREW NOTES tool hides")
	_check(not bool(campaign.handle_ui_command({"verb": "set_crew", "payload": {"mode": "class", "players": 1}}).accepted), "an invalid crew command is rejected")
	campaign.hud.panels.open_panel("settings_accessibility")
	await process_frame
	var class2 := campaign.hud.panels.find_child("Crew_class_2", true, false) as Button
	_check(class2 != null, "Settings shows the crew mode row inside an expedition")
	class2.pressed.emit()
	await process_frame
	_check(campaign.query().crew == {"mode": "class", "players": 2} and button.visible and button.text.contains("2 PLAYERS"), "the Settings row changes the crew at once")
	campaign.hud.panels.close_panel()
	campaign.free()
	storage.cleanup()

# --- Helpers -------------------------------------------------------------------

func _reach(route: RefCounted, scene_id: String) -> void:
	while route.current_scene_id() != scene_id:
		for target_id in _targets(route.current_scene_id()):
			route.perform(target_id)
		if not bool(route.advance_scene().get("accepted", false)):
			_check(false, "route reaches " + scene_id + " (stuck at " + route.current_scene_id() + ")")
			return

func _targets(scene_id: String) -> Array:
	if scene_id == "EX-CH01-S03":
		return ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]
	var ids: Array = []
	for spec in GateCatalog.targets_for_scene(scene_id):
		ids.append(String(spec.target_id))
	return ids

## Every visible label and button text under `node`, joined; hidden subtrees
## (such as a closed hand-off) are skipped.
func _text(node: Node) -> String:
	var parts: Array = []
	_collect_text(node, parts)
	return "\n".join(parts)

func _collect_text(node: Node, parts: Array) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		_collect_text(child, parts)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
