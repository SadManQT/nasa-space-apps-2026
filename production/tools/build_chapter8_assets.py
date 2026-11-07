"""M3-8A phase 2: export the approved Chapter 8 pieces to Godot (Blender 5.2; no credits, no generation).

    python3 production/concept/chapter8_v1/road_data.py          (road, pads, segments, 10 m heights; cached LOLA only)
    python3 production/tools/heavy.py blender -b --factory-startup --python production/tools/build_chapter8_assets.py

Builds every EN_MalapertSummit and EN_RelayRoad piece with the same procedural builders that drew the approved sheets
(production/concept/chapter8_v1/summit_kit.py and road_kit.py; Sadman, 7 Nov 2026: "Approve all"), then for each
piece and LOD:
  * evaluates modifiers and curves into meshes and joins them per movable part (door hinge, isolator handle, dish
    azimuth and elevation, local antenna azimuth and elevation, solar wing, repeater lid and panel antennas), so every
    part that moves is its own node with its pivot at the hinge or axis;
  * maps the sheet materials onto the M1-05 kit's PBR sets (paint white/navy/orange/dark, steel, grey) with box UVs at
    the kit's tile size, and gives every live surface its own plain slot: Screen_LocalLeg, Screen_EarthLeg,
    Screen_Checksum, Lamp_Status_0..2, Lamp_Beacon, Lamp_Link_0..1, Lamp_Guide (words and states are runtime UI);
  * adds simplified -convcolonly boxes (LOD0 only; the door's box rides on its hinge) and Socket_* empties;
  * exports a GLB (+Y up, -Z = local north for summit pieces) whose images point at ../kit/textures (stored once).
Writes game/assets/environment/EN_MalapertSummit/ and EN_RelayRoad/ (GLBs, .import, malapert_summit.json,
relay_road.json), production/manifest/chapter8_assets.csv (gate rows), the VH_Rover light sockets
(game/assets/vehicles/VH_Rover/rover_lights.json and VH_Rover_Lit.tscn, decision 7) and studio previews in
production/models/chapter8/preview/.
"""
import csv
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "production/concept/chapter8_v1"))
import build_habitat_kit as hk  # noqa: E402  (kit material helpers)
import ch08_common as C  # noqa: E402
import road_kit as RK  # noqa: E402
import summit_kit as K  # noqa: E402
from glb_external_textures import externalise  # noqa: E402

TASK = "M3-8A"
KIT = ROOT / "game/assets/environment/kit"
OUT_SUMMIT = ROOT / "game/assets/environment/EN_MalapertSummit"
OUT_ROAD = ROOT / "game/assets/environment/EN_RelayRoad"
ROVER = ROOT / "game/assets/vehicles/VH_Rover"
PREVIEW = ROOT / "production/models/chapter8/preview"
LAYOUT = json.loads((ROOT / "production/concept/chapter8_v1/summit_layout.json").read_text())
ROAD = json.loads((ROOT / "production/models/chapter8/data/road.json").read_text())
SOURCE = "tools/build_chapter8_assets.py from the approved M3-8A sheets (production/concept/chapter8_v1; Sadman, 7 Nov 2026: \"Approve all\")"
LOD_DISTANCE_M = 25.0
DECIMATE_LOD1 = 0.45
NO_RENDER = "--no-render" in sys.argv

# sheet material -> kit set ("kit", key) or a plain named slot
MATERIAL_MAP = {
    "PaintWhite": ("kit", "PaintWhite"), "BetaCloth": ("kit", "PaintWhite"), "StripeWhite": ("kit", "PaintWhite"),
    "PaintNavy": ("kit", "PaintNavy"), "PaintOrange": ("kit", "PaintOrange"), "Steel": ("kit", "Steel"),
    "DarkMetal": ("kit", "PaintDark"), "Rubber": ("kit", "PaintDark"), "Ballast": ("kit", "PaintGrey"),
    "SolarCell": ("plain", "SolarCell"), "TagRed": ("plain", "LockoutTag"), "Reflector": ("plain", "Reflector"),
    "ScreenOff": ("plain", "Screen"), "ScreenBlue": ("plain", "Screen"), "LampGreen": ("plain", "Lamp"),
    "LampAmber": ("plain", "Lamp"), "LampOff": ("plain", "Lamp"), "LampRed": ("plain", "Lamp"), "Foil": ("kit", "Steel"),
}
PLAIN = {  # name: roughness, colour, emission ((rgb), strength) -- the dark/off state; runtime drives the rest
    "SolarCell": (0.18, (0.012, 0.02, 0.06), None),
    "LockoutTag": (0.6, (0.58, 0.07, 0.05), None),
    "Reflector": (0.3, (0.89, 0.27, 0.05), None),
    "Screen_LocalLeg": (0.12, (0.02, 0.025, 0.03), None),
    "Screen_EarthLeg": (0.12, (0.02, 0.025, 0.03), None),
    "Screen_Checksum": (0.12, (0.02, 0.025, 0.03), None),
    "Screen": (0.12, (0.02, 0.025, 0.03), None),
    "Lamp_Status_0": (0.25, (0.05, 0.06, 0.055), None), "Lamp_Status_1": (0.25, (0.05, 0.06, 0.055), None),
    "Lamp_Status_2": (0.25, (0.05, 0.06, 0.055), None), "Lamp_Beacon": (0.3, (0.08, 0.06, 0.04), None),
    "Lamp_Link_0": (0.25, (0.05, 0.06, 0.055), None), "Lamp_Link_1": (0.25, (0.05, 0.06, 0.055), None),
    "Lamp_Guide": (0.3, (0.6, 0.32, 0.06), ((1.0, 0.55, 0.12), 3.0)),
    "Lamp": (0.25, (0.05, 0.06, 0.055), None),
}
# object (base) name -> plain slot, for surfaces the runtime addresses one by one
OBJECT_SLOTS = {"screen_L": "Screen_LocalLeg", "screen_E": "Screen_EarthLeg", "screen_check": "Screen_Checksum",
                "ring_lamp": "Lamp_Beacon", "gl_head": "Lamp_Guide"}
