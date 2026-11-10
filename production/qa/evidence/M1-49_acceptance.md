# M1-49 Care Round, M3-5U and M3-7U: acceptance (10 Nov 2026, Sadman / Claude Code)

Source: main at e552aebf (after Ramim's accepted combined gate, M1-125 done; M1-19, M1-83, M1-84, M1-51, M4-18 done).

## Gate
M1-125 accepted 119/119 suites across two hosts (Ramim 1-41 on Windows at 11722b7d, Sadman 42-119 on macOS at 54be6a6f, identical game tree e5c5d5ed). It is not one uninterrupted full run:
`production/qa/evidence/M1-125_117_gate_2026-11-10/combined119/README.md`. Re-run today on e552aebf through `game/tools/run_tests.sh`:
care_round 3/3 suites (panel 32/0, props 81/0, runtime 86/0); upgrade_pairs_ch4_ch6 34/0 (1/1 suites passed); ch01_room_hooks 117/0.

## M1-49
- Tests (test_care_round_runtime 86/0): two photos on two dates for each plant (12 and 18 April, before 25 April), a second photo on the same date is refused, Alo and Tara both have entries before 25 April; photos go through the Director's plant_care into the plants' receipts.
- S02: the inventory lamp blinks once after the roll call; S12 ends with `CH01-MUGS-NAMED` recorded and the four mugs named.
- Screenshots (copies of the M1-83 / M1-84 captures, inspected): M1-49_care_round_ghost_alo_tara.png, M1-49_care_round_paired_ghost.png, M1-49_care_round_tara_family_duplicate.png, M1-49_S02_lamp_blink.png, M1-49_S12_mugs_named.png.
- Care Round panel shows moisture and temperature side by side; the runtime commits no temperature of its own because no authored chamber temperature exists in the repo.
- **Partly met:** point 4 of the task (opening lines L01-L04). M1-51 is done and CS-01 was left unchanged (no duplicate captions). The four lines play with captions in the dialogue box, but they advance at scene entry, not at the beats (L01-L02 on arrival at the Mission Table, L03 at route preview, L04 before commit). Holding them to those beats needs a presentation hook in the HUD (`chapter1_campaign_hud.gd`, `Chapter1Campaign.present_dialogue`) and is not done.

## M3-5U and M3-7U
M4-17 and M4-18: test_upgrade_pairs_ch4_ch6 34/0; the choice screens (M3-5U_upgrade_after_ch04.png, M3-7U_upgrade_after_ch06.png) show the pair, earned only after the chapter, exclusive, saved and restored. Option effects: ice harvester +2 separate shelter water; rover lamps and heater 1.8x to 1.45x heater draw; storm early warning consumed in the Chapter 7 shelter run (M4-18, Ramim); bigger Safe Room K3.
