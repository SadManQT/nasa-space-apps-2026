# M3-69: the junior-astronaut curriculum (landed 11 Nov 2026)

Model, data and manual panel are Asif's saved work (`asif/curriculum-20261110`, 8cf5ea81, authorship kept); Sadman wired them into the game.

- `curriculum.json`: twelve competencies, each with learned, practised and proved moments mapped to missions, plus a three-things-and-one-decision page per chapter.
- Moments are derived from the scenes this save has completed, so they cannot drift from the save and replays give the same results.
- **Journal Manual tab** opens the Academy Manual (index of the twelve competencies, one page each with explainer clips, the real data card and the cadet's own recorded decisions). The pause menu lists "Academy Manual" too.
- **Chapter end:** the "What you learned" page opens first, and closing it opens that chapter's upgrade choice.
- **Cadet record:** a "Learning" tab shows learned, practised and proved counts for each competency.
- No quizzes or exams.

## Proof
`test_curriculum.gd` 183/0 (every competency has a teach, practise and prove moment; pack validates against missions, sources and clips); `test_academy_manual_wiring.gd` 15/0 in the production campaign (Journal tab and button, pause menu entry, chapter page then upgrade choice, refused page for an incomplete chapter, Learning tab lists twelve rows); `test_journal_tabs.gd` 322/0 (updated for seven tabs). Screenshots (inspected): `M3-69_manual_index.png`, `M3-69_what_you_learned_ch01.png`, `M3-69_cadet_record_learning.png`. Full gate: see M3-3P_M3-69_M1-105_gate.md.

## Known limits
Chapter 8's page opens from the campaign-complete result; the explainer buttons reuse the existing hint player. Chapter 1's page shows "No choice from this chapter is recorded" in the fixture because the fixture has no recorded decision.
