"""M1-32: reproducible Blender exterior art studies, NOT surveyed lunar terrain.

blender -b --python-exit-code 1 -P production/concept/lookdev_exterior_v1/render_studies.py -- --shot aurora --option A
Four settings; Aurora is rendered in A/B with identical camera, geometry and lights.
Only local approved GLBs are imported. Source assets and gameplay are untouched.
"""
import argparse
import hashlib
import json
import math
import random
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WORK = ROOT / "production/models/lookdev_exterior_v1"
ASSETS = ROOT / "game/assets"
USED = {}


def mat(name, color, roughness=.8, metal=0, emission=0):
    m = bpy.data.materials.new(name)
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color,1)
    bs.inputs["Roughness"].default_value = roughness
    bs.inputs["Metallic"].default_value = metal
    if emission:
        bs.inputs["Emission Color"].default_value = (*color,1)
        bs.inputs["Emission Strength"].default_value = emission
    return m


def cube(name, position, dimensions, material, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=position)
    obj=bpy.context.object
    obj.name=name
    obj.dimensions=dimensions
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(material)
    if bevel:
        mod=obj.modifiers.new("Fabricated edges","BEVEL")
        mod.width=bevel
        mod.segments=3
        obj.modifiers.new("Corner normals","WEIGHTED_NORMAL")
    return obj


def aim(obj, point):
    obj.rotation_euler=(Vector(point)-obj.location).to_track_quat("-Z","Y").to_euler()


def load_asset(category, name, position=(0,0,0), yaw=0, character=False, option="B"):
    path=ASSETS/category/name/(name+".glb")
    USED[path.relative_to(ROOT).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    before=set(bpy.context.scene.objects)
    old_actions=set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=str(path))
    objects=set(bpy.context.scene.objects)-before
    shapes={p.custom_shape for o in objects if o.type=="ARMATURE" for p in o.pose.bones}
    for o in list(objects):
        if o in shapes:
            objects.remove(o)
            bpy.data.objects.remove(o,do_unlink=True)
    if character:
        arm=next(o for o in objects if o.type=="ARMATURE")
        for track in arm.animation_data.nla_tracks:
            track.mute=True
        action=next(a for a in set(bpy.data.actions)-old_actions if a.name.split(".")[0]=="Idle_loop")
        arm.animation_data.action=action
        if action.slots:
            arm.animation_data.action_slot=action.slots[0]
        bpy.context.scene.frame_set(12)
    parent=bpy.data.objects.new(name+"_Placement",None)
    bpy.context.collection.objects.link(parent)
    for obj in objects:
        if obj.parent not in objects:
            obj.parent=parent
        if obj.type!="MESH":
            continue
        if obj.name.startswith("Face"):
            # Neutral atlas cell is transparent: the approved painted feature shows.
            obj.hide_render=True
            continue
        for slot in obj.material_slots:
            if not slot.material:
                continue
            m=slot.material.copy()
            slot.material=m
            bs=next((n for n in m.node_tree.nodes if n.type=="BSDF_PRINCIPLED"),None)
            if not bs:
                continue
            for socket_name in ("Metallic", "Roughness"):
                for link in list(bs.inputs[socket_name].links):
                    m.node_tree.links.remove(link)
            bs.inputs["Metallic"].default_value=0
            bs.inputs["Roughness"].default_value=.82
            if character:
                bs.inputs["Roughness"].default_value=.78
                # Keep material textures, face, kit, anatomy and pose identical.
                if option=="A":
                    toon_material(m, bs)
        if character and option=="A" and obj.name.startswith("Body"):
            outline(obj)
    parent.location=position
    parent.rotation_euler.z=yaw
    return parent, list(objects)


