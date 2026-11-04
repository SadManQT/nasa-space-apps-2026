"""Build game/resources/campaign/content/mission_data_cards.json (board M1-30).

Every visual number is read from the bundled fixtures by path, so nothing is retyped.
Run: python3 -I production/tools/build_mission_cards.py <repo root>   (writes the JSON and prints the checks)
"""
import json, re, sys
from pathlib import Path

ROOT = Path(sys.argv[1])
NASA = ROOT / "game/resources/data/nasa"
OUT = ROOT / "game/resources/campaign/content/mission_data_cards.json"
FIX = {p.stem: json.loads(p.read_text()) for p in NASA.glob("*.json") if p.stem != "puzzle_sources"}
CATALOG = json.loads((ROOT / "game/resources/campaign/content/campaign_catalog.json").read_text())
TITLES = {m["id"]: m["title"] for m in CATALOG["missions"]}


def get(ref):
    """'fixture path' -> value. Path parts: key, [n], [*] (map over list), derived:name."""
    fid, path = ref.split(" ", 1)
    cur = [FIX[fid]]
    many = False
    for part in re.findall(r"derived:[\w]+|\[\*\]|\[-?\d+\]|[^.\[\]]+", path):
        if part.startswith("derived:"):
            name = part.split(":", 1)[1]
            cur = [next(d["value"] for d in c["derived"] if d["name"] == name) for c in cur]
        elif part == "[*]":
            cur = [x for c in cur for x in c]
            many = True
        elif part.startswith("["):
            cur = [c[int(part[1:-1])] for c in cur]
        else:
            cur = [c[part] for c in cur]
    return cur if many else cur[0]


def series(ref, every=1):
    vals = get(ref)
    vals = vals[::every]
    return [v for v in vals if v is not None]


METERS = ["power", "life", "shielding", "food", "none"]

# --- the 32 cards ---------------------------------------------------------------------------
# plain: (1) plain sentences; visual: (2); aurora: (3) tied to an Outpost Status meter
# (game/resources/campaign/outpost_status.json group id; "rover" = the separate rover battery);
# sources: (4) fixture ids, primary first. Game numbers come from game-design/08_PUZZLE_DESIGNS.md.
C = []

def card(mid, puzzle, decision, sources, plain, visual, meter, fields, aurora, limits, q, a, game_numbers, extra_sources=None):
    C.append(dict(mid=mid, puzzle=puzzle, decision=decision, sources=sources, plain=plain, visual=visual,
                  meter=meter, fields=fields, aurora=aurora, limits=limits, q=q, a=a,
                  game_numbers=game_numbers, extra_sources=extra_sources or []))

# Chapter 1 ------------------------------------------------------------------------------------
card("EX-M0101", "P-01",
     "Send spare commissioning power to stored air or to the planting-bay lamp, and choose which record is made first.",
     ["jpl_horizons_pole_season"],
     "At the Moon's south pole, the Sun never climbs high. In 2046 and 2047 it stays within about 1.6 degrees of the horizon. That is less than the width of your thumb held at arm's length.",
     dict(kind="line", every=7, values="jpl_horizons_pole_season values.daily[*][1]",
          start="jpl_horizons_pole_season values.daily[0][0]", end="jpl_horizons_pole_season values.daily[-1][0]",
          unit="degrees", labels=["Sun's height at the pole (degrees), 2046 to 2047", "0 is the horizon", "Highest: 1.59 degrees"],
          note="Every 7th daily value is drawn; the 1.59 label is the fixture's computed maximum."),
     "power", ["E"],
     "Aurora's solar power comes from low, sideways sunlight. The battery holds at most 20 units, so power that does not fit is lost. Making stored air now turns spare power into something the crew can use later.",
     "Computed with NASA JPL's Horizons service for a flat horizon at the exact pole. Hills, crater rims and Aurora's real site change the sunlight it gets.",
     "Why put spare power into stored air?",
     "A full battery cannot take more. Air made now uses power that would otherwise be lost, and the crew needs that air later.",
     "P-02 contract: battery cap 20; air production O costs the same energy it adds.")

card("EX-M0102", "P-01",
     "Plant Alo and Tara, keep a fair care record (photos plus conditions), and choose when borrowed shelter water goes back to the garden.",
     ["osdr_brassica_rapa_iss"],
     "Alo's species, Brassica rapa, has grown in space before. On the International Space Station, a leafy kind called mizuna grew for 27 days in the Lada greenhouse. Its lamps gave between 125 and 250 units of the light plants use.",
     dict(kind="gauge", values="osdr_brassica_rapa_iss values.OSD-59.par_umol_m2_s",
          marks="osdr_brassica_rapa_iss derived:full_lamp_par_reference",
          unit="micromoles of light per square metre per second",
          unit_plain="A count of the light that lands on each square metre of leaf every second.",
          labels=["Plant light", "Space Station mizuna: 125 to 250", "Veggie ground tests: 200 to 300"]),
     "food", ["C"],
     "Light feeds the garden but costs power. A FULL lamp costs 2 units a shift, DIM costs 1 and OFF costs 0, but OFF makes plants weaker. Writing the lamp setting beside each photo shows why a plant changed.",
     "The Space Station plants grew while floating, not in Moon gravity. Aurora's OFF, DIM and FULL settings are game units, not measured light.",
     "Why keep a conditions table beside the photos?",
     "Photos show what changed. The table shows why: light, water and warmth. You need both to compare two plants fairly.",
     "P-02 contract: light OFF/DIM/FULL costs 0/1/2 and changes plants by -1/0/+1.")

card("EX-M0103", "P-02",
     "Split daylight energy between stored air and the garden lamp, and rehearse moving water into the shelter wall and back.",
     ["lro_mazarico_2011_illumination"],
     "Even the sunniest places near the south pole have nights. Scientists used maps from NASA's LRO laser altimeter to calculate the sunlight at one spot on the rim of Shackleton crater. Its longest stretch of total darkness is about 1.5 days.",
     dict(kind="bar", values="lro_mazarico_2011_illumination values.longest_darkness_days", unit="days",
          labels=["Longest total darkness at the LRO study spot", "About 1.5 days, or 36 hours", "Aurora's night: 5 shifts of 7.2 hours = 36 hours"]),
     "power", ["E", "A"],
     "In daylight shifts 1 and 2 the panels add 8 units each. Then come 36 hours with no solar power at all. Air, warmth and lamp light for the whole night must come from what you store now.",
     "This is one modelled spot, not Aurora's site. Aurora's 36-hour night is a training scenario sized to match it.",
     "Why can a plan that feels comfortable at sunset run short before dawn?",
     "Every unit used early is gone for the rest of the night. Nothing refills the battery until the Sun returns.",
     "P-02: day income +8 in shifts 1-2; shifts 3-7 dark, 7.2 h each.")