INDEXED_SLOTS = {"status": "Lamp_Status_", "link_lamp": "Lamp_Link_"}


def base(name):
    return name.split(".")[0]


# ------------------------------------------------------------------------------------------- piece table
# id, builder(P, pal), movable pivots {sheet empty name: exported node name}, collision boxes, sockets, size flag
# collision: (name, parent node or None, centre, size) in that parent's frame (Blender, Z up)
# sockets: (name, parent node or None, position or the name of a sheet object whose centre is used)

def summit_pieces():
    return [
        dict(id="EN_MalapertSummit_RelayDeck", display="Legacy relay deck (2034) with the Earth dish and the local antenna",
             make=lambda P, pal: K.relay_deck(P, (0, 0), pal),
             movable={"yoke": "DishAzimuth", "el_axis": "DishElevation", "local_head": "LocalAzimuth", "local_tilt": "LocalElevation"},
             collision=[("Deck", None, (0, 0, 0.625), (4.0, 4.0, 1.25)), ("Pedestal", None, (0, 0.8, 1.9), (0.7, 0.7, 1.3)),
                        ("RfBox", None, (1.1, 1.2, 1.63), (0.9, 0.55, 0.76)), ("Mast", None, (-1.6, -1.5, 3.4), (0.14, 0.14, 4.2)),
                        ("RailN", None, (0, 1.95, 1.75), (4.0, 0.06, 1.0)), ("RailW", None, (-1.95, 0, 1.75), (0.06, 4.0, 1.0)),
                        ("RailE", None, (1.95, 0, 1.75), (0.06, 4.0, 1.0)), ("RailS", None, (1.2, -1.95, 1.75), (1.5, 0.06, 1.0))],
             sockets=[("Socket_Ladder", None, (-0.15, -2.4, 0.0)), ("Socket_DeckTop", None, (0, -0.8, 1.25)),
                      ("Socket_DishFeed", "DishElevation", "feed"), ("Socket_LocalFeed", "LocalElevation", "local_feed"),
                      ("Socket_CableEntry", None, (1.0, 1.0, 0.0))],
             flag="--height", kind="relay"),
        dict(id="EN_MalapertSummit_ControllerHousing", display="Controller housing (service door east, controller bay, test point, three status lamps)",
             make=lambda P, pal: K.controller_housing(P, (0, 0), pal, door_open_deg=0.0, state="dark"),
             movable={"door_hinge": "DoorHinge", "controller": "Controller"},
             collision=[("Body", None, (0, 0, 0.86), (0.85, 1.55, 1.72)), ("Door", "DoorHinge", (0.0, -0.55, 0.0), (0.05, 1.1, 1.24))],
             sockets=[("Socket_ControllerSlot", None, (0.15, -0.1, 0.76)), ("Socket_TestPoint", None, "tp_plate"),
                      ("Socket_StatusLamps", None, (0.37, 0.0, 1.66)), ("Socket_DoorBrace", "DoorHinge", "brace_handle"),
                      ("Socket_Operator", None, (1.0, 0.0, 0.0))],
             flag="--height", kind="housing"),
        dict(id="EN_MalapertSummit_PowerIsolator", display="Power isolator (rotary handle, lock-out hasp and tag)",
             make=lambda P, pal: K.power_isolator(P, (0, 0), pal, isolated=False),
             movable={"handle": "Handle"},
             collision=[("Body", None, (0.03, 0, 0.66), (0.25, 0.36, 1.32))],
             sockets=[("Socket_Handle", "Handle", (0, 0, 0)), ("Socket_Operator", None, (0.6, 0, 0)), ("Socket_LockoutTag", None, (0.2, 0.08, 0.84))],
             flag="--height", kind="isolator"),
        dict(id="EN_MalapertSummit_ControlPedestal", display="L/E tuner and ALO42 checksum pedestal (three live screens, two dials)",
             make=lambda P, pal: K.control_pedestal(P, (0, 0), pal, lit=False),
             movable={},
             collision=[("Body", None, (0.0, 0, 0.58), (0.5, 1.0, 1.16))],
             sockets=[("Socket_Operator", None, (0.75, 0, 0)), ("Socket_Screen_LocalLeg", None, "screen_L"),
                      ("Socket_Screen_EarthLeg", None, "screen_E"), ("Socket_Screen_Checksum", None, "screen_check")],
             flag="--height", kind="pedestal"),
        dict(id="EN_MalapertSummit_SolarMast", display="Solar mast and battery (vertical wing tracking the circling polar Sun)",
             make=lambda P, pal: K.solar_mast(P, (0, 0), pal, face_az=0.0),
             movable={"wing": "Wing"},
             collision=[("Pole", None, (0, 0, 2.2), (0.2, 0.2, 4.4)), ("Battery", None, (0, -1.3, 0.45), (0.8, 0.5, 0.9)),
                        ("Wing", "Wing", (0, 0.12, 0), (2.25, 0.1, 3.65))],
             sockets=[("Socket_Battery", None, (0, -1.3, 0.9)), ("Socket_CableOut", None, (0.1, -1.0, 0.0))],
             flag="--height", kind="solar"),
        dict(id="EN_MalapertSummit_TetherAnchor", display="Tether anchor (stake, plate and ring)",
             make=lambda P, pal: K.tether_anchor(P, (0, 0), pal),
             movable={}, collision=[("Body", None, (0, 0, 0.36), (0.12, 0.12, 0.72))],
             sockets=[("Socket_Ring", None, (0, 0, 0.7))], flag="--height", kind="anchor"),
        dict(id="EN_MalapertSummit_PerimeterMarker", display="Perimeter marker (orange reflective cap)",
             make=lambda P, pal: K.perimeter_marker(P, (0, 0), pal),
             movable={}, collision=[("Body", None, (0, 0, 0.285), (0.08, 0.08, 0.57))], sockets=[], flag="--height", kind="marker"),
        dict(id="EN_MalapertSummit_UmbilicalPost", display="Umbilical post (rover power and data)",
             make=lambda P, pal: K.umbilical_post(P, (0, 0), pal, rover_port=None),
             movable={}, collision=[("Body", None, (0, 0, 0.55), (0.3, 0.32, 1.1))],
             sockets=[("Socket_Port", None, (0.16, 0, 0.98))], flag="--height", kind="umbilical"),
        dict(id="EN_MalapertSummit_ViewpointRail", display="Earth viewpoint rail and standing plate",
             make=lambda P, pal: K.viewpoint(P, (0, 0), pal),
             movable={}, collision=[("Rail", None, (0, 0.3, 0.5), (3.06, 0.08, 1.0))],
             sockets=[("Socket_Stand", None, (0, -0.4, 0.0))], flag="--longest", kind="viewpoint"),
        dict(id="EN_MalapertSummit_CableTray", display="Cable tray, 2 m straight (tiles along the runs)",
             make=lambda P, pal: K.cable_tray(P, [(-1.0, 0.0), (1.0, 0.0)], pal),
             movable={}, collision=[("Body", None, (0, 0, 0.03), (2.0, 0.16, 0.06))], sockets=[], flag="--longest", kind="tray"),
    ]


