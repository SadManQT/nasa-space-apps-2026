#!/usr/bin/env python3
"""Source-data mesh audit for Blender 5.2 GLBs.

  blender -b --factory-startup -P production/tools/mesh_audit.py -- \
      <file.glb> [<file.glb> ...] --report <out.md> [--json <out.json>]
  blender -b --factory-startup -P production/tools/mesh_audit.py -- --selftest

The audit intentionally reads imported source data only.  It never writes an input GLB.
"""
import argparse
import json
import math
import os
import re
import sys
import hashlib
import struct
import tempfile
from datetime import datetime, timezone
from collections import defaultdict
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

# Named quality thresholds.  Keep these visible so a review can tell what PASS means.
ISLAND_FRACTION = 0.01
MIN_ISLAND_VERTICES = 3
ISLAND_GAP_M = 0.002
FACE_MATERIALS = {"LipInner", "MouthInterior", "Teeth", "Gums", "Tongue", "Eyelid"}
ZERO_AREA_M2 = 1.0e-10
SLIVER_ANGLE_DEG = 2.0
DUPLICATE_TOLERANCE_M = 1.0e-6
FLIPPED_NORMAL_DOT = -0.5
UV_AREA_EPS = 1.0e-10
UV_OVERLAP_GRID = 64
UV_OVERLAP_EPS = 1.0e-8
STRETCH_WARN_RATIO = 4.0
DENSITY_WARN_SPREAD = 2.0
UNWEIGHTED_EPS = 1.0e-5
MAX_INFLUENCES = 4
WEIGHT_SUM_TOLERANCE = 0.01
JOINT_RADIUS_M = 0.035
SHAPE_MOVE_DEFECT_M = 0.001
HEAD_LOWER_FRACTION = 0.78
SYMMETRY_MATCH_TOLERANCE_M = 0.003
SYMMETRY_WARN_MM = 2.0
LOOP_MATCH_WARN_DEG = 2.0
LOOP_MATCH_FAIL_DEG = 5.0
LOOP_MATCH_WARN_M = 0.001
LOOP_MATCH_FAIL_M = 0.005
LOOP_MATCH_SCALE_EPS = 0.001
WORST_REGION_COUNT = 5

STATUS_ORDER = {"PASS": 0, "WARN": 1, "FAIL": 2, "SKIP": 0}


def v3(v):
    return [round(float(v.x), 6), round(float(v.y), 6), round(float(v.z), 6)]


def vec_dict(v):
    return {"x": round(float(v.x), 6), "y": round(float(v.y), 6), "z": round(float(v.z), 6)}


def pct(values, p):
    if not values:
        return None
    xs = sorted(values)
    if len(xs) == 1:
        return float(xs[0])
    at = (len(xs) - 1) * p / 100.0
    lo, hi = int(math.floor(at)), int(math.ceil(at))
    if lo == hi:
        return float(xs[lo])
    return float(xs[lo] + (xs[hi] - xs[lo]) * (at - lo))


def check(status, detail, **extra):
    d = {"status": status, "detail": detail}
    d.update(extra)
    return d


def overall_status(checks):
    statuses = [x.get("status", "PASS") for x in checks.values()]
    return max(statuses, key=lambda s: STATUS_ORDER.get(s, 0)) if statuses else "PASS"


def world_normal(obj, normal):
    try:
        n = obj.matrix_world.to_3x3().inverted().transposed() @ normal
    except Exception:
        n = obj.matrix_world.to_3x3() @ normal
    return n.normalized() if n.length else Vector((0, 0, 0))


def world_points(obj, mesh):
    return [obj.matrix_world @ v.co for v in mesh.vertices]


def face_area(points, ids):
    if len(ids) < 3:
        return 0.0
    a = points[ids[0]]
    return sum((points[ids[i]] - a).cross(points[ids[i + 1]] - a).length * 0.5
               for i in range(1, len(ids) - 1))


def polygon_uv_area(uvs):
    if len(uvs) < 3:
        return 0.0
    return abs(sum(uvs[i].x * uvs[(i + 1) % len(uvs)].y -
                   uvs[(i + 1) % len(uvs)].x * uvs[i].y for i in range(len(uvs))) * 0.5)


def min_face_angle(points, ids):
    if len(ids) < 3:
        return 180.0
    result = 180.0
    for i, idx in enumerate(ids):
        prev = points[ids[i - 1]] - points[idx]
        nxt = points[ids[(i + 1) % len(ids)]] - points[idx]
        if prev.length == 0 or nxt.length == 0:
            return 0.0
        c = max(-1.0, min(1.0, prev.normalized().dot(nxt.normalized())))
        result = min(result, math.degrees(math.acos(c)))
    return result


def face_triangles(points, ids):
    if len(ids) < 3:
        return []
    a = points[ids[0]]
    return [(a, points[ids[i]], points[ids[i + 1]]) for i in range(1, len(ids) - 1)]


def tri_area_2d(a, b, c):
    return abs((b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])) * 0.5


def tri_bbox(t):
    return min(p[0] for p in t), min(p[1] for p in t), max(p[0] for p in t), max(p[1] for p in t)