card("EX-M0104", "P-02",
     "When the storm alarm sounds, WAIT if the prepared shelter is enough, or choose one PUMP or STACK action; then send the borrowed water home.",
     ["goes13_protons_2017_09", "donki_2017_09"],
     "On 10 September 2017, a huge flare and a very fast cloud of solar gas sped up a storm of protons. Protons are tiny, fast pieces of atoms. Seventy minutes after the flare began, a weather satellite near Earth measured the proton storm.",
     dict(kind="line", values="goes13_protons_2017_09 values.hourly[*][1]",
          start="goes13_protons_2017_09 values.hourly[0][0]", end="goes13_protons_2017_09 values.hourly[-1][0]",
          unit="pfu", unit_plain="pfu: how many protons cross each square centimetre every second, from one patch of sky.",
          labels=["Fast protons near Earth, 10 to 12 September 2017", "Storm level (10 pfu) reached at 16:45 UTC", "West-facing sensor's highest 5-minute reading: 1,347 pfu"],
          note="Hourly means from the west-facing sensor are drawn; the 1,347 label is its 5-minute maximum, so the line peaks lower. NOAA's official peak, 1,490 pfu at 11:45 UTC on 11 Sep, is from the east-facing sensor."),
     "shielding", ["S", "Z"],
     "Aurora replays this storm in dark shifts 5 and 6. Wall water (W) plus supply crates (K) make shelter S, up to 6, and more shelter means less exposure Z. If Z goes above 3 the mission stops, and after the storm the water must go back to the garden.",
     "GOES-13 measured this 36,000 km above Earth, where Earth's magnetic field barely slows protons this fast. The Moon has no magnetic field or air, so a storm like this reaches its surface. This is a flux, not a dose at the Moon. The real storm stayed above storm level for about three and a half days. Aurora's replay shortens it to two shifts; that is a game rule. The 2046 night and Aurora are fiction, and exposure Z is a game score, not a real radiation dose.",
     "When is WAIT the right choice?",
     "When the wall was filled before the alarm. Shelter must be ready before the protons arrive, and the water goes back to the garden afterwards.",
     "P-02: S = min(6, W + K); dose per storm shift 3/2/1/0 for S 0-1/2-3/4-5/6; Z <= 3.")

# Chapter 2 ------------------------------------------------------------------------------------
card("EX-M0201", "P-03",
     "Choose the compatible partner and a sealed, labelled route for carrying pollen between the two greenhouses.",
     ["fast_plants_lifecycle"],
     "Alo and Tara are Fast Plants, a quick-growing kind of Brassica rapa. A Fast Plant cannot make seeds with its own pollen, the yellow dust inside a flower. The pollen has to come from a different, matching plant.",
     dict(kind="bar", values="fast_plants_lifecycle values.seed_harvest_days_after_planting",
          marks=["fast_plants_lifecycle values.days_to_flower", "fast_plants_lifecycle values.pollinate_days_after_planting"],
          unit="days after planting",
          labels=["A Fast Plant's life: about 40 days", "First flowers: about day 14", "Best days to pollinate: 15 to 21"]),
     "food", ["C"],
     "There are no bees on the Moon, so the cadets carry pollen by hand. Each two-way pollen run costs 1 power unit and 1 air unit. The carrier stays sealed so the route keeps its air.",
     "These timings are for ideal classroom growing on Earth. Growing on the Moon and Alo's exact dates are fiction.",
     "Why can't Alo use its own pollen?",
     "Fast Plants are self-incompatible: their own pollen does not make seeds. They need a different, compatible plant, like Tara.",
     "P-03: E1/A1 per reciprocal run; runs on days 1, 4 and 7.")

card("EX-M0202", "P-03",
     "Make three two-way pollen runs over seven dated care days, then record an honest stem-colour prediction.",
     ["mir_brassica_seed_to_seed", "fast_plants_lifecycle"],
     "Has this worked in space before? Yes. On the Mir space station, a NASA-funded experiment grew Brassica rapa from seed to new seed. The plants were pollinated by hand during a 122-day run.",
     dict(kind="bar", values="mir_brassica_seed_to_seed values.mission_days",
          marks="fast_plants_lifecycle values.seed_harvest_days_after_planting", unit="days",
          labels=["Days", "Mir experiment: 122 days", "One Fast Plant life cycle: about 40 days"]),
     "food", ["C"],
     "Three careful runs, on 30 April, 3 May and 6 May, give Alo and Tara their best chance of seeds. Each run costs 1 power and 1 air. Moving pollen is only the first step; seeds still need weeks to form.",
     "Mir was weightless, while the Moon has gravity. Alo's dates and seed count are fiction.",
     "You predicted the seedlings' stem colours. Is that a promise?",
     "No. A prediction is a guess you can test. The next generation's stems will show what really happened.",
     "P-03: three reciprocal runs on days 1, 4 and 7 (30 April to 6 May), E1/A1 each.")

card("EX-M0203", "P-04",
     "Wait for the pods instead of rushing them, collect the label evidence, and match date, device and channel to rebuild the old recording.",
     ["fast_plants_lifecycle"],
     "After a flower is pollinated, its seed pods take about 20 days to ripen. Fast Plant seeds are ready about 40 days after planting. No button can make them grow faster.",
     dict(kind="bar", values="fast_plants_lifecycle values.pod_maturity_days_after_pollination", unit="days",
          labels=["Days from pollination to ripe pods", "About 20 days", "Seeds ready about 40 days after planting"]),
     "food", ["C"],
     "Alo was planted on 11 April 2046, so its seeds will not be ready until about 21 May. Until then the job is steady care. Rushing could ruin the seeds Aurora is waiting for.",
     "These are ideal classroom timings on Earth; real plants vary with light, warmth and variety. Alo's dates are story dates.",
     "The 2034 chart shows plants that never flowered. Does that make Alo's bloom less of a first?",
     "No. That earlier trial stopped before any flowers. It reached a different stage, so Alo's bloom is still the first.",
     "P-04 tokens (2034-04, HORT-01, ENGINEERING) are fiction; P-06 harvest on plant day 40.")

