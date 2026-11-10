# Suites 42-119 of the 119-suite gate, run by Sadman (Claude Code)

10 November 2026, macOS (Apple Silicon), Godot 4.7.2 headless, one suite at a time, same pass rule and per-suite limits as `game/tools/run_tests.sh` (a result line with PASS / 0 failures, exit 0, no SCRIPT/Parse error). Run by a standalone loop because the runner has no start index.

Source: `54be6a6f` (main after Ramim's 295a468c). Ramim's own result for suites 1-41 (41 passed, 0 errors, source and logs on his machine) is **not** re-verified here: he could not push because his Codex limit ended.

**Result: 78 of 78 suites passed, 0 failed (34.6 min).** Together with Ramim's reported 41/41 this is 119/119, but the two halves ran on different checkouts, so it is **not** one frozen-source full gate. M1-125 stays Ramim's to close.

| # | Suite | Seconds | Result line |
|---|---|---|---|
| 42 | test_chapter8_puzzles.gd | 24.1 | CHAPTER 8 PUZZLES RESULT: PASS (110 checks, 0 failures) |
| 43 | test_chapter8_rooms.gd | 230.8 | CHAPTER 8 ROOMS RESULT: PASS (1328 checks, 0 failures) |
| 44 | test_chapter_select.gd | 3.0 | CHAPTER SELECT RESULT: PASS (119 checks, 0 failures) |
| 45 | test_comms.gd | 4.0 | COMMS RESULT: PASS (45 checks, 0 failures) |
| 46 | test_cutscene_choice_card.gd | 11.0 | CUTSCENE CHOICE CARD RESULT: PASS (47 checks, 0 failures) |
| 47 | test_director_message_metadata.gd | 2.0 | DIRECTOR MESSAGE METADATA RESULT: PASS (76 checks, 0 failures) |
| 48 | test_earth_screen.gd | 3.0 | EARTH SCREEN RESULT: PASS (49 checks, 0 failures) |
| 49 | test_eclipse_props.gd | 1.0 | ECLIPSE PROPS RESULT: PASS (567 checks, 0 failures) |
| 50 | test_eclipse_rim_gate.gd | 1.0 | ECLIPSE RIM GATE RESULT: PASS (65 checks, 0 failures) |
| 51 | test_en_airlock.gd | 1.0 | EN_AIRLOCK RESULT: PASS (145 checks, 0 failures) |
| 52 | test_eva.gd | 6.0 | EVA RESULT: PASS (54 checks, 0 failures) |
| 53 | test_explainers.gd | 5.0 | EXPLAINERS RESULT: PASS (321 checks, 0 failures) |
| 54 | test_extended_campaign_route.gd | 24.1 | EXTENDED CAMPAIGN ROUTE RESULT: PASS (639 checks, 0 failures) |
| 55 | test_exterior_terrain.gd | 89.4 | EXTERIOR TERRAIN RESULT: PASS (1109 checks, 0 failures) |
| 56 | test_face_atlas.gd | 1.0 | PASS FaceAtlas (17 checks, 16 cue frames checked) |
| 57 | test_face_expression.gd | 7.0 | PASS FaceExpression / HeadAccent (68 checks, including runtime Kai GLTF integration) |
| 58 | test_first_five_minutes.gd | 2.0 | FIRST FIVE MINUTES RESULT: PASS (59 checks, 0 failures) |
| 59 | test_garden_collision.gd | 7.0 | GARDEN COLLISION RESULT: PASS (19 checks, 0 failures) |
| 60 | test_garden_movement.gd | 46.2 | GARDEN MOVEMENT RESULT: PASS (54 checks, 0 failures) |
| 61 | test_habitat_kit.gd | 1.0 | HABITAT KIT RESULT: PASS (225 checks, 0 failures) |
| 62 | test_habitat_rooms.gd | 31.1 | HABITAT ROOMS RESULT: PASS (360 checks, 0 failures) |
| 63 | test_hair_springs.gd | 1.0 | PASS HairSprings (5 checks, 3 chains) |
| 64 | test_hazards.gd | 1.0 | HAZARDS RESULT: PASS (24 checks, 0 failures) |
| 65 | test_hint_player.gd | 5.0 | HINT PLAYER RESULT: PASS (124 checks, 0 failures) |
| 66 | test_hud_world_lifetime.gd | 4.0 | HUD WORLD LIFETIME RESULT: PASS (13 checks, 0 failures) |
| 67 | test_journal_tabs.gd | 5.0 | JOURNAL TABS RESULT: PASS (322 checks, 0 failures) |
| 68 | test_later_numeric.gd | 9.0 | LATER NUMERIC RESULT: PASS (388 checks, 0 failures) |
| 69 | test_lip_sync.gd | 1.0 | PASS LipSync coarticulation, closures, loudness, release and errors |
| 70 | test_loading.gd | 7.0 | LOADING WATCHDOG RESULT: PASS (29 checks, 0 failures) |
| 71 | test_lunar_kit.gd | 1.0 | LUNAR KIT RESULT: PASS (89 checks, 0 failures) |
| 72 | test_m155_mission_table.gd | 2.0 | M155 MISSION TABLE RESULT: PASS (109 checks, 0 failures) |
| 73 | test_main_menu_contrast.gd | 2.0 | MAIN MENU CONTRAST RESULT: PASS (170 checks, 0 failures) |
| 74 | test_mission_table_lifetime.gd | 1.0 | MISSION TABLE LIFETIME RESULT: PASS (11 checks, 0 failures) |
| 75 | test_mission_trainer.gd | 3.0 | MISSION TRAINER RESULT: PASS (951 checks, 0 failures) |
| 76 | test_moon_region.gd | 9.0 | MOON REGION RESULT: PASS (511 checks, 0 failures) |
| 77 | test_moon_trainer.gd | 142.6 | MOON TRAINER RESULT: PASS (136 checks, 0 failures) |
| 78 | test_narrative_props.gd | 2.0 | NARRATIVE PROPS RESULT: PASS (401 checks, 0 failures) |
| 79 | test_network.gd | 1.0 | NETWORK RESULT: PASS (35 checks, 0 failures) |
| 80 | test_outpost_status.gd | 5.0 | OUTPOST STATUS RESULT: PASS (63 checks, 0 failures) |
| 81 | test_p01_inputs.gd | 4.0 | P01 INPUTS RESULT: PASS (319 checks, 0 failures) |
| 82 | test_p01_labels.gd | 1.0 | P01 LABELS RESULT: PASS (104 checks, 0 failures) |
| 83 | test_p01_nearby.gd | 5.0 | P01 NEARBY RESULT: PASS (30 checks, 0 failures) |
| 84 | test_p01_panel.gd | 7.0 | P01 PANEL RESULT: PASS (140 checks, 0 failures) |
| 85 | test_p02_mission_table.gd | 6.0 | P02 MISSION TABLE RESULT: PASS (78 checks, 0 failures) |
| 86 | test_p03_p04_content.gd | 1.0 | P03 P04 CONTENT RESULT: PASS (303 checks, 0 failures) |
| 87 | test_p09_p10_panels.gd | 1.0 | P09 P10 PANELS RESULT: PASS (330 checks, 0 failures) |
| 88 | test_p13_p14_panels.gd | 1.0 | P13 P14 PANELS RESULT: PASS (406 checks, 0 failures) |
| 89 | test_payload.gd | 5.0 | PAYLOAD RESULT: PASS (162 checks, 0 failures) |
| 90 | test_performance_runtime.gd | 21.1 | PERFORMANCE RUNTIME RESULT: PASS (548 checks, 0 failures) |
| 91 | test_plant_seedlings.gd | 1.0 | PLANT SEEDLINGS RESULT: PASS (86 checks, 0 failures) |
| 92 | test_player_controller.gd | 6.0 | PLAYER RESULT: PASS (105 checks, 0 failures) |
| 93 | test_player_text.gd | 469.3 | PLAYER TEXT RESULT: PASS (13092 checks, 0 failures) |
| 94 | test_probe_calibration_job.gd | 1.0 | PROBE CALIBRATION JOB RESULT: PASS (83 checks, 0 failures) |
| 95 | test_progression.gd | 1.0 | PROGRESSION RESULT: PASS (72 checks, 0 failures) |
| 96 | test_review_scene.gd | 4.0 | REVIEW RESULT: PASS (447 checks, 0 failures) |
| 97 | test_room_presentation.gd | 5.0 | ROOM PRESENTATION RESULT: PASS (155 checks, 0 failures) |
| 98 | test_route_messages.gd | 1.0 | ROUTE MESSAGES RESULT: PASS (31 checks, 0 failures) |
| 99 | test_rover.gd | 1.0 | ROVER RESULT: PASS (27 checks, 0 failures) |
| 100 | test_save_service_recovery.gd | 2.0 | SAVE RECOVERY RESULT: 92/92 checks, 0 failures |
| 101 | test_science_data.gd | 4.0 | SCIENCE DATA RESULT: PASS (206 checks, 0 failures) |
| 102 | test_science_watch.gd | 5.0 | SCIENCE WATCH RESULT: PASS (65 checks, 0 failures) |
| 103 | test_session_crew.gd | 1.0 | RESULT test_session_crew: 135 checks, 0 failures |
| 104 | test_sound_captions.gd | 9.0 | SOUND CAPTIONS RESULT: PASS (82 checks, 0 failures) |
| 105 | test_story_echoes.gd | 1.0 | STORY ECHOES RESULT: PASS (780 checks, 0 failures) |
| 106 | test_story_log.gd | 2.0 | STORY LOG RESULT: PASS (64 checks, 0 failures) |
| 107 | test_tara_lifecycle.gd | 1.0 | TARA LIFECYCLE RESULT: PASS (75 checks, 0 failures) |
| 108 | test_terrain.gd | 4.0 | TERRAIN STREAM RESULT: PASS (104 checks, 0 failures) |
| 109 | test_terrain_lola.gd | 5.0 | TERRAIN LOLA RESULT: PASS (1404 checks, 0 failures) |
| 110 | test_terrain_session.gd | 3.0 | TERRAIN SESSION RESULT: PASS (78 checks, 0 failures) |
| 111 | test_terrain_work_lights.gd | 5.0 | TERRAIN WORK LIGHTS RESULT: PASS (1045 checks, 0 failures) |
| 112 | test_toon_materials.gd | 1.0 | PASS ToonMaterials (12 checks, 2 swapped materials) |
| 113 | test_ui_families.gd | 4.0 | UI FAMILIES RESULT: PASS (84 checks, 0 failures) |
| 114 | test_ui_kit.gd | 1.0 | UI KIT RESULT: PASS (522 checks, 0 failures) |
| 115 | test_upgrade_pairs_ch4_ch6.gd | 1.0 | UPGRADE PAIRS CH4 CH6 RESULT: PASS (34 checks, 0 failures) |
| 116 | test_upgrade_profiles.gd | 776.7 | UPGRADE PROFILES RESULT: PASS (130308 checks, 0 failures) |
| 117 | test_worker_a_systems.gd | 1.0 | WORKER A SYSTEMS RESULT: PASS (108 checks, 0 failures) |
| 118 | test_worker_b_world_missions.gd | 2.0 | WORKER B WORLD/MISSIONS RESULT: PASS (429 checks, 0 failures) |
| 119 | test_worker_c_content.gd | 1.0 | WORKER C CONTENT RESULT: PASS (572 checks, 0 failures) |