def orient2(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def point_in_tri(p, t):
    signs = [orient2(t[i], t[(i + 1) % 3], p) for i in range(3)]
    return all(x >= -UV_OVERLAP_EPS for x in signs) or all(x <= UV_OVERLAP_EPS for x in signs)


def proper_segment_intersection(a, b, c, d):
    ab_c, ab_d = orient2(a, b, c), orient2(a, b, d)
    cd_a, cd_b = orient2(c, d, a), orient2(c, d, b)
    return ((ab_c > UV_OVERLAP_EPS and ab_d < -UV_OVERLAP_EPS) or
            (ab_c < -UV_OVERLAP_EPS and ab_d > UV_OVERLAP_EPS)) and \
           ((cd_a > UV_OVERLAP_EPS and cd_b < -UV_OVERLAP_EPS) or
            (cd_a < -UV_OVERLAP_EPS and cd_b > UV_OVERLAP_EPS))


def triangles_overlap(a, b):
    for tri in (a, b):
        for i in range(3):
            p, q = tri[i], tri[(i + 1) % 3]
            nx, ny = p[1] - q[1], q[0] - p[0]
            length = math.hypot(nx, ny)
            if length <= UV_AREA_EPS:
                continue
            aa = [(v[0] * nx + v[1] * ny) / length for v in a]
            bb = [(v[0] * nx + v[1] * ny) / length for v in b]
            if min(max(aa), max(bb)) - max(min(aa), min(bb)) <= UV_OVERLAP_EPS:
                return False
    return True


def approximate_uv_overlaps(triangles):
    """Find overlapping UV triangles with a bounded grid; shared edges are ignored."""
    buckets = defaultdict(list)
    for idx, tri in enumerate(triangles):
        x0, y0, x1, y1 = tri_bbox(tri[1])
        gx0, gy0 = math.floor(x0 * UV_OVERLAP_GRID), math.floor(y0 * UV_OVERLAP_GRID)
        gx1, gy1 = math.floor(x1 * UV_OVERLAP_GRID), math.floor(y1 * UV_OVERLAP_GRID)
        cells = (gx1 - gx0 + 1) * (gy1 - gy0 + 1)
        if cells > 128:
            # Very large islands: a few representative cells keep runtime bounded.
            cells_to_use = {(math.floor(((x0 + x1) * 0.5) * UV_OVERLAP_GRID),
                             math.floor(((y0 + y1) * 0.5) * UV_OVERLAP_GRID)),
                            (gx0, gy0), (gx1, gy1)}
        else:
            cells_to_use = ((x, y) for x in range(gx0, gx1 + 1) for y in range(gy0, gy1 + 1))
        for cell in cells_to_use:
            if len(buckets[cell]) < 160:
                buckets[cell].append(idx)
    candidates = set()
    for ids in buckets.values():
        for i in range(len(ids)):
            for j in range(i + 1, len(ids)):
                a, b = ids[i], ids[j]
                if triangles[a][0] != triangles[b][0] and triangles[a][2] == triangles[b][2]:
                    candidates.add((min(a, b), max(a, b)))
    overlaps = []
    for a, b in candidates:
        if triangles_overlap(triangles[a][1], triangles[b][1]):
            overlaps.append((a, b))
    faces = sorted({triangles[i][0] for pair in overlaps for i in pair})
    return {"triangle_pairs": len(overlaps), "faces": len(faces), "face_indices": faces[:50]}


def material_image_info(mat):
    textures = []
    base = None
    if mat and mat.use_nodes and mat.node_tree:
        nodes = mat.node_tree.nodes
        for node in nodes:
            if node.type != "TEX_IMAGE" or not node.image:
                continue
            img = node.image
            item = {"name": img.name, "size": [int(img.size[0]), int(img.size[1])],
                    "path": bpy.path.abspath(img.filepath) if img.filepath else ""}
            if item not in textures:
                textures.append(item)
            for link in mat.node_tree.links:
                if link.from_node == node and link.to_node.type == "BSDF_PRINCIPLED" and \
                   link.to_socket.name == "Base Color":
                    base = item
    return {"name": mat.name if mat else "<none>", "textures": textures,
            "base_color": base}


def material_report(obj):
    mats = []
    seen = set()
    for mat in obj.data.materials:
        key = mat.name if mat else "<none>"
        if key not in seen:
            mats.append(material_image_info(mat))
            seen.add(key)
    return mats


def material_name(mesh, poly):
    mat = mesh.materials[poly.material_index] if poly.material_index < len(mesh.materials) else None
    return re.sub(r"\.\d{3}$", "", mat.name) if mat else "<none>"


def face_region(obj, points):
    """Bone-based head region; height fallback only for unrigged test meshes."""
    arm = armature_for_mesh(obj)
    head = next((b for b in arm.data.bones if b.name.split(":")[-1].lower() == "head"), None) if arm else None
    if head:
        origin = arm.matrix_world @ head.head_local
        return origin.z, origin.x, "Head bone origin"
    lo, hi = min(p.z for p in points), max(p.z for p in points)
    return lo + (hi - lo) * HEAD_LOWER_FRACTION, 0.0, "height fallback (no Head bone)"


def topology(obj, points):
    """Analysis-only weld of glTF attribute splits, preserving cuts that deform apart.

    The imported mesh, UVs, normals, weights and morphs are never modified. Quantised
    positions alone would seal the intentional lip cut; morph deltas distinguish it.
    """
    mesh = obj.data
    groups = defaultdict(list)
    for i, point in enumerate(points):
        groups[tuple(round(c / DUPLICATE_TOLERANCE_M) for c in point)].append(i)
    remap = list(range(len(points)))
    keys = mesh.shape_keys.key_blocks[1:] if mesh.shape_keys else []
    linear = obj.matrix_world.to_3x3()
    for ids in groups.values():
        if len(ids) < 2:
            continue
        signatures = {}
        for i in ids:
            morph = tuple(round(c / DUPLICATE_TOLERANCE_M) for key in keys
                          for c in linear @ (key.data[i].co - mesh.vertices[i].co))
            # UV/hard-normal seams merge; vertices with different deformation do not.
            weights = tuple(sorted((g.group, round(g.weight, 6)) for g in mesh.vertices[i].groups
                                   if g.weight > UNWEIGHTED_EPS))
            remap[i] = signatures.setdefault((morph, weights), i)
    edge_faces = defaultdict(list)
    directions = defaultdict(list)
    for fi, poly in enumerate(mesh.polygons):
        ids = [remap[i] for i in poly.vertices]
        for a, b in zip(ids, ids[1:] + ids[:1]):
            if a == b:
                continue
            edge = tuple(sorted((a, b)))
            edge_faces[edge].append(fi)
            directions[edge].append((fi, a < b))
    for edge in mesh.edges:
        a, b = (remap[i] for i in edge.vertices)
        if a != b:
            edge_faces.setdefault(tuple(sorted((a, b))), [])
    return remap, edge_faces, directions


def boundary_loops(points, edge_faces):
    """Connected boundary chains, including branched/open chains, with exact length."""
    adjacency = defaultdict(set)
    for (a, b), fs in edge_faces.items():
        if len(fs) == 1:
            adjacency[a].add(b)
            adjacency[b].add(a)
    seen, loops = set(), []
    for root in sorted(adjacency):
        if root in seen:
            continue
        todo, ids = [root], set()
        while todo:
            v = todo.pop()
            if v in ids:
                continue
            ids.add(v)
            todo.extend(adjacency[v] - ids)
        seen.update(ids)
        edges = sorted({tuple(sorted((v, n))) for v in ids for n in adjacency[v]})
        centre = sum((points[i] for i in ids), Vector()) / len(ids)
        loops.append({"vertices": len(ids), "edge_count": len(edges),
                      "closed": all(len(adjacency[i]) == 2 for i in ids),
                      "length_m": round(sum((points[a] - points[b]).length for a, b in edges), 6),
                      "centre": vec_dict(centre), "edges": edges})
    return loops


def component_report(mesh, points, edge_faces, remap=None):
    remap = remap if remap is not None else list(range(len(points)))
    adjacency = defaultdict(set)
    for a, b in edge_faces:
        adjacency[a].add(b)
        adjacency[b].add(a)
    faces_by_vertex = defaultdict(list)
    for fi, poly in enumerate(mesh.polygons):
        for vi in poly.vertices:
            faces_by_vertex[remap[vi]].append(fi)
    seen, components = set(), []
    for root in sorted(set(remap)):
        if root in seen:
            continue
        todo, ids = [root], []
        seen.add(root)
        while todo:
            v = todo.pop()
            ids.append(v)
            for n in adjacency[v]:
                if n not in seen:
                    seen.add(n)
                    todo.append(n)
        fids = sorted({f for v in ids for f in faces_by_vertex[v]})
        lo = Vector(tuple(min(points[v][axis] for v in ids) for axis in range(3)))
        hi = Vector(tuple(max(points[v][axis] for v in ids) for axis in range(3)))
        components.append({"vertices": len(ids), "faces": len(fids), "size_m": round((hi - lo).length, 6),
                           "centre": vec_dict(sum((points[v] for v in ids), Vector()) / len(ids)),
                           "bounds_min": v3(lo), "bounds_max": v3(hi),
                           "materials": sorted({material_name(mesh, mesh.polygons[f]) for f in fids}),
                           "vertex_indices": sorted(ids), "face_indices": fids})
    components.sort(key=lambda x: (-x["vertices"], x["vertex_indices"][0]))
    limit = max(MIN_ISLAND_VERTICES, len(set(remap)) * ISLAND_FRACTION)
    for i, c in enumerate(components):
        # A detached triangle is still an island in an eight-vertex fixture. Ranking,
        # not equality with the largest count, handles equally sized components.
        c["small_island"] = i > 0 and c["vertices"] <= limit
    return components


def geometry_report(obj):
    mesh = obj.data
    points = world_points(obj, mesh)
    remap, edge_faces, directions = topology(obj, points)
    components = component_report(mesh, points, edge_faces, remap)
    if not points:
        return {"object": obj.name, "checks": {"geometry": check("FAIL", "empty mesh")}}
    neck_z, _, _ = face_region(obj, points)
    character = armature_for_mesh(obj) is not None
    expected_faces = {p.index for p in mesh.polygons
                      if character and material_name(mesh, p) in FACE_MATERIALS
                      and all(points[i].z >= neck_z for i in p.vertices)}
    body = components[0] if components else None
    body_faces = [tuple(mesh.polygons[i].vertices) for i in body["face_indices"]] if body else []
    tree = BVHTree.FromPolygons(points, body_faces, all_triangles=False) if body_faces else None
    flagged_islands = []
    for i, c in enumerate(components):
        expected = bool(c["face_indices"]) and all(f in expected_faces for f in c["face_indices"])
        c["expected_face_part"] = expected
        c["gap_m"] = 0.0
        if i and tree and not expected:
            distances, outside = [], []
            for vi in c["vertex_indices"]:
                nearest, normal, _, distance = tree.find_nearest(points[vi])
                if nearest is not None:
                    distances.append(distance)
                    outside.append((points[vi] - nearest).dot(normal) > ISLAND_GAP_M)
            c["gap_m"] = min(distances, default=0.0)
            c["outside_fraction"] = sum(outside) / max(1, len(outside))
        c["stray_candidate"] = bool(i and not expected and
                                      (not c["faces"] or (c["gap_m"] > ISLAND_GAP_M and
                                       (c["small_island"] or c.get("outside_fraction", 0) > 0.8))))
        if c["stray_candidate"]:
            flagged_islands.append(c)
    boundary = boundary_loops(points, edge_faces)
    # The original body lip rim sits next to the named inner-lip skirt. Constrain
    # the exemption to the head AND a 2 mm neighbourhood of that actual skirt.
    lip_points = {i for p in mesh.polygons if p.index in expected_faces and material_name(mesh, p) == "LipInner"
                  for i in p.vertices}
    lip_tree = KDTree(len(lip_points)) if lip_points else None
    if lip_tree:
        for i in lip_points:
            lip_tree.insert(points[i], i)
        lip_tree.balance()
    expected_boundary_edges = 0
    unexpected_edges = []
    for loop in boundary:
        intentional = []
        for a, b in loop["edges"]:
            fs = edge_faces[(a, b)]
            allowed = all(f in expected_faces for f in fs)
            if not allowed and lip_tree and min(points[a].z, points[b].z) >= neck_z:
                allowed = max(lip_tree.find(points[v])[2] for v in (a, b)) <= ISLAND_GAP_M
            intentional.append(allowed)
            if not allowed:
                unexpected_edges.append((a, b))
        loop["expected_edges"] = sum(intentional)
        loop["unexpected_edges"] = len(intentional) - sum(intentional)
        expected_boundary_edges += sum(intentional)
        del loop["edges"]
    zero_area, sliver, expected_thin = [], [], []
    for fi, poly in enumerate(mesh.polygons):
        ids = list(poly.vertices)
        area = face_area(points, ids)
        angle = min_face_angle(points, ids)
        if fi in expected_faces and material_name(mesh, poly) == "Eyelid" and (area <= ZERO_AREA_M2 or angle < SLIVER_ANGLE_DEG):
            expected_thin.append(fi)
        elif area <= ZERO_AREA_M2:
            zero_area.append(fi)
        elif angle < SLIVER_ANGLE_DEG:
            sliver.append({"face": fi, "min_angle_deg": round(angle, 4),
                           "position": vec_dict(sum((points[i] for i in ids), Vector()) / len(ids))})
    dupf = defaultdict(list)
    for fi, poly in enumerate(mesh.polygons):
        key = tuple(sorted(tuple(round(v / DUPLICATE_TOLERANCE_M) for v in points[i]) for i in poly.vertices))
        dupf[key].append(fi)
    duplicates = [ids for ids in dupf.values() if len(ids) > 1 and not all(i in expected_thin for i in ids)]
    duplicate_faces = sum(len(ids) - 1 for ids in duplicates)
    # Opposing normals also occur on properly wound folds. Same traversal direction
    # across a shared edge is the topology evidence of inconsistent face winding.
    flipped = set()
    for edge, entries in directions.items():
        if len(entries) == 2 and entries[0][1] == entries[1][1]:
            flipped.update(fi for fi, _ in entries)
    for ids in duplicates:
        for fi in ids[1:]:
            if mesh.polygons[ids[0]].normal.dot(mesh.polygons[fi].normal) < FLIPPED_NORMAL_DOT:
                flipped.update((ids[0], fi))
    # Stored corner normals opposing every corner of a triangle are independent
    # evidence; ordinary smoothing over a hard corner is not classified as flipped.
    for poly in mesh.polygons:
        if poly.index not in expected_thin and poly.area > ZERO_AREA_M2 and all(
                poly.normal.dot(mesh.corner_normals[li].vector) < FLIPPED_NORMAL_DOT for li in poly.loop_indices):
            flipped.add(poly.index)
    edges_by_vertex = defaultdict(list)
    for edge in edge_faces:
        for v in edge:
            edges_by_vertex[v].append(edge)
    inward = []
    for c in components:
        if c["expected_face_part"] or not c["faces"]:
            continue
        component_edges = {e for v in c["vertex_indices"] for e in edges_by_vertex[v]}
        closed = all(len(edge_faces[e]) == 2 for e in component_edges)
        if closed:
            origin = points[c["vertex_indices"][0]]
            volume = sum((a - origin).dot((b - origin).cross(d - origin)) / 6
                         for fi in c["face_indices"] for a, b, d in face_triangles(points, list(mesh.polygons[fi].vertices)))
            if volume < -ZERO_AREA_M2:
                inward.append({"face": c["face_indices"][0], "centre": c["centre"], "signed_volume_m3": volume})
                flipped.update(c["face_indices"])
    nonmanifold = [e for e, fs in edge_faces.items() if len(fs) > 2 or len(fs) == 0]
    def samples(fids):
        return [{"face": fi, "material": material_name(mesh, mesh.polygons[fi]),
                 "position": vec_dict(sum((points[i] for i in mesh.polygons[fi].vertices), Vector()) / len(mesh.polygons[fi].vertices))}
                for fi in sorted(fids)[:50]]
    edge_samples = [{"vertices": list(e), "position": vec_dict((points[e[0]] + points[e[1]]) * 0.5),
                     "incident_faces": edge_faces[e]} for e in (nonmanifold + unexpected_edges)[:50]]
    custom = bool(getattr(mesh, "has_custom_normals", False))
    duplicate_vertices = len(points) - len(set(remap))
    checks = {
        "counts": check("PASS", f"{len(mesh.vertices)} vertices, {len(mesh.polygons)} faces, "
                         f"{sum(max(0, len(p.vertices) - 2) for p in mesh.polygons)} triangles"),
        "loose_parts": check("FAIL" if any(not c["faces"] for c in flagged_islands) else ("WARN" if flagged_islands else "PASS"),
                              f"{len(components)} connected parts; {sum(c['expected_face_part'] for c in components)} intentional face parts; "
                              f"{len(flagged_islands)} detached candidates (review placement; separate prop parts can be intentional)"),
        "non_manifold_edges": check("FAIL" if nonmanifold or (character and unexpected_edges) else ("WARN" if unexpected_edges else "PASS"),
                                     f"{len(nonmanifold)} edges with >2/no faces; {len(unexpected_edges)} boundary edges outside accepted face parts/lip rim"),
        "boundary_loops": check("WARN" if unexpected_edges else "PASS", f"{len(boundary)} boundary chains; {expected_boundary_edges} intentional face/lip edges"),
        "zero_area_faces": check("FAIL" if zero_area else "PASS", f"{len(zero_area)} faces; {len(expected_thin)} intentional thin/folded eyelid faces excluded"),
        "sliver_faces": check("WARN" if sliver else "PASS", f"{len(sliver)} faces under {SLIVER_ANGLE_DEG:g} degrees (quality candidates)"),
        "duplicate_vertices": check("PASS", f"{duplicate_vertices} attribute-split vertices joined only for topology analysis"),
        "duplicate_faces": check("FAIL" if duplicate_faces else "PASS", f"{duplicate_faces} duplicate faces"),
        "flipped_normals": check("FAIL" if flipped else "PASS", f"{len(flipped)} faces incident to inconsistent winding or in inward closed shells"),
        "custom_normals": check("PASS", "present" if custom else "not present (no custom split normals stored)"),
    }
    # Full membership is needed above, but samples keep machine-readable evidence small.
    for c in components:
        c["vertex_indices"] = c["vertex_indices"][:20]
        c["face_indices"] = c["face_indices"][:20]
    return {"object": obj.name, "checks": checks, "vertices": len(mesh.vertices), "faces": len(mesh.polygons),
            "triangles": sum(max(0, len(p.vertices) - 2) for p in mesh.polygons),
            "components": components, "flagged_islands": flagged_islands, "boundary_loops": boundary,
            "zero_area_faces": zero_area[:50], "zero_area_samples": samples(zero_area), "sliver_faces": sliver[:50],
            "duplicate_vertices": duplicate_vertices, "duplicate_faces": duplicate_faces,
            "duplicate_face_samples": samples([i for ids in duplicates for i in ids]),
            "flipped_faces": sorted(flipped), "flipped_samples": samples(flipped), "inward_shells": inward,
            "non_manifold_edges": [list(e) for e in nonmanifold[:50]], "edge_samples": edge_samples,
            "unexpected_boundary_edges": len(unexpected_edges), "expected_thin_eyelid_faces": len(expected_thin),
            "custom_normals": custom}


def uv_report(obj):
    mesh = obj.data
    layer = mesh.uv_layers.active
    points = world_points(obj, mesh)
    base_info = {m.name: material_image_info(m) for m in mesh.materials if m}
    if not layer:
        return {"layers": 0, "checks": {"unmapped_faces": check("FAIL" if mesh.polygons else "PASS", f"{len(mesh.polygons)} faces have no UV layer"),
                "overlapping_islands": check("PASS", "none (no UV layer)"), "stretch": check("SKIP", "no UV layer"),
                "texel_density": check("SKIP", "no UV layer")}, "unmapped_faces": len(mesh.polygons),
                "overlaps": {}, "stretch": {}, "texel_density": {}}
    unmapped = []
    triangles = []
    area_ratios, angle_diffs, densities = [], [], []
    regions = []
    intentional_uv_faces = 0
    for fi, poly in enumerate(mesh.polygons):
        if material_name(mesh, poly) in FACE_MATERIALS and armature_for_mesh(obj):
            intentional_uv_faces += 1
            continue
        ids = list(poly.vertices)
        uvs = [layer.data[li].uv.copy() for li in poly.loop_indices]
        ua = polygon_uv_area(uvs)
        wa = face_area(points, ids)
        if ua <= UV_AREA_EPS or wa <= ZERO_AREA_M2:
            unmapped.append(fi)
            continue
        for i in range(1, len(uvs) - 1):
            triangles.append((fi, (tuple(uvs[0]), tuple(uvs[i]), tuple(uvs[i + 1])), poly.material_index))
        ratio = ua / wa
        area_ratios.append(ratio)
        diffs = []
        # Compare each corner angle in world and UV space.  This is intentionally a
        # face-level approximation for n-gons; the source mesh remains authoritative.
        for i in range(len(ids)):
            wi_prev = points[ids[i - 1]]
            wi = points[ids[i]]
            wi_next = points[ids[(i + 1) % len(ids)]]
            uv_prev, uv_i, uv_next = uvs[i - 1], uvs[i], uvs[(i + 1) % len(uvs)]
            wa1, wa2 = wi_prev - wi, wi_next - wi
            ua1, ua2 = Vector((uv_prev.x - uv_i.x, uv_prev.y - uv_i.y)), Vector((uv_next.x - uv_i.x, uv_next.y - uv_i.y))
            if wa1.length and wa2.length and ua1.length and ua2.length:
                wd = math.degrees(math.acos(max(-1.0, min(1.0, wa1.normalized().dot(wa2.normalized())))))
                ud = math.degrees(math.acos(max(-1.0, min(1.0, ua1.normalized().dot(ua2.normalized())))))
                diffs.append(abs(wd - ud))
        angle = max(diffs, default=0.0)
        angle_diffs.append(angle)
        info = base_info.get(mesh.materials[poly.material_index].name) if 0 <= poly.material_index < len(mesh.materials) and mesh.materials[poly.material_index] else None
        image = info.get("base_color") if info else None
        density = None
        if image and image["size"][0] > 0 and image["size"][1] > 0:
            density = math.sqrt(ua * image["size"][0] * image["size"][1] / wa)
            densities.append(density)
        centre = sum((obj.matrix_world @ mesh.vertices[i].co for i in ids), Vector()) / len(ids)
        regions.append({"face": fi, "position": vec_dict(centre), "area_ratio": ratio,
                        "angle_deg": angle, "texel_density": density})
    median = pct(area_ratios, 50) or 1.0
    for r in regions:
        r["area_distortion"] = max(r["area_ratio"] / median, median / max(r["area_ratio"], UV_AREA_EPS))
    worst = sorted(regions, key=lambda x: (x["area_distortion"] + x["angle_deg"] / 45.0), reverse=True)[:WORST_REGION_COUNT]
    overlap = approximate_uv_overlaps(triangles)
    density_spread = (max(densities) / min(densities)) if densities and min(densities) > 0 else None
    stretch_bad = any(r["area_distortion"] > STRETCH_WARN_RATIO or r["angle_deg"] > 45 for r in regions)
    density_bad = density_spread is not None and density_spread > DENSITY_WARN_SPREAD
    checks = {
        "unmapped_faces": check("FAIL" if unmapped else "PASS", f"{len(unmapped)} faces with no usable UV area; {intentional_uv_faces} intentional face-part gradient UV faces excluded"),
        "overlapping_islands": check("WARN" if overlap["triangle_pairs"] else "PASS",
                                     f"about {overlap['triangle_pairs']} overlapping triangle pairs ({overlap['faces']} faces)"),
        "stretch": check("WARN" if stretch_bad else "PASS", f"{len(regions)} mapped faces; area ratio p50/p95/p99 "
                          f"{pct(area_ratios,50):.4g}/{pct(area_ratios,95):.4g}/{pct(area_ratios,99):.4g}; "
                          f"angle p95 {pct(angle_diffs,95):.2f} degrees" if regions else "no mapped faces"),
        "texel_density": check("WARN" if density_bad else "PASS", "no base-colour image densities" if not densities else
                                f"{min(densities):.1f}–{max(densities):.1f} texels/m; spread {density_spread:.2f}x"),
    }
    return {"layers": len(mesh.uv_layers), "active_layer": layer.name, "checks": checks,
            "unmapped_faces": unmapped[:50], "intentional_gradient_faces": intentional_uv_faces, "overlaps": overlap,
            "stretch": {"area_ratio_percentiles": {str(p): pct(area_ratios, p) for p in (50, 90, 95, 99)},
                         "angle_percentiles_deg": {str(p): pct(angle_diffs, p) for p in (50, 90, 95, 99)}, "worst": worst},
            "texel_density": {"percentiles": {str(p): pct(densities, p) for p in (50, 90, 95, 99)},
                              "min": min(densities) if densities else None, "max": max(densities) if densities else None,
                              "spread": density_spread}, "materials": list(base_info.values())}


def armature_for_mesh(obj):
    for mod in obj.modifiers:
        if mod.type == "ARMATURE" and mod.object and mod.object.type == "ARMATURE":
            return mod.object
    if obj.parent and obj.parent.type == "ARMATURE":
        return obj.parent
    return None


def skin_report(obj, arm):
    if not arm:
        return {"checks": {"skinning": check("PASS", "no armature; skinning checks not applicable")}, "armature": None}
    mesh = obj.data
    names = [b.name for b in arm.data.bones]
    weights = defaultdict(float)
    deform_groups = {g.index: g.name for g in obj.vertex_groups if g.name in names and arm.data.bones[g.name].use_deform}
    unweighted, over4, bad_sum = [], [], []
    for v in mesh.vertices:
        vals = [(g.group, g.weight) for g in v.groups if g.weight > UNWEIGHTED_EPS and g.group in deform_groups]
        for gi, w in vals:
            weights[deform_groups[gi]] += w
        if not vals:
            unweighted.append(v.index)
        if len(vals) > MAX_INFLUENCES:
            over4.append({"vertex": v.index, "count": len(vals)})
        total = sum(w for _, w in vals)
        if vals and abs(total - 1.0) > WEIGHT_SUM_TOLERANCE:
            bad_sum.append({"vertex": v.index, "sum": round(total, 5)})
    no_weight_bones = [n for i, n in enumerate(names) if weights.get(n, 0.0) <= UNWEIGHTED_EPS]
    prefix = os.path.commonprefix(names).rstrip("_:.-") if names else ""
    points = world_points(obj, mesh)
    diag = (Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points))) -
            Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))).length if points else 1.0
    radius = min(JOINT_RADIUS_M, max(0.01, diag * 0.02))
    joint_details = []
    joint_pattern = re.compile(r"(thumb|index|middle|ring|pinky|little|finger|hand|shoulder)", re.I)
    group_names = {g.index: g.name for g in obj.vertex_groups}
    for bone in arm.data.bones:
        if not joint_pattern.search(bone.name):
            continue
        mid = arm.matrix_world @ ((bone.head_local + bone.tail_local) * 0.5)
        near = [v.index for v, p in zip(mesh.vertices, points) if (p - mid).length <= radius]
        influences = sorted({group_names.get(g.group, str(g.group)) for vi in near for g in mesh.vertices[vi].groups if g.weight > UNWEIGHTED_EPS})
        joint_details.append({"bone": bone.name, "vertices_near": len(near), "influences": influences})
    checks = {
        "bone_count": check("PASS", f"{len(names)} bones; prefix `{prefix or '<none>'}`"),
        "unweighted_vertices": check("FAIL" if unweighted else "PASS", f"{len(unweighted)} vertices"),
        "more_than_4_influences": check("FAIL" if over4 else "PASS", f"{len(over4)} vertices"),
        "weights_sum": check("FAIL" if bad_sum else "PASS", f"{len(bad_sum)} vertices outside ±{WEIGHT_SUM_TOLERANCE:g}"),
        "bones_without_weights": check("PASS", f"{len(no_weight_bones)} bones (unweighted control/end bones are allowed)"),
        "hands_shoulders_joints": check("PASS", f"{len(joint_details)} hand/finger/shoulder joints sampled at {radius:.3f} m"),
    }
    return {"armature": arm.name, "bone_count": len(names), "bone_names": names, "bone_prefix": prefix,
            "unweighted_vertices": unweighted[:50], "more_than_4_influences": over4[:50],
            "bad_weight_sums": bad_sum[:50], "bones_without_weights": no_weight_bones,
            "joint_details": joint_details, "checks": checks}


