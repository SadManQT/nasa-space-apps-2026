"""Verify published acceptance evidence; does not run Godot or modify game/cache/save data."""
import argparse
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[5])
    parser.add_argument('--output', type=Path, default=Path(__file__).with_name('validation.json'))
    args = parser.parse_args()
    root = args.root.resolve()
    def git(*parts):
        return subprocess.check_output(['git', *parts], cwd=root).decode('utf-8').strip()
    def read(path):
        return json.loads(path.read_text(encoding='utf-8'))
    def sha(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()
    combined = root/'production/qa/evidence/M1-125_117_gate_2026-11-10/combined119'
    summary = read(combined/'summary.json')
    started = read(combined/'ramim_started_provenance.json')
    rows = summary['results']
    current_names = sorted(path.name for path in (root/'game/tools').glob('test_*.gd'))
    assert len(rows) == 119
    assert [row['n'] for row in rows] == list(range(1, 120))
    assert [Path(row['suite']).name for row in rows] == current_names == started['suite_files']
    assert all(row['ok'] for row in rows)
    trees = {ref: git('rev-parse', ref+':game') for ref in ['11722b7d', '54be6a6f', '87707938', 'HEAD']}
    assert set(trees.values()) == {summary['game_tree']}
    logs = []
    for record in summary['raw_log_manifest']:
        path = combined/record['file']
        assert sha(path) == record['sha256'], path
        logs.append(record['file'])
    assert len(logs) == 77
    peer = read(root/'production/qa/evidence/M1-125_suites_42-119_sadman/summary.json')
    assert peer['head'] == '54be6a6f'
    assert len(peer['results']) == 78
    assert [row['n'] for row in peer['results']] == list(range(42, 120))
    for original, combined_row in zip(peer['results'], rows[41:]):
        assert all(original[key] == combined_row[key] for key in ['n', 'suite', 'ok', 'rc', 'line'])
    # Peer raw suite logs were not published. This validates the accepted report, not those missing bytes.
    relevant = [row for row in rows if Path(row['suite']).name in {
        'test_garden_collision.gd', 'test_garden_movement.gd', 'test_habitat_rooms.gd',
        'test_chapter1_campaign_flow.gd', 'test_player_controller.gd', 'test_performance_runtime.gd'}]
    perf = combined.parent/'raw_cleanup/perf-final-11722b7d'
    perf_meta = read(perf/'manifest.json')
    assert perf_meta['game_tree']['stdout'] == summary['game_tree']
    perf_results = []
    error_pattern = re.compile(r'^\s*(?:SCRIPT ERROR|ERROR):', re.MULTILINE)
    for row in perf_meta['runs']:
        folder = perf/('run-'+str(row['index']))
        assert row['exit_code'] == 0
        assert sha(perf/row['stage_trace']['path']) == row['stage_trace']['sha256']
        log = (folder/'test_performance_runtime.gd.txt').read_text(encoding='utf-8')
        runner = (folder/'runner.txt').read_text(encoding='utf-8')
        setup = (folder/'setup.txt').read_text(encoding='utf-8')
        assert 'PERFORMANCE RUNTIME RESULT: PASS (618 checks, 0 failures)' in log
        assert '1/1 suites passed' in runner
        assert not error_pattern.search(log+'\n'+setup)
        perf_results.append({'index': row['index'], 'checks': 618, 'failures': 0,
                             'runner_summary': '1/1 suites passed', 'raw_engine_errors': 0})
    assert len(perf_results) == 2
    pilot = root/'production/qa/evidence/M1-123/current_pilot_20261110'
    native_meta = read(pilot/'verification_resync/run.json')
    native = next(row for row in native_meta['runs'] if row['name'] == 'native')
    assert sha(root/'game/tools/test_garden_movement.gd') == native_meta['pilot_source_sha256']
    unchanged = ['game/resources/campaign/rooms/LOC-03.json',
                 'game/tools/test_garden_collision.gd', 'game/scripts/player/player_controller.gd']
    for path in unchanged:
        assert git('rev-parse', native_meta['base_commit']+':'+path) == git('rev-parse', 'HEAD:'+path)
    assert native['invocation']['effective_exit_code'] == 0
    assert native['invocation']['generic_error_count'] == 0
    assert not native['invocation']['script_error_lines']
    trace = native['trace_summary']
    assert trace['checks'] == 62 and trace['failures'] == 0 and len(trace['center_rows']) == 4
    for row in trace['center_rows'].values():
        x, y, z = row['position']
        assert (x*x+(z-0.5)**2)**0.5 < 0.25 and abs(y) < 0.06
        assert row['speed'] < 0.03 and not row['movement_locked']
    assert len(native['pngs']) == 8
    for row in native['pngs']:
        assert sha(pilot/'verification_resync'/row['file']) == row['sha256']
    manifests = []
    for relative in [
        'production/qa/evidence/M1-122/current_acceptance_20261110/artifacts.json',
        'production/qa/evidence/M1-122/current_acceptance_20261110/post_sync_f328/artifacts.json',
        'production/qa/evidence/M1-123/current_pilot_20261110/artifacts.json',
        'production/qa/chapters/ch01/M1-85_cold_import_2026-11-10/current_recheck_20261110/artifacts.json']:
        path = root/relative
        manifest = read(path)
        for row in manifest['artifacts']:
            artifact = path.parent/row['file']
            assert sha(artifact) == row['sha256'] and artifact.stat().st_size == row['bytes'], artifact
        manifests.append({'file': relative, 'verified': len(manifest['artifacts'])})
    subprocess.run(['python', 'production/plan/board.py', 'check'], cwd=root, check=True)
    board = read(root/'production/plan/tasks.json')
    statuses = {row['id']: row['status'] for row in board['tasks'] if row['id'] in {'M1-122','M1-123','M1-85'}}
    result = {'checked_utc': datetime.now(timezone.utc).isoformat(), 'head': git('rev-parse','HEAD'),
              'verifier_sha256': sha(Path(__file__)), 'game_trees': trees,
              'accepted_suites': 119, 'reported_failures': 0, 'exact_suite_coverage': True,
              'combined_windows_raw_hashes_verified': len(logs), 'preserved_artifacts': manifests,
              'relevant_current_results': relevant, 'original_windows_performance': perf_results,
              'native': {'source_base': native_meta['base_commit'], 'pilot_sha256': native_meta['pilot_source_sha256'],
                         'unchanged_git_paths': unchanged, 'checks': 62, 'failures': 0,
                         'png_hashes_verified': len(native['pngs']), 'four_center_cases_verified': True},
              'board_statuses': statuses, 'new_game_runs': 0,
              'qualification': 'Reuses explicitly accepted combined119 across Windows/Godot4.7 and macOS/Godot4.7.2. No uninterrupted full119 exit result; peer raw logs absent. Native remains its original Arc Compatibility capture snapshot. Historical exact pose unknown; two sparse-render diagnostics remain failed with79errors each. M1-85 native139 unresolved; no cause inferred from loading repair.'}
    args.output.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print('Verified: current accepted119,77raw hashes,274preserved artifacts, two618/0performance runs and original62/0native. No game run repeated.')


if __name__ == '__main__':
    main()
