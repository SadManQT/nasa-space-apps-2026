"""One controlled sparse-native rerun with a shorter isolated QA profile."""
import argparse
import json
import os
from pathlib import Path
import runpy
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--godot', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--profiles', type=Path, required=True)
args = parser.parse_args()
root, output, profiles = Path.cwd().resolve(), args.output.resolve(), args.profiles.resolve()
assert not output.exists() and not profiles.exists(), 'Refusing to overwrite an earlier case'
api_path = root / 'production/qa/chapters/ch01/M1-85_cold_import_2026-11-10/cold_import_repro.py'
api = runpy.run_path(str(api_path))
sha, dump = api['sha'], api['dump']
query = subprocess.check_output(['powershell.exe', '-NoProfile', '-Command', "$ErrorActionPreference='Stop'; $items=@(Get-CimInstance Win32_Process -ErrorAction Stop -Filter \"Name like '%Godot%'\"); [pscustomobject]@{count=$items.Count} | ConvertTo-Json -Compress"], text=True, timeout=20)
assert json.loads(query.lstrip('\ufeff'))['count'] == 0, 'Another engine is active'
output.mkdir(parents=True)
profiles.mkdir(parents=True)
trace_dir = output / 'trace'
trace_dir.mkdir()
source_names = [s for s in subprocess.check_output(['git', 'ls-files', '-z', '--', 'game'], text=True).split('\0') if s]
before = {s: sha(root / s) for s in source_names}
save = Path(os.environ['APPDATA']) / 'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
save_before = sha(save) if save.exists() else None
env = os.environ.copy()
for key, suffix in [('APPDATA', 'r'), ('LOCALAPPDATA', 'l'), ('TEMP', 't'), ('TMP', 't'), ('TMPDIR', 't')]:
    folder = profiles / suffix
    folder.mkdir(exist_ok=True)
    env[key] = folder.as_posix()
env['TEST_LOG_DIR'] = trace_dir.as_posix()
command = [str(args.godot.resolve()), '--path', 'game', '--rendering-method', 'gl_compatibility', '--resolution', '1280x720', '--max-fps', '10', '--script', 'res://tools/test_garden_movement.gd']
meta = {'scope': 'One rerun of the failed optional sparse-render diagnostic with a fresh shorter profile prefix. Same game, engine, Compatibility renderer, max-fps10, physics settings, input budget and assertions. No production setting changed; path causation is not assumed.', 'base_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(), 'pilot_source_sha256': sha(root / 'game/tools/test_garden_movement.gd'), 'verifier_sha256': sha(Path(__file__).resolve()), 'invoke_helper_sha256': sha(api_path), 'profiles': str(profiles), 'env': {k:env[k] for k in ['APPDATA','LOCALAPPDATA','TEMP','TMP','TMPDIR','TEST_LOG_DIR']}, 'source_before': before, 'save_sha256_before': save_before, 'complete': False}
dump(output / 'run.json', meta)
result = api['invoke'](output, 'native', command, root, env, 300)
meta['invocation'] = result
meta['invocation_end_utc_epoch'] = time.time()
text = (output / 'native.txt').read_text(encoding='utf-8', errors='replace')
trace = json.loads((trace_dir / 'movement_trace.json').read_text(encoding='utf-8'))
ends = {}
for row in trace['trace']:
    if row['phase'].startswith('leg_end:'):
        ends[row['trial']] = row
meta['center_rows'] = ends
meta['movement_checks_passed'] = result['effective_exit_code'] == 0 and 'GARDEN MOVEMENT RESULT: PASS (54 checks, 0 failures)' in text and trace['checks'] == 54 and trace['failures'] == 0
meta['settled_centers_passed'] = len(ends) == 4 and all((r['position'][0]**2 + (r['position'][2]-0.5)**2)**0.5 < 0.25 and abs(r['position'][1]) < 0.06 and r['speed'] < 0.03 for r in ends.values())
meta['corrections'] = sum(r['phase'] == 'recover_correction' for r in trace['trace'])
meta['key_resyncs'] = sum(r['phase'] == 'input_resync' for r in trace['trace'])
meta['log_integrity_passed'] = not result['script_error_lines'] and result['generic_error_count'] == 0
meta['source_after'] = {s: sha(root / s) for s in source_names}
meta['changed_tracked_files'] = [s for s in source_names if meta['source_after'][s] != before[s]]
meta['non_import_source_unchanged'] = all(s.endswith('.import') for s in meta['changed_tracked_files'])
meta['save_sha256_after'] = sha(save) if save.exists() else None
meta['save_unchanged'] = meta['save_sha256_after'] == save_before
cache_files = [p for p in profiles.rglob('*') if p.is_file() and 'shader_cache' in p.as_posix()]
meta['shader_cache_files'] = [{'file': str(p), 'path_characters':len(str(p)), 'sha256':sha(p), 'bytes':p.stat().st_size} for p in cache_files]
meta['complete'] = True
meta['success'] = all(meta[k] for k in ['movement_checks_passed','settled_centers_passed','log_integrity_passed','non_import_source_unchanged','save_unchanged'])
dump(output / 'run.json', meta)
print('Sparse shorter-profile result:', meta['success'], 'errors:',result['generic_error_count'],'corrections:',meta['corrections'], flush=True)
raise SystemExit(0 if meta['success'] else 1)