def shape_report(obj):
    keys = obj.data.shape_keys
    if not keys:
        return {"checks": {"shape_keys": check("PASS", "none")}, "keys": []}
    blocks = keys.key_blocks
    base_local = [v.co.copy() for v in blocks[0].data]
    base_world = [obj.matrix_world @ p for p in base_local]
    neck_z, _, neck_source = face_region(obj, base_world)
    mirror_x = (min(p.x for p in base_world) + max(p.x for p in base_world)) * 0.5
    # Match in metres once, within the same material, rather than rescanning 27
    # cells for every vertex of every key in unscaled object coordinates.
    materials = defaultdict(set)
    for poly in obj.data.polygons:
        for i in poly.vertices:
            materials[i].add(poly.material_index)
    regions = defaultdict(list)
    for i, p in enumerate(base_world):
        regions[tuple(sorted(materials[i]))].append(i)
    trees = {}
    for region, ids in regions.items():
        tree = KDTree(len(ids))
        for i in ids:
            tree.insert(base_world[i], i)
        tree.balance()
        trees[region] = tree
    matches = {}
    for i, p in enumerate(base_world):
        target = Vector((2 * mirror_x - p.x, p.y, p.z))
        _, j, distance = trees[tuple(sorted(materials[i]))].find(target)
        if distance <= SYMMETRY_MATCH_TOLERANCE_M:
            matches[i] = (j, distance)
    result, nonzero_defaults, outside = [], [], []
    outside_count = 0
    symmetry_re = re.compile(r"(viseme|expr|brow|eyes|jaw)", re.I)
    for block in blocks[1:]:
        if abs(block.value) > 1.0e-8:
            nonzero_defaults.append({"name": block.name, "value": block.value})
        disps = [obj.matrix_world.to_3x3() @ (block.data[i].co - base_local[i]) for i in range(len(base_local))]
        mags = [d.length for d in disps]
        moved = [i for i, magnitude in enumerate(mags) if magnitude > SHAPE_MOVE_DEFECT_M]
        bad = [i for i in moved if base_world[i].z < neck_z]
        outside_count += len(bad)
        outside.extend({"key": block.name, "vertex": i, "position": vec_dict(base_world[i]),
                        "displacement_mm": round(mags[i] * 1000, 3)} for i in bad[:50])
        sym = None
        if symmetry_re.search(block.name):
            errors, used = [], set()
            for i in moved:
                if i not in matches:
                    continue
                j, distance = matches[i]
                pair = tuple(sorted((i, j)))
                if pair in used:
                    continue
                used.add(pair)
                d, e = disps[i], disps[j]
                error = Vector((d.x + e.x, d.y - e.y, d.z - e.z)).length * 1000
                errors.append({"vertices": list(pair), "error_mm": error,
                               "rest_match_mm": distance * 1000, "position": vec_dict(base_world[i])})
            if errors:
                sym = {"max_error_mm": max(e["error_mm"] for e in errors),
                       "mean_error_mm": sum(e["error_mm"] for e in errors) / len(errors),
                       "pairs": len(errors), "unmatched_moved_vertices": sum(i not in matches for i in moved),
                       "worst": sorted(errors, key=lambda e: -e["error_mm"])[:5]}
        result.append({"name": block.name, "default_value": block.value, "max_displacement_cm": max(mags, default=0) * 100,
                       "moved_vertices": len(moved), "outside_head_count": len(bad),
                       "outside_head_vertices": bad[:50], "symmetry": sym})
    symmetry_bad = [x for x in result if x["symmetry"] and x["symmetry"]["max_error_mm"] > SYMMETRY_WARN_MM]
    incomplete = [x for x in result if x["moved_vertices"] and (not x["symmetry"] or x["symmetry"]["unmatched_moved_vertices"])]
    checks = {
        "shape_key_defaults": check("FAIL" if nonzero_defaults else "PASS", f"{len(nonzero_defaults)} nonzero defaults (must be 0)"),
        "shape_key_head_region": check("FAIL" if outside_count else "PASS", f"{outside_count} key/vertex moves below neck (>{SHAPE_MOVE_DEFECT_M:g} m); z={neck_z:.4f} m, {neck_source}"),
        "shape_key_symmetry": check("WARN" if symmetry_bad or incomplete else "PASS", f"{len(symmetry_bad)} keys over {SYMMETRY_WARN_MM:g} mm; {len(incomplete)} keys have unmatched moved vertices (not verified symmetric)"),
    }
    return {"head_neck_z": neck_z, "neck_source": neck_source, "mirror_x": mirror_x, "keys": result,
            "nonzero_defaults": nonzero_defaults, "outside_head": outside, "checks": checks}


