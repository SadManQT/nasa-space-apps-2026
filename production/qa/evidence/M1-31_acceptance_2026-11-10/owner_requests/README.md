# Owner handoff candidates

Frozen source: daa0141 (game bytes unchanged through c112f88).

## Asif / current M1-105 reservation
Actual full runner test_chapter1_campaign_flow fails `production player uses lunar gravity`.
The current campaign binds Moon gravity only outdoors and uses9.8 indoors. Pressurised habitat rooms remain on the Moon; pressure should alter suit drain, not gravitational acceleration.
Proposed one-line correction: Asif_MoonGravity.patch. Not applied because chapter1_campaign.gd has Asif/M1-105's active exact-file reservation. Apply through that working session or publish saved work and release the file before Ramim applies it. Preserve all input bridge work.

## Sadman / room data and world ownership
Current mandatory room suites report unsupported staged holder bases (Ch2), unreadable staged labels (Ch3/5/6), and a Chapter1 garden mutation check (Ch3). Complete logs are retained under ../full-gate/. These are observed automated failures, not an established rendering root cause. Preserve canon props/names; do not delete authored labels or relax checks without reproducing and verifying actual placement/metadata.
