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
          'limits':{k:env[k] for k in ['SUITE_TIMEOUT','PLAYER_TEXT_TIMEOUT','UPGRADE_PROFILE_TIMEOUT']},'complete':False,'full_pass':False,'runs':[]}
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
        meta['cache_after']=api['cache_state'](project)
        meta['full_pass']=bool(meta['full_pass'] and meta['original_save_unchanged'] and not meta['tracked_nonimport_source_changed'])
        dump(out/'current_gate.json',meta)
    print('Current gate collected; accepted:',meta['full_pass'],flush=True)
    raise SystemExit(0 if meta['full_pass'] else 1)


if __name__=='__main__':main()