def glb_data(path):
    raw = Path(path).read_bytes()
    if raw[:4] != b"glTF" or struct.unpack_from("<I", raw, 4)[0] != 2:
        raise ValueError("not a glTF 2 GLB")
    document, binary = None, b""
    at = 12
    while at < len(raw):
        length, kind = struct.unpack_from("<II", raw, at)
        chunk = raw[at + 8:at + 8 + length]
        if kind == 0x4e4f534a:
            document = json.loads(chunk)
        elif kind == 0x004e4942:
            binary = chunk
        at += 8 + length
    return document, binary


def accessor_data(document, binary, index):
    """Read animation source values, including strided and sparse accessors."""
    acc = document["accessors"][index]
    kinds = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
    widths = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
    width = widths[acc["type"]]
    def read(view_index, offset, count, kind, size):
        view = document["bufferViews"][view_index]
        fmt = "<" + kinds[kind] * size
        stride = view.get("byteStride", struct.calcsize(fmt))
        start = view.get("byteOffset", 0) + offset
        return [struct.unpack_from(fmt, binary, start + i * stride) for i in range(count)]
    values = read(acc["bufferView"], acc.get("byteOffset", 0), acc["count"], acc["componentType"], width) if "bufferView" in acc else [(0.0,) * width] * acc["count"]
    if "sparse" in acc:
        sp = acc["sparse"]
        inds, vals = sp["indices"], sp["values"]
        ids = read(inds["bufferView"], inds.get("byteOffset", 0), sp["count"], inds["componentType"], 1)
        updates = read(vals["bufferView"], vals.get("byteOffset", 0), sp["count"], acc["componentType"], width)
        for (i,), value in zip(ids, updates):
            values[i] = value
    return values


