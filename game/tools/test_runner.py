"""Exercise the actual shell runner against an isolated, injected engine."""
import os
from pathlib import Path
import shutil
import subprocess
import signal
import sys
import tempfile
import time
import unittest
from unittest.mock import patch


def bash_executable():
    if os.environ.get("RUNNER_BASH"):
        return Path(os.environ["RUNNER_BASH"]).as_posix()
    if os.name == "nt":
        git = shutil.which("git")
        if git:
            installation = Path(git).resolve()
            for bash in [installation.with_name("bash.exe"), installation.parent.parent / "bin" / "bash.exe"]:
                if bash.is_file():
                    return bash.as_posix()
        raise RuntimeError("Set RUNNER_BASH to Git Bash's bash.exe; Windows WSL Bash cannot run this fixture.")
    return shutil.which("bash") or "bash"


def process_alive(pid):
    if os.name == "nt":
        import ctypes
        from ctypes import wintypes
        kernel = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel.OpenProcess.restype = wintypes.HANDLE
        handle = kernel.OpenProcess(0x1000, False, pid)
        if not handle:
            return False
        try:
            code = wintypes.DWORD()
            return bool(kernel.GetExitCodeProcess(wintypes.HANDLE(handle), ctypes.byref(code))) and code.value == 259
        finally:
            kernel.CloseHandle(wintypes.HANDLE(handle))
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False


