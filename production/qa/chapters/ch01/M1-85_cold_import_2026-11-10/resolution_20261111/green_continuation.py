"""M1-85 green-only continuation after preserving a fresh native failed state."""
import json
import os
from pathlib import Path
import runpy
import shutil
import subprocess


def main():
    out=Path(__file__).resolve().parent;api=runpy.run_path(str(out.parent/'cold_import_repro.py'));sha,dump=api['sha'],api['dump']
    prior=json.loads((out/'run.json').read_text());capture=json.loads((out/'native_capture.json').read_text());saved=json.loads((out/'native_inputs.json').read_text())
    assert capture['stopped_run_sha256']==sha(out/'run.json') and capture['native_manifest_sha256']==sha(out/'native_inputs.json')
    assert not prior['complete'] and not (out/'green_continuation.json').exists()
    scratch=Path(prior['native_failure_preserved']).parent;project=scratch/'green2';profile=scratch/'profiles/green2'
    for rel,row in saved['green2'].items():
        path=(project/rel) if rel.startswith('game/') else profile/rel.removeprefix('profile/')
        assert sha(path)==row['sha256']
    # The byte-identical baseline2 remains untouched and retains the full pre-control input.
    for rel,row in saved['baseline2'].items():
        path=(scratch/'baseline2'/rel) if rel.startswith('game/') else scratch/'profiles/baseline2'/rel.removeprefix('profile/')
        assert sha(path)==row['sha256']
    q="$ErrorActionPreference='Stop';$x=@(Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\");[pscustomobject]@{count=$x.Count}|ConvertTo-Json -Compress"
    assert json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-Command',q],text=True,timeout=30).lstrip('\ufeff'))['count']==0
    old=out.parent/'recovered_repro_20261110';old_env=json.loads((old/'environment.json').read_text());engine=Path(old_env['godot'])
    assert sha(engine)==prior['godot_sha256']
    manifest=json.loads((old/'source_manifest.json').read_text());original=Path(old_env['scratch'])/'b'
    env=os.environ.copy()
    for key,sub in [('APPDATA','roaming'),('LOCALAPPDATA','local'),('TEMP','tmp'),('TMP','tmp'),('TMPDIR','tmp')]:env[key]=(profile/sub).as_posix()
    env.update(GODOT=engine.as_posix(),SUITE_TIMEOUT='300')
    save=Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
    state={'collector_sha256':sha(Path(__file__)),'stopped_run_sha256':sha(out/'run.json'),'native_capture_sha256':sha(out/'native_capture.json'),'source_game_tree':prior['source_game_tree'],'original_save_before':prior['original_save_before'],'native_red2_never_retried':True,'input_equals_recorded_pair2_clone':True,'complete':False,'cases':[]}
    def persist():dump(out/'green_continuation.json',state)
    def guards():
        for row in manifest:
            if not row['path'].endswith('.import') and row['path'] not in prior['candidate_files']:assert sha(project/row['path'])==row['sha256']
        for rel,digest in prior['candidate_files'].items():assert sha(project/rel)==digest
        assert (sha(save) if save.exists() else None)==prior['original_save_before']
    def run(label):
        target=out/label;target.mkdir();dump(target/'before.json',api['cache_state'](project))
        result=api['invoke'](target,'runner',['C:/Program Files/Git/bin/bash.exe','game/tools/run_tests.sh','m185_import_integrity'],project,env,900)
        dump(target/'after.json',api['cache_state'](project));guards()
        setup=int((target/'runner_logs/setup.exit.txt').read_text());suite=target/'runner_logs/test_m185_import_integrity.gd.exit.txt'
        suite_exit=int(suite.read_text()) if suite.exists() else None
        healthy=result['effective_exit_code']==0 and result['generic_error_count']==0 and not result['script_error_lines'] and not result['native_crash_signature'] and setup==0 and suite_exit==0 and result['suite_summary']==['1/1 suites passed']
        state['cases'].append({'label':label,'result':result,'setup_exit':setup,'suite_exit':suite_exit,'healthy':healthy});persist();assert healthy,'Green run failed; stop and retain'
    persist();run('green2_control')
    changes=0
    for row in manifest:
        if row['path'].endswith('.import'):
            raw=(original/row['path']).read_bytes();assert sha(original/row['path'])==row['sha256'] and b'\r\n' not in raw
            target=project/row['path'];before=target.read_bytes();assert before.replace(b'\r\n',b'\n')==raw
            changes+=before!=raw;target.write_bytes(raw)
    state['LF_restore_byte_changes']=changes;state['LF_restore_source']='Original verified LF blobs; equal to pinned green exports in stopped replay.';persist()
    run('green2_restore')
    # Verify the failed state is still fully retained, not warmed by this continuation.
    for rel,row in saved['red2'].items():
        path=(scratch/'red2'/rel) if rel.startswith('game/') else scratch/'profiles/red2'/rel.removeprefix('profile/')
        assert sha(path)==row['sha256']
    state['red2_postcrash_snapshot_unchanged']=True;state['original_save_unchanged']=True;state['complete']=True;persist()
    print('Green-only continuation clean; native failed state unchanged.',flush=True)


if __name__=='__main__':main()
