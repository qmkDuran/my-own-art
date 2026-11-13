"""Blender (4.2, headless): renders the frames of two soft effect flipbooks with Cycles on a transparent film.
  ember_burst: warm amber embers flying out of a soft glow, cooling to deep orange as they fade.
  smoke_puff: a small curling puff of warm grey smoke that swells, rises and thins out.
Soft edges everywhere (the glow rule: no white-hot cores). Pack the frames with pack_flipbook.py.
Run: blender -b -P tools/vfx/make_flipbooks.py -- OUT_DIR [FRAMES] [TILE_PX]"""
import math
import random
import sys

import bpy

ARGS = sys.argv[sys.argv.index("--") + 1:]
OUT = ARGS[0]
FRAMES = int(ARGS[1]) if len(ARGS) > 1 else 25
TILE = int(ARGS[2]) if len(ARGS) > 2 else 200
EMBERS = 22
EMBER_HOT = (1.0, 0.68, 0.28)
EMBER_COOL = (0.85, 0.28, 0.08)
SMOKE = (0.72, 0.64, 0.64)


def reset(samples):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.render.film_transparent = True
    scene.render.resolution_x = TILE
    scene.render.resolution_y = TILE
    scene.view_settings.view_transform = "Standard"
    scene.frame_start = 1
    scene.frame_end = FRAMES
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 4.0
    cam.location = (0, -10, 0)
    cam.rotation_euler = (math.pi / 2, 0, 0)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return scene


def soft_emission(name):
    """Emission that fades to transparent towards the silhouette edge (a soft sprite, never a hard disc)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    mix = nodes.new("ShaderNodeMixShader")
    clear = nodes.new("ShaderNodeBsdfTransparent")
    glow = nodes.new("ShaderNodeEmission")
    facing = nodes.new("ShaderNodeLayerWeight")
    power = nodes.new("ShaderNodeMath")
    power.operation = "POWER"
    power.inputs[1].default_value = 2.2
    invert = nodes.new("ShaderNodeMath")
    invert.operation = "SUBTRACT"
    invert.inputs[0].default_value = 1.0
    links.new(facing.outputs["Facing"], invert.inputs[1])
    links.new(invert.outputs[0], power.inputs[0])
    links.new(power.outputs[0], mix.inputs[0])
    links.new(clear.outputs[0], mix.inputs[1])
    links.new(glow.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], out.inputs[0])
    return mat, glow


def key_ember(obj, glow, frame, position, size, heat, strength):
    obj.location = position
    obj.scale = (size, size, size)
    obj.keyframe_insert("location", frame=frame)
    obj.keyframe_insert("scale", frame=frame)
    colour = [EMBER_HOT[i] * heat + EMBER_COOL[i] * (1 - heat) for i in range(3)] + [1.0]
    glow.inputs["Color"].default_value = colour
    glow.inputs["Strength"].default_value = strength
    glow.inputs["Color"].keyframe_insert("default_value", frame=frame)
    glow.inputs["Strength"].keyframe_insert("default_value", frame=frame)


def ember_burst():
    scene = reset(48)
    rng = random.Random(7)
    core, core_glow = soft_emission("core")
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16)
    centre = bpy.context.object
    centre.data.materials.append(core)
    for frame in range(1, FRAMES + 1):
        t = (frame - 1) / (FRAMES - 1)
        key_ember(centre, core_glow, frame, (0, 0, 0), 0.7 * (1 - t) ** 2 + 0.01, 0.6, 0.9 * (1 - t) ** 3)
    for index in range(EMBERS):
        mat, glow = soft_emission(f"ember{index}")
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8)
        ember = bpy.context.object
        ember.data.materials.append(mat)
        angle = rng.uniform(0, math.tau)
        speed = rng.uniform(0.7, 1.1)
        size = rng.uniform(0.12, 0.22)
        for frame in range(1, FRAMES + 1):
            t = (frame - 1) / (FRAMES - 1)
            reach = speed * (1 - (1 - t) ** 2.5) * 1.4
            pos = (math.cos(angle) * reach, 0, math.sin(angle) * reach + t * t * 0.5)
            key_ember(ember, glow, frame, pos, size * (1 - t * 0.7), 1 - t, 1.0 * (1 - t) ** 1.2)
    render(scene, "ember_burst")


def smoke_puff():
    scene = reset(24)
    bpy.ops.mesh.primitive_cube_add(size=2.0)
    domain = bpy.context.object
    mat = bpy.data.materials.new("smoke")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    volume = nodes.new("ShaderNodeVolumePrincipled")
    volume.inputs["Color"].default_value = SMOKE + (1.0,)
    coords = nodes.new("ShaderNodeTexCoord")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 2.2
    noise.inputs["Detail"].default_value = 3.0
    noise.noise_dimensions = "4D"
    sphere = nodes.new("ShaderNodeTexGradient")
    sphere.gradient_type = "SPHERICAL"
    shape = nodes.new("ShaderNodeMath")
    shape.operation = "MULTIPLY"
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.25
    ramp.color_ramp.elements[1].position = 0.6
    density = nodes.new("ShaderNodeMath")
    density.operation = "MULTIPLY"
    links.new(coords.outputs["Object"], noise.inputs["Vector"])
    links.new(coords.outputs["Object"], sphere.inputs["Vector"])
    links.new(sphere.outputs["Fac"], shape.inputs[0])
    links.new(noise.outputs["Fac"], shape.inputs[1])
    links.new(shape.outputs[0], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], density.inputs[0])
    links.new(density.outputs[0], volume.inputs["Density"])
    links.new(volume.outputs[0], out.inputs["Volume"])
    domain.data.materials.append(mat)
    light = bpy.data.objects.new("warm", bpy.data.lights.new("warm", "POINT"))
    light.data.energy = 900
    light.data.color = (1.0, 0.7, 0.45)
    light.location = (0.5, -2.5, -1.5)
    scene.collection.objects.link(light)
    world = bpy.data.worlds.new("w")
    world.color = (0.08, 0.08, 0.12)
    scene.world = world
    for frame in range(1, FRAMES + 1):
        t = (frame - 1) / (FRAMES - 1)
        size = 0.75 + 0.7 * (1 - (1 - t) ** 2)
        domain.scale = (size, size, size)
        domain.location = (0.15 * math.sin(t * 3.0), 0, -0.6 + t * 1.0)
        domain.rotation_euler = (0, t * 1.4, 0)
        noise.inputs["W"].default_value = t * 1.5
        density.inputs[1].default_value = 14.0 * (1 - t) ** 1.4
        for socket in (density.inputs[1], noise.inputs["W"]):
            socket.keyframe_insert("default_value", frame=frame)
        for path in ("scale", "location", "rotation_euler"):
            domain.keyframe_insert(path, frame=frame)
    render(scene, "smoke_puff")


def render(scene, name):
    for frame in range(1, FRAMES + 1):
        scene.frame_set(frame)
        scene.render.filepath = f"{OUT}/{name}_{frame:02d}.png"
        bpy.ops.render.render(write_still=True)


ember_burst()
smoke_puff()
