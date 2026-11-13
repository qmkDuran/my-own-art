class_name HitFeel
extends Node
## The weight of a hit: a hit-stop of a few frames (the world nearly freezes) on kills and strong hits, and a tiny
## camera nudge on critical hits only. Kept small so it reads as punch, never as stutter.

var _camera: Camera3D
var _stop_frames: int = 0
var _nudge: float = 0.0


func setup(camera: Camera3D) -> void:
	name = "HitFeel"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = camera


func hit_stop(frames: int, time_scale: float) -> void:
	_stop_frames = maxi(_stop_frames, frames)
	Engine.time_scale = time_scale


func nudge(amount: float, seconds: float) -> void:
	if _camera == null:
		return
	_nudge = amount
	var tween: Tween = create_tween()
	tween.tween_property(self, "_nudge", 0.0, seconds)


func _process(_delta: float) -> void:
	if _stop_frames > 0:
		_stop_frames -= 1
		if _stop_frames == 0:
			Engine.time_scale = 1.0
	if _camera != null:
		_camera.h_offset = randf_range(-_nudge, _nudge)
		_camera.v_offset = randf_range(-_nudge, _nudge)
