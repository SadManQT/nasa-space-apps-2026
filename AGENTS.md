# Last Light Academy — instructions for AI agents (Codex, Antigravity, others)


## Current implementation batch (user reassignment, 10 November 2026)

Read [CURRENT_BATCH.md](production/plan/CURRENT_BATCH.md) first. While `implementation_batch.active` is true in [tasks.json](production/plan/tasks.json), its exact per-member IDs override the older member/folder mappings below and in historical reports. Ramim20, Sadman11, Asif10, Atik4, Tanvir3, Shanto2. Shanto is the sixth named member, not a free QA/reviewer slot.

- Work only on your active IDs. Inspect `board.py list --member <name> --phase implementation` and `mine --by "Name/AI"`; claim one exact ready ID. Do not use general take/next to select extra work or resume excluded old claims.
- The task's paths/integration_paths are task-scoped edit permission, not ownership of every file in a folder. Before editing source, publish exact-file reservations with `board.py lock ID --by "Name/AI" --files path1,path2`. Preserve competing reservations when syncing; only edit after your reservation push succeeds. Save/push work before `unlock`. No silent lock expiry or overwriting another agent's WIP.
- New assigned members implement their listed feature chains themselves. Do not wait solely for a former Sadman/Atik/Ramim folder owner. Real active edits require a saved-work handoff; use another ready listed task meanwhile.
- Video creation, submission, release packaging and manual QA are deferred. Fifteen source-delivered rows are acceptance-only, not new implementation assignments. Automated tests and actual campaign/scripted UI verification remain required now.
- Preserve all canon, science, credit/asset approvals, own-account commits, import/settings protections and test rules below. A fixture-only prototype is not a completed feature.

The older workflow below applies only where it agrees with this active-batch override. Outside the batch, the historical folder defaults apply again.

**`continue(<name>)`:** when a teammate types `continue(sadman)`, `continue(ramim)`, `continue(atik)` or `continue(<their name>)`, follow [production/plan/GO_NEXT.md](production/plan/GO_NEXT.md) §0: work only that member's board tasks (`board.py take --by "<Name>/<AI>"`) and edit only the folders they own ([production/plan/MASTER_PLAN.md](production/plan/MASTER_PLAN.md) §7, their card in [production/plan/team/](production/plan/team/)). A change in someone else's folder becomes a board task for them (`board.py add`), never an edit.

**Teammates use Codex (GPT).** Every task on the board is assigned to one member; Ramim, Atik and the QA and science reviewers' tasks are all in the `codex` lane, so Codex can do every one of them. Before your first task: `git config user.name "<your GitHub username>"` and `git config user.email "<the email verified on your GitHub account>"`, or GitHub will not credit your commits to you. Tasks needing Claude, video or paid generation tools are Sadman's; if one of your tasks needs one, `board.py add --for sadman` and carry on. The game is released on 12 Nov (M3-93): finish the game first.

**"Continue" / "go next":** when a teammate says "continue" (take a chunk of up to 5 tasks and keep going) or "go next" (one task), follow [production/plan/GO_NEXT.md](production/plan/GO_NEXT.md) with the team board (`python3 production/plan/board.py next --tool <your tool>`; readable view: `production/plan/BOARD.html`). The board is the ordered list of all remaining work; [HANDOFF.md](HANDOFF.md) is history.

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
<!-- end claude-reflect -->