def toon_material(material, bs):
    nt=material.node_tree
    base_socket=bs.inputs["Base Color"]
    base=base_socket.links[0].from_socket if base_socket.is_linked else None
    alpha_socket=bs.inputs["Alpha"]
    alpha=alpha_socket.links[0].from_socket if alpha_socket.is_linked else None
    diffuse=nt.nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.inputs["Color"].default_value=(1,1,1,1)
    lighting=nt.nodes.new("ShaderNodeShaderToRGB")
    nt.links.new(diffuse.outputs[0],lighting.inputs[0])
    ramp=nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation="CONSTANT"
    ramp.color_ramp.elements.remove(ramp.color_ramp.elements[1])
    e=ramp.color_ramp.elements[0]
    e.position=0
    e.color=(.18,.16,.23,1)
    e=ramp.color_ramp.elements.new(.18)
    e.color=(.7,.7,.75,1)
    e=ramp.color_ramp.elements.new(.62)
    e.color=(1,1,1,1)
    nt.links.new(lighting.outputs[0],ramp.inputs[0])
    multiply=nt.nodes.new("ShaderNodeMixRGB")
    multiply.blend_type="MULTIPLY"
    multiply.inputs[0].default_value=1
    nt.links.new(ramp.outputs[0],multiply.inputs[1])
    if base:
        nt.links.new(base,multiply.inputs[2])
    else:
        multiply.inputs[2].default_value=base_socket.default_value
    emission=nt.nodes.new("ShaderNodeEmission")
    nt.links.new(multiply.outputs[0],emission.inputs[0])
    out=next(n for n in nt.nodes if n.type=="OUTPUT_MATERIAL")
    if alpha:
        transparent=nt.nodes.new("ShaderNodeBsdfTransparent")
        mix=nt.nodes.new("ShaderNodeMixShader")
        nt.links.new(alpha,mix.inputs[0])
        nt.links.new(transparent.outputs[0],mix.inputs[1])
        nt.links.new(emission.outputs[0],mix.inputs[2])
        nt.links.new(mix.outputs[0],out.inputs["Surface"])
    else:
        nt.links.new(emission.outputs[0],out.inputs["Surface"])


def outline(body):
    edge=body.copy()
    edge.data=body.data.copy()
    bpy.context.collection.objects.link(edge)
    edge.name="CelOutline"
    black=bpy.data.materials.new("Ink_Backfaces")
    nt=black.node_tree
    nt.nodes.clear()
    geom=nt.nodes.new("ShaderNodeNewGeometry")
    transparent=nt.nodes.new("ShaderNodeBsdfTransparent")
    ink=nt.nodes.new("ShaderNodeEmission")
    ink.inputs[0].default_value=(.007,.011,.018,1)
    mix=nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(geom.outputs["Backfacing"],mix.inputs[0])
    nt.links.new(transparent.outputs[0],mix.inputs[1])
    nt.links.new(ink.outputs[0],mix.inputs[2])
    out=nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(mix.outputs[0],out.inputs[0])
    edge.data.materials.clear()
    edge.data.materials.append(black)
    mod=edge.modifiers.new("Fine ink silhouette","DISPLACE")
    mod.strength=.0022
    mod.mid_level=0


def height(x,y, shot):
    # Broad placeholder landforms for composition only. M1-34 replaces these
    # with real LOLA crops; never claim these values are lunar measurements.
    z=9*np.sin(x*.003+y*.0015)+6*np.sin(y*.004-x*.002)
    for cx,cy,r,depth in ((-270,470,220,85),(580,870,420,105),(-850,1600,600,115),(170,1700,470,72)):
        d=np.sqrt((x-cx)**2+(y-cy)**2)
        z += depth*.65*np.exp(-((d-r)/(r*.18))**2)-depth*np.exp(-(d/(r*.72))**4)
    z += .6*np.sin(x*.13+y*.037)+.35*np.sin(x*.04-y*.19)
    r=np.sqrt(x*x+y*y)
    z *= np.clip((r-40)/100,0,1)
    if shot=="summit":
        z-=np.clip((r-90)/220,0,1)*65
    if shot=="coldtrap":
        z+=np.clip((r-50)/220,0,1)*80
    return z


def terrain(shot):
    t=np.linspace(-1,1,401)
    coordinates=np.sign(t)*np.abs(t)**2.35*2300
    x,y=np.meshgrid(coordinates,coordinates)
    z=height(x,y,shot)
    vertices=np.stack([x.ravel(),y.ravel(),z.ravel()],axis=1).tolist()
    n=len(t)
    faces=[(i*n+j,i*n+j+1,(i+1)*n+j+1,(i+1)*n+j) for i in range(n-1) for j in range(n-1)]
    mesh=bpy.data.meshes.new("TerrainProxy_NotLOLA")
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj=bpy.data.objects.new("TerrainProxy_NotSurveyed",mesh)
    bpy.context.collection.objects.link(obj)
    for p in mesh.polygons:
        p.use_smooth=True
    surface=mat("GreyRegolith_ArtStudy",(.24,.24,.24),.96)
    nt=surface.node_tree
    bs=nt.nodes.get("Principled BSDF")
    geometry=nt.nodes.new("ShaderNodeTexCoord")
    noise=nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value=5
    noise.inputs["Detail"].default_value=5
    nt.links.new(geometry.outputs["Object"],noise.inputs["Vector"])
    ramp=nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color=(.11,.115,.12,1)
    ramp.color_ramp.elements[1].color=(.31,.315,.32,1)
    nt.links.new(noise.outputs["Fac"],ramp.inputs[0])
    nt.links.new(ramp.outputs[0],bs.inputs["Base Color"])
    fine=nt.nodes.new("ShaderNodeTexNoise")
    fine.inputs["Scale"].default_value=115
    fine.inputs["Detail"].default_value=2
    nt.links.new(geometry.outputs["Object"],fine.inputs["Vector"])
    bump=nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value=.48
    bump.inputs["Distance"].default_value=.014
    nt.links.new(fine.outputs["Fac"],bump.inputs["Height"])
    nt.links.new(bump.outputs[0],bs.inputs["Normal"])
    mesh.materials.append(surface)
    return surface


