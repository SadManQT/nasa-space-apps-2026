"""Exercise the actual shell runner against an isolated, injected engine."""
import os
from pathlib import Path
import shutil
import subprocess
import signal
import tempfile
import time
import unittest


class RunnerTests(unittest.TestCase):
    def run_case(self, mode, suite_name="test_probe.gd", suite_timeout="1", text_timeout=None):
        with tempfile.TemporaryDirectory(prefix="lla-runner-") as directory:
            root = Path(directory)
            tools = root / "game" / "tools"
            tools.mkdir(parents=True)
            shutil.copy2(Path(__file__).with_name("run_tests.sh"), tools)
            (tools / suite_name).write_text("# Engine stub owns this fixture.\n")
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
  suite_runtime_hang) echo 'SCRIPT ERROR: Invalid call: fixture'; exec sleep 30 ;;
  suite_pass_runtime_hang)
    echo 'PROBE RESULT: PASS'; echo 'SCRIPT ERROR: Invalid call: fixture'; exec sleep 30 ;;
  suite_ignores_term)
    trap '' TERM; echo 'SCRIPT ERROR: Invalid call: fixture'; exec sleep 30 ;;
  suite_slow) sleep 2 ;;
  suite_many_failures)
    for index in $(seq 8); do echo "FAIL detail $index"; done
    echo 'PROBE RESULT: FAIL'; exit 1 ;;
esac
echo 'PROBE RESULT: PASS'
''')
            engine.chmod(0o755)
            calls = root / "calls"
            command = ["bash", str(tools / "run_tests.sh")]
            env = {**os.environ, "GODOT": str(engine), "RUNNER_CASE": mode,
                   "RUNNER_CALLS": str(calls), "SUITE_TIMEOUT": suite_timeout,
                   "TEST_LOG_DIR": str(root / "logs")}
            env.pop("PLAYER_TEXT_TIMEOUT", None)
            if text_timeout is not None:
                env["PLAYER_TEXT_TIMEOUT"] = text_timeout
            process = subprocess.Popen(command, env=env, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, text=True,
                                       start_new_session=os.name != "nt")
            try:
                stdout, stderr = process.communicate(timeout=12)
                result = subprocess.CompletedProcess(command, process.returncode, stdout, stderr)
            finally:
                # A failing runner must not leave this test's injected engine alive.
                if os.name != "nt":
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                elif process.poll() is None:
                    process.kill()
                process.wait()
                process.stdout.close()
                process.stderr.close()
            self.assertTrue((root / "logs" / "setup.log").is_file())
            if mode.startswith("setup_"):
                self.assertFalse((root / "logs" / (suite_name + ".log")).exists())
            else:
                self.assertTrue((root / "logs" / (suite_name + ".log")).is_file())
                result.suite_log = (root / "logs" / (suite_name + ".log")).read_text()
            if mode == "suite_many_failures":
                self.assertIn("FAIL detail 8", (root / "logs" / "test_probe.gd.log").read_text())
                self.assertNotIn("FAIL detail 8", result.stdout)
            return result, calls.exists()

    def test_fatal_script_error_stops_live_engine_before_its_timeout(self):
        for mode in ["suite_runtime_hang", "suite_pass_runtime_hang"]:
            with self.subTest(mode=mode):
                started = time.monotonic()
                result, _ = self.run_case(mode, suite_timeout="20")
                self.assertLess(time.monotonic() - started, 10)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("0/1 suites passed", result.stdout)
                self.assertIn("SCRIPT ERROR", result.stdout)
                self.assertNotIn("TIMEOUT after 20s", result.suite_log)

    @unittest.skipIf(os.name == "nt", "POSIX ignored-signal fixture; Windows host still needs real verification")
    def test_fatal_error_reaps_engine_that_ignores_term(self):
        result, _ = self.run_case("suite_ignores_term", suite_timeout="20")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("0/1 suites passed", result.stdout)
        self.assertIn("process exit 137", result.suite_log)

    def test_long_text_guard_does_not_raise_other_suite_limits(self):
        result, _ = self.run_case("suite_slow", suite_name="test_player_text.gd", text_timeout="5")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("1/1 suites passed", result.stdout)
        result, _ = self.run_case("suite_slow", text_timeout="5")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("TIMEOUT after 1s", result.suite_log)

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
        for mode in ["suite_parse", "suite_error", "timeout", "suite_many_failures"]:
            with self.subTest(mode=mode):
                result, invoked = self.run_case(mode)
                self.assertTrue(invoked)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("0/1 suites passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
