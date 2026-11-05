"""Line-of-sight data for the Chapter 7 surveyed-route simulator (board M3-7A), from the real LOLA relay corridor.

    python3 production/tools/route_simulator_data.py        (prints the analysis; the Blender build imports it)

EX-CH07-S11: "Rafi lays three repeater sites along the surveyed road model. A straight line drawn over a ridge fails
the simulator's obstruction check." The simulator table in EN_Fabrication carries a relief of the corridor between
Aurora and the Malapert summit, milled from the same NASA LRO LOLA heightmap the Chapter 8 exteriors stand on
(game/assets/environment/terrain/lola/relay_road, PGDA product 90, 80 m/px, board M1-34). This module turns that
heightmap into the table's numbers so the puzzle (M3-7P) can test any line honestly instead of using a scripted answer:

  * the map-to-table transform (scale 1:90,000, vertical exaggeration 2 on the table only);
  * the surveyed road (routes.relay_road of lola_terrain.json, computed by make_terrain.py) in table coordinates;
  * three repeater pads: the highest LOLA pixel within 2.5 km of the road, chosen so that Aurora -> R1 -> R2 -> R3 ->
    summit are four clear hops (three sites, four links: STORY_FULL CH07 production handoff), every hop at least
    25 km of road apart;
  * a hop table (Aurora, the pads, the summit): clear or blocked, the smallest clearance and where it occurs;
  * straight lines between road-level points that a ridge blocks (the S11 teaching example), with the ridge point.

Line of sight is computed in true scale (never on the exaggerated table): the chord between two antenna tips sags
below the 1,737.4 km reference sphere by s(d - s) / 2R (the lunar curvature), and the terrain is the bilinear LOLA
height under the chord, sampled every 40 m. Polar stereographic distances are within 0.2 % of true at these
latitudes. Clearance within 500 m of each end is ignored: there the antenna mast and the 80 m grid's
smoothing of the pad itself, not a ridge, decide. Every pad also gets its road-level alternative (the road point it
was sited from), which shows the S11 lesson in real terrain: a repeater down on the road in a valley is blocked
by the next ridge, the same repeater on the high ground beside the road clears it.

Finding to report (not a story change): on this grid Aurora's ridge-top site and the Malapert summit see each other
directly (`direct_aurora_summit` below). STORY_FULL EX-CH07-S11 says the base is "hidden by terrain"; the science
reviewer decides how the story frames it (board task filed by M3-7A).
"""
import json
import math
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
LOLA = ROOT / "game/assets/environment/terrain/lola"
MOON_RADIUS_M = 1737400.0
SCALE = 1.0 / 90000.0          # table metres per map metre
VERTICAL_EXAGGERATION = 2.0    # table only; every line-of-sight number is true scale
REGION_X_M = (-44000.0, 2000.0)     # map x (toward 90 deg E) covered by the relief
REGION_Y_M = (-18000.0, 134000.0)   # map y (toward 0 deg E): Aurora at -12.5 km, the summit at 122.3 km
MAST_M = {"aurora": 10.0, "repeater": 3.0, "summit": 5.0}  # Aurora's mast (sites.json); portable repeater; summit relay
PAD_SEARCH_RADIUS_M = 2500.0
MIN_HOP_ROAD_M = 25000.0
END_IGNORE_M = 500.0
STEP_M = 40.0


class Heightmap:
    """The relay corridor heightmap (r16) with bilinear sampling in map metres."""

    def __init__(self):
        self.meta = json.loads((LOLA / "relay_road/heightmap_80m.json").read_text(encoding="utf-8"))
        m = self.meta
        raw = np.fromfile(LOLA / "relay_road/heightmap_80m.r16", dtype="<u2").reshape(m["rows"], m["columns"])
        self.h = m["z_min_m"] + raw.astype(np.float64) * (m["z_max_m"] - m["z_min_m"]) / 65535.0
        self.mpp, self.ox, self.oy = m["metres_per_pixel"], m["origin_x_m"], m["origin_y_m"]

    def sample(self, x, y):
        """Height in metres above the reference sphere at map (x, y); arrays or scalars."""
        m = self.meta
        c = (np.asarray(x, dtype=np.float64) - self.ox) / self.mpp
        r = (self.oy - np.asarray(y, dtype=np.float64)) / self.mpp
        c0 = np.clip(np.floor(c).astype(int), 0, m["columns"] - 2)
        r0 = np.clip(np.floor(r).astype(int), 0, m["rows"] - 2)
        fc, fr = np.clip(c - c0, 0, 1), np.clip(r - r0, 0, 1)
        h = self.h
        return (h[r0, c0] * (1 - fc) * (1 - fr) + h[r0, c0 + 1] * fc * (1 - fr)
                + h[r0 + 1, c0] * (1 - fc) * fr + h[r0 + 1, c0 + 1] * fc * fr)

    def grid(self, xs, ys):
        """Heights on the outer product of map x values (columns) and map y values (rows)."""
        xx, yy = np.meshgrid(xs, ys)
        return self.sample(xx, yy)


