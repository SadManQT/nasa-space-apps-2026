# Future implementation blueprint — no implementation supplied

## Architecture intent

Keep the expedition's story state, puzzle rules and presentation separate. This is a contract for a later developer, not source code or an engine project. Godot with GDScript is the existing project preference; choose and pin an available supported 4.x version at implementation start after testing the Compatibility renderer on target hardware. The older gameplay document’s4.7.2 label is not a verified installed dependency. No dependency was installed here.

Scene presentation consumes an authoritative mission state. Preview and commit must use the same numeric contract with different persistence permissions. UI reads values, never secretly changes resource totals. Companion positions come from physical location/roster state, not dialogue speaker labels. Narrative milestones advance dates only by explicit accepted transitions.

## Content contracts for later authoring tools

| Record | Required fields | Invariants |
|---|---|---|
| Chapter | CH-ID,title,ordered M-IDs,start/end dates,locations | Exactly8; no mandatory branch omitted |
| Mission | M-ID,predecessor flag, 3 scene IDs,puzzle ID,objective predicates,completion flag,next mission | Exactly16; graph acyclic; next unlock after final scene transaction |
| Scene | SC-ID,mission,location,time,physical/remote/archive cast,line IDs,interactions,EV predicate,next |48; every line unique, every physical actor at correct location |
| Dialogue | DL-ID,speaker,text,unknown-name behavior,trigger,priority,caption/VO reference | Word-for-word master; no required knowledge before acquisition |
| Puzzle | P-ID,initial conditions,allowed inputs,subchecks,solution witnesses,hints,pass/retry |16; no success from animation length alone |
| Prop | Asset ID,location,socket,interaction verb,stage prerequisite,result,evidence/item policy | Critical items cannot be dropped/lost; interaction within 2 m and line of sight |
| Discovery | Journal ID,type,observed/verified status,source,time,knowledge flag | Acquired pages only; replay cannot award physical items |
| Plant | Individual/lineage ID,cultivar,stage,dates,stress,pollen parents,seed inventory | Alo and Tara separate individuals; later generations explicitly descendants |
| Travel | Trip ID,roster,route,segment,departure/arrival,resources,repeaters | Cannot be physically at two locations; final trip 24 h outbound/24 h return |
| Save | Version,mission/scene phase,puzzle state,resources,inventory,flags,locations,time,dialogue cursor,settings version | Atomic snapshot plus valid previous checkpoint |

No content importer is supplied. A developer may manually enter these records, but may not invent fields that change story semantics. Numeric state contracts are [puzzles](08_PUZZLE_DESIGNS.md), ordered play is [missions](07_MISSION_DESIGNS/), line text is [dialogue](11_DIALOGUE_MASTER.md).

## Flag registry

Campaign flags are monotonic except rollback to a saved checkpoint. Commit each only when its owning mission completes:

| Flag | Owner | Unlocks |
|---|---|---|
| arrival_accepted | New Expedition setup | M-0101 |
| pair_planted | M-0101 | M-0102 |
| first_bloom | M-0102 | M-0201 |
| pollen_shared | M-0201 | M-0202 |
| recorder_context | M-0202 | M-0301 |
| leak_sealed | M-0301 | M-0302 |
| seed_legacy | M-0302 | M-0401 |
| ice_survey | M-0401 | M-0402 |
| vault_recovered | M-0402 | M-0501 |
| zero_sequence | M-0501 | M-0502 |
| noor_known | M-0502 | M-0601 |
| eclipse_ready | M-0601 | M-0602 |
| kai_supported | M-0602 | M-0701 |
| storm_prepared | M-0701 | M-0702 |
| route_clear | M-0702 | M-0801 |
| summit_reached | M-0801 | M-0802 |
| campaign_complete | M-0802 | Credits, final garden Continue |

Each SC-ID has its own _done flag; each EV-ID only sets that matching scene's flag after every conjunct in the scene gate is true. Puzzle _pending flags live inside the mission transaction and never unlock the next mission. Evidence flags (packet_initial_seen, engineer_voice_heard, manual_gauge_trusted, old_garden_seedling_only, vault_route_known, brought_home_line_seen, zero_all_returned, noor_contact_consented, noor_identity_revealed, eclipse_observed, radio_external_failed, final_log_heard, repeater_chain_live, aurora_home_ready, relay_live, crew_returned, final_garden_validated, credits_available) gate presentation/substeps, not substitute mission completion. For any spelling seen in a mission, the listed completion flag is authoritative; no duplicate synonymous campaign flag is permitted.

## Inventory and knowledge invariant ledger

FOUNDER-A: two source seeds become individuals ALO-01 and TAR-01; both exhausted from packet. ALO-01 × TAR-01 yields FOUNDER-HARVEST42; 12 planted, 30 protected. Later routine generations use their own new harvests; never decrement the remaining 30 to explain October flowers. Reserve can be split 15+15 inside the same protected case but must still sum 30 and be counted once. P-13/14 protect that founder reserve, not a second magically duplicated 30.

