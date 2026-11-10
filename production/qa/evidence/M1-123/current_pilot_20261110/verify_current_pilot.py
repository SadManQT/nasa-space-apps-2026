"""Bounded real-campaign pilot verification; preserves source, caches and user saves."""
import argparse
import json
import os
from pathlib import Path
import runpy
import subprocess
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--bash', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--profiles', type=Path, required=True)
    parser.add_argument('--prior-collection', type=Path)
    args = parser.parse_args()
    root, output, profiles = args.root.resolve(), args.output.resolve(), args.profiles.resolve()
    if args.prior_collection:
        prior = json.loads(args.prior_collection.read_text(encoding='utf-8'))
        assert prior.get('complete'), 'Prior import collection must finish before another engine starts'
    assert not output.exists() and not profiles.exists(), 'Refusing to overwrite verification evidence'
    output.mkdir(parents=True)
    profiles.mkdir(parents=True)
    api_path = root / 'production/qa/chapters/ch01/M1-85_cold_import_2026-11-10/cold_import_repro.py'
    api = runpy.run_path(str(api_path))
    sha, dump = api['sha'], api['dump']

    def git(*parts):
        return subprocess.check_output(['git', *parts], cwd=root, text=True).strip()

    def snapshot():
        names = subprocess.check_output(['git', 'ls-files', '-z', '--', 'game'], cwd=root).decode().split('\0')
        return {name: sha(root / name) for name in names if name}

    def fresh_env(name):
        env = os.environ.copy()
        for key, suffix in [('APPDATA', 'roaming'), ('LOCALAPPDATA', 'local'), ('TEMP', 'tmp'), ('TMP', 'tmp'), ('TMPDIR', 'tmp')]:
            folder = profiles / name / suffix
            folder.mkdir(parents=True, exist_ok=True)
            env[key] = folder.as_posix()
        env.update(GODOT=str(args.godot.resolve()), SUITE_TIMEOUT='300', PLAYER_TEXT_TIMEOUT='1500')
        return env

    def trace_summary(folder):
        trace = json.loads((folder / 'movement_trace.json').read_text(encoding='utf-8'))
        ends = {}
        for row in trace['trace']:
            if row['phase'].startswith('leg_end:'):
                ends[row['trial']] = row
        assert len(ends) == 4
        for row in ends.values():
            x, y, z = row['position']
            assert (x*x + (z-0.5)**2)**0.5 < 0.25 and abs(y) < 0.06
            assert row['speed'] < 0.03 and not row['movement_locked']
        return {'checks': trace['checks'], 'failures': trace['failures'], 'corrections': sum(row['phase'] == 'recover_correction' for row in trace['trace']), 'key_resyncs': sum(row['phase'] == 'input_resync' for row in trace['trace']), 'center_rows': ends}

    # Do not overlap another Godot process, including a surviving old test child.
    check = subprocess.check_output(['powershell.exe', '-NoProfile', '-Command', "$ErrorActionPreference='Stop'; $items=@(Get-CimInstance Win32_Process -ErrorAction Stop -Filter \"Name like '%Godot%'\"); [pscustomobject]@{count=$items.Count;ids=@($items.ProcessId)} | ConvertTo-Json -Compress"], text=True, timeout=20)
    processes = json.loads(check.lstrip('\ufeff'))
    assert processes['count'] == 0, 'Another Godot process is active; inspect instead of overlapping it'
    base_commit = git('rev-parse', 'HEAD')
    with (output / 'lfs_checkout.txt').open('wb') as stream:
        subprocess.run(['git', 'lfs', 'checkout', 'game'], cwd=root, stdout=stream, stderr=subprocess.STDOUT, check=True)
    inputs = api['frozen_inputs'](root, base_commit)
    for row in inputs:
        if 'lfs_source' in row:
            assert sha(root / row['path']) == row['sha256'], 'Unhydrated or changed LFS payload: ' + row['path']
    save = Path(os.environ['APPDATA']) / 'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
    before = snapshot()
    metadata = {'base_commit': base_commit, 'base_game_tree': git('rev-parse', 'HEAD:game'), 'owned_uncommitted_diff': git('diff', '--', 'game/tools/test_garden_movement.gd'), 'pilot_source_sha256': sha(root / 'game/tools/test_garden_movement.gd'), 'verifier_sha256': sha(Path(__file__).resolve()), 'invoke_helper_sha256': sha(api_path), 'godot_sha256': sha(args.godot), 'project_cache_before': api['cache_state'](root), 'source_before': before, 'save_sha256_before': sha(save) if save.exists() else None, 'profile_root': str(profiles), 'runs': [], 'complete': False, 'scope': 'Only approved test input pilot changes. Runtime/capsule/collision untouched. Two ordinary mandatory Garden processes with distinct profiles; native real-campaign four ending/input cases; optional separately labeled sparse-render diagnostic.'}

    def persist():
        dump(output / 'run.json', metadata)

    def guard():
        after = snapshot()
        changed = [name for name, digest in before.items() if after.get(name) != digest]
        assert all(name.endswith('.import') for name in changed), 'Unexpected non-import source change: ' + str(changed)
        metadata['generated_import_changes'] = changed
        assert sha(root / 'game/tools/test_garden_movement.gd') == metadata['pilot_source_sha256']
        assert (sha(save) if save.exists() else None) == metadata['save_sha256_before'], 'Original user save changed'

    persist()
    for name in ['focused1', 'focused2']:
        folder = output / name
        folder.mkdir()
        result = api['invoke'](folder, 'runner', [str(args.bash), 'game/tools/run_tests.sh', 'garden'], root, fresh_env(name), 1200)
        metadata['runs'].append({'name': name, 'invocation': result})
        persist()
        assert result['effective_exit_code'] == 0 and result['suite_summary'] == ['2/2 suites passed']
        assert not result['script_error_lines'] and result['generic_error_count'] == 0
        summary = trace_summary(folder / 'runner_logs')
        assert summary['checks'] == 54 and summary['failures'] == 0
        metadata['runs'][-1]['trace_summary'] = summary
        guard()
        persist()

    for name, extra, capture in [('native', [], True), ('sparse_native', ['--max-fps', '10'], False)]:
        if name == 'sparse_native' and any(row.get('trace_summary', {}).get('corrections', 0) for row in metadata['runs']):
            metadata['sparse_skipped_reason'] = 'Correction already observed in ordinary verification; no additional run needed'
            break
        folder = output / name
        folder.mkdir()
        logs = folder / 'capture'
        logs.mkdir()
        env = fresh_env(name)
        env['TEST_LOG_DIR'] = logs.as_posix()
        command = [str(args.godot.resolve()), '--path', 'game', '--rendering-method', 'gl_compatibility', '--resolution', '1280x720', *extra, '--script', 'res://tools/test_garden_movement.gd']
        if capture:
            command += ['--', '--capture']
        result = api['invoke'](folder, 'native', command, root, env, 300)
        end_epoch = time.time()
        entry = {'name': name, 'invocation': result, 'invocation_end_utc_epoch': end_epoch, 'renderer': 'Compatibility', 'sparse_render_cap': 10 if extra else None}
        metadata['runs'].append(entry)
        persist()
        log = (folder / 'native.txt').read_text(encoding='utf-8', errors='replace')
        expected_checks = 62 if capture else 54
        assert result['effective_exit_code'] == 0 and f'GARDEN MOVEMENT RESULT: PASS ({expected_checks} checks, 0 failures)' in log
        assert not result['script_error_lines'] and result['generic_error_count'] == 0
        entry['trace_summary'] = trace_summary(logs)
        pngs = sorted(logs.glob('*.png'))
        assert len(pngs) == (8 if capture else 0)
        entry['pngs'] = []
        for path in pngs:
            assert result['start_utc_epoch'] <= path.stat().st_mtime <= end_epoch
            entry['pngs'].append({'file': path.relative_to(output).as_posix(), 'sha256': sha(path), 'mtime_utc_epoch': path.stat().st_mtime})
        guard()
        persist()
    metadata['source_after'] = snapshot()
    metadata['save_sha256_after'] = sha(save) if save.exists() else None
    metadata['save_unchanged'] = metadata['save_sha256_before'] == metadata['save_sha256_after']
    metadata['complete'] = True
    persist()
    print('Pilot verification complete; source guard and original-save guard passed', flush=True)


if __name__ == '__main__':
    main()