def road_pieces():
    return [
        dict(id="EN_RelayRoad_Repeater", display="Repeater R1-R3 (3 m mast, ring beacon, two panel antennas, two link lamps, battery bay)",
             make=lambda P, pal: RK.repeater(P, (0, 0), pal, yaw_back=180.0, yaw_fwd=0.0, state="dark", bay_open=False),
             movable={"bay_lid": "BayLid", "panel_back": "PanelBack", "panel_fwd": "PanelForward"},
             collision=[("Mast", None, (0, 0, 1.55), (0.42, 0.42, 3.1)), ("Bay", None, (0, 0, 0.25), (0.52, 0.38, 0.5))],
             sockets=[("Socket_BatteryBay", None, (0, 0, 0.5)), ("Socket_Beacon", None, (0, 0, 2.75)),
                      ("Socket_LinkBack", "PanelBack", (0, 0.32, 0)), ("Socket_LinkForward", "PanelForward", (0, 0.32, 0)),
                      ("Socket_Operator", None, (0, -0.85, 0))],
             flag="--height", kind="repeater"),
        dict(id="EN_RelayRoad_BatteryModule", display="Repeater battery module (removable, orange handle)",
             make=lambda P, pal: RK.battery_module(P, (0, 0), pal),
             movable={}, collision=[("Body", None, (0, 0, 0.2), (0.42, 0.28, 0.4))],
             sockets=[("Socket_Grip", None, (0, 0, 0.4))], flag="--height", kind="battery"),
        dict(id="EN_RelayRoad_GuideLight", display="Guide light (amber, every 18 m on spurs and the road edge)",
             make=lambda P, pal: RK.guide_light(P, (0, 0), pal, lit=False),
             movable={}, collision=[("Body", None, (0, 0, 0.35), (0.11, 0.11, 0.7))],
             sockets=[("Socket_Light", None, (0, 0, 0.66))], flag="--height", kind="guide"),
        dict(id="EN_RelayRoad_SlopeSign", display="Slope warning sign (pictogram only)",
             make=lambda P, pal: RK.slope_sign(P, (0, 0), pal, yaw=0),
             movable={}, collision=[("Post", None, (0, 0, 0.65), (0.07, 0.07, 1.3)), ("Panel", None, (0, -0.04, 1.35), (0.9, 0.05, 0.9))],
             sockets=[], flag="--height", kind="sign"),
        dict(id="EN_RelayRoad_TurnbackBarrier", display="Turnback barrier (closes the unsupported bypass)",
             make=lambda P, pal: RK.turnback_barrier(P, (0, 0), pal, yaw=0),
             movable={}, collision=[("Body", None, (0, 0, 0.53), (4.16, 0.16, 1.06))], sockets=[], flag="--longest", kind="barrier"),
        dict(id="EN_RelayRoad_SupplyCache", display="Layby supply cache (rack with two latched crates)",
             make=lambda P, pal: RK.supply_cache(P, (0, 0), pal, yaw=0),
             movable={}, collision=[("Body", None, (0, 0, 0.4), (1.62, 0.72, 0.8))],
             sockets=[("Socket_Crate0", None, (-0.38, 0, 0.8)), ("Socket_Crate1", None, (0.38, 0, 0.8))], flag="--longest", kind="cache"),
    ]


# ------------------------------------------------------------------------------------------- materials

def kit_tiles():
    catalogue = json.loads((KIT / "kit.json").read_text(encoding="utf-8"))
    return {m["id"].replace("M_Kit_", ""): float(m["tile_m"]) for m in catalogue["materials"]}


