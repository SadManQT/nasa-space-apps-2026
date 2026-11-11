"""M1-85 separate warm-copy current gate; original cold failure remains failed."""
import argparse
import json
import difflib
import re
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import zipfile


def main():
    ap=argparse.ArgumentParser()
    for name in ['root','scratch','godot','bash']:ap.add_argument('--'+name,type=Path,required=True)
    ap.add_argument('--revision',required=True)
    args=ap.parse_args();root=args.root.resolve();scratch=args.scratch.resolve();base=Path(__file__).resolve().parent;out=base/'current_warm';out.mkdir(exist_ok=True)
    assert not scratch.exists() and not (out/'current_gate.json').exists(),'Refuse overwrite'
    common=Path(subprocess.check_output(['git','rev-parse','--git-common-dir'],cwd=root).decode().strip())
    if not common.is_absolute():common=(root/common).resolve()
    assert scratch.is_relative_to(common.parent/'.codex')
    api=runpy.run_path(str(base.parent/'cold_import_repro.py'));sha,dump=api['sha'],api['dump']
    revision=subprocess.check_output(['git','rev-parse',args.revision],cwd=root).decode().strip()
    inputs=api['frozen_inputs'](root,revision)
    assert shutil.disk_usage(common.parent).free>sum(r['bytes'] for r in inputs)+2*1024**3
    q="$ErrorActionPreference='Stop';$x=@(Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\");[pscustomobject]@{count=$x.Count}|ConvertTo-Json -Compress"
    assert json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-Command',q],text=True,timeout=30).lstrip('\ufeff'))['count']==0
    save=Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
    before_save=sha(save) if save.exists() else None
    dump(out/'current_source_manifest.json',[{k:r[k] for k in ['path','git_blob','sha256','bytes']} for r in inputs])
    cold=json.loads((base/'current_gate.json').read_text())
    assert not cold['full_pass'] and cold['original_save_unchanged'] and cold['tracked_nonimport_source_changed']==['game/project.godot']
    assert revision==cold['revision'] and sha(args.godot)==cold['godot_sha256']
    failed=Path(cold['scratch']);snapshot={}
    original_project=next(r['raw'] for r in inputs if r['path']=='game/project.godot')
    normalized_project=(failed/'project/game/project.godot').read_bytes()
    def settings(raw):
        result={};section='';key=None;value=[]
        def flush():
            if key is not None:
                assert key not in result
                result[key]='\n'.join(value).strip()
        for line in raw.decode().splitlines():
            text=line.strip()
            if re.fullmatch(r'\[[A-Za-z0-9_/]+\]',text):
                flush();section=text[1:-1];key=None;value=[]
            else:
                match=re.fullmatch(r'([A-Za-z0-9_./-]+)=(.*)',text)
                if match:
                    flush();key=section+'/'+match.group(1);value=[match.group(2)]
                elif key is not None:value.append(line)
                else:assert not text or text.startswith(';')
        flush();return result
    before_cfg=settings(original_project);after_cfg=settings(normalized_project)
    removed='rendering/renderer/rendering_method.web'
    assert set(before_cfg)-set(after_cfg)=={removed} and not set(after_cfg)-set(before_cfg)
    assert before_cfg[removed]=='"gl_compatibility"' and all(before_cfg[k]==v for k,v in after_cfg.items())
    normalized_sha=sha(failed/'project/game/project.godot')
    normalization={'original_project_sha256':next(r['sha256'] for r in inputs if r['path']=='game/project.godot'),'editor_project_sha256':normalized_sha,'only_removed_setting':removed,'removed_value':'gl_compatibility','all_other_setting_values_equal':True,'default_equivalence_source':'https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp#L2483','local_autosave_call':'game/addons/gohud/plugin.gd:57,77; _enter_tree declares fields and saves ProjectSettings','diff':''.join(difflib.unified_diff(original_project.decode().splitlines(True),normalized_project.decode().splitlines(True))),'qualification':'Exact recorded editor auto-save normalization in isolated copy; not byte-identical project.godot. No authored settings change.'}
    for folder,prefix in [(failed/'project/game','game/'),(failed/'profile','profile/')]:
        for path in sorted(folder.rglob('*')):
            if path.is_file():
                st=path.stat();snapshot[prefix+path.relative_to(folder).as_posix()]={'sha256':sha(path),'bytes':st.st_size,'mtime_ns':st.st_mtime_ns}
    assert not (base/'current_cold_inputs.json').exists(),'Refuse input snapshot overwrite'
    dump(base/'current_cold_inputs.json',snapshot)
    scratch.mkdir();project=scratch/'project'
    shutil.copytree(failed/'project/game',project/'game');shutil.copytree(failed/'profile',scratch/'profile')
    for rel,row in snapshot.items():
        path=project/rel if rel.startswith('game/') else scratch/'profile'/rel.removeprefix('profile/')
        assert sha(path)==row['sha256'],'Copied failed-state input differs'
    dump(out/'input_capture.json',{'failed_cold_record_sha256':sha(base/'current_gate.json'),'failed_input_manifest_sha256':sha(base/'current_cold_inputs.json'),'files':len(snapshot),'bytes':sum(r['bytes'] for r in snapshot.values()),'copy_matches':True,'editor_normalization':normalization,'original_failed_state':str(failed),'warm_copy':str(scratch),'limitation':'Copied post-import failed cold state at a new project/profile absolute path. Original cold remains FAILED; never retry its preserved project.'})
    env=os.environ.copy()
    for key,sub in [('APPDATA','roaming'),('LOCALAPPDATA','local'),('TEMP','tmp'),('TMP','tmp'),('TMPDIR','tmp')]:
        target=scratch/'profile'/sub;target.mkdir(parents=True,exist_ok=True);env[key]=target.as_posix()
    env.update(GODOT=args.godot.resolve().as_posix(),SUITE_TIMEOUT='300',PLAYER_TEXT_TIMEOUT='1500',UPGRADE_PROFILE_TIMEOUT='10800')
    meta={'revision':revision,'game_tree':subprocess.check_output(['git','rev-parse',revision+':game'],cwd=root).decode().strip(),
          'collector_sha256':sha(Path(__file__)),'godot_sha256':sha(args.godot),'manifest_sha256':sha(out/'current_source_manifest.json'),
          'source_files':len(inputs),'source_bytes':sum(r['bytes'] for r in inputs),'scratch':str(scratch),'original_save_before':before_save,
          'scope':'Warm copy of preserved failed current cold-import state at a new project/profile path. Required setup retained. Original cold remains FAILED; exact recorded editor auto-save normalization is disclosed, all other nonimport source stays exact. No authored settings/cache bypass or cold qualification.',
          'limits':{k:env[k] for k in ['SUITE_TIMEOUT','PLAYER_TEXT_TIMEOUT','UPGRADE_PROFILE_TIMEOUT']},'complete':False,'full_pass':False,'runs':[],'editor_normalization':normalization}
    dump(out/'current_gate.json',meta)
    logs=scratch/'evidence';logs.mkdir()
    try:
        focused=api['invoke'](logs,'smoke_runner',[str(args.bash),'game/tools/run_tests.sh','m185_import_integrity'],project,env,900)
        meta['runs'].append({'kind':'focused','result':focused})
        shutil.copyfile(logs/'smoke_runner.txt',out/'current_smoke.txt')
        dump(out/'current_gate.json',meta)
        assert focused['effective_exit_code']==0 and focused['generic_error_count']==0 and not focused['script_error_lines'] and focused['suite_summary']==['1/1 suites passed'],'Focused import integrity failed'
        full=api['invoke'](logs,'runner',[str(args.bash),'game/tools/run_tests.sh'],project,env,14400)
        meta['runs'].append({'kind':'full','result':full})
        expected=sorted(Path(r['path']).name for r in inputs if Path(r['path']).parent.as_posix()=='game/tools' and Path(r['path']).name.startswith('test_') and r['path'].endswith('.gd'))
        phase=logs/'runner_logs'
        exits={p.name.removesuffix('.exit.txt'):int(p.read_text().strip()) for p in phase.glob('*.exit.txt')}
        raw_suites=sorted(p.name.removesuffix('.log') for p in phase.glob('test_*.gd.log'))
        verdicts=[]
        for line in (logs/'runner.txt').read_text(encoding='utf-8',errors='replace').splitlines():
            if line.startswith(('ok   tools/','FAIL tools/')):verdicts.append(line.split('tools/',1)[1].split(' ::',1)[0])
        meta['coverage']={'expected':expected,'raw_suites':raw_suites,'verdicts':sorted(verdicts),'phase_exits':exits}
        meta['full_pass']=(full['effective_exit_code']==0 and not full['script_error_lines'] and not full['native_crash_signature']
            and full['suite_summary']==[f'{len(expected)}/{len(expected)} suites passed']
            and raw_suites==expected and sorted(verdicts)==expected and sorted(exits)==['setup']+expected
            and all(v==0 for v in exits.values()) and not api['diagnostics'](phase/'setup.log')['engine_errors'])
        meta['complete']=True
    finally:
        folder=out/'current_full';folder.mkdir(exist_ok=True)
        for name in ['runner.txt','runner.json']:
            if (logs/name).exists():shutil.copyfile(logs/name,folder/name)
        if (logs/'runner.txt').exists():shutil.copyfile(logs/'runner.txt',out/'full_gate.txt')
        with zipfile.ZipFile(folder/'raw_logs.zip','w',compression=zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(logs.rglob('*')):
                if path.is_file():archive.write(path,path.relative_to(logs).as_posix())
        meta['raw_logs_sha256']=sha(folder/'raw_logs.zip')
        meta['original_save_unchanged']=(sha(save) if save.exists() else None)==before_save
        meta['tracked_nonimport_source_changed']=[r['path'] for r in inputs if not r['path'].endswith('.import') and (not (project/r['path']).is_file() or sha(project/r['path'])!=r['sha256'])]
        meta['unexpected_tracked_source_changed']=[name for name in meta['tracked_nonimport_source_changed'] if name!='game/project.godot']
        meta['recorded_editor_normalization_unchanged']=sha(project/'game/project.godot')==normalized_sha
        original_now={}
        for folder,prefix in [(failed/'project/game','game/'),(failed/'profile','profile/')]:
            for path in sorted(folder.rglob('*')):
                if path.is_file():original_now[prefix+path.relative_to(folder).as_posix()]=sha(path)
        meta['original_failed_snapshot_unchanged']=original_now=={k:v['sha256'] for k,v in snapshot.items()}
        meta['cache_after']=api['cache_state'](project)
        meta['full_pass']=bool(meta['full_pass'] and meta['original_save_unchanged'] and not meta['unexpected_tracked_source_changed'] and meta['recorded_editor_normalization_unchanged'] and meta['original_failed_snapshot_unchanged'])
        meta['qualified_warm_full_pass']=meta['full_pass']
        dump(out/'current_gate.json',meta)
    print('Current gate collected; accepted:',meta['full_pass'],flush=True)
    raise SystemExit(0 if meta['full_pass'] else 1)


if __name__=='__main__':main()
