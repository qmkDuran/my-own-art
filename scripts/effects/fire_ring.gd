class_name FireRing
extends Node2D
## A swirling ring of fire bursting out all around the attacker (the Spinning Hook),
## drawn in code pixel by pixel.
##
## The ring snaps outward to full size while a hot streak races round it the way the
## attacker turns (down, right, up, left); behind the streak the fire cools from gold to
## deep red (blue-white to blue once Awakened), then the ring breaks up into flickering
## pixels. A few embers float up from it.
## Every pixel sits on the world grid, so it stays crisp.
## Spawn it, call play(), and it removes itself when done.

## Where the ring's outer edge starts, as a share of the radius, before snapping out to full size.
const START_SIZE := 0.55
## Share of the ring's life spent growing to full size.
const GROW_SHARE := 0.35
## How thick the band of fire is at first and at the end, as a share of the radius.
const START_THICKNESS := 0.32
const END_THICKNESS := 0.1
## How many times the hot streak goes round during the ring's life.
const STREAK_TURNS := 1.25
## Where the streak starts: straight down (toward the camera), like the turn.
const STREAK_START_ANGLE := PI / 2.0
## Share of the ring's life after which it starts breaking up into pixels.
const BREAK_UP_START := 0.5
## How much each kind of cooling counts toward a pixel's colour.
const COOLING_BEHIND_STREAK := 0.75
const COOLING_OVER_TIME := 0.8
const COOLING_INWARD := 0.35

## Seconds the ring is visible.
@export var duration: float = 0.25
@export var ember_count: int = 12
@export var ember_lifetime: float = 0.45

## Each cell is one pixel the ring may cover: where it is, how far out (share of the radius),
## its angle around the centre and a fixed random value.
## Hottest to coolest: Emberoo's fire colours when this started (see EmberooFlameColors).
var _fire_colors: Array[Color] = EmberooFlameColors.fire_ramp()
var _cell_offsets: PackedVector2Array = PackedVector2Array()
var _cell_distances: PackedFloat32Array = PackedFloat32Array()
var _cell_angles: PackedFloat32Array = PackedFloat32Array()
var _cell_noise: PackedFloat32Array = PackedFloat32Array()
var _elapsed: float = 0.0


## Bursts the ring out to `radius` pixels around this node's position.
func play(radius: float) -> void:
	# In front of the attacker; the band sits outside the sprite, so it never hides it.
	z_index = 2
	_collect_cells(radius)
	_spawn_embers(radius)
	var lifetime := maxf(duration, ember_lifetime) + 0.1
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var progress := _elapsed / duration
	if progress >= 1.0:
		return
	var outer := lerpf(START_SIZE, 1.0, ease(minf(1.0, progress / GROW_SHARE), 0.4))
	var inner := outer - lerpf(START_THICKNESS, END_THICKNESS, progress)
	var streak_angle := STREAK_START_ANGLE - progress * STREAK_TURNS * TAU
	for index in _cell_offsets.size():
		var color_index := _color_index_at(index, progress, inner, outer, streak_angle)
		if color_index >= 0:
			draw_rect(Rect2(_cell_offsets[index], Vector2.ONE), _fire_colors[color_index])


## The fire colour of one pixel right now, or -1 when that pixel is not burning.
func _color_index_at(index: int, progress: float, inner: float, outer: float, streak_angle: float) -> int:
	var distance := _cell_distances[index]
	if distance > outer or distance < inner:
		return -1
	if progress > BREAK_UP_START and _cell_noise[index] < (progress - BREAK_UP_START) / (1.0 - BREAK_UP_START):
		return -1
	# 0 right at the streak, near 1 for pixels it passed almost a full turn ago.
	# The streak turns toward smaller angles, so pixels it has passed have larger ones.
	var behind_streak := fposmod(_cell_angles[index] - streak_angle, TAU) / TAU
	var inward := (outer - distance) / maxf(outer - inner, 0.05)
	var heat_lost := behind_streak * COOLING_BEHIND_STREAK + progress * COOLING_OVER_TIME + inward * COOLING_INWARD
	return clampi(floori(heat_lost * _fire_colors.size()), 0, _fire_colors.size() - 1)


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
			_cell_offsets.append(Vector2(x, y))
			_cell_distances.append(distance)
			_cell_angles.append(center.angle())
			_cell_noise.append(randf())


## A handful of sparks flung off the ring that float up and fade.
func _spawn_embers(radius: float) -> void:
	var embers := CPUParticles2D.new()
	embers.one_shot = true
	embers.amount = ember_count
	embers.lifetime = ember_lifetime
	embers.explosiveness = 0.9
	embers.local_coords = false
	embers.direction = Vector2.UP
	embers.spread = 180.0
	embers.initial_velocity_min = 15.0
	embers.initial_velocity_max = 40.0
	embers.damping_min = 50.0
	embers.damping_max = 80.0
	embers.gravity = Vector2(0, -25)
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	embers.emission_sphere_radius = radius * 0.85
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([_fire_colors[0], _fire_colors[1], _fire_colors[3], Color(_fire_colors[4], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	embers.color_ramp = ramp
	add_child(embers)
	embers.emitting = true