card("EX-M0204", "P-04",
     "Treat the familiar voice as a guess to check, send the evidence to Ferreira, and drop everything for a roll call when the floor shakes.",
     ["apollo_shallow_moonquakes"],
     "The Moon has quakes too. Apollo astronauts left seismometers, instruments that feel the ground shake. From 1971 to 1976 they recorded 28 shallow moonquakes. The strongest measured 3.2 on the catalogue's own scale.",
     dict(kind="line", values="apollo_shallow_moonquakes values.quakes[*].magnitude",
          start="apollo_shallow_moonquakes values.quakes[0].date", end="apollo_shallow_moonquakes values.quakes[-1].date",
          unit="catalogue magnitude", labels=["Strength of each shallow moonquake", "28 quakes, 1971 to 1976", "Strongest: 3.2"]),
     "life", ["A"],
     "When the floor shakes, people come first: roll call, then check the air pressure. A quake can loosen a seal, and a leak drains air.",
     "Recorded by Apollo stations near the Moon's equator, far from the pole. The catalogue uses its own magnitude scale, so do not compare it directly with earthquake numbers. Aurora's quake is fiction.",
     "Why stop listening to the recording when the floor shook?",
     "A new hazard changes priorities. A recording can wait; checking that everyone is safe and the air is holding cannot.",
     "P-05: an unsealed leak costs 1 air per phase.")

# Chapter 3 ------------------------------------------------------------------------------------
card("EX-M0301", "P-05",
     "Compare three pressure taps and choose the smallest safe isolation: the garden spur, not the whole habitat trunk.",
     ["bvad_2022_metabolic"],
     "Air pushes on everything around it, and that push is called pressure. It is measured in kilopascals, or kPa. The Space Station keeps its air at 101.3 kPa, the same as air at sea level on Earth. A pressure reading that keeps falling means air is escaping.",
     dict(kind="bar", values="bvad_2022_metabolic values.cabin_pressure_iss_kPa", unit="kPa",
          labels=["Cabin air pressure (kPa)", "Space Station: 101.3 kPa, like sea level on Earth"]),
     "life", ["A"],
     "Aurora's GARDEN tap fell from 82 to 74 test units while MAIN and RETURN stayed at 100. That points to the garden line, so close only that valve. Until the leak is sealed it costs 1 extra air unit each phase.",
     "Aurora's gauges show relative test units, not kPa. BVAD values are NASA planning numbers, not measurements from Aurora.",
     "Why close only the GARDEN valve?",
     "Only the garden reading fell. Closing the whole habitat trunk would shut off more than needed and still not find the leak.",
     "P-05: MAIN 100, GARDEN 82 then 74, RETURN 100 (relative test units); leak A1 per phase.")

card("EX-M0302", "P-05",
     "Reopen only when the mechanical hold and five steady readings agree, correct the copied note to match, and inspect the annex by camera first.",
     ["apollo_shallow_moonquakes"],
     "Most of the moonquakes Apollo recorded were far from the south pole. One, on 13 March 1973, seems to have started near 84 degrees south. It ties for the strongest in the list, but its exact spot is uncertain.",
     dict(kind="line", values="apollo_shallow_moonquakes values.quakes[*].lat",
          start="apollo_shallow_moonquakes values.quakes[0].date", end="apollo_shallow_moonquakes values.quakes[-1].date",
          unit="degrees latitude", labels=["Where each moonquake started (latitude; -90 is the south pole)", "Most were far from the pole", "13 March 1973: about 84 degrees south"],
          note="27 of 28 quakes have a location; the one without is left out."),
     "life", ["A"],
     "A repair only counts when it is measured. Aurora reopens the garden line slowly and needs five steady readings of 100 in a row. An aftershock can open another branch, so its automatic isolation must be checked too.",
     "The 1973 location is uncertain, and the Apollo stations were far away near the equator. Aurora's aftershock is fiction.",
     "The clamp animation finished. Is the leak fixed?",
     "Not yet. A finished action is not a verified repair. Five steady readings of 100 prove the clamp holds.",
     "P-05: five 2-second checks reading 100; phase-2 aftershock opens the annex branch.")

card("EX-M0303", "P-06",
     "Decide what the 2034 annex really shows, treat the old map as a plan to verify, and open Alo's pods only after the dry-down.",
     ["fast_plants_lifecycle"],
     "Fast Plant seeds are ready to harvest about 40 days after planting. The pods ripen first, and then they dry. Only then are the seeds taken out and counted.",
     dict(kind="bar", values="fast_plants_lifecycle values.seed_harvest_days_after_planting", unit="days after planting",
          labels=["Days from planting to seed harvest", "About 40 days", "Alo: planted 11 April, harvested 21 May"]),
     "food", ["C"],
     "The 2034 annex holds only young seedlings with curled leaves: no buds, no flowers. Alo's pods ripen on 16 May and dry until 21 May before they are opened. Ripe is not the same as ready.",
     "Ideal classroom timing on Earth. The annex, its 2034 trial and Alo's dates are fiction; the drying moisture numbers are game values.",
     "Why open the pods only after the dry-down?",
     "Ripening, drying and harvesting are separate steps. Each step has its own check before the next one starts.",
     "P-06: maturity 16 May (plant day 35); dry-down to moisture 20 by 21 May (plant day 40).")

card("EX-M0304", "P-06",
     "Count 42 seeds, seal 12 for planting and 30 for the reserve, plant only the 12, and plan care and supplies through October.",
     ["bvad_2022_metabolic"],
     "NASA plans about 0.8 kg of food for each astronaut each day. That weight does not count the water in the food. It gives about 3,050 food Calories of energy.",
     dict(kind="bar", values="bvad_2022_metabolic values.food_solids_kg_per_crew_day", unit="kg per person per day",
          labels=["Food per astronaut per day, without water", "0.8 kg", "Energy: about 3,050 Calories a day"],
          note="Calories computed from the fixture: 12.778 MJ / 4.184 kJ per kcal = 3,054 kcal."),
     "food", ["R", "C"],
     "A small garden is a fresh extra, not the crew's whole menu. Stored rations, counted in crew-days, still feed the cadets between supply deliveries. That is why 30 seeds stay sealed: they protect Alo's line, not today's dinner.",
     "BVAD values are NASA planning averages for a reference crew member. Aurora's crop and ration units are game units.",
     "Why plant only 12 seeds instead of all 42?",
     "Twelve grow the garden now, and 30 stay sealed in case something goes wrong. A ledger counts each seed exactly once.",
     "P-06: 42 = 6 x 7, 12 planting + 30 reserve; P-02 food layer (a harvest is a small supplement).")

