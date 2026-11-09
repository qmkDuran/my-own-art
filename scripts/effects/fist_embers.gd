class_name FistEmbers
extends Node2D
## Tiny sparks drifting up from Emberoo's fists, so his fire feels alive without blinking.
##
## The fists sit in different places in each view and each evolution form, so the two
## emitters move to match whichever way he's facing (and rise with him when he leaps).
## HeroFormSwitch hands over the current form's `fist_spots`. The sparks take Emberoo's
## fire colours (EmberooFlameColors).

@export var sparks_per_fist: int = 4
@export var spark_lifetime: float = 0.7

## Where each fist is, from the feet, in each view (facing right); see HeroForm.fist_spots.
## A missing second fist means it's hidden behind the body in that view.
var fist_spots: Dictionary[String, Array] = {}

var _emitters: Array[CPUParticles2D] = []


func _ready() -> void:
	for fist in 2:
		var emitter := _make_emitter()
		add_child(emitter)
		_emitters.append(emitter)


## Call every frame with the view being shown, whether it's flipped, and how far the sprite
## is lifted off the feet.
func follow(view: String, is_flipped: bool, sprite_lift: Vector2) -> void:
	var spots: Array = fist_spots.get(view, fist_spots.get("front", []))
	for index in _emitters.size():
		var emitter := _emitters[index]
		var has_fist := index < spots.size()
		emitter.emitting = has_fist
		if has_fist:
			var spot: Vector2 = spots[index]
			if is_flipped:
				spot.x = -spot.x
			emitter.position = sprite_lift + spot


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
	emitter.color_ramp = _spark_colors()
	return emitter


## Hot sparks that cool and fade as they rise.
static func _spark_colors() -> Gradient:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([EmberooFlameColors.hot(), EmberooFlameColors.warm(), Color(EmberooFlameColors.cool(), 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	return ramp
