"""Blender (4.2, headless): builds two effect meshes and exports them as GLB, with UVs made for scrolling-gradient
shaders (u runs along the length 0..1, v across the width 0..1).
  swirl_ring: a flat crescent that spirals outwards and tapers, lying on the ground (the impact shockwave).
  spiral_ribbon: a ribbon twisting around the direction of flight, -Z forward (a projectile trail).
Run: blender -b -P tools/vfx/make_meshes.py -- OUT_DIR"""
import math
import sys

import bmesh
import bpy

OUT = sys.argv[sys.argv.index("--") + 1]
STEPS = 64


def mesh_object(name, rows):
    """rows: a list of (left point, right point) pairs along the length."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    verts = [(bm.verts.new(a), bm.verts.new(b)) for a, b in rows]
    for index in range(len(verts) - 1):
        (a0, b0), (a1, b1) = verts[index], verts[index + 1]
        face = bm.faces.new((a0, b0, b1, a1))
        u0, u1 = index / (len(verts) - 1), (index + 1) / (len(verts) - 1)
        for loop, coords in zip(face.loops, ((u0, 0.0), (u0, 1.0), (u1, 1.0), (u1, 0.0))):
            loop[uv].uv = coords
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def swirl_ring():
    rows = []
    for step in range(STEPS + 1):
        t = step / STEPS
        angle = t * math.radians(320)
        radius = 0.55 + 0.45 * t
        width = 0.22 * math.sin(math.pi * min(t * 1.1, 1.0)) + 0.02
        inner, outer = radius - width * 0.5, radius + width * 0.5
        rows.append(((math.cos(angle) * inner, math.sin(angle) * inner, 0.0),
                     (math.cos(angle) * outer, math.sin(angle) * outer, 0.0)))
    return mesh_object("swirl_ring", rows)


def spiral_ribbon():
    rows = []
    for step in range(STEPS + 1):
        t = step / STEPS
        angle = t * math.tau * 1.5
        radius = 0.08 + 0.1 * t
        width = 0.12 * (1.0 - t) + 0.02
        centre = (math.cos(angle) * radius, math.sin(angle) * radius, t * 1.6)
        side = (-math.sin(angle) * width * 0.5, math.cos(angle) * width * 0.5, 0.0)
        rows.append((tuple(c - s for c, s in zip(centre, side)), tuple(c + s for c, s in zip(centre, side))))
    return mesh_object("spiral_ribbon", rows)


def export(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=f"{OUT}/{obj.name}.glb", use_selection=True, export_yup=True)


bpy.ops.wm.read_factory_settings(use_empty=True)
export(swirl_ring())
export(spiral_ribbon())
