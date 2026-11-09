class_name AshGuardShimmer
extends Node2D
## Ash Guard's look: a curved wall of stone-grey ash in front of the guard, its edges molten
## gold, embers and white-hot cracks flickering through it, sparks drifting up off it. It
## rises with a white flash, and every hit it takes flares its rim white and throws sparks.
## Drawn in code pixel by pixel, sized to the guard's body (FxBody), so it fits the 16 px
## Emberoo and the ~46 px one alike.
##
## A child of the guarding creature, so it moves with him. It sits in front of the sprite
## when he faces the camera, behind it when he faces away. Free it when the guard drops.

## Coolest to hottest; the ash is mostly grey, the cracks and rim glow.
const ASH_COLORS: Array[Color] = [ApolloPalette.STONE, ApolloPalette.STONE_LIGHT, ApolloPalette.GREY]
## Where the wall sits, as shares of the body's height: the gloves' height (the wall's
## middle), how far in front of the body it stands, and how tall it is.
const GLOVE_HEIGHT_SHARE := 0.45
const DISTANCE_SHARE := 0.42
const WALL_HEIGHT_SHARE := 0.4
## Height of the old 16 px Emberoo, used when the body can't be measured.
const FALLBACK_BODY_HEIGHT := 16.0
## Rows of molten rim along the wall's top and bottom.
const RIM_ROWS := 2
## How far the wall curves round each side.
const HALF_ARC := deg_to_rad(60.0)
## Share of the wall's pixels that glow as embers, and as white-hot cracks, at any moment.
const EMBER_SHARE := 0.14
const CRACK_SHARE := 0.03
## Times per second the flicker picks new pixels to glow.
const FLICKER_RATE := 14.0
## How long the wall takes to rise, how long it flashes white then, and how long a hit's flare lasts.
const RISE_TIME := 0.08
const FLASH_SECONDS := 0.035
const HIT_FLARE_SECONDS := 0.12
## Sparks drifting up off the wall while it stands, and the burst a hit throws.
const DRIFT_SPARKS := 8
const HIT_SPARKS := 10
const SPARK_LIFETIME := 0.5

var _facing := Vector2.RIGHT
var _elapsed: float = 0.0
var _since_hit: float = INF
var _ramp: Array[Color] = EmberooFlameColors.burst_ramp()
var _distance: float = 7.0
var _wall_height: int = 8
var _drift_sparks: CPUParticles2D
var _hit_sparks: CPUParticles2D


func _ready() -> void:
	var body_height := FxBody.height_of(get_parent(), FALLBACK_BODY_HEIGHT)
	_distance = body_height * DISTANCE_SHARE
	_wall_height = maxi(4, roundi(body_height * WALL_HEIGHT_SHARE))
	position = Vector2(0, -roundf(body_height * GLOVE_HEIGHT_SHARE))
	_drift_sparks = _make_sparks(DRIFT_SPARKS, false)
	add_child(_drift_sparks)
	_hit_sparks = _make_sparks(HIT_SPARKS, true)
	add_child(_hit_sparks)
	var guard_health := Health.of(get_parent())
	if guard_health != null:
		guard_health.damaged.connect(_on_guard_hit)


## Turns the wall to stand in `direction` (a unit vector) from the guard.
func face(direction: Vector2) -> void:
	_facing = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	z_index = 1 if _facing.y >= 0.0 else -1
	_drift_sparks.position = (_facing * _distance).round()


func _process(delta: float) -> void:
	_elapsed += delta
	_since_hit += delta
	queue_redraw()


func _draw() -> void:
	var rise := clampf(_elapsed / RISE_TIME, 0.0, 1.0)
	var is_flashing := _elapsed < FLASH_SECONDS or _since_hit < FLASH_SECONDS
	var is_flaring := _since_hit < HIT_FLARE_SECONDS
	var flicker_step := floori(_elapsed * FLICKER_RATE)
	var shown_height := maxi(1, roundi(_wall_height * rise))
	var columns := _column_positions()
	for column_index in columns.size():
		var is_side_edge := column_index == 0 or column_index == columns.size() - 1
		for row in shown_height:
			var cell := (columns[column_index] + Vector2(0, row - shown_height / 2.0)).floor()
			var is_rim := is_side_edge or row < RIM_ROWS or row >= shown_height - RIM_ROWS
			var color := ApolloPalette.WHITE if is_flashing else _color_at(column_index, row, flicker_step, is_rim, is_flaring)
			draw_rect(Rect2(cell, Vector2.ONE), color)


## One pixel column per step along the arc in front of the guard.
func _column_positions() -> PackedVector2Array:
	var columns := PackedVector2Array()
	var steps := ceili(_distance * HALF_ARC * 2.0)
	var last := Vector2.INF
	for step in steps + 1:
		var angle := _facing.angle() - HALF_ARC + HALF_ARC * 2.0 * step / steps
		var column := (Vector2.from_angle(angle) * _distance).round()
		if column != last:
			columns.append(column)
			last = column
	return columns


## Ash inside a molten rim (white while a hit flares it); a changing few pixels glow as
## embers, fewer still as white-hot cracks.
func _color_at(column_index: int, row: int, flicker_step: int, is_rim: bool, is_flaring: bool) -> Color:
	if is_rim:
		if is_flaring:
			return _ramp[0]
		return _ramp[1] if FxPixels.noise(column_index, row, flicker_step) < 0.5 else _ramp[2]
	var noise := FxPixels.noise(column_index, row, flicker_step)
	if noise < CRACK_SHARE:
		return _ramp[0]
	if noise < CRACK_SHARE + EMBER_SHARE:
		return _ramp[1 + floori((noise - CRACK_SHARE) / EMBER_SHARE * 3.0)]
	# Smooth ash, a shade darker toward the wall's middle row band, so it reads as a solid slab.
	var middle_band := absf(row - _wall_height / 2.0) < _wall_height / 4.0
	return ASH_COLORS[1] if middle_band else ASH_COLORS[2]


func _on_guard_hit(_amount: int, _source_position: Vector2) -> void:
	_since_hit = 0.0
	_hit_sparks.position = (_facing * _distance).round()
	_hit_sparks.direction = _facing
	_hit_sparks.restart()


## Sparks off the wall: a steady drift upward, or (`is_burst`) a one-shot spray outward.
func _make_sparks(amount: int, is_burst: bool) -> CPUParticles2D:
	var sparks := CPUParticles2D.new()
	sparks.amount = amount
	sparks.lifetime = SPARK_LIFETIME
	sparks.local_coords = false
	sparks.one_shot = is_burst
	sparks.emitting = not is_burst
	sparks.explosiveness = 1.0 if is_burst else 0.0
	sparks.direction = Vector2.UP
	sparks.spread = 60.0 if is_burst else 25.0
	sparks.initial_velocity_min = 60.0 if is_burst else 12.0
	sparks.initial_velocity_max = 120.0 if is_burst else 30.0
	sparks.gravity = Vector2(0, 160) if is_burst else Vector2(0, -20)
	sparks.damping_min = 50.0
	sparks.damping_max = 80.0
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = _distance * 0.5
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([_ramp[0], _ramp[1], _ramp[3], Color(_ramp[5], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.65, 1.0])
	sparks.color_ramp = ramp
	return sparks