# Chapter 4 ------------------------------------------------------------------------------------
card("EX-M0401", "P-07",
     "Read the descendant sample honestly, charge each person to one supply ledger, and pick the route that passes both the slope and the return-reserve rules.",
     ["viper_slope_limit"],
     "NASA designed its VIPER Moon rover to climb slopes of up to 15 degrees. Steeper ground is beyond what it was built for. A route must respect that limit, even when it is shorter.",
     dict(kind="gauge", values="viper_slope_limit values.max_incline_deg", marks_game=[12, 24], unit="degrees",
          labels=["Rover slope limit: 15 degrees", "Route B, ridge: 12 degrees (passes)", "Route A, short: 24 degrees (fails)"]),
     "rover", ["rover battery"],
     "Route B is 12 km instead of 8, but it is safe. It costs 30 rover units each way, so 100 - 30 - 30 leaves 40, above the 30-unit return reserve. Route C fails both rules.",
     "VIPER's figure is a design value for one rover. Aurora's rover, its routes and their slopes are game numbers.",
     "Route A is the shortest. Why not take it?",
     "Its 24-degree slope is steeper than the rover's 15-degree limit. A valid route must pass every hard rule, not just be short.",
     "P-07: routes A 8 km/24 deg, B 12 km/12 deg, C 10 km/18 deg; rover 100, reserve 30; costs 35/30/40 each way.")

card("EX-M0402", "P-07",
     "Cross a blind corner only after the next beacon link is tested, tag only samples above the calibrated threshold, and keep the vault find in its own record.",
     ["lcross_water_2009"],
     "In 2009, NASA's LCROSS mission crashed a used rocket stage into Cabeus, a dark crater near the south pole. Instruments studied the cloud it threw up. The soil there held about 5.6% water ice by mass, give or take 2.9%.",
     dict(kind="bar", values="lcross_water_2009 values.water_ice_mass_percent", error="lcross_water_2009 values.uncertainty_percent",
          unit="% of mass", labels=["Water ice in Cabeus soil", "5.6%, give or take 2.9%", "Measured at one impact site only"]),
     "life", [],
     "No meter moves today; this decides what Aurora can honestly report about future water. The scanner reads 2 on a dry reference, so only readings above 12 count. Samples 18 and 19 pass, and the 2 stays as the control.",
     "One impact site in one crater. Ice is not everywhere, and ice is not drinking water until it is mined and cleaned. Aurora's sample site is fiction.",
     "Why measure a dry reference before scanning samples?",
     "Without a reference you cannot tell a real signal from the instrument's normal reading. The control makes the claim fair.",
     "P-07: dry reference 2; samples 2, 18, 19; threshold = reference + 10 = 12.")

card("EX-M0403", "P-08",
     "Keep the vault's biological seal closed in the field, prove the cargo latch with a lock test, and log forecast and actual reserves side by side.",
     ["diviner_cold_traps"],
     "NASA's LRO spacecraft carries Diviner, a tool that measures heat. In one dark crater near the south pole, the ground just under the surface is estimated at 38 kelvin. That is minus 235 degrees Celsius. Kelvin counts up from the coldest possible temperature.",
     dict(kind="bar", values="diviner_cold_traps derived:cold_trap_celsius", unit="degrees Celsius",
          labels=["Cold-trap soil temperature", "38 kelvin = minus 235 degrees C", "Water freezes at 0 degrees C"]),
     "food", [],
     "The vault's outer case is very cold. Opening it outside, or warming it fast, could let water condense on the seeds, like drops on a cold glass. It travels sealed and warms in three steps inside a dry glovebox.",
     "Diviner measured natural cold traps. The vault, its site and its seeds' temperature history are fiction, and the seeds were not necessarily at 38 kelvin.",
     "Why not open the lid as soon as you find the vault?",
     "Cold seeds meeting warm, damp air can get wet from condensation. Keeping the case sealed until a controlled warm-up protects both the evidence and the seeds.",
     "P-08: probe, sleeve, cradle, mount; three-stage sealed warm-up; condensation check before opening.")

card("EX-M0404", "P-08",
     "Inventory the 12 specimens without assuming they are alive, send the inscription to Ferreira as a question, and plan her real journey to Aurora.",
     ["kaguya_shackleton_floor"],
     "Japan's Kaguya spacecraft photographed the floor of Shackleton crater. The floor is colder than 90 kelvin, which is about minus 183 degrees Celsius. Yet its camera saw no patches of pure ice.",
     dict(kind="bar", values="kaguya_shackleton_floor derived:shackleton_floor_celsius_below", unit="degrees Celsius",
          labels=["Shackleton crater floor temperature", "Below about minus 183 degrees C", "No pure ice seen at 10-metre detail"]),
     "food", [],
     "Being cold did not prove there was ice. In the same way, a label does not prove a seed is alive. The 12 specimens stay in quarantine, kept apart, until tests show they can grow.",
     "Ice may still be mixed into the soil below what Kaguya could see. The vault and its specimens are fiction.",
     "The vault list says 12 specimens. Are they healthy?",
     "We do not know yet. A record tells us what is there, not whether it lives. Quarantine and a test come first.",
     "P-08: 12 distinct specimens; quarantine pending viability.")

# Chapter 5 ------------------------------------------------------------------------------------
card("EX-M0501", "P-09",
     "Recompute the forecast for five people when Ferreira arrives, keep corrections visible, and rebuild the 2034 departure from timestamps.",
     ["bvad_2022_metabolic"],
     "NASA plans that each astronaut breathes about 0.9 kilograms of oxygen a day. When a fifth person moves in, the base needs a quarter more air than with four. The rooms stay the same size, but the need grows.",
     dict(kind="bar", values="bvad_2022_metabolic derived:air_per_shift_by_crew.5", marks="bvad_2022_metabolic derived:air_per_shift_by_crew.4",
          unit="air units per 7.2-hour shift", labels=["Air used per 7.2-hour shift (game units)", "4 people: 1 unit", "5 people: 1.25 units"]),
     "life", ["A", "R"],
     "From 12 December, every shift costs 1.25 air units and 1.5 crew-days of food instead of 1 and 1.2. A forecast made for four people would run out early.",
     "BVAD gives planning averages for a reference crew member. One game air unit stands for about 1.07 kg of oxygen: four people over one shift.",
     "Ferreira's arrival changed no machine. Why did the forecast change?",
     "More people breathe and eat more. Consumption follows the people actually aboard.",
     "P-10/P-13: five-person breathing 1.25 and food 1.5 per 7.2-hour step; P-02: four-person 1 and 1.2.")

card("EX-M0502", "P-09",
     "Read the archived growth record correctly, and ask the questions that repair trust while keeping the station working.",
     ["change4_cotton"],
     "A plant trial can end early. In 2019, a cotton seed sprouted inside China's Chang'e-4 lander on the Moon. It grew a first green leaf, but never flowered.",
     dict(kind="gauge", values=["change4_cotton values.germinated", "change4_cotton values.flowered"], unit="yes or no",
          labels=["Chang'e-4 cotton, 2019", "Sprouted: yes", "Flowered: no"]),
     "food", [],
     "The 2034 record shows the same kind of story: young seedlings with curled leaves and no buds. That trial stopped before flowering, so Alo's bloom stays the first. Getting the stage right keeps Aurora's history honest.",
     "Chang'e-4 was a small sealed experiment, not a garden. Aurora's 2034 trial is fiction.",
     "Did the old garden ever flower?",
     "No. The record shows seedlings only. A young seedling and a flowering plant are different stages of life.",
     "Story canon: the annex holds young, unflowered seedlings with curled leaves only.")

