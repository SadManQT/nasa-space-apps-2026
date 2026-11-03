"""Failure-path regressions, also invoked by Godot's showcase suite."""
import json
import subprocess
import unittest
from unittest.mock import patch

import verify_gate


class AssetGateTests(unittest.TestCase):
    def run_gate(self, stdout, stderr="", status=0, expected=("fixture",)):
        completed = subprocess.CompletedProcess([], status, stdout, stderr)
        with patch.object(verify_gate.subprocess, "run", return_value=completed):
            return verify_gate.godot_assets(expected)

    def test_nonzero_exit_even_with_records(self):
        with self.assertRaises(SystemExit):
            self.run_gate('ASSET {"file":"fixture"}', status=1)

    def test_script_error_even_with_zero_exit(self):
        with self.assertRaises(SystemExit):
            self.run_gate('ASSET {"file":"fixture"}', "SCRIPT ERROR: parse failure")

    def test_zero_assets(self):
        with self.assertRaises(SystemExit):
            self.run_gate("Godot Engine", expected=())

    def test_missing_expected_asset(self):
        with self.assertRaises(SystemExit):
            self.run_gate('ASSET {"file":"fixture"}', expected=("fixture", "missing"))

    def test_malformed_and_duplicate_records(self):
        for output in ['ASSET {}', 'ASSET broken', 'ASSET []',
                       'ASSET {"file":"fixture"}\nASSET {"file":"fixture"}']:
            with self.subTest(output=output), self.assertRaises(SystemExit):
                self.run_gate(output)

    def test_timeout(self):
        with patch.object(verify_gate.subprocess, "run", side_effect=subprocess.TimeoutExpired("godot", 300)):
            with self.assertRaises(SystemExit):
                verify_gate.godot_assets(["fixture"])

    def test_complete_success(self):
        record = {"file": "fixture", "loaded": True}
        self.assertEqual(self.run_gate("ASSET " + json.dumps(record)), {"fixture": record})


if __name__ == "__main__":
    unittest.main()
