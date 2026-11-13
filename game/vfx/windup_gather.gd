class_name WindupGather
extends Node3D
## The wind-up of a cast: a ring of soft motes rushing in to the lantern and a little glow pulse there, over a
## tenth of a second or so. Frees itself.

const MOTE_ENERGY: float = 1.2
const PULSE_ENERGY: float = 1.0
const RING_FLATTEN: float = 0.6
const GONE: float = 0.01
const LINGER_SHARE: float = 4.0


func play(kit: VfxKit, spec: Dictionary) -> void:
	name = "WindupGather"
	var seconds: float = spec["seconds"]
	var colour: Color = Tuning.color(spec["color"])
	var radius: float = spec["radius"]
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	process.emission_sphere_radius = radius
	process.radial_velocity_min = -radius / seconds
	process.radial_velocity_max = -radius / seconds
	process.gravity = Vector3.ZERO
	process.scale_min = RING_FLATTEN
	process.tangential_accel_min = radius / seconds / seconds
	process.tangential_accel_max = radius / seconds / seconds
	process.color_ramp = ParticleKit.fade_ramp()
	var motes := GPUParticles3D.new()
	motes.process_material = process
	motes.draw_pass_1 = ParticleKit.glow_quad(float(spec["mote_size"]), colour, MOTE_ENERGY)
	motes.amount = kit.quota.count(int(spec["motes"]))
	motes.lifetime = seconds
	motes.one_shot = true
	motes.explosiveness = 1.0
	motes.emitting = true
	add_child(motes)
	var pulse: Node3D = SoftGlow.make(colour, float(spec["mote_size"]) * 2.0, PULSE_ENERGY)
	add_child(pulse)
	var swell: EffectLight = EffectLight.make(kit.quota, colour, float(spec["light_energy"]), radius * 2.0)
	if swell != null:
		add_child(swell)
		swell.fade_out(seconds * 2.0)
	var tween: Tween = create_tween()
	tween.tween_property(pulse, "scale", Vector3.ONE * float(spec["pulse"]), seconds)
	tween.tween_property(pulse, "scale", Vector3.ONE * GONE, seconds)
	tween.tween_interval(seconds * LINGER_SHARE)
	tween.tween_callback(queue_free)
