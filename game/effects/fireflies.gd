class_name Fireflies
extends Node3D
## Fireflies drifting over the square, along the canal, in the alley and on the overlook: one particle swarm per
## zone in data/lighting.json, wandering on turbulence and blinking in and out.

const ZONE_POSITION: int = 0
const ZONE_SIZE: int = 3
const ZONE_AMOUNT: int = 6
const ALL_DIRECTIONS_DEG: float = 180.0
const WANDER: Vector2 = Vector2(0.05, 0.1)
const VISIBILITY_MARGIN: float = 4.0


func _ready() -> void:
	name = "Fireflies"
	for zone: Array in Tuning.doc("lighting")["fireflies"]["zones"]:
		add_child(_swarm(zone))


func _swarm(zone: Array) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Tuning.vec3(zone.slice(ZONE_SIZE, ZONE_SIZE + 3)) * 0.5
	process.gravity = Vector3.ZERO
	process.direction = Vector3.UP
	process.spread = ALL_DIRECTIONS_DEG
	process.initial_velocity_max = Tuning.look_f("fireflies", "speed")
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.0
	process.turbulence_influence_min = WANDER.x
	process.turbulence_influence_max = WANDER.y
	process.color_ramp = ParticleKit.fade_ramp()
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.amount = int(zone[ZONE_AMOUNT])
	particles.lifetime = Tuning.look_f("fireflies", "lifetime")
	particles.preprocess = particles.lifetime
	particles.position = Tuning.vec3(zone.slice(ZONE_POSITION, ZONE_POSITION + 3))
	var extents: Vector3 = process.emission_box_extents
	particles.visibility_aabb = AABB(-extents * 2.0, extents * VISIBILITY_MARGIN)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.draw_pass_1 = ParticleKit.glow_quad(Tuning.look_f("fireflies", "size"), Tuning.look_color("fireflies",
		"color"), Tuning.look_f("fireflies", "energy"))
	return particles
