class_name SparkleBurst
extends GPUParticles3D
## The cozy pop when an enemy is defeated: a one-shot burst of warm sparkles that frees itself after a timer
## (not the finished signal, which some renderers never send, so bursts would pile up).

const ALL_DIRECTIONS_DEG: float = 180.0
const FALL: float = 1.5


func _ready() -> void:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = ALL_DIRECTIONS_DEG
	var look: Dictionary = Tuning.doc("vfx")["combat"]["sparkle"]
	process.initial_velocity_max = float(look["speed"])
	process.gravity = Vector3.DOWN * FALL
	process.damping_max = float(look["speed"])
	process.color_ramp = ParticleKit.fade_ramp()
	process_material = process
	amount = int(look["amount"])
	lifetime = float(look["lifetime"])
	one_shot = true
	explosiveness = 1.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	draw_pass_1 = ParticleKit.glow_quad(float(look["size"]), Tuning.color(look["color"]), float(look["energy"]))
	emitting = true
	get_tree().create_timer(lifetime * 2.0, false).timeout.connect(queue_free)
