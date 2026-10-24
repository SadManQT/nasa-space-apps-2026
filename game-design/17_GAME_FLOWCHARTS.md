# Story and gameplay flowcharts

IDs agree with mission, scene, puzzle, location and flag documents. Rectangles are required progress unless marked optional. Failure loops restore a safe checkpoint; no failed campaign silently substitutes another plant.

## 1. Entire chronology

```mermaid
flowchart TD
 Z0[2034: seedlings, relay fault and safe evacuation] --> Z1[Noor returns and founds Last Light Academy]
 Z1 --> A[2046 Apr11: arrival and two seeds]
 A --> B[Apr25-27: first night and bloom; 2017 replay]
 B --> C[Apr30-May6: bee runs, mustard-fields log and quake]
 C --> D[May7-21: annex and 42 seeds]
 D --> E[Oct21-22: two-field/two-base team and twelve-specimen vault]
 E --> F[Dec12-15: Ferreira arrives; confession and founder reveal]
 F --> G[2047 Jan12: eclipse and Kai acts]
 G --> H[Feb14-16: 2012 counterfactual and failed uplink]
 H --> P[Stable care and relay preparation to April]
 P --> I[Apr8-9: rover and home team; relay handover at Earth-set]
 I --> J[Apr10: returned crew and garden sunrise]
 J --> K[Credits; optional MARS drawer]
```

## 2. Chapter progression

```mermaid
flowchart LR
 C1[CH01 Night One] --> C2[CH02 Be the Bee]
 C2 --> C3[CH03 Moonquake]
 C3 --> C4[CH04 Into the Cold Trap]
 C4 --> C5[CH05 Shooting Stars]
 C5 --> C6[CH06 The Red Ring]
 C6 --> C7[CH07 The Great Storm]
 C7 --> C8[CH08 The Lighthouse]
 C8 --> END[Complete adventure]
```

## 3. Mission dependencies

```mermaid
flowchart TD
 START[arrival_accepted] --> M0101[M-0101 A Drawer of Light]
 M0101 -->|pair_planted| M0102[M-0102 Keep the Night]
 M0102 -->|first_bloom| M0201[M-0201 Borrow a Bee]
 M0201 -->|pollen_shared| M0202[M-0202 A Voice Before Us]
 M0202 -->|recorder_context| M0301[M-0301 Numbers That Disagree]
 M0301 -->|leak_sealed| M0302[M-0302 Forty-Two]
 M0302 -->|seed_legacy| M0401[M-0401 Where the Sun Cannot Follow]
 M0401 -->|ice_survey| M0402[M-0402 Twelve in the Dark]
 M0402 -->|vault_recovered| M0501[M-0501 The Engineer Comes Home]
 M0501 -->|zero_sequence| M0502[M-0502 Permission to Answer]
 M0502 -->|noor_known| M0601[M-0601 A Plan for Darkness]
 M0601 -->|eclipse_ready| M0602[M-0602 All the Sunrises]
 M0602 -->|kai_supported| M0701[M-0701 Your Call Cadets]
 M0701 -->|storm_prepared| M0702[M-0702 What We Carry]
 M0702 -->|route_clear| M0801[M-0801 The Long Road]
 M0801 -->|summit_reached| M0802[M-0802 From Last Light to First Light]
 M0802 --> COMPLETE[campaign_complete]
```

## 4. Relationships

```mermaid
graph TD
 K[Kai] <-->|light and support| R[Rafi]
 K <-->|plans and measurements| A[Amara]
 M[Mei] <-->|care and acceptance| A
 M <-->|hope and invitation| N[Noor]
 F[Ferreira] <-->|evacuation and honesty| N
 F -->|trusts local judgment| K
 F -->|recognises caution| R
 Q[Rao] -->|communications and consent| F
 M -->|care| AL[Alo]
 M -->|equal care| T[Tara]
 AL <-->|compatible pollen| T
```

## 5. Expedition Zero revelation

