## Godot --headless --path game --script res://tools/test_network.gd
## M3-62: Tests for placeable survey markers, fixed lines, path lights, relay
## repeaters from carried payloads, CH04 beacons returning as a layer on the
## CH08 route map, coverage map message unlocks, P-16 voice over player-built
## links, and SaveService v1/v2/v3 persistence & migration.
extends SceneTree

const NetworkScript = preload("res://scripts/network/lunar_network.gd")
const CoveragePanelScript = preload("res://scripts/network/coverage_map_panel.gd")
const PayloadInventoryScript = preload("res://scripts/payload/payload_inventory.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const SaveServiceScript = preload("res://scripts/save/save_service.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const UiDesignScript = preload("res://scripts/ui/ui_design.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_payload_placement_and_capacity()
	_test_ch04_beacons_layer_on_ch08_map()
	_test_coverage_hops_and_message_unlocks()
	_test_p16_voice_over_network()
	_test_save_persistence_and_migration()
	await _test_ui_and_capture()
	print("NETWORK RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_payload_placement_and_capacity() -> void:
	var net := NetworkScript.new(0)
	_check(net.marker_capacity() == 6, "Navigation rank 0 has base marker capacity 6")
	var net_r3 := NetworkScript.new(3)
	_check(net_r3.marker_capacity() == 9, "Navigation rank 3 raises marker capacity to 9")

	var inv := PayloadInventoryScript.new(4, ["sled", "trailer"])
	for kind_val in ["marker", "fixed_line", "path_light", "repeater"]:
		var kind := String(kind_val)
		var site := "site_" + kind
		var def := NetworkScript.make_payload_definition("pay_" + kind, kind, site)
		_check(bool(inv.register_payload(def).get("accepted", false)), "register payload for " + kind)
		_check(bool(inv.pickup("pay_" + kind, "hands").get("accepted", false)), "carry payload for " + kind)
		var wrong_site := net.place_from_payload("net_" + kind, kind, "wrong_site", [200.0, 150.0], 4, "", inv, "pay_" + kind)
		_check(not bool(wrong_site.get("accepted", false)), "cannot place " + kind + " at wrong site")
		var placed := net.place_from_payload("net_" + kind, kind, site, [250.0, 180.0], 4, "", inv, "pay_" + kind)
		_check(bool(placed.get("accepted", false)) and inv.item("pay_" + kind).place == "delivered", "carrying and delivering payload builds " + kind)

	_check(net.all_placed().size() == 4, "all four structure types (marker, fixed_line, path_light, repeater) persist")
	var dup := net.place_from_payload("net_marker", "marker", "site_marker", [250.0, 180.0], 4)
	_check(not bool(dup.get("accepted", false)) and bool(dup.get("duplicate", false)), "duplicate structure id is rejected")

func _test_ch04_beacons_layer_on_ch08_map() -> void:
	var net := NetworkScript.new(1)
	var added := net.record_ch04_beacons(3)
	_check(added.size() == 3, "three Chapter 4 survey beacons recorded")
	var layer := net.ch04_beacon_layer()
	_check(layer.size() == 3 and String(layer[0].get("id", "")) == "CH04-BEACON-1" and String(layer[2].get("id", "")) == "CH04-BEACON-3", "CH04 beacons return as a persistent layer on the CH08 route map (doc 24 N1)")

func _test_coverage_hops_and_message_unlocks() -> void:
	var director := DirectorScript.new()
	director.new_campaign()
	var net := NetworkScript.new(2)
	var r1 := net.activate_hop("Aurora-R1", director)
	_check(bool(r1.get("accepted", false)) and String(r1.get("newly_unlocked_message_id", "")) == "MSG-NET-R1", "new coverage hop unlocks its message")
	_check(director.message_metadata().delivered_ids.has("MSG-NET-R1"), "unlocked message is recorded in CampaignDirector.message_metadata")
	var full := net.activate_full_local_chain(director)
	_check(bool(full.get("local_chain_complete", false)) and net.active_hops().size() == 4, "activating all 4 local repeater hops completes the local chain")
	_check(net.unlocked_message_ids().size() == 4, "all 4 hop message links are unlocked once")

func _test_p16_voice_over_network() -> void:
	var net := NetworkScript.new(2)
	var premature := net.verify_finale_voice_network("L2", "E3", "ALO42")
	_check(not bool(premature.get("accepted", false)), "finale voice requires the 4-hop local repeater chain first")
	net.activate_full_local_chain()
	var bad_bearing := net.verify_finale_voice_network("L1", "E3", "ALO42")
	_check(not bool(bad_bearing.get("accepted", false)), "wrong local bearing L1 is rejected")
	var bad_echo := net.verify_finale_voice_network("L2", "E3", "WRONG")
	_check(not bool(bad_echo.get("accepted", false)), "wrong known-content echo is rejected")
	var good := net.verify_finale_voice_network("L2", "E3", "ALO42")
	_check(bool(good.get("accepted", false)) and net.is_voice_ready() and good.get("voice_path", []).size() == 6, "P-16 dual-link verification carries Noor's live voice over the player's repeater network")

func _test_save_persistence_and_migration() -> void:
	var net := NetworkScript.new(2)
	net.record_ch04_beacons(3)
	net.place_from_payload("LINE-01", "fixed_line", "ridge_chute", [410.0, 210.0], 4, "Fixed line · Ridge chute")
	net.place_from_payload("LIGHT-01", "path_light", "shadow_gate", [560.0, 275.0], 4, "Path light · Shadow gate")
	net.activate_full_local_chain()
	net.verify_finale_voice_network("L2", "E3", "ALO42")

	var snapshot := StateScript.new_snapshot()
	snapshot = net.write_to_campaign_snapshot(snapshot)
	var save_service := SaveServiceScript.new()
	var temp_path := OS.get_temp_dir().path_join("test_lunar_network_%d.json" % Time.get_ticks_usec())
	var saved := save_service.save(snapshot, temp_path)
	_check(bool(saved.get("accepted", false)), "SaveService validates and saves snapshot with lunar_network")
	var loaded := save_service.load(temp_path)
	_check(bool(loaded.get("accepted", false)), "SaveService loads snapshot with lunar_network")

	var restored := NetworkScript.new()
	restored.sync_from_campaign_snapshot(loaded.snapshot)
	_check(restored.all_placed().size() == 5 and restored.ch04_beacon_layer().size() == 3 and restored.is_voice_ready(), "restored LunarNetwork preserves CH04 beacons, fixed lines, path lights, hops and P-16 voice readiness")

	# Also verify v2 save migration preserves presentation_resume.lunar_network
	var v2_snap := snapshot.duplicate(true)
	v2_snap["schema_version"] = 2
	v2_snap.erase("story_log")
	var migrated := save_service.migrate(v2_snap)
	var migrated_net := NetworkScript.new()
	migrated_net.sync_from_campaign_snapshot(migrated.get("snapshot", {}))
	_check(bool(migrated.get("accepted", false)) and migrated_net.ch04_beacon_layer().size() == 3 and migrated_net.is_voice_ready(), "v2 save migration preserves lunar_network structures and links")
	save_service.clear(temp_path)

func _test_ui_and_capture() -> void:
	root.size = Vector2i(1280, 720)
	var net := NetworkScript.new(2)
	net.record_ch04_beacons(3)
	net.place_from_payload("LINE-01", "fixed_line", "ridge_chute", [410.0, 210.0], 4, "Fixed line · Ridge chute")
	net.place_from_payload("LIGHT-01", "path_light", "shadow_gate", [560.0, 275.0], 4, "Path light · Shadow gate")
	net.activate_full_local_chain()
	net.verify_finale_voice_network("L2", "E3", "ALO42")

	var panel := CoveragePanelScript.new()
	root.add_child(panel)
	panel.bind_network(net)
	await process_frame
	await process_frame

	var problems := _scan_banned_ui_text(panel)
	_check(problems.is_empty(), "CoverageMapPanel contains no banned developer tokens")

	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		if img != null:
			var out_path := ProjectSettings.globalize_path("res://../production/qa/evidence/M3-62_coverage_map.png")
			img.save_png(out_path)
			print("Saved capture: ", out_path)
	panel.queue_free()
	await process_frame

func _scan_banned_ui_text(node: Node) -> Array:
	var out: Array = []
	if node is Label:
		var t := (node as Label).text
		var found := UiDesignScript.banned_regex().search(t)
		if found != null:
			out.append(found.get_string() + " in " + t)
	for child in node.get_children():
		out.append_array(_scan_banned_ui_text(child))
	return out

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
