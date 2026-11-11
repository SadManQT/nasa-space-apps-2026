"""Read-only, post-crash native-state preservation; does not launch Godot."""
import hashlib
import json
import os
from pathlib import Path
import runpy
import subprocess
import time


def main():
    out=Path(__file__).resolve().parent;root=out.parents[6]
    api=runpy.run_path(str(out.parent/'cold_import_repro.py'));sha,dump=api['sha'],api['dump']
    run=json.loads((out/'run.json').read_text());failed=next(c for c in run['cases'] if c['label']=='red2_restore')
    scratch=Path(run['native_failure_preserved']).parent
    assert not (out/'native_capture.json').exists(),'Refuse overwrite'
    q="$ErrorActionPreference='Stop';$x=@(Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\");[pscustomobject]@{count=$x.Count}|ConvertTo-Json -Compress"
    assert json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-Command',q],text=True,timeout=30).lstrip('\ufeff'))['count']==0
    captured={};summaries={}
    for name in ['baseline2','green2','red2']:
        rows={}
        for folder,prefix in [(scratch/name/'game','game/'),(scratch/'profiles'/name,'profile/')]:
            for p in sorted(folder.rglob('*')):
                if p.is_file():
                    st=p.stat();rows[prefix+p.relative_to(folder).as_posix()]={'sha256':sha(p),'bytes':st.st_size,'mtime_ns':st.st_mtime_ns}
        captured[name]=rows
        hashes={p:r['sha256'] for p,r in rows.items()}
        summaries[name]={'files':len(rows),'bytes':sum(r['bytes'] for r in rows.values()),'hash_only_aggregate':hashlib.sha256(json.dumps(hashes,sort_keys=True).encode()).hexdigest(),'path':str(scratch/name),'profile':str(scratch/'profiles'/name)}
        print('Preserved',name,len(rows),'file hashes',flush=True)
    clone=run['pairs'][1]['cloned_input_sha256']
    assert summaries['baseline2']['hash_only_aggregate']==clone and summaries['green2']['hash_only_aggregate']==clone
    dump(out/'native_inputs.json',captured)
    start=failed['result']['start_utc_epoch'];end=start+failed['result']['duration_seconds']
    ps="$ErrorActionPreference='Stop';$a=[DateTimeOffset]::FromUnixTimeSeconds("+str(int(start)-120)+").LocalDateTime;$b=[DateTimeOffset]::FromUnixTimeSeconds("+str(int(end)+300)+").LocalDateTime;try {$events=@(Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000,1001,1002;StartTime=$a;EndTime=$b} -ErrorAction Stop | Where-Object {$_.Message -match 'Godot'} | Select-Object Id,RecordId,ProviderName,TimeCreated,Message);[pscustomobject]@{events=$events;count=$events.Count}|ConvertTo-Json -Depth 5 -Compress}catch{[pscustomobject]@{events=@();count=0;collection_note=$_.Exception.Message}|ConvertTo-Json -Compress}"
    result=subprocess.run(['powershell.exe','-NoProfile','-Command',ps],capture_output=True,text=True,timeout=30)
    events=json.loads(result.stdout.lstrip('\ufeff')) if result.returncode==0 else {'collection_error':result.stderr}
    dump(out/'native_system_events.json',events)
    dumps=[]
    for folder in [Path(os.environ['LOCALAPPDATA'])/'CrashDumps',scratch/'profiles/red2/local/CrashDumps']:
        if folder.is_dir():
            for path in folder.glob('*Godot*.dmp'):
                st=path.stat()
                if start-120<=st.st_mtime<=end+600:dumps.append({'path':str(path),'bytes':st.st_size,'mtime_epoch':st.st_mtime,'sha256':sha(path),'linked_to_pid':False})
    save=Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
    meta={'captured_utc_epoch':time.time(),'collector_sha256':sha(Path(__file__)),'stopped_run_sha256':sha(out/'run.json'),'native_manifest_sha256':sha(out/'native_inputs.json'),'event_record_sha256':sha(out/'native_system_events.json'),'snapshots':summaries,'pair2_clone_sha256':clone,'red2_state':'Post-crash; not exact pre-crash cache. Never rerun this preserved copy.','baseline2_green2_state':'Both hash-identical to recorded pair2 pre-control clone input; green2 has never launched an engine.','fresh_failure':failed,'nearby_dump_candidates':dumps,'original_save_unchanged':(sha(save) if save.exists() else None)==run['original_save_before'],'native_stack_available':False}
    assert meta['original_save_unchanged']
    dump(out/'native_capture.json',meta)
    print('Native state and host-linked event search preserved; no engine launched.',flush=True)


if __name__=='__main__':main()
