#!/usr/bin/env python3
"""Validate M1-76's current GPU artifacts and refresh their derived records.

Called by capture.sh after both renderers finish, or with --verify-only to
recount saved evidence without opening a window. Requires Pillow and NumPy.
"""
import hashlib
import importlib.util
import json
import re
import getpass
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = ROOT / 'production/qa/evidence'
VIEWS = ('opening', 'shadows', 'character_shadows_off', 'furniture_shadows_off')
ERROR_PATTERN = re.compile(
    r'SCRIPT ERROR|Parse Error|Failed to load script|dual.?paraboloid.*(unsupported|not supported)|must.*cube|cube.*required',
    re.I,
)


def modified_at(path):
    """Return an artifact's filesystem write time as UTC, explicitly not a launch time."""
    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat()


def brighter_pixels(before, after):
    """Recount the lower-half, alternate-pixel ablation in the saved RGB PNGs."""
    before = before[before.shape[0] // 2::2, ::2].astype(np.float64)
    after = after[after.shape[0] // 2::2, ::2].astype(np.float64)
    # Retain the reviewer's byte-scale recount convention. Separate luminances
    # and a >2 byte-level threshold avoid normalization changing borderline sums.
    before_luma = 0.2126 * before[:, :, 0] + 0.7152 * before[:, :, 1] + 0.0722 * before[:, :, 2]
    after_luma = 0.2126 * after[:, :, 0] + 0.7152 * after[:, :, 1] + 0.0722 * after[:, :, 2]
    return int(np.count_nonzero(after_luma - before_luma > 2.0))


def refresh_records(sentence):
    """Replace only M1-76's marked capture facts; regenerate HTML through the board API."""
    start, end = '<!-- M1-76 capture -->', '<!-- /M1-76 capture -->'
    for relative in ('PRODUCTION_HANDBOOK.md', 'production/AI_PROMPT_LOG.md'):
        path = ROOT / relative
        text = path.read_text()
        assert text.count(start) == text.count(end) == 1, f'Missing M1-76 evidence markers: {path}'
        text = re.sub(re.escape(start) + '.*?' + re.escape(end), lambda _: start + sentence + end, text)
        path.write_text(text)
    spec = importlib.util.spec_from_file_location('m1_76_board', ROOT / 'production/plan/board.py')
    board = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(board)
    data = board.load()
    task = board.by_id(data)['M1-76']
    start, end = '[M1-76 capture]', '[/M1-76 capture]'
    evidence = task['evidence']
    assert evidence.count(start) == evidence.count(end) == 1, 'Missing M1-76 board evidence markers'
    task['evidence'] = re.sub(re.escape(start) + '.*?' + re.escape(end), lambda _: start + sentence + end, evidence)
    # Updating capture facts must never change the claim or mark untested work done.
    board.save(data)


def main():
    """Validate both complete capture sets, recount PNGs and replace every capture-derived field."""
    summary_path = EVIDENCE / 'M1-76_verification.json'
    summary = json.loads(summary_path.read_text())
    layout = json.loads((ROOT / 'game/resources/campaign/rooms/LOC-01.json').read_text())
    now = datetime.now(timezone.utc).isoformat()
    windowed, crosscheck, manifest, provenance = {}, {}, {}, {}
    screenshots = []
    for renderer, mode in (('forward_plus', 0), ('gl_compatibility', 1)):
        probe = EVIDENCE / f'M1-76_{renderer}_probe.json'
        report = json.loads(probe.read_text())
        assert report['rendered'] and report['renderer'] == renderer and report['failures'] == 0, report
        assert report['display'] != 'headless', report
        assert len(report['lights']) == len(layout['ceiling_strips']), report
        assert sum(light['shadow_enabled'] for light in report['lights']) == layout['lighting']['shadow_lights'], report
        assert all(light['shadow_mode'] == mode for light in report['lights']), report
        images = {}
        for view in VIEWS:
            path = EVIDENCE / f'M1-76_{renderer}_{view}.png'
            with Image.open(path) as image:
                assert image.format == 'PNG' and image.size == (1280, 720), path
                images[view] = np.array(image.convert('RGB'))
            manifest[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
            screenshots.append(path.name)
        crosscheck[renderer] = {}
        for subject in ('character', 'furniture'):
            assert report[subject]['caster_count'] > 0, report
            threshold = max(32, 2 * report['control_brighter_pixels'])
            assert report[subject]['brighter_pixels'] > threshold, report
            count = brighter_pixels(images['shadows'], images[subject + '_shadows_off'])
            assert count > threshold, f'{renderer} saved {subject} PNG fails shadow ablation: {count}'
            crosscheck[renderer][subject + '_brighter_pixels'] = count
        log_path = EVIDENCE / f'M1-76_{renderer}_capture.txt'
        engine_path = EVIDENCE / f'M1-76_{renderer}_engine.log'
        log = log_path.read_text()
        assert re.search(r'^M1-76 CAPTURE RESULT: PASS \(\d+ checks, 0 failures\)$', log, re.M), renderer
        assert not ERROR_PATTERN.search(log), renderer
        if engine_path.exists():
            assert not ERROR_PATTERN.search(engine_path.read_text()), engine_path
        lines = log.splitlines()
        errors = ['\n'.join(lines[i:i+3]) for i, line in enumerate(lines) if line.startswith('ERROR:')]
        (EVIDENCE / f'M1-76_{renderer}_other_errors.txt').write_text('\n\n'.join(errors) + '\n')
        windowed[renderer] = {
            'probe': probe.name, 'log': log_path.name, 'driver': report['driver'], 'display': report['display'],
            'checks': report['checks'], 'failures': report['failures'],
            'shadow_modes': [light['shadow_mode'] for light in report['lights']],
            'control_brighter_pixels': report['control_brighter_pixels'],
            'character': report['character'], 'furniture': report['furniture'],
            'unsupported_shadow_errors': 0,
            'shader_cache_write_errors': sum('_save_to_cache' in error for error in errors),
            'other_engine_errors': len(errors),
        }
        provenance[renderer] = {
            'runner': report.get('capture_runner') or 'Night-shift desktop runner: production/tools/night_shift.py run_capture -> bash M1-76_capture.sh',
            'time_basis': 'probe launch/finish timestamps' if report.get('capture_started_at_utc') else 'artifact mtimes; original process identity and launch time were not recorded',
            'started_at_utc': report.get('capture_started_at_utc'),
            'first_png_written_at_utc': modified_at(EVIDENCE / f'M1-76_{renderer}_opening.png'),
            'finished_at_utc': report.get('capture_finished_at_utc') or modified_at(probe),
            'probe_sha256': hashlib.sha256(probe.read_bytes()).hexdigest(),
            'log_sha256': hashlib.sha256(log_path.read_bytes()).hexdigest(),
        }
        print(f'M1-76 {renderer}: Godot probe character/furniture {report["character"]["brighter_pixels"]}/{report["furniture"]["brighter_pixels"]}; saved PNG {crosscheck[renderer]["character_brighter_pixels"]}/{crosscheck[renderer]["furniture_brighter_pixels"]}')

    # Visual inspection is a separate claim from automated validation. Retain it
    # only when a named reviewer inspected these exact eight image hashes.
    review = summary.get('visual_review', {})
    if not isinstance(review, dict) or review.get('screenshot_sha256') != manifest:
        review = {'status': 'pending', 'reason': 'Current PNGs require visual inspection; automatic ablation checks passed.', 'screenshot_sha256': manifest}
    summary.update({
        'windowed_verification': {
            'status': 'passed', 'validated_at_utc': now,
            'method': 'GPU probe reports, PASS markers, error logs and decoded 1280x720 PNGs; in-memory probe and saved-PNG counts are distinct measurements.',
            'renderers': windowed, 'screenshot_count': len(screenshots),
        },
        'capture_provenance': {'renderers': provenance, 'validated_at_utc': now,
                               'validated_by': 'M1-76_verify.py (OS user: ' + getpass.getuser() + ')',
                               'screenshot_sha256': manifest},
        'saved_png_shadow_crosscheck': {
            'method': 'Decoded RGB PNGs as float64 byte values; every other pixel in lower half; separate before/after luminances with weights 0.2126/0.7152/0.0722; ablation increase >2 byte levels (equivalent to >2/255 normalized). Float precision at the threshold can differ from Godot Color.get_luminance; exact equality with the pre-save probe is not required.',
            'validated_at_utc': now, **crosscheck,
        },
        'visual_review': review, 'expected_screenshots': screenshots,
    })
    summary['other_errors']['windowed_captures'] = {
        renderer: {key: result[key] for key in ('unsupported_shadow_errors', 'shader_cache_write_errors', 'other_engine_errors')}
        for renderer, result in windowed.items()
    }
    tests = (EVIDENCE / 'M1-76_tests.txt').read_text().splitlines()
    summary['test_runner_last_line'] = tests[-1] if tests and re.fullmatch(r'\d+/\d+ suites passed', tests[-1]) else 'pending; M1-76_tests.txt is incomplete'
    summary_path.write_text(json.dumps(summary, indent=2) + '\n')
    parts = []
    for renderer, label in (('forward_plus', 'Forward+'), ('gl_compatibility', 'Compatibility')):
        p, w, c = provenance[renderer], windowed[renderer], crosscheck[renderer]
        parts.append(f'{label}: {p["runner"]}; first PNG {p["first_png_written_at_utc"]}, report finished {p["finished_at_utc"]}; Godot probe character/furniture {w["character"]["brighter_pixels"]}/{w["furniture"]["brighter_pixels"]} pixels, saved-PNG recount {c["character_brighter_pixels"]}/{c["furniture_brighter_pixels"]}, control drift {w["control_brighter_pixels"]}, {w["shader_cache_write_errors"]} cache-write errors and {w["other_engine_errors"]} total other engine errors.')
    checks = f'Forward+ {windowed["forward_plus"]["checks"]} and Compatibility {windowed["gl_compatibility"]["checks"]}'
    sentence = ' '.join(parts) + f' {checks} checks passed, eight PNGs total, zero unsupported-shadow errors. Required test runner: ' + summary['test_runner_last_line'] + '. Visual review: ' + review['status'] + '. Details: production/qa/evidence/M1-76_verification.json. '
    refresh_records(sentence)
    print('M1-76 EVIDENCE RESULT: PASS (2 renderers, 8 screenshots)')


if __name__ == '__main__':
    main()
