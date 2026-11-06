#!/usr/bin/env bash
# M4-02 evidence, reproducible: the CS-18 lamp tick in the film the game plays.
# 1. M3-97_capture.sh: re-encodes only runtime films whose picture or sound drifted from the master
#    (verify_staging.py --stale), checks runtime parity including sound and the tick's frame, and captures
#    the real CampaignCutscenePlayer with its window on top (M3-97_*_ingame_*.png).
# 2. M4-02_sync_sheet.py: frames 89-96 of the runtime film over its waveform -> M4-02_CS18_tick_sync.png.
# No credits or network. Run outside the sandbox (Godot needs a window); heavy steps take heavy.py themselves.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$ROOT"
OUT="$ROOT/production/qa/evidence"
exec > >(tee "$OUT/M4-02_capture_output.txt") 2>&1

bash production/qa/evidence/M3-97_capture.sh
python3 production/tools/heavy.py python3 production/qa/evidence/M4-02_sync_sheet.py
echo 'M4-02 CAPTURE: PASS'
