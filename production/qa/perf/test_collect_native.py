"""Process-level checks for the collector, using disposable fake engines."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

COLLECTOR = Path(__file__).with_name("collect_native.py")


class NativeCollectorTests(unittest.TestCase):
    def invoke(self, folder, mode, timeout=3):
        engine = folder / "fake-godot"
        engine.write_text(f"#!{sys.executable}\n" + '''
import json, os, time
from pathlib import Path
p = Path(os.environ["TEST_LOG_DIR"])
mode = os.environ["LLA_COLLECTOR_TEST_MODE"]
if mode != "missing_artifacts":
    (p / "input_trace.json").write_text(json.dumps({"stub": True}))
    for i in range(5):
        (p / (str(i) + ".png")).write_bytes(b"stub artifact; no rendered image claimed")
if mode != "missing_result":
    print("CAMPAIGN INTERACTION INPUT RESULT: PASS (44 checks, 0 failures)", flush=True)
if mode == "hang_after_result":
    time.sleep(20)
else:
    time.sleep(0.15)
raise SystemExit(7 if mode == "nonzero_exit" else 0)
''')
        engine.chmod(0o755)
        output = folder / "evidence"
        result = subprocess.run([sys.executable, str(COLLECTOR), "--godot", str(engine),
                                 "--output", str(output), "--case", "input", "--timeout", str(timeout)],
                                env={**os.environ, "LLA_COLLECTOR_TEST_MODE": mode},
                                capture_output=True, text=True, timeout=15)
        return result, json.loads((output / "run.json").read_text()), output, engine

    def test_success_requires_result_artifacts_and_normal_exit(self):
        with tempfile.TemporaryDirectory() as directory:
            result, run, _, _ = self.invoke(Path(directory), "success")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(run["capture_checks_passed"])
            self.assertEqual(run["exit_code"], 0)
            self.assertTrue(run["source_unchanged"])
            self.assertEqual(len([p for p in run["artifacts"] if p.endswith(".png")]), 5)

    def test_pass_followed_by_hung_process_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            result, run, _, _ = self.invoke(Path(directory), "hang_after_result", timeout=0.5)
            self.assertEqual(result.returncode, 1)
            self.assertFalse(run["capture_checks_passed"])
            self.assertTrue(run["timed_out"])
            self.assertEqual(run["exit_code"], 124)
            self.assertTrue(run["markers"])
            self.assertIsNotNone(run["result_first_observed_seconds"])

    def test_incomplete_or_nonzero_attempts_are_retained_and_rejected(self):
        for mode in ["missing_artifacts", "missing_result", "nonzero_exit"]:
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                result, run, output, _ = self.invoke(Path(directory), mode)
                self.assertEqual(result.returncode, 1)
                self.assertFalse(run["capture_checks_passed"])
                self.assertFalse(run["timed_out"])
                self.assertTrue((output / "stdout.log").is_file())
                self.assertEqual(run["exit_code"], 7 if mode == "nonzero_exit" else 0)

    def test_existing_evidence_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            _, _, output, engine = self.invoke(Path(directory), "success")
            original = (output / "run.json").read_bytes()
            result = subprocess.run([sys.executable, str(COLLECTOR), "--godot", str(engine),
                                     "--output", str(output), "--case", "input"],
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 2)
            self.assertEqual((output / "run.json").read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
