# Claude Motion house style: science explainers and hint videos (M1-63)

Short animated films that teach the science behind a clue or decision. They play as **level 2 hints** (MASTER_PLAN.md §5), from the mission data cards (M1-30) and from Journal → Science. How-to clips (using a panel or a control) are a different kind. They are recorded in Godot from the game's own screens (doc 25 §7, M1-59).

Made with **Claude Motion**: the Tweenkit plugin (`tweenkit@claude-motion-skills`, MIT, free; installed in Sadman's Claude Code 5 Nov 2026). We use its render contract: a page where every frame is a pure function of time `t`, captured frame by frame, with stills checked before the full render. The renderer is ours (`production/tools/motion/`), so the house look stays the same for every clip.

## 1. Rules that never bend

- **Every number comes from a bundled NASA fixture** (`game/resources/data/nasa/`), written as a `{token}` in the spec. Any other digit in on-screen text fails `build.py check`, unless the spec lists it under `literals` with a reason (a satellite name, a citation year, a channel name, the data card's storm level). Scene code draws data numbers only from `SPEC.v` or `D`. Axis tick values are the only literals allowed in scene code.
- **Every beat with data or a diagram carries an honest label chip:** `MEASURED` (observed data), `MODEL` (computed: ephemeris, illumination model), or `DIAGRAM` (a picture, not to scale). The chip also names the source.
- **Say where the data stops.** Each clip has one beat that says it plainly (for example, "counted near Earth, not on the Moon; a count of protons, not a dose").
- **End on what it means for the player's next decision, never the answer** (doc 22, MASTER_PLAN §5 level 2).
- Canon: English only (the check rejects Bangla script), no NASA logos (agency names as text credits only), plants never have faces, and the Moon science rules (ART_BIBLE §2).

## 2. For every age: friendly, fun, clear (Sadman, 5 Nov)

A 9-year-old and a judge should both follow every clip, the first time, with the sound off.

- **One idea per beat, one sentence per caption.** Captions have at most 16 words and are read at no more than 20 characters a second; `build.py check` enforces both. Use short, everyday words. Say "tiny, fast bits of the Sun" before "protons", and "how high the Sun gets" instead of "solar elevation".
- **Explain with things people already know:** a spinning top, your thumb held at arm's length, "each step is ten times bigger". Draw the comparison to the same scale as the data, so it stays honest.
- **Something always moves:** a main action, plus a slow secondary one (the corona turning, stars twinkling, the Sun riding the head of the curve). Things arrive with a springy pop (`K.pop`), never just a fade.
- **Fun beats:** a little question that the next beat answers ("Where did it go?"), a counter that fills as protons hit, a satisfying "Now both fit!".
- **Readable for everyone:** captions are 46 px at 1080p on a dark scrim. Labels are 26–34 px, never below 22 px. Colour is never the only cue: every coloured line also has a word label. White or ivory text sits on dark backgrounds.
- **No jump scares or flashes:** crossfades between beats (0.6 s), no strobing and no hard cuts. The hint player shows stills under reduced motion (M1-64).

## 3. Look

| Item | Value |
|---|---|
| Canvas | 1920×1080 masters, 24 fps; game encode 1280×720 (the project's film size, like the cutscenes), 24 fps, Ogg Theora (`.ogv`) |
| Length | 8–45 s (science explainers 20–45 s) |
| Background | space black `#05060A` to `#0B1222`, with a fixed, slowly twinkling star field |
| Palette | `game/resources/ui/ui_design.json` colours plus ART_BIBLE §3: ivory text, accent mustard `#F2C230` (the Sun, hope, key lines), water blue `#2E8BC0`, regolith grey `#7A7672`, caution `#F2A33A` (protons), danger `#E56B6F` (storm line), good `#68C78B` (measured), cyan `#20B8C9` (model) |
| Type | Avenir Next (Sadman's Mac renders every clip); SF Mono for axis ticks. Titles 88 px bold, labels 26–34 px semibold, captions 46 px semibold |
| Layout | Label chip top left (64 px margin); content between y≈140 and y≈820; captions centred at the bottom on a scrim; a thin progress bar on the bottom edge |
| Framing | Every clip opens on the shared `title` beat (eyebrow "SCIENCE EXPLAINER" and the title) and closes on the shared `takeaway` beat ("WHAT IT MEANS FOR YOU" and `ends_on`) |

## 4. Sound

- **No narration** (doc 25 §7.1: "calm narrator-free"). The captions carry every word, so a clip works with the sound off. ElevenLabs is therefore not used for these clips. If a future clip needs a real sound effect, generate it with ElevenLabs and log it in `production/ai_log_parts/`.
- A quiet sound bed is synthesized in code by `build.py`, so it is reproducible and costs no credits. It is a soft D-major pad, with a chime on each new beat and a small "pop" as each caption appears, at about −30 dBFS RMS so it sits under the game's music.

## 5. Spec format (one JSON per clip in `specs/`)

| Field | Meaning |
|---|---|
| `id` | `sci_<topic>`; also the file name of the `.ogv` and the registry id |
| `title`, `purpose`, `level` | title on screen; one line on what it teaches; `concept`, `explainer` or `method` |
| `length_s`, `fps` | 8–45 s; always 24 |
| `scenes` | the clip's scene file in `scenes/`; it adds functions with `Object.assign(SCENES, {...})` |
| `used_by` | missions, puzzles or cards that play it |
| `sources` | the fixture ids the clip uses (all must exist) |
| `values` | named tokens: `{"from": "<fixture>:<path>", "fmt": "<format>"}`. Paths use dots and `[i]`, and a name inside a list of `{name, value}` items (the fixtures' `derived`) picks that item's value. Formats: a Python format such as `{:,.1f}` (a `+` format prints a true minus sign), or `time` (15:35 UTC), `date` (10 September 2017), `day` (1 May), `year`, `words` (70 → seventy) |
| `series` | raw fixture data for scenes, as `D.<name>` (for example the 730 daily Sun heights) |
| `beats` | `{from, to, scene, label, credit, ...text fields}`, back to back from 0 to `length_s`. Every text field is checked like a caption |
| `captions` | `[start, end, text]`, in order, at least 1.8 s each |
| `ends_on` | the takeaway sentence |
| `literals` | `{text, why}` for each non-token number shown on screen |

## 6. Make or change a clip

```bash
cd production/tools/motion && npm install       # once: playwright-core, drives the installed Google Chrome
python3 production/tools/motion/build.py check
python3 production/tools/motion/build.py stills production/explainers/motion/specs/<id>.json   # contact sheet in build/<id>/
python3 production/tools/motion/build.py render production/explainers/motion/specs/<id>.json
```

`render` writes the master (`masters/<id>.mp4`, gitignored, can be rebuilt), the game file (`game/assets/explainers/science/<id>.ogv`, through Godot's Movie Maker behind `production/tools/godot_gated`), and the clip's entry in `game/resources/campaign/content/explainers.json`. Never edit that entry by hand. `game/tools/test_explainers.gd` checks that every registered clip loads and plays for its length.

Quality loop, every clip: check the contact sheet, open two or three stills at full size, fix overlaps and widows, then do a **swap test**: if the frame would still work for a different topic, redraw it from this topic's own things. After the render, look at the in-game captures.

## 7. Prompts that shaped this style

Picked from [awesome-opus-5-5-video-prompts](https://github.com/LeaddeOpenLab/awesome-opus-5-5-video-prompts), Explainers & Education (91 entries, read 5 Nov 2026), for a calm, data-true, all-ages science film:

- **Photon Journey Explainer** (`prompts/2103629247751618782.md`): rendered from code frame by frame, one strong idea per scene, a coherent design system, the real thing simulated rather than drawn, real numbers with honest uncertainty, burned-in captions, and loops that review stills before handing anything over. Its playful touches (a character to follow, little visual gags) are behind our §2.
- **Japan Summer Weather Visualization** (`2103678647777230877`): pull the real data first, then visualise it. Our version is fixtures through tokens, never typed numbers.
- **Minimalist Optogenetics Explainer** (`2107478638501220672`): a minimal, didactic look with structured scenes and captions.
- Not used: the fast-cut, flash and strobe styles (Tweenkit's `kinetic-cut-video` defaults and most of the Motion Graphics category). They suit a launch reel, not a hint a learner pauses on.

The working prompt for new clips (M1-60, M3-68, M3-77), in our own words:

> Make a 20–45 s science explainer for Last Light Academy in the house style (production/explainers/motion/STYLE.md). Topic: <topic>. Teach <one idea>, for a learner of any age, with the sound off. Use only the fixtures <ids> through `{tokens}`; label every beat measured, model or diagram; include one beat that says where the data stops; end on what it means for <decision>, without giving the answer. One idea per beat, one comparison everyone knows, drawn to scale. Write the spec and scene file, render stills, review them critically (overlaps, widows, the swap test), fix them, then render and check the in-game captures.
