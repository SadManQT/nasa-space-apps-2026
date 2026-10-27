# meshy_post.py <endpoint> '<json body>': POST to https://api.meshy.ai/openapi/v1/<endpoint> and print the new task id.
# e.g. meshy_post.py animations '{"rig_task_id": "...", "action_ids": [243, 249]}'
#      meshy_post.py text-to-motion '{"prompt": "...", "duration": 4}'
# Key read from ~/.claude.json like the other Meshy helpers; never printed.
import json, os, sys, urllib.error, urllib.request
endpoint, body = sys.argv[1], sys.argv[2].encode()
key = json.load(open(os.path.expanduser("~/.claude.json")))["mcpServers"]["meshy"]["env"]["MESHY_API_KEY"]
req = urllib.request.Request(f"https://api.meshy.ai/openapi/v1/{endpoint}", data=body, method="POST",
                             headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
try:
    print(json.loads(urllib.request.urlopen(req, timeout=120).read())["result"])
except urllib.error.HTTPError as e:
    print("HTTP", e.code, e.read().decode()[:500]); sys.exit(1)