def line_of_sight(hm, a, b, mast_a, mast_b):
    """Clearance of the chord between two antenna tips over the curved terrain (true scale).
    Returns dict(clear, min_clearance_m, at_m (distance from a), distance_m, point (map x, y, terrain height))."""
    (xa, ya), (xb, yb) = a, b
    d = math.hypot(xb - xa, yb - ya)
    s = np.linspace(0.0, d, max(4, int(d / STEP_M)) + 1)[1:-1]
    keep = (s > END_IGNORE_M) & (s < d - END_IGNORE_M)
    s = s[keep] if keep.any() else s
    t = s / d
    x, y = xa + (xb - xa) * t, ya + (yb - ya) * t
    terrain = hm.sample(x, y)
    za, zb = float(hm.sample(xa, ya)) + mast_a, float(hm.sample(xb, yb)) + mast_b
    chord = za + (zb - za) * t - s * (d - s) / (2.0 * MOON_RADIUS_M)
    clearance = chord - terrain
    i = int(np.argmin(clearance))
    return dict(clear=bool(clearance[i] > 0.0), min_clearance_m=round(float(clearance[i]), 1), at_m=round(float(s[i]), 0),
                distance_m=round(d, 0), point=[round(float(x[i]), 1), round(float(y[i]), 1), round(float(terrain[i]), 1)])


def to_table(x, y, h, h_floor):
    """Map metres -> table metres. Aurora sits on the operator's left, the summit on the right: table X = -(y - yc),
    table Z = -(x - xc) (map +x comes toward the operator), table Y = relief base + (h - h_floor) * VE, all * SCALE.
    The relief's own base (y = 0 here) is placed on the table by the build."""
    xc, yc = sum(REGION_X_M) / 2, sum(REGION_Y_M) / 2
    return (-(y - yc) * SCALE, (h - h_floor) * SCALE * VERTICAL_EXAGGERATION, -(x - xc) * SCALE)


def _pad_candidates(hm, road):
    radius = int(PAD_SEARCH_RADIUS_M / hm.mpp)
    seen, out = set(), []
    for i in range(0, len(road), 4):
        x, y = road[i][0], road[i][1]
        c, r = int(round((x - hm.ox) / hm.mpp)), int(round((hm.oy - y) / hm.mpp))
        r0, c0 = max(0, r - radius), max(0, c - radius)
        window = hm.h[r0:r + radius + 1, c0:c + radius + 1]
        rr, cc = np.mgrid[r0:r0 + window.shape[0], c0:c0 + window.shape[1]]
        masked = np.where((rr - r) ** 2 + (cc - c) ** 2 <= radius * radius, window, -1e9)
        kr, kc = np.unravel_index(int(np.argmax(masked)), window.shape)
        px, py = hm.ox + (c0 + kc) * hm.mpp, hm.oy - (r0 + kr) * hm.mpp
        if (px, py) in seen:
            continue
        seen.add((px, py))
        out.append(dict(x=px, y=py, h=float(hm.h[r0 + kr, c0 + kc]), road_m=float(road[i][3]), road_index=i,
                        offset_m=round(math.hypot(px - x, py - y), 0)))
    return out


