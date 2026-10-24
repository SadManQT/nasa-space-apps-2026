# UI/UX specification

## Design language and reading order

Navy surfaces, warm ivory text, mustard accent, role-colour tabs plus role icon/name. Large rounded type for headings; a licensed humanist sans for body with tested Bangla shaping. Baloo Da2 is a source credit, not a font file present in this repository. Base body 24 px at 1080p, captions 28 px, minimum interactive target 44 px with at least 8 px separation; scale to 150% and reflow. Maintain4.5:1 normal-text contrast and 3:1 large text/nontext controls. These are production targets to test, not measured screenshots. No essential labels rendered into textures. Plain text supports English and Bangla.

## Screen contracts

| Screen | Layout / content | Behavior and feedback | Exit / edge case |
|---|---|---|---|
| Main menu | Left title, New Expedition, Continue, Chapter Replay, Settings, Credits; right station/garden art reflecting latest safe chapter | Continue includes chapter/date; New Expedition explains existing saves remain; unavailable Continue disabled with reason | Back offers quit confirmation; no sign-in |
| New Expedition | Story premise, Family/Cadet/Engineer/Class/Solo choice, assistance presets, captions/language and first-save slot | Default English captionsON, timersOFF for initial accessibility setup; Standard optional 90 s storm response enabled explicitly | Start opens SC-0101; existing slots require overwrite confirmation |
| HUD | Top-left active cadet and current action objective; top-right time/location and comms; bottom-left contextual systems only; bottom-centre captions; bottom-right interaction | Resource deltas appear only during planning/results; minimal HUD during quiet exploration | Hold details optional; no persistent quest clutter or compass across indoor rooms |
| Objective panel | One current action, location name, up to 3 subchecks | Completed subcheck ticks with words; Track shows short floor markers on request | Hidden objectives stay hidden; no future Noor name |
| Dialogue | Lower20–30% shaded panel, speaker/remote/archive tag; choices above interaction strip, backlog button | Auto-advance optional, current line can be held; unknown gardener labelled N. | Skip opens read transcript and preserves facts; choices do not time out |
| Interaction | Object name, verb, control glyph and unmet condition | Inspect, Use, Transfer, Verify, Confirm; no technical state names | Disabled unsafe action says why, never silently ignores input |
| Expedition journal | Left tabs; middle dated list; right image/text/source and relevant objective link | Mission, People, Garden, Evidence, Science; acquired-only entries; unread indicator optional | Back restores exact world position and focus; doesn't advance time |
| Discovery log | Evidence cards with observed/verified/linked badges and timestamps | Pin source beside reconstruction; automatically records required evidence | Optional scans never block story; spoilers gated by scene knowledge |
| Scientific puzzle | Left observed data; centre equipment/slots; right result preview; bottom Undo/Hint/Confirm | Every slot can be selected by focus; H1/H2/H3 explicit; failures describe observation | Dirty plan confirmation on leave; completed physical changes persist only at committed gates |
| Mission Table | Four role observation cards, system summary, forecast, Share, Preview and Commit | Share marks sender and read state; Preview shows exact known deltas; Commit confirmation names consequences | Alarm cannot steal focus while modal open; queued until safe closure |
| Rover | Speed upper-left; next marker/distance centre; return reserve and hours lower-left; local link lower-right | Reserve warning names required margin; Cruise only at validated stops | Motion option hides direct driving and exposes identical route/repair decisions |
| Greenhouse | Plant name/lineage/stage, date, temperature/moisture, care actions and comparison tab | Stress icon includes cause; mature Alo archive visibly distinct from descendants | Harvest disabled until mature; shows “Pods are not ready” |
| Outcome | Named local ending, crew/base/plant outcomes, decision timeline, Retry/Review | Golden/Bloom can continue; Lost/Stopped require retry to advance campaign | No next chapter unlocked by failure; no shaming grade |
| Pause | Resume, Save, Load, Journal, Settings, Return to title | All timers and resources pause; saving shows verified slot/time | Resume consumes the pause input release; no accidental commit |
| Settings | Tabs Controls/Reading/Motion/Audio/Language/Assistance; preview area | Remapping with conflict swap, subtitle size/background, guide outlines, no timers, shakeOFF, horizon lock, volume, dynamic range | Apply reversible; reset confirm; accessibility never reduces ending eligibility |
| Credits | Slow optional auto-scroll, manual scroll, photo+dedication, return garden, skip | Credit source art/audio and science accurately; contributor facts checked before release | Skip still offers optional MARS drawer; no forced teaser |

## Wireframes

```text
EXPLORATION
+---------------------------------------------------------------+
| MEI / Garden          Current: Inspect the sealed packet       |
|                                          Aurora · Apr 11       |
|                     [world remains visible]                   |
|                                                               |
|                [ E ] Inspect · Old storage drawer             |
| [J] Journal                                                   |
|              MEI: Someone gave these seeds a name.             |
+---------------------------------------------------------------+

MISSION TABLE
+---------------------------------------------------------------+
| Plan the next shift                           [Back]            |
| Kai: heat      Amara: stored air      Mei: water     Rafi: wall |
| [Shared ✓]     [Shared ✓]              [Read]        [Shared ✓] |
| OBSERVED              SETTINGS              PREVIEW            |
| Battery 16/20         Heat [COOL]          Battery 13 (-3)      |
| Air 8/10              Air [OFF]            Air 7 (-1)           |
| Wall 2/6              Lamp [DIM]           Garden water 4      |
| Alo health 6              Pump [HOLD]          COOL: Alo health -1   |
| [Hint] [Undo]         [Preview]             [Commit shift]      |
+---------------------------------------------------------------+

JOURNAL
+---------------------------------------------------------------+
| Mission | People | Garden | Evidence | Science                 |
| April27 First bloom    | [image] Alo's first flower             |
| May6 Engineer voice | Observed at Aurora · recording         |
| May21 Forty-two        | Lineage: Alo × Tara                    |
|                        | 12 planted / 30 protected              |
|                        | [Transcript] [Related objective]       |
+---------------------------------------------------------------+
```

