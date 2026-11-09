class_name FlameArc
extends PixelFire
## A burst of flame fanning out in an arc (Flame Uppercut), see PixelFire.
##
## The flame front races outward while the fire burns out from the inside, then breaks up
## into flickering pixels. The arc is never rotated, so every pixel stays on the world grid.

## How far out the flame front starts, as a share of the reach (it ends at the full reach).
const FRONT_START := 0.35
## Share of the flame's life spent racing out to full reach, and the easing of that race.
const FRONT_TRAVEL_SHARE := 0.4
const FRONT_EASING := 0.4
## How much shorter the flame is at the arc's sides than in the middle (a crescent).
const SIDE_TAPER := 0.35
## Closest the flame comes to the fist, as a share of the reach, and how far out the burnt
## inside reaches by the end (it speeds up as it goes, by BURN_OUT_POWER).
const INNER_GAP := 0.12
const BURN_OUT_END := 0.95
const BURN_OUT_POWER := 1.4
## Flame tongues: how many across the arc, how long (share of reach), how often they flicker.
const TONGUE_COUNT := 7.0
const TONGUE_LENGTH := 0.16
const TONGUE_FLICKER_SECONDS := 0.05
## A tongue's random length runs from this share below to the rest above TONGUE_LENGTH's span.
const TONGUE_SHORTEST := 0.3
## How much each kind of cooling counts toward a pixel's colour: how deep into the flame
## from its front, how far through its life, how far out to the arc's sides.
const COOLING_INWARD := 0.6
const COOLING_OVER_TIME := 1.0
const COOLING_SIDEWAYS := 0.15
## Thinnest flame the inward cooling is measured across, as a share of the reach.
const MIN_DEPTH := 0.05
## Aimed further up than this (away from the camera), the flame goes behind the creature.
const BEHIND_BELOW_Y := -0.35
const FRONT_Z_INDEX := 2
const BEHIND_Z_INDEX := 0
## Embers: how hard and how fast they're thrown (pixels per second), how far out along the
## flame they start, how much they lean upward and the cone (degrees) and blob they fill.
const EMBER_EXPLOSIVENESS := 0.85
const EMBER_SPEED := Vector2(25.0, 60.0)
const EMBER_START_SHARE := 0.55
const EMBER_LIFT := 0.6
const EMBER_SPREAD_DEGREES := 50.0
const EMBER_BLOB_SHARE := 0.25

## Each cell's place across the arc (-1 = one edge, 1 = the other), matching PixelFire's cells.
var _cell_sides: PackedFloat32Array = PackedFloat32Array()
## This frame's flame front and burnt-out back (shares of the reach), and flicker roll.
var _front: float = 0.0
var _back: float = 0.0
var _flicker_step: int = 0


func _init() -> void:
	duration = 0.3
	ember_count = 10
	ember_lifetime = 0.55
	break_up_start = 0.55


## Bursts the flame toward `direction` (a unit vector), `reach` pixels out, `arc_degrees` wide.
func play(direction: Vector2, reach: float, arc_degrees: float) -> void:
	z_index = FRONT_Z_INDEX if direction.y > BEHIND_BELOW_Y else BEHIND_Z_INDEX
	_collect_cells(direction, reach, deg_to_rad(arc_degrees) / 2.0)
	_spawn_embers(direction, reach)
	_free_when_done()


func _prepare_frame(progress: float) -> void:
	_front = lerpf(FRONT_START, 1.0, ease(minf(1.0, progress / FRONT_TRAVEL_SHARE), FRONT_EASING))
	_back = lerpf(INNER_GAP, BURN_OUT_END, pow(progress, BURN_OUT_POWER))
	_flicker_step = floori(_elapsed / TONGUE_FLICKER_SECONDS)


func _color_index_at(index: int, progress: float) -> int:
	var side := absf(_cell_sides[index])
	var taper := 1.0 - SIDE_TAPER * side * side
	var cell_front := _front * taper + _tongue_length(_cell_sides[index])
	var cell_back := _back * taper
	var distance := _cell_distances[index]
	if distance > cell_front or distance < cell_back or _has_broken_up(index, progress):
		return -1
	# 0 at the leading edge (hottest), 1 at the trailing edge; everything cools with time.
	var depth := (cell_front - distance) / maxf(cell_front - cell_back, MIN_DEPTH)
	return _color_index_for_heat_lost(depth * COOLING_INWARD + progress * COOLING_OVER_TIME + side * COOLING_SIDEWAYS)


## Flame tongues licking out past the front: a random length per slice of the arc,
## re-rolled every few frames so the edge flickers.
func _tongue_length(side: float) -> float:
	var slice := floorf((side + 1.0) * TONGUE_COUNT / 2.0)
	return (_hash_roll(slice, _flicker_step) - TONGUE_SHORTEST) * TONGUE_LENGTH


## A repeatable random number from 0 to 1 for this slice and flicker step (a classic sine hash).
static func _hash_roll(slice: float, flicker_step: int) -> float:
	return fposmod(sin(slice * 12.9898 + flicker_step * 78.233) * 43758.5453, 1.0)


## Works out once which pixels lie inside the arc, so drawing each frame is just a lookup.
func _collect_cells(direction: Vector2, reach: float, half_arc: float) -> void:
	var extent := ceili(reach * (1.0 + TONGUE_LENGTH)) + 1
	for y in range(-extent, extent + 1):
		for x in range(-extent, extent + 1):
			var center := Vector2(x + 0.5, y + 0.5)
			var side := direction.angle_to(center) / half_arc
			var distance := center.length() / reach
			if absf(side) > 1.0 or distance > 1.0 + TONGUE_LENGTH:
				continue
			_add_cell(Vector2(x, y), distance)
			_cell_sides.append(side)


## A handful of sparks thrown out with the flame that float up and fade.
func _spawn_embers(direction: Vector2, reach: float) -> void:
	var embers := _make_embers()
	embers.explosiveness = EMBER_EXPLOSIVENESS
	embers.position = (direction * reach * EMBER_START_SHARE).round()
	embers.direction = (direction + Vector2.UP * EMBER_LIFT).normalized()
	embers.spread = EMBER_SPREAD_DEGREES
	embers.initial_velocity_min = EMBER_SPEED.x
	embers.initial_velocity_max = EMBER_SPEED.y
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = reach * EMBER_BLOB_SHARE
	add_child(embers)
	embers.emitting = true