card("EX-M0503", "P-10",
     "Count only flashes that change between frames, reject the fixed detector spots, clean the dusty panel, patch the leaking spur, and keep the report's claims bounded.",
     ["meo_lunar_impact_flashes", "vsat_relocatable_array"],
     "When a small space rock hits the Moon, it can make a quick flash of light. NASA watches the dark part of the Moon with two telescopes about 10 nights a month. A flash counts only if both telescopes see it.",
     dict(kind="bar", values="meo_lunar_impact_flashes values.calibrated_flashes_first_5_years", unit="flashes",
          labels=["Confirmed impact flashes, first 5 years", "126 flashes", "62% came during meteor showers"]),
     "power", ["E", "A"],
     "Two of Aurora's candidates are detector glitches that stay in one spot; real flashes change. Cleaning the dusty panel brings daylight income back from 6 to 8. Patching the dome spur stops the extra loss of 1 air unit each phase.",
     "NASA's telescopes are on Earth. Aurora's eight candidates, its six-flash goal and the dust loss are game values.",
     "How can you tell a real flash from a glitch?",
     "A real flash changes from frame to frame. A detector fault stays in the same spot. Checking more than one frame tells them apart.",
     "P-10: 8 transients + 2 artifacts, 6 verified; dust 8 to 6; leak 1 air per unresolved phase.")

card("EX-M0504", "P-10",
     "Match the signed record to Dr Noor Rahman, invite contact without demanding it, and plant the vault's cotton seed.",
     ["change4_cotton"],
     "The first green leaf grown on the Moon was cotton. It sprouted inside China's Chang'e-4 lander in 2019, but it never flowered. Aurora's cotton will try to go further.",
     dict(kind="gauge", values=["change4_cotton values.germinated", "change4_cotton values.flowered"], unit="yes or no",
          labels=["Cotton on the Moon, 2019", "Sprouted: yes", "Flowered: no"]),
     "food", ["C"],
     "Noor's cotton seed is planted on 15 December, which leaves 11 vault specimens in storage. The album's 16 entries are records, not 16 seeds. Each living plant and each stored seed is counted once.",
     "Chang'e-4 was a sealed experiment and did not forecast Aurora's garden. Aurora's cotton is fiction.",
     "After planting the cotton, how many vault specimens are stored?",
     "Eleven. Twelve specimens minus one planted cotton seed. The 16 album entries describe knowledge, not extra seeds.",
     "Story canon: 12 vault specimens, cotton planted 15 Dec, 11 stored.")

# Chapter 6 ------------------------------------------------------------------------------------
card("EX-M0601", "P-11",
     "Turn the crew's needs into one checked eclipse budget: essentials in all five segments, the pump once, the camera once, no decorative floods.",
     ["nasa_eclipse_2047_01_12"],
     "On 12 January 2047, the Moon will pass through Earth's shadow. That is a total lunar eclipse. NASA's eclipse catalogue shows that any one spot on the Moon stays in the darkest shadow for between 70 and 209 minutes.",
     dict(kind="bar", values="nasa_eclipse_2047_01_12 derived:point_full_shadow_bounds_min[1]", marks="nasa_eclipse_2047_01_12 derived:point_full_shadow_bounds_min[0]",
          unit="minutes", labels=["Time one spot spends in Earth's darkest shadow", "At least 70.0 minutes", "At most 208.9 minutes"]),
     "power", ["E"],
     "While Earth blocks the Sun, Aurora's panels make no power. The plan keeps 7 of the 14 stored units: essentials in all five segments, plus the pump once and the camera once. Decorative floodlights cost 3 each and would break the budget.",
     "Catalogue times are for the whole Moon. Aurora's own times depend on its exact site, which is not fixed yet. The seven-unit split is a stated game fallback.",
     "Why are floodlights not part of the plan?",
     "Each flood costs 3 units. Five essentials, one pump and one camera already use the 7 protected units.",
     "P-11: essentials 1 per segment, pump 1, camera 1, floods 3 each; total 7 of 14.")

card("EX-M0602", "P-11",
     "Choose the small guide-light route over decorative floods, rehearse isolating a fault on the paused model, and close the readiness call with a shared checklist.",
     ["jpl_horizons_pole_season"],
     "On eclipse day, 12 January 2047, the Sun at the south pole is barely up. NASA JPL's calculation puts it just 0.14 degrees above a flat horizon. Light is scarce even before Earth's shadow arrives.",
     dict(kind="bar", values="jpl_horizons_pole_season derived:sun_elevation_2047_01_12", marks="jpl_horizons_pole_season derived:sun_elevation_range[1]",
          unit="degrees", labels=["Sun's height at the pole", "12 January 2047: 0.14 degrees", "Highest in 2046 to 2047: 1.59 degrees"]),
     "power", ["E"],
     "Every stored unit matters tonight. The small guide-light route gives a safe path at a low cost, while floodlights would look brighter but use 3 units each. The best plan meets the need and keeps the reserve.",
     "Computed for a flat horizon at the exact pole. Aurora's ridge and nearby hills change the real sunlight.",
     "Why rehearse a fault before the eclipse starts?",
     "Practising on a paused model means the crew already knows the safe order when a real fault happens.",
     "P-11: floods 3 per activation; essentials include the dim guide light.")

card("EX-M0603", "P-12",
     "Enter only checked science in the log (Earth's air bending sunlight, not a map of Bangladesh), and call home only inside a valid contact window.",
     ["nasa_eclipse_2047_01_12"],
     "During a total lunar eclipse, Earth hides the Sun from the Moon. Sunlight bending through Earth's air, at every sunrise and sunset at once, makes a red ring around Earth. On 12 January 2047 the total part lasts 70 minutes.",
     dict(kind="bar", values="nasa_eclipse_2047_01_12 values.total_min", unit="minutes",
          range=["nasa_eclipse_2047_01_12 derived:contacts_ut.U2", "nasa_eclipse_2047_01_12 derived:contacts_ut.U3"],
          labels=["Totality: the Moon fully inside Earth's shadow", "70.0 minutes", "00:49:44 to 01:59:44 UTC"]),
     "none", [],
     "Watching moves no meter: the camera runs on its own branch, F2. If F2 trips, only the camera goes dark while air, heat and the garden keep running. That separation is what makes observing safe.",
     "The red glow is real physics, but no camera can pick out one country on Earth's edge. The diagram is labelled as a concept.",
     "Can the camera see Bangladesh's sunrise in the red ring?",
     "No. The red light comes from Earth's whole edge at once. The diagram is a labelled concept, not a photo of one country.",
     "P-12: camera and view-screen branch F2 only; habitat services unaffected.",
     extra_sources=["NASA Science · Eclipses and the Moon (explains the red light) · https://science.nasa.gov/moon/eclipses/"])

