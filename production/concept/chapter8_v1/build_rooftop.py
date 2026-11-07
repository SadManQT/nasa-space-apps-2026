"""EN_NoorRooftop approval renders for M3-8A: Noor's modest rooftop in Dhaka, Bangladesh, on Earth (Blender 5.2 Cycles,
procedural; no credits). EX-CH08-S10 is 9 Apr 2047 02:15-03:00 UTC = 08:15 Dhaka (doc 24 7.5: morning; CS-15-B's
accepted rooftop picture; the Moon is not in her sky); EX-CH08-S12 is 10 Apr 06:00 UTC = 12:00 Dhaka. No signs or
writing anywhere (English only, no Bangla script; the city carries no lettering at all). The mustard in her pots is the
installed PL_Tara_Bloom model (four-petal Brassica rapa flowers, no faces).

    python3 production/tools/heavy.py blender -b --factory-startup --python production/concept/chapter8_v1/build_rooftop.py -- [--quick]
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import ch08_common as C  # noqa: E402

QUICK = "--quick" in sys.argv
# Sun over Dhaka (23.81 N, 90.41 E): apparent solar time 08:15, declination +7.6 deg -> elevation 33.9, azimuth 97.0;
# noon on 10 Apr -> elevation 74.1, azimuth 180.
SUN_S10 = (97.0, 33.9)
SUN_S12 = (180.0, 74.1)
FLOOR_H = 3.0
ROOF_Z = 18.0  # six storeys


def d(az, el):
    a, e = math.radians(az), math.radians(el)
    return Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e)))


def plaster(name, hexcol, windows=True, rough=0.85):
    m = bpy.data.materials.new(name)
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = rough
    base = C.srgb(hexcol)
    tc = nt.nodes.new("ShaderNodeTexCoord")
    stain = nt.nodes.new("ShaderNodeTexNoise"); stain.inputs["Scale"].default_value = 0.35; stain.inputs["Detail"].default_value = 8
    nt.links.new(tc.outputs["Object"], stain.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.35; ramp.color_ramp.elements[0].color = tuple(c * 0.62 for c in base[:3]) + (1,)
    ramp.color_ramp.elements[1].position = 0.75; ramp.color_ramp.elements[1].color = base
    nt.links.new(stain.outputs["Fac"], ramp.inputs["Fac"])
    col = ramp.outputs["Color"]
    if windows:
        sep = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(tc.outputs["Object"], sep.inputs["Vector"])
        add = nt.nodes.new("ShaderNodeMath"); add.operation = "ADD"
        nt.links.new(sep.outputs["X"], add.inputs[0]); nt.links.new(sep.outputs["Y"], add.inputs[1])

        def band(src, period, duty, offset=0.0):
            m1 = nt.nodes.new("ShaderNodeMath"); m1.operation = "MULTIPLY"; m1.inputs[1].default_value = 1.0 / period
            nt.links.new(src, m1.inputs[0])
            a1 = nt.nodes.new("ShaderNodeMath"); a1.operation = "ADD"; a1.inputs[1].default_value = offset
            nt.links.new(m1.outputs[0], a1.inputs[0])
            fr = nt.nodes.new("ShaderNodeMath"); fr.operation = "FRACT"; nt.links.new(a1.outputs[0], fr.inputs[0])
            lt = nt.nodes.new("ShaderNodeMath"); lt.operation = "LESS_THAN"; lt.inputs[1].default_value = duty
            nt.links.new(fr.outputs[0], lt.inputs[0])
            return lt.outputs[0]
        wx = band(add.outputs[0], 2.4, 0.34)
        wz = band(sep.outputs["Z"], FLOOR_H, 0.38, 0.62)
        geo = nt.nodes.new("ShaderNodeNewGeometry")
        nsep = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(geo.outputs["Normal"], nsep.inputs["Vector"])
        wall = nt.nodes.new("ShaderNodeMath"); wall.operation = "LESS_THAN"; wall.inputs[1].default_value = 0.5  # walls only, not roofs
        nt.links.new(nsep.outputs["Z"], wall.inputs[0])
        m0 = nt.nodes.new("ShaderNodeMath"); m0.operation = "MULTIPLY"
        nt.links.new(wx, m0.inputs[0]); nt.links.new(wz, m0.inputs[1])
        mul = nt.nodes.new("ShaderNodeMath"); mul.operation = "MULTIPLY"
        nt.links.new(m0.outputs[0], mul.inputs[0]); nt.links.new(wall.outputs[0], mul.inputs[1])
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
        nt.links.new(mul.outputs[0], mix.inputs["Factor"])
        nt.links.new(col, mix.inputs["A"])
        mix.inputs["B"].default_value = (0.018, 0.022, 0.026, 1)
        col = mix.outputs["Result"]
        rmix = nt.nodes.new("ShaderNodeMapRange"); rmix.inputs["To Min"].default_value = rough; rmix.inputs["To Max"].default_value = 0.25
        nt.links.new(mul.outputs[0], rmix.inputs["Value"]); nt.links.new(rmix.outputs["Result"], b.inputs["Roughness"])
    nt.links.new(col, b.inputs["Base Color"])
    return m


def leafy(name, loc, r, mat, rng, n=40, flat=0.35):
    out = []
    for k in range(n):
        v = Vector((rng.normal(), rng.normal(), abs(rng.normal()) * 0.8)).normalized() * r * rng.uniform(0.4, 1.0)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=r * rng.uniform(0.18, 0.3), location=Vector(loc) + v)
        o = bpy.context.object
        bpy.ops.object.shade_smooth()
        o.scale = (1.0, rng.uniform(0.5, 0.8), flat)
        o.rotation_euler = (rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6), rng.uniform(0, 6.28))
        o.data.materials.append(mat)
        out.append(o)
    return out


def pot(name, loc, r, h, mat):
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=r * 0.78, radius2=r, depth=h, location=(loc[0], loc[1], loc[2] + h / 2))
    o = bpy.context.object; o.name = name; o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    C.cyl(name + "_soil", r * 0.94, 0.02, (loc[0], loc[1], loc[2] + h - 0.03), C.mat("Soil", (0.06, 0.04, 0.03, 1), 0.95), verts=24)
    return o


def build():
    sc = C.reset()
    sc.cycles.max_bounces = 6
    rng = np.random.default_rng(2047)
    pal = C.palette()
    concrete = C.mat("RoofConcrete", (0.36, 0.35, 0.33, 1), 0.92, grain=0.06)
    parapet_m = plaster("ParapetPlaster", "#E8E2D4", windows=False)
    terracotta = C.mat("Terracotta", C.srgb("#B5653A"), 0.8, grain=0.08)
    leaf = C.mat("Leaf", (0.06, 0.20, 0.04, 1), 0.55, grain=0.1)
    leaf2 = C.mat("LeafLight", (0.13, 0.30, 0.06, 1), 0.55, grain=0.1)
    tank_m = C.mat("TankBlack", (0.012, 0.012, 0.014, 1), 0.45)
    blue_door = C.mat("DoorBlue", C.srgb("#2E6C9A"), 0.55, grain=0.12)
    bamboo = C.mat("Bamboo", C.srgb("#A88A55"), 0.7, grain=0.12)
    tin = C.mat("TinSheet", (0.55, 0.56, 0.57, 1), 0.45, metal=0.8, grain=0.2)
    # our building: roof slab at z = 0 (the scene origin), body below to the street
    W, Dp = 8.0, 10.0
    C.box("roof_slab", (W, Dp, 0.25), (0, 0, -0.125), concrete)
    C.box("building", (W - 0.1, Dp - 0.1, ROOF_Z), (0, 0, -ROOF_Z / 2 - 0.25), plaster("OwnPlaster", "#E6DFCF"))
    for (sx, sy, lx, ly) in ((0, Dp / 2 - 0.075, W, 0.15), (0, -Dp / 2 + 0.075, W, 0.15), (W / 2 - 0.075, 0, 0.15, Dp), (-W / 2 + 0.075, 0, 0.15, Dp)):
        C.box("parapet", (lx, ly, 1.0), (sx, sy, 0.5), parapet_m, bevel=0.01)
        C.box("parapet_cap", (lx + 0.06 if lx > 1 else 0.24, ly + 0.06 if ly > 1 else 0.24, 0.06), (sx, sy, 1.03), concrete)
    # stair-head room, north-west corner, door facing south; the black tank on its roof
    C.box("stair_room", (2.6, 3.0, 2.5), (-2.6, 3.4, 1.25), plaster("StairPlaster", "#E3DACB", windows=False), bevel=0.02)
    C.box("stair_door", (1.0, 0.06, 2.0), (-2.2, 1.88, 1.0), blue_door)
    C.box("door_frame", (1.12, 0.05, 2.08), (-2.2, 1.9, 1.04), C.mat("FrameGrey", (0.2, 0.2, 0.2, 1), 0.6))
    C.cyl("tank", 0.62, 1.35, (-2.6, 3.6, 2.5 + 0.35 + 0.675), tank_m, verts=40)
    C.cyl("tank_lid", 0.22, 0.08, (-2.6, 3.6, 2.5 + 0.35 + 1.39), tank_m, verts=24)
    C.box("tank_stand", (1.4, 1.4, 0.35), (-2.6, 3.6, 2.5 + 0.175), C.mat("SteelGrey", (0.25, 0.25, 0.26, 1), 0.5, metal=0.6))
    C.tube("tank_pipe", [(-2.0, 3.0, 2.9), (-1.2, 2.9, 2.9), (-1.2, 2.9, 0.05)], 0.025, C.mat("PVC", (0.5, 0.5, 0.48, 1), 0.5))
    # shade canopy over the seating corner (south-east): bamboo frame, corrugated tin
    for (x, y) in ((1.0, -4.6), (3.7, -4.6), (1.0, -1.8), (3.7, -1.8)):
        C.cyl("bamboo_post", 0.045, 2.35, (x, y, 1.175), bamboo, verts=12)
    sheet = C.box("tin_roof", (3.4, 3.4, 0.03), (2.35, -3.2, 2.42), tin, rot=(math.radians(-6), 0, 0))
    wave = sheet.modifiers.new("ripple", "WAVE"); wave.use_x = True; wave.use_y = False; wave.height = 0.02; wave.width = 0.08; wave.narrowness = 1.0
    sub = sheet.modifiers.new("sub", "SUBSURF"); sub.levels = 3; sub.subdivision_type = "SIMPLE"
    sheet.modifiers.move(1, 0)
    for k in range(5):
        C.cyl("bamboo_beam", 0.035, 3.3, (1.0 + k * 0.675, -3.2, 2.36), bamboo, rot=(math.radians(90 - 6), 0, 0), verts=10)
    # table, chair, the handheld radio and tablet
    C.box("table_top", (0.9, 0.6, 0.04), (2.5, -3.3, 0.72), C.mat("Wood", C.srgb("#7A5534"), 0.6, grain=0.15))
    for (x, y) in ((2.1, -3.55), (2.9, -3.55), (2.1, -3.05), (2.9, -3.05)):
        C.box("table_leg", (0.04, 0.04, 0.7), (x, y, 0.35), C.mat("Wood", C.srgb("#7A5534"), 0.6))
    chair = C.mat("ChairWhite", (0.8, 0.8, 0.78, 1), 0.4)
    C.box("chair_seat", (0.45, 0.45, 0.04), (1.75, -2.6, 0.44), chair, bevel=0.03)
    C.box("chair_back", (0.45, 0.04, 0.45), (1.75, -2.4, 0.7), chair, bevel=0.03, rot=(math.radians(-10), 0, 0))
    for (x, y) in ((1.55, -2.8), (1.95, -2.8), (1.55, -2.42), (1.95, -2.42)):
        C.cyl("chair_leg", 0.02, 0.44, (x, y, 0.22), chair, verts=10)
    C.box("radio", (0.065, 0.035, 0.17), (2.7, -3.25, 0.83), C.mat("RadioBlack", (0.02, 0.02, 0.022, 1), 0.5), rot=(math.radians(80), 0, math.radians(20)))
    C.box("tablet", (0.26, 0.18, 0.012), (2.35, -3.35, 0.746), C.mat("TabletBlack", (0.01, 0.01, 0.012, 1), 0.15, spec=0.9), rot=(0, 0, math.radians(-12)))
    C.cyl("mug", 0.04, 0.09, (2.85, -3.5, 0.785), C.mat("MugWhite", (0.85, 0.85, 0.82, 1), 0.3), verts=20)
    # clothesline from the stair room to a post
    C.cyl("line_post", 0.03, 2.0, (2.8, 3.8, 1.0), C.mat("SteelGrey", (0.25, 0.25, 0.26, 1), 0.5))
    C.tube("clothesline", [(-1.3, 3.8, 1.9), (0.8, 3.8, 1.82), (2.8, 3.8, 1.92)], 0.006, C.mat("Rope", (0.6, 0.58, 0.52, 1), 0.8))
    for k, (x, col) in enumerate(((0.0, "#B23A48"), (0.9, "#3D7A9E"), (1.7, "#E0B23B"))):
        cl = C.box("cloth", (0.6, 0.01, 0.75), (x, 3.8, 1.45), C.mat(f"Cloth{k}", C.srgb(col), 0.85))
        sb = cl.modifiers.new("sub", "SUBSURF"); sb.levels = 2; sb.subdivision_type = "SIMPLE"
        wv = cl.modifiers.new("fold", "WAVE"); wv.use_x = True; wv.use_y = False; wv.height = 0.03; wv.width = 0.18
    # plants: mustard in flower (installed PL_Tara_Bloom, scaled to a field plant's 0.6 m), leafy pots, a raised bed
    mustard = [o for o in C.import_glb(C.ROOT / "game/assets/plants/PL_Tara_Bloom/PL_Tara_Bloom.glb") if o.type == "MESH"]
    for o in mustard:
        o.hide_render = True
    proto_h = max(max((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in mustard)
    spots = [(3.55, 1.0), (3.55, 1.9), (3.55, 2.8), (3.55, 3.7), (2.6, 4.55), (1.7, 4.55), (0.8, 4.55), (3.55, -0.2), (-0.6, -4.55), (-1.6, -4.55), (-3.55, 1.2)]
    for k, (x, y) in enumerate(spots):
        pot(f"pot{k}", (x, y, 0), 0.2, 0.32, terracotta)
        for o in mustard:
            dup = o.copy(); bpy.context.scene.collection.objects.link(dup)
            dup.hide_render = False
            s = 0.62 / proto_h * rng.uniform(0.85, 1.1)
            dup.rotation_mode = "XYZ"
            dup.scale = (s, s, s)
            dup.location = (x, y, 0.16)  # its nursery pot sits inside the terracotta one
            dup.rotation_euler = (0, 0, rng.uniform(0, 6.28))
    leafy_spots = [(3.55, -1.2), (-3.55, -1.0), (-3.55, 0.1), (-3.55, -2.2), (-0.2, 4.55), (-3.55, -3.4), (0.3, -4.55), (-1.0, -4.55)]
    for k, (x, y) in enumerate(leafy_spots):
        r = rng.uniform(0.22, 0.3)
        pot(f"lpot{k}", (x, y, 0), r * 0.9, 0.36, terracotta if k % 3 else C.mat("PotGrey", (0.3, 0.3, 0.29, 1), 0.8))
        leafy(f"leafy{k}", (x, y, 0.36 + r * 0.6), r * rng.uniform(1.4, 2.0), leaf if k % 2 else leaf2, rng, n=34)
    bloom = C.mat("Bougainvillea", C.srgb("#C2307A"), 0.6)
    pot("bpot", (3.4, -4.4, 0), 0.32, 0.45, terracotta)
    leafy("bougainvillea", (3.4, -4.3, 1.0), 0.75, leaf, rng, n=40, flat=0.5)
    leafy("bougainvillea_fl", (3.45, -4.25, 1.15), 0.7, bloom, rng, n=28, flat=0.4)
    # neighbouring city: deterministic blocks round our building, lanes between, rooftop tanks, street trees
    colours = ["#E8DCC2", "#E9C9A8", "#D9B8B0", "#C8D6C0", "#B9CFDD", "#EFE2B0", "#D8C6A6", "#E5E1D8", "#C7B39A", "#D7A88C"]
    mats = [plaster(f"City{k}", c) for k, c in enumerate(colours)]
    blocks = 0
    for gx in range(-9, 10):
        for gy in range(-9, 10):
            if abs(gx) <= 0 and abs(gy) <= 0:
                continue
            cx = gx * 16.0 + rng.uniform(-2, 2)
            cy = gy * 17.0 + rng.uniform(-2, 2)
            dist = math.hypot(cx, cy)
            if dist < 9 or (20 < cx < 36):  # a 14 m road runs north-south east of her building: the morning view opens
                continue
            w, dd = rng.uniform(9, 13.5), rng.uniform(10, 14.5)
            h = FLOOR_H * int(rng.integers(3, 6 if dist < 30 else (9 if dist < 90 else 12))) + rng.uniform(0, 1)
            C.box("blk", (w, dd, h), (cx, cy, h / 2 - ROOF_Z), mats[int(rng.integers(len(mats)))])
            top = h - ROOF_Z
            if rng.random() < 0.7:
                C.cyl("blk_tank", rng.uniform(0.45, 0.7), rng.uniform(1.0, 1.5), (cx + rng.uniform(-3, 3), cy + rng.uniform(-3, 3), top + 0.7), tank_m, verts=20)
            if rng.random() < 0.5:
                C.box("blk_stair", (2.4, 2.8, 2.4), (cx + rng.uniform(-3, 3), cy + rng.uniform(-3, 3), top + 1.2), mats[int(rng.integers(len(mats)))])
            if rng.random() < 0.35 and dist < 120:
                leafy("tree", (cx + w / 2 + 2.2, cy + rng.uniform(-4, 4), -ROOF_Z + rng.uniform(6, 10)), rng.uniform(3, 4.5), leaf, rng, n=26, flat=0.7)
            blocks += 1
    C.box("street", (400, 400, 0.1), (0, 0, -ROOF_Z - 0.05), C.mat("Asphalt", (0.06, 0.06, 0.06, 1), 0.9))
    # air: a thin aerial-perspective volume (Earth has an atmosphere; this is Dhaka, not the Moon)
    vol = C.box("haze", (420, 420, 120), (0, 0, 30 - ROOF_Z), None)
    vm = bpy.data.materials.new("Haze")
    vt = vm.node_tree
    vt.nodes.remove(vt.nodes["Principled BSDF"])
    pv = vt.nodes.new("ShaderNodeVolumePrincipled")
    pv.inputs["Color"].default_value = (0.9, 0.9, 0.88, 1)
    pv.inputs["Density"].default_value = 0.0011
    vt.links.new(pv.outputs["Volume"], vt.nodes["Material Output"].inputs["Volume"])
    vol.data.materials.append(vm)
    print("BLOCKS", blocks)
    return sc


def sky(sun_az, sun_el, strength):
    w = bpy.context.scene.world
    nt = w.node_tree
    bg = nt.nodes["Background"]
    try:
        st = nt.nodes.new("ShaderNodeTexSky")
        try:
            st.sky_type = "MULTIPLE_SCATTERING"
        except Exception:
            st.sky_type = "NISHITA"
        st.sun_disc = False
        st.sun_elevation = math.radians(sun_el)
        st.sun_rotation = math.radians(90 - sun_az)  # Blender measures sun_rotation from +X, counter-clockwise
        st.air_density = 1.6
        if hasattr(st, "aerosol_density"):
            st.aerosol_density = 3.0
        nt.links.new(st.outputs["Color"], bg.inputs["Color"])
        bg.inputs["Strength"].default_value = 0.22
    except Exception as e:  # gradient fallback
        print("SKY fallback", e)
        bg.inputs["Color"].default_value = (0.45, 0.6, 0.85, 1)
        bg.inputs["Strength"].default_value = 0.6
    for o in [o for o in bpy.data.objects if o.type == "LIGHT" and o.name.startswith("Sun")]:
        bpy.data.objects.remove(o)
    C.sun_lamp(d(sun_az, sun_el), strength=strength, angle_deg=0.53)


def main():
    sc = build()
    res = (960, 540) if QUICK else (1920, 1080)
    smp = 32 if QUICK else 160
    sc.view_settings.look = "AgX - Medium High Contrast"
    sky(*SUN_S10, strength=4.2)
    # A: over Noor's shoulder to the city in the morning (CS-15-B direction)
    camA = C.camera("A", (-1.6, -2.4, 1.62), (8.0, -0.6, 1.2), 26)
    C.render(camA, C.OUT / "rooftop_A_morning_wide.png", res, smp)
    # B: the Earth-screen backdrop: camera where Aurora sees her, Noor's place at 1.2 m in focus, the roof behind her
    camB = C.camera("B", (3.35, -1.1, 1.42), (-2.2, 0.6, 1.3), 38)
    camB.data.dof.use_dof = True
    camB.data.dof.focus_distance = 1.3
    camB.data.dof.aperture_fstop = 4.0
    C.render(camB, C.OUT / "rooftop_B_backdrop_S10.png", (1536, 864) if not QUICK else (768, 432), smp)
    # C: noon on 10 April (S12, "Show me the cotton by the window."): same backdrop, high Sun from the south
    sky(*SUN_S12, strength=4.8)
    C.render(camB, C.OUT / "rooftop_C_backdrop_S12.png", (1536, 864) if not QUICK else (768, 432), smp)
    # D: plan-like overview from above the stair room
    camD = C.camera("D", (-6.5, -9.0, 9.5), (0.4, 0.2, 0.0), 24)
    sky(*SUN_S10, strength=4.2)
    C.render(camD, C.OUT / "rooftop_D_overview.png", res, smp)


main()