def animation_report(path):
    """Exact stored endpoint poses: avoids inactive Blender NLA/slot false passes.

    glTF holds endpoint values outside each sampler's time range. At the global
    clip endpoints, first/last values therefore are the poses even when channels
    have different time ranges. CUBICSPLINE tangents are not pose values.
    """
    document, binary = glb_data(path)
    actions = []
    fps = bpy.context.scene.render.fps / bpy.context.scene.render.fps_base
    for action in document.get("animations", []):
        start, end = float("inf"), float("-inf")
        comparisons = []
        for channel in action["channels"]:
            sampler = action["samplers"][channel["sampler"]]
            times = accessor_data(document, binary, sampler["input"])
            values = accessor_data(document, binary, sampler["output"])
            start, end = min(start, times[0][0]), max(end, times[-1][0])
            path_name = channel["target"]["path"]
            cubic = sampler.get("interpolation") == "CUBICSPLINE"
            factor = 3 if cubic else 1
            width = len(values) // (len(times) * factor)
            first_index = width if cubic else 0
            last_index = len(values) - 2 * width if cubic else len(values) - width
            first = tuple(v for row in values[first_index:first_index + width] for v in row)
            last = tuple(v for row in values[last_index:last_index + width] for v in row)
            node = document["nodes"][channel["target"]["node"]]
            if path_name == "rotation":
                dot = abs(sum(a * b for a, b in zip(first, last)))
                norm = math.sqrt(sum(a * a for a in first) * sum(a * a for a in last))
                error = math.degrees(2 * math.acos(min(1.0, dot / norm))) if norm else 180.0
                status = "FAIL" if error > LOOP_MATCH_FAIL_DEG else ("WARN" if error > LOOP_MATCH_WARN_DEG else "PASS")
            elif path_name == "translation":
                error = math.sqrt(sum((a - b) ** 2 for a, b in zip(first, last)))
                status = "FAIL" if error > LOOP_MATCH_FAIL_M else ("WARN" if error > LOOP_MATCH_WARN_M else "PASS")
            else:
                error = max((abs(a - b) for a, b in zip(first, last)), default=0)
                status = "WARN" if error > LOOP_MATCH_SCALE_EPS else "PASS"
            comparisons.append({"node": node.get("name", str(channel["target"]["node"])),
                                "path": path_name, "error": error, "status": status})
        item = {"name": action.get("name", "<unnamed>"), "frame_start": start * fps + 1, "frame_end": end * fps + 1,
                "duration_s": end - start}
        if item["name"].lower().endswith("_loop"):
            max_deg = max((c["error"] for c in comparisons if c["path"] == "rotation"), default=0)
            max_m = max((c["error"] for c in comparisons if c["path"] == "translation"), default=0)
            status = overall_status({str(i): c for i, c in enumerate(comparisons)}) if comparisons else "SKIP"
            item.update({"loop_max_bone_rotation_deg": max_deg, "loop_max_translation_m": max_m,
                         "loop_channels_compared": len(comparisons), "endpoint_differences": [c for c in comparisons if c["status"] != "PASS"],
                         "check": check(status, f"first/last local pose: max rotation {max_deg:.3f} degrees; translation {max_m * 1000:.3f} mm")})
        else:
            item["check"] = check("PASS", "not a loop; frame range recorded")
        actions.append(item)
    loops = [a for a in actions if a["name"].lower().endswith("_loop")]
    status = overall_status({a["name"]: a["check"] for a in loops}) if loops else "PASS"
    return {"actions": actions, "checks": {"animations": check(status, f"{len(actions)} actions; {len(loops)} loop actions (stored glTF endpoint channels)")}}


