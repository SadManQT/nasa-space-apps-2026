#!/usr/bin/env python3
"""Tripo OpenAPI v3 client (stdlib only) for the separate API-credit pool.
Web-plan accounts use the `tripo` CLI instead. Docs: https://developers.tripo3d.ai/en/docs/

  tripo_api.py balance
  tripo_api.py image <png|url> <out_dir> [--face-limit N] [--quad]
  tripo_api.py multiview <out_dir> --front F [--left L] [--back B] [--right R] [--face-limit N] [--quad]
  tripo_api.py rig <task_id|model file|url> <out_dir> [--model v1.0-20240301 --spec tripo]
  tripo_api.py retarget <rig_task_id> <out_dir> --animations preset:biped:idle,preset:biped:wait [--in-place]
  tripo_api.py task <task_id> [<out_dir>]

Reads TRIPO_OPENAPI_KEY (deliberately not TRIPO_API_KEY, which the CLI would pick up
and use instead of the web login). Each create command uploads local files, polls until
done, downloads every URL in `output` into <out_dir> and writes task.json beside them.
"""
import argparse, json, mimetypes, os, sys, time, urllib.error, urllib.request, uuid
from pathlib import Path

BASE = "https://openapi.tripo3d.ai/v3"
MODEL = "v3.1-20260211"      # H3.1, highest precision
RIG_MODEL = "v3.0-20260909"  # recommended for humanoids


def multipart(field, path):
    boundary = uuid.uuid4().hex
    mime = mimetypes.guess_type(path)[0] or "application/octet-stream"
    head = (f'--{boundary}\r\nContent-Disposition: form-data; name="{field}"; '
            f'filename="{Path(path).name}"\r\nContent-Type: {mime}\r\n\r\n').encode()
    body = head + Path(path).read_bytes() + f"\r\n--{boundary}--\r\n".encode()
    return body, f"multipart/form-data; boundary={boundary}"


def call(method, path, body=None, ctype="application/json"):
    key = os.environ.get("TRIPO_OPENAPI_KEY") or sys.exit("TRIPO_OPENAPI_KEY is not set")
    data = json.dumps(body).encode() if isinstance(body, dict) else body
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={"Authorization": f"Bearer {key}", "Content-Type": ctype})
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                res = json.load(r)
            break
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 5:  # rate or concurrency limit
                time.sleep(int(e.headers.get("Retry-After") or 15))
                continue
            sys.exit(f"{method} {path} -> HTTP {e.code}: {e.read().decode(errors='replace')}")
    if res.get("code") != 0:
        sys.exit(f"{method} {path} -> {res}")
    return res["data"]


def ref(value):
    """Local file -> file_token; URL or task_id passes through."""
    if Path(value).is_file():
        body, ctype = multipart("file", value)
        return call("POST", "/files", body, ctype)["file_token"]
    return value


def wait(task_id):
    while True:
        t = call("GET", f"/tasks/{task_id}")
        print(f"  {task_id} {t['status']} {t.get('progress', 0)}%", file=sys.stderr)
        if t["status"] in ("success", "failed", "cancelled"):
            return t
        time.sleep(10)


def save(task, out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "task.json").write_text(json.dumps(task, indent=2))
    for name, url in (task.get("output") or {}).items():
        if isinstance(url, str) and url.startswith("http"):
            ext = Path(url.split("?")[0]).suffix or ".bin"
            urllib.request.urlretrieve(url, out / f"{name}{ext}")
            print(out / f"{name}{ext}")
    if task["status"] != "success":
        sys.exit(f"task {task['task_id']} ended {task['status']}")


def run(path, body, out):
    task_id = call("POST", path, body)["task_id"]
    print(f"task {task_id}", file=sys.stderr)
    save(wait(task_id), out)


def geometry(a):
    body = {"model": MODEL, "geometry_quality": "detailed", "texture_quality": "detailed", "pbr": True}
    if a.face_limit:
        body["face_limit"] = a.face_limit
    if a.quad:
        body["quad"] = True  # Tripo then returns FBX
    return body


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("balance")
    for name in ("image", "multiview"):
        s = sub.add_parser(name)
        if name == "image":
            s.add_argument("src")
        s.add_argument("out")
        s.add_argument("--face-limit", type=int)
        s.add_argument("--quad", action="store_true")
        if name == "multiview":
            for view in ("front", "left", "back", "right"):
                s.add_argument(f"--{view}", required=view == "front")
    s = sub.add_parser("rig"); s.add_argument("src"); s.add_argument("out")
    s.add_argument("--model", default=RIG_MODEL); s.add_argument("--spec", default="mixamo")
    s = sub.add_parser("retarget"); s.add_argument("src"); s.add_argument("out")
    s.add_argument("--animations", required=True); s.add_argument("--in-place", action="store_true")
    s = sub.add_parser("task"); s.add_argument("task_id"); s.add_argument("out", nargs="?")
    a = p.parse_args()

    if a.cmd == "balance":
        print(json.dumps(call("GET", "/account/balance"), indent=2))
    elif a.cmd == "image":
        run("/generation/image-to-model", {"input": ref(a.src), **geometry(a)}, a.out)
    elif a.cmd == "multiview":
        views = [{v: ref(getattr(a, v))} for v in ("front", "left", "back", "right") if getattr(a, v)]
        if len(views) < 2:
            sys.exit("multiview needs --front plus at least one other view")
        run("/generation/multiview-to-model", {"inputs": views, **geometry(a)}, a.out)
    elif a.cmd == "rig":
        run("/animations/rig", {"input": ref(a.src), "model": a.model, "rig_type": "biped",
                                "spec": a.spec, "out_format": "glb"}, a.out)
    elif a.cmd == "retarget":
        run("/animations/retarget", {"input": a.src, "animations": a.animations.split(","), "out_format": "glb",
                                     "animate_in_place": a.in_place}, a.out)
    elif a.cmd == "task":
        t = call("GET", f"/tasks/{a.task_id}")
        if a.out:
            save(t, a.out)
        else:
            print(json.dumps(t, indent=2))
            if t["status"] in ("failed", "cancelled"):
                sys.exit(1)


if __name__ == "__main__":
    main()
