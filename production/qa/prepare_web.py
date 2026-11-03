#!/usr/bin/env python3
"""Stage a bounded Chapter 1 browser investigation; requires Pillow 11.3.0.
Run with a virtual environment: python production/qa/prepare_web.py
Only builds/web-stage is rewritten; approved game/assets are read-only.
"""
import io,json,pathlib,struct,shutil
from PIL import Image
root=pathlib.Path(__file__).resolve().parents[2]
stage=root/'builds/web-stage'
shutil.copytree(root/'game',stage,ignore=shutil.ignore_patterns('.godot'),dirs_exist_ok=True)
count=0;before=0;after=0
for p in (stage/'assets').rglob('*.glb'):
 raw=p.read_bytes();before+=len(raw)
 length,kind=struct.unpack_from('<II',raw,12);data=json.loads(raw[20:20+length]);off=20+length
 blen,bkind=struct.unpack_from('<II',raw,off);binary=raw[off+8:off+8+blen]
 images={image['bufferView']:image for image in data.get('images',[]) if 'bufferView' in image}
 rebuilt=bytearray()
 for i,view in enumerate(data.get('bufferViews',[])):
  chunk=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
  if i in images:
   try:
    image=Image.open(io.BytesIO(chunk))
    if max(image.size)>1024:
     image.thumbnail((1024,1024),Image.Resampling.LANCZOS)
     output=io.BytesIO();image.save(output,format='PNG');chunk=output.getvalue();images[i]['mimeType']='image/png';count+=1
   except (OSError,ValueError):pass
  while len(rebuilt)%4:rebuilt.append(0)
  view['byteOffset']=len(rebuilt);view['byteLength']=len(chunk);rebuilt.extend(chunk)
 while len(rebuilt)%4:rebuilt.append(0)
 data['buffers'][0]['byteLength']=len(rebuilt)
 encoded=json.dumps(data,separators=(',',':')).encode()
 encoded+=b' '*((-len(encoded))%4)
 result=b'glTF'+struct.pack('<II',2,28+len(encoded)+len(rebuilt))+struct.pack('<I4s',len(encoded),b'JSON')+encoded+struct.pack('<I4s',len(rebuilt),b'BIN\0')+rebuilt
 p.write_bytes(result);after+=len(result)
# A bounded Chapter 1 investigation, clearly separated from native candidates.
p=stage/'scripts/campaign/chapter1_campaign.gd';text=p.read_text();text=text.replace('if chapter == 1:\n\t\treturn _start_chapter2()', 'if chapter == 1:\n\t\treturn {"accepted": true, "chapter_complete": true, "campaign_complete": true, "reason": "Chapter 1 browser preview complete. The desktop candidate contains the later chapters."}')
p.write_text(text)
manifest={'texture_limit':1024,'images_resized':count,'glb_bytes_before':before,'glb_bytes_after':after,'source_glbs_changed':False,'scope':'Chapter 1 web feasibility; all source assets remain untouched'}
(root/'builds/2026-11-04/web/texture_transform.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(manifest)
