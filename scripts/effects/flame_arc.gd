class_name FlameArc
extends PixelFire
## A fan of flame bursting out in an arc (Flame Uppercut), see PixelFire.
##
## Drawn like pixel-art fire, not smoke: a few big pointed flame tongues with hard edges and
## flat colour bands, white-hot at the root by the fist, gold, orange, then red at the tips.
## The tongues shoot out to full reach, flicker their lengths, then pull back in while the
## fire cools from the root outward; nothing dissolves into speckle. A white-hot streak
## shoots straight up from the fist with it (the uppercut). The fan is never rotated, so
## every pixel stays on the world grid. It is drawn HeroFxScale.SKILL_SIZE_SCALE times the
## reach it is given.

## How many flame tongues fan out across the arc.
const TONGUE_COUNT := 5
## The solid fan under the tongues, as a share of the reach; the tongues' tips reach the rest.
const BODY_SHARE := 0.62
const TONGUE_SHARE := 0.38
## A tongue's length wobbles between this share and full, re-rolled this often (seconds).
const TONGUE_SHORTEST := 0.72
const TONGUE_FLICKER_SECONDS := 0.06
## How much shorter the fan is at the arc's sides than in the middle (a crescent).
const SIDE_TAPER := 0.3
## Share of the flame's life spent shooting out to full reach, and the easing of that.
const SHOOT_OUT_SHARE := 0.25
const SHOOT_OUT_EASING := 0.35
## From this share of its life on, the tongues pull back in (gone at the end).
const PULL_BACK_START := 0.55
## Closest the flame comes to the fist, as a share of the reach, and how far out the burnt
## root reaches by the end.
const ROOT_GAP := 0.1
const ROOT_BURN_OUT := 0.6
## Colour bands along a tongue, root to tip, as shares of its length: where each of the
## burst ramp's colours ends (white-hot, gold, orange, orange, light red, then red to the tip).
const BAND_ENDS: Array[float] = [0.22, 0.42, 0.6, 0.74, 0.88]
## How many colour steps the whole flame cools by over its life.
const COOLING_STEPS := 2.0
## Aimed further up than this (away from the camera), the flame goes behind the creature.
const BEHIND_BELOW_Y := -0.35
const FRONT_Z_INDEX := 2
const BEHIND_Z_INDEX := 0
## Embers: how hard and how fast they're thrown (pixels per second), how far out along the
## flame they start, how much they lean upward and the cone (degrees) and blob they fill.
const EMBER_EXPLOSIVENESS := 0.85
const EMBER_SPEED := Vector2(50.0, 110.0)
const EMBER_START_SHARE := 0.6
const EMBER_LIFT := 0.6
const EMBER_SPREAD_DEGREES := 45.0
const EMBER_BLOB_SHARE := 0.2
## The uppercut streak rising from the fist: its height as a share of the reach, the share
## of the flame's life it shows, and how thick it starts.
const STREAK_HEIGHT_SHARE := 0.8
const STREAK_SHARE := 0.4
const STREAK_THICKNESS := 5

## Each cell's place across the arc (-1 = one edge, 1 = the other), matching PixelFire's cells.
var _cell_sides: PackedFloat32Array = PackedFloat32Array()
## This frame's reach (share of the full reach) and burnt-out root, and each tongue's length.
var _reach_now: float = 0.0
var _root: float = 0.0
var _tongue_lengths: PackedFloat32Array = PackedFloat32Array()
## How many colour steps the flame has cooled by this frame.
var _cooled_by: int = 0
## How long the uppercut streak is drawn, in pixels.
var _streak_height: float = 0.0


func _init() -> void:
	duration = 0.34
	ember_count = 8
	ember_lifetime = 0.55
	_tongue_lengths.resize(TONGUE_COUNT)


