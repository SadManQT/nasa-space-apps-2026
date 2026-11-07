#!/usr/bin/env python3
"""Survey the Chapter 4 cold-trap road on the real LOLA terrain for EN_ColdTrap (board M3-4A). No credits.

    python3 production/tools/coldtrap_survey.py            # writes production/models/ch04/coldtrap_survey.json

Reuses make_terrain.py (M1-34): the same 20 m PGDA product 90 grid, slope rule and least-cost search that
produced production/terrain/routes.json, but keeps every 20 m road cell instead of the 320 m thinning, then:

  * line of sight along the road, true scale on the curved Moon: from Aurora's 10 m mast, walk the road and put a
    beacon (PR_SurveyBeacon, antenna 1.8 m) on the last cell the current relay still sees before the first blind
    one ("Beacon before the blind corner", EX-CH04-S04); the receiver is the rover's antenna (3.0 m);
  * the three 100 m playable segments of LOC-09, centred on the beacon corners;
  * the LOC-10 vault shelf: the 20 x 15 m footprint at the cold-trap site (M1-82 placement), its slope and its depth
    inside the permanently shadowed region.

Every number this writes is Computed from LOLA; the game's P-07 numbers (route B 30 + 30 of 100, 12 deg against
the 15 deg limit) stay canon from game-design/08_PUZZLE_DESIGNS.md.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_terrain as mt  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "production/models/ch04/coldtrap_survey.json"
MAST_M = {"aurora": 10.0, "beacon": 5.0, "rover": 3.0, "suit": 1.5}  # beacon: PR_SurveyBeacon on a 5 m mast (decision 9)
SEGMENT_M = 100.0
END_IGNORE_M = 30.0  # the chord ends sit on the antenna tips; skip the cells under them


def road_cells():
    """The cold-trap road on the 20 m grid, every cell (the routes.json polyline is thinned to 320 m)."""
    route = next(r for r in mt.CFG["routes"] if r["id"] == "cold_trap_road")
    sites = mt.load_sites()["sites"]
    a, b = sites["aurora"], sites["cold_trap"]
    length = math.hypot(b["x_m"] - a["x_m"], b["y_m"] - a["y_m"])
    cx, cy = (a["x_m"] + b["x_m"]) / 2, (a["y_m"] + b["y_m"]) / 2
    margin = float(route["corridor_half_width_m"])
    h, geo = mt.window_m(route["grid"], cx, cy, length + 2 * margin)
    h = mt.fill_nan(h)
    gm = geo["mpp"]
    cols, rows = np.meshgrid(np.arange(h.shape[1]), np.arange(h.shape[0]))
    xg, yg = geo["origin_x_m"] + cols * gm, geo["origin_y_m"] - rows * gm
    ux, uy = (b["x_m"] - a["x_m"]) / length, (b["y_m"] - a["y_m"]) / length
    hs = np.where(np.abs(-(xg - a["x_m"]) * uy + (yg - a["y_m"]) * ux) <= margin, h, 1.0e6)
    psr, _ = mt.window_m("pgda90_20mpp_psr", cx, cy, length + 2 * margin)
    psr = np.nan_to_num(psr) > 0.5
    bb = sites["cold_trap"]["psr_bbox_xy_m"]
    goals = psr & (xg >= bb[0] - gm) & (xg <= bb[1] + gm) & (yg >= bb[2] - gm) & (yg <= bb[3] + gm)

    def px(site):
        return int(round((geo["origin_y_m"] - site["y_m"]) / gm)), int(round((site["x_m"] - geo["origin_x_m"]) / gm))

    path, _ = mt.dijkstra_route(hs, gm, px(a), goals, route["slope_limit_deg"])
    prof = mt.path_profile(path, h, gm, geo, route["slope_limit_deg"])
    return prof, h, geo, psr, sites


class Grid:
    """Bilinear sampler over one window (map metres)."""

    def __init__(self, h, geo):
        self.h, self.g = h, geo

    def __call__(self, x, y):
        g, h = self.g, self.h
        c = (np.asarray(x, float) - g["origin_x_m"]) / g["mpp"]
        r = (g["origin_y_m"] - np.asarray(y, float)) / g["mpp"]
        c0 = np.clip(np.floor(c).astype(int), 0, h.shape[1] - 2)
        r0 = np.clip(np.floor(r).astype(int), 0, h.shape[0] - 2)
        fc, fr = np.clip(c - c0, 0, 1), np.clip(r - r0, 0, 1)
        return (h[r0, c0] * (1 - fc) * (1 - fr) + h[r0, c0 + 1] * fc * (1 - fr) + h[r0 + 1, c0] * (1 - fc) * fr + h[r0 + 1, c0 + 1] * fc * fr)


def clearance(z, a, b, mast_a, mast_b, step=10.0):
    """Lowest clearance (m) of the chord between two antenna tips over the curved terrain."""
    (xa, ya), (xb, yb) = a, b
    d = math.hypot(xb - xa, yb - ya)
    if d < 2 * END_IGNORE_M:
        return 99.0
    s = np.arange(END_IGNORE_M, d - END_IGNORE_M, step)
    if s.size == 0:
        return 99.0
    t = s / d
    terrain = z(xa + (xb - xa) * t, ya + (yb - ya) * t)
    za, zb = float(z(xa, ya)) + mast_a, float(z(xb, yb)) + mast_b
    chord = za + (zb - za) * t - s * (d - s) / (2.0 * mt.R_MOON)
    return float(np.min(chord - terrain))


def beacon_chain(pts, z, site, every=2):
    """Fewest beacons on the road so that Aurora's mast -> B1 -> ... -> Bn -> the vault shelf is an unbroken chain of
    clear chords (breadth-first over candidate road cells every 40 m); among the shortest chains, the one whose
    weakest link has the most clearance. Each beacon's blind corner is the first road cell past it that the
    previous relay cannot see from the rover's antenna."""
    cand = list(range(1, len(pts), every))
    nodes = [("aurora", 0, (pts[0][0], pts[0][1]), MAST_M["aurora"])] + [("beacon", i, (pts[i][0], pts[i][1]), MAST_M["beacon"]) for i in cand]
    end = ("shelf", len(pts), (site["x_m"], site["y_m"]), MAST_M["suit"])
    best = {0: (0, 1e9, None)}  # node -> (hops, weakest clearance, previous node)
    frontier = [0]
    found = None
    while frontier and found is None:
        nxt = {}
        for a in frontier:
            hops, weak, _ = best[a]
            ca = nodes[a]
            ce = clearance(z, ca[2], end[2], ca[3], end[3])
            if ce > 0 and a:
                cand_end = (hops, min(weak, ce), a)
                if found is None or cand_end[1] > found[1]:
                    found = cand_end
            for b in range(a + 1, len(nodes)):
                c = clearance(z, ca[2], nodes[b][2], ca[3], nodes[b][3])
                if c <= 0:
                    continue
                cand_b = (hops + 1, min(weak, c), a)
                if b not in best and (b not in nxt or cand_b[1] > nxt[b][1]):
                    nxt[b] = cand_b
        best.update(nxt)
        frontier = list(nxt)
        if len(best) and min(v[0] for v in best.values()) > 12:
            raise RuntimeError("no chain within 12 beacons")
    if found is None:
        raise RuntimeError("no chain reaches the shelf")
    chain = []
    k = found[2]
    while k:
        chain.append(k)
        k = best[k][2]
    chain.reverse()
    relays = [dict(kind="aurora", index=0, xy=nodes[0][2], mast=MAST_M["aurora"])]
    for k in chain:
        prev = relays[-1]
        idx = nodes[k][1]
        j = idx + 1
        while j < len(pts) and clearance(z, prev["xy"], (pts[j][0], pts[j][1]), prev["mast"], MAST_M["rover"]) > 0.0:
            j += 1
        relays.append(dict(kind="beacon", index=idx, xy=nodes[k][2], mast=MAST_M["beacon"], blind_from=min(j, len(pts) - 1)))
    return relays, round(found[1], 1)


