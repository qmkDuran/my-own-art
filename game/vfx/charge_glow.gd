class_name ChargeGlow
extends Node3D
## The heavy's build-up at the lantern: a warm orb that swells with the charge, a swirling ring that spins faster,
## motes pulled in from around it, and a light that brightens; when the charge is full it pulses once and shifts to
## a richer gold.

const RING_SHADER: Shader = preload("res://shaders/vfx_scroll.gdshader")
const SPIN: float = 4.0
const SPIN_FULL: float = 12.0
const PULSE_SECONDS: float = 0.18
const RING_FROM: float = 0.4
const WOBBLE_SPEED: float = 0.001
const WOBBLE: float = 0.5
const SWIRL: float = 4.0

var _spec: Dictionary
var _orb: Node3D
var _ring: MeshInstance3D
var _ring_material: ShaderMaterial
var _light: EffectLight
var _share: float = 0.0
var _full: bool = false


func setup(kit: VfxKit, spec: Dictionary) -> void:
	name = "ChargeGlow"
	_spec = spec
	_orb = SoftGlow.make(Tuning.color(spec["core"]), 1.0, 1.0)
	add_child(_orb)
	_ring = MeshInstance3D.new()
	_ring.mesh = kit.effect_mesh("swirl_ring")
	_ring_material = ShaderMaterial.new()
	_ring_material.shader = RING_SHADER
	_ring_material.set_shader_parameter("color", Tuning.color(spec["outer"]))
	_ring_material.set_shader_parameter("energy", 1.0)
	_ring.material_override = _ring_material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	add_child(_gather(kit))
	_light = EffectLight.make(kit.quota, Tuning.color(spec["core"]), float(spec["light_min"]), float(
		spec["light_range"]))
	if _light != null:
		add_child(_light)
	set_share(0.0)


func set_share(share: float) -> void:
	_share = share
	var size: float = lerpf(float(_spec["size_min"]), float(_spec["size_max"]), share)
	_orb.scale = Vector3.ONE * size
	_ring.scale = Vector3.ONE * float(_spec["ring_size"]) * (RING_FROM + (1.0 - RING_FROM) * share)
	if _light != null:
		_light.light_energy = lerpf(float(_spec["light_min"]), float(_spec["light_max"]), share)
	if share >= 1.0 and not _full:
		_full = true
		_ring_material.set_shader_parameter("color", Tuning.color(_spec["full_color"]))
		var pulse: Tween = _orb.create_tween()
		pulse.tween_property(_orb, "scale", Vector3.ONE * size * float(_spec["full_pulse"]), PULSE_SECONDS)
		pulse.tween_property(_orb, "scale", Vector3.ONE * size, PULSE_SECONDS)


func _process(delta: float) -> void:
	_ring.rotation.y += (SPIN_FULL if _full else SPIN * (0.5 + _share)) * delta
	_ring.rotation.x = sin(Time.get_ticks_msec() * WOBBLE_SPEED) * WOBBLE


func _gather(kit: VfxKit) -> GPUParticles3D:
	var radius: float = float(_spec["ring_size"])
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	process.emission_sphere_radius = radius
	process.radial_velocity_min = -radius * 2.0
	process.radial_velocity_max = -radius * 2.0
	process.tangential_accel_min = radius * SWIRL
	process.tangential_accel_max = radius * SWIRL
	process.gravity = Vector3.ZERO
	process.color_ramp = ParticleKit.fade_ramp()
	var motes := GPUParticles3D.new()
	motes.process_material = process
	motes.draw_pass_1 = ParticleKit.glow_quad(float(_spec["mote_size"]), Tuning.color(_spec["core"]), 1.0)
	motes.amount = kit.quota.count(int(_spec["motes"]))
	motes.lifetime = 0.5
	motes.local_coords = true
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return motes