card("EX-M0604", "P-12",
     "Isolate, check and restore only the camera feeder F2, count the recovery honestly, and hand over the watch.",
     ["vsat_relocatable_array"],
     "NASA engineers designed a 10-kilowatt solar array for the Moon's south pole. It stands on a 16-metre mast to catch the low Sun. When sunlight returns, so does power.",
     dict(kind="bar", values="vsat_relocatable_array values.array_power_kW", marks="vsat_relocatable_array derived:game_mean_power", unit="kilowatts",
          labels=["Power from one array (kilowatts)", "Design: 10 kW", "Aurora's daylight average: about 11.1 kW (our estimate)"]),
     "power", ["E"],
     "The eclipse plan ends with 7 units left in the battery. After the shadow passes, sunlight refills it, but recovery is counted shift by shift, not assumed. Only feeder F2 was reset; the protected main power line was never touched.",
     "A NASA design study, not flight hardware. Aurora's 11.1 kW daylight average is the team's estimate, about 56% of two such arrays.",
     "Why reset only F2 and not all the power?",
     "The fault was only on the camera branch. A small, bounded fault needs a bounded fix, and resetting everything would risk air and heat.",
     "P-11/P-12: E7 at recovery; isolate F2, confirm zero, reset, reconnect, test.")

# Chapter 7 ------------------------------------------------------------------------------------
card("EX-M0701", "P-13",
     "Label the 2012 storm as history used in a what-if, switch the forecast to five people, and keep protection until the last exposure check.",
     ["donki_2012_07", "donki_2017_09"],
     "On 23 July 2012 the Sun blasted out a giant cloud of charged gas, called a CME (coronal mass ejection). It flew at about 3,435 km per second, but it missed Earth and the Moon. NASA's STEREO-A spacecraft was in its path and measured it.",
     dict(kind="bar", values="donki_2012_07 derived:cme_speed", marks="donki_2017_09 derived:cme_speed", unit="km per second",
          labels=["Speed of the solar cloud", "July 2012: 3,435 km/s", "September 2017: 2,650 km/s"]),
     "shielding", ["S", "Z"],
     "Chapter 7 asks: what if a storm like this hit Aurora? The forecast must count five people: 1.25 air units and 1.5 crew-days of food every 7.2-hour step. Shelter stays up until the last exposure check, because draining early leaves the crew open to a later wave.",
     "The 2012 storm really happened, but it missed Earth and the Moon. Aurora's 2047 strike and its three waves are a labelled what-if.",
     "Is Chapter 7's storm a real Moon event?",
     "No. It uses real 2012 measurements to build a what-if. The game labels it so nobody mistakes a model for an observation.",
     "P-13: six 7.2 h steps; multipliers [1,1,2,2,1,1]; five occupants A1.25, R1.5.")

card("EX-M0702", "P-13",
     "Sample exposure before draining on the last step, resolve every name before the hatch closes, and check the seed case by its sensors instead of opening it.",
     ["clowdsley_2021_shielding"],
     "NASA engineers modelled how much shielding protects a crew in a big solar storm. Their guide is about 20 grams of material over every square centimetre, like a wall of water 20 cm thick. Thicker shielding still helps, but less each time.",
     dict(kind="line", values="clowdsley_2021_shielding values.aug1972_spe_effective_dose_mSv_no_curtain", unit="mSv",
          unit_plain="mSv (millisieverts): a measure of radiation's effect on the body.",
          axis="Shielding: 5, 7, 10 and 15 grams per square centimetre",
          labels=["Modelled storm dose behind shielding", "5 g/cm2: 185 mSv", "15 g/cm2: 85 mSv"]),
     "shielding", ["W", "S"],
     "Aurora's full water wall is 6 units, standing for 20 g/cm2, so 1 unit is about 3.3 cm of water. Four units of water plus two crate units give the best shelter, S6. The water is not used up: it starts going back after the last exposure check.",
     "A NASA model of a rover shelter in the August 1972 storm. Real dose never drops to zero, and Aurora's exposure score is not mSv.",
     "Why sample exposure before draining on the last step?",
     "Draining first would remove shielding while the storm is still there. Protection ends only after the final exposure check.",
     "P-13: W [4,4,4,4,4,2], K2; S6 = W4 + K2; founder reserve 15 + 15 latched.")

card("EX-M0703", "P-14",
     "Hold water and cargo through the peak, report progress truthfully, and find the one failed link by comparing passing and failing tests.",
     ["stereo_a_het_2012_07"],
     "STEREO-A measured the fastest protons from the July 2012 storm. Protons are tiny, fast pieces of atoms. Split into six steps of 7.2 hours, most of them arrived in steps 2 and 3, and then the count dropped quickly.",
     dict(kind="line", values="stereo_a_het_2012_07 derived:step_fluence_80MeV", unit="share of the peak step",
          labels=["Share of the fastest protons in each 7.2-hour step (peak = 1)", "Peak: step 3", "Game's what-if waves: 1, 1, 2, 2, 1, 1"]),
     "shielding", ["Z"],
     "The game's three waves are a what-if; the real storm had one big peak. Either way the rule is the same: keep water and crates in place until the peak has passed. In Chapter 7, exposure Z must stay at 6 or below.",
     "STEREO-A was in orbit around the Sun, far from the Moon. 'Fastest' means the 80 MeV channel; slower protons peaked in step 3 too.",
     "The local radio works, but Earth is silent. What failed?",
     "If the local network passes and only the Earth path fails, the fault is on the Earth uplink: the external feedthrough.",
     "P-14: Z <= 6; F-EXT; route readings 0.4 and 0.3 below threshold 1.")

