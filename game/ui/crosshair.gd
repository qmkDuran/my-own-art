class_name Crosshair
extends Control
## A small aiming ring in the middle of the screen (hidden while locked on: the lock marker takes over).

const RING_RADIUS: float = 9.0
const DOT_RADIUS: float = 2.0
const RING_SEGMENTS: int = 24
const SHADOW_WIDTH: float = 3.0
const LINE_WIDTH: float = 1.5

var _lock_on: LockOn


func setup(lock_on: LockOn) -> void:
	_lock_on = lock_on
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	visible = not _lock_on.target_locked()


func _draw() -> void:
	var centre: Vector2 = size * 0.5
	draw_arc(centre, RING_RADIUS, 0.0, TAU, RING_SEGMENTS, HudStyle.SHADOW, SHADOW_WIDTH)
	draw_arc(centre, RING_RADIUS, 0.0, TAU, RING_SEGMENTS, HudStyle.INK, LINE_WIDTH)
	draw_circle(centre, DOT_RADIUS, HudStyle.INK)
