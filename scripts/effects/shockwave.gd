class_name Shockwave
extends Node2D
## An expanding ring that fades out, e.g. the Warden's rod shove.
##
## Spawn it, call play(), and it removes itself when done.

## Thickness of the ring, in pixels.
@export var ring_width: float = 1.5

var _max_radius: float = 0.0
var _duration: float = 0.0
var _color: Color = Color.WHITE
var _elapsed: float = 0.0


func play(max_radius: float, duration: float, color: Color) -> void:
	_max_radius = max_radius
	_duration = duration
	_color = color
	_elapsed = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	var faded := Color(_color, _color.a * (1.0 - progress))
	draw_arc(Vector2.ZERO, _max_radius * progress, 0.0, TAU, 32, faded, ring_width)
