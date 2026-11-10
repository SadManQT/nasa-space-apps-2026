"""Verify M1-85 published evidence independently of runner exit codes."""
import argparse
import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path


def sha(path):
    value=hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda:stream.read(1024*1024),b''):value.update(block)
    return value.hexdigest()


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--verify-local',action='store_true');args=ap.parse_args()
    root=Path(__file__).resolve().parent
    def read(name):return json.loads((root/name).read_text(encoding='utf-8'))
    manifest=read('artifacts.json')
    for row in manifest['artifacts']:
        path=root/row['file'];assert sha(path)==row['sha256'] and path.stat().st_size==row['bytes'],path
    env=read('environment.json');rec=read('reconstruction.json');initial=read('execution.json');cont=read('continuation.json');filtered=read('filtered_continuation.json')
    assert rec['expected_game_tree_matches'] and rec['game_tree']=='f59fcc7b080618dc5388cf84c56fd5938ced76ab'
    assert sha(root/'executed_prepare.py')==rec['prepare_collector_sha256']
    assert sha(root/'recovered_repro.py')==env['collector_sha256']
    assert sha(root/'godot_log_shim.sh')==env['logging_shim_sha256']
    assert sha(root/'continued_repro.py')==cont['collector_sha256']
    assert sha(root/'filtered_repro.py')==filtered['collector_sha256']
    assert len(initial['runs'])==1 and not initial['collection_complete'] and initial['stop_reason']
    assert cont['complete'] and filtered['complete']
    assert not cont['all_cases_overall_clean'] and not filtered['all_cases_overall_clean']
    assert cont['retained_a_and_b_hashes_still_match'] and filtered['original_save_unchanged']
    assert cont['restoration']['tracked_sidecars']==960 and cont['restoration']['byte_differences']==0
    assert filtered['restoration']['tracked_sidecars']==960 and filtered['restoration']['byte_differences']==960
    assert not filtered['restoration']['non_crlf_differences']
    checks=read('collector_selfcheck.json')['checks']
    assert [(x['mode'],x['raw_exit'],x['classified_failure']) for x in checks]==[('generic',0,True),('nonzero',7,True),('script',1,True)]
    rows=[];setup_total=suite_total=0
    for name in ['cold','warm','clone_control','restored','retry','filtered_control','filtered_restore','filtered_retry']:
        result=read(name+'/runner.json');assert result['raw_exit_code']==0 and not result['timed_out']
        assert result['suite_summary']==['1/1 suites passed']
        assert sha(root/name/'runner.txt')==result['log_sha256']
        phase_counts={}
        for phase in ['setup','test_hint_player.gd']:
            log=root/name/'runner_logs'/(phase+'.log')
            text=re.sub(r'\x1b\[[0-9;]*m','',log.read_text(encoding='utf-8',errors='replace'))
            errors=[line for line in text.splitlines() if re.match(r'^\s*ERROR:',line)]
            scripts=[line for line in text.splitlines() if re.search(r'SCRIPT ERROR|Parse Error|Could not find type|Failed to load script',line)]
            assert not scripts
            assert int(log.with_suffix('.exit.txt').read_text().strip())==0
            phase_counts[phase]=len(errors)
            if phase=='test_hint_player.gd':
                assert 'HINT PLAYER RESULT: PASS (85 checks, 0 failures)' in text
                expected_audio="ERROR: Resumed function '_stream()' after await, but class instance is gone. At script: res://scripts/audio/audio_director.gd:283"
                assert all(line==expected_audio for line in errors), 'Unexpected suite error cannot be called historical audio'
            if phase=='setup' and name=='filtered_restore':
                assert len(errors)==2 and text.count('get_multiple_md5 (core/io/file_access.cpp:967)')==2
                assert not any('Unrecognized UID' in line or "Can't find file" in line for line in text.splitlines())
        assert phase_counts['setup']==(2 if name=='filtered_restore' else 0)
        assert phase_counts['test_hint_player.gd'] in [1,2]
        assert result['generic_error_count']==sum(phase_counts.values())
        assert not result['any_native_failure'] and not result['same_setup_exit139_signature']
        if name=='cold':assert not initial['runs'][0]['clean']
        else:assert not result['overall_clean']
        setup_total+=phase_counts['setup'];suite_total+=phase_counts['test_hint_player.gd']
        rows.append({'case':name,'seconds':result['duration_seconds'],'outer_exit':0,'setup_exit':0,'suite_exit':0,
                     'setup_errors':phase_counts['setup'],'suite_errors':phase_counts['test_hint_player.gd'],
                     'hint_assertions':[85,0],'overall_log_integrity':'FAIL','native_setup139':False})
    assert setup_total==2 and suite_total==13
    local={'requested':args.verify_local,'verified':False}
    if args.verify_local:
        scratch=Path(env['scratch']);verified={};counts={}
        maps={'retained_inputs.json':{'a_after_failed_cold':'a','b_after_restoration':'b'},
              'filtered_retained_inputs.json':{'b_input_after_raw_restoration':'b','d_after_filtered_restoration':'d'}}
        for file,mapping in maps.items():
            data=read(file)
            for key,project in mapping.items():
                counts[key]=len(data[key])
                for row in data[key]:
                    if row['file'].startswith('profile/'):base=scratch/'profiles'/project;name=row['file'][8:]
                    else:base=scratch/project;name=row['file']
                    path=(base/name).resolve();assert path.is_relative_to(base.resolve())
                    if path not in verified:
                        assert sha(path)==row['sha256'] and path.stat().st_size==row['bytes'],path
                        verified[path]=row['sha256']
                    else:assert verified[path]==row['sha256']
        save=Path(os.environ['APPDATA'])/'Godot/app_userdata/Last Light Academy/last_light_expedition_v2.json'
        assert (sha(save) if save.exists() else None)==initial['original_save_sha256']
        local={'requested':True,'verified':True,'unique_cache_sidecar_uid_profile_files':len(verified),'manifest_counts':counts,'original_save_unchanged':True}
    audit={'verified_utc':datetime.now(timezone.utc).isoformat(),'manifest_sha256':sha(root/'artifacts.json'),
           'verified_artifact_count':len(manifest['artifacts']),'game_tree':rec['game_tree'],'cases':rows,
           'setup_engine_errors':setup_total,'historical_suite_audio_errors':suite_total,'script_errors':0,
           'native_setup139_reproduced':False,'local_retained_state':local,
           'scope':'Eight separate focused historical-source calls. All assertion markers85/0 and exit0, all overall log-integrityFAIL. Two file-access errors occur only in configured Git-filter restoration. No original native-crash cause/fix, no production source/asset/settings change and no new full campaign gate claimed.'}
    (root/'audit.json').write_text(json.dumps(audit,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Verified',len(rows),'focused cases:',setup_total,'setup file-access errors,',suite_total,'historical suite audio errors; all overall FAIL; original native139 not reproduced.')


if __name__=='__main__':main()
