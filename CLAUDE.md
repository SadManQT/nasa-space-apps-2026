# Last Light Academy — instructions for AI agents

**`continue(<name>)`:** when a teammate types `continue(sadman)`, `continue(ramim)`, `continue(atik)` or `continue(<their name>)`, follow [production/plan/GO_NEXT.md](production/plan/GO_NEXT.md) §0: that member's board tasks only, edits only inside the folders they own ([production/plan/MASTER_PLAN.md](production/plan/MASTER_PLAN.md) §7; card in [production/plan/team/](production/plan/team/)); a change in someone else's folder becomes a board task for them (`board.py add`). A bare "continue" on Sadman's machine means `continue(sadman)`.

**"Continue" / "go next":** when a teammate says "continue" (take a chunk of up to 5 tasks and keep going) or "go next" (one task), follow [production/plan/GO_NEXT.md](production/plan/GO_NEXT.md) with the team board (`python3 production/plan/board.py next --tool claude`; readable view: `production/plan/BOARD.html`). That protocol overrides the template's per-file "May I write" prompts for the claimed task's own paths; approvals the task itself requires still apply.

Before any work on assets, cutscenes, story or gameplay, read [PRODUCTION_HANDBOOK.md](PRODUCTION_HANDBOOK.md). It holds the canon order, locked decisions, pipeline, tools and credit rules, the full asset and cutscene lists, and current status. Update it in the same change whenever a decision or status changes.

Never break these (details in the handbook):
- Story canon is `full-game-story/STORY_FULL.md` (96 scenes, `EX-CHxx-Sxx`); game numbers come from `game-design/08_PUZZLE_DESIGNS.md`.
- No NASA logos. No Bangla script in the game. Plants never have eyes or faces. Moon science rules in `production/ART_BIBLE.md` §2.
- Log every AI generation in `production/AI_PROMPT_LOG.md`.
- Tripo CLI: switch accounts only with `tripo config use`; never set `TRIPO_API_KEY` (the API pool uses `TRIPO_OPENAPI_KEY`); always `--visibility private`; rigs must be re-exported with `--with-animation`.
- Get the user's approval on 2D sheets before spending Tripo credits on new characters or hero props.
- Commit only when asked; "go next" asks for its one task's claim, commit and push. Commit under the teammate's own GitHub account (`sadmanqt` on Sadman's machine), with no AI co-author lines.
- Run tests with `game/tools/run_tests.sh`, never by a bare Godot exit code (Godot exits 0 when a test script fails to parse).

<!-- claude-reflect: learned rules (saved from the band; edit freely) -->
## Learned rules
- Always verify each generated asset is correct, and remove unnecessary files so the folders and GitHub repo stay clean.
- Never recommend or assume purchases that spend the user's money; present paid options only as choices the user explicitly approves.
- Make all game missions and puzzles scientifically accurate, following NASA project requirements, real NASA mission types, and realistic engineering trade-offs.
- Use Claude Opus 5.5 with extra-high reasoning effort for all tasks.
<!-- end claude-reflect -->