## Chapter 1 onboarding and HUD disclosure (GAME-04)

Loop shown to the player: **Observe → Discuss → Choose → Execute → See impact → Debrief/retry.**

- **First decision inside the first minute:** the SC-0101 commissioning choice, before any long dialogue.
- **Progressive emphasis, same model:** all eight P-02 values exist and are simulated from shift 1. The HUD *emphasises* only the ones in play and keeps the rest under an **All systems** expander, which is always one press away:

| Moment | Emphasised | Introduced by |
|---|---|---|
| SC-0101 | Battery jar (E), spill counter | Commissioning choice |
| Shift 1 | E, Air (A) | Kai and Amara cards |
| Shift 2 (drill) | + Water wall (W), crates (K) | Drill, Rafi card |
| Shift 3 | + Alo health (H), crop (C), heat | Mei card, DL-0105-08 to 12 |
| Shift 5 | + Storm dose (Z) | Particle alarm |
| Always under All systems | Rations (R) | Engineer Mode shows it inline |

- **Every control shows its cost** as a chip before selection (“−2 drops”, “Alo −1”), with words as well as the icon.
- **The preview uses the same simulation function as Commit** and shows exact deltas. Unknown future events show as “not known yet”, never as a hidden number.
- **The commit point is explicit:** “Commit shift 3? Uses 3 drops. This can’t be undone. Retry restores this checkpoint.” Space, then a confirmation; no dialogue reply commits.
- **Alarm response panel:** the first line, already ticked and locked, reads “Crew into Safe Room: required (flight rule)”. PUMP / STACK / WAIT follow, each with its cost and the previewed dose.
- **Tutorial cards** are skippable and replayable from the journal and never change any value. In playtests, a novice should be able to say the current objective in their own words after shift 1 (recorded per GAME-09).

## Evidence chips (GAME-06)

Every science-bearing display carries one chip, **OBSERVED**, **COMPUTED** or **SIMULATED** (definitions and source-card fields in [scientific accuracy](16_SCIENTIFIC_ACCURACY.md#three-evidence-labels-story-04-game-06)). Chips use text plus icon, never colour alone, and open the source card on select.

| Chapter 1 display | Chip |
|---|---|
| Storm timeline / Rafi forecast | OBSERVED · *Historical replay 2017, re-dated* |
| Dose meter (zaps) | SIMULATED (until calibrated to CRaTER; then COMPUTED for the curve only) |
| Battery, air, Alo, crop, rations | SIMULATED |
| Horizon strip, Last Light, Earth-set countdown | SIMULATED · *training scenario* until the register row is signed off |
| “Why here?” illumination map | OBSERVED (LROC) |
| Debrief Moon/Mars radiation charts | OBSERVED (CRaTER, MSL RAD) when bundled; otherwise omitted, not faked |

## Chapter 1 debrief (GAME-07)

The same five panels appear for all four endings, in this order:

1. **Outcome line:** crew safety, station status (blackout or not), Alo’s state, plus the named ending.
2. **Most influential decision:** the single shift change that would most improve the outcome. It is found by re-running the real P-02 update with one shift altered at a time, and only safe alternatives are considered (crew sheltered, Z≤3). Shown as “Shift 4: FILL → HOLD would have left Alo +1.”
3. **One trade-off, explained:** a cause→effect sentence plus an evidence chip, such as “The wall borrowed garden water; at 4 or more, Alo goes thirsty.”
4. **Compare / retry:** “Try this change” replays from that checkpoint with the real rules, and the side-by-side result uses the same arithmetic as play. No suggestion ever drops crew shelter to gain flower health.
5. **Who knew what:** card receipt, sharing and the shift-3 preview comparison, plus one sentence on where discussion changed the plan (GAME-05).

Optional comprehension check: three questions answered by choosing an option, never scored against the ending. 1) Why make air in daylight? 2) Why does the shelter water hurt Alo? 3) Which label means “a real measurement”? Alo lost and Mission stopped use the same calm tone as a bloom. There are no grades and no blame words.

## Microcopy and feedback

“Link unavailable: Earth is below Aurora's terrain horizon.” “Local radios connected.” “Open housing: isolate power first.” “Sample unverified: record the dry reference.” “Reserve too small for the return.” “Pause time before trying again.” Normal screens never display story flags, source file paths or implementation IDs. The science journal may display dataset names because the player deliberately asks for evidence.

Keep explicit historical-replay and counterfactual labels in the science presentation. First Science page says: “A fictional expedition, informed by real observations. Some measurements and timelines are simplified for play.” Source details sit behind Read the science, leaving the adventure free of technical disclaimers during emotional scenes.
