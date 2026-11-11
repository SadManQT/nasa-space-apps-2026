# M4-20 industrial UI integration

User delegated the DOOM-inspired visual direction and safe shared integration. The primary title composition is now authored in main_menu.tscn, with bundled Roboto body text, Barlow headings, graphite surfaces and mustard actions. UiDesign/UiKit and the saved Theme keep existing API contracts. Gohud sci-fi HeroPanel is serialized in the saved Theme so it is visible in the editor. Checked rows keep dark backing for existing ivory label overrides. Role colours and gameplay/save arithmetic remain unchanged; Rafi briefing label is Space weather.

Existing MainMenu signals, developer-only showcase, modal focus and accessibility state remain. Escape now dismisses Briefing and Science. The title artwork is an extraction at 0.6 s from the existing approved production/cutscenes/v7/src/shots/CS-01-A.mp4, not a new AI generation. Fonts are already bundled; no new paid assets.

Verification before integration: ui_polish19/0, main_menu_contrast170/0, first_five_minutes59/0. UI families84/0, UI kit522/0 and Chapter 1 UI regressions42/0 passed on the earlier pass; repeat the affected group on final integrated source. The polish assertions went RED before the typography/authored-layout, checked-row contrast and Escape fixes.

Native captures menu.png, menu_large.png and settings.png use Godot4.7 on original Windows/NVIDIA RTX4060, Compatibility renderer at1280x720. These are production MainMenu/CampaignPanels scenes (not a mockup); large text is150%. Capture logs are local ~/.codex/tmp/ui-merge-capture.log. Compatibility emits its expected TAA-not-supported warning; no script/parse errors. No new complete campaign or cross-platform certification is claimed.

Independent review caught the missing developer entry and weak lower-navigation assertion; both were corrected. One shared GoUi preset is applied when UiKit initializes, intentionally establishing this project's sci-fi visual baseline.

Final integration acceptance: user accepted the combined Ramim1-35/Sadman36-onward gate and explicitly stopped duplicate runs. Current integrated Chapter1 UI42/0 and first35 suite names/results are preserved in ../M4-21/verification.txt. Later user instruction stopped further UI iteration; the saved implementation was merged as-is. Integrated native menu/150%/settings captures were refreshed before that stop instruction.