def sun_state(x, y, h0, h20, geo20, scene="EX-CH04-S04"):
    """Lit / dark / partial for the dated Sun row of a scene at map (x, y): the terrain horizon at the Sun's azimuth
    from the 20 m road grid (to its edge) and make_terrain's 40 m / 80 m legs (to 100 km), against the Sun's
    elevation and its 0.27 deg radius."""
    rows = json.loads((mt.GAME_LOLA / "sun_positions.json").read_text())["scene_lighting"]
    row = next(r for r in rows if r["scene"] == scene)
    az, el = row["sun_az_deg"], row["sun_el_deg"]
    geo = dict(geo20, cols=h20.shape[1], rows=h20.shape[0])
    hz = np.maximum(mt.horizon_mask(x, y, h0), mt.horizon_mask_hero(x, y, h0, h20, geo))
    horizon = float(np.interp(az % 360.0, np.arange(361.0), np.r_[hz, hz[0]]))
    margin = el - horizon
    state = "lit" if margin > mt.SUN_RADIUS_DEG else ("dark" if margin < -mt.SUN_RADIUS_DEG else "partial")
    return dict(scene=scene, utc=row["utc"], sun_az_deg=az, sun_el_deg=el, terrain_horizon_deg=round(horizon, 2), sun_state=state)


def coverage(pts, z, relays):
    """Fraction of road cells whose rover antenna sees at least one relay of the chain."""
    seen = 0
    for p in pts:
        if any(clearance(z, r["xy"], (p[0], p[1]), r["mast"], MAST_M["rover"]) > 0 for r in relays):
            seen += 1
    return round(seen / len(pts), 3)


