# P-02 balance check (Chapter 1, *Seven Shifts, One Night*)

**Date:** 24 October 2026 · **Checked:** the locked P-02 numeric execution contract in
[`game-design/08_PUZZLE_DESIGNS.md`](../game-design/08_PUZZLE_DESIGNS.md#p-02-numeric-execution-contract) and
[`GAMEPLAY_DESIGN_FINAL.md` §6](GAMEPLAY_DESIGN_FINAL.md#6-chapter-1-numerical-contract), exactly as written
(start E14/A6/H6/W0/K0, cap E20/A10/H10, +8 in shifts 1–2, the shift order in steps 1–8, the dose table, the
blackout penalties, and Mission stopped at A≤0 or Z>3).

**Method:** a paper design calculation (not game code) that applies the contract's shift order to **every possible
plan**: 528,398,500,275 plans, with the interface blocking impossible transfers (FILL at W6, DRAIN at W0). No numbers
were changed. This is a design check, not a playtest; the contract still needs the GAME-02 test suite on 13 Nov.

---

## 1. What is confirmed

| Check | Result |
|---|---|
| The four worked plans (Bloom/WAIT, Golden, PUMP, STACK) | **All four reproduce exactly**, final E/A/H/W/K/C/Z as published, no blackout |
| All four endings reachable | Yes |
| "Every setting appears in some ★★★ plan" | **True** for every shift: each heat level, air level, lamp level, transfer and alarm choice |
| Golden Bloom is rare | Yes: **28,224 plans** (1 in 18.7 million random plans, 0.009% of ★★★ plans) |
| Golden only at exactly H=5 (prediction in 08) | **True**: the highest H reachable with no blackout and a safe crew is 5 |

| Ending | Share of all plans |
|---|---:|
| Golden Bloom | 0.000005% |
| Bloom | 0.71% (★★★ 0.06%) |
| Alo lost | 49.7% |
| Mission stopped | 49.6% (air 4.5%, crew dose 45.1%) |

## 2. Findings for the team (no numbers changed; decide through change control)

### F1 · The "crew safe" star can never be missed

Mission stopped triggers at Z>3, and the star is Z≤3. Every finished run therefore earns the crew star
automatically, so Chapter 1 really has two stars to earn (lights on, Alo alive).

*Options:* (a) keep the stop at Z>3 (crew safety as a hard rule, STORY-03) and replace star 1 with something a
player can miss, e.g. **"Crew dose 0"** (needs a full wall of 6 at the alarm, which then costs Alo water;
reachable together with lights on and a living Alo in 2.5 million plans, but **never together with H≥5**, so Golden
would then have to require "lights on + Alo alive + H≥5" rather than all three stars);
(b) stop only at a higher dose and let Z=4 cost the star (closer to the v7 game plan, but it weakens STORY-03).
**Recommendation: (a).**

### F2 · Shift 6 of the storm repeats shift 5

Shift 5 is scored after the alarm, and shift 6 is scored at the start of the shift, before its transfer. No transfer
can happen in between, and crates stay until shift 7, so shift 6 always gets the same dose as shift 5. The crew dose
is always **0, 2, 4 or 6**, and the storm is really one decision.

*Options:* make the storm's tail weaker (for example, shift 6 uses one row better on the dose table), so draining in
shift 6 becomes a real gamble; or score shift 6 after its transfer, so Rafi can still FILL. Either needs a re-run of
this check and the worked plans.

### F3 · Only Rafi's secret is decisive

| If the team ignores… | Best possible result |
|---|---|
| Rafi's flare warning (no wall before the alarm) | **Always Mission stopped** |
| Amara's tip (no air made in daylight) | ★★★ still possible; Golden impossible |
| Kai's long-night fact (COZY every night) | ★★★ and Golden still possible |
| Mei's water fact (never drain after the storm) | ★★★ and Golden still possible |

`GAMEPLAY_DESIGN_FINAL.md` already says ignoring a secret need not cost a star. But the pitch line *"missions fail
from silence"* and the Communication badge are stronger if more secrets matter. An alternative tuning in which every
ignored secret costs at least one star was tested on 23 Oct (jar 15 / income 14, 14, 6 / storm 6 then 3 / Alo frost
and thirst limits). It is available if the team wants to consider it, through change control only.

### F4 · Golden fallback H≥4 is a big step

Lowering Golden to H≥4 makes it about **30× more common** (857,832 plans, 1 in 616,000; 0.27% of ★★★ plans). That still
fits "rare", so the pre-agreed fallback is reasonable.

### F6 · Golden Bloom needs STACK

Without the STACK choice, Golden is impossible (no plan reaches it). `GAME_PLAN_FINAL.md` §11 lists STACK as a
*Should*, and its hour-24 rule cuts every Should. If STACK is cut, the Golden ending, its worked plan and its tests all
break. *Fix:* make STACK a **Must**, or drop Golden from the hackathon build.

### F7 · The radiation stop has no written number

P-02 says "a crew exposure safety breach" stops the mission, and its completion trigger needs Z≤3, so the breach is
Z>3 by implication. Other files disagree (the v7 table lets Z=4 finish; the test suite in
`game-design/20_TESTING_AND_ACCEPTANCE.md` treats Z=4 as unsafe). *Fix:* write the number into P-02 (this check used
Z>3), together with the F1 decision.

### F8 · Partial PUMP / STACK results are always worse

Assisted input is always allowed and gives the full result, so partial results (PUMP +1, STACK one crate) are only
ever a penalty for players who skip assistance. *Fix:* keep the timed version as the fun default, but make assistance
visible on the alarm panel so nobody is punished for slow hands.

### F5 · Out-of-date claims in `GAME_PLAN_FINAL.md` §5

The v7 balance table predates the P-02 contract. Under P-02:

- "COZY every night → ★★ (blackout)": false (the published Bloom/WAIT plan is all-COZY with ★★★).
- "No prefill, PUMP or STACK only at the alarm → ★★ (4 zaps)": now **Mission stopped**.
- "923 ★★★ end states", "Golden ≈ 15% of ★★★", "Random: ★★★ in 2.3%": do not match P-02
  (Golden ≈ 0.009% of ★★★ plans; ★★★ ≈ 0.06% of all plans).

§5 should point to P-02 instead of repeating its own numbers.
