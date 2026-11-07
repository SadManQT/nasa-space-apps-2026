"""Terrain and route data for the EN_RelayRoad sheet (system Python; no network: a missing LOLA tile stops the script).

    python3 production/concept/chapter8_v1/road_data.py

Writes production/models/chapter8/data/r2_40m.npy/.json (a 12 km window of LDEM_80S_40MPP_ADJ round repeater site R2,
the marker-two service pad) and road.json (the computed relay road, the three repeater pads, the five playable segments
and the two laybys, with real and game distances). The pads and hops come from production/tools/route_simulator_data.py
(M3-7A), so the road, the fabrication-bench simulator and this environment agree.
"""
import json
import math
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "production/tools"))
import make_terrain as mt  # noqa: E402
import route_simulator_data as rs  # noqa: E402

OUT = ROOT / "production/models/chapter8/data"
GAME_KM = 120.0  # canon one-way distance (08_PUZZLE_DESIGNS P-15; M1-34 decision keeps it)


def no_fetch(*_a, **_k):
    raise RuntimeError("road_data.py reads cached LOLA tiles only")


def main():
    mt.http_get = no_fetch
    d = rs.compute()
    road = json.loads((ROOT / "production/terrain/routes.json").read_text())["routes"]["relay_road"]
    pts = road["points"]
    total = road["length_m"]
    pads = d["pads"]
    r2 = pads[1]
    a, g = mt.window_m("pgda90_40mpp", r2["x"], r2["y"], 12000)
    OUT.mkdir(parents=True, exist_ok=True)
    np.save(OUT / "r2_40m.npy", mt.fill_nan(a).astype(np.float32))
    g.update({"site_x": r2["x"], "site_y": r2["y"], "site_h": r2["h"]})
    (OUT / "r2_40m.json").write_text(json.dumps(g, indent=1))

    def at(dist):
        k = min(range(len(pts)), key=lambda i: abs(pts[i][3] - dist))
        return pts[k]

    def game_km(dist):
        return round(dist / total * GAME_KM, 1)

    segs = [  # five short playable segments, about 700 m in all (LOC-11)
        {"id": "A", "name": "Marker one", "scene": "EX-CH08-S03", "road_m": pads[0]["road_m"], "length_m": 140, "what": "match map, marker and bearing; R1 adjacent-link test; local check-in to Aurora"},
        {"id": "B", "name": "The dark marker", "scene": "EX-CH08-S03", "road_m": pads[1]["road_m"] - 1500, "length_m": 160, "what": "marker two dark; the apparent bypass over the unsupported slope; turnback zone; brake at the pad"},
        {"id": "C", "name": "Marker-two service pad", "scene": "EX-CH08-S04", "road_m": pads[1]["road_m"], "length_m": 120, "what": "EVA: isolate, swap the battery, close the bay, test both neighbours"},
        {"id": "D", "name": "Marker three", "scene": "EX-CH08-S04", "road_m": pads[2]["road_m"], "length_m": 140, "what": "R3 adjacent links; the 100 km approach begins"},
        {"id": "E", "name": "Summit approach", "scene": "EX-CH08-S06", "road_m": total - 900, "length_m": 140, "what": "the last climb (up to 15 deg on the 80 m grid) onto the LOC-12 pad"},
    ]
    laybys = [{"id": "L1", "road_m": round(total * 0.18)}, {"id": "L2", "road_m": round(total * 0.72)}]
    for s in segs + laybys:
        p = at(s["road_m"])
        s.update({"x": p[0], "y": p[1], "h": round(p[2], 1), "game_km": game_km(s["road_m"])})
    for p in pads:
        p["game_km"] = game_km(p["road_m"])
    out = {"about": __doc__.strip().splitlines()[0], "road_length_m": total, "game_km": GAME_KM,
           "pads": pads, "segments": segs, "laybys": laybys,
           "aurora": [d["aurora"]["x"], d["aurora"]["y"]] if isinstance(d["aurora"], dict) else d["aurora"],
           "summit": [d["summit"]["x"], d["summit"]["y"]] if isinstance(d["summit"], dict) else d["summit"],
           "road_xy": [[p[0], p[1]] for p in pts],
           "spur_r2": {"from": at(pads[1]["road_m"])[:2], "to": [r2["x"], r2["y"]]},
           "hops": d["hops"]}
    (OUT / "road.json").write_text(json.dumps(out, indent=1, default=float))
    print("segments", [(s["id"], s["game_km"], s["road_m"]) for s in segs])
    print("pads", [(round(p["road_m"]), p["game_km"]) for p in pads])
    print("total", round(sum(s["length_m"] for s in segs)), "m playable")


if __name__ == "__main__":
    main()
