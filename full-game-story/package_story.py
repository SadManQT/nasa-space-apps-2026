"""Package the local deliverable and its editable, auditable source."""
from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parent
paths = sorted(p for p in root.rglob('*') if p.is_file() and p.suffix in {'.html','.md','.json','.css','.js','.cjs','.svg','.py'} and p.name != 'PACKAGE_MANIFEST.json' and '__pycache__' not in p.parts)
manifest = {
    'title': 'Last Light Academy — The First Moon Garden',
    'edition': 'Complete main-campaign story / 25 October 2026',
    'entryPoint': 'index.html',
    'scope': {'chapters':8,'requiredMissions':32,'scenes':96,'targetMinutes':720,'rangeMinutes':[600,840]},
    'files': [{'path':str(p.relative_to(root)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths]
}
manifest_path = root/'PACKAGE_MANIFEST.json'
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
archive = root/'Last-Light-Academy-Full-Story.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as bundle:
    for p in paths+[manifest_path]:
        bundle.write(p,p.relative_to(root))
with zipfile.ZipFile(archive) as bundle:
    if bundle.testzip() is not None:
        raise RuntimeError('Archive integrity check failed')
    for item in manifest['files']:
        if hashlib.sha256(bundle.read(item['path'])).hexdigest() != item['sha256']:
            raise RuntimeError('Archive hash mismatch: '+item['path'])
print(json.dumps({'archive':str(archive),'bytes':archive.stat().st_size,'files':len(paths)+1,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'integrity':'passed'},indent=2))
