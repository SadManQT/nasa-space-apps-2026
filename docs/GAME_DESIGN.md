# Last Light Academy · Game Design (Chapter 1: *Night One*)

**Status:** final draft for team approval · **Version:** 1.0 · **Scope:** what we build at the hackathon

This document locks the story and the rules of Chapter 1 so that every asset, voice line and cutscene can be made
against it. The [README](../README.md) is the pitch; this is the build spec. When the two disagree, this file wins.

Related documents: [Cutscenes](CUTSCENES.md) · [3D quality and performance](TECH_ART.md) · [Asset tracker](ASSETS.md)

---

## 1. The game in one paragraph

Four cadets run Aurora Station on the rim of Shackleton crater, at the Moon's south pole, through one real 36-hour
lunar night. They share a jar of **sun-drops** (stored solar energy) between heat, air and light, move water between
the radiation shelter and Alo, a tiny mustard flower, and survive a replay of the real solar storm of
10 September 2017. Each cadet learns one **secret** about the future that the others need. The game is a 3D,
third-person, cooperative planning game: walk the station, inspect consoles, share what you know, preview the shift,
commit, and watch the consequences. At First Light, Alo blooms, if the team talked.

**Session length:** 25–30 minutes (judge route: 5 minutes). **Players:** 1 (Solo), or a whole class on one projector.

---

## 2. Story bible

### 2.1 The world

| | |
|---|---|
| **Year** | April 2046. The exact night is a real future night computed from LOLA terrain and JPL Horizons at the hackathon. |
| **Place** | Aurora Station, a small training base on the rim of Shackleton crater. Sunlight about 240 days a year. |
| **Last Light Academy** | A school that trains young cadets to run Moon bases. Tonight is their first solo night. |
| **Mission Control** | Houston, on Earth. Can only talk to the base while Earth is above the horizon. |
| **Alo** (আলো, "light") | A field-mustard plant (*Brassica rapa*) in a sealed outdoor chamber modelled on NASA's LEAF. |
| **Tara** (তারা, "star") | Alo's partner plant, grown indoors in Mei's garden. Seen in Chapter 1; matters in Chapter 2. |
| **N.** | The unknown person who left the seed packet. Revealed in Season 1 as Dr. Noor Rahman. |

### 2.2 Characters (final)

| Character | Role in play | Personality | Look | Voice |
|---|---|---|---|---|
| **Kai** | Power and heat | Bold, loves comfort, hates switching things off. Secretly afraid of the dark. | Orange role colour, spiky hair, power-gauntlet tool belt | Energetic boy, 12–13 |
| **Amara** | Air (oxygen) | Precise, loves exact numbers, calm under pressure | Cyan role colour, braids, data tablet | Clear, confident girl, 12–13 |
| **Mei** | Garden, food and Alo | Warm, talks to her plants, stubborn about the garden | Green role colour, short bob, gardening gloves | Soft but firm girl, 12 |
| **Rafi** | Safe Room (radiation shelter) | Worrier, teased for it, right in the storm | Purple role colour, curly hair, oversized helmet | Nervous, kind boy, 11–12 |
| **Commander Ferreira** | Instructor, Mission Control | Calm, strict, proud of them in the end | Seen only on screens | Warm, firm adult woman |
| **Rao** | Flight controller | Friendly, gives one hint per shift | Seen only on screens | Cheerful adult man |
| **N. (Dr. Noor Rahman)** | Seed-giver, voice only in Chapter 1 | Gentle, mysterious | Never seen in Chapter 1 | Bangladeshi woman, 40s, recorded-message quality |
| **Alo** | The heart of the game | Expressive, no words | Mustard bud with a face, leaf "arms" | Small chimes and sighs, no speech |

If we reuse the cadet models from the pitch video, their faces and hair win over the "Look" column above.

All cadets wear white suits with navy panels, orange trim and a Bangladesh flag patch, plus their role colour on the
shoulders and helmet stripe. Inside the pressurised station, helmets are off (except Rafi, who keeps his on during
the storm, as a running gag that pays off).

### 2.3 Chapter 1 beat sheet

