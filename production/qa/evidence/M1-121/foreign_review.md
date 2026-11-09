# Foreign branch audit

Base: main 5f6f1df9d4fe. Read-only review of 32 refs.

## Result

- No scoped branch contains a completed Messages inbox or the pending M1-59, M3-66 and M3-76 clip sets. These clip tasks remain todo for Sadman on the current board.
- Main has the M1-55 Mission Table; M1-56 Messages remains a separate Ramim UI blocker.
- M4-05 has an alternate tracked Earth/dish source, while main carries the later accepted true-crescent repaint and different installed CS-15 LFS payloads. Preserve the ref for targeted owner inspection only if current visual QA finds a defect.
- The M1-10/M1-11 parked media branch predates current audio runtime. Its probe is archival.

## Per-ref decisions

| Ref | SHA | Class | Exact / different / branch-only | Finding |
|---|---|---|---:|---|
| backup/pre-sync-20261104-69c4283c | ff09cfd33 | ancestry-integrated | 0 / 0 / 0 | This backup is a direct ancestor of main. |
| origin/night/M1-03 | f7ec969f7 | superseded | 17 / 4 / 0 | Approved habitat concept sheets and labeling tools match main; only mutable planning and logs differ. |
| origin/night/M1-05 | 574dda3ac | superseded | 29 / 89 / 0 | Habitat kit is installed on main. Later corridor, hatch and texture revisions changed 31 GLB LFS pointers; old imports must stay archived. |
| origin/night/M1-06 | 1158f837d | superseded | 9 / 15 / 0 | Chapter 1 rooms and builder exist on main; room and contract code evolved. |
| origin/night/M1-07 | a7140a30e | superseded | 112 / 47 / 0 | Plant stages, UI icons and Earth desk exist; portrait and integration were revised later. |
| origin/night/M1-100 | b276bb4d3 | superseded | 0 / 6 / 94 | Parked delayed voice-readiness test differs from current bounded readiness and freed-owner coverage; board records landed 71/71 run. |
| origin/night/M1-34 | fece37e29 | superseded | 433 / 20 / 3 | LOLA terrain heightmaps and textures are installed; terrain and astronomy manifests evolved. .night_merge is scratch. |
| origin/night/M1-47 | 467a16f74 | superseded | 6 / 11 / 0 | Story-log choice/moment saving exists; UI panel and campaign test evolved. |
| origin/night/M1-50 | 0c79ea7b4 | metadata-only | 0 / 2 / 0 | Only board files changed; no narrative payload in this tip. |
| origin/night/M1-51 | 0eb7f7c2b | superseded | 1 / 22 / 0 | Current CS-01 cold open was rebuilt after M1-45 exterior fix; parked master and runtime pointers are older. |
| origin/night/M1-52 | 88301efda | metadata-only | 0 / 4 / 0 | Only handbook, AI log and board changed; no branch media payload. |
| origin/night/M1-76 | b38ac3d3f | superseded | 0 / 7 / 27 | Compatibility shadow fix exists; branch-only QA evidence is archival and runner/test evolved. |
| origin/night/M1-81 | 4c5e4e18f | metadata-only | 0 / 4 / 10 | Only status and QA evidence changed; newer UI status is on main. |
| origin/night/M1-86 | 1bc781345 | metadata-only | 0 / 5 / 5 | Only status and QA evidence changed; hint reader/runtime status is on main. |
| origin/night/M1-87 | 8bd450fd2 | superseded | 140 / 27 / 2 | Relay-road terrain assets exist; later terrain/provenance changed. Branch patch-map evidence is archival. |
| origin/night/M1-91 | e2336d411 | superseded | 4 / 12 / 3 | Cold-trap work lights exist; main extends rover scene staging and LOC-11 states. |
| origin/night/M1-96 | 879b67afc | metadata-only | 0 / 4 / 8 | Only status and QA evidence changed; newer Care Round status is on main. |
| origin/night/M3-104 | 27a573915 | superseded | 19 / 8 / 13 | Repaired glove-port exports exist; main removed runtime workaround. Branch editor/cache files are unsafe to port. |
| origin/night/M3-108 | 5803b8886 | superseded | 7 / 10 / 2 | Petal GLBs match main; scripts and room placement evolved. Handbook still says native capture pending. |
| origin/night/M3-2A | 8907a1f72 | superseded | 33 / 30 / 0 | Airlock and paper-bee assets exist; glove-port exports were later repaired in M3-104. |
| origin/night/M3-2R | b91078e81 | superseded | 4 / 51 / 3 | Chapter 2 room staging exists with later route wiring. .night_merge is scratch. |
| origin/night/M3-3A | 6246460ad | superseded | 139 / 22 / 0 | Chapter 3 asset family exists; petal exports were later corrected in M3-108. |
| origin/night/M3-5A | a1672162d | superseded | 168 / 10 / 0 | Chapter 5 game assets match; only registry, manifest and review metadata differ. |
| origin/night/M3-6R | cd547b114 | superseded | 29 / 15 / 3 | Chapter 6 staging exists; room/roster code evolved. .night_merge is scratch. |
| origin/night/M3-7A | 0f2396f52 | superseded | 77 / 11 / 3 | Chapter 7 shelter/uplink assets match; gate and registry tools evolved. .night_merge is scratch. |
| origin/night/M3-94 | c81b8eb0a | superseded | 11 / 14 / 0 | Approved canon lines/catalog are on main; media and catalog generation evolved. |
| origin/night/M3-97 | 5051d6494 | superseded | 26 / 33 / 0 | CS-17 assets match; CS-15/18 were rebuilt by later M4-05/M4-02 work. |
| origin/night/M3-99 | a41b57155 | ancestry-integrated | 0 / 0 / 0 | This tip is a direct ancestor of main. |
| origin/night/M3-99-saved | 33ffca653 | superseded | 6 / 8 / 0 | This tip is a direct ancestor of main. |
| origin/night/M4-02 | 7549dfc13 | superseded | 6 / 15 / 0 | Current CS-18 master/runtime and tick source match; CS-15 audio/verification evolved. |
| origin/night/M4-05 | f484b2caf | superseded | 2 / 15 / 25 | Main uses a later true-crescent repaint with different CS-15 master/runtime LFS payloads. Parked tracked Earth/dish source is an alternate, not current production input. |
| origin/sadman/m110-m111-media | 6b7054dd9 | superseded | 4 / 2 / 2 | M1-10/M1-11 media runtime and buses exist; current audio runtime has more methods. Parked probe is archival. |

## Evidence and limits

- The companion JSON records each exact SHA, merge base, diff count, current blob adoption, divergent source paths, board status and evidence excerpt, selected LFS OID/size checks, action and verification limit.
- LFS pointer identity proves referenced asset identity, not visual quality. Different pointers prove different payloads, not which render is better.
- Historical screenshots and logs were inspected as branch paths and board references. No fresh asset render, playback, generation, Godot/native test or credit spend was done.
- No foreign source ref, HEAD, index, board entry or installed asset was modified.