def kit_materials(lod):
    """Kit PBR materials for one LOD, built from the published texture files (exported names = kit names)."""
    tiles = kit_tiles()
    folder, suffix = (KIT / "textures", "") if lod == 0 else (KIT / "textures/lod1", "_LOD1")
    table = {}
    for key in ("PaintWhite", "PaintNavy", "PaintOrange", "PaintDark", "PaintGrey", "Steel"):
        shared = "Paint" if key.startswith("Paint") else key
        maps = {}
        for kind, stem, srgb in (("base", f"T_Kit_{key}_BaseColor", True), ("normal", f"T_Kit_{shared}_Normal", False), ("orm", f"T_Kit_{shared}_ORM", False)):
            name = stem + suffix
            image = bpy.data.images.get(name) or bpy.data.images.load(str(folder / (name + ".png")), check_existing=True)
            image.name = name
            image.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
            maps[kind] = image
        table[key] = (hk.pbr_material("M_Kit_" + key + suffix, maps), tiles[key])
    for name, (rough, colour, emission) in PLAIN.items():
        table[name] = (hk.pbr_material(name, None, rough, colour, emission=emission), 1.0)
    return table


def slot_for(obj_name, mat_name, counters):
    b = base(obj_name)
    if b in OBJECT_SLOTS:
        return OBJECT_SLOTS[b]
    if b in INDEXED_SLOTS:
        return INDEXED_SLOTS[b] + str(counters.setdefault(obj_name, len([k for k in counters if base(k) == b])))
    kind, key = MATERIAL_MAP.get(base(mat_name), ("kit", "PaintGrey"))
    return key


def box_uv(me, tiles_by_slot):
    """Box projection per face at the slot's tile size (kit textures repeat once per tile metres)."""
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        u_i, v_i = [(1, 2), (0, 2), (0, 1)][ax]
        slot = me.materials[f.material_index].name if f.material_index < len(me.materials) and me.materials[f.material_index] else ""
        tile = tiles_by_slot.get(slot, 1.0)
        for loop in f.loops:
            co = loop.vert.co
            loop[uv].uv = (co[u_i] / tile, co[v_i] / tile)
    bm.to_mesh(me)
    bm.free()


# ------------------------------------------------------------------------------------------- piece build

def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    C._MATS.clear()
    hk._gltf_group = None


def descendants(o):
    out = []
    for c in o.children:
        out.append(c)
        out += descendants(c)
    return out


def piece_lod(spec, lod):
    clear()
    table = kit_materials(lod)  # first, so the plain slots keep their exact names
    pal = C.palette()
    tiles_by_slot = {m.name: t for m, t in table.values()}
    P = C.empty("P")
    spec["make"](P, pal)
    bpy.context.view_layer.update()
    src = descendants(P)
    for o in src:  # glTF-imported or empty-parented sheet objects: Euler mode for any later rotation
        o.rotation_mode = "XYZ"
    # socket positions taken from sheet objects before those are removed
    centres = {}
    for o in src:
        if o.type in ("MESH", "CURVE"):
            pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
            centres[base(o.name)] = sum(pts, Vector()) / 8.0
    root = hk.make_empty(f"{spec['id']}_LOD{lod}")
    # new pivot empties, nested like the sheet's movable empties
    pivots = {}
    movable = spec["movable"]

    def pivot_of(o):
        p = o.parent
        while p is not None and p is not P:
            if base(p.name) in movable:
                return p
            p = p.parent
        return None
    for o in sorted([o for o in src if o.type == "EMPTY" and base(o.name) in movable], key=lambda o: len(o.name)):
        pass
    ordered = []

    def visit(o):
        for c in o.children:
            if c.type == "EMPTY" and base(c.name) in movable:
                ordered.append(c)
            visit(c)
    visit(P)
    for e in ordered:
        parent_e = pivot_of(e)
        node = hk.make_empty(movable[base(e.name)], (0, 0, 0), pivots[parent_e.name] if parent_e is not None else root)
        node.matrix_world = e.matrix_world.copy()
        pivots[e.name] = node
    # evaluate, remap materials, group
    dg = bpy.context.evaluated_depsgraph_get()
    groups = {}
    counters = {}
    for o in src:
        if o.type not in ("MESH", "CURVE") or o.hide_render or base(o.name) in ("bay_cut",):
            continue
        me = bpy.data.meshes.new_from_object(o.evaluated_get(dg), preserve_all_data_layers=False, depsgraph=dg)
        if not me.polygons:
            continue
        me.transform(o.matrix_world)
        names = [slot_for(o.name, (m.name if m else ""), counters) for m in (me.materials or [None])]
        me.materials.clear()
        for n in names:
            me.materials.append(table.get(n, table["PaintGrey"])[0])
        pv = pivot_of(o)
        key = pv.name if pv is not None else None
        groups.setdefault(key, []).append(me)
    out = []
    for key, meshes in groups.items():
        node = pivots[key] if key is not None else root
        objs = []
        for me in meshes:
            ob = bpy.data.objects.new("part", me)
            bpy.context.scene.collection.objects.link(ob)
            objs.append(ob)
        with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, selected_objects=objs, object=objs[0]):
            bpy.ops.object.join()
        joined = objs[0]
        joined.data.transform(node.matrix_world.inverted())
        joined.matrix_world = Matrix.Identity(4)
        joined.parent = node
        joined.matrix_parent_inverse = Matrix.Identity(4)
        joined.name = (spec["id"] if node is root else node.name) + f"_Mesh_LOD{lod}"
        bpy.context.view_layer.update()
        if lod == 1 and len(joined.data.polygons) > 60:
            mod = joined.modifiers.new("decimate", "DECIMATE")
            mod.ratio = DECIMATE_LOD1
            dg2 = bpy.context.evaluated_depsgraph_get()
            dec = bpy.data.meshes.new_from_object(joined.evaluated_get(dg2), depsgraph=dg2)
            joined.modifiers.clear()
            joined.data = dec
        joined.data.update()
        for p in joined.data.polygons:
            p.use_smooth = False
        box_uv(joined.data, tiles_by_slot)
        out.append(joined)
    for o in src:
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.objects.remove(P, do_unlink=True)
    bpy.context.view_layer.update()
    # floor: the lowest visual point at y = 0 (ballast bags and cables may dip a few mm-cm under the sheet's z = 0)
    lo = min((ob.matrix_world @ v.co).z for ob in out for v in ob.data.vertices)
    lift = -lo if abs(lo) > 0.002 else 0.0
    if lift:
        for c in list(root.children):
            c.location.z += lift
        bpy.context.view_layer.update()
    nodes = {n.name: n for n in pivots.values()}
    extra = []
    if lod == 0:
        for name, parent, centre, size in spec["collision"]:
            node = nodes[parent] if parent else root
            bpy.ops.mesh.primitive_cube_add(size=1)
            cb = bpy.context.object
            cb.name = f"{name}-convcolonly"
            cb.scale = size
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            cb.data.materials.clear()
            cb.parent = node
            cb.matrix_parent_inverse = Matrix.Identity(4)
            cb.location = Vector(centre) + (Vector((0, 0, lift)) if node is root else Vector())
            cb.display_type = "WIRE"
            extra.append(cb)
    sockets = {}
    for name, parent, where in spec["sockets"]:
        node = nodes[parent] if parent else root
        if isinstance(where, str):
            world = centres[where] + Vector((0, 0, lift))
            local = node.matrix_world.inverted() @ world
        else:
            local = Vector(where) + (Vector((0, 0, lift)) if node is root else Vector())
        e = hk.make_empty(name, (0, 0, 0), node)
        e.location = local
        extra.append(e)
        bpy.context.view_layer.update()
        w = e.matrix_world.translation
        sockets[name] = [round(w.x, 3), round(w.z, 3), round(-w.y, 3)]  # Godot frame: x, y up, z = -Blender y
    bpy.context.view_layer.update()
    vis = out
    pts = [ob.matrix_world @ v.co for ob in vis for v in ob.data.vertices]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    tris = sum(len(p.vertices) - 2 for ob in vis for p in ob.data.polygons)
    slots = sorted({m.name for ob in vis for m in ob.data.materials if m})
    nodes_out = {n.name: [round(n.matrix_world.translation.x, 3), round(n.matrix_world.translation.z, 3), round(-n.matrix_world.translation.y, 3)] for n in pivots.values()}
    return root, vis + list(pivots.values()) + extra, dict(lo=lo, hi=hi, tris=tris, slots=slots, sockets=sockets, nodes=nodes_out, lift=round(lift, 4))


