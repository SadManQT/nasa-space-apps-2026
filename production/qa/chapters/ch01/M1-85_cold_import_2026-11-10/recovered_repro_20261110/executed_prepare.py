"""M1-85: reconstruct recovered committed inputs and run bounded import diagnostics.
Only new ignored scratch copies are materialized. Existing source/cache/save data is read-only.
"""
import argparse
import hashlib
import json
import os
import re
import runpy
import shutil
import subprocess
import time
from pathlib import Path

PARENT = 'ed86d7bb596a93b8811f5c0849ae9078d65dc98a'
ORIGINAL = '046662cf278bd8b30ac5cbdcbbbafc08f00c61aa'
GAME_TREE = 'f59fcc7b080618dc5388cf84c56fd5938ced76ab'
LOG_SHA = 'effac2b310a27c472845d20f7175dfd4ec35052c5f912919ffa433cf190f43ac'


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024*1024), b''): h.update(chunk)
    return h.hexdigest()


def dump(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=True)+'\n', encoding='utf-8', newline='\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', type=Path, required=True)
    ap.add_argument('--scratch', type=Path, required=True)
    ap.add_argument('--godot', type=Path, required=True)
    ap.add_argument('--bash', type=Path, required=True)
    ap.add_argument('--prepare-only', action='store_true')
    ap.add_argument('--run-prepared', action='store_true')
    args = ap.parse_args()
    root, scratch, output = args.root.resolve(), args.scratch.resolve(), Path(__file__).resolve().parent
    assert scratch.is_relative_to(root.parents[2]) and '.codex' in scratch.parts
    assert args.godot.is_file() and args.bash.is_file()
    recovered = output.parent/'recovered_original_20261110'
    api_path = output.parent/'cold_import_repro.py'
    api = runpy.run_path(str(api_path))
    invoke = api['invoke']
    shim = output/'godot_log_shim.sh'
    def git(*parts, env=None):
        return subprocess.check_output(['git', *parts], cwd=root, env=env)
    if not args.run_prepared:
        assert not scratch.exists(), 'Refusing to overwrite retained scratch'
        scratch.mkdir(parents=True)
        assert sha(recovered/'original_setup_failure.txt') == LOG_SHA
        raw = (recovered/'original_setup_failure.txt').read_bytes()
        assert len(raw) == 198663
        cleaned = re.sub(r'\x1b\[[0-9;]*m', '', raw.decode('utf-8', errors='replace'))
        lines = cleaned.splitlines()
        analysis = {'original_raw_bytes': len(raw), 'sha256': LOG_SHA,
                    'native_setup_exit': 139, 'suites_executed': 0,
                    'engine_error_lines': [x for x in lines if re.match(r'^\s*ERROR:',x)],
                    'script_error_lines': [x for x in lines if re.search(r'SCRIPT ERROR|Parse Error',x)],
                    'native_signature_lines': lines[:2], 'last_lines': lines[-8:],
                    'backtrace_emitted': False,
                    'last_printed_import_is_not_cause': True,
                    'original_hardware_and_precrash_cache': 'Not supplied by the recovered log; no same-host/cache equivalence assumed.'}
        dump(output/'original_analysis.json', analysis)
        common = Path(git('rev-parse','--git-common-dir').decode().strip())
        if not common.is_absolute(): common = (root/common).resolve()
        objects = scratch/'objects'; objects.mkdir()
        env = os.environ.copy()
        env.update(GIT_INDEX_FILE=str(scratch/'reconstruction.index'),
                   GIT_OBJECT_DIRECTORY=str(objects), GIT_ALTERNATE_OBJECT_DIRECTORIES=str(common/'objects'))
        provenance = json.loads((recovered/'provenance.json').read_text(encoding='utf-8'))
        patch = recovered/'original_source.patch'
        assert sha(patch) == provenance['source_patch']['sha256']
        subprocess.run(['git','read-tree',PARENT], cwd=root, env=env, check=True)
        subprocess.run(['git','apply','--cached','--check',str(patch)], cwd=root, env=env, check=True)
        subprocess.run(['git','apply','--cached',str(patch)], cwd=root, env=env, check=True)
        tree = git('write-tree',env=env).decode().strip()
        game_tree = git('rev-parse',tree+':game',env=env).decode().strip()
        assert game_tree == GAME_TREE, (game_tree,GAME_TREE)
        previous = {k:os.environ.get(k) for k in ['GIT_INDEX_FILE','GIT_OBJECT_DIRECTORY','GIT_ALTERNATE_OBJECT_DIRECTORIES']}
        try:
            os.environ.update({k:env[k] for k in previous})
            inputs = api['frozen_inputs'](root,tree)
        finally:
            for key,value in previous.items():
                if value is None: os.environ.pop(key,None)
                else: os.environ[key] = value
        assert shutil.disk_usage(scratch).free > 3*sum(x['bytes'] for x in inputs)+3*1024**3
        api['materialize'](scratch/'a',inputs)
        manifest = [{k:row[k] for k in ['path','git_blob','sha256','bytes']} for row in inputs]
        dump(output/'source_manifest.json',manifest)
        reconstruction = {'expected_original_commit': ORIGINAL, 'parent': PARENT, 'root_tree': tree,
                          'game_tree': game_tree, 'expected_game_tree_matches': True,
                          'patch_sha256': sha(patch), 'files':len(inputs), 'bytes':sum(x['bytes'] for x in inputs),
                          'source_manifest_sha256':sha(output/'source_manifest.json'),
                          'object_store': str(objects), 'index':str(scratch/'reconstruction.index'),
                          'qualification': 'Reconstructed exact committed Game tree; no original pre-crash cache or original native stack. Local isolated objects/index only; main index/refs/source are untouched.'}
        dump(output/'reconstruction.json',reconstruction)
        print('Reconstructed exact original game tree',game_tree,len(inputs),'files',flush=True)
        if args.prepare_only: return
    else:
        reconstruction = json.loads((output/'reconstruction.json').read_text(encoding='utf-8'))
        assert reconstruction['game_tree'] == GAME_TREE and (scratch/'a/game/project.godot').is_file()
    manifest = json.loads((output/'source_manifest.json').read_text(encoding='utf-8'))
    assert all(sha(scratch/'a'/row['path']) == row['sha256'] for row in manifest)
    save = Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
    save_sha = sha(save) if save.exists() else None
    hw_command = [ 'powershell.exe','-NoProfile','-Command',
      "$ErrorActionPreference='Stop'; [pscustomobject]@{activeGodot=@(Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\" | Select-Object ProcessId,CreationDate,CommandLine);cpu=@(Get-CimInstance Win32_Processor|Select-Object Name);gpu=@(Get-CimInstance Win32_VideoController|Select-Object Name,DriverVersion);os=@(Get-CimInstance Win32_OperatingSystem|Select-Object Caption,Version,BuildNumber)}|ConvertTo-Json -Depth 5"]
    hardware = subprocess.run(hw_command,capture_output=True,text=True,timeout=30,check=True)
    hardware_data = json.loads(hardware.stdout.lstrip('\ufeff'))
    assert not hardware_data['activeGodot'], 'Another Godot process is active; do not overlap'
    dump(output/'environment.json',{'hardware':hardware_data, 'godot':str(args.godot),
        'godot_sha256':sha(args.godot), 'engine_version':subprocess.check_output([str(args.godot),'--version']).decode().strip(),
        'bash':str(args.bash), 'source_head':git('rev-parse','HEAD').decode().strip(),
        'collector_sha256':sha(Path(__file__)), 'invoke_helper_sha256':sha(api_path), 'logging_shim_sha256':sha(shim),
        'original_save_sha256':save_sha,'scratch':str(scratch),
        'scope':'Original unmodified runner, original committed Game inputs, same recorded4.7.2 version on this Arc host. Logging shim forwards unchanged Godot args/exit and retains discarded raw logs; timing/same-original-host/cache equivalence not claimed.'})
    def fresh_env(label,real=None):
        env = os.environ.copy()
        for key,sub in [('APPDATA','roaming'),('LOCALAPPDATA','local'),('TEMP','tmp'),('TMP','tmp'),('TMPDIR','tmp')]:
            folder=scratch/'profiles'/label/sub;folder.mkdir(parents=True,exist_ok=True);env[key]=folder.as_posix()
        env.update(GODOT=shim.as_posix(),LLA_REAL_GODOT=(real or args.godot).resolve().as_posix(),SUITE_TIMEOUT='300')
        return env
    def clean(result):
        return result['effective_exit_code']==0 and not result['generic_error_count'] and not result['script_error_lines'] and result['suite_summary']==['1/1 suites passed']
    # Exercise the original runner + logging shim against a harmless stub; these are not engine observations.
    self_root=scratch/'selfcheck';(self_root/'game/tools').mkdir(parents=True)
    shutil.copyfile(scratch/'a/game/tools/run_tests.sh',self_root/'game/tools/run_tests.sh')
    (self_root/'game/tools/test_hint_player.gd').write_text('stub - never parsed by an engine\n')
    fake=self_root/'fake_godot.sh'
    fake.write_text('#!/usr/bin/env bash\ncase " $* " in *" --editor "*) echo "ERROR: retained-selfcheck-sentinel";; *) echo "HINT PLAYER RESULT: PASS (1 checks, 0 failures)";; esac\nexit 0\n',newline='\n')
    self_out=self_root/'evidence';self_out.mkdir()
    stub=invoke(self_out,'runner',[str(args.bash),'game/tools/run_tests.sh','hint_player'],self_root,fresh_env('selfcheck',fake),30)
    assert stub['raw_exit_code']==0 and stub['suite_summary']==['1/1 suites passed']
    assert stub['generic_error_count']==1 and not clean(stub)
    dump(output/'collector_selfcheck.json',{'stub_not_a_game_run':True,'raw_exit':stub['raw_exit_code'],'runner_summary':stub['suite_summary'],
        'nested_error_retained':stub['generic_error_lines'],'classified_failure':not clean(stub),
        'raw_log_sha256':sha(self_out/'runner_logs/setup.log'),'shim_sha256':sha(shim)})
    state={'source_game_tree':GAME_TREE,'historical_native_crash_reproduced':False,'runs':[],
           'collection_complete':False,'all_runs_clean':False,'original_save_sha256':save_sha,
           'protocol':'Cold mandatory hint; unchanged warm; copied warm control; exact raw tracked-sidecar restore; unchanged retry in separate copy. Stop on native crash or unexpected control failure; retain every project.'}
    def persist(): dump(output/'execution.json',state)
    persist()
    def run_case(label,project):
        evidence=output/label;evidence.mkdir(exist_ok=False)
        api['dump'](evidence/'before.json',api['cache_state'](project))
        result=invoke(evidence,'runner',[str(args.bash),'game/tools/run_tests.sh','hint_player'],project,fresh_env(label),600)
        api['dump'](evidence/'after.json',api['cache_state'](project))
        changes=[]
        for row in manifest:
            actual=sha(project/row['path'])
            if actual!=row['sha256']:
                assert row['path'].endswith('.import'),'Non-import source changed: '+row['path']
                original=(scratch/'tracked_sidecars'/row['path'])
                changes.append({'path':row['path'],'before_sha256':row['sha256'],'after_sha256':actual})
        dump(evidence/'sidecar_changes.json',changes)
        assert (sha(save) if save.exists() else None)==save_sha, 'Original user save changed'
        state['runs'].append({'label':label,'project':str(project),'result':result,'clean':clean(result),'generated_import_changes':len(changes)})
        state['historical_native_crash_reproduced'] |= result['native_crash_signature']
        persist()
        return result
    # Preserve the exact tracked sidecar bytes separately before the first engine invocation.
    for row in manifest:
        if row['path'].endswith('.import'):
            target=scratch/'tracked_sidecars'/row['path'];target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(scratch/'a'/row['path'],target)
    a=scratch/'a';b=scratch/'b';c=scratch/'c'
    for label in ['cold','warm']:
        result=run_case(label,a)
        if not clean(result):
            state['stop_reason']='Unexpected cold/warm failure: project retained; no automatic retry';persist();return
    shutil.copytree(a/'game',b/'game')
    control=run_case('clone_control',b)
    if not clean(control): state['stop_reason']='Cloned warm control failed; no sidecar experiment';persist();return
    for row in manifest:
        if row['path'].endswith('.import'):shutil.copyfile(scratch/'tracked_sidecars'/row['path'],b/row['path'])
    restored=run_case('restored',b)
    if restored['native_crash_signature']:
        state['stop_reason']='Native crash: leave failing cache untouched before further diagnosis';persist();return
    shutil.copytree(b/'game',c/'game')
    run_case('retry',c)
    state['collection_complete']=True
    state['all_runs_clean']=all(row['clean'] for row in state['runs'])
    state['original_save_unchanged']=(sha(save) if save.exists() else None)==save_sha
    persist()
    print('Collection finished:',json.dumps({k:state[k] for k in ['collection_complete','historical_native_crash_reproduced','all_runs_clean','original_save_unchanged']}),flush=True)


if __name__=='__main__': main()
