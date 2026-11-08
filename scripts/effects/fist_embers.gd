class_name FistEmbers
extends Node2D
## Tiny sparks drifting up from Emberoo's fists, so his fire feels alive without blinking.
##
## The fists sit in different places in each view, so the two emitters move to match
## whichever way he's facing (and rise with him when he leaps).

## Where each fist is, relative to the sprite's centre, in each view (facing right).
## A missing second fist means it's hidden behind the body in that view.
const FIST_SPOTS := {
	"front": [Vector2(-5, 1), Vector2(4, 1)],
	"frontdiag": [Vector2(5, 1), Vector2(-3, 1)],
	"side": [Vector2(6, 2)],
	"backdiag": [Vector2(5, 1), Vector2(-3, 1)],
	"back": [Vector2(-5, 1), Vector2(4, 1)],
}

@export var sparks_per_fist: int = 4
@export var spark_lifetime: float = 0.7
@export var colors: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.RED_LIGHT]

var _emitters: Array[CPUParticles2D] = []


func _ready() -> void:
	for fist in 2:
		var emitter := _make_emitter()
		add_child(emitter)
		_emitters.append(emitter)


## Call every frame with the view being shown, whether it's flipped, and the sprite's position.
func follow(view: String, is_flipped: bool, sprite_position: Vector2) -> void:
	var spots: Array = FIST_SPOTS.get(view, FIST_SPOTS["front"])
	for index in _emitters.size():
		var emitter := _emitters[index]
		var has_fist := index < spots.size()
		emitter.emitting = has_fist
		if has_fist:
			var spot: Vector2 = spots[index]
			if is_flipped:
				spot.x = -spot.x
			emitter.position = sprite_position + spot


func _make_emitter() -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.amount = sparks_per_fist
	emitter.lifetime = spark_lifetime
	emitter.local_coords = false  # sparks stay behind as Emberoo moves
	emitter.direction = Vector2.UP
	emitter.spread = 35.0
	emitter.initial_velocity_min = 6.0
	emitter.initial_velocity_max = 14.0
	emitter.gravity = Vector2(0, -12)
	emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emitter.emission_sphere_radius = 1.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([colors[0], colors[1], Color(colors[2], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	emitter.color_ramp = ramp
	return emitter
