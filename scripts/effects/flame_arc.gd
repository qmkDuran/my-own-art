class_name FlameArc
extends Node2D
## A burst of flame fanning out in an arc (Flame Uppercut), drawn in code pixel by pixel.
##
## The flame front races outward while the fire burns out from the inside, cooling from
## gold to deep red, then breaks up into flickering pixels. A few embers drift up from it.
## Every pixel sits on the world grid (the arc is never rotated), so it stays crisp.
## Spawn it, call play(), and it removes itself when done.

## Hottest to coolest.
const FIRE_COLORS: Array[Color] = [
	ApolloPalette.GOLD,
	ApolloPalette.ORANGE,
	ApolloPalette.ORANGE_MID,
	ApolloPalette.RED_LIGHT,
	ApolloPalette.RED,
]
## How far out the flame front starts and ends, as a share of the reach.
const FRONT_START := 0.35
## Share of the flame's life spent racing out to full reach.
const FRONT_TRAVEL_SHARE := 0.4
## How much shorter the flame is at the arc's sides than in the middle (a crescent).
const SIDE_TAPER := 0.35
## Closest the flame comes to the fist, as a share of the reach.
const INNER_GAP := 0.12
## Share of the flame's life after which it starts breaking up into pixels.
const BREAK_UP_START := 0.55
## Flame tongues: how many across the arc, how long (share of reach), how often they flicker.
const TONGUE_COUNT := 7.0
const TONGUE_LENGTH := 0.16
const TONGUE_FLICKER_SECONDS := 0.05

## Seconds the flame is visible.
@export var duration: float = 0.3
@export var ember_count: int = 10
@export var ember_lifetime: float = 0.55

## Each cell is one pixel the arc may cover: where it is, how far out (share of the reach),
## where across the arc (-1 = one edge, 1 = the other) and a fixed random value.
var _cell_offsets: PackedVector2Array = PackedVector2Array()
var _cell_distances: PackedFloat32Array = PackedFloat32Array()
var _cell_sides: PackedFloat32Array = PackedFloat32Array()
var _cell_noise: PackedFloat32Array = PackedFloat32Array()
var _elapsed: float = 0.0


## Bursts the flame toward `direction` (a unit vector), `reach` pixels out, `arc_degrees` wide.
func play(direction: Vector2, reach: float, arc_degrees: float) -> void:
	# Flames aimed up (away from the camera) go behind the creature; others in front.
	z_index = 2 if direction.y > -0.35 else 0
	_collect_cells(direction, reach, deg_to_rad(arc_degrees) / 2.0)
	_spawn_embers(direction, reach)
	var lifetime := maxf(duration, ember_lifetime) + 0.1
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var progress := _elapsed / duration
	if progress >= 1.0:
		return
	var front := lerpf(FRONT_START, 1.0, ease(minf(1.0, progress / FRONT_TRAVEL_SHARE), 0.4))
	var back := lerpf(INNER_GAP, 0.95, pow(progress, 1.4))
	var flicker_step := floori(_elapsed / TONGUE_FLICKER_SECONDS)
	for index in _cell_offsets.size():
		var color_index := _color_index_at(index, progress, front, back, flicker_step)
		if color_index >= 0:
			draw_rect(Rect2(_cell_offsets[index], Vector2.ONE), FIRE_COLORS[color_index])


## The fire colour of one pixel right now, or -1 when that pixel is not burning.
func _color_index_at(index: int, progress: float, front: float, back: float, flicker_step: int) -> int:
	var side := absf(_cell_sides[index])
	var taper := 1.0 - SIDE_TAPER * side * side
	var cell_front := front * taper + _tongue_length(_cell_sides[index], flicker_step)
	var cell_back := back * taper
	var distance := _cell_distances[index]
	if distance > cell_front or distance < cell_back:
		return -1
	if progress > BREAK_UP_START and _cell_noise[index] < (progress - BREAK_UP_START) / (1.0 - BREAK_UP_START):
		return -1
	# 0 at the leading edge (hottest), 1 at the trailing edge; everything cools with time.
	var depth := (cell_front - distance) / maxf(cell_front - cell_back, 0.05)
	var heat_lost := depth * 0.6 + progress * 1.0 + side * 0.15
	return clampi(floori(heat_lost * FIRE_COLORS.size()), 0, FIRE_COLORS.size() - 1)


## Flame tongues licking out past the front: a random length per slice of the arc,
## re-rolled every few frames so the edge flickers.
func _tongue_length(side: float, flicker_step: int) -> float:
	var slice := floorf((side + 1.0) * TONGUE_COUNT / 2.0)
	var roll := fposmod(sin(slice * 12.9898 + flicker_step * 78.233) * 43758.5453, 1.0)
	return (roll - 0.3) * TONGUE_LENGTH


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
			_cell_offsets.append(Vector2(x, y))
			_cell_distances.append(distance)
			_cell_sides.append(side)
			_cell_noise.append(randf())


## A handful of sparks thrown out with the flame that float up and fade.
func _spawn_embers(direction: Vector2, reach: float) -> void:
	var embers := CPUParticles2D.new()
	embers.one_shot = true
	embers.amount = ember_count
	embers.lifetime = ember_lifetime
	embers.explosiveness = 0.85
	embers.local_coords = false
	embers.position = (direction * reach * 0.55).round()
	embers.direction = (direction + Vector2.UP * 0.6).normalized()
	embers.spread = 50.0
	embers.initial_velocity_min = 25.0
	embers.initial_velocity_max = 60.0
	embers.damping_min = 50.0
	embers.damping_max = 80.0
	embers.gravity = Vector2(0, -25)
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = reach * 0.25
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([FIRE_COLORS[0], FIRE_COLORS[1], FIRE_COLORS[3], Color(FIRE_COLORS[4], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	embers.color_ramp = ramp
	add_child(embers)
	embers.emitting = true
