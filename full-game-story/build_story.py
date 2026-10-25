"""Build and audit the self-contained, offline story atlas. Standard library only."""
from __future__ import annotations

import argparse
import hashlib
import html
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
TARGETS = [75, 75, 85, 90, 85, 85, 105, 120]
TITLES = ['Night One', 'Be the Bee', 'Moonquake', 'Into the Cold Trap', 'Shooting Stars', 'The Red Ring', 'The Great Storm', 'The Lighthouse']
CHAPTER_FIELDS = ['id','title','subtitle','date','coreMinutes','summary','emotionalArc','openingHook','transitionOut','missions','scenes','learning','continuity','production']
SCENE_FIELDS = ['id','legacyScene','title','minutes','location','pointOfView','storyTime','prose','dialogue','playerActions','choice','learning','exitCondition','evidenceTag','sourceRefs']


def load(path: Path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def word_count(text):
    return len(re.findall(r"\b[\w]+(?:['’][\w]+)*\b", text))


def validate(chapters, learning, draft=False):
    errors, warnings, checks = [], [], []

    def check(condition, label):
        checks.append({'check':label, 'passed':bool(condition)})
        if not condition:
            errors.append(label)

    if not draft:
        check([c['id'] for c in chapters] == list(range(1, 9)), 'Exactly eight ordered chapters')
    check('\ufffd' not in json.dumps(chapters,ensure_ascii=False), 'Narrative has no Unicode replacement characters')
    check('\ufffd' not in json.dumps(learning,ensure_ascii=False), 'Learning package has no Unicode replacement characters')
    ids, dialogue_ids, mission_ids = set(), set(), set()
    source_ids = {s['id'] for s in learning['sourceCards']}
    word_total, dialogue_total = 0, 0
    for chapter in chapters:
        cid = chapter['id']
        prefix = f'CH{cid:02d}'
        check(all(f in chapter for f in CHAPTER_FIELDS), f'{prefix}: chapter fields present')
        check(chapter['coreMinutes'] == TARGETS[cid-1], f'{prefix}: correct target minutes')
        check(chapter['title'] == TITLES[cid-1], f'{prefix}: canonical chapter title')
        check(len(chapter['missions']) == 4, f'{prefix}: four required missions')
        check(len(chapter['scenes']) == 12, f'{prefix}: twelve required scenes')
        check(sum(s['minutes'] for s in chapter['scenes']) == chapter['coreMinutes'], f'{prefix}: scene minutes reconcile')
        check(sum(m['minutes'] for m in chapter['missions']) == chapter['coreMinutes'], f'{prefix}: mission minutes reconcile')
        for mi, mission in enumerate(chapter['missions']):
            mid = f'EX-M{cid:02d}{mi+1:02d}'
            check(mission['id'] == mid, f'{prefix}: ordered mission {mi+1}')
            check(mission['id'] not in mission_ids, f'{mid}: unique mission ID')
            mission_ids.add(mission['id'])
            check(sum(s['minutes'] for s in chapter['scenes'][mi*3:mi*3+3]) == mission['minutes'], f'{mid}: three-scene allocation reconciles')
            check(bool(mission.get('goal')), f'{mid}: explicit goal')
        for si, scene in enumerate(chapter['scenes']):
            sid = scene['id']
            check(sid == f'EX-{prefix}-S{si+1:02d}', f'{prefix}: scene {si+1} has expected ID')
            check(sid not in ids, f'{sid}: unique scene ID')
            ids.add(sid)
            check(all(f in scene for f in SCENE_FIELDS), f'{sid}: scene fields present')
            check(isinstance(scene['minutes'], int) and scene['minutes'] > 0, f'{sid}: positive whole-minute budget')
            check(scene.get('mandatory',True) is True, f'{sid}: required main-route scene')
            if scene.get('missionId'):
                check(scene['missionId'] == chapter['missions'][si//3]['id'], f'{sid}: mission ownership matches sequence')
            wc = word_count(scene['prose'])
            word_total += wc
            check(wc >= 145, f'{sid}: finished narrative, at least 145 words')
            if wc > 250:
                warnings.append(f'{sid}: prose is {wc} words; review spoken/cinematic pacing')
            check(len(scene['dialogue']) >= 4, f'{sid}: at least four authored dialogue lines')
            check(all(d.get('speaker') and d.get('line') for d in scene['dialogue']), f'{sid}: dialogue has speakers and words')
            dialogue_total += len(scene['dialogue'])
            for li, line in enumerate(scene['dialogue']):
                line_id = line.get('id', f'{sid}-L{li+1:02d}')
                check(line_id not in dialogue_ids, f'{line_id}: unique dialogue ID')
                dialogue_ids.add(line_id)
            check(len(scene['playerActions']) >= 3, f'{sid}: concrete player actions')
            check(all(isinstance(a,str) and len(a)>12 for a in scene['playerActions']), f'{sid}: actions are written, not placeholders')
            check(bool(scene['choice'].get('prompt')) and len(scene['choice'].get('options',[])) == 2, f'{sid}: two examined responses')
            check(all(o.get('label') and o.get('consequence') for o in scene['choice']['options']), f'{sid}: explicit response consequences')
            check(bool(scene['choice'].get('convergence')), f'{sid}: checked story convergence')
            check(all(scene['learning'].get(k) for k in ['concept','predict','observe','explain','transfer']), f'{sid}: full learning loop')
            check(bool(scene['exitCondition']), f'{sid}: explicit exit condition')
            check(scene['evidenceTag'] in ['Observed','Computed-pending','Simulated','Fiction'], f'{sid}: valid evidence boundary')
            check(bool(scene['sourceRefs']), f'{sid}: source lineage present')
            for ref in scene['sourceRefs']:
                check(ref in source_ids or (REPO / ref.split('#')[0]).is_file(), f'{sid}: source resolves: {ref}')
            check(not re.search(r'\b(?:TODO|TBD|lorem ipsum|insert dialogue)\b',scene['prose'],re.I), f'{sid}: no unfinished prose placeholders')
        check(bool(chapter['continuity']) and bool(chapter['production']), f'{prefix}: continuity and production handoff')
    if not draft:
        check(len(ids) == 96, 'Ninety-six unique mandatory scenes')
        check(len(mission_ids) == 32, 'Thirty-two unique mandatory missions')
        check(sum(c['coreMinutes'] for c in chapters) == 720, 'Main route totals exactly 720 minutes')
    check(len(learning['chapters']) == 8, 'Eight chapter-level learning progressions')
    for lesson in learning['chapters']:
        check(all(lesson.get(k) for k in ['question','misconception','predict','test','observe','explain','transfer','evidenceArtifact','assessment','accessibility','scienceBoundary']), f'Learning CH{lesson["chapter"]:02d}: complete teaching and evidence contract')
        check(all(ref in source_ids for ref in lesson['sourceRefs']), f'Learning CH{lesson["chapter"]:02d}: primary source references resolve')
    check(len(learning['continuityLocks']) >= 12, 'At least twelve cross-chapter continuity locks')
    for key,total in [('minimumMinutes',600),('targetMinutes',720),('maximumMinutes',840)]:
        check(sum(c[key] for c in learning['pacing']['chapters']) == total, f'{key}: chapter ranges total {total}')
    for s in learning['sourceCards']:
        check(s['url'].startswith('https://'), f'{s["id"]}: HTTPS primary-source link')
        check(bool(s.get('boundary')), f'{s["id"]}: scientific claim boundary')
    return {'errors':errors,'warnings':warnings,'checks':checks,'checkCount':len(checks),'passedCount':sum(c['passed'] for c in checks),'narrativeWords':word_total,'dialogueLines':dialogue_total,'sceneCount':len(ids),'missionCount':len(mission_ids)}


def manuscript(chapters, learning):
    out = ['# LAST LIGHT ACADEMY — THE FIRST MOON GARDEN', '', 'Extended main-campaign edition · 25 October 2026', '', '**Scope:** 8 chapters · 32 required missions · 96 scenes · target 720 minutes / range 10–14 hours.', '', 'পুরো মূল campaign-ই ১০–১৪ ঘণ্টার। আলাদা side mission, সংগ্রহের grind বা বাধ্যতামূলক replay দিয়ে সময় বাড়ানো হয়নি।', '', 'This standalone expansion supersedes the earlier four-hour main-route budget while preserving the established plot, reveal order, character histories and physical ledgers. It is a production blueprint, not an implemented or playtested game.', '']
    for c in chapters:
        out += [f'## Chapter {c["id"]}: {c["title"]}', '', f'*{c["subtitle"]}*', '', f'{c["date"]} · {c["coreMinutes"]} minutes · all four missions required', '', c['summary'], '', f'**Emotional arc:** {c["emotionalArc"]}', '']
        for mi,m in enumerate(c['missions']):
            out += [f'### {m["id"]} — {m["title"]}', '', f'{m["minutes"]} minutes · {m["goal"]}', '']
            for s in c['scenes'][mi*3:mi*3+3]:
                out += [f'#### {s["id"]} — {s["title"]}', '', f'{s["storyTime"]} · {s["location"]} · {s["minutes"]} active minutes', '', s['prose'], '']
                out += [f'**{d["speaker"]}:** {d["line"]}\n' for d in s['dialogue']]
                out += ['**Player actions**', ''] + [f'{i+1}. {a}' for i,a in enumerate(s['playerActions'])] + ['']
                out += [f'**Decision review:** {s["choice"]["prompt"]}', ''] + [f'- **{o["label"]}:** {o["consequence"]}' for o in s['choice']['options']] + ['', f'**Convergence:** {s["choice"]["convergence"]}', '', '**Learning through action**', '']
                out += [f'- **{k.title()}:** {v}' for k,v in s['learning'].items()]
                out += ['', f'**Exit gate:** {s["exitCondition"]}', '', f'**Evidence:** {s["evidenceTag"]} · {", ".join(s["sourceRefs"])}', '']
        out += [f'**Transition:** {c["transitionOut"]}', '', '**Continuity locks**', ''] + [f'- {x}' for x in c['continuity']] + ['', '**Production handoff**', ''] + [f'- {x}' for x in c['production']] + ['']
    out += ['## Primary sources and claim boundaries','']
    for s in learning['sourceCards']:
        out += [f'### {s["id"]} — {s["title"]}', '', s['url'], '', str(s['supports']), '', '**Boundary:** '+s['boundary'], '']
    return '\n'.join(out)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--draft',action='store_true',help='Build a partial authoring preview; not a deliverable')
    args=parser.parse_args()
    chapters=[]
    for name in ['chapters-1-4.json','chapters-5-8.json']:
        path=ROOT/'content'/name
        if path.exists():
            value=load(path)
            chapters.extend(value['chapters'] if isinstance(value,dict) else value)
    chapters.sort(key=lambda c:c['id'])
    learning=load(ROOT/'content'/'learning-and-continuity.json')
    audit=validate(chapters,learning,args.draft)
    if audit['errors']:
        print(json.dumps({'errors':audit['errors'],'warnings':audit['warnings']},indent=2))
        raise SystemExit(1)
    if args.draft:
        existing={c['id']:c for c in chapters}
        chapters=[existing.get(i,{'id':i,'title':TITLES[i-1],'date':'Authoring in progress','coreMinutes':TARGETS[i-1],'subtitle':'This chapter is being synchronised with the complete campaign.','summary':'Authoring preview; not the final story.','missions':[],'scenes':[],'learning':[],'continuity':[],'production':[],'emotionalArc':'Draft','openingHook':'Draft','transitionOut':'Draft'}) for i in range(1,9)]
    data={'edition':'Extended main-campaign edition 02','created':'2026-10-25','chapters':chapters,'learning':learning,'pacing':{'brisk':[c['minimumMinutes'] for c in learning['pacing']['chapters']],'target':TARGETS,'deliberate':[c['maximumMinutes'] for c in learning['pacing']['chapters']]},'auditSummary':f'{audit["passedCount"]} structural and reference assertions passed; human continuity review is documented separately. Gameplay duration and balance remain design targets.'}
    styles=(ROOT/'styles.css').read_text(encoding='utf-8')
    artwork=(ROOT/'artwork.svg').read_text(encoding='utf-8')
    serialized=json.dumps(data,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c').replace('\u2028','\\u2028').replace('\u2029','\\u2029')
    app=(ROOT/'app.js').read_text(encoding='utf-8').replace('/*__STORY_DATA__*/',serialized).replace('/*__ARTWORK__*/',artwork.replace('`','\\`').replace('${','\\${'))
    compiled=ROOT/'app.compiled.js'
    compiled.write_text(app,encoding='utf-8')
    syntax=subprocess.run(['node','--check',str(compiled)],capture_output=True,text=True)
    if syntax.returncode:
        raise RuntimeError(syntax.stderr)
    template=(ROOT/'template.html').read_text(encoding='utf-8')
    nav='\n'.join(f'<button class="rail-link" data-chapter="{c["id"]}"><span class="rail-number">{c["id"]:02d}</span><span class="rail-name">{html.escape(c["title"])}</span><span class="time">{c["coreMinutes"]}m</span></button>' for c in chapters)
    page=template.replace('/*__STYLES__*/',styles).replace('<!--__CHAPTER_NAV__-->',nav).replace('/*__APP__*/',app)
    (ROOT/'index.html').write_text(page,encoding='utf-8')
    (ROOT/'story-data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    (ROOT/'STORY_FULL.md').write_text(manuscript(chapters,learning),encoding='utf-8')
    (ROOT/'audit-results.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'draft':args.draft,'chapters':sum(bool(c['scenes']) for c in chapters),'scenes':audit['sceneCount'],'missions':audit['missionCount'],'narrativeWords':audit['narrativeWords'],'dialogueLines':audit['dialogueLines'],'assertionsPassed':audit['passedCount'],'assertionsTotal':audit['checkCount'],'warnings':audit['warnings'],'htmlBytes':(ROOT/'index.html').stat().st_size,'sha256':hashlib.sha256((ROOT/'index.html').read_bytes()).hexdigest()},indent=2))


if __name__ == '__main__':
    main()