def main():
    prof, h, geo, psr, sites = road_cells()
    z = Grid(h, geo)
    pts = prof["points"]
    site = sites["cold_trap"]
    relays, weakest = beacon_chain(pts, z, site)
    beacons = []
    for n, r in enumerate(relays[1:], 1):
        p = pts[r["index"]]
        prev = relays[n - 1]
        seg = [q for q in pts if abs(q[3] - p[3]) <= SEGMENT_M / 2]
        beacons.append(dict(id=f"B{n}", road_index=r["index"], x_m=p[0], y_m=p[1], height_m=p[2], road_distance_m=p[3],
                            local_slope_deg=p[4], blind_corner_distance_m=pts[r["blind_from"]][3],
                            light=sun_state(p[0], p[1], p[2], h, geo),
                            link_back=dict(to=prev["kind"] if prev["kind"] == "aurora" else f"B{n - 1}",
                                           clearance_m=round(clearance(z, prev["xy"], r["xy"], prev["mast"], MAST_M["beacon"]), 1),
                                           distance_m=round(math.hypot(r["xy"][0] - prev["xy"][0], r["xy"][1] - prev["xy"][1]), 0)),
                            segment=dict(from_m=seg[0][3], to_m=seg[-1][3], max_slope_deg=round(max(q[4] for q in seg), 2),
                                         climb_m=round(seg[-1][2] - seg[0][2], 1))))
    last = relays[-1]
    shelf_link = clearance(z, last["xy"], (site["x_m"], site["y_m"]), last["mast"], MAST_M["suit"])
    direct = clearance(z, relays[0]["xy"], (site["x_m"], site["y_m"]), MAST_M["aurora"], MAST_M["suit"])
    # vault shelf: 20 x 15 m at the site on the 10 m cold-trap grid (the tiles' own field)
    meta = json.loads((mt.GAME_LOLA / "cold_trap/heightmap_10m.json").read_text())
    raw = np.fromfile(mt.GAME_LOLA / "cold_trap/heightmap_10m.r16", dtype="<u2").reshape(meta["rows"], meta["columns"])
    h10 = meta["z_min_m"] + raw.astype(float) * (meta["z_max_m"] - meta["z_min_m"]) / 65535.0
    z10 = Grid(h10, dict(origin_x_m=meta["origin_x_m"], origin_y_m=meta["origin_y_m"], mpp=10.0))
    xs, ys = np.meshgrid(np.linspace(-10, 10, 9) + site["x_m"], np.linspace(-7.5, 7.5, 7) + site["y_m"])
    hz = z10(xs, ys)
    A = np.c_[xs.ravel() - site["x_m"], ys.ravel() - site["y_m"], np.ones(xs.size)]
    coef, *_ = np.linalg.lstsq(A, hz.ravel(), rcond=None)
    shelf_slope = math.degrees(math.atan(math.hypot(coef[0], coef[1])))
    psr_edge = road_end = pts[-1]
    dist_into_psr = math.hypot(site["x_m"] - road_end[0], site["y_m"] - road_end[1])
    out = dict(
        about="EN_ColdTrap survey (M3-4A), Computed from NASA LRO LOLA (PGDA product 90, 20 m road grid; 10 m cold_trap region for the shelf) by production/tools/coldtrap_survey.py. Beacon antennas on 5 m masts (1.8 m tripods would need five beacons), rover antenna 3.0 m, Aurora mast 10 m, suit radio 1.5 m; chords true scale over the 1,737.4 km sphere.",
        road=dict(length_m=prof["length_m"], max_slope_deg=prof["max_slope_deg"], descent_m=prof["descent_m"], climb_m=prof["climb_m"],
                  cells=len(pts), ends_at_psr_edge=dict(x_m=road_end[0], y_m=road_end[1], height_m=road_end[2])),
        beacons=beacons,
        chain_weakest_link_clearance_m=weakest,
        road_coverage_fraction=coverage(pts, z, relays),
        road_coverage_aurora_only=coverage(pts, z, relays[:1]),
        shelf_link=dict(from_relay=f"B{len(beacons)}" if beacons else "aurora", clearance_m=round(shelf_link, 1)),
        aurora_to_shelf_direct_clearance_m=round(direct, 1),
        vault_shelf=dict(x_m=site["x_m"], y_m=site["y_m"], height_m=round(float(z10(site["x_m"], site["y_m"])), 1), size_m=[20.0, 15.0],
                         fitted_slope_deg=round(shelf_slope, 2), relief_m=round(float(hz.max() - hz.min()), 2),
                         walk_from_road_end_m=round(dist_into_psr, 0), below_road_end_m=round(road_end[2] - float(z10(site["x_m"], site["y_m"])), 1),
                         light=sun_state(site["x_m"], site["y_m"], site["height_m"], h, geo, "EX-CH04-S06")),
        m182_loc09_corner=dict(x_m=-4850.0, y_m=-10970.0, sees_B2=False, light=sun_state(-4850.0, -10970.0, 1272.9, h, geo)),
        polyline_every_100m=[[round(q[0], 1), round(q[1], 1), round(q[2], 1), q[3], q[4]] for q in pts[::5]] + [pts[-1]],
        road_cells_20m=[[round(q[0], 1), round(q[1], 1), round(q[2], 1), q[3], q[4]] for q in pts],
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, indent=1), encoding="utf-8")
    print(json.dumps({k: v for k, v in out.items() if k != "polyline_every_100m"}, indent=1))


if __name__ == "__main__":
    main()
