"""Acceptance-harness regressions. Synthetic evidence lives only in temporary dirs."""

import contextlib
import csv
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch
import zlib

import m1_53_acceptance as acceptance


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="m1-53-unit-")
        self.addCleanup(self.temporary.cleanup)
        self.evidence = Path(self.temporary.name)
        name = "M1-53_run_01"
        self.json_path = self.evidence / f"{name}.json"
        self.data = {
            "cpu_only": False,
            "metadata": {"cpu_only": False, "display": "macOS", "driver": "metal",
                         "renderer": "forward_plus", "window": "(1280, 720)", "seconds": 20},
            "events": [{"event": event, "duration_ms": 10} for event in acceptance.EVENTS],
            "preparation_recoveries": [],
            "summaries": [{"sample": sample, "frames_or_calls": 2} for sample in acceptance.SAMPLES],
        }
        self.save_data()
        for suffix in (".log", "_engine.log"):
            (self.evidence / f"{name}{suffix}").write_text("PERF RESULT: PASS (rendered samples recorded)\n")
        with (self.evidence / f"{name}.csv").open("w", newline="") as stream:
            writer = csv.writer(stream)
            writer.writerow(("sample", "elapsed_ms", "frame_ms"))
            for sample in acceptance.SAMPLES:
                writer.writerows(((sample, 1, 1), (sample, 20000, 16.67)))
        # Valid black PNGs, generated strictly as temporary unit fixtures.
        def chunk(kind, data):
            return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
        png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1280, 720, 8, 2, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress((b"\x00" + bytes(1280 * 3)) * 720)) + chunk(b"IEND", b"")
        for event in acceptance.EVENTS:
            (self.evidence / f"{name}_{event}.png").write_bytes(png)

    def save_data(self):
        self.json_path.write_text(json.dumps(self.data))

    def test_complete_probe_has_artifact_hashes(self):
        result = acceptance.validate_probe(self.evidence, 1)
        self.assertEqual(len(result["artifacts_sha256"]), 9)

    def test_missing_pass_marker_rejected(self):
        (self.evidence / "M1-53_run_01.log").write_text("engine exited zero, no PASS")
        with self.assertRaisesRegex(ValueError, "Invalid log"):
            acceptance.validate_probe(self.evidence, 1)

    def test_script_error_after_pass_rejected(self):
        with (self.evidence / "M1-53_run_01.log").open("a") as stream:
            stream.write("SCRIPT ERROR: broken\n")
        with self.assertRaisesRegex(ValueError, "Invalid log"):
            acceptance.validate_probe(self.evidence, 1)

    def test_headless_shortened_and_recovered_probes_rejected(self):
        for key, value in (("display", "headless"), ("seconds", 1)):
            with self.subTest(key=key):
                original = self.data["metadata"][key]
                self.data["metadata"][key] = value
                self.save_data()
                with self.assertRaisesRegex(ValueError, "full 20-second"):
                    acceptance.validate_probe(self.evidence, 1)
                self.data["metadata"][key] = original
        self.data["preparation_recoveries"] = [{"step": "stuck"}]
        self.save_data()
        with self.assertRaisesRegex(ValueError, "recovery"):
            acceptance.validate_probe(self.evidence, 1)

    def test_truncated_csv_and_missing_screenshot_rejected(self):
        csv_path = self.evidence / "M1-53_run_01.csv"
        content = csv_path.read_text()
        csv_path.write_text(content.splitlines()[0] + "\n")
        with self.assertRaisesRegex(ValueError, "incomplete CSV"):
            acceptance.validate_probe(self.evidence, 1)
        csv_path.write_text(content)
        (self.evidence / "M1-53_run_01_full_cast_enter.png").unlink()
        with self.assertRaises(FileNotFoundError):
            acceptance.validate_probe(self.evidence, 1)


class ResumeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="m1-53-resume-unit-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.evidence = self.root / "production/qa/evidence"
        self.evidence.mkdir(parents=True)
        (self.evidence / "M1-53_capture.sh").touch()
        self.engine_calls = []
        for name, replacement in (
            ("ROOT", self.root), ("source_hash", lambda: "test-only-hash"),
            ("validate_forced", lambda _: None),
            ("validate_probe", lambda _, i: {"run": i, "artifacts_sha256": {"test": str(i)}}),
            ("run_engine", self.fake_engine),
        ):
            patcher = patch.object(acceptance, name, replacement)
            patcher.start()
            self.addCleanup(patcher.stop)
        signal_patch = patch.object(acceptance.signal, "signal")
        signal_patch.start()
        self.addCleanup(signal_patch.stop)

    def fake_engine(self, evidence, name, *args):
        self.engine_calls.append(name)
        if name.startswith("M1-53_run_"):
            (evidence / f"{name}.json").write_text("{}")
        elif name == "M1-53_forced_stall":
            (evidence / f"{name}.log").write_text("unit fixture")
        return 0.1

    def invoke(self, *args):
        with patch("sys.argv", ["capture", *args]), contextlib.redirect_stdout(io.StringIO()):
            return acceptance.main()

    def state(self):
        return json.loads((self.evidence / "M1-53_capture_progress.json").read_text())

    def test_two_run_batches_resume_and_only_tenth_can_pass(self):
        for count in (2, 4, 6, 8):
            self.assertEqual(self.invoke(), 3)
            self.assertEqual(len(self.state()["runs"]), count)
            self.assertFalse((self.evidence / "M1-53_ten_runs.json").exists())
        self.assertEqual(self.invoke(), 0)
        self.assertEqual([r["run"] for r in self.state()["runs"]], list(range(1, 11)))
        self.assertEqual(len([c for c in self.engine_calls if c.startswith("M1-53_run_")]), 10)
        self.assertEqual(self.engine_calls.count("M1-53_forced_stall"), 1)
        self.assertEqual(self.invoke("--verify-only"), 0)
        self.assertIn(acceptance.SUCCESS, (self.evidence / "M1-53_capture_summary.txt").read_text())

    def test_lost_summary_recovers_completed_fifth_without_rerunning(self):
        self.assertEqual(self.invoke("--max-runs", "4"), 3)
        self.fake_engine(self.evidence, "M1-53_run_05")
        self.assertEqual(self.invoke("--verify-only"), 3)
        self.assertEqual(len(self.state()["runs"]), 5)
        self.assertNotIn("M1-53_run_06", self.engine_calls)

    def test_failed_probe_latches_failure_and_cannot_be_skipped(self):
        self.assertEqual(self.invoke(), 3)
        with patch.object(acceptance, "run_engine", side_effect=RuntimeError("probe timed out")):
            self.assertEqual(self.invoke(), 1)
        with self.assertRaisesRegex(ValueError, "failed probe"):
            self.invoke()
        self.assertFalse((self.evidence / "M1-53_ten_runs.json").exists())

    def test_runtime_change_and_sequence_gap_rejected(self):
        self.assertEqual(self.invoke(), 3)
        with patch.object(acceptance, "source_hash", return_value="changed-runtime"):
            with self.assertRaisesRegex(ValueError, "Runtime changed"):
                self.invoke()
        (self.evidence / "M1-53_run_04.json").write_text("{}")
        self.assertEqual(self.invoke("--verify-only"), 1)
        self.assertIn("Gaps", self.state()["failure"])


if __name__ == "__main__":
    unittest.main()