| # | Beat | Where it happens | How it is shown |
|:---:|---|---|---|
| 0 | **Cold open: 2019.** The cotton sprout in Chang'e-4 freezes on its first night. | History | Cutscene **C01** |
| 1 | **Arrival.** Aurora Station on the crater rim; title card. Mei shows the crew the seed packet: two seeds, the word আলো, the letter N. One seed became Alo (outside), one became Tara (inside). | Exterior, Garden | Cutscene **C02**, then in-engine scene |
| 2 | **Shift 1: Day.** Meet the crew, learn to walk, inspect and run a shift. Secrets for Kai and Amara. | Station | Gameplay |
| 3 | **Shift 2: The Drill.** Ferreira calls a storm drill; the team practises PUMP and STACK. Rafi's secret: the flare. | Station | Gameplay + in-engine scene |
| 4 | **Shift 3: Last Light.** The Sun slides behind the far mountains; the solar masts go dark. Mei's secret. | Exterior, Garden window | Gameplay, then cutscene **C03** |
| 5 | **Shift 4: Earth-set.** Earth sinks below the horizon. "From here, you're on your own." The radio hisses and goes silent. Hints stop. | Exterior, Mission Table | Cutscene **C04**, then gameplay |
| 6 | **Shift 5: The Storm.** Rafi's counter ticks. THIS IS NOT A DRILL. 90 seconds: PUMP, STACK or WAIT. | Safe Room | Cutscene **C05** (5 s sting), then gameplay |
| 7 | **Shift 6: Storm.** Particles keep coming; the wall decides the dose. Alo hides its buds. | Station | Gameplay |
| 8 | **Shift 7: The last dark shift.** Will the jar last? | Station | Gameplay |
| 9 | **First Light.** The Sun climbs over the crater rim; light pours into Alo's chamber. | Exterior | Cutscene **C06** in one of four versions (§4) |
| 10 | **Earth-rise.** Days later, Earth rises; Ferreira returns: "You didn't survive the Moon. You ran it." | Exterior, Mission Table | Cutscene **C07** (Bloom endings only) |
| 11 | **Debrief.** Stars, badges, timeline, who knew what, what-if, "it was all real". | UI | Gameplay (UI) |
| 12 | **N.'s message.** The old computer wakes: *"If you're hearing this, Alo bloomed. Good. Now Alo needs a friend. — N."* Season map: Chapter 1 of 8, Chapters 2–8 locked. | Station, UI | Cutscene **C08** |

### 2.4 Season 1 (context only, not built at the hackathon)

Season 1, *The First Moon Garden*, is as written in the README: eight chapters over one Moon year, the mystery of
who left the seeds, and the reveal that N. is Dr. Noor Rahman. Chapter 1 must only **plant** these threads:
the seed packet with **আলো** and **N.**, Tara indoors, Ferreira going quiet when the seeds are mentioned, the old
computer in the corner of the Mission Table room, and N.'s message after the bloom.

---

## 3. Gameplay

### 3.1 Camera, movement and controls

- **Camera:** third-person, over the shoulder, auto-framing in small rooms; collision-safe spring arm. Fixed, framed
  camera angles at consoles (the camera eases to a console view when you press **E**).
- **Movement:** walk and jog only, no jumping (it is a calm, readable space). Lunar gravity is shown outside in
  cutscenes; inside the station, artificial floors keep movement simple.
- **Controls:** WASD + mouse, **E** interact, **1–4** switch cadet, **Tab** Mission Table, **Space** run the shift,
  **Esc** pause. Full gamepad support. Every control can be remapped.
- **Switching cadets (Solo):** the camera flies to the other cadet in under a second. Each cadet stands in their own
  room by default.

### 3.2 The station (playable space)

A compact hub-and-spoke layout, small on purpose so it reads well on a projector and renders fast:

```
                 [ Air room ]
                      |
 [ Power room ] — [ Mission Table hub ] — [ Garden ] — window → (Alo's chamber, outside)
                      |
                 [ Safe Room ] — [ Airlock ]
```