card("EX-M0704", "P-15",
     "Keep the base running on stored procedures and local supplies, design a relay path from Aurora to the summit dish, and set the home-night occupancy.",
     ["jpl_horizons_ch8_relay", "esa_moonlight_relay"],
     "From the south pole in early April 2047, Earth sits below the horizon. NASA JPL's calculation puts it 4 to 7 degrees below a flat horizon. Aurora cannot point a dish straight at Earth.",
     dict(kind="line", values="jpl_horizons_ch8_relay values.pole_6hourly[*][2]",
          start="jpl_horizons_ch8_relay values.pole_6hourly[0][0]", end="jpl_horizons_ch8_relay values.pole_6hourly[-1][0]",
          unit="degrees", labels=["Earth's height seen from the south pole, 7 to 11 April 2047", "Below 0 means hidden", "Lowest: about minus 6.8 degrees"]),
     "life", ["A"],
     "A relay is a station that passes a signal along. This one needs both legs: road repeaters from Aurora to the summit, then the summit dish to Earth. Until it works, the base runs on stored procedures and local supplies. The home-night plan charges two people for 33 hours, then five for 3.",
     "A geometric calculation with no hills. Aurora's exact site is not fixed yet, and the road and relay are fiction.",
     "Why can't the summit dish just point at Earth and be done?",
     "Aurora also has to reach the summit. A relay helps only when both legs work: Aurora to summit, and summit to Earth.",
     "P-15: home air 0.5 per 7.2 h for 33 h, then 1.25 per 7.2 h for 3 h.")

# Chapter 8 ------------------------------------------------------------------------------------
card("EX-M0801", "P-15",
     "Provision the whole 51-hour trip with margin, take the surveyed road instead of the steep shortcut, and inspect the dark marker without leaving the road.",
     ["usgs_gazetteer_south_pole"],
     "Mons Malapert is a real mountain near the Moon's south pole. On the official map of Moon place names, its centre is about 122 km from the pole. That is almost three marathons laid end to end.",
     dict(kind="bar", values="usgs_gazetteer_south_pole derived:pole_to_mons_malapert", unit="km",
          labels=["Shortest distance over the Moon, pole to Mons Malapert", "121.9 km", "Aurora's road: 120 km each way (story value)"],
          note="Three marathons = 126.6 km, so 121.9 km is 'almost three'."),
     "rover", ["rover battery"],
     "The rover trip is 24 hours out, 3 hours of repair and 24 hours back: 51 hours, with 72 hours of supplies. Its battery plan is 14 - 5 - 5 = 4, above the 2-unit reserve. The surveyed road stays at 12 degrees or less; the 22-degree shortcut does not.",
     "Distance between feature centres on a smooth sphere. Aurora's site, the summit point and the road are fiction.",
     "Why plan the return before leaving?",
     "Supplies and battery for the trip home must already be on board. A plan that only reaches the summit is not a plan.",
     "P-15: 120 km each way; 24 + 3 + 24 = 51 h <= 72 h; rover E14, allowances 5/5, reserve 2; road <= 12 deg, shortcut 22 deg.")

card("EX-M0802", "P-15",
     "Test both links at each repaired marker, and set the home forecast to two people for 33 hours, then five for the last 3.",
     ["bvad_2022_metabolic"],
     "NASA plans each astronaut's oxygen at about 0.9 kilograms a day, so air needs follow the number of people. In Aurora's units, two people use half an air unit every 7.2-hour shift. Five people use one and a quarter.",
     dict(kind="bar", values="bvad_2022_metabolic derived:air_per_shift_by_crew.2", marks="bvad_2022_metabolic derived:air_per_shift_by_crew.5",
          unit="air units per 7.2-hour shift", labels=["Air used per 7.2-hour shift (game units)", "2 people at home: 0.5", "All 5 at home: 1.25"]),
     "life", ["A"],
     "Mei and Amara hold Aurora alone for 33 hours, using 0.5 air unit per shift. When the rover team returns for the last 3 hours, use rises to 1.25. The whole home night costs 2.8125 air units.",
     "BVAD gives planning averages. Game air units are a teaching scale: one unit is about 1.07 kg of oxygen.",
     "Why not charge two people for the whole night?",
     "Three travellers come home before dawn. From then on five people breathe at the base, so the forecast must change at that moment.",
     "P-15: 0.5 per 7.2 h for 33 h, then 1.25 per 7.2 h for 3 h; total 2.8125.")

card("EX-M0803", "P-16",
     "Isolate and test for zero before swapping the controller, lock the local bearing L2 and the Earth bearing E3, and accept only the exact ALO42 reply.",
     ["jpl_horizons_ch8_relay"],
     "On 9 April 2047, Earth is almost due north of Mons Malapert. But NASA JPL's calculation puts it about 2.3 degrees below a flat horizon there. A spot at least 1.4 km above the Moon's average surface can see over the curve to Earth.",
     dict(kind="line", values="jpl_horizons_ch8_relay values.malapert_15min[*][2]",
          start="jpl_horizons_ch8_relay values.malapert_15min[0][0]", end="jpl_horizons_ch8_relay values.malapert_15min[-1][0]",
          unit="degrees", labels=["Earth's height seen from Mons Malapert", "0 is a flat horizon", "Link window 00:45 to 01:45 UTC: about minus 2.3 degrees"]),
     "none", [],
     "This moves no meter; it decides whether Aurora can talk to Earth at all. The relay works only when the local link (L2) and the Earth link (E3) each pass their own test. The ALO42 message must also come back exactly.",
     "Geometry with no terrain: the summit's real height and the hills to the north still need NASA's LOLA elevation map. Until then the dial is labelled Computed.",
     "Earth's signal is strong. Is the relay working?",
     "Not until the local leg to Aurora is also tested. A network needs every link, and the data must arrive exactly.",
     "P-16: bearings L2 then E3; checksum ALO42.")

card("EX-M0804", "P-16",
     "Credit both teams in the report, raise home consumption only when the travellers actually return, and pass the five sunrise checks before opening the shutter.",
     ["jpl_ipn_42_176_dte"],
     "A NASA JPL study searched near the south pole for the best place to work. Even the best spot sees the Sun 92% of the time, but sees Earth only 51% of the time. Relays fill the gaps.",
     dict(kind="bar", values="jpl_ipn_42_176_dte values.dte_availability_best_site_percent", marks="jpl_ipn_42_176_dte values.solar_availability_best_site_percent",
          unit="% of the time", labels=["Best south-pole site", "Sunlight: 92%", "Direct view of Earth: 51%"]),
     "food", ["C"],
     "With the relay live, Aurora no longer waits for Earth to rise. At first light, five checks still decide success. They are: all five crew safe; 30 founder seeds and 11 vault specimens protected; steady garden pressure; steady temperature; and living cotton.",
     "The study used a 40-metre radar elevation map, not Aurora's site. Aurora's relay is fiction.",
     "Who kept the expedition connected?",
     "Both teams, and the work before them. The road team fixed the relay while the home team kept the base and garden safe.",
     "P-16: five final indicators (crew 5, founder reserve 30, 11 vault specimens, garden pressure and temperature stable, cotton alive).")


