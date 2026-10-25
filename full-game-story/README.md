# Last Light Academy — complete main-campaign story

Open **index.html** in a browser. It is one self-contained offline file: no server, login, external font, JavaScript dependency or image download is required.

এই সংস্করণে পুরো মূল গল্পের লক্ষ্য **১০–১৪ ঘণ্টা**, মাঝামাঝি বাজেট **১২ ঘণ্টা**। আট chapter-এর সব ৩২টি mission ও ৯৬টি scene মূল campaign-এর অংশ। Side mission, collection grind, বাধ্যতামূলক failure বা পুরো campaign replay দিয়ে সময় বাড়ানো হয়নি।

The body is written in English for a studio production team, with Bengali reading guidance and chapter summaries. The **Read** mode presents finished narrative, character dialogue, player actions and examined responses. **Studio** adds lesson evidence, source lineage and exit conditions. The atlas also includes chronology, crew arcs, learning progression, continuity ledgers, search, local reading marks, manuscript printing, Markdown export and structured-data export.

## Files

- `index.html`: complete standalone deliverable. Copy/share this one file to retain the full experience.
- `STORY_FULL.md`: full readable manuscript, including dialogue, actions, learning and scene gates.
- `story-data.json`: assembled structured content for narrative and engineering pipelines.
- `content/chapters-1-4.json` and `content/chapters-5-8.json`: separate narrative-author outputs, synchronised into the final edition.
- `content/learning-and-continuity.json`: primary-source learning package, pacing and shared canon locks.
- `content/learning-audit.md`: separate review of narrative, learning and cross-chapter continuity.
- `AUDIT_REPORT.md`: final verification status and limits.
- `build_story.py`, `template.html`, `styles.css`, `artwork.svg`, `app.js`: editable, dependency-free source.

The older repository documents remain intact. This standalone edition changes their earlier four-hour main-route scope to the requested 10–14-hour route. It preserves the established eight-chapter plot, reveal order, plant lineage, character presence, historical-replay framing and travel arithmetic. New connective scenes and dialogue are authored expansion material, not a representation that every line already existed in the original canon.

## Rebuild

With Python and Node installed, run from the repository root:

```powershell
python full-game-story/build_story.py
```

The builder validates the content and references, checks JavaScript syntax, and regenerates the HTML, manuscript, structured data and structural audit results. It uses only the Python standard library and Node's syntax checker.

`verify_dom.cjs` additionally exercises the rendered DOM and interaction logic using an installed `linkedom` package. This QA dependency is not used by the deliverable:

```powershell
node full-game-story/verify_dom.cjs C:/path/to/node_modules/linkedom
```

## Production boundary

This package is the full narrative and mission blueprint, not the engine build. Target playtimes require learner playtesting; the original survival contracts require integration and balance checks; exact Aurora sky geometry and physical route claims require verified processing. Reading marks are local document progress, not a gameplay save.

No Git push, source publication or hosted deployment is part of this task.