VAULT-V12: twelve distinct specimens, one collection entry each: Tori mustard, rice, thale cress, duckweed, zinnia, red romaine lettuce, chile pepper, radish, dwarf tomato, SEEDS tomato, super-dwarf wheat and cotton. Exact preserved specimens are a fictional curatorial choice, not a claim that all species share one storage protocol. Validate handling/viability before planting. One cotton seed is planted Dec 15; the other eleven specimens remain protected. No invented six-mustard/six-cotton split or five cotton backups. Viability screening is required; inspection alone does not prove a seed will germinate. The successful story branch confirms cotton germination during the care montage. Any nonviable specimen can retain its research album entry without pretending it grew.

ALBUM-16 is an educational collection, not the founder-harvest count or the number of physical vault seeds: two founding entries (Alo, Tara) + twelve recovered entries above + two optional challenge entries (zucchini, sunflower) = sixteen. Optional challenges unlock garden-mode cultivar records, not extra mandatory seeds in the story. FOUNDER-HARVEST42, VAULT-V12 and ALBUM-16 have separate IDs and transactions; a card never increments a specimen count.

KNOWLEDGE: technical safety notes arrive CH03; Ferreira’s confession, complete identity connection and Academy-founder reveal occur CH05, last personal naming/Academy-origin log CH07, live voice CH08. Noor's identity is known after CH05 even when she signs N. Portraits, journal titles, quest text and screen-reader labels obey the same gate.

## Event ordering, concurrency and recovery

One interaction transaction owns a prop at a time. Queue competing input; release interaction lock on cancel/load. A journal scan and a physical operation may share a prop but not double-fire a completion event. Pause freezes world, timers and companion interaction progression; dialogue reading never consumes oxygen. On cinematic skip, acknowledge delivered lines and stage NPCs to safe final anchors; do not invent puzzle/subcheck flags. On failure, show causal result before restoring snapshot; keep the separate review record so the player can learn without corrupting the restored state.

Cross-location authored viewpoint cuts preserve each team's snapshot. Free role switching cannot cross teams. Home checks happen before summit arrival confirmation at Apr 9 00:00; player order must not rewrite an already-failed home simulation. Direct radio unavailable still permits stored observations/local network; quest guidance comes from local companions or journal. Save during transit records segment/rest stop and elapsed mission time; reload never charges a travel cost twice.

## Build and performance targets for later verification

Windows offline first, Compatibility renderer, 1280×720 minimum UI layout, target 30 fps at 720p on an agreed modest classroom reference laptop. Establish the actual machine/spec at production kickoff; no claim of benchmark results here. Modular station, limited active NPCs, shared rigs, instanced plants/rocks, bounded roads and authored cruise reduce scope. Avoid mandatory heavy volumetrics, cinematic-resolution textures on all props, online APIs and dynamic global simulation of an entire lunar year.

Localization: externalize all player-visible text by stable ID; use Unicode/Bangla shaping; do not concatenate translated sentence fragments. Input abstraction supplies remappable glyphs and tap alternatives. Save migration must be explicit and versioned; prior incompatible versions preserve files and explain supported actions. Production logs must identify mission/scene/interaction without exposing private user data.

## Vertical slice

Build M-0101 and M-0102 as a complete 28-minute target chapter, with an optional five-minute judge demonstration using the same rules and explicit omitted-time montage. It must include walking the station, choosing a cadet, a conversation, planting, sharing observations, a real preview/commit, shelter/water consequence, bloom, old message, save/reload and accessibility. Temporary art may replace listed assets; temporary plot, invented dialogue or an auto-win puzzle may not. This slice tests the emotional premise before expensive rover/season production.

Implementation begins only in a later authorised task. This package contains no Godot project, scripts, scenes, executable prototype or generated production assets.

## Required source integration and release truthfulness

The source-data pipeline remains part of the project, as defined in [SCIENCE_AND_DATA.md](../docs/SCIENCE_AND_DATA.md#c-data-pipeline-for-the-hackathon-one-team-member-about-68-hours). Bundle provenance for the LROC illumination map, DONKI replay records, crew-consumables and engineering references in the Chapter 1 slice. Process CRaTER/RAD comparisons and LOLA/Horizons horizon inputs before claiming measured curves or a computed local sky; otherwise mark the specific fallback [E]/[G]. Later chapters add Apollo PSE, ShadowCam/LCROSS/Diviner, impact records, eclipse geometry, STEREO-A and the relay bearings. DONKI metadata does not replace an instrument time series.

Every source-derived value records product/instrument, archive URL, interval, retrieval date, units, transformation and consumer. Raw and derived artifacts are separate. No importer or processed data exists yet. The concept’s promise of NASA data is a production requirement; it is not satisfied by renaming it “inspired by.” Story replays remain labelled when data integration is complete.