def export(root, objs, path, lod):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_animations=False, export_cameras=False, export_lights=False,
                              export_extras=False, export_image_format="AUTO", export_texcoords=True, export_normals=True)
    externalise(path, "../kit/textures/lod1" if lod == 1 else "../kit/textures", write_files=False)
    import_file = path.with_name(path.name + ".import")
    params = hk.SCENE_IMPORT_PARAMS  # embedded_image_handling=1: the kit's shared PNGs are used as already imported
    if import_file.exists():
        lines = import_file.read_text(encoding="utf-8").splitlines()
        lines = ["gltf/embedded_image_handling=1" if l.startswith("gltf/embedded_image_handling=") else l for l in lines]
        import_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    else:
        import_file.write_text('[remap]\n\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n[deps]\n\n'
                               'source_file="res://' + path.relative_to(ROOT / "game").as_posix() + '"\n\n[params]\n\n' + params, encoding="utf-8")


def preview(root, objs, path):
    """Studio still of the exported LOD (what the GLB holds), for the review contact sheet."""
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "METAL"
        prefs.get_devices()
        for d in prefs.devices:
            d.use = True
        sc.cycles.device = "GPU"
    except Exception:
        pass
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "AgX"
    world = bpy.data.worlds.new("W")
    sc.world = world
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.5, 0.5, 0.52, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    for o in objs:
        if o.name.endswith("-convcolonly"):
            o.hide_render = True
    floor = C.box("cyc", (60, 60, 0.02), (0, 0, -0.011), C.mat("Cyc", (0.42, 0.42, 0.43, 1), 0.9))
    key = C.point_light("Key", (4.0, -5.0, 7.0), 2500, (1, 0.98, 0.95), 4.0, "AREA", None, Vector((-4.0, 5.0, -7.0)))
    vis = [o for o in objs if o.type == "MESH" and not o.name.endswith("-convcolonly")]
    pts = [o.matrix_world @ v.co for o in vis for v in o.data.vertices]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    centre, span = (lo + hi) / 2, max(hi - lo)
    cam = C.camera("cam", centre + Vector((1.0, -1.15, 0.75)).normalized() * span * 2.1, centre, 50)
    C.render(cam, path, (640, 640), 48)
    bpy.data.objects.remove(floor)
    bpy.data.objects.remove(key)
    bpy.data.objects.remove(cam)


# ------------------------------------------------------------------------------------------- rover lights