def audit_scene(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.gltf(filepath=str(path))
    except Exception as exc:
        return {"file": str(path), "overall": "FAIL", "error": f"GLB import failed: {exc}", "meshes": [], "actions": []}
    scene = bpy.context.scene
    for obj in scene.objects:
        if obj.animation_data:
            obj.animation_data.action = None
            for track in obj.animation_data.nla_tracks:
                track.mute = True
        if obj.type == "ARMATURE":
            obj.data.pose_position = "REST"
    bpy.context.view_layer.update()
    meshes = [o for o in scene.objects if o.type == "MESH"]
    mesh_results = []
    for obj in meshes:
        arm = armature_for_mesh(obj)
        g = geometry_report(obj)
        u = uv_report(obj)
        s = skin_report(obj, arm)
        k = shape_report(obj)
        checks = {}
        checks.update(g.pop("checks")); checks.update(u.pop("checks")); checks.update(s.pop("checks")); checks.update(k.pop("checks"))
        mesh_results.append({"name": obj.name, "overall": overall_status(checks), "checks": checks,
                             "geometry": g, "uvs": u, "skinning": s, "shape_keys": k})
    a = animation_report(path)
    all_checks = {f"{m['name']}:{n}": c for m in mesh_results for n, c in m["checks"].items()}
    all_checks.update({f"animations:{n}": c for n, c in a["checks"].items()})
    return {"file": str(path), "overall": overall_status(all_checks), "meshes": mesh_results,
            "actions": a["actions"], "animation_checks": a["checks"], "mesh_count": len(meshes),
            "sha256": hashlib.sha256(Path(path).read_bytes()).hexdigest()}


def create_selftest_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Two opposite-wound copies of one face exercise flipped normals and duplicate faces;
    # a third face on edge (0,1) makes that edge non-manifold.  (5,6,7) is a loose island.
    verts = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1), (0, -1, 0), (3, 0, 0), (3.1, 0, 0), (3, .1, 0)]
    faces = [(0, 1, 2), (0, 2, 1), (0, 1, 3), (5, 6, 7)]
    mesh = bpy.data.meshes.new("SelfTestMesh")
    mesh.from_pydata(verts, [], faces); mesh.update()
    obj = bpy.data.objects.new("SelfTest", mesh); bpy.context.collection.objects.link(obj)
    obj.shape_key_add(name="Basis")
    key = obj.shape_key_add(name="viseme_far")
    key.data[0].co = (0, 0, -1)
    return obj


