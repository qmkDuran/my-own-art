class_name EmberStreak
extends Node2D
## A quick streak of fire racing from one point to another (Wildfire's burn jumping to the
## next enemy), drawn in code pixel by pixel: a white-hot head shoots along a short arc,
## leaving a thick tail that cools through gold and orange to red (EmberooFlameColors'
## burst ramp) and throws off flickering sparks; where it lands, the fire flares up in a
## small burst over a faint glow.
##
## Spawn it in the world, call play(), and it removes itself when done.

## How high the streak arcs above the straight line, as a share of its length.
const ARC_HEIGHT := 0.25
## How long the tail is, as a share of the whole path.
const TAIL_LENGTH := 0.45
## Thickness of the head and of the tail's hot first half, in pixels.
const HEAD_THICKNESS := 3
const TAIL_THICKNESS := 2
## Sparks flicking off the tail: share of tail pixels that throw one, and how far out.
const SPARK_SHARE := 0.25
const SPARK_REACH := 3
## Times per second the sparks pick new places.
const FLICKER_RATE := 24.0
## The burst where it lands: its largest radius, and its glow.
const LANDING_RADIUS := 9.0
const GLOW_RADIUS := 14.0
const GLOW_STRENGTH := 0.3
const STREAK_Z_INDEX := 2

## Seconds for the head to reach the far end; the tail then fades for as long again.
@export var travel_time: float = 0.16

var _ramp: Array[Color] = EmberooFlameColors.burst_ramp()
var _path := PackedVector2Array()
var _elapsed: float = 0.0
var _has_landed: bool = false


## Shoots the streak from `from` to `to` (global positions).
func play(from: Vector2, to: Vector2) -> void:
	z_index = STREAK_Z_INDEX
	global_position = from.round()
	_build_path(to - from)
	get_tree().create_timer(travel_time * 2.0).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	if not _has_landed and _elapsed >= travel_time and not _path.is_empty():
		_has_landed = true
		var glow := FxGlow.add_to(self, GLOW_RADIUS, _ramp[2], GLOW_STRENGTH, travel_time)
		glow.position = _path[_path.size() - 1]
	queue_redraw()


func _draw() -> void:
	if _path.is_empty():
		return
	var head := clampf(_elapsed / travel_time, 0.0, 1.0)
	var fade := clampf((_elapsed - travel_time) / travel_time, 0.0, 1.0)
	var flicker_step := floori(_elapsed * FLICKER_RATE)
	var last_index := _path.size() - 1
	for index in _path.size():
		var along := float(index) / maxf(1.0, last_index)
		var behind_head := (head - along) / TAIL_LENGTH
		if behind_head < 0.0 or behind_head > 1.0 - fade:
			continue
		var color := FxPixels.ramp_color(_ramp, behind_head)
		var thickness := HEAD_THICKNESS if behind_head < 0.1 else (TAIL_THICKNESS if behind_head < 0.5 else 1)
		var half := floorf(thickness / 2.0)
		draw_rect(Rect2(_path[index] - Vector2(half, half), Vector2.ONE * thickness), color)
		if FxPixels.noise(index, 0, flicker_step) < SPARK_SHARE:
			var offset := Vector2i(roundi((FxPixels.noise(index, 1, flicker_step) - 0.5) * 2.0 * SPARK_REACH), -roundi(FxPixels.noise(index, 2, flicker_step) * SPARK_REACH))
			draw_rect(Rect2(_path[index] + Vector2(offset), Vector2.ONE), FxPixels.ramp_color(_ramp, behind_head + 0.2))
	if _has_landed:
		_draw_landing(fade)


## The fire catching on the next enemy: a disc that flares out white-hot and cools as it grows.
func _draw_landing(progress: float) -> void:
	var landing := _path[_path.size() - 1]
	var radius := LANDING_RADIUS * ease(progress, 0.3)
	FxPixels.draw_ring(self, landing, radius, radius * progress, FxPixels.ramp_color(_ramp, progress))


## One pixel per step along a shallow arc from here to `offset`.
func _build_path(offset: Vector2) -> void:
	var steps := maxi(2, ceili(offset.length()))
	var bulge := Vector2(0, -offset.length() * ARC_HEIGHT)
	for step in steps + 1:
		var along := float(step) / steps
		var point := offset * along + bulge * sin(PI * along)
		var cell := point.round()
		if _path.is_empty() or _path[_path.size() - 1] != cell:
			_path.append(cell)
