class_name SpeedTrail
extends Line2D
## Draws a fading streak behind something moving fast, so a burst of speed is easy to see.
##
## While active it records where the target has been; when stopped, the streak
## shrinks away from the tail end.

## What the streak follows.
@export var target: Node2D
## Where on the target the streak attaches, e.g. the middle of the body.
@export var attach_offset: Vector2 = Vector2(0, -6)
## Longest the streak can get, in recorded points (one point per physics frame).
@export var max_points: int = 8

var _is_recording: bool = false


func _ready() -> void:
	# Points are stored in world space so the streak stays behind as the target moves.
	top_level = true
	global_position = Vector2.ZERO
	clear_points()


func play_for(duration: float) -> void:
	_is_recording = true
	await Wait.seconds(self, duration)
	_is_recording = false


func _physics_process(_delta: float) -> void:
	if _is_recording:
		add_point(target.global_position + attach_offset)
		if get_point_count() > max_points:
			remove_point(0)
	elif get_point_count() > 0:
		remove_point(0)
