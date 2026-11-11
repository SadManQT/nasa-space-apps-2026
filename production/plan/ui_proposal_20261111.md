# Approved proposal UI implementation plan (M4-22)

**Goal:** Implement the approved 15 images in `ui_proposal/` as usable Godot screens, preserving every existing feature.
**Spec:** The user's 11 November request and the 15 proposal images (1672x941).
**Architecture:** Keep runtime commands/query/save boundaries. Author major screen shells in scenes; dynamic content remains data-driven. Reuse UiDesign/UiKit and existing Gohud. No gameplay, science, roster or save arithmetic changes.
**Look:** Proposal 01 is the title composition; 02/03 are atmosphere alternatives, not extra menu modes. Soft deep navy, ivory, restrained warm gold, fine cool edges, 8px surfaces, 44px interaction targets. Cinzel display title, Barlow semiconducted headings, Roboto body. Respect 150% text, keyboard/controller focus, reduced motion and persistent settings.

- [ ] Shared theme and cinematic title: replace rejected split industrial layout with full-room backdrop and vertical navigation; all trainer/chapter/science/settings/credits entries and save state remain reachable. Remove mockup lettering from the art plate, use live controls. New, Continue, modal Back/Escape, focus restoration, no-save state checked.
- [ ] Settings and chapter selection: serialize shells, left settings navigation with scrollable content; preserve immediate-save semantics instead of a misleading Apply button; all Display/Audio/Controls/Assist/Saves options, rebinding and chapters stay connected. Proposal04/13.
- [ ] Mission Table, calibration and greenhouse: scene-authored header/body/footer shells; retain existing preview/confirm steps, calibration values, care commands, audit state. Proposal06/07/09.
- [ ] Campaign HUD and shared overlays: quieter goal card, real content/sidebar/action hierarchy for Journal/Science, pause, debrief, comms and supporting screens, and consistent trainer styling. Proposal05/08/10/11/12/14/15. Never make fake clickable mockup controls.
- [ ] Validation and delivery: targeted existing UI suites plus proposal regression, scripted native screenshots at 1280x720 and 150% text; check parsing/import/runtime logs, real command behavior, focus/scroll/modal exits; independent review; update handbook/evidence; fetch/merge safely and push exact scoped files, then release locks. Re-run broader tests only for new coverage concerns.

**Review focus:** no-save Continue; large-text clipping; keyboard focus behind modals; unchanged settings save/apply behavior; stale preview and actual campaign command contracts. Existing shared-PC implementation gaps remain with Asif; do not rewrite them as cosmetic work.
**Engine:** local Godot4.7, target4.7.2. Godot MCP unavailable (no registered tool/server); CLI and native captures used. Existing user import/settings changes stay untouched in the original checkout.