## Bursts the flame toward `direction` (a unit vector), `reach` pixels out (times
## HeroFxScale.SKILL_SIZE_SCALE), `arc_degrees` wide.
func play(direction: Vector2, reach: float, arc_degrees: float) -> void:
	var drawn_reach := reach * HeroFxScale.SKILL_SIZE_SCALE
	z_index = FRONT_Z_INDEX if direction.y > BEHIND_BELOW_Y else BEHIND_Z_INDEX
	_streak_height = drawn_reach * STREAK_HEIGHT_SHARE
	_collect_cells(direction, drawn_reach, deg_to_rad(arc_degrees) / 2.0)
	_spawn_embers(direction, drawn_reach)
	_free_when_done()


func _draw() -> void:
	super()
	var progress := _elapsed / duration
	if progress < STREAK_SHARE:
		_draw_rising_streak(progress / STREAK_SHARE)


## The uppercut: a flame streak shooting up from the fist, white-hot at its head and
## cooling toward its foot, thinning as its foot climbs after it.
func _draw_rising_streak(progress: float) -> void:
	var head := roundi(_streak_height * ease(minf(1.0, progress * 2.0), 0.3))
	var tail := roundi(_streak_height * progress)
	var thickness := maxi(1, roundi(STREAK_THICKNESS * (1.0 - progress)))
	var left := -floori(thickness / 2.0)
	for rise in range(tail, head):
		var below_head := float(head - rise) / maxf(1.0, head - tail)
		var color := _fire_colors[_color_index_for_heat_lost(below_head * 0.7 + progress * 0.5)]
		# Narrower toward the head, like a flame's tip.
		var width := thickness if below_head > 0.3 else maxi(1, thickness - 2)
		draw_rect(Rect2(left + floori((thickness - width) / 2.0), -rise - 1, width, 1), color)


func _prepare_frame(progress: float) -> void:
	var shoot_out := ease(minf(1.0, progress / SHOOT_OUT_SHARE), SHOOT_OUT_EASING)
	var pull_back := clampf((progress - PULL_BACK_START) / (1.0 - PULL_BACK_START), 0.0, 1.0)
	_reach_now = shoot_out * (1.0 - pull_back * pull_back)
	_root = lerpf(ROOT_GAP, ROOT_BURN_OUT, pull_back)
	_cooled_by = floori(progress * COOLING_STEPS)
	var flicker_step := floori(_elapsed / TONGUE_FLICKER_SECONDS)
	for tongue in TONGUE_COUNT:
		_tongue_lengths[tongue] = lerpf(TONGUE_SHORTEST, 1.0, FxPixels.noise(tongue, flicker_step, 3))


func _color_index_at(index: int, _progress: float) -> int:
	var side := _cell_sides[index]
	var length := _flame_length_at(side)
	var distance := _cell_distances[index]
	var root := _root * length
	if distance > length or distance < root or length <= 0.0:
		return -1
	var along := (distance - root) / maxf(length - root, 0.01)
	return mini(_band_of(along) + _cooled_by, _fire_colors.size() - 1)


## How far out the flame reaches at `side` this frame (share of the reach): the fan's body
## plus a pointed tongue, tallest at the tongue's middle.
func _flame_length_at(side: float) -> float:
	var across := (side + 1.0) * TONGUE_COUNT / 2.0
	var tongue := clampi(floori(across), 0, TONGUE_COUNT - 1)
	var off_middle := absf(fposmod(across, 1.0) - 0.5) * 2.0
	var point := (1.0 - off_middle) * _tongue_lengths[tongue]
	var taper := 1.0 - SIDE_TAPER * side * side
	return _reach_now * taper * (BODY_SHARE + TONGUE_SHARE * point)


## Which colour band a pixel `along` (0 root, 1 tip) of its tongue is in.
static func _band_of(along: float) -> int:
	for band in BAND_ENDS.size():
		if along < BAND_ENDS[band]:
			return band
	return BAND_ENDS.size()


## Works out once which pixels lie inside the arc, so drawing each frame is just a lookup.
func _collect_cells(direction: Vector2, reach: float, half_arc: float) -> void:
	var extent := ceili(reach) + 1
	for y in range(-extent, extent + 1):
		for x in range(-extent, extent + 1):
			var center := Vector2(x + 0.5, y + 0.5)
			var side := direction.angle_to(center) / half_arc
			var distance := center.length() / reach
			if absf(side) > 1.0 or distance > 1.0:
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
