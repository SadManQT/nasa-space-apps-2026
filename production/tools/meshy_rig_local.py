# rig_local.py <static.glb> <height_m>: POST a local GLB (as a data URI) to Meshy's rigging endpoint; prints the task id
import base64, json, os, sys, urllib.request
glb, height = sys.argv[1], float(sys.argv[2])
key = json.load(open(os.path.expanduser("~/.claude.json")))["mcpServers"]["meshy"]["env"]["MESHY_API_KEY"]
body = json.dumps({"height_meters": height,
                   "model_url": "data:application/octet-stream;base64," + base64.b64encode(open(glb, "rb").read()).decode()}).encode()
req = urllib.request.Request("https://api.meshy.ai/openapi/v1/rigging", data=body, method="POST",
                             headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
try:
    print(urllib.request.urlopen(req, timeout=300).read().decode())
except urllib.error.HTTPError as e:
    print("HTTP", e.code, e.read().decode()[:500])