class RunnerTests(unittest.TestCase):
    def run_case(self, mode, suite_name="test_probe.gd", suite_timeout="1", text_timeout=None, profile_timeout=None):
        with tempfile.TemporaryDirectory(prefix="lla-runner-") as directory:
            root = Path(directory)
            tools = root / "game" / "tools"
            tools.mkdir(parents=True)
            runner = Path(os.environ.get("RUNNER_SCRIPT", Path(__file__).with_name("run_tests.sh")))
            shutil.copy2(runner, tools / "run_tests.sh")
            (tools / suite_name).write_text("# Engine stub owns this fixture.\n")
            engine = root / "godot-stub"
            engine.write_text('''#!/usr/bin/env bash
case " $* " in
  *" --editor "*)
    case "$RUNNER_CASE" in
      setup_error) echo 'import diagnostic: fixture failure'; exit 42 ;;
      setup_crash) echo 'import diagnostic: crash fixture'; exit 139 ;;
      setup_parse) echo 'SCRIPT ERROR: Parse Error: setup fixture'; exit 0 ;;
      setup_script_plain) echo 'SCRIPT ERROR fixture without colon'; exit 0 ;;
      setup_uid) echo 'ERROR: Unrecognized UID: uid://setup_fixture'; exit 0 ;;
      setup_file_access) echo 'ERROR: Condition "f.is_null()" is true. Continuing.'; echo '   at: get_multiple_md5 (core/io/file_access.cpp:967)'; exit 0 ;;
      setup_ansi) printf '\\033[91mERROR: colored import fixture\\033[0m\\n'; exit 0 ;;
      setup_warning) echo 'WARNING: ordinary import fixture'; exit 0 ;;
    esac
    exit 0 ;;
esac
echo invoked >> "$RUNNER_CALLS"
case "$RUNNER_CASE" in
  suite_parse) echo 'SCRIPT ERROR: Parse Error: suite fixture' ;;
  suite_error) echo 'PROBE RESULT: PASS'; exit 7 ;;
  suite_expected_error) echo 'ERROR: expected suite fixture';;
  timeout) exec sleep 30 ;;
  suite_runtime_hang) echo 'SCRIPT ERROR: Invalid call: fixture'; exec sleep 30 ;;
  suite_pass_runtime_hang)
    echo 'PROBE RESULT: PASS'; echo 'SCRIPT ERROR: Invalid call: fixture'; exec sleep 30 ;;
  suite_ignores_term)
    trap '' TERM; echo 'SCRIPT ERROR: Invalid call: fixture'; exec sleep 30 ;;
  suite_slow) sleep 2 ;;
  suite_child_hang|suite_child_error)
    exec "$RUNNER_PYTHON" "$RUNNER_CHILD_SCRIPT" ;;
  suite_many_failures)
    for index in $(seq 8); do echo "FAIL detail $index"; done
    echo 'PROBE RESULT: FAIL'; exit 1 ;;
esac
echo 'PROBE RESULT: PASS'
''')
            engine.chmod(0o755)
            calls = root / "calls"
            child_pid_path = root / "child.pid"
            child_script = root / "child.py"
            child_script.write_text("import os, subprocess, sys\nfrom pathlib import Path\nchild = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'], creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)\nPath(os.environ['RUNNER_CHILD_PID']).write_text(str(child.pid))\nif os.environ['RUNNER_CASE'] == 'suite_child_error':\n    print('SCRIPT ERROR: child fixture', flush=True)\nchild.wait()\n")
            command = [bash_executable(), (tools / "run_tests.sh").as_posix()]
            env = {**os.environ, "GODOT": engine.as_posix(), "RUNNER_CASE": mode,
                   "RUNNER_CALLS": calls.as_posix(), "SUITE_TIMEOUT": suite_timeout,
                   "TEST_LOG_DIR": (root / "logs").as_posix(),
                   "RUNNER_PYTHON": Path(sys.executable).as_posix(),
                   "RUNNER_CHILD_SCRIPT": child_script.as_posix(),
                   "RUNNER_CHILD_PID": child_pid_path.as_posix()}
            env.pop("UPGRADE_PROFILE_TIMEOUT", None)
            if profile_timeout is not None:
                env["UPGRADE_PROFILE_TIMEOUT"] = profile_timeout
            env.pop("PLAYER_TEXT_TIMEOUT", None)
            if text_timeout is not None:
                env["PLAYER_TEXT_TIMEOUT"] = text_timeout
            process = subprocess.Popen(command, env=env, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, text=True,
                                       start_new_session=os.name != "nt")
            try:
                stdout, stderr = process.communicate(timeout=12)
                result = subprocess.CompletedProcess(command, process.returncode, stdout, stderr)
                if mode.startswith("suite_child_"):
                    self.assertTrue(child_pid_path.is_file(), "fixture child must actually start")
                    result.descendant_alive = process_alive(int(child_pid_path.read_text()))
            finally:
                # A failing runner must not leave this test's injected engine alive.
                if os.name != "nt":
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                elif process.poll() is None:
                    subprocess.run(["taskkill.exe", "/PID", str(process.pid), "/T", "/F"], capture_output=True)
                process.wait()
                process.stdout.close()
                process.stderr.close()
                if child_pid_path.is_file():
                    child_pid = int(child_pid_path.read_text())
                    if process_alive(child_pid):
                        if os.name == "nt":
                            subprocess.run(["taskkill.exe", "/PID", str(child_pid), "/T", "/F"], capture_output=True)
                        else:
                            os.kill(child_pid, signal.SIGKILL)
            self.assertTrue((root / "logs" / "setup.log").is_file(), result.stdout + result.stderr)
            result.setup_log = (root / "logs" / "setup.log").read_text()
            result.setup_exit = int((root / "logs" / "setup.exit.txt").read_text().strip())
            if mode.startswith("setup_") and mode != "setup_warning":
                self.assertFalse((root / "logs" / (suite_name + ".log")).exists())
            else:
                self.assertTrue((root / "logs" / (suite_name + ".log")).is_file())
                result.suite_log = (root / "logs" / (suite_name + ".log")).read_text()
                result.suite_exit = int((root / "logs" / (suite_name + ".exit.txt")).read_text().strip())
            if mode == "suite_many_failures":
                self.assertIn("FAIL detail 8", (root / "logs" / "test_probe.gd.log").read_text())
                self.assertNotIn("FAIL detail 8", result.stdout)
            return result, calls.exists()

    @unittest.skipUnless(os.name == "nt", "Windows Git Bash selection")
    def test_windows_selects_git_bash_before_wsl(self):
        git = shutil.which("git")
        with patch.dict(os.environ, {"RUNNER_BASH": ""}), patch("shutil.which", side_effect=lambda name: git if name == "git" else "C:/Windows/System32/bash.exe"):
            self.assertNotEqual(bash_executable(), "C:/Windows/System32/bash.exe")
            self.assertTrue(Path(bash_executable()).is_file())

    def test_runner_stops_its_engine_descendants(self):
        for mode in ["suite_child_hang", "suite_child_error"]:
            with self.subTest(mode=mode):
                result, _ = self.run_case(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(result.descendant_alive, "runner left its fixture engine's child alive")

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

    def test_profile_guard_is_isolated_from_other_suites(self):
        result, _ = self.run_case("suite_slow", "test_upgrade_profiles.gd", profile_timeout="4")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        result, _ = self.run_case("suite_slow", "test_probe.gd", profile_timeout="4")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("0/1 suites passed", result.stdout)

    def test_failed_setup_stops_before_any_suite(self):
        for mode, code in [("setup_error", 42), ("setup_crash", 139), ("setup_parse", 1)]:
            with self.subTest(mode=mode):
                result, invoked = self.run_case(mode)
                self.assertEqual(result.returncode, code, result.stdout + result.stderr)
                self.assertFalse(invoked)
                self.assertEqual(result.setup_exit, 0 if mode == "setup_parse" else code)
                self.assertIn("FAIL setup:", result.stdout)
                self.assertIn("fixture", result.stdout)
                self.assertNotIn("suites passed", result.stdout)

    def test_zero_exit_import_errors_stop_before_any_suite(self):
        for mode in ["setup_uid", "setup_file_access", "setup_ansi", "setup_script_plain"]:
            with self.subTest(mode=mode):
                result, invoked = self.run_case(mode)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertEqual(result.setup_exit, 0)
                self.assertFalse(invoked)
                self.assertIn("FAIL setup:", result.stdout)
                self.assertIn("ERROR", result.setup_log)
                if mode == "setup_ansi":
                    self.assertIn("\x1b[91m", result.setup_log)
                self.assertNotIn("suites passed", result.stdout)

    def test_warnings_allow_suite_and_expected_suite_errors_stay_scoped(self):
        for mode in ["setup_warning", "suite_expected_error"]:
            with self.subTest(mode=mode):
                result, invoked = self.run_case(mode)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertTrue(invoked)
                self.assertEqual(result.setup_exit, 0)
                self.assertEqual(result.suite_exit, 0)
                self.assertIn("1/1 suites passed", result.stdout)

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