def rover_lights():
    """Light sockets on VH_Rover (decision 7): headlights, two roof work floods and the cabin glow, in the GLB's own
    frame (Godot: +Z is the rover's front, its cabin end; Y up). The GLB is not modified; VH_Rover_Lit.tscn instances it with lights."""
    clear()
    objs = C.import_glb(ROVER / "VH_Rover.glb")
    bpy.context.view_layer.update()
    meshes = [o for o in objs if o.type == "MESH"]
    pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    cx, cy = (lo.x + hi.x) / 2, (lo.y + hi.y) / 2

    def g(v):  # Blender (x, y, z) -> Godot (x, z, -y)
        return [round(v[0], 3), round(v[2], 3), round(-v[1], 3)]
    front = lo.y  # the cabin end is Blender -Y (Godot +Z)
    roof = 3.7     # top of the cabin shell (the mast and lamp reach 4.4 m)
    lights = [
        dict(name="Headlight_L", type="spot", position=g((cx + 0.9, front - 0.05, lo.z + 1.15)), direction=g((0.0, -1.0, -0.12)), energy=6.0, range_m=45.0, angle_deg=27.5, color=[0.92, 0.95, 1.0]),
        dict(name="Headlight_R", type="spot", position=g((cx - 0.9, front - 0.05, lo.z + 1.15)), direction=g((0.0, -1.0, -0.12)), energy=6.0, range_m=45.0, angle_deg=27.5, color=[0.92, 0.95, 1.0]),
        dict(name="RoofFlood_L", type="spot", position=g((cx + 1.6, front + 1.0, roof)), direction=g((0.24, -0.9, -1.0)), energy=4.0, range_m=24.0, angle_deg=47.5, color=[0.95, 0.97, 1.0]),
        dict(name="RoofFlood_R", type="spot", position=g((cx - 1.6, front + 1.0, roof)), direction=g((-0.24, -0.9, -1.0)), energy=4.0, range_m=24.0, angle_deg=47.5, color=[0.95, 0.97, 1.0]),
        dict(name="CabinGlow", type="omni", position=g((cx, front + 1.6, lo.z + 1.9)), energy=0.6, range_m=3.0, color=[1.0, 0.8, 0.55]),
    ]
    data = dict(task=TASK, decision="7: roof work floods added to VH_Rover as light sockets (Sadman, 7 Nov 2026: \"Approve all\")",
                frame="VH_Rover.glb's own frame in Godot: +Z is the rover's front (the cabin end), +Y up, metres; directions are unit vectors",
                bounds_min=[round(lo.x, 3), round(lo.z, 3), round(-hi.y, 3)], bounds_max=[round(hi.x, 3), round(hi.z, 3), round(-lo.y, 3)],
                sides="facing +Z with +Y up, the rover's left is +X",
                states={"driving": ["Headlight_L", "Headlight_R", "CabinGlow"], "eva_stop": ["Headlight_L", "Headlight_R", "RoofFlood_L", "RoofFlood_R", "CabinGlow"], "parked_dark": []},
                lights=lights, scene="res://assets/vehicles/VH_Rover/VH_Rover_Lit.tscn",
                note="Exterior lights only light the ground and hardware they hit: no beams or haze in vacuum (ART_BIBLE 2).")
    for l in lights:
        d = Vector(l.get("direction", (0, 0, -1)))
        l["direction"] = [round(v, 4) for v in d.normalized()] if "direction" in l else None
        if l["direction"] is None:
            del l["direction"]
    (ROVER / "rover_lights.json").write_text(json.dumps(data, indent=1) + "\n", encoding="utf-8")
    lines = ['[gd_scene load_steps=2 format=3]', '', '[ext_resource type="PackedScene" path="res://assets/vehicles/VH_Rover/VH_Rover.glb" id="1_rover"]', '',
             '[node name="VH_Rover_Lit" type="Node3D"]', '', '[node name="VH_Rover" parent="." instance=ExtResource("1_rover")]']
    for l in lights:
        p = Vector(l["position"])
        if l["type"] == "spot":
            z = -Vector(l["direction"]).normalized()  # a SpotLight3D shines along its local -Z
            up = Vector((0, 1, 0)) if abs(z.y) < 0.95 else Vector((1, 0, 0))
            x = up.cross(z).normalized()
            y = z.cross(x).normalized()
            basis = (x, y, z)
            kind = "SpotLight3D"
        else:
            basis = (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))
            kind = "OmniLight3D"
        bx, by, bz = basis  # the .tscn text form lists the basis row by row: (x.x, y.x, z.x, x.y, y.y, z.y, x.z, y.z, z.z)
        t = ", ".join(f"{v:.5f}" for v in (bx.x, by.x, bz.x, bx.y, by.y, bz.y, bx.z, by.z, bz.z, p.x, p.y, p.z))
        lines += ['', f'[node name="{l["name"]}" type="{kind}" parent="."]', f'transform = Transform3D({t})',
                  'light_color = Color({:.3f}, {:.3f}, {:.3f}, 1)'.format(*l["color"]), f'light_energy = {l["energy"]}', 'shadow_enabled = true']
        if kind == "SpotLight3D":
            lines += [f'spot_range = {l["range_m"]}', f'spot_angle = {l["angle_deg"]}', 'spot_angle_attenuation = 0.6']
        else:
            lines += [f'omni_range = {l["range_m"]}']
        if l["name"].startswith("RoofFlood"):
            lines.append("visible = false")  # on only at an EVA stop (rover_lights.json states)
    (ROVER / "VH_Rover_Lit.tscn").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("ROVER lights", [l["name"] for l in lights], "bounds", g(lo), g(hi))
    return data


# ------------------------------------------------------------------------------------------- catalogues

