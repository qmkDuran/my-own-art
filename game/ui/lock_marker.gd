class_name LockMarker
extends Control
## The lock-on marker: four corner brackets and a small diamond over the locked target.

const HEAD_ABOVE: float = 1.2
const BRACKET: float = 26.0
const ARM: float = 9.0
const DIAMOND: float = 6.0
const LINE_WIDTH: float = 3.0

var _lock_on: LockOn
var _camera: Camera3D


func setup(lock_on: LockOn, camera: Camera3D) -> void:
	_lock_on = lock_on
	_camera = camera
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not _lock_on.target_locked():
		return
	var above: Vector3 = _lock_on.target.global_position + Vector3.UP * HEAD_ABOVE
	if _camera.is_position_behind(above):
		return
	var centre: Vector2 = _camera.unproject_position(_lock_on.target.chest_position())
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var tip: Vector2 = centre + corner * BRACKET
		draw_line(tip, tip - Vector2(corner.x * ARM, 0), HudStyle.LOCK_COLOR, LINE_WIDTH)
		draw_line(tip, tip - Vector2(0, corner.y * ARM), HudStyle.LOCK_COLOR, LINE_WIDTH)
	var top: Vector2 = _camera.unproject_position(above)
	var diamond := PackedVector2Array([top + Vector2(0, -DIAMOND), top + Vector2(DIAMOND, 0),
		top + Vector2(0, DIAMOND), top + Vector2(-DIAMOND, 0)])
	draw_colored_polygon(diamond, HudStyle.LOCK_COLOR)
