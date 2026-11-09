class_name ScreenShake
extends Node
## Gives the active camera a short, fading shake (e.g. a heavy hit landing).
##
## Works on whichever Camera2D the viewport is using, so it needs no wiring.
## Moves the camera in whole pixels only, so the pixel art stays crisp.

## More than this many pixels is noise at 480×270 (see PROJECT_B.md, hit-feel kit).
const MAX_STRENGTH := 4.0

var _strength: float = 0.0
var _duration: float = 0.0
var _seconds_left: float = 0.0
var _camera: Camera2D = null


## Shakes the camera up to `strength` pixels, fading to nothing over `duration` seconds.
## A stronger shake replaces a weaker one; a weaker one never cuts a stronger one short.
func shake(strength: float, duration: float) -> void:
	if _seconds_left > 0.0 and minf(strength, MAX_STRENGTH) < _current_strength():
		return
	_camera = get_viewport().get_camera_2d()
	_strength = minf(strength, MAX_STRENGTH)
	_duration = maxf(duration, 0.001)
	_seconds_left = _duration


func _process(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	_seconds_left = maxf(0.0, _seconds_left - delta)
	if _seconds_left == 0.0:
		_camera.offset = Vector2.ZERO
		_camera = null
		return
	var reach := roundi(_current_strength())
	_camera.offset = Vector2(randi_range(-reach, reach), randi_range(-reach, reach))


## The shake fades out linearly as it runs.
func _current_strength() -> float:
	return _strength * (_seconds_left / _duration)