def godot_xz(x, y):
    """Platform frame (x local east, y local north) -> Godot room frame (x east, z = -north)."""
    return [round(x, 3), round(-y, 3)]


def summit_catalogue(entries):
    lay = LAYOUT
    place = []
    rel = {"relay_deck": ("EN_MalapertSummit_RelayDeck", 0.0), "controller_housing": ("EN_MalapertSummit_ControllerHousing", 0.0),
           "power_isolator": ("EN_MalapertSummit_PowerIsolator", 0.0), "control_pedestal": ("EN_MalapertSummit_ControlPedestal", 0.0),
           "solar_mast": ("EN_MalapertSummit_SolarMast", 0.0), "umbilical_post": ("EN_MalapertSummit_UmbilicalPost", 0.0),
           "earth_viewpoint": ("EN_MalapertSummit_ViewpointRail", 0.0)}
    for p in lay["pieces"]:
        if p["id"] in rel:
            piece, yaw = rel[p["id"]]
            place.append(dict(piece=piece, at_xz=godot_xz(*p["at"]), yaw_deg=yaw))
        if p["id"] == "tether_anchors":
            for k, a in enumerate(p["at"]):
                place.append(dict(piece="EN_MalapertSummit_TetherAnchor", at_xz=godot_xz(*a), yaw_deg=0.0, name=f"anchor_{k}"))
    x0, x1, y0, y1 = lay["pad_bounds"]
    for x in range(int(x0), int(x1) + 1, 5):
        for y in (y0, y1):
            place.append(dict(piece="EN_MalapertSummit_PerimeterMarker", at_xz=godot_xz(x, y), yaw_deg=0.0))
    for y in range(int(y0) + 5, int(y1), 5):
        for x in (x0, x1):
            place.append(dict(piece="EN_MalapertSummit_PerimeterMarker", at_xz=godot_xz(x, y), yaw_deg=0.0))
    trays = [((-11.5, 3.5), (-11.5, 0.2)), ((-11.5, 0.2), (-3.5, 0.2)), ((-4.0, 2.2), (-4.0, 3.2)), ((-1.8, 2.2), (-1.8, 0.6)), ((-1.8, 0.6), (3.0, 0.6))]
    runs = [dict(from_xz=godot_xz(*a), to_xz=godot_xz(*b), piece="EN_MalapertSummit_CableTray", piece_length_m=2.0) for a, b in trays]
    sky = lay["dated_sky"]
    return dict(
        task=TASK, location="LOC-12 Malapert relay summit", approved="Sadman, 7 Nov 2026: \"Approve all\" (sheet production/concept/chapter8_v1/M3-8A_EN_MalapertSummit_sheet.png)",
        conventions=dict(units="metres", up="+Y", platform_frame="room origin at the summit site of sun_positions.json (malapert_summit, the highest LOLA pixel of PGDA Site23); +X local east, -Z local north (away from the pole); the frame is the LOLA tile frame rotated 2.34 deg about Y so -Z is true local north",
                         piece_front="pieces are authored with Blender +Y = Godot -Z = local north; yaw_deg rotates about +Y", lod_distance_m=LOD_DISTANCE_M,
                         textures="the kit's PBR sets by uri in ../kit/textures (stored once)"),
        terrain=dict(region="malapert_summit", pad_bounds_xz=[[x0, -y1], [x1, -y0]], pad_level_m=-0.3,
                     pad_rule="cut level 0.3 m under the summit crown and filled outward (decision 1): from a pad at the median ground height the crown hides Earth, which clears the summit skyline by about 2 deg",
                     platform_yaw_deg_from_tile=2.335),
        dated_sky=sky,
        aims=dict(earth_dish=dict(node="DishAzimuth/DishElevation", az_deg=358.7, el_deg=-2.3, rule="boresight 2.3 deg below level: Earth is below the mathematical horizon from a 5 km summit"),
                  local_antenna=dict(node="LocalAzimuth/LocalElevation", az_deg=216.7, el_deg=-4.8, target="R3, 54.3 km, 3.7 km lower (route_simulator_data.py)")),
        states=dict(housing=dict(dark=["Lamp_Status_0", "Lamp_Status_1", "Lamp_Status_2"], two_unverified=dict(amber=["Lamp_Status_0", "Lamp_Status_1"]), locked=dict(green=["Lamp_Status_0", "Lamp_Status_1", "Lamp_Status_2"]),
                                    bridge="EX-CH08-S06 -> S07: the dark relay housing beyond the rover window (all lamps off)"),
                    isolator=dict(node="Handle", isolated_rotation_deg_x=90, live_rotation_deg_x=0, lockout_socket="Socket_LockoutTag"),
                    door=dict(node="DoorHinge", open_rotation_deg_z=105, axis="+Y in Godot (vertical hinge on the north edge of the opening)"),
                    pedestal=dict(screens=["Screen_LocalLeg", "Screen_EarthLeg", "Screen_Checksum"], rule="all words, bearings, signal and obstruction meters and the ALO42 echo are live UI; the bearings stay labelled scenario values (STORY_FULL S08)")),
        placements=place, cable_runs=runs,
        rover=dict(piece="res://assets/vehicles/VH_Rover/VH_Rover_Lit.tscn", at_xz=godot_xz(7.6, -1.0), heading="west: the rover's +Z (cabin end) toward room -X, i.e. rotation_y = -90 deg; its cabin window looks at the housing", umbilical_socket="EN_MalapertSummit_UmbilicalPost/Socket_Port"),
        anchors={k: godot_xz(*v) for k, v in lay["anchors"].items()},
        scenes=lay["scenes"], pieces=entries)


