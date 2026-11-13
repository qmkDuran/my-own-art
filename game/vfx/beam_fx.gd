class_name BeamFx
extends Node3D
## The look of the heavy's release: a glowing orange tube with a bright gold core from the lantern to where it
## ends (vfx_beam shader, fading near the camera), rings blown outwards along it, embers scattered down its length
## and a light at each end. It snaps open at full width, then thins and fades over beam_seconds.

const SHADER: Shader = preload("res://shaders/vfx_beam.gdshader")
const RING_SHADER: Shader = preload("res://shaders/vfx_scroll.gdshader")
const SEGMENTS: int = 16
const RING_ENERGY: float = 0.6
const BODY_ENERGY: float = 0.7
const CORE_WIDTH: float = 0.35
const STRAIGHT_UP: float = 0.99
const EMBER_SIZE: float = 0.15
const EMBER_SPEED: float = 4.0
const EMBER_SPREAD: float = 0.3
const LIGHT_LINGER: float = 1.5
const RING_GROW: float = 2.2

var _materials: Array[ShaderMaterial] = []


func play(kit: VfxKit, spec: Dictionary, from: Vector3, to: Vector3, width: float, seconds: float) -> void:
	name = "BeamFx"
	var length: float = from.distance_to(to)
	kit.place(self, (from + to) * 0.5)
	basis = Basis.looking_at(from.direction_to(to), Vector3.UP if absf(from.direction_to(to).y) < STRAIGHT_UP else
		Vector3.RIGHT)
	_tube(spec, length, width, float(spec["energy"]) * BODY_ENERGY)
	_tube({ "core": spec["core"], "outer": spec["core"] }, length, width * CORE_WIDTH, float(spec["energy"]))
	_rings(kit, spec, length, width, seconds)
	var embers: GPUParticles3D = ParticleBursts.embers(kit.quota.count(int(spec["embers"])), Tuning.color(
		spec["outer"]), width * EMBER_SIZE, width * EMBER_SPEED, seconds * 2.0)
	var process: ParticleProcessMaterial = embers.process_material
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(width * EMBER_SPREAD, width * EMBER_SPREAD, length * 0.5)
	embers.local_coords = false
	add_child(embers)
	for end: Vector3 in [from, to]:
		var light: EffectLight = EffectLight.make(kit.quota, Tuning.color(spec["core"]), float(spec["light_energy"]),
			float(spec["light_range"]))
		if light != null:
			kit.place(light, end)
			light.fade_out(seconds * LIGHT_LINGER)
	var tween: Tween = create_tween()
	tween.tween_method(_fade, 1.0, 0.0, seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(seconds * 2.0)
	tween.tween_callback(queue_free)


func _fade(value: float) -> void:
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter("fade", value)
	for child: Node in get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is CylinderMesh:
			(child as MeshInstance3D).scale = Vector3(value, value, 1.0)


func _tube(spec: Dictionary, length: float, width: float, energy: float) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = width * 0.5
	cylinder.bottom_radius = width * 0.5
	cylinder.height = length
	cylinder.radial_segments = SEGMENTS
	cylinder.rings = 1
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("core_color", Tuning.color(spec["core"]))
	material.set_shader_parameter("outer_color", Tuning.color(spec["outer"]))
	material.set_shader_parameter("energy", energy)
	cylinder.material = material
	_materials.append(material)
	var tube := MeshInstance3D.new()
	tube.mesh = cylinder
	tube.rotation.x = PI * 0.5
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tube)


## Rings blown outward along the beam, staggered from the lantern to the end.
func _rings(kit: VfxKit, spec: Dictionary, length: float, width: float, seconds: float) -> void:
	var count: int = int(spec["rings"])
	for index: int in count:
		var ring := MeshInstance3D.new()
		ring.mesh = kit.effect_mesh("swirl_ring")
		var material := ShaderMaterial.new()
		material.shader = RING_SHADER
		material.set_shader_parameter("color", Tuning.color(spec["outer"]))
		material.set_shader_parameter("energy", RING_ENERGY)
		ring.material_override = material
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		ring.position.z = length * 0.5 - length * (index + 0.5) / count
		ring.rotation.x = PI * 0.5
		ring.scale = Vector3.ONE * width * float(spec["ring_size"])
		var tween: Tween = ring.create_tween().set_parallel()
		tween.tween_property(ring, "scale", Vector3.ONE * width * float(spec["ring_size"]) * RING_GROW, seconds)
		tween.tween_method(func(value: float) -> void: material.set_shader_parameter("progress", value), 0.0, 1.0,
			seconds)
