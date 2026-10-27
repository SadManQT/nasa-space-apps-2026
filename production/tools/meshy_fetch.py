# meshy_fetch.py <rigging|animations> <task_id> <out_dir> [<name>...]: wait for a task, then download every *_glb_url
# (or only the named keys) into out_dir; prints status and files, never the signed URLs or the key
import json, os, sys, time, urllib.request
kind, tid, out = sys.argv[1:4]; want = set(sys.argv[4:])
key = json.load(open(os.path.expanduser("~/.claude.json")))["mcpServers"]["meshy"]["env"]["MESHY_API_KEY"]
def get():
    req = urllib.request.Request(f"https://api.meshy.ai/openapi/v1/{kind}/{tid}", headers={"Authorization": f"Bearer {key}"})
    return json.loads(urllib.request.urlopen(req, timeout=60).read())
for _ in range(120):
    try: t = get()
    except Exception as e:  # a dropped connection or a 429 while many fetches poll at once: wait and poll again
        print("  poll retry:", type(e).__name__); time.sleep(15); continue
    if t["status"] in ("SUCCEEDED", "FAILED", "CANCELED"): break
    time.sleep(10)
print(kind, tid, t["status"], t.get("task_error", {}).get("message", "") if t["status"] != "SUCCEEDED" else "")
os.makedirs(out, exist_ok=True)
def urls(d, path=""):
    for k, v in d.items():
        if isinstance(v, dict): yield from urls(v, k)
        elif isinstance(v, str) and k.endswith("glb_url"): yield k, v
for k, u in urls(t.get("result", {})):
    if want and k.replace("_glb_url", "") not in want: continue
    dst = os.path.join(out, k.replace("_glb_url", "") + ".glb")
    urllib.request.urlretrieve(u, dst); print("  saved", dst, os.path.getsize(dst))
