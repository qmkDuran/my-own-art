class_name CaptainRodSweep
extends CaptainAttack
## The Captain's rod sweep: he cocks the halberd-rod back while a red wedge on the ground
## fills in front of him (toward where the player stood), then swings it in a wide arc.
## Anyone in the wedge is hurt and shoved away. A dodge, or a step back out of reach, avoids it.

## He sweeps when the player is this close, in pixels.
@export var trigger_distance: float = 34.0
## How far the sweep reaches, in pixels.
@export var reach: float = 36.0
## Half the width of the arc, in degrees (so the arc is twice this wide).
@export var half_arc_degrees: float = 70.0
@export var damage: int = 2
## Speed the player is shoved at, in pixels per second.
@export var push_speed: float = 190.0
## Seconds the shove controls the player.
@export var push_time: float = 0.25
@export var telegraph_color: Color = ApolloPalette.RED
@export var slash_color: Color = ApolloPalette.SILVER
## Seconds the slash stays visible after the swing.
@export var slash_time: float = 0.15

## Locked when the wind-up starts: the sweep goes there, wherever the player moves.
var _direction: Vector2 = Vector2.DOWN
var _wind_up_progress: float = 0.0
var _seconds_since_slash: float = INF


func _process(delta: float) -> void:
	if _seconds_since_slash < slash_time:
		_seconds_since_slash += delta
		queue_redraw()


func _is_wanted(distance_to_player: float) -> bool:
	return distance_to_player <= trigger_distance


func _on_start() -> void:
	var player := PlayerFinder.find(self)
	if player != null and player.global_position != captain.global_position:
		_direction = captain.global_position.direction_to(player.global_position)
	_wind_up_progress = 0.0


func _on_wind_up(progress: float) -> void:
	_wind_up_progress = progress


func _release() -> void:
	_seconds_since_slash = 0.0
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var to_player := player.global_position - captain.global_position
	var is_in_arc := absf(_direction.angle_to(to_player)) <= deg_to_rad(half_arc_degrees)
	if to_player.length() > reach or not is_in_arc:
		return
	var player_health: Health = player.get_node_or_null("Health")
	if player_health == null or player_health.is_invulnerable:
		return  # dodged through it
	player_health.take_damage(damage, captain.global_position)
	if player.has_method("push"):
		player.push(to_player.normalized() * push_speed, push_time)


func _draw() -> void:
	var half_arc := deg_to_rad(half_arc_degrees)
	var facing := _direction.angle()
	if is_winding_up() and _wind_up_progress > 0.0:
		# The wedge fills outward as the swing gets closer.
		var fill := Color(telegraph_color, 0.12 + 0.2 * _wind_up_progress)
		draw_colored_polygon(_wedge(reach * _wind_up_progress, facing, half_arc), fill)
		draw_arc(Vector2.ZERO, reach, facing - half_arc, facing + half_arc, 16, Color(telegraph_color, 0.7), 1.0)
	elif _seconds_since_slash < slash_time:
		var fade := 1.0 - _seconds_since_slash / slash_time
		draw_arc(Vector2.ZERO, reach - 2.0, facing - half_arc, facing + half_arc, 16, Color(slash_color, fade), 2.0)
		draw_arc(Vector2.ZERO, reach - 6.0, facing - half_arc * 0.8, facing + half_arc * 0.8, 16, Color(slash_color, fade * 0.5), 1.0)


func _wedge(radius: float, facing: float, half_arc: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var steps := 12
	for step in steps + 1:
		var angle := facing - half_arc + 2.0 * half_arc * step / steps
		points.append(Vector2.from_angle(angle) * radius)
	return points