def selftest():
    obj = create_selftest_scene()
    result = geometry_report(obj)
    shape = shape_report(obj)
    assert result["flagged_islands"], "selftest did not find loose island"
    assert result["flipped_faces"], "selftest did not find flipped face"
    assert result["non_manifold_edges"], "selftest did not find non-manifold edge"
    assert shape["outside_head"], "selftest did not find shape key outside head"
    assert any(c["faces"] == 1 and set(c["vertex_indices"]) == {5, 6, 7}
               for c in result["flagged_islands"]), "selftest missed the triangle itself"
    # Equal-size disconnected triangles must not both be mistaken for the main part.
    mesh = bpy.data.meshes.new("EqualIslands")
    mesh.from_pydata([(0, 0, 0), (1, 0, 0), (0, 1, 0), (3, 0, 0), (4, 0, 0), (3, 1, 0)], [], [(0, 1, 2), (3, 4, 5)])
    mesh.update()
    equal = bpy.data.objects.new("EqualIslands", mesh)
    bpy.context.collection.objects.link(equal)
    assert len(geometry_report(equal)["flagged_islands"]) == 1, "equal-sized islands missed"
    # A glTF UV seam must not turn a connected quad into two defective islands.
    seam_mesh = bpy.data.meshes.new("Seam")
    seam_mesh.from_pydata([(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)], [], [(0, 1, 2), (3, 4, 5)])
    seam_mesh.update()
    seam = bpy.data.objects.new("Seam", seam_mesh)
    bpy.context.collection.objects.link(seam)
    seam_result = geometry_report(seam)
    assert len(seam_result["components"]) == 1, "UV seam split topology"
    assert not seam_result["flipped_faces"], "consistent winding flagged"
    seam.shape_key_add(name="Basis")
    key = seam.shape_key_add(name="jawOpen")
    key.data[3].co.z += 0.02
    key.data[5].co.z += 0.02
    assert len(geometry_report(seam)["components"]) == 2, "deforming mouth cut welded shut"
    assert not triangles_overlap(((0, 0), (1, 0), (0, 1)), ((1, 0), (1, 1), (0, 1))), "shared UV edge flagged"
    assert triangles_overlap(((0, 0), (1, 0), (0, 1)), ((0, 0), (1, 0), (0, 1))), "UV duplicate missed"
    # Exercise the source GLB loop reader with translation-only discontinuity,
    # quaternion sign equivalence and CUBICSPLINE value/tangent separation.
    binary = bytearray()
    document = {"asset": {"version": "2.0"}, "nodes": [{"name": "Root"}], "bufferViews": [], "accessors": [], "animations": []}
    def accessor(rows, kind):
        offset = len(binary)
        for row in rows:
            binary.extend(struct.pack("<" + "f" * len(row), *row))
        document["bufferViews"].append({"buffer": 0, "byteOffset": offset, "byteLength": len(binary) - offset})
        document["accessors"].append({"bufferView": len(document["bufferViews"]) - 1, "componentType": 5126, "count": len(rows), "type": kind})
        return len(document["accessors"]) - 1
    times = accessor([(0,), (1,)], "SCALAR")
    for name, path, rows, kind, interpolation in [
            ("Translation_loop", "translation", [(0, 0, 0), (0.02, 0, 0)], "VEC3", "LINEAR"),
            ("Sign_loop", "rotation", [(0, 0, 0, 1), (0, 0, 0, -1)], "VEC4", "LINEAR"),
            ("Cubic_loop", "translation", [(2, 0, 0), (0, 0, 0), (3, 0, 0), (4, 0, 0), (0, 0, 0), (5, 0, 0)], "VEC3", "CUBICSPLINE")]:
        out = accessor(rows, kind)
        document["animations"].append({"name": name, "channels": [{"sampler": 0, "target": {"node": 0, "path": path}}],
                                       "samplers": [{"input": times, "output": out, "interpolation": interpolation}]})
    document["buffers"] = [{"byteLength": len(binary)}]
    raw_json = json.dumps(document).encode()
    raw_json += b" " * (-len(raw_json) % 4)
    payload = struct.pack("<II", len(raw_json), 0x4e4f534a) + raw_json + struct.pack("<II", len(binary), 0x004e4942) + binary
    with tempfile.TemporaryDirectory(prefix="mesh-audit-selftest-") as tmp:
        fixture = Path(tmp) / "loops.glb"
        fixture.write_bytes(struct.pack("<4sII", b"glTF", 2, len(payload) + 12) + payload)
        actions = animation_report(fixture)["actions"]
    assert actions[0]["check"]["status"] == "FAIL", "translation-only loop mismatch missed"
    assert actions[1]["check"]["status"] == "PASS", "equivalent quaternion signs flagged"
    assert actions[2]["check"]["status"] == "PASS", "spline tangents treated as poses"
    print("SELFTEST PASS: loose triangle, equal islands, flipped face, non-manifold edge, shape-key defect, seams/cuts, UV overlap, loop endpoints")


def md_status(c):
    return c.get("status", "PASS")


def md_check(name, c):
    return f"- **{name}** — **{md_status(c)}**: {c.get('detail', '')}"


