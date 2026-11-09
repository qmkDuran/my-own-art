class_name AmbientLife
extends CPUParticles2D
## A little life in the air of a zone: pollen over a sunny meadow, leaves let go by an old wood,
## fireflies over a fen, grit dust over a quarry. A child of the zone's camera: specks are born around the view but live
## in the world, so they stay put while the camera moves. Decoration only: few, small and
## faint, so they never compete with creatures, enemies or pickups.

enum Kind { POLLEN, LEAVES, FIREFLIES, DUST }

## A little more than half the 480×270 view, so specks drift in from beyond its edges.
const SPAWN_HALF_EXTENTS := Vector2(260.0, 150.0)
## Specks sit above the world and the canopy, below the HUD.
const DRAW_LAYER := 20

const POLLEN_AMOUNT := 14
const POLLEN_LIFETIME := 9.0
const LEAF_AMOUNT := 7
const LEAF_LIFETIME := 11.0
const FIREFLY_AMOUNT := 16
const FIREFLY_LIFETIME := 7.0
const DUST_AMOUNT := 12
const DUST_LIFETIME := 8.0

@export var kind: Kind = Kind.POLLEN


func _ready() -> void:
	z_index = DRAW_LAYER
	z_as_relative = false
	local_coords = false
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = SPAWN_HALF_EXTENTS
	match kind:
		Kind.POLLEN:
			_set_up_pollen()
		Kind.LEAVES:
			_set_up_leaves()
		Kind.FIREFLIES:
			_set_up_fireflies()
		Kind.DUST:
			_set_up_dust()
	preprocess = lifetime
	emitting = true


## Pale specks of pollen lifting lazily on a warm breeze from the west.
func _set_up_pollen() -> void:
	amount = POLLEN_AMOUNT
	lifetime = POLLEN_LIFETIME
	direction = Vector2(1.0, -0.35)
	spread = 35.0
	initial_velocity_min = 3.0
	initial_velocity_max = 7.0
	gravity = Vector2(0.0, -0.6)
	scale_amount_min = 1.0
	scale_amount_max = 1.0
	color = Color(ApolloPalette.WHITE, 0.7)
	color_initial_ramp = _tints([ApolloPalette.LIME_PALE, ApolloPalette.GOLD, ApolloPalette.WHITE])
	color_ramp = _fade_in_and_out(ApolloPalette.WHITE, 1.0)


## A few leaves tumbling down out of the canopy, drifting east.
func _set_up_leaves() -> void:
	amount = LEAF_AMOUNT
	lifetime = LEAF_LIFETIME
	direction = Vector2(1.0, 0.5)
	spread = 25.0
	initial_velocity_min = 5.0
	initial_velocity_max = 10.0
	gravity = Vector2(0.0, 1.5)
	angular_velocity_min = -120.0
	angular_velocity_max = 120.0
	scale_amount_min = 1.0
	scale_amount_max = 2.0
	color = Color(ApolloPalette.WHITE, 0.75)
	color_initial_ramp = _tints([ApolloPalette.GREEN, ApolloPalette.GREEN_LIGHT, ApolloPalette.ORANGE_DARK])
	color_ramp = _fade_in_and_out(ApolloPalette.WHITE, 1.0)


## Fen fireflies: slow wandering motes that glow up and dim again.
func _set_up_fireflies() -> void:
	amount = FIREFLY_AMOUNT
	lifetime = FIREFLY_LIFETIME
	direction = Vector2(0.0, -1.0)
	spread = 180.0
	initial_velocity_min = 2.0
	initial_velocity_max = 5.0
	gravity = Vector2.ZERO
	orbit_velocity_min = -0.04
	orbit_velocity_max = 0.04
	scale_amount_min = 1.0
	scale_amount_max = 1.0
	color = Color(ApolloPalette.WHITE, 0.9)
	color_initial_ramp = _tints([ApolloPalette.SKY_LIGHT, ApolloPalette.LIME_PALE])
	color_ramp = _glow_pulse(ApolloPalette.WHITE)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


## Fine grit lifted off the quarry floor, blown slowly east and settling again.
func _set_up_dust() -> void:
	amount = DUST_AMOUNT
	lifetime = DUST_LIFETIME
	direction = Vector2(1.0, -0.15)
	spread = 20.0
	initial_velocity_min = 6.0
	initial_velocity_max = 12.0
	gravity = Vector2(0.0, 1.0)
	scale_amount_min = 1.0
	scale_amount_max = 1.0
	color = Color(ApolloPalette.WHITE, 0.6)
	color_initial_ramp = _tints([ApolloPalette.GREY_LIGHT, ApolloPalette.CREAM, ApolloPalette.GREY])
	color_ramp = _fade_in_and_out(ApolloPalette.WHITE, 1.0)


## Each speck picks one of the given colours when it is born.
func _tints(colors: Array[Color]) -> Gradient:
	var tints := Gradient.new()
	tints.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	for index in colors.size():
		offsets.append(float(index) / colors.size())
	tints.offsets = offsets
	tints.colors = PackedColorArray(colors)
	return tints


## Specks fade in after birth and out before they die, so none pops.
func _fade_in_and_out(tint: Color, peak_alpha: float) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	ramp.colors = PackedColorArray([Color(tint, 0.0), Color(tint, peak_alpha), Color(tint, peak_alpha), Color(tint, 0.0)])
	return ramp


## Two slow glows over a firefly's life, dark in between.
func _glow_pulse(tint: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.55, 0.75, 1.0])
	ramp.colors = PackedColorArray([Color(tint, 0.0), Color(tint, 1.0), Color(tint, 0.1), Color(tint, 0.1), Color(tint, 1.0), Color(tint, 0.0)])
	return ramp
