class_name CaptainRodSweep
extends CaptainAttack
## The Captain's rod sweep: he cocks the halberd-rod back while a red wedge on the ground
## fills in front of him (toward where the player stood), then swings it in a wide arc.
## Anyone in the wedge is hurt and shoved away. A dodge, or a step back out of reach, avoids it.
## The whole wedge shows faintly from the first frame of the wind-up, with a bold pulsing
## outline (see TelegraphPainter); the fill sweeping outward times the swing.

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
@export var slash_color: Color = ApolloPalette.SILVER
## Seconds the slash stays visible after the swing.
@export var slash_time: float = 0.15

## The faint fill showing the whole wedge, and the growing fill's opacity from start to swing.
const ZONE_ALPHA := 0.1
const GROWING_FILL_ALPHA := Vector2(0.12, 0.32)
## The outline's opacity, and how much the pulse adds.
const OUTLINE_ALPHA := 0.7
const OUTLINE_PULSE_ALPHA := 0.25
## The outline's sides start this far out, in pixels, so they don't cross his feet.
const OUTLINE_INNER_RADIUS := 6.0

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
	if PlayerHit.try_to_hurt(player, damage, captain.global_position):
		PlayerHit.shove(player, to_player.normalized() * push_speed, push_time)


func _draw() -> void:
	var half_arc := deg_to_rad(half_arc_degrees)
	var facing := _direction.angle()
	if is_winding_up() and _wind_up_progress > 0.0:
		_draw_wind_up(facing, half_arc)
	elif _seconds_since_slash < slash_time:
		var fade := 1.0 - _seconds_since_slash / slash_time
		draw_arc(Vector2.ZERO, reach - 2.0, facing - half_arc, facing + half_arc, 16, Color(slash_color, fade), 2.0)
		draw_arc(Vector2.ZERO, reach - 6.0, facing - half_arc * 0.8, facing + half_arc * 0.8, 16, Color(slash_color, fade * 0.5), 1.0)


## The whole wedge faintly, a stronger fill sweeping out toward the swing, and a bold
## pulsing outline around it.
func _draw_wind_up(facing: float, half_arc: float) -> void:
	var from := facing - half_arc
	var to := facing + half_arc
	TelegraphPainter.fill_wedge(self, Vector2.ZERO, reach, from, to, Color(TelegraphPainter.DANGER_COLOR, ZONE_ALPHA))
	var growing_alpha := lerpf(GROWING_FILL_ALPHA.x, GROWING_FILL_ALPHA.y, _wind_up_progress)
	TelegraphPainter.fill_wedge(self, Vector2.ZERO, reach * _wind_up_progress, from, to, Color(TelegraphPainter.DANGER_COLOR, growing_alpha))
	var pulse := TelegraphPainter.pulse(_wind_up_progress * current_wind_up)
	var outline := TelegraphPainter.outline_color(pulse, OUTLINE_ALPHA + OUTLINE_PULSE_ALPHA * pulse)
	var width := TelegraphPainter.OUTLINE_WIDTH
	draw_arc(Vector2.ZERO, reach, from, to, 16, outline, width)
	for side: float in [from, to]:
		var outward := Vector2.from_angle(side)
		draw_line(outward * OUTLINE_INNER_RADIUS, outward * reach, outline, width)
