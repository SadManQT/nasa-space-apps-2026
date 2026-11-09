"""Collector retention checks with an injected runner; no engine/cache changes."""
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import subprocess

spec = importlib.util.spec_from_file_location("collector", Path(__file__).with_name("collect_loading.py"))
collector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collector)


class CollectionTests(unittest.TestCase):
    def run_case(self, retain, present=True, runner_code=0):
        with tempfile.TemporaryDirectory(prefix="lla-loading-collector-") as directory:
            root = Path(directory)
            engine, bash = root / "godot", root / "bash"
            engine.touch()
            bash.touch()
            destination = root / "evidence"
            trace_bytes = b'{"windows": [{"label": "production title"}], "steps": [{"step": "example", "ms": 1.25}]}\n'
            seen_env = []

            def runner(command, **kwargs):
                env = kwargs["env"]
                seen_env.append(env)
                logs = Path(env["TEST_LOG_DIR"])
                (logs / "setup.log").write_text("fixture setup\n")
                (logs / "test_performance_runtime.gd.log").write_text("fixture full suite\n")
                if present:
                    (logs / "loading_trace.json").write_bytes(trace_bytes)
                kwargs["stdout"].write("1/1 suites passed\n" if runner_code == 0 else "0/1 suites passed\n")
                return subprocess.CompletedProcess(command, runner_code)

            argv = ["collect_loading.py", "--godot", str(engine), "--bash", str(bash), "--output", str(destination), "--runs", "2"]
            with patch.object(sys, "argv", argv), patch.dict(os.environ, {"LLA_RETAIN_LOAD_TRACE": "1" if retain else "0"}), patch.object(collector, "output", return_value={"stdout": "fixture source"}), patch.object(collector.subprocess, "run", side_effect=runner), contextlib.redirect_stdout(io.StringIO()):
                code = collector.main()
            manifest = json.loads((destination / "manifest.json").read_text())
            self.assertEqual(len(manifest["runs"]), 2)
            self.assertTrue(all(env["LLA_RETAIN_LOAD_TRACE"] == ("1" if retain else "0") for env in seen_env))
            for index, run in enumerate(manifest["runs"], 1):
                self.assertEqual(run["exit_code"], runner_code)
                self.assertTrue((destination / f"run-{index}" / "setup.log").is_file())
                if retain:
                    self.assertIn("stage_trace", run)
                if retain and present:
                    trace = run["stage_trace"]
                    self.assertEqual(trace["path"], f"run-{index}/loading_trace.json")
                    self.assertEqual(trace["sha256"], hashlib.sha256(trace_bytes).hexdigest())
                    self.assertEqual(trace["bytes"], len(trace_bytes))
                elif retain:
                    self.assertIn("missing", run["stage_trace"]["error"])
                else:
                    self.assertNotIn("stage_trace", run)
            return code

    def test_opt_in_retains_complete_artifact_even_on_suite_failure(self):
        for code in [0, 1]:
            with self.subTest(runner_code=code):
                self.assertEqual(self.run_case(True, runner_code=code), code)

    def test_missing_opt_in_trace_cannot_report_collection_success(self):
        self.assertEqual(self.run_case(True, present=False), 1)

    def test_default_does_not_require_stage_output(self):
        self.assertEqual(self.run_case(False, present=False), 0)


if __name__ == "__main__":
    unittest.main()