| Room | Cadet | Main interactive objects |
|---|---|---|
| **Mission Table hub** | All | Holographic table (ghost preview, plan, run), radio screen (Ferreira/Rao), old computer (N.'s message), the battery jar |
| **Power room** | Kai | Heater dial (COZY / COOL / COLD), solar mast status panel |
| **Air room** | Amara | Air maker lever (0 / 1 / 2 drops), air tank with bubbles |
| **Garden** | Mei | Grow lamp switch (OFF / DIM / FULL), Tara, plant trays, big window onto Alo's chamber |
| **Safe Room** | Rafi | Pump valve wheel (FILL / HOLD / DRAIN), water-wall gauge, bunks, crate stack area, radiation counter |
| **Airlock** | — | Locked in Chapter 1 (door glows; "Not tonight, cadet."). Teases later chapters. |

### 3.3 The core loop

**Observe → inspect → share → preview → commit → run the shift → see the consequences → update the plan.**

One shift takes 2–3 minutes:

1. **Secret** (some shifts): one cadet gets a private message: "For Kai only."
2. **Talk and plan:** each cadet sets their console. The Mission Table shows the **ghost preview**: the end of this
   shift if you commit now.
3. **Run:** about 7 hours pass in 6–8 seconds as a time-lapse: the Sun moves, frost or warm light spreads, bubbles
   rise, Alo reacts.
4. **Result:** big icons show what changed and why.

**Key design rule:** the ghost preview shows **this shift only**. The secrets are about **the future** (the long
night, the full tank, the flare, Alo's water). The preview makes every choice understandable; the secrets make
talking necessary.

### 3.4 Final rules and numbers

These numbers are balanced and tested (see §5). Every number lives in one data file in the game, tagged with its
source.

| Resource | Rule |
|---|---|
| **Sun-drops (the jar)** | Holds **15**. Starts with **6**. Sunlight adds **14** per day shift (shifts 1–2) and **6** at Last Light (shift 3), then **0**. Drops arrive and are spent during the shift; anything above 15 at the end of the shift spills and fades. |
| **Base basics** | Always cost **1** drop per shift (CO₂ scrubbers, fans, radio). |
| **Heater (Kai)** | Night shifts only (3–7). **COZY** 2 drops, frost +0 · **COOL** 1 drop, frost +1 · **COLD** 0 drops, frost +2. |
| **Air maker (Amara)** | **0 / 1 / 2** drops → **+0 / +1 / +2** air. The tank holds **8** and starts with **3**. The crew breathes **1** per shift. |
| **Grow lamp (Mei)** | Night shifts only. **OFF** 0 drops, Alo growth −1 · **DIM** 1 drop, ±0 · **FULL** 2 drops, +1. In day shifts, sunlight gives Alo +1 growth for free. |
| **Pumps (Rafi)** | Move water, not drops. **FILL** +2 water into the wall · **HOLD** · **DRAIN** −2. One step per shift. |
| **Water** | One loop of **6** water. Whatever is not in the shelter wall is in Alo's tank. |
| **The storm** | Shift 5 strength **6**, shift 6 strength **3**. Shielding = water in the wall + crates. Dose this shift = strength − shielding (never below 0). |
| **STACK** | Storm shift only. Crates add **+2** shielding for the rest of the storm and use no water. That shift, everyone builds: air maker 0, lamp OFF, heater COOL, pumps HOLD. |
| **If the jar runs short** | The game downgrades settings in this order: lamp, then air, then heater. That is a **blackout** and costs the "Lights on" star. The ghost preview warns before you commit. |

**Alo's three needs** (shown on Alo's face and as three small meters):

| Need | Goes bad when… | Alo dies when… | Mood shown |
|---|---|---|---|
| **Warmth** | the heater is COOL (+1 frost) or COLD (+2) | frost reaches **4** | 🥶 shivering, tiny scarf (frost 2+) |
| **Water** | the wall holds **4 or more** water at the end of a shift (+1 thirst) | thirst reaches **3** | 🥵 drooping leaves (any thirst) |
| **Light** | the lamp is OFF at night (−1 growth) | growth falls to **0** | 😴 closed, pale bud (growth 1–2) |

In the storm, Alo is 😨 scared and hides its buds, but radiation never hurts it: plants are tough.

**Mission rules (crew first):**

- The air tank runs out → **Mission stopped**.
- Storm dose reaches **6** or more → **Mission stopped** (flight rules call the crew home).

### 3.5 Shift-by-shift script

| Shift | Sky | Sun-drops in | Event | Secret delivered | Rao's hint |
|:---:|---|:---:|---|---|---|
| 1 | ☀️ Day | +14 | Tutorial: walk, inspect, preview, run | **Kai:** "Tonight is the longest night of the year: about 36 hours without the Sun. Heat eats drops every night shift." **Amara:** "The jar can't hold all of today's sunlight. Make air now, and the tank keeps it for the night." | Yes |
| 2 | ☀️ Day | +14 | **Storm drill:** practise PUMP (valve task) and STACK (crate puzzle). No real effect. | **Rafi:** "Sunspot 2673 just fired a giant flare. Another big one may come within about two days." | Yes |
| 3 | 🌅 Last Light | +6 | The Sun sets during the time-lapse; masts go dark | **Mei:** "Alo can handle radiation. But frost and thirst can kill it. Don't keep the wall full for long: that's Alo's water." | Yes |
| 4 | 🌍⬇️ Earth-set | 0 | Earth sets at the start; the radio goes to static | — | **No more hints** |
| 5 | ⚡ The Storm | 0 | Alarm. 90-second decision: **PUMP / STACK / WAIT** | — | — |
| 6 | ⚡ Storm | 0 | Particles continue (strength 3) | — | — |
| 7 | 🌑 Last dark | 0 | Will the jar last? | — | — |
| End | 🌄 First Light | — | Ending cutscene, debrief, N.'s message | — | — |

**The storm in numbers** (why getting ready early matters):

| Wall before the alarm | Choice at the alarm | Dose (shift 5 + 6) | Result |
|:---:|---|:---:|---|
| 0 | WAIT | 6 + 3 | Mission stopped |
| 0 | PUMP or STACK | 4 + 1 = 5 | Crew hurt (no ★ Crew safe) |
| 2 | WAIT | 4 + 1 = 5 | Crew hurt |
| 2 | PUMP | 2 + 0 = 2 | Crew safe, but the wall now holds 4: Alo gets thirsty |
| 2 | **STACK** | 2 + 0 = 2 | Crew safe **and** Alo keeps its water (the expert move) |
| 4 | WAIT | 2 + 0 = 2 | Crew safe, but Alo has been thirsty since shift 4 and dies unless the wall is drained in shift 6 |

### 3.6 Mini-tasks (the "hands" of the game)

| Task | Used in | How it plays | Family Mode |
|---|---|---|---|
| **PUMP valve** | Drill, storm | Turn the valve wheel in rhythm with a pressure gauge for 15 s. Class Mode: the class claps the rhythm. | No timer |
| **STACK puzzle** | Drill, storm | 30 s: drag supply bundles around the bunks to cover the gaps in the shield outline (NASA's Orion storm-shelter idea). | No timer, bigger pieces |
| **WAIT** | Storm | A tense countdown; the team watches the counter. | Same |

No task needs rapid button presses.

### 3.7 Stars, endings and debrief

**Stars,** in the order of real mission priorities:

- ★ **Crew safe:** storm dose 3 or less.
- ★ **Lights on:** no blackout.
- ★ **Alo blooms:** Alo is alive at First Light.

| Ending | Condition | Cutscene |
|---|---|---|
| 🌟 **Golden Bloom** | All three stars, and Alo is thriving: growth 6+, frost 2 or less, thirst 1 or less | C06-G: a full golden cluster |
| 🌸 **Bloom** | Alo alive, mission not stopped (stars show how safe the crew and base were) | C06-B: one tiny yellow flower |
| 🥀 **Alo lost** | Alo died (frost, thirst or no light) | C06-L: the chamber at sunrise, frost on the glass. "Try again?" |
| 📡 **Mission stopped** | Air ran out, or storm dose 6+ | C06-S: the rescue lander's lights. "Try again?" |

**Debrief badges** (Space Flight Resource Management skills):

| Badge | Earned when… |
|---|---|
| 🗣️ **Communication** | The team acted on all four secrets (each secret has a tracked "acted on" check, e.g. Amara made 3+ air in daylight) |
| 👀 **Situational awareness** | The wall held 2+ water before the alarm |
| ⚖️ **Decision making** | No blackout |
| 🤝 **Team care** | Crew safe and Alo bloomed |

**Debrief screens:** the night's timeline · who knew what, and when · "what if" (replay with one change, using the same
simulation) · "it was all real" (LROC sunlight map, DONKI storm timeline, CRaTER dose curve, Curiosity's RAD chart).

### 3.8 Modes

| Mode | Changes |
|---|---|
| 🙋 **Solo** (judges, home) | One player switches between all four cadets; secrets arrive in each cadet's inbox (marked "unread" until opened) |
| 👨‍👩‍👧 **Family** (6+ with an adult) | No timers, hints always on, storm strength 4 then 2 |
| 🧑‍🚀 **Cadet** (default, 10–15) | The rules above |
| 🧠 **Engineer** | Real units: 1 drop ≈ 10 kWh, 1 shift ≈ 7.2 h, shielding in g/cm², dose from CRaTER |
| 🏫 **Class** | One projector, four role groups, printed role cards and sealed secret envelopes; each group approves its own setting |

### 3.9 Feedback and "juice"

| Moment | Feedback |
|---|---|
| Sun-drops arrive | Drops fall into the jar with a glassy clink; extra drops spill over the rim and fade |
| Heater COLD | Frost creeps over windows and Alo's glass; breath puffs; cadets wrap blankets |
| Air tank full | Amara blows a bubble; the tank glows cyan |
| Lamp FULL | Warm green-gold light floods the Garden and Alo's chamber |
| Earth-set | Radio static, the comm screen fades to "NO SIGNAL", music drops out |
| Storm | Red alarm light, screen shake (can be turned off), sparks fizzle in the blue water wall |
| First Light | Long golden rays over the crater rim, music swell, petals |

---

## 4. Cutscene list (summary)

Full shot lists and prompts are in [CUTSCENES.md](CUTSCENES.md).

| ID | Name | Length | Type |
|---|---|:---:|---|
| C01 | 2019: the first sprout freezes | 20 s | Pre-rendered (Seedance 2.5) |
| C02 | Aurora Station / title | 25 s | Pre-rendered |
| C03 | Last Light | 15 s | Pre-rendered |
| C04 | Earth-set | 20 s | Pre-rendered |
| C05 | THIS IS NOT A DRILL (sting) | 5 s | Pre-rendered |
| C06-G/B/L/S | First Light: four endings | 15–20 s each | Pre-rendered |
| C07 | Earth-rise: "You ran it." | 15 s | Pre-rendered |
| C08 | N.'s message | 20 s | Pre-rendered |
| — | Crew dialogue scenes (arrival, drill, results) | short | In-engine (real-time) |

---

## 5. Balance check (how the numbers were tested)

We checked the rules above by enumerating **every possible plan** for the 7 shifts (about 286 billion) with a paper
design model (a spreadsheet-style calculation, not game code). Results:

- **Every secret matters.** A team that ignores any one secret loses at least one star:
  Kai's (heater on COZY all night → blackout), Amara's (air made at night → blackout), Mei's (wall kept full → Alo
  lost), Rafi's (no shelter until the alarm → crew dose 4).
- **A fully silent team** ends with one star at most.
- **Many ways to win.** Every setting (including COLD and OFF) appears in some three-star plan. The only exception is
  draining the wall during the storm.
- **Golden Bloom is rare:** about 1 in 9 million random plans (32,892 plans). The expert route prepares the wall a little
  early, makes air in daylight, uses **STACK** in the storm to save Alo's water, and spends the saved drops on
  COZY and FULL in the last shifts.
- **Random play rarely wins:** only about 0.13% of random plans earn all three stars.

**Two example plans:**

| Shift | Informed team (3 stars, Bloom) | Expert team (Golden Bloom) |
|:---:|---|---|
| 1 | Air 2 | Air 1 · FILL |
| 2 | Air 2 | Air 2 · FILL |
| 3 | COZY · DIM · FILL | COZY · Air 1 · FULL · DRAIN |
| 4 | COOL · DIM | COOL · DIM |
| 5 | COOL · DIM · PUMP | **STACK** |
| 6 | COZY · DIM | COZY · FULL |
| 7 | COOL · DIM · DRAIN | COZY · FULL |

These numbers will be re-checked in the paper playtest with students before the hackathon.

---

## 6. Open items for the team

- [ ] Approve this document (story, rules, numbers).
- [ ] Paper playtest with the numbers above (cards + tokens), with guardian permission.
- [ ] Confirm the real night date from LOLA + Horizons at the hackathon (the story only needs "April 2046" until then).
- [ ] Check the Space Apps 2026 rules on assets made before the event (see [ASSETS.md](ASSETS.md)).
