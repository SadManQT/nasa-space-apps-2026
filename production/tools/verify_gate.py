#!/usr/bin/env python3
"""Asset quality gate: compare what Godot imports with each asset's spec.

  python3 production/tools/verify_gate.py            (run after sync_to_godot.sh)

Specs come from production/manifest/{characters,tripo_props_batch1,reuse_props,lunar_kit,habitat_kit}.csv and every
chapter set production/manifest/chapter*_assets.csv (M3-7A).
Checks per asset: imports with a mesh; triangles within budget; largest texture within budget;
standing on the floor (lowest point y = 0 ± 1 cm); real-world size within 2 % of spec
(height for --height, longest side for --longest); characters have their rig (bones) and at least
the clips in the manifest's clips column, written <clips>/<looping clips>.
Writes production/review/asset_verification.md and exits 1 if anything fails. It also fails, without
writing the report, when Godot exits non-zero or prints a script error, or reports zero assets; and
it fails when a GLB under game/assets has no ASSET record (the importer skipped or crashed on it).
The LOLA terrain tiles under game/assets/environment/terrain/lola/ (M1-34) are kilometre-scale heightfield
meshes with no prop spec; both this gate and verify_assets.gd skip them, and game/tools/test_terrain_lola.gd
verifies them (import, triangle counts, footprint, vertices on the heightfield, UVs and normal maps).
"""
import csv, json, os, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
GODOT_ERRORS = ("SCRIPT ERROR", "Parse Error", "Failed to load script", "ERROR:")


MANIFESTS = ("characters", "tripo_props_batch1", "reuse_props", "lunar_kit", "habitat_kit")


def manifest_names():
    """The fixed manifests plus every chapter asset set (production/manifest/chapter*_assets.csv)."""
    extra = sorted(p.stem for p in (ROOT / "production/manifest").glob("chapter*_assets.csv"))
    return list(MANIFESTS) + [n for n in extra if n not in MANIFESTS]


def specs():
    out = {}
    for name in manifest_names():
        for r in csv.DictReader(open(ROOT / f"production/manifest/{name}.csv", encoding="utf-8")):
            out[r["name"]] = r
    return out


def check(spec, a):
    if not a.get("loaded"):
        return [("imports", False, "did not import or has no mesh")]
    size = a["size"]
    measured = size[1] if spec["size_flag"] == "--height" else max(size)
    target = float(spec["size_m"])
    res = [
        ("imports", True, ""),
        ("tris", a["tris"] <= int(spec["tris"]) * 1.01, f'{a["tris"]} / {spec["tris"]}'),
        ("texture", 0 < a["max_tex"] <= int(spec["tex"]), f'{a["max_tex"]} / {spec["tex"]} px'),
        ("on floor", abs(a["min_y"]) <= 0.01, f'min y {a["min_y"]} m'),
        ("size", abs(measured - target) <= 0.02 * target, f'{measured} / {target} m ({spec["size_flag"][2:]})'),
    ]
    if spec.get("bones"):
        clips, loops = (int(v) for v in spec.get("clips", "0/0").split("/"))
        res.append(("rig", a["bones"] == int(spec["bones"]) and a.get("anims", 0) >= clips and a.get("loops", 0) >= loops,
                    f'{a["bones"]} bones, {a.get("anims", 0)} clips ({a.get("loops", 0)} loop)'))
    return res


def godot_assets(expected):
    """Runs verify_assets.gd; exits 1 if Godot failed or reported nothing."""
    try:
        run = subprocess.run([GODOT, "--headless", "--path", str(ROOT / "game"), "--script", "res://tools/verify_assets.gd"],
                             capture_output=True, text=True, timeout=300)
    except (OSError, subprocess.TimeoutExpired) as error:
        sys.exit(f"FAIL: could not start Godot ({GODOT}): {error}")
    log = run.stdout + run.stderr
    errors = [l for l in log.splitlines() if any(e in l for e in GODOT_ERRORS)]
    if run.returncode != 0 or errors:
        sys.exit(f"FAIL: Godot exited {run.returncode}; " + ("; ".join(errors[:5]) or "no ASSET output trusted"))
    assets = {}
    try:
        for line in run.stdout.splitlines():
            if not line.startswith("ASSET "):
                continue
            record = json.loads(line[6:])
            name = record["file"]
            if not isinstance(name, str) or not name or name in assets:
                raise ValueError("invalid or duplicate asset name")
            assets[name] = record
    except (ValueError, KeyError, TypeError) as error:
        sys.exit(f"FAIL: malformed ASSET record: {error}")
    if not assets:
        sys.exit("FAIL: Godot reported 0 assets; refusing to write a passing report.")
    missing = set(expected) - assets.keys()
    if missing:
        sys.exit("FAIL: missing expected ASSET records: " + ", ".join(sorted(missing)))
    return assets


def main():
    sp = specs()
    # Every GLB on disk must come back as a record; manifest rows without a GLB
    # are planned assets, reported below as not yet in Godot.
    skip = (ROOT / "game/assets/environment/terrain/lola").resolve()
    expected = {p.stem for p in (ROOT / "game/assets").rglob("*.glb") if skip not in p.resolve().parents}
    assets = godot_assets(expected)
    lines = ["# Asset verification", "", "Generated by `production/tools/verify_gate.py` from what Godot 4.7.2 actually imports. "
             "Visual review notes are in [visual_review.md](visual_review.md).", "",
             "| Asset | Result | Triangles | Texture | Floor | Size | Rig |", "|---|---|---|---|---|---|---|"]
    failed = 0
    for name in sorted(set(sp) | set(assets)):
        if name not in assets:
            lines.append(f"| {name} | ⬜ not in Godot yet | | | | | |"); continue
        if name not in sp:
            lines.append(f"| {name} | ❌ no spec in a manifest | | | | | |"); failed += 1; continue
        res = {k: (ok, note) for k, ok, note in check(sp[name], assets[name])}
        ok = all(v[0] for v in res.values())
        failed += not ok
        cell = lambda k: "" if k not in res else ("✅ " if res[k][0] else "❌ ") + res[k][1]
        lines.append(f"| {name} | {'✅ PASS' if ok else '❌ FAIL'} | {cell('tris')} | {cell('texture')} | {cell('on floor')} | {cell('size')} | {cell('rig')} |"
                     if "imports" in res and res["imports"][0] else f"| {name} | ❌ FAIL | {res['imports'][1]} | | | | |")
    lines += ["", f"**{len(assets)} assets in Godot, {failed} failing.**"]
    (ROOT / "production/review/asset_verification.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines[-1:]))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