def scatter(shot,surface):
    rng=random.Random(320411)
    catalog=json.loads((ASSETS/"environment/terrain/kit.json").read_text())
    prototypes=[]
    for rock in catalog["rocks"]:
        path=ROOT/"game"/rock["lods"][1].removeprefix("res://")
        USED[path.relative_to(ROOT).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
        before=set(bpy.context.scene.objects)
        bpy.ops.import_scene.gltf(filepath=str(path))
        objects=set(bpy.context.scene.objects)-before
        mesh=next(o for o in objects if o.type=="MESH")
        mesh.data.materials.clear()
        mesh.data.materials.append(surface)
        prototypes.append((mesh.data,rock["size_m"]))
        for obj in objects:
            bpy.data.objects.remove(obj,do_unlink=True)
    for i in range(750):
        x,y=rng.uniform(-280,280),rng.uniform(-80,450)
        if abs(x)<7 and y<200 or abs(x)<17 and -15<y<22:
            continue
        prototype,size=prototypes[rng.randrange(9 if x*x+y*y<80*80 else 16)]
        rock=bpy.data.objects.new("Rock",prototype)
        bpy.context.collection.objects.link(rock)
        rock.location=(x,y,float(height(x,y,shot))-.06*size)
        rock.rotation_euler.z=rng.uniform(0,math.tau)
    return prototypes


def area(name,pos,target,energy,color,size):
    data=bpy.data.lights.new(name,"AREA")
    data.energy=energy
    data.color=color
    data.shape="DISK"
    data.size=size
    light=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(light)
    light.location=pos
    aim(light,target)
    return light


def sun(shot):
    if shot=="coldtrap":
        return
    data=bpy.data.lights.new("Sun_1p5deg_Study_NotEphemeris","SUN")
    data.energy=5
    data.angle=math.radians(.53)
    light=bpy.data.objects.new(data.name,data)
    bpy.context.collection.objects.link(light)
    elevation=math.radians(1.5)
    direction=Vector((-.6,-.8,math.tan(elevation))).normalized()
    light.rotation_euler=(-direction).to_track_quat("-Z","Y").to_euler()


def observation_room(option):
    white=mat("HabitatIvory",(.55,.6,.65),.42,.15)
    navy=mat("HabitatNavy",(.025,.04,.065),.6,.2)
    lamp=mat("PracticalLight",(.8,.91,1),.4,0,3)
    cube("PressurizedBayFloor",(0,-2.5,2.35),(11,12,.3),navy,.08)
    cube("PressurizedBayRoof",(0,-2.5,6.3),(11,12,.3),navy,.08)
    for x in (-5.4,5.4):
        cube("PressureSideWall",(x,-2.5,4.4),(.25,12,4),white,.06)
        cube("WindowFrame",(x,3.35,4.4),(.35,.35,4),navy,.05)
    cube("SealedRearBulkhead",(0,-8.4,4.4),(11,.25,4),white)
    cube("WindowLowerSill",(0,3.35,2.68),(11,.42,.5),white,.05)
    cube("WindowTopSill",(0,3.35,6.1),(11,.42,.3),white,.04)
    # Clear glazing with restrained reflection; closed pressure boundary.
    glass=mat("ViewportGlazing",(.7,.8,.9),.08)
    nt=glass.node_tree
    out=nt.nodes.get("Material Output")
    transparent=nt.nodes.new("ShaderNodeBsdfTransparent")
    nt.links.new(transparent.outputs[0],out.inputs[0])
    cube("SealedViewport",(0,3.35,4.4),(10.5,.04,3.5),glass)
    for x in (-3,2.7):
        cube("CeilingPractical",(x,-2.3,6.05),(.12,5,.06),lamp,.02)
    area("BayPracticalKey",(1,-3,5.9),(-1,0,3.5),580,(1,.92,.82),2.5)
    area("BayPracticalFill",(-3,-3,5.9),(-1,0,3.5),140,(.75,.86,1),2)
    load_asset("characters","CH_Kai",(-.9,.15,2.52),.22,True,option)
    load_asset("characters","CH_Amara",(-2.5,1.15,2.52),-.22,True,option)


def headlights(position):
    for x in (-1.3,1.3):
        light=bpy.data.lights.new("RoverHeadlamp","SPOT")
        light.energy=2800
        light.color=(.85,.91,1)
        light.spot_size=math.radians(65)
        light.spot_blend=.25
        light.shadow_soft_size=.08
        obj=bpy.data.objects.new(light.name,light)
        bpy.context.collection.objects.link(obj)
        obj.location=(position[0]+x,position[1]-3.15,position[2]+1.65)
        aim(obj,(position[0]+x,position[1]-40,position[2]))


def scene_content(shot,option):
    surface=terrain(shot)
    scatter(shot,surface)
    if shot=="aurora":
        observation_room(option)
        for i in range(3):
            load_asset("environment","EN_ExteriorModule",(12+i*5,55+(i%2)*2,0),.2)
        load_asset("environment","EN_SolarMast",(-16,39,0),.35)
        load_asset("environment","EN_SolarMast",(-29,54,0),.35)
        load_asset("vehicles","VH_Rover",(2,40,0),.3)
        return (1.3,-5,3.9),(-.3,14,3.8),28
    if shot=="road":
        load_asset("vehicles","VH_Rover",(0,8,0),math.pi+.2)
        for i in range(3):
            load_asset("props","PR_SurveyBeacon",(6,35+i*37,float(height(6,35+i*37,shot))))
        return (12,-17,3.3),(-6,60,5),40
    if shot=="coldtrap":
        load_asset("vehicles","VH_Rover",(0,15,0),0)
        headlights((0,15,0))
        load_asset("props","PR_VaultCase",(2,-5,0),.2)
        return (4,0,1.6),(2,-5,.28),33
    load_asset("props","PR_MalapertRelay",(-3,3,0),-.4)
    load_asset("vehicles","VH_Rover",(12,8,0),.7)
    platform=mat("SummitPlatform",(.18,.2,.22),.6,.25)
    cube("RelayServicePad",(-3,3,-.12),(10,9,.22),platform,.04)
    return (12,-15,5),(-14,65,-10),32


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--shot",choices=("aurora","road","coldtrap","summit"),required=True)
    parser.add_argument("--option",choices=("A","B"),default="B")
    parser.add_argument("--width",type=int,default=1920)
    parser.add_argument("--samples",type=int,default=64)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    WORK.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene
    scene.render.engine="BLENDER_EEVEE"
    scene.eevee.taa_render_samples=args.samples
    scene.world=bpy.data.worlds.new("AirlessBlack")
    scene.world.node_tree.nodes["Background"].inputs[0].default_value=(0,0,0,1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value=0
    scene.render.resolution_x=args.width
    scene.render.resolution_y=args.width*9//16
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.view_settings.view_transform="AgX"
    scene.view_settings.look="AgX - Medium High Contrast"
    scene.view_settings.exposure=.35
    position,target,lens=scene_content(args.shot,args.option)
    sun(args.shot)
    camera=bpy.data.objects.new("Camera",bpy.data.cameras.new("Camera"))
    bpy.context.collection.objects.link(camera)
    camera.location=position
    camera.data.lens=lens
    camera.data.clip_start=.05
    camera.data.clip_end=8000
    aim(camera,target)
    scene.camera=camera
    scene.render.film_transparent=False
    name=args.shot+("_"+args.option if args.shot=="aurora" else "")
    scene.render.filepath=str(WORK/(name+".png"))
    # Save provenance and art variables, not a redundant binary scene.
    metadata={"task":"M1-32","shot":args.shot,"option":args.option,"blender":bpy.app.version_string,
              "camera":{"position":position,"target":target,"lens_mm":lens},"sun_elevation_deg":None if args.shot=="coldtrap" else 1.5,
              "terrain":"procedural composition proxy; NOT LOLA or surveyed geography", "earth":"omitted pending verified viewing geometry",
              "cast":"approved Kai/Amara indoor coveralls, inside sealed pressurized bay" if args.shot=="aurora" else "no exposed crew",
              "inputs_sha256":USED,"resolution":[scene.render.resolution_x,scene.render.resolution_y],"samples":args.samples}
    (WORK/(name+".json")).write_text(json.dumps(metadata,indent=2)+"\n",encoding="utf-8")
    bpy.ops.render.render(write_still=True)
    print("LOOKDEV_RENDER_PASS",name)


if __name__=="__main__":
    main()