```mermaid
flowchart TD
 A[CH01: N packet and triggered care recording] --> B[CH02: mustard-fields log, stem prediction and engineer voice]
 B --> C[CH03: safety notes, frozen seedlings and N.R. clue]
 C --> D[CH03: frozen seedlings and vault map]
 D --> E[CH04: twelve-specimen case; ask Ferreira]
 E --> F[CH05: all boarding signatures reconstructed]
 F --> G[CH05: Noor alive and Academy founder]
 G --> H[CH06: known Noor sends eclipse memory]
 H --> I[CH07: final log explains Alo and Academy naming]
 I --> J[CH08: Noor chooses live voice and shared authorship]
```

## 6. World connectivity

```mermaid
graph LR
 L1[LOC-01 Commons] --- L2[LOC-02 Power/Air]
 L1 --- L3[LOC-03 Garden]
 L1 --- L4[LOC-04 Shelter]
 L2 --- L4
 L2 --- L7[LOC-07 Annex]
 L3 --- L7
 L1 --- L5[LOC-05 Airlock]
 L3 --- L5
 L5 --- L6[LOC-06 Courtyard]
 L6 --- L8[LOC-08 Garage]
 L8 --- L9[LOC-09 Cold-trap road]
 L9 --- L10[LOC-10 Vault]
 L8 --- L11[LOC-11 Relay road]
 L11 --- L12[LOC-12 Malapert summit]
```

## 7. Main gameplay loop

```mermaid
flowchart TD
 O[Explore and observe] --> I[Inspect equipment and evidence]
 I --> S[Share specialist observation]
 S --> P[Plan and preview known consequences]
 P --> D{Commit?}
 D -->|edit| P
 D -->|yes| A[Act or advance explicit shift]
 A --> R[See consequence and hear companions]
 R --> V{Safe objective passed?}
 V -->|yes| J[Journal and checkpoint]
 J --> O
 V -->|no| F[Review observation and retry checkpoint]
 F --> P
```

## 8. Rover flow

```mermaid
flowchart TD
 C[Check roster, seals, tools, supplies] --> P[Compare slope and return reserve]
 P --> V{Valid route?}
 V -->|no| P
 V -->|yes| D[Drive short surveyed segment]
 D --> M[Stop, brake, inspect marker]
 M --> T{Required task passed?}
 T -->|no| M
 T -->|yes| N{More stops?}
 N -->|yes| CR[Explicit cruise and elapsed time]
 CR --> D
 N -->|no| A[Arrive and checkpoint]
 A --> RET[Return on same validated route]
```

## 9. Garden progression

```mermaid
flowchart TD
 S[2 dry seeds] --> P[Alo external test and Tara indoor reference]
 P --> B[First bloom after36h dark window]
 B --> X[Compatible cross-pollination]
 X --> H[Mature pods and42 founder seeds]
 H --> R[30 protected founder reserve]
 H --> T[12 planting seeds]
 T --> G[Repeated documented generations]
 V[Vault:12 distinct seed specimens] --> Q[Quarantine and viability check]
 Q --> C[1 cotton planted,11 other specimens retained]
 G --> F[Mixed pressure-enclosed garden]
 C --> F
 R --> Z[Protected through great storm]
 Z --> E[Final safe seed-renewing garden]
 F --> E
```

## 10. Ending sequence

```mermaid
flowchart TD
 A[Storm clears; two safe readings] --> B[Three travellers; two home cadets]
 B --> C[Surveyed road and working repeaters]
 C --> D[Home heat, air and return loop verified]
 D --> E[Replace relay controller safely]
 E --> L[Local link L2]
 L --> X[Earth link E3 and checksum]
 X --> N[Hello Aurora: Noor live]
 N --> R[24h return; all crew at Aurora]
 R --> F[Final safety and garden checks]
 F --> S[Player opens viewing shutter]
 S --> P[Photo and dedication]
 P --> CR[Credits and campaign complete]
 CR --> O[Optional MARS drawer or garden Continue]
```
