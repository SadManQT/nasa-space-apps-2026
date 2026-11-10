"""Verify post-audit collection without launching Godot or altering retained run evidence."""
from pathlib import Path
import hashlib
import json
import os
import runpy
import sys

root = Path(__file__).resolve().parent
api = runpy.run_path(str(root / "cold_import_repro.py"))
actual = api["diagnostics"](root / "sidecar_restore/restored_sidecars_runner_logs/setup.log")
assert len(actual["engine_errors"]) == 440
assert not actual["script_errors"] and not actual["native_crash_signature"]
assert not api["diagnostics"](root / "sidecar_restore/warm_control_runner_logs/setup.log")["engine_errors"]
out = root / "collector_selfcheck"
out.mkdir(exist_ok=False)
code = "import os,pathlib; pathlib.Path(os.environ['TEST_LOG_DIR'],'setup.log').write_text('ERROR: nested import fault\\n'); print('1/1 suites passed')"
result = api["invoke"](out, "nested_error_runner", [sys.executable, "-c", code], root, os.environ.copy(), 10)
assert result["effective_exit_code"] == 0
assert result["suite_summary"] == ["1/1 suites passed"]
assert result["generic_error_count"] == 1
assert not result["native_crash_signature"]
assert len(result["audited_logs"]) == 1
for name, expected in [("cold_import_repro.py", "f93c58926a6698b77ecff7f655368120d9ce66b04e046f43ad560e9dc0a102b1"), ("sidecar_restore_repro.py", "25f48a9a8dc00907353020683096fbe3fbada1d31949b0b39d0056b6c41b7299")]:
    assert hashlib.sha256((root / "executed_scripts" / name).read_bytes()).hexdigest() == expected
api["dump"](root / "post_audit_selfcheck.json", {"stub_process_only": True, "retained_setup_error_count": 440, "clean_control_setup": True, "nested_error_detected_despite_exit_zero_and_passing_summary": True, "ordinary_engine_error_not_native_crash": True, "executed_script_snapshots_match_recorded_run_hashes": True, "collector_sha256": api["sha"](root / "cold_import_repro.py")})
print("POST-AUDIT COLLECTOR RESULT: PASS")
