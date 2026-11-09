class_name HandlerRetreat
extends Node
## A Handler keeping his distance: when the player gets too close he backs away (turning
## aside from walls, see PathMover), but he tires out. After backing away for a while he
## must stop and catch his breath, which is the player's chance to catch him.
##
## The Handler asks for his next step each frame; this decides whether he backs away and how fast.

## If the player gets closer than this (pixels), he backs away.
@export var comfortable_distance: float = 50.0
## Walking speed in pixels per second. Much slower than the player, so you can catch him.
@export var walk_speed: float = 22.0
## Longest he keeps backing away before he has to stop, in seconds.
@export var max_retreat_time: float = 1.2
## Seconds he stands still to catch his breath after retreating that long.
@export var catch_breath_time: float = 1.5
@export var path_mover: PathMover

var _seconds_retreating: float = 0.0
var _seconds_catching_breath: float = 0.0

@onready var handler: Node2D = get_parent()


## His velocity this frame: backing away from a player who is too close, or zero when he's
## comfortable, pinned, or out of breath. `was_retreating`: he was backing away last frame.
func next_velocity(was_retreating: bool, delta: float) -> Vector2:
	var away_from_player := _direction_away_from_player()
	if away_from_player == Vector2.ZERO or not _can_keep_retreating(was_retreating, delta):
		return Vector2.ZERO
	return away_from_player * walk_speed


func _can_keep_retreating(was_retreating: bool, delta: float) -> bool:
	if _seconds_catching_breath > 0.0:
		_seconds_catching_breath -= delta
		return false
	if was_retreating:
		_seconds_retreating += delta
		if _seconds_retreating >= max_retreat_time:
			_seconds_retreating = 0.0
			_seconds_catching_breath = catch_breath_time
			return false
	else:
		_seconds_retreating = 0.0
	return true


## Points away from the player when they're too close (but not into a wall); zero when
## he's comfortable, or pinned with nowhere to back away to.
func _direction_away_from_player() -> Vector2:
	var player := PlayerFinder.find(self)
	if player == null:
		return Vector2.ZERO
	var comfortable_squared := comfortable_distance * comfortable_distance
	if handler.global_position.distance_squared_to(player.global_position) >= comfortable_squared:
		return Vector2.ZERO
	return path_mover.direction_away_from(player.global_position)
