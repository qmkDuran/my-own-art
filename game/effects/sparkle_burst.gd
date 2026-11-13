class_name SparkleBurst
extends GPUParticles3D
## The cozy pop when a creature is defeated: a one-shot burst of warm sparkles that frees itself afterwards.

const ALL_DIRECTIONS_DEG: float = 180.0
const FALL: float = 1.5


func _ready() -> void:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = ALL_DIRECTIONS_DEG
	process.initial_velocity_max = Tuning.number("defence", "sparkle", "speed")
	process.gravity = Vector3.DOWN * FALL
	process.damping_max = Tuning.number("defence", "sparkle", "speed")
	process.color_ramp = ParticleKit.fade_ramp()
	process_material = process
	amount = int(Tuning.number("defence", "sparkle", "amount"))
	lifetime = Tuning.number("defence", "sparkle", "lifetime")
	one_shot = true
	explosiveness = 1.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var colour: Color = Tuning.color(Tuning.doc("defence")["sparkle"]["color"])
	draw_pass_1 = ParticleKit.glow_quad(Tuning.number("defence", "sparkle", "size"), colour, Tuning.number("defence",
		"sparkle", "energy"))
	emitting = true
	finished.connect(queue_free)