def compute():
    """The full route-simulator data set (deterministic)."""
    hm = Heightmap()
    lola = json.loads((LOLA / "lola_terrain.json").read_text(encoding="utf-8"))
    sites = lola["sites"]
    aurora = (sites["aurora"]["x_m"], sites["aurora"]["y_m"])
    summit = (sites["malapert_summit"]["x_m"], sites["malapert_summit"]["y_m"])
    road = lola["routes"]["relay_road"]["points"]
    road_len = float(road[-1][3])
    cands = _pad_candidates(hm, road)
    n = len(cands)
    pts = [(c["x"], c["y"]) for c in cands]
    from_a = [line_of_sight(hm, aurora, p, MAST_M["aurora"], MAST_M["repeater"]) for p in pts]
    to_s = [line_of_sight(hm, p, summit, MAST_M["repeater"], MAST_M["summit"]) for p in pts]
    pair = {}
    best = None
    for i in range(n):
        if not from_a[i]["clear"]:
            continue
        for j in range(i + 1, n):
            if cands[j]["road_m"] - cands[i]["road_m"] < MIN_HOP_ROAD_M or cands[i]["road_m"] < MIN_HOP_ROAD_M:
                continue
            if (i, j) not in pair:
                pair[(i, j)] = line_of_sight(hm, pts[i], pts[j], MAST_M["repeater"], MAST_M["repeater"])
            if not pair[(i, j)]["clear"]:
                continue
            for k in range(j + 1, n):
                if cands[k]["road_m"] - cands[j]["road_m"] < MIN_HOP_ROAD_M or road_len - cands[k]["road_m"] < MIN_HOP_ROAD_M:
                    continue
                if not to_s[k]["clear"]:
                    continue
                if (j, k) not in pair:
                    pair[(j, k)] = line_of_sight(hm, pts[j], pts[k], MAST_M["repeater"], MAST_M["repeater"])
                if not pair[(j, k)]["clear"]:
                    continue
                score = min(from_a[i]["min_clearance_m"], pair[(i, j)]["min_clearance_m"], pair[(j, k)]["min_clearance_m"], to_s[k]["min_clearance_m"])
                if best is None or score > best[0]:
                    best = (score, i, j, k)
    if best is None:
        raise RuntimeError("no clear three-repeater chain along the surveyed road")
    _, i, j, k = best
    chosen = [cands[i], cands[j], cands[k]]
    nodes = [("Aurora", aurora, MAST_M["aurora"])] + [(f"R{q + 1}", (c["x"], c["y"]), MAST_M["repeater"]) for q, c in enumerate(chosen)] + [("Summit", summit, MAST_M["summit"])]
    hops = []
    for a in range(len(nodes)):
        for b in range(a + 1, len(nodes)):
            res = line_of_sight(hm, nodes[a][1], nodes[b][1], nodes[a][2], nodes[b][2])
            hops.append(dict(frm=nodes[a][0], to=nodes[b][0], chain_link=(b == a + 1), **res))
    # straight lines between road-level points (3 m masts) that a ridge blocks: the S11 "drawn over a ridge" example
    blocked = []
    for p in range(0, len(road), 6):
        for q in range(p + 6, len(road), 6):
            span = road[q][3] - road[p][3]
            if not 20000.0 <= span <= 45000.0:
                continue
            res = line_of_sight(hm, (road[p][0], road[p][1]), (road[q][0], road[q][1]), MAST_M["repeater"], MAST_M["repeater"])
            if not res["clear"]:
                blocked.append(dict(frm_road_m=road[p][3], to_road_m=road[q][3], frm=[road[p][0], road[p][1]], to=[road[q][0], road[q][1]], **res))
    blocked.sort(key=lambda r: r["min_clearance_m"])
    examples, used = [], []
    for r in blocked:
        if all(abs(r["frm_road_m"] - u) > 30000.0 for u in used):
            examples.append(r)
            used.append(r["frm_road_m"])
        if len(examples) == 3:
            break
    # the same chain with one pad moved down to the road point it was sited from (an obstructed site to correct)
    alternatives = []
    for q, c in enumerate(chosen):
        rp = road[c["road_index"]]
        before = nodes[q]
        after = nodes[q + 2]
        legs = [line_of_sight(hm, before[1], (rp[0], rp[1]), before[2], MAST_M["repeater"]),
                line_of_sight(hm, (rp[0], rp[1]), after[1], MAST_M["repeater"], after[2])]
        alternatives.append(dict(pad=f"R{q + 1}", road_point=[rp[0], rp[1], rp[2]], road_m=rp[3],
                                 legs=[dict(frm=before[0], to=f"R{q + 1} (road)", **legs[0]), dict(frm=f"R{q + 1} (road)", to=after[0], **legs[1])]))
    direct = line_of_sight(hm, aurora, summit, MAST_M["aurora"], MAST_M["summit"])
    return dict(hm=hm, aurora=aurora, summit=summit, road=road, road_length_m=road_len, pads=chosen, hops=hops,
                blocked_examples=examples, road_level_alternatives=alternatives, direct=direct, candidates=n, credit=lola["credit_line"], credit_short=lola["credit_line_short"])


def main():
    data = compute()
    print(f"candidates {data['candidates']}; road {data['road_length_m'] / 1000:.1f} km")
    for c in data["pads"]:
        print(f"pad road {c['road_m'] / 1000:.1f} km, {c['offset_m']:.0f} m off the road, height {c['h']:.0f} m")
    for h in data["hops"]:
        print(f"{h['frm']:>6} -> {h['to']:<6} {'link ' if h['chain_link'] else 'skip '} {'clear  ' if h['clear'] else 'BLOCKED'} "
              f"{h['distance_m'] / 1000:6.1f} km, min clearance {h['min_clearance_m']:8.1f} m at {h['at_m'] / 1000:.1f} km")
    for b in data["blocked_examples"]:
        print(f"blocked road line {b['frm_road_m'] / 1000:.1f} -> {b['to_road_m'] / 1000:.1f} km: ridge {-b['min_clearance_m']:.0f} m above the line at {b['point']}")
    for alt in data["road_level_alternatives"]:
        print(f"{alt['pad']} at road level ({alt['road_point'][2]:.0f} m): " + "; ".join(
            f"{l['frm']} -> {l['to']} {'clear' if l['clear'] else 'BLOCKED'} ({l['min_clearance_m']} m)" for l in alt["legs"]))
    d = data["direct"]
    print(f"direct Aurora -> summit: {'clear' if d['clear'] else 'blocked'}, min clearance {d['min_clearance_m']} m at {d['at_m'] / 1000:.1f} km")


if __name__ == "__main__":
    main()
