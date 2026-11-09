class_name FireRing
extends PixelFire
## A swirling ring of fire bursting out all around the attacker (the Spinning Hook), see
## PixelFire.
##
## The ring snaps outward to full size while a hot streak races round it the way the
## attacker turns (down, right, up, left); behind the streak the fire cools, then the ring
## breaks up into flickering pixels.

## Where the ring's outer edge starts, as a share of the radius, before snapping out to full size.
const START_SIZE := 0.55
## Share of the ring's life spent growing to full size, and the easing of that growth.
const GROW_SHARE := 0.35
const GROW_EASING := 0.4
## How thick the band of fire is at first and at the end, as a share of the radius.
const START_THICKNESS := 0.32
const END_THICKNESS := 0.1
## How many times the hot streak goes round during the ring's life.
const STREAK_TURNS := 1.25
## Where the streak starts: straight down (toward the camera), like the turn.
const STREAK_START_ANGLE := PI / 2.0
## How much each kind of cooling counts toward a pixel's colour.
const COOLING_BEHIND_STREAK := 0.75
const COOLING_OVER_TIME := 0.8
const COOLING_INWARD := 0.35
## Thinnest band the inward cooling is measured across, as a share of the radius.
const MIN_BAND := 0.05
## In front of the attacker; the band sits outside the sprite, so it never hides it.
const RING_Z_INDEX := 2
## Embers: how hard they're flung (pixels per second) and how far out round the ring they start.
const EMBER_EXPLOSIVENESS := 0.9
const EMBER_SPEED := Vector2(15.0, 40.0)
const EMBER_START_SHARE := 0.85

## Each cell's angle around the centre (matching PixelFire's cells).
var _cell_angles: PackedFloat32Array = PackedFloat32Array()
## This frame's band (shares of the radius) and the streak's angle.
var _outer: float = 0.0
var _inner: float = 0.0
var _streak_angle: float = 0.0


## Bursts the ring out to `radius` pixels around this node's position.
func play(radius: float) -> void:
	z_index = RING_Z_INDEX
	_collect_cells(radius)
	_spawn_embers(radius)
	_free_when_done()


func _prepare_frame(progress: float) -> void:
	_outer = lerpf(START_SIZE, 1.0, ease(minf(1.0, progress / GROW_SHARE), GROW_EASING))
	_inner = _outer - lerpf(START_THICKNESS, END_THICKNESS, progress)
	_streak_angle = STREAK_START_ANGLE - progress * STREAK_TURNS * TAU


func _color_index_at(index: int, progress: float) -> int:
	var distance := _cell_distances[index]
	if distance > _outer or distance < _inner or _has_broken_up(index, progress):
		return -1
	# 0 right at the streak, near 1 for pixels it passed almost a full turn ago.
	# The streak turns toward smaller angles, so pixels it has passed have larger ones.
	var behind_streak := fposmod(_cell_angles[index] - _streak_angle, TAU) / TAU
	var inward := (_outer - distance) / maxf(_outer - _inner, MIN_BAND)
	return _color_index_for_heat_lost(behind_streak * COOLING_BEHIND_STREAK + progress * COOLING_OVER_TIME + inward * COOLING_INWARD)


## Works out once which pixels lie within the ring's reach, so drawing each frame is just a lookup.
func _collect_cells(radius: float) -> void:
	var extent := ceili(radius) + 1
	var smallest_inner := START_SIZE - START_THICKNESS
	for y in range(-extent, extent + 1):
		for x in range(-extent, extent + 1):
			var center := Vector2(x + 0.5, y + 0.5)
			var distance := center.length() / radius
			if distance > 1.0 or distance < smallest_inner:
				continue
			_add_cell(Vector2(x, y), distance)
			_cell_angles.append(center.angle())


## A handful of sparks flung off the ring that float up and fade.
func _spawn_embers(radius: float) -> void:
	var embers := _make_embers()
	embers.explosiveness = EMBER_EXPLOSIVENESS
	embers.direction = Vector2.UP
	embers.spread = 180.0
	embers.initial_velocity_min = EMBER_SPEED.x
	embers.initial_velocity_max = EMBER_SPEED.y
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	embers.emission_sphere_radius = radius * EMBER_START_SHARE
	add_child(embers)
	embers.emitting = true
