"""M1-85 mandatory current-source gate in an isolated frozen game copy."""
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
    ap.add_argument('--revision',required=True)
    args=ap.parse_args();root=args.root.resolve();scratch=args.scratch.resolve();out=Path(__file__).resolve().parent
    assert not scratch.exists() and not (out/'current_gate.json').exists(),'Refuse overwrite'
    common=Path(subprocess.check_output(['git','rev-parse','--git-common-dir'],cwd=root).decode().strip())
    if not common.is_absolute():common=(root/common).resolve()
    assert scratch.is_relative_to(common.parent/'.codex')
    api=runpy.run_path(str(out.parent/'cold_import_repro.py'));sha,dump=api['sha'],api['dump']
    revision=subprocess.check_output(['git','rev-parse',args.revision],cwd=root).decode().strip()
    inputs=api['frozen_inputs'](root,revision)
    assert shutil.disk_usage(common.parent).free>sum(r['bytes'] for r in inputs)+2*1024**3
    q="$ErrorActionPreference='Stop';$x=@(Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\");[pscustomobject]@{count=$x.Count}|ConvertTo-Json -Compress"
    assert json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-Command',q],text=True,timeout=30).lstrip('\ufeff'))['count']==0
    save=Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
    before_save=sha(save) if save.exists() else None
    dump(out/'current_source_manifest.json',[{k:r[k] for k in ['path','git_blob','sha256','bytes']} for r in inputs])
    scratch.mkdir();project=scratch/'project';api['materialize'](project,inputs)
    env=os.environ.copy()
    for key,sub in [('APPDATA','roaming'),('LOCALAPPDATA','local'),('TEMP','tmp'),('TMP','tmp'),('TMPDIR','tmp')]:
        target=scratch/'profile'/sub;target.mkdir(parents=True,exist_ok=True);env[key]=target.as_posix()
    env.update(GODOT=args.godot.resolve().as_posix(),SUITE_TIMEOUT='300',PLAYER_TEXT_TIMEOUT='1500',UPGRADE_PROFILE_TIMEOUT='10800')
    meta={'revision':revision,'game_tree':subprocess.check_output(['git','rev-parse',revision+':game'],cwd=root).decode().strip(),
          'collector_sha256':sha(Path(__file__)),'godot_sha256':sha(args.godot),'manifest_sha256':sha(out/'current_source_manifest.json'),
          'source_files':len(inputs),'source_bytes':sum(r['bytes'] for r in inputs),'scratch':str(scratch),'original_save_before':before_save,
          'scope':'Fresh project cache and isolated profile. Required runner setup retained; no asset/settings/cache bypass. OS filesystem caches not evicted.',
          'limits':{k:env[k] for k in ['SUITE_TIMEOUT','PLAYER_TEXT_TIMEOUT','UPGRADE_PROFILE_TIMEOUT']},'complete':False,'runs':[]}
    dump(out/'current_gate.json',meta)
    try:
        logs=scratch/'evidence';logs.mkdir()
        focused=api['invoke'](logs,'smoke_runner',[str(args.bash),'game/tools/run_tests.sh','m185_import_integrity'],project,env,900)
        meta['runs'].append({'kind':'focused','result':focused})
        shutil.copyfile(logs/'smoke_runner.txt',out/'current_smoke.txt')
        dump(out/'current_gate.json',meta)
        assert focused['effective_exit_code']==0 and focused['generic_error_count']==0 and not focused['script_error_lines'] and focused['suite_summary']==['1/1 suites passed'],'Focused import integrity failed'
        full=api['invoke'](logs,'runner',[str(args.bash),'game/tools/run_tests.sh'],project,env,14400)
        meta['runs'].append({'kind':'full','result':full})
        folder=out/'current_full';folder.mkdir()
        shutil.copyfile(logs/'runner.txt',folder/'runner.txt');shutil.copyfile(logs/'runner.json',folder/'runner.json')
        shutil.copyfile(logs/'runner.txt',out/'full_gate.txt')
        with zipfile.ZipFile(folder/'raw_logs.zip','w',compression=zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(logs.rglob('*')):
                if path.is_file():archive.write(path,path.relative_to(logs).as_posix())
        meta['raw_logs_sha256']=sha(folder/'raw_logs.zip')
        meta['complete']=True
    finally:
        meta['original_save_unchanged']=(sha(save) if save.exists() else None)==before_save
        meta['tracked_nonimport_source_changed']=[r['path'] for r in inputs if not r['path'].endswith('.import') and sha(project/r['path'])!=r['sha256']]
        meta['cache_after']=api['cache_state'](project)
        dump(out/'current_gate.json',meta)
    assert meta['original_save_unchanged'] and not meta['tracked_nonimport_source_changed']
    print('Current gate completed:',meta['runs'][-1]['result']['suite_summary'],flush=True)


if __name__=='__main__':main()
