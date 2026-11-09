class_name RootSnare
extends Node2D
## A Bramole's root snare: roots burst out of the ground in a ring of twisting spokes, hold
## for a moment, then crumble away pixel by pixel. Also used small at a rooted player's feet,
## lasting as long as the root. Drawn in code, every pixel on the world grid.
## Event-only: spawned by the slam, frees itself when done.

## Seconds for the roots to shoot out to full length.
const GROW_TIME := 0.1
## Seconds they take to crumble away at the end.
const CRUMBLE_TIME := 0.3
## Pixels between spokes along the ring's edge (more spokes for a bigger snare).
const SPOKE_SPACING := 9.0
## How far a spoke wiggles sideways, in pixels, and how many wiggles it makes.
const WIGGLE_PIXELS := 1.5
const WIGGLES := 2.0
## Squash, so the snare lies flat on the ground.
const GROUND_SQUASH := 0.6
## Dark root near the middle, bright leafy tips.
const COLORS: Array[Color] = [ApolloPalette.GREEN_LIGHT, ApolloPalette.GREEN, ApolloPalette.CORK_DARK]

var _hold_time: float = 0.0
var _age: float = 0.0
## Each pixel: where it is, how far out along its spoke (0-1) and a random value for crumbling.
var _offsets := PackedVector2Array()
var _reach := PackedFloat32Array()
var _noise := PackedFloat32Array()


## Adds a snare of `radius` pixels to `world` at `at`, holding for `hold_time` seconds.
static func spawn(world: Node, at: Vector2, radius: float, hold_time: float) -> RootSnare:
	var snare := RootSnare.new()
	world.add_child(snare)
	snare.global_position = at.round()
	snare._hold_time = hold_time
	snare._collect_cells(radius)
	return snare


func _process(delta: float) -> void:
	_age += delta
	if _age >= GROW_TIME + _hold_time + CRUMBLE_TIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var grown := minf(1.0, _age / GROW_TIME)
	var crumbled := clampf((_age - GROW_TIME - _hold_time) / CRUMBLE_TIME, 0.0, 1.0)
	for index in _offsets.size():
		if _reach[index] > grown or _noise[index] < crumbled:
			continue
		var color_index := clampi(floori((1.0 - _reach[index]) * COLORS.size()), 0, COLORS.size() - 1)
		draw_rect(Rect2(_offsets[index], Vector2.ONE), COLORS[color_index])


func _collect_cells(radius: float) -> void:
	var spokes := maxi(5, roundi(TAU * radius / SPOKE_SPACING))
	var seen := {}
	for spoke in spokes:
		var angle := TAU * (spoke + randf_range(-0.25, 0.25)) / spokes
		var along := Vector2(cos(angle), sin(angle))
		var phase := randf() * TAU
		for step in range(2, ceili(radius) + 1):
			var share := step / radius
			var wiggle := along.orthogonal() * sin(phase + share * WIGGLES * TAU) * WIGGLE_PIXELS
			var at := along * step + wiggle
			var cell := Vector2(at.x, at.y * GROUND_SQUASH).round()
			if seen.has(cell):
				continue
			seen[cell] = true
			_offsets.append(cell)
			_reach.append(share)
			_noise.append(randf())