def road_catalogue(entries):
    r = ROAD
    return dict(
        task=TASK, location="LOC-11 Aurora to Malapert relay road", approved="Sadman, 7 Nov 2026: \"Approve all\" (sheet production/concept/chapter8_v1/M3-8A_EN_RelayRoad_sheet.png)",
        conventions=dict(units="metres", up="+Y", map_frame="LOLA south polar stereographic metres (x toward 90 E, y toward 0 E); game distances 120 km each way (P-15), computed road 198 km on the 80 m grid",
                         lod_distance_m=LOD_DISTANCE_M, textures="the kit's PBR sets by uri in ../kit/textures"),
        road=dict(source="production/terrain/routes.json relay_road (make_terrain.py, 80 m grid, slope limit 12 deg, 15 deg hard limit)", length_m=r["road_length_m"], game_km=r["game_km"]),
        repeaters=[dict(id=f"R{k}", x_m=p["x"], y_m=p["y"], height_m=round(p["h"], 1), road_m=round(p["road_m"], 1), game_km=p["game_km"], offset_from_road_m=p["offset_m"],
                        lola_10m=r["lola_10m"]["pads"][f"R{k}"], piece="EN_RelayRoad_Repeater", mast_m=3.0) for k, p in enumerate(r["pads"], 1)],
        hops=r["hops"], segments=[dict(s, lola_10m=r["lola_10m"]["segments"].get(s["id"])) for s in r["segments"]], laybys=r["laybys"],
        service_pad=dict(at="R2 (marker two)", size_m=[20, 15], pieces=["EN_RelayRoad_Repeater", "EN_MalapertSummit_TetherAnchor", "EN_MalapertSummit_PerimeterMarker x8"],
                         guide_lights=dict(piece="EN_RelayRoad_GuideLight", spacing_m=18, offset_m=3.4, alternate_sides=True),
                         bypass=dict(pieces=["EN_RelayRoad_TurnbackBarrier", "EN_RelayRoad_SlopeSign"], rule="closes the unsupported cliff bypass (S03); the shortcut's slope is a hard boundary")),
        spurs_note="The straight lines from the road to the pads cross 15-25 deg stretches on the 10 m grid (lola_10m.spur.steepest_20m_deg), so each playable spur must follow a slope-limited path (<= 12 deg, 15 deg hard), routed on the 10 m tiles when the walkable patches are cut (M1-87 / M3-8R).",
        lighting="EX-CH08-S03 and S04 are dark (sun_positions.json relay_road_mid rows): rover lights (VH_Rover_Lit.tscn eva_stop state), guide lights and suit lamps only; faint stars only in frames with no sunlit ground (ART_BIBLE 2, 7 Nov 2026)",
        ten_metre_tiles="production/terrain/cache/pgda90_10mpp/t_0026_0035, t_0027_0035, t_0031_0037, t_0031_0038, t_0032_0037, t_0036_0037, t_0036_0038 (LDEM_83S_10MPP_ADJ, fetched 7 Nov 2026 for M3-8A; decision 9)",
        pieces=entries)


# ------------------------------------------------------------------------------------------- main

def main():
    PREVIEW.mkdir(parents=True, exist_ok=True)
    rows = []
    for out_dir, specs, catalogue_name in ((OUT_SUMMIT, summit_pieces(), "malapert_summit.json"), (OUT_ROAD, road_pieces(), "relay_road.json")):
        out_dir.mkdir(parents=True, exist_ok=True)
        for old in out_dir.glob("*.glb"):
            old.unlink()
        entries = []
        for spec in specs:
            entry = dict(id=spec["id"], display=spec["display"], lods=[], triangles=[], collision=True, lod_distance_m=LOD_DISTANCE_M)
            for lod in (0, 1):
                root, objs, info = piece_lod(spec, lod)
                name = f"{spec['id']}_LOD{lod}"
                path = out_dir / (name + ".glb")
                size = info["hi"] - info["lo"]
                measured = size.z if spec["flag"] == "--height" else max(size)
                export(root, objs, path, lod)
                if lod == 0 and not NO_RENDER:
                    preview(root, objs, PREVIEW / f"{spec['id']}.png")
                rows.append(dict(name=name, concept_or_source=SOURCE, size_flag=spec["flag"], size_m=round(measured, 3), tris=info["tris"],
                                 tex=1024 if lod == 0 else 512, game_path=path.relative_to(ROOT).as_posix(), art_status="approved",
                                 notes=f"{TASK} {spec['display']}; " + ("game LOD with collision" if lod == 0 else "Compatibility LOD, no collision")))
                entry["lods"].append("res://" + path.relative_to(ROOT / "game").as_posix())
                entry["triangles"].append(info["tris"])
                if lod == 0:
                    entry.update(size_m=[round(size.x, 3), round(size.z, 3), round(size.y, 3)], material_slots=info["slots"],
                                 sockets=info["sockets"], moving_nodes=info["nodes"], floor_lift_m=info["lift"])
                print(f"CH8 {name}: {info['tris']} tris, size {[round(v, 3) for v in size]}, lift {info['lift']}, slots {info['slots']}")
            entries.append(entry)
        cat = summit_catalogue(entries) if out_dir == OUT_SUMMIT else road_catalogue(entries)
        (out_dir / catalogue_name).write_text(json.dumps(cat, indent=1) + "\n", encoding="utf-8")
    with (ROOT / "production/manifest/chapter8_assets.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    rover_lights()
    print(f"CHAPTER8_BUILD_PASS: {len(rows)} GLBs, manifest production/manifest/chapter8_assets.csv")


main()
