"""M1-116: bounded original-host retest with the unchanged native collector.

Outputs are private until reviewed and archived. Existing evidence/cache/save files
are read only. No production runtime, fixture behavior or project setting is edited.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import threading
import time
import zipfile

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
SHA = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()

def dump(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ['scratch', 'cache-from', 'godot', 'bash']:
        ap.add_argument('--' + name, type=Path, required=True)
    ap.add_argument('--prepared-from', type=Path)
    ap.add_argument('--prior-evidence', type=Path)
    args = ap.parse_args()
    scratch = args.scratch.resolve()
    assert not scratch.exists(), 'Never overwrite prior results'
    assert args.cache_from.is_dir() and args.godot.is_file() and args.bash.is_file()
    common = Path(subprocess.check_output(['git', 'rev-parse', '--path-format=absolute', '--git-common-dir'], cwd=ROOT, text=True).strip())
    assert scratch.is_relative_to(common.parent / '.codex')
    assert shutil.disk_usage(scratch.parent).free > 3 * 1024**3
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    gitdir = subprocess.check_output(['git', 'rev-parse', '--absolute-git-dir'], cwd=ROOT, text=True).strip()
    names = subprocess.check_output(['git', 'ls-files', '-z', 'game'], cwd=ROOT).decode().split('\0')
    names = [p for p in names if p]
    extra = ['production/qa/perf/collect_native.py', 'production/qa/playtests/first_impressions/retest_2026-11-09/capture_dry_zero.gd']
    source = {p: SHA(ROOT / p) for p in names + extra}
    for name in names:
        with (ROOT / name).open('rb') as f:
            assert not f.read(140).startswith(b'version https://git-lfs.github.com/spec/v1'), name
    save_dir = Path(os.environ['APPDATA']) / 'Godot/app_userdata/Last Light Academy'
    def saves():
        return {p.name: SHA(p) for p in save_dir.glob('last_light*.json')}
    before_save = saves()
    scratch.mkdir()
    project = scratch / 'project'
    project.mkdir()
    if args.prepared_from:
        assert args.prior_evidence and args.prepared_from.is_dir()
        shutil.copytree(args.prepared_from / 'project/game', project / 'game')
    else:
        shutil.copytree(ROOT / 'game', project / 'game', ignore=shutil.ignore_patterns('.godot'))
        shutil.copytree(args.cache_from, project / 'game/.godot')
    for name in extra:
        dest = project / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, dest)
    initial_differences = [n for n,h in source.items() if SHA(project / n) != h]
    if args.prepared_from:
        prior = json.loads((ROOT / 'production/qa/chapters/ch01/M1-85_cold_import_2026-11-10/resolution_20261111/current_complete/current_gate.json').read_text())['editor_normalization']
        assert initial_differences == ['game/project.godot']
        assert SHA(project / 'game/project.godot') == prior['editor_project_sha256']
        assert hashlib.sha256((ROOT / 'game/project.godot').read_bytes().replace(b'\r\n',b'\n')).hexdigest() == prior['original_project_sha256']
    else:
        assert not initial_differences
    raw = scratch / 'evidence'
    raw.mkdir()
    env = os.environ.copy()
    for key, sub in [('APPDATA', 'roaming'), ('LOCALAPPDATA', 'local'), ('TEMP', 'tmp'), ('TMP', 'tmp'), ('TMPDIR', 'tmp')]:
        folder = scratch / 'profile' / sub
        folder.mkdir(parents=True, exist_ok=True)
        env[key] = folder.as_posix()
    env.update(GODOT=args.godot.as_posix(), GIT_DIR=gitdir, GIT_WORK_TREE=str(ROOT), TEST_LOG_DIR=(raw / 'focused_logs').as_posix())
    query = "@{gpu=@(Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,PNPDeviceID);os=@(Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture);cpu=@(Get-CimInstance Win32_Processor | Select-Object Name)}|ConvertTo-Json -Depth 5"
    hardware = json.loads(subprocess.check_output(['powershell.exe', '-NoProfile', '-Command', query], text=True).lstrip('\ufeff'))
    binaries = {p.name: {'path': str(p), 'bytes': p.stat().st_size, 'sha256': SHA(p)} for p in [args.godot, args.godot.with_name(args.godot.name.replace('_console.exe', '.exe'))]}
    meta = {'task': 'M1-116', 'revision': revision, 'game_tree': subprocess.check_output(['git', 'rev-parse', 'HEAD:game'], cwd=ROOT, text=True).strip(), 'scratch': str(scratch), 'hardware': hardware, 'binaries': binaries, 'source_sha256': source, 'cache_policy': 'New source-matched project, copied retained M1-85 postmerge warm editor cache; isolated fresh profile. Native attempts share this new cache/profile and are separate processes, not independent cold imports.', 'cache_from': str(args.cache_from), 'native_collector': 'Unchanged published collect_native.py imported with ROOT/INPUT redirected to byte-verified isolated project; Popen observer records PID and optional hold diagnostics without changing engine arguments or results.', 'player_saves_before': before_save, 'complete': False, 'accepted': False, 'attempts': []}
    meta['executed_helper_sha256'] = SHA(Path(__file__))
    meta['initial_source_differences'] = initial_differences
    if args.prepared_from:
        meta['continuation'] = {'original_failed_scratch':str(args.prepared_from), 'prior_evidence':str(args.prior_evidence), 'sha256':{p.name:SHA(p) for p in args.prior_evidence.iterdir() if p.is_file()}, 'policy':'Separate warm project/cache copied from preserved failed setup, fresh isolated profile; original setup remains FAILED and is never retried. Only exact previously verified editor normalization (including canonical LF equality) is permitted.'}
    dump(OUT / 'provenance.json', meta)
    try:
        start = time.monotonic()
        with (raw / 'focused_runner.txt').open('w') as log:
            cmd = [str(args.bash), 'game/tools/run_tests.sh', 'campaign_interaction_input']
            rc = subprocess.call(cmd, cwd=project, env=env, stdout=log, stderr=subprocess.STDOUT)
        logs = list((raw / 'focused_logs').glob('*.log'))
        errors = [{'path': str(p.relative_to(raw)), 'lines': [line for line in p.read_text(errors='replace').splitlines() if re.search(r'ERROR:|SCRIPT ERROR|Parse Error|Failed to load script', line)]} for p in logs]
        meta['focused'] = {'command': cmd, 'exit_code': rc, 'seconds': time.monotonic() - start, 'diagnostics': [p for p in errors if p['lines']], 'runner': (raw / 'focused_runner.txt').read_text(errors='replace')}
        dump(OUT / 'provenance.json', meta)
        assert rc == 0 and not meta['focused']['diagnostics'] and '1/1 suites passed' in meta['focused']['runner'], 'Mandatory focused gate failed; retain diagnostics'
        spec = importlib.util.spec_from_file_location('native_collector', project / extra[0])
        collector = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(collector)
        collector.ROOT = project
        collector.INPUT = project / extra[1]
        original_popen = subprocess.Popen
        original_env = os.environ.copy()
        os.environ.update(env)
        try:
            for label, renderer, driver in [('forward1', 'forward_plus', 'vulkan'), ('forward2', 'forward_plus', 'vulkan'), ('compatibility', 'gl_compatibility', 'opengl3')]:
                destination = raw / label
                record = {'label': label}
                threads = []
                def observer(cmd, *pargs, **kwargs):
                    proc = original_popen(cmd, *pargs, **kwargs)
                    if isinstance(cmd, list) and cmd and str(cmd[0]) == str(args.godot.resolve()):
                        record.update(pid=proc.pid, command=cmd, start_epoch=time.time())
                        dump(raw / (label + '_process.json'), record)
                        def watch():
                            first = None
                            while proc.poll() is None:
                                logfile = destination / 'stdout.log'
                                if logfile.exists() and 'CAMPAIGN INTERACTION INPUT RESULT: PASS' in logfile.read_text(errors='replace'):
                                    if first is None:
                                        first = time.monotonic()
                                        record['pass_seen_epoch'] = time.time()
                                    if time.monotonic() - first >= 10 and not record.get('hold_diagnostics'):
                                        record['hold_diagnostics'] = True
                                        q = f"$p=Get-Process -Id {proc.pid};@{{pid=$p.Id;path=$p.Path;threads=@($p.Threads|Select-Object Id,ThreadState,WaitReason);modules=@($p.Modules|Select-Object ModuleName,FileName)}}|ConvertTo-Json -Depth 5"
                                        diag = original_popen(['powershell.exe','-NoProfile','-Command',q],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
                                        data,_ = diag.communicate(timeout=15)
                                        (destination / 'hold_process.txt').write_bytes(data)
                                        # A live-process minidump records native threads/modules; no engine
                                        # process is terminated or resumed by this diagnostic call.
                                        import ctypes
                                        from ctypes import wintypes
                                        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
                                        kernel.OpenProcess.restype = wintypes.HANDLE
                                        handle = kernel.OpenProcess(0x0400 | 0x0010, False, proc.pid)
                                        if handle:
                                            import msvcrt
                                            dbg = ctypes.WinDLL('Dbghelp', use_last_error=True)
                                            dbg.MiniDumpWriteDump.argtypes = [wintypes.HANDLE,wintypes.DWORD,wintypes.HANDLE,wintypes.DWORD,ctypes.c_void_p,ctypes.c_void_p,ctypes.c_void_p]
                                            with (destination / 'hold.dmp').open('wb') as f:
                                                ok = dbg.MiniDumpWriteDump(handle,proc.pid,msvcrt.get_osfhandle(f.fileno()),0,None,None,None)
                                            record['dump_ok'] = bool(ok)
                                            record['dump_winerror'] = ctypes.get_last_error()
                                            kernel.CloseHandle.argtypes = [wintypes.HANDLE]
                                            kernel.CloseHandle(handle)
                                        dump(raw / (label + '_process.json'), record)
                                time.sleep(.1)
                            record['process_returncode'] = proc.returncode
                            record['end_epoch'] = time.time()
                            dump(raw / (label + '_process.json'), record)
                        thread = threading.Thread(target=watch)
                        thread.start()
                        threads.append(thread)
                    return proc
                subprocess.Popen = observer
                sys.argv = ['collect_native.py', '--godot', str(args.godot), '--output', str(destination), '--case', 'input', '--renderer', renderer, '--driver', driver, '--timeout', '180']
                try:
                    rc = collector.main()
                finally:
                    subprocess.Popen = original_popen
                    for thread in threads:
                        thread.join(timeout=20)
                run = json.loads((destination / 'run.json').read_text())
                raw_errors = [line for p in [destination / 'stdout.log', destination / 'engine.log'] if p.exists() for line in p.read_text(errors='replace').splitlines() if re.search(r'ERROR:|SCRIPT ERROR|Parse Error|Failed to load script', line)]
                trace = json.loads((destination / 'input_trace.json').read_text()) if (destination / 'input_trace.json').exists() else {}
                record.update(collector_exit=rc, collector_run=run, raw_errors=raw_errors, trace_checks=trace.get('checks'), trace_failures=trace.get('failures'))
                meta['attempts'].append(record)
                dump(OUT / 'provenance.json', meta)
                assert rc == 0 and run['capture_checks_passed'] and not run['timed_out'] and run['raw_returncode'] == 0 and not raw_errors and trace.get('failures') == 0, 'Native attempt failed; preserve it before any repair or retry'
        finally:
            subprocess.Popen = original_popen
            os.environ.clear()
            os.environ.update(original_env)
        meta['complete'] = True
    finally:
        meta['player_saves_after'] = saves()
        meta['player_saves_unchanged'] = meta['player_saves_after'] == before_save
        meta['owned_source_unchanged'] = all(SHA(ROOT / p) == h for p,h in source.items())
        meta['generated_source_changes'] = [p for p,h in source.items() if SHA(project / p) != h]
        meta['project_before_sha256'] = source['game/project.godot']
        meta['project_after_sha256'] = SHA(project / 'game/project.godot')
        (raw / 'project_after.godot').write_bytes((project / 'game/project.godot').read_bytes())
        (raw / 'project_before.godot').write_bytes((ROOT / 'game/project.godot').read_bytes())
        # Editor-generated import metadata and the already documented Godot editor
        # normalization must remain explicitly visible, not silently discarded.
        prior = json.loads((ROOT / 'production/qa/chapters/ch01/M1-85_cold_import_2026-11-10/resolution_20261111/current_complete/current_gate.json').read_text())['editor_normalization']
        allowed_project = meta['project_after_sha256'] in [meta['project_before_sha256'],prior['editor_project_sha256']] and hashlib.sha256((ROOT / 'game/project.godot').read_bytes().replace(b'\r\n',b'\n')).hexdigest() == prior['original_project_sha256']
        meta['documented_editor_normalization_only'] = allowed_project and all(p.endswith('.import') or p == 'game/project.godot' for p in meta['generated_source_changes'])
        meta['accepted'] = meta['complete'] and meta['owned_source_unchanged'] and meta['player_saves_unchanged'] and meta['documented_editor_normalization_only'] and len(meta['attempts']) == 3
        with zipfile.ZipFile(OUT / 'raw_logs.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(raw.rglob('*')):
                if path.is_file() and path.suffix != '.dmp':
                    archive.write(path, path.relative_to(raw).as_posix())
        if args.prior_evidence:
            with zipfile.ZipFile(OUT / 'raw_logs.zip', 'a', zipfile.ZIP_DEFLATED) as archive:
                for path in sorted(args.prior_evidence.iterdir()):
                    if path.is_file():archive.write(path,'initial_failed_setup/' + path.name)
        dump(OUT / 'provenance.json', meta)
        print('M1-116 accepted:', meta['accepted'], flush=True)
    return 0 if meta['accepted'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
