class_name SunFx
extends Node3D
## The Sunrise's giant lantern sun: a boiling sphere (vfx_sun shader), a slowly turning crown of long rays, a wide
## soft corona, a swirl ring around it, motes rushing in while it forms, and a big warm light that bathes the whole
## area. It swells into being, burns, then flares and collapses.

const SUN_SHADER: Shader = preload("res://shaders/vfx_sun.gdshader")
const RING_SHADER: Shader = preload("res://shaders/vfx_scroll.gdshader")
const FROM: float = 0.05
const FLARE: float = 1.35
const RAY_INNER: float = 0.55
const RAY_WIDTH: float = 0.12
const SEGMENTS: int = 32
const RING_TILT: float = 0.35
const RING_SIZE: float = 1.2
const GATHER_MOTE: float = 0.25
const FLARE_SHARE: float = 0.35
const SHORT_RAY: float = 0.6

var _spec: Dictionary
var _rays: MeshInstance3D
var _ring: MeshInstance3D
var _light: OmniLight3D


func setup(kit: VfxKit, spec: Dictionary, size: float) -> void:
	name = "SunFx"
	_spec = spec
	add_child(_sphere(size * 0.5))
	add_child(SoftGlow.make(Tuning.color(spec["corona"]), size * float(spec["halo_size"]) / SoftGlow.HALO_SIZE,
		float(spec["halo_strength"])))
	_rays = _crown(size * 0.5)
	add_child(_rays)
	_ring = MeshInstance3D.new()
	_ring.mesh = kit.effect_mesh("swirl_ring")
	var material := ShaderMaterial.new()
	material.shader = RING_SHADER
	material.set_shader_parameter("color", Tuning.color(spec["mid"]))
	material.set_shader_parameter("energy", 1.0)
	_ring.material_override = material
	_ring.scale = Vector3.ONE * size * RING_SIZE
	_ring.rotation.x = RING_TILT
	add_child(_ring)
	_light = OmniLight3D.new()
	_light.light_color = Tuning.look_color("sunrise", "sun_color")
	_light.light_energy = 0.0
	_light.omni_range = Tuning.look_f("sunrise", "sun_light_range")
	_light.shadow_enabled = false
	add_child(_light)
	scale = Vector3.ONE * FROM


## Swells into being over a time while motes rush in.
func form(kit: VfxKit, seconds: float) -> void:
	var gather := WindupGather.new()
	add_child(gather)
	gather.play(kit, { "seconds": seconds, "motes": _spec["gather_motes"], "radius": float(_spec["gather_radius"]) /
		scale.x, "mote_size": GATHER_MOTE, "pulse": 1.0, "color": _spec["ray_color"], "light_energy": 0.0 })
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector3.ONE, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_light, "light_energy", Tuning.look_f("sunrise", "sun_light_energy"), seconds)


## Flares up and collapses to nothing, then frees itself.
func collapse(seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * FLARE, seconds * FLARE_SHARE).set_ease(Tween.EASE_OUT)
	var shrink: float = seconds * (1.0 - FLARE_SHARE)
	tween.tween_property(self, "scale", Vector3.ONE * FROM, shrink).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(_light, "light_energy", 0.0, shrink)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_rays.rotation.z += float(_spec["spin"]) * delta
	_ring.rotation.y += float(_spec["spin"]) * 2.0 * delta


func _sphere(radius: float) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = SEGMENTS
	sphere.rings = SEGMENTS / 2
	var material := ShaderMaterial.new()
	material.shader = SUN_SHADER
	for key: String in ["core", "mid", "edge"]:
		material.set_shader_parameter(key + "_color", Tuning.color(_spec[key]))
	material.set_shader_parameter("energy", float(_spec["energy"]))
	sphere.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


## A camera-facing crown of long tapering rays (vertex colours fading out to the tips).
func _crown(radius: float) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var rays: int = int(_spec["rays"])
	var colour: Color = Tuning.color(_spec["ray_color"])
	for index: int in rays:
		var angle: float = TAU * index / rays
		var length: float = radius + float(_spec["ray_length"]) * radius * (1.0 if index % 2 == 0 else SHORT_RAY)
		var side := Vector3(cos(angle + PI * 0.5), sin(angle + PI * 0.5), 0.0) * radius * RAY_WIDTH
		var root := Vector3(cos(angle), sin(angle), 0.0) * radius * RAY_INNER
		vertices.append_array([root + side, root - side, Vector3(cos(angle), sin(angle), 0.0) * length])
		colours.append_array([colour, colour, Color(colour.r, colour.g, colour.b, 0.0)])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colours
	var crown := ArrayMesh.new()
	crown.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := MeshInstance3D.new()
	mesh.mesh = crown
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh
