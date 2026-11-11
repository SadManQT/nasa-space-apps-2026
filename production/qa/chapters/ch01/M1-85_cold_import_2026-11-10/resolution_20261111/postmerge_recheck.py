"""M1-85 mandatory recheck of the sole merged export-hook change; no export/build."""
import argparse
import json
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import zipfile


def main():
    ap=argparse.ArgumentParser()
    for name in ['root','scratch','godot','bash']:ap.add_argument('--'+name,type=Path,required=True)
    args=ap.parse_args();root=args.root.resolve();scratch=args.scratch.resolve();base=Path(__file__).resolve().parent;out=base/'postmerge';out.mkdir(exist_ok=True)
    assert not scratch.exists() and not (out/'run.json').exists(),'Refuse overwrite'
    api=runpy.run_path(str(base.parent/'cold_import_repro.py'));sha,dump=api['sha'],api['dump']
    common=Path(subprocess.check_output(['git','rev-parse','--git-common-dir'],cwd=root).decode().strip())
    if not common.is_absolute():common=(root/common).resolve()
    assert scratch.is_relative_to(common.parent/'.codex')
    old=json.loads((base/'current_complete/current_gate.json').read_text());assert old['qualified_warm_full_pass']
    previous=json.loads((base/'current_complete/current_source_manifest.json').read_text());old_map={r['path']:r for r in previous}
    revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root).decode().strip();inputs=api['frozen_inputs'](root,revision);current={r['path']:r for r in inputs}
    changed=sorted(p for p in set(old_map)|set(current) if p not in old_map or p not in current or old_map[p]['sha256']!=current[p]['sha256'])
    assert changed==['game/addons/runtime_assets/plugin.gd'],'New Game changes need explicit source/acceptance review: '+str(changed)
    assert sha(args.godot)==old['godot_sha256']
    q="$ErrorActionPreference='Stop';$x=@(Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\");[pscustomobject]@{count=$x.Count}|ConvertTo-Json -Compress"
    assert json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-Command',q],text=True,timeout=30).lstrip('\ufeff'))['count']==0
    original=Path(old['scratch']);before_cache=api['cache_state'](original/'project');plugin='game/addons/runtime_assets/plugin.gd'
    assert sha(original/'project'/plugin)==old_map[plugin]['sha256']
    assert shutil.disk_usage(common.parent).free>old['source_bytes']+2*1024**3
    scratch.mkdir();project=scratch/'project';shutil.copytree(original/'project',project);shutil.copytree(original/'profile',scratch/'profile')
    (project/plugin).write_bytes(current[plugin]['raw'])
    norm=old['editor_normalization'];assert current['game/project.godot']['sha256']==norm['original_project_sha256']
    support=json.loads((base/'current_complete/support_manifest.json').read_text())
    for row in support:
        raw=subprocess.check_output(['git','show',revision+':'+row['path']],cwd=root)
        assert sha(project/row['path'])==row['sha256'] and raw==(project/row['path']).read_bytes(),'Support dependency changed; review new input'
    dump(out/'source_manifest.json',[{k:r[k] for k in ['path','git_blob','sha256','bytes']} for r in inputs])
    save=Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json';before_save=sha(save) if save.exists() else None
    env=os.environ.copy()
    for key,sub in [('APPDATA','roaming'),('LOCALAPPDATA','local'),('TEMP','tmp'),('TMP','tmp'),('TMPDIR','tmp')]:env[key]=(scratch/'profile'/sub).as_posix()
    env.update(GODOT=args.godot.resolve().as_posix(),SUITE_TIMEOUT='300')
    meta={'revision':revision,'game_tree':subprocess.check_output(['git','rev-parse',revision+':game'],cwd=root).decode().strip(),'collector_sha256':sha(Path(__file__)),'source_manifest_sha256':sha(out/'source_manifest.json'),'base_full_record_sha256':sha(base/'current_complete/current_gate.json'),'base_revision':old['revision'],'scratch':str(scratch),'original_full_scratch':str(original),'changed_Game_paths':changed,'godot_sha256':sha(args.godot),'binary_hash_scope':'Console launcher hash in earlier records; companion measured here before merged-source recheck, not retroactively pinned for earlier crash. Faulting image unknown.','engine_binaries':{kind:{'path':str(path),'sha256':sha(path),'bytes':path.stat().st_size,'mtime_ns':path.stat().st_mtime_ns} for kind,path in [('console',args.godot),('companion',args.godot.with_name(args.godot.name.replace('_console.exe','.exe')))]},'editor_normalization':norm,'scope':'New copy of accepted full-run project/cache/profile. Only current Git export plugin overlaid; its changed callbacks run during export, not the headless campaign gate. Mandatory editor refresh/font probe still run. No release export/build or cold qualification.','complete':False,'accepted':False}
    dump(out/'run.json',meta)
    evidence=scratch/'evidence';evidence.mkdir()
    try:
        result=api['invoke'](evidence,'runner',[str(args.bash),'game/tools/run_tests.sh','m185_import_integrity'],project,env,900)
        meta['result']=result
        meta['tracked_nonimport_source_changed']=[r['path'] for r in inputs if not r['path'].endswith('.import') and sha(project/r['path'])!=(norm['editor_project_sha256'] if r['path']=='game/project.godot' else r['sha256'])]
        meta['support_unchanged']=all(sha(project/r['path'])==r['sha256'] for r in support)
        meta['original_full_selected_cache_before']=before_cache
        meta['original_full_selected_cache_after']=api['cache_state'](original/'project')
        meta['original_full_selected_cache_unchanged']=meta['original_full_selected_cache_after']==before_cache and sha(original/'project'/plugin)==old_map[plugin]['sha256']
        meta['original_save_unchanged']=(sha(save) if save.exists() else None)==before_save
        meta['setup_exit']=int((evidence/'runner_logs/setup.exit.txt').read_text());suite=evidence/'runner_logs/test_m185_import_integrity.gd.exit.txt';meta['suite_exit']=int(suite.read_text()) if suite.exists() else None
        meta['accepted']=result['effective_exit_code']==0 and result['generic_error_count']==0 and not result['script_error_lines'] and not result['native_crash_signature'] and result['suite_summary']==['1/1 suites passed'] and meta['setup_exit']==0 and meta['suite_exit']==0 and not meta['tracked_nonimport_source_changed'] and meta['support_unchanged'] and meta['original_full_selected_cache_unchanged'] and meta['original_save_unchanged']
        meta['complete']=True
    finally:
        for name in ['runner.txt','runner.json']:
            if (evidence/name).exists():shutil.copyfile(evidence/name,out/name)
        with zipfile.ZipFile(out/'raw_logs.zip','w',compression=zipfile.ZIP_DEFLATED) as z:
            for path in sorted(evidence.rglob('*')):
                if path.is_file():z.write(path,path.relative_to(evidence).as_posix())
        meta['raw_logs_sha256']=sha(out/'raw_logs.zip');dump(out/'run.json',meta)
    print('Merged mandatory check accepted:',meta['accepted'],flush=True)
    raise SystemExit(0 if meta['accepted'] else 1)


if __name__=='__main__':main()
