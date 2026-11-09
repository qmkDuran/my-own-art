class_name EmberStreak
extends Node2D
## A quick streak of fire racing from one point to another (Wildfire's burn jumping to the
## next enemy), drawn in code pixel by pixel: a hot head shoots along a short arc, leaving
## a tail that cools from gold to red (blue-white to blue once Awakened) and breaks up behind it.
##
## Spawn it in the world, call play(), and it removes itself when done.

## How high the streak arcs above the straight line, as a share of its length.
const ARC_HEIGHT := 0.25
## How long the tail is, as a share of the whole path.
const TAIL_LENGTH := 0.45

## Seconds for the head to reach the far end; the tail then fades for as long again.
@export var travel_time: float = 0.16

## Hottest to coolest: Emberoo's fire colours when this started (see EmberooFlameColors).
var _fire_colors: Array[Color] = EmberooFlameColors.fire_ramp()
var _path := PackedVector2Array()
var _elapsed: float = 0.0


## Shoots the streak from `from` to `to` (global positions).
func play(from: Vector2, to: Vector2) -> void:
	z_index = 2
	global_position = from.round()
	_build_path(to - from)
	get_tree().create_timer(travel_time * 2.0).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	if _path.is_empty():
		return
	var head := clampf(_elapsed / travel_time, 0.0, 1.0)
	var fade := clampf((_elapsed - travel_time) / travel_time, 0.0, 1.0)
	var last_index := _path.size() - 1
	for index in _path.size():
		var along := float(index) / maxf(1.0, last_index)
		var behind_head := (head - along) / TAIL_LENGTH
		if behind_head < 0.0 or behind_head > 1.0 - fade:
			continue
		var color_index := clampi(floori(behind_head * _fire_colors.size()), 0, _fire_colors.size() - 1)
		draw_rect(Rect2(_path[index], Vector2.ONE), _fire_colors[color_index])


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
