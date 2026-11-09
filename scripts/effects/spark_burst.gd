class_name SparkBurst
extends Node2D
## A Fizzbug's burst: a white flash, then a crackling ring of sparks that snaps out to the
## burst's reach and breaks up. Drawn in code, every pixel on the world grid.
## Event-only: spawned by the burst, frees itself when done.

## Seconds the whole burst lasts, and the share of it the ring spends snapping out.
const DURATION := 0.3
const GROW_SHARE := 0.4
## Seconds the white flash in the middle lasts, and its radius as a share of the reach.
const FLASH_TIME := 0.06
const FLASH_SHARE := 0.35
## How far sparks jitter in and out of the ring, in pixels.
const JITTER := 2.0
## Squash, so the ring lies flat on the ground.
const GROUND_SQUASH := 0.6
## Hottest to coolest.
const COLORS: Array[Color] = [ApolloPalette.WHITE, ApolloPalette.GOLD, ApolloPalette.ORANGE]

var _radius: float = 0.0
var _age: float = 0.0
var _angles := PackedFloat32Array()
var _jitter := PackedFloat32Array()
var _noise := PackedFloat32Array()


## Adds a burst reaching `radius` pixels to `world` at `at`.
static func spawn(world: Node, at: Vector2, radius: float) -> void:
	var burst := SparkBurst.new()
	world.add_child(burst)
	burst.global_position = at.round()
	burst.z_index = 2
	burst._radius = radius
	var sparks := roundi(TAU * radius)
	for spark in sparks:
		burst._angles.append(TAU * spark / sparks)
		burst._jitter.append(randf_range(-JITTER, JITTER))
		burst._noise.append(randf())


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := _age / DURATION
	if _age < FLASH_TIME:
		draw_circle(Vector2.ZERO, _radius * FLASH_SHARE, ApolloPalette.WHITE)
	var ring := _radius * ease(minf(1.0, progress / GROW_SHARE), 0.4)
	for index in _angles.size():
		if _noise[index] < progress:  # sparks drop out as it fades
			continue
		var distance := ring + _jitter[index]
		var at := Vector2(cos(_angles[index]) * distance, sin(_angles[index]) * distance * GROUND_SQUASH)
		var color_index := clampi(floori((progress + _noise[index] * 0.5) * COLORS.size()), 0, COLORS.size() - 1)
		draw_rect(Rect2(at.round(), Vector2.ONE), COLORS[color_index])
