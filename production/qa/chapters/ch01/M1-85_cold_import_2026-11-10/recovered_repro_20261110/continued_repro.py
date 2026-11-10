"""Continue only phase-qualified import comparisons after the preserved historical suite error.
All case-level engine errors remain failures. No production/historical Game file is repaired.
"""
import argparse
import hashlib
import json
import os
import runpy
import shutil
import subprocess
from pathlib import Path

AUDIO_ERROR = "ERROR: Resumed function '_stream()' after await, but class instance is gone. At script: res://scripts/audio/audio_director.gd:283"
GAME_TREE = 'f59fcc7b080618dc5388cf84c56fd5938ced76ab'


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root',type=Path,required=True)
    ap.add_argument('--scratch',type=Path,required=True)
    ap.add_argument('--godot',type=Path,required=True)
    ap.add_argument('--bash',type=Path,required=True)
    args=ap.parse_args();root=args.root.resolve();scratch=args.scratch.resolve();output=Path(__file__).resolve().parent
    assert scratch.is_relative_to(root.parents[2]) and '.codex' in scratch.parts
    assert not (output/'continuation.json').exists(), 'Refusing to overwrite continuation evidence'
    api_path=output.parent/'cold_import_repro.py';api=runpy.run_path(str(api_path));sha,dump,invoke=api['sha'],api['dump'],api['invoke']
    initial=json.loads((output/'execution.json').read_text(encoding='utf-8'))
    env_meta=json.loads((output/'environment.json').read_text(encoding='utf-8'))
    assert len(initial['runs'])==1 and initial['runs'][0]['label']=='cold' and not initial['collection_complete']
    assert initial['source_game_tree']==GAME_TREE and not initial['any_native_failure']
    assert sha(args.godot)==env_meta['godot_sha256'] and sha(api_path)==env_meta['invoke_helper_sha256']
    shim=output/'godot_log_shim.sh';assert sha(shim)==env_meta['logging_shim_sha256']
    manifest=json.loads((output/'source_manifest.json').read_text(encoding='utf-8'))
    save=Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
    save_sha=sha(save) if save.exists() else None;assert save_sha==initial['original_save_sha256']
    command="$ErrorActionPreference='Stop'; $p=@(Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\"); [pscustomobject]@{count=$p.Count;ids=@($p.ProcessId)}|ConvertTo-Json -Compress"
    active=json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-Command',command],text=True,timeout=30).lstrip('\ufeff'))
    assert active['count']==0, 'Another engine is active'
    def fresh_env(label):
        env=os.environ.copy()
        for key,sub in [('APPDATA','roaming'),('LOCALAPPDATA','local'),('TEMP','tmp'),('TMP','tmp'),('TMPDIR','tmp')]:
            folder=scratch/'profiles'/label/sub;folder.mkdir(parents=True,exist_ok=True);env[key]=folder.as_posix()
        env.update(GODOT=shim.as_posix(),LLA_REAL_GODOT=args.godot.resolve().as_posix(),SUITE_TIMEOUT='300')
        return env
    def classify(folder,result):
        logs=folder/'runner_logs';phase_exits={};forwarded={}
        expected={'setup':['--headless','--path','.','--editor','--quit'],
                  'test_hint_player.gd':['--headless','--path','.','--script','res://tools/test_hint_player.gd']}
        for phase in expected:
            file=logs/(phase+'.exit.txt');phase_exits[phase]=int(file.read_text().strip()) if file.exists() else None
            file=logs/(phase+'.args0')
            if file.exists():
                forwarded[phase]=[x.decode('utf-8') for x in file.read_bytes().split(b'\0')[:-1]]
                assert forwarded[phase]==expected[phase]
        setup=api['diagnostics'](logs/'setup.log')
        suite=api['diagnostics'](logs/'test_hint_player.gd.log') if (logs/'test_hint_player.gd.log').exists() else None
        any_native=result['native_crash_signature'] or any(x in {139,134,132,136,-1073741819,3221225477} for x in phase_exits.values())
        setup_clean=phase_exits['setup']==0 and not setup['engine_errors'] and not setup['script_errors']
        suite_text=(logs/'test_hint_player.gd.log').read_text(encoding='utf-8',errors='replace') if suite else ''
        assertion_pass=phase_exits['test_hint_player.gd']==0 and result['suite_summary']==['1/1 suites passed'] and 'HINT PLAYER RESULT: PASS (85 checks, 0 failures)' in suite_text
        known_only=suite is not None and not suite['script_errors'] and all(x==AUDIO_ERROR for x in suite['engine_errors'])
        eligible=setup_clean and assertion_pass and known_only and not any_native
        overall_clean=result['effective_exit_code']==0 and not result['generic_error_count'] and not result['script_error_lines'] and assertion_pass
        return {'phase_exit_codes':phase_exits,'forwarded_args':forwarded,'setup_engine_errors':len(setup['engine_errors']),
                'setup_script_errors':len(setup['script_errors']),'suite_engine_errors':len(suite['engine_errors']) if suite else None,
                'setup_clean':setup_clean,'import_control_eligible':eligible,'overall_clean':overall_clean,
                'any_native_failure':any_native,'same_setup_exit139_signature':phase_exits['setup']==139}
    cold=initial['runs'][0]['result'];cold_class=classify(output/'cold',cold)
    assert cold_class['import_control_eligible'] and not cold_class['overall_clean'] and cold['generic_error_lines']==[AUDIO_ERROR]
    dump(output/'continuation_selfcheck.json',{'actual_cold_case_not_a_stub':True,'classification':cold_class,
        'failure_stays_failed':not cold_class['overall_clean'],'phase_qualified_only':True,
        'unexpected_suite_error_would_block_controls':True,'allowed_historical_suite_error':AUDIO_ERROR})
    def snapshot(project,profile):
        paths=[p for p in (project/'game/.godot').rglob('*') if p.is_file()]
        paths += [p for p in (project/'game').rglob('*') if p.is_file() and p.suffix in {'.import','.uid'} and '.godot' not in p.parts]
        rows=[{'file':p.relative_to(project).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(set(paths))]
        if profile.exists():
            rows += [{'file':'profile/'+p.relative_to(profile).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(profile.rglob('*')) if p.is_file()]
        return rows
    a,b,c=[scratch/x for x in ['a','b','c']]
    assert a.is_dir() and not b.exists() and not c.exists()
    retained={'a_after_failed_cold':snapshot(a,scratch/'profiles/a')};dump(output/'retained_inputs.json',retained)
    state={'source_game_tree':GAME_TREE,'collector_sha256':sha(Path(__file__)),'invoke_helper_sha256':sha(api_path),
           'shim_sha256':sha(shim),'runs':[],'complete':False,'any_native_failure':False,'same_setup_exit139_signature_observed':False,
           'all_cases_overall_clean':False,'allowlisted_historical_suite_error':AUDIO_ERROR,
           'qualification':'Original cold case remains failed and untouched. Warm is an a-to-b copied-state control, next clone_control name means repeat/pre-restore control on sameb/profileb. Only setup-stage import health gates this experiment, with suite assertions85/0 and no unexpected suite errors; every engine error remains an overall failure. Retry uses copiedb Game/profile inc at changed absolute paths; not an original-cache/same-path replay.'}
    def persist():dump(output/'continuation.json',state)
    persist()
    shutil.copytree(a/'game',b/'game');shutil.copytree(scratch/'profiles/a',scratch/'profiles/b')
    def run_case(label,project):
        folder=output/label;folder.mkdir(exist_ok=False)
        dump(folder/'before.json',api['cache_state'](project))
        result=invoke(folder,'runner',[str(args.bash),'game/tools/run_tests.sh','hint_player'],project,fresh_env(project.name),600)
        result.update(classify(folder,result));dump(folder/'runner.json',result)
        dump(folder/'after.json',api['cache_state'](project))
        changes=[]
        for row in manifest:
            actual=sha(project/row['path'])
            if actual!=row['sha256']:
                assert row['path'].endswith('.import'), 'Historical source changed outside import sidecars'
                changes.append({'path':row['path'],'before_sha256':row['sha256'],'after_sha256':actual})
        dump(folder/'sidecar_changes.json',changes)
        assert (sha(save) if save.exists() else None)==save_sha
        state['runs'].append({'label':label,'project':str(project),'result':result,'generated_import_changes':len(changes)})
        state['any_native_failure'] |= result['any_native_failure']
        state['same_setup_exit139_signature_observed'] |= result['same_setup_exit139_signature']
        persist();return result
    for label in ['warm','clone_control']:
        result=run_case(label,b)
        if not result['import_control_eligible']:
            state['stop_reason']='New control failure; preserve all projects and stop before restoration';persist();return
    changed=[];semantic=[]
    for row in manifest:
        if row['path'].endswith('.import'):
            before=(b/row['path']).read_bytes();original=(scratch/'tracked_sidecars'/row['path']).read_bytes()
            if before!=original:changed.append(row['path'])
            if before.replace(b'\r\n',b'\n')!=original.replace(b'\r\n',b'\n'):semantic.append(row['path'])
            shutil.copyfile(scratch/'tracked_sidecars'/row['path'],b/row['path'])
    state['restoration']={'tracked_sidecars':sum(x['path'].endswith('.import') for x in manifest),'byte_differences':len(changed),
                          'non_crlf_differences':semantic,'method':'Exact committed raw bytes, not claimed identical to original Git checkout filters or original pre-crash cache.'};persist()
    result=run_case('restored',b)
    retained['b_after_restoration']=snapshot(b,scratch/'profiles/b');dump(output/'retained_inputs.json',retained)
    if result['any_native_failure']:
        state['stop_reason']='Native failure; preserveb untouched before further diagnosis';persist();return
    shutil.copytree(b/'game',c/'game');shutil.copytree(scratch/'profiles/b',scratch/'profiles/c')
    run_case('retry',c)
    assert snapshot(a,scratch/'profiles/a')==retained['a_after_failed_cold'],'Initial failed state changed'
    assert snapshot(b,scratch/'profiles/b')==retained['b_after_restoration'],'Restoration state changed during copied retry'
    state['retained_a_and_b_hashes_still_match']=True
    state['original_save_unchanged']=(sha(save) if save.exists() else None)==save_sha
    state['complete']=True
    state['all_cases_overall_clean']=cold_class['overall_clean'] and all(x['result']['overall_clean'] for x in state['runs'])
    persist();print('Continuation finished:',json.dumps({k:state[k] for k in ['complete','any_native_failure','same_setup_exit139_signature_observed','all_cases_overall_clean','original_save_unchanged']}),flush=True)


if __name__=='__main__':main()
