"""Exercise the actual shell runner against an isolated, injected engine."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class RunnerTests(unittest.TestCase):
    def run_case(self, mode):
        with tempfile.TemporaryDirectory(prefix="lla-runner-") as directory:
            root = Path(directory)
            tools = root / "game" / "tools"
            tools.mkdir(parents=True)
            shutil.copy2(Path(__file__).with_name("run_tests.sh"), tools)
            (tools / "test_probe.gd").write_text("# Engine stub owns this fixture.\n")
            engine = root / "godot-stub"
            engine.write_text('''#!/usr/bin/env bash
case " $* " in
  *" --editor "*)
    case "$RUNNER_CASE" in
      setup_error) echo 'import diagnostic: fixture failure'; exit 42 ;;
      setup_crash) echo 'import diagnostic: crash fixture'; exit 139 ;;
      setup_parse) echo 'SCRIPT ERROR: Parse Error: setup fixture'; exit 0 ;;
    esac
    exit 0 ;;
esac
echo invoked >> "$RUNNER_CALLS"
case "$RUNNER_CASE" in
  suite_parse) echo 'SCRIPT ERROR: Parse Error: suite fixture' ;;
  suite_error) echo 'PROBE RESULT: PASS'; exit 7 ;;
  timeout) exec sleep 30 ;;
esac
echo 'PROBE RESULT: PASS'
''')
            engine.chmod(0o755)
            calls = root / "calls"
            result = subprocess.run(
                ["bash", str(tools / "run_tests.sh")],
                env={**os.environ, "GODOT": str(engine), "RUNNER_CASE": mode,
                     "RUNNER_CALLS": str(calls), "SUITE_TIMEOUT": "1"},
                capture_output=True, text=True, timeout=10,
            )
            return result, calls.exists()

    def test_failed_setup_stops_before_any_suite(self):
        for mode, code in [("setup_error", 42), ("setup_crash", 139), ("setup_parse", 1)]:
            with self.subTest(mode=mode):
                result, invoked = self.run_case(mode)
                self.assertEqual(result.returncode, code, result.stdout + result.stderr)
                self.assertFalse(invoked)
                self.assertIn("FAIL setup:", result.stdout)
                self.assertIn("fixture", result.stdout)
                self.assertNotIn("suites passed", result.stdout)

    def test_successful_setup_runs_suite(self):
        result, invoked = self.run_case("success")
        self.assertTrue(invoked)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("1/1 suites passed", result.stdout)

    def test_existing_failure_checks_remain_effective(self):
        for mode in ["suite_parse", "suite_error", "timeout"]:
            with self.subTest(mode=mode):
                result, invoked = self.run_case(mode)
                self.assertTrue(invoked)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("0/1 suites passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
