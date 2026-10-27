# Last Light Academy — instructions for AI agents (Codex, Antigravity, others)

Work in progress and the ordered next steps are in [HANDOFF.md](HANDOFF.md): if you are taking over from another agent, read it right after the handbook and continue from there.

Before any work on assets, cutscenes, story or gameplay, read [PRODUCTION_HANDBOOK.md](PRODUCTION_HANDBOOK.md). It holds the canon order, locked decisions, pipeline, tools and credit rules, the full asset and cutscene lists, and current status. Update it in the same change whenever a decision or status changes.

Never break these (details in the handbook):
- Story canon is `full-game-story/STORY_FULL.md` (96 scenes, `EX-CHxx-Sxx`); game numbers come from `game-design/08_PUZZLE_DESIGNS.md`.
- No NASA logos. No Bangla script in the game. Plants never have eyes or faces. Moon science rules in `production/ART_BIBLE.md` §2.
- Log every AI generation in `production/AI_PROMPT_LOG.md`.
- Tripo CLI: switch accounts only with `tripo config use`; never set `TRIPO_API_KEY` (the API pool uses `TRIPO_OPENAPI_KEY`); always `--visibility private`; rigs must be re-exported with `--with-animation`.
- Get the user's approval on 2D sheets before spending Tripo credits on new characters or hero props.
- Commit only when asked, as `sadmanqt`, with no AI co-author lines.

<!-- claude-reflect: learned rules (saved from the band; edit freely) -->
## Learned rules
- Always verify each generated asset is correct, and remove unnecessary files so the folders and GitHub repo stay clean.
<!-- end claude-reflect -->
