class_name BombBurstFx
extends Node3D
## The lantern bomb's burst, in teal spirit-fire: a flash of light, a swirling ring racing out to the blast's
## reach, a glowing dome that swells and fades, a crisp star pop, a spray of sparks, rising flame wisps, dark teal
## smoke and a scorch mark on the ground.

const DOME_SHADER: Shader = preload("res://shaders/vfx_bubble.gdshader")
const RING_SHADER: Shader = preload("res://shaders/vfx_scroll.gdshader")
const RISE: float = 2.0
const HEX: float = 3.0
const LIGHT_LIFT: float = 0.3
const POP_LIFT: float = 0.2
const RING_FROM: float = 0.2
const DOME_FRESNEL: float = 1.5
const DOME_SIZE: float = 0.8
const DOME_HOLD: float = 0.3


func play(fx: CombatFx, at: Vector3, radius: float) -> void:
	name = "BombBurstFx"
	var spec: Dictionary = fx.look("bomb")
	var kit: VfxKit = fx.kit
	kit.place(self, at)
	var colour: Color = Tuning.color(spec["color"])
	var light: EffectLight = EffectLight.make(kit.quota, colour, float(spec["flash_energy"]),
		float(spec["flash_range"]))
	if light != null:
		add_child(light)
		light.position.y = radius * LIGHT_LIFT
		light.fade_out(float(spec["flash_seconds"]))
	_ring(kit, colour, radius, float(spec["dome_seconds"]))
	_dome(spec, radius)
	var star := StarPop.new()
	add_child(star)
	star.position.y = radius * POP_LIFT
	star.play(colour, Tuning.color(spec["tip"]), float(spec["pop_size"]), float(spec["pop_seconds"]),
		float(spec["pop_energy"]))
	add_child(ParticleBursts.embers(kit.quota.count(int(spec["sparks"])), colour, float(spec["spark_size"]),
		float(spec["spark_speed"]), float(spec["spark_lifetime"])))
	var wisps: GPUParticles3D = ParticleBursts.embers(kit.quota.count(int(spec["wisps"])), Tuning.color(spec["deep"]),
		float(spec["wisp_size"]), RISE, float(spec["wisp_lifetime"]))
	(wisps.process_material as ParticleProcessMaterial).gravity = Vector3.UP * RISE
	add_child(wisps)
	add_child(ParticleBursts.smoke(kit.quota.count(int(spec["smoke"])), Tuning.color(spec["smoke_color"]),
		float(spec["smoke_size"]), float(spec["smoke_lifetime"])))
	var mark := EmberMark.new()
	kit.place(mark, at)
	mark.play(kit, spec["mark"])
	get_tree().create_timer(float(spec["smoke_lifetime"]) * 2.0, false).timeout.connect(queue_free)


func _ring(kit: VfxKit, colour: Color, radius: float, seconds: float) -> void:
	var ring := MeshInstance3D.new()
	ring.mesh = kit.effect_mesh("swirl_ring")
	var material := ShaderMaterial.new()
	material.shader = RING_SHADER
	material.set_shader_parameter("color", colour)
	material.set_shader_parameter("energy", 1.0)
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	ring.position.y = RingMesh.LIFT
	ring.scale = Vector3.ONE * radius * RING_FROM
	var tween: Tween = ring.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3.ONE * radius, seconds).set_ease(Tween.EASE_OUT).set_trans(
		Tween.TRANS_CUBIC)
	tween.tween_property(ring, "rotation:y", PI, seconds * 2.0)
	tween.tween_method(func(value: float) -> void: material.set_shader_parameter("progress", value), 0.0, 1.0,
		seconds * 2.0)
	tween.chain().tween_callback(ring.queue_free)


func _dome(spec: Dictionary, radius: float) -> void:
	var dome := Bubble.new()
	add_child(dome)
	dome.setup({ "color": spec["deep"], "edge": spec["color"], "ripple_color": spec["color"],
		"energy": spec["dome_energy"], "hex_scale": HEX, "fresnel": DOME_FRESNEL }, radius * DOME_SIZE)
	var seconds: float = float(spec["dome_seconds"])
	var tween: Tween = dome.create_tween()
	tween.tween_method(dome.set_strength, 1.0, 0.0, seconds).set_delay(seconds * DOME_HOLD)
	tween.tween_callback(dome.queue_free)
