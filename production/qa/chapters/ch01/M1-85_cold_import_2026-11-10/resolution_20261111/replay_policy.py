"""M1-85 paired checkout-policy proof using retained original-source warm inputs.
No production asset/settings/cache/save mutation; all generated projects remain local.
"""
import argparse
import hashlib
import json
import os
import re
import runpy
import shutil
import subprocess
from pathlib import Path


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--root',type=Path,required=True);ap.add_argument('--scratch',type=Path,required=True)
    ap.add_argument('--godot',type=Path,required=True);ap.add_argument('--bash',type=Path,required=True);args=ap.parse_args()
    root=args.root.resolve();scratch=args.scratch.resolve();out=Path(__file__).resolve().parent;old=out.parent/'recovered_repro_20261110'
    assert not scratch.exists() and not (out/'run.json').exists(),'Refuse evidence overwrite'
    common=Path(subprocess.check_output(['git','rev-parse','--git-common-dir'],cwd=root).decode().strip())
    if not common.is_absolute():common=(root/common).resolve()
    assert scratch.is_relative_to(common.parent/'.codex')
    api=runpy.run_path(str(out.parent/'cold_import_repro.py'));sha,dump,invoke=api['sha'],api['dump'],api['invoke']
    old_env=json.loads((old/'environment.json').read_text(encoding='utf-8'));rec=json.loads((old/'reconstruction.json').read_text(encoding='utf-8'))
    source=Path(old_env['scratch'])/'b';profile=Path(old_env['scratch'])/'profiles/b'
    assert sha(args.godot)==old_env['godot_sha256']
    manifest=json.loads((old/'source_manifest.json').read_text(encoding='utf-8'))
    for row in manifest:
        assert sha(source/row['path'])==row['sha256'],'Original-source baseline changed'
    q="$ErrorActionPreference='Stop';$x=@(Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\");[pscustomobject]@{count=$x.Count}|ConvertTo-Json -Compress"
    assert json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-Command',q],text=True,timeout=30).lstrip('\ufeff'))['count']==0
    save=Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json';save_before=sha(save) if save.exists() else None
    scratch.mkdir(parents=True);contexts={};git_base=os.environ.copy();git_base['GIT_DIR']=subprocess.check_output(['git','rev-parse','--absolute-git-dir'],cwd=root).decode().strip()
    git_base.update(GIT_INDEX_FILE=rec['index'],GIT_OBJECT_DIRECTORY=rec['object_store'],GIT_ALTERNATE_OBJECT_DIRECTORIES=str(common/'objects'))
    root_attrs=subprocess.check_output(['git','show',rec['root_tree']+':.gitattributes'],cwd=root,env=git_base)
    for role in ['red','green']:
        folder=scratch/'attributes'/role;(folder/'game').mkdir(parents=True);(folder/'.gitattributes').write_bytes(root_attrs)
        if role=='green':shutil.copyfile(root/'game/.gitattributes',folder/'game/.gitattributes')
        env=git_base.copy();env['GIT_WORK_TREE']=str(folder);contexts[role]=env
    sidecars=[row for row in manifest if row['path'].endswith('.import')]
    query=b'\0'.join(row['path'].encode() for row in sidecars)+b'\0'
    attrs={role:subprocess.check_output(['git','check-attr','--all','-z','--stdin'],cwd=Path(env['GIT_WORK_TREE']),env=env,input=query) for role,env in contexts.items()}
    assert attrs['red']==b'' and attrs['green'].count(b'eol\0lf\0')==len(sidecars)
    exported={role:{} for role in contexts}
    for role,env in contexts.items():
        print('Export',role,'pinned metadata context',flush=True)
        for row in sidecars:
            exported[role][row['path']]=subprocess.check_output(['git','-c','core.autocrlf=true','cat-file','--filters',rec['root_tree']+':'+row['path']],cwd=Path(env['GIT_WORK_TREE']),env=env)
    assert all(exported['red'][r['path']].replace(b'\r\n',b'\n')==exported['green'][r['path']] for r in sidecars)
    assert sum(exported['red'][r['path']]!=exported['green'][r['path']] for r in sidecars)==960
    overrides=['game/.gitattributes','game/tools/run_tests.sh','game/tools/test_m185_import_integrity.gd','game/tools/test_m185_import_integrity.gd.uid']
    state={'source_game_tree':rec['game_tree'],'code_sha256':sha(Path(__file__)),'helper_sha256':sha(out.parent/'cold_import_repro.py'),
           'godot_sha256':sha(args.godot),'candidate_files':{p:sha(root/p) for p in overrides},'original_save_before':save_before,
           'protocol':'Two independently prepared warm baselines. Each red/green pair is byte-identical at cloning including cache/profile; post-clone controls use their own stable paths. Only pinned checkout conversion differs. No intentional cache deletion or source asset/renderer/project-setting modification.',
           'attributes':{'red':'Original root attributes, no Game rule','green':'Original root plus candidate Game LF rule','per_command_autocrlf':True},'cases':[],'pairs':[],'complete':False}
    def persist():dump(out/'run.json',state)
    persist()
    def env_for(name):
        env=os.environ.copy()
        for key,sub in [('APPDATA','roaming'),('LOCALAPPDATA','local'),('TEMP','tmp'),('TMP','tmp'),('TMPDIR','tmp')]:
            folder=scratch/'profiles'/name/sub;folder.mkdir(parents=True,exist_ok=True);env[key]=folder.as_posix()
        env.update(GODOT=args.godot.resolve().as_posix(),SUITE_TIMEOUT='300');return env
    def snapshot(project,name):
        result={}
        for folder,prefix in [(project/'game','game/'),(scratch/'profiles'/name,'profile/')]:
            for path in sorted(folder.rglob('*')):
                if path.is_file():result[prefix+path.relative_to(folder).as_posix()]=sha(path)
        return result
    def check_source(project):
        for row in manifest:
            if row['path'] not in overrides and not row['path'].endswith('.import'):assert sha(project/row['path'])==row['sha256'],row['path']
        for name in overrides:assert sha(project/name)==state['candidate_files'][name]
        assert (sha(save) if save.exists() else None)==save_before
    def run(label,project):
        folder=out/label;folder.mkdir(exist_ok=False);dump(folder/'before.json',api['cache_state'](project))
        result=invoke(folder,'runner',[str(args.bash),'game/tools/run_tests.sh','m185_import_integrity'],project,env_for(project.name),900)
        dump(folder/'after.json',api['cache_state'](project));check_source(project)
        logs=folder/'runner_logs';setup_exit=int((logs/'setup.exit.txt').read_text().strip());suite_file=logs/'test_m185_import_integrity.gd.exit.txt'
        suite_exit=int(suite_file.read_text().strip()) if suite_file.exists() else None
        setup=api['diagnostics'](logs/'setup.log');suite_log=logs/'test_m185_import_integrity.gd.log'
        suite=api['diagnostics'](suite_log) if suite_log.exists() else None
        healthy=result['effective_exit_code']==0 and result['generic_error_count']==0 and not result['script_error_lines'] and result['suite_summary']==['1/1 suites passed'] and setup_exit==0 and suite_exit==0
        item={'label':label,'result':result,'setup_exit':setup_exit,'suite_exit':suite_exit,'setup_errors':setup['engine_errors'],
              'suite_errors':suite['engine_errors'] if suite else [],'healthy':healthy,'reimport_steps':sum('reimport |' in line for line in re.sub(r'\x1b\[[0-9;]*m','',(logs/'setup.log').read_text(encoding='utf-8',errors='replace')).splitlines())}
        state['cases'].append(item);persist();return item
    for pair in [1,2]:
        baseline=scratch/('baseline'+str(pair));shutil.copytree(source/'game',baseline/'game');shutil.copytree(profile,scratch/'profiles'/baseline.name)
        for name in overrides:
            target=baseline/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/name,target)
        warm=run('baseline'+str(pair),baseline);assert warm['healthy'],'Baseline failed; keep all state, stop'
        frozen=snapshot(baseline,baseline.name);pair_meta={'index':pair,'cloned_input_sha256':hashlib.sha256(json.dumps(frozen,sort_keys=True).encode()).hexdigest(),'files':len(frozen),'roles':{}}
        for role in ['red','green']:
            name=role+str(pair);project=scratch/name;shutil.copytree(baseline/'game',project/'game');shutil.copytree(scratch/'profiles'/baseline.name,scratch/'profiles'/name)
            assert snapshot(project,name)==frozen,'Pair input differs before control'
            pair_meta['roles'][role]={'project':str(project),'cloned_input_matches':True}
        state['pairs'].append(pair_meta);persist()
        for role in ['red','green']:
            name=role+str(pair);project=scratch/name
            control=run(name+'_control',project);assert control['healthy'],'Control failed; no restoration attribution'
            changes=[]
            for row in sidecars:
                before=(project/row['path']).read_bytes();after=exported[role][row['path']]
                if before!=after:changes.append(row['path'])
                assert before.replace(b'\r\n',b'\n')==after.replace(b'\r\n',b'\n'),'Semantic metadata change'
                (project/row['path']).write_bytes(after)
            pair_meta['roles'][role]['sidecar_byte_changes']=len(changes);persist()
            case=run(name+'_restore',project)
            if role=='green':assert case['healthy'],'LF candidate did not preserve clean import'
            if case['result']['native_crash_signature']:
                state['native_failure_preserved']=str(project);persist();raise RuntimeError('Native failure retained; inspect before further runs')
    state['complete']=True;state['original_save_unchanged']=(sha(save) if save.exists() else None)==save_before
    state['red_failures']=sum(not c['healthy'] for c in state['cases'] if c['label'].startswith('red') and c['label'].endswith('_restore'))
    state['green_passes']=sum(c['healthy'] for c in state['cases'] if c['label'].startswith('green') and c['label'].endswith('_restore'))
    persist();print('Pair replay complete:',json.dumps({k:state[k] for k in ['red_failures','green_passes','original_save_unchanged']}),flush=True)


if __name__=='__main__':main()
