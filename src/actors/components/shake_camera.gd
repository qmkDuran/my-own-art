class_name ShakeCamera
extends Camera2D
## Follows its parent smoothly and shakes on Events.shake_requested.

var _strength := 0.0
var _remaining := 0.0
var _duration := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	offset = Vector2(0, -24)
	Events.shake_requested.connect(shake)
	make_current()


func set_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)


func shake(strength: float, duration: float) -> void:
	_strength = maxf(_strength, strength)
	_remaining = maxf(_remaining, duration)
	_duration = maxf(_remaining, 0.01)


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		offset = Vector2(0, -24)
		_strength = 0.0
		return
	_remaining -= delta
	var amount := _strength * (_remaining / _duration)
	offset = Vector2(0, -24) + Vector2(randf_range(-amount, amount), randf_range(-amount, amount)).round()