# --- build -----------------------------------------------------------------------------------
def resolve_visual(v):
    out = {"kind": v["kind"]}
    refs = []
    def val(ref):
        fid, path = ref.split(" ", 1)
        # dict-key access for derived values that are maps (air_per_shift_by_crew.5, contacts_ut.U2)
        m = re.match(r"(derived:\w+)\.(\w+)$", path)
        if m:
            refs.append(ref)
            return get(f"{fid} {m.group(1)}")[m.group(2)]
        refs.append(ref)
        x = get(ref)
        return list(x.values()) if isinstance(x, dict) else x
    vals = v["values"]
    if isinstance(vals, list):
        vals = [val(r) for r in vals]
        vals = [1.0 if x is True else 0.0 if x is False else x for x in vals]
    elif "[*]" in vals:
        refs.append(vals + (f" every {v.get('every', 1)}" if v.get("every", 1) > 1 else ""))
        vals = series(vals, v.get("every", 1))
    else:
        vals = val(vals)
        vals = vals if isinstance(vals, list) else [vals]
    out["values"] = [round(float(x), 4) for x in vals]
    if "marks" in v:
        mk = v["marks"] if isinstance(v["marks"], list) else [v["marks"]]
        flat = []
        for r in mk:
            x = val(r)
            flat += x if isinstance(x, list) else [x]
        out["marks"] = [round(float(x), 4) for x in flat]
    if "marks_game" in v:
        out["marks"] = v["marks_game"]
        refs.append("game-design/08_PUZZLE_DESIGNS.md P-07 route slopes (game values)")
    if "error" in v:
        out["error"] = val(v["error"])
    if "range" in v:
        out["range"] = [val(r) for r in v["range"]]
    for k in ("start", "end"):
        if k in v:
            out[k] = val(v[k])
    for k in ("unit", "unit_plain", "axis", "labels", "note"):
        if k in v:
            out[k] = v[k]
    out["from"] = refs
    return out


def source_line(fid):
    f = FIX[fid]
    return f"{f['agency']} · {f['title']} · {f['dataset_id']} · {f['url']}"


missions = {}
for c in C:
    missions[c["mid"]] = {
        "title": TITLES[c["mid"]],
        "puzzle": c["puzzle"],
        "decision": c["decision"],
        "source_ids": c["sources"],
        "evidence": FIX[c["sources"][0]]["evidence_label"],
        "plain": c["plain"],
        "visual": resolve_visual(c["visual"]),
        "for_aurora": {"meter": c["meter"], "fields": c["fields"], "text": c["aurora"]},
        "limits": c["limits"],
        "source_lines": [source_line(s) for s in c["sources"]] + c["extra_sources"],
        "debrief": {"question": c["q"], "answer": c["a"]},
        "game_numbers": "game-design/08_PUZZLE_DESIGNS.md " + c["game_numbers"],
    }

doc = {
    "schema_version": 1,
    "board_task": "M1-30",
    "about": "Plain-language NASA data content for every mission EX-M0101..EX-M0804: what the briefing, the Data Card and the debrief show. English only, written for 10-16-year-olds. Visual numbers are copied from the bundled fixtures in game/resources/data/nasa/ by the paths in visual.from; game numbers come from game-design/08_PUZZLE_DESIGNS.md (see game_numbers). Story canon is not quoted or changed here.",
    "screens": {
        "briefing": ["plain", "visual", "for_aurora", "source_lines"],
        "data_card": ["plain", "visual", "for_aurora", "limits", "source_lines", "evidence"],
        "debrief": ["debrief", "for_aurora", "limits"]
    },
    "fields": {
        "plain": "(1) What the real data says, in short sentences; hard words are explained in the same text.",
        "visual": "(2) One simple chart. kind is line, bar or gauge; values are drawn; marks are reference lines; labels (3 or fewer) are the only text on the chart.",
        "for_aurora": "(3) What it means for Aurora. meter is an Outpost Status group id (game/resources/campaign/outpost_status.json), 'rover' for the separate rover battery, or 'none'. fields lists the meter fields this mission changes; an empty list means the choice protects that area without changing a meter now.",
        "source_lines": "(4) Agency · title · dataset ID · URL for each source, primary first. Full citations stay in the fixture files.",
        "limits": "What the data does not show, said plainly.",
        "evidence": "The primary fixture's evidence label (Observed, Published value or Computed)."
    },
    "missions": missions,
}

# --- checks ----------------------------------------------------------------------------------
problems = []
ids = [m["id"] for m in CATALOG["missions"]]
if list(missions) != ids:
    problems.append("mission ids differ from the catalog")

def sentences(t):
    return [s for s in re.split(r"(?<=[.!?])\s+", t.strip()) if s]

def syllables(w):
    w = re.sub(r"[^a-z]", "", w.lower())
    if not w:
        return 0
    n = len(re.findall(r"[aeiouy]+", w))
    if w.endswith("e") and not w.endswith(("le", "ee")) and n > 1:
        n -= 1
    return max(n, 1)

def fk(text):
    ss = sentences(text)
    words = [w for s in ss for w in re.findall(r"[A-Za-z][A-Za-z'-]*|\d[\d,.]*", s)]
    syl = sum(syllables(w) if w[0].isalpha() else 1 for w in words)
    return 0.39 * len(words) / len(ss) + 11.8 * syl / len(words) - 15.59, max(len(re.findall(r"\S+", s)) for s in ss)

report = []
for mid, m in missions.items():
    for s in m["source_ids"]:
        if s not in FIX:
            problems.append(f"{mid}: unknown fixture {s}")
    if len(m["visual"]["labels"]) > 3:
        problems.append(f"{mid}: more than 3 labels")
    if m["for_aurora"]["meter"] not in METERS + ["rover"]:
        problems.append(f"{mid}: bad meter")
    texts = {"plain": m["plain"], "for_aurora": m["for_aurora"]["text"], "debrief": m["debrief"]["question"] + " " + m["debrief"]["answer"], "limits": m["limits"]}
    row = [mid]
    for k, t in texts.items():
        g, longest = fk(t)
        row.append(f"{k} FK{g:4.1f} max{longest:2d}w")
        if longest > 30:
            problems.append(f"{mid} {k}: sentence of {longest} words")
    report.append("  ".join(row))
    blob = json.dumps(m, ensure_ascii=False)
    if re.search(r"[ঀ-৿]", blob):
        problems.append(f"{mid}: Bangla script")

OUT.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n")
print("\n".join(report))
plain_fk = [fk(m["plain"])[0] for m in missions.values()]
print(f"plain FK mean {sum(plain_fk)/len(plain_fk):.1f}, max {max(plain_fk):.1f}")
print("PROBLEMS:", problems or "none")
print("wrote", OUT, OUT.stat().st_size, "bytes")