def write_report(results, out, title):
    lines = [f"# {title}", "", "Generated by `production/tools/mesh_audit.py` from Blender " + bpy.app.version_string + " source data. "
             "Inputs were imported read-only; no source GLB was modified.", "",
             "Coordinates are Blender world metres (Z up). Vertex/face IDs refer to the imported mesh; source SHA-256 is recorded per file. "
             "FAIL is source-data evidence; WARN is a candidate requiring intent/visual review. No self-intersection, rendered appearance, "
             "runtime contact or lightmap validation is implied. Topology welds attribute seams only in an analysis map and preserves morph/weight cuts. "
             "Intentional head materials and the nearby lip rim are exempt from boundary/island findings; folded eyelids are exempt from thin-face findings. "
             "UV overlap is a capped per-material sample, not exhaustive; facial gradient maps are intentional. "
             "Symmetry is a nearest mirrored-rest-position comparison within 3 mm and reports unmatched moved vertices. "
             "Loops compare stored local TRS/morph endpoints, not velocity continuity or evaluated world-space motion.", "",
             "## Thresholds", "",
             f"`ISLAND_FRACTION={ISLAND_FRACTION:g}`, `SLIVER_ANGLE_DEG={SLIVER_ANGLE_DEG:g}`, "
             f"`SHAPE_MOVE_DEFECT_M={SHAPE_MOVE_DEFECT_M:g}`, `MAX_INFLUENCES={MAX_INFLUENCES}`, "
             f"`LOOP_MATCH_WARN_DEG={LOOP_MATCH_WARN_DEG:g}`, `LOOP_MATCH_FAIL_DEG={LOOP_MATCH_FAIL_DEG:g}`, "
             f"`LOOP_MATCH_WARN_M={LOOP_MATCH_WARN_M:g}`, `LOOP_MATCH_FAIL_M={LOOP_MATCH_FAIL_M:g}`, "
             f"`MIN_ISLAND_VERTICES={MIN_ISLAND_VERTICES}`, `ISLAND_GAP_M={ISLAND_GAP_M:g}`.", "",
             "## Summary", "", "| File | Result | Meshes | PASS | WARN | FAIL |", "|---|---:|---:|---:|---:|---:|"]
    for r in results:
        cs = [c for m in r.get("meshes", []) for c in m.get("checks", {}).values()] + list(r.get("animation_checks", {}).values())
        counts = {s: sum(md_status(c) == s for c in cs) for s in ("PASS", "WARN", "FAIL")}
        lines.append(f"| `{r['file']}` | **{r.get('overall','FAIL')}** | {r.get('mesh_count', 0)} | {counts['PASS']} | {counts['WARN']} | {counts['FAIL']} |")
    for r in results:
        lines += ["", f"## `{r['file']}`", ""]
        if r.get("error"):
            lines.append(f"- **imports** — **FAIL**: {r['error']}")
            continue
        lines.append(f"**Overall: {r.get('overall', 'FAIL')}** · SHA-256 `{r.get('sha256', 'unavailable')}`")
        for m in r.get("meshes", []):
            lines += ["", f"### Mesh `{m['name']}` — **{m['overall']}**", ""]
            for name, c in m.get("checks", {}).items():
                lines.append(md_check(name, c))
            g, u, s, k = m.get("geometry", {}), m.get("uvs", {}), m.get("skinning", {}), m.get("shape_keys", {})
            lines.append(f"- geometry detail: {g.get('vertices', 0)} verts, {g.get('faces', 0)} faces, {g.get('triangles', 0)} tris; "
                         f"boundary loops {len(g.get('boundary_loops', []))}; flagged islands {len(g.get('flagged_islands', []))}")
            if g.get("boundary_loops"):
                lines.append("  - boundary loops: " + "; ".join(f"{x['length_m']:.3f} m at {x['centre']}" for x in g["boundary_loops"][:12]))
            if g.get("flagged_islands"):
                lines.append("  - detached candidates: " + "; ".join(f"{x['vertices']} verts, gap {x['gap_m']:.4f} m at {x['centre']}, materials {x['materials']}, faces {x['face_indices'][:3]}" for x in g["flagged_islands"][:20]))
            for kind in ("zero_area_samples", "duplicate_face_samples", "flipped_samples", "edge_samples"):
                if g.get(kind):
                    lines.append(f"- {kind} (up to 10): " + json.dumps(g[kind][:10]))
            if u.get("stretch", {}).get("worst"):
                lines.append("- worst UV regions: " + "; ".join(f"face {x['face']} at {x['position']} (area {x['area_distortion']:.2f}x, angle {x['angle_deg']:.1f}°)" for x in u["stretch"]["worst"]))
            if u.get("materials"):
                for mat in u["materials"]:
                    tex = ", ".join(f"{x['name']} {x['size'][0]}×{x['size'][1]}" for x in mat["textures"]) or "no image textures"
                    lines.append(f"- material `{mat['name']}` textures: {tex}")
            if s.get("bone_names"):
                lines.append(f"- armature `{s.get('armature')}`: {s.get('bone_count')} bones, prefix `{s.get('bone_prefix') or '<none>'}`")
                if s.get("bones_without_weights"):
                    lines.append("  - bones without weights: " + ", ".join(s["bones_without_weights"][:30]))
                for j in s.get("joint_details", []):
                    lines.append(f"  - joint `{j['bone']}`: {j['vertices_near']} nearby vertices; influences {', '.join(j['influences']) or '<none>'}")
            if k.get("keys"):
                lines.append("- shape keys: " + "; ".join(f"{x['name']} default={x['default_value']:.3g}, max={x['max_displacement_cm']:.3f} cm" for x in k["keys"]))
                for key in k["keys"]:
                    sym = key.get("symmetry")
                    if sym:
                        lines.append(f"  - symmetry `{key['name']}`: max {sym['max_error_mm']:.3f} mm; {sym['pairs']} matched moving pairs; "
                                     f"{sym['unmatched_moved_vertices']} unmatched moving vertices; worst {sym['worst'][0]}")
                if k.get("outside_head"):
                    lines.append("  - below-neck moves: " + "; ".join(f"{x['key']} v{x['vertex']} {x['displacement_mm']:.1f} mm at {x['position']}" for x in k["outside_head"][:20]))
        if r.get("actions"):
            lines += ["", "### Animations", ""]
            for a in r["actions"]:
                c = a["check"]
                suffix = f"; loop max rotation {a.get('loop_max_bone_rotation_deg', 0):.3f}°; translation {a.get('loop_max_translation_m', 0) * 1000:.3f} mm" if "loop_max_bone_rotation_deg" in a else ""
                lines.append(f"- **{a['name']}** — **{c['status']}**: frames {a['frame_start']:.3f}–{a['frame_end']:.3f}{suffix}")
                for path_name in ("rotation", "translation", "scale", "weights"):
                    worst = sorted((x for x in a.get("endpoint_differences", []) if x["path"] == path_name), key=lambda x: -x["error"])[:5]
                    if worst:
                        lines.append(f"  - {path_name} worst channels: " + "; ".join(f"`{x['node']}` {x['error']:.6g}" for x in worst))
    Path(out).write_text("\n".join(lines) + "\n")


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("files", nargs="*")
    p.add_argument("--report", default="mesh_audit.md")
    p.add_argument("--json")
    p.add_argument("--selftest", action="store_true")
    return p.parse_args(argv)


def main():
    args = parse_args()
    if args.selftest:
        selftest(); return
    if not args.files:
        raise SystemExit("No GLB files supplied")
    results = []
    for filename in args.files:
        print(f"AUDIT {filename}", flush=True)
        results.append(audit_scene(Path(filename)))
    title = "Mesh audit — characters" if "character" in Path(args.report).name else "Mesh audit — props and environment"
    write_report(results, args.report, title)
    if args.json:
        Path(args.json).write_text(json.dumps(results, indent=2, sort_keys=True))
    print(f"WROTE {args.report}")
    if args.json:
        print(f"WROTE {args.json}")
    print("SUMMARY", json.dumps({"files": len(results), "fail": sum(r.get("overall") == "FAIL" for r in results),
                                "warn": sum(r.get("overall") == "WARN" for r in results)}))


if __name__ == "__main__":
    main()
