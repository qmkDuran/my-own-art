class_name AmbientDrift
extends CPUParticles2D
## Quiet weather for a zone: a few specks drifting across the view (snow in a frosty pass,
## blossom petals and leaves in an orchard). A child of the zone's camera: specks are born
## around the view but live in the world, so they stay put while the camera moves.
## Decoration only, kept faint so it never competes with the fight.

enum Kind { SNOW, PETALS }

## A little more than half the 480×270 view, so specks drift in from beyond its edges.
const SPAWN_HALF_EXTENTS := Vector2(260.0, 150.0)
const SNOW_AMOUNT := 46
const PETAL_AMOUNT := 18
const SNOW_LIFETIME := 9.0
const PETAL_LIFETIME := 10.0
## Specks sit above the world and the canopy, below the HUD.
const DRAW_LAYER := 20

@export var kind: Kind = Kind.SNOW


func _ready() -> void:
	z_index = DRAW_LAYER
	z_as_relative = false
	local_coords = false
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = SPAWN_HALF_EXTENTS
	preprocess = SNOW_LIFETIME
	if kind == Kind.SNOW:
		_set_up_snow()
	else:
		_set_up_petals()
	emitting = true


## Fine snow on a steady wind from the east.
func _set_up_snow() -> void:
	amount = SNOW_AMOUNT
	lifetime = SNOW_LIFETIME
	direction = Vector2(-1.0, 0.45)
	spread = 12.0
	initial_velocity_min = 6.0
	initial_velocity_max = 14.0
	gravity = Vector2(0.0, 3.0)
	scale_amount_min = 1.0
	scale_amount_max = 1.0
	color = Color(ApolloPalette.WHITE, 0.55)
	color_ramp = _fade_in_and_out(ApolloPalette.WHITE)


## Petals and a few leaves, tumbling on gusts from the west.
func _set_up_petals() -> void:
	amount = PETAL_AMOUNT
	lifetime = PETAL_LIFETIME
	direction = Vector2(1.0, 0.3)
	spread = 20.0
	initial_velocity_min = 8.0
	initial_velocity_max = 16.0
	gravity = Vector2(0.0, 2.0)
	angular_velocity_min = -90.0
	angular_velocity_max = 90.0
	scale_amount_min = 1.0
	scale_amount_max = 2.0
	color = Color(ApolloPalette.WHITE, 0.85)
	color_initial_ramp = _petal_tints()
	color_ramp = _fade_in_and_out(ApolloPalette.WHITE)


## Specks fade in after birth and out before they die, so none pops.
func _fade_in_and_out(tint: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	ramp.colors = PackedColorArray([Color(tint, 0.0), tint, tint, Color(tint, 0.0)])
	return ramp


## Mostly pink petals, some pale ones and a few green leaves.
func _petal_tints() -> Gradient:
	var tints := Gradient.new()
	tints.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	tints.offsets = PackedFloat32Array([0.0, 0.55, 0.8])
	tints.colors = PackedColorArray([ApolloPalette.PINK, ApolloPalette.WHITE, ApolloPalette.GREEN_LIGHT])
	return tints
