class_name KnuckleBarrage
extends BossAttack
## The Shalendrill's knuckle barrage (the Ash Guard check): it cocks both stone fists back
## while a red wedge fills toward the player, then throws a quick chain of punches, each
## turning a little after the player. Too quick to side-step them all: back out of reach, or
## stand and take them on Ash Guard. A punch that lands on the guard cracks its knuckles on
## the ash: after the barrage it reels, shaking its hands, for a long punish window (and
## Counter Punch is armed by the blocked hit).

const ZONE_ALPHA := 0.1
const GROWING_FILL_ALPHA := Vector2(0.12, 0.32)
const OUTLINE_ALPHA := 0.75
## Seconds a punch's streak stays on screen.
const STREAK_TIME := 0.1

@export var trigger_distance: float = 34.0
## How far each punch reaches, in pixels.
@export var reach: float = 40.0
## Half the width of the wedge, in degrees.
@export var half_arc_degrees: float = 55.0
@export var punch_count: int = 3
## Seconds between punches (the first lands at the release).
@export var punch_interval: float = 0.22
## Most each punch turns after the player, from the wedge's centre, in degrees.
@export var max_turn_degrees: float = 30.0
@export var damage: int = 1
## The last punch of the chain is a haymaker.
@export var last_punch_damage: int = 2
@export var push_speed: float = 120.0
@export var push_time: float = 0.12
## Seconds it reels after its knuckles cracked on a guard (instead of `recovery_time`).
@export var reel_time: float = 2.2
@export var reel_animation: String = "reel"
@export var dust_scene: PackedScene
@export var punch_color: Color = ApolloPalette.SILVER

var _direction: Vector2 = Vector2.DOWN
var _punch_direction: Vector2 = Vector2.DOWN
var _wind_up_progress: float = 0.0
var _punches_thrown: int = 0
var _seconds_since_punch: float = INF
var _cracked_on_guard: bool = false


func _process(delta: float) -> void:
	if _seconds_since_punch < STREAK_TIME:
		_seconds_since_punch += delta
		queue_redraw()


func recovery_seconds() -> float:
	return reel_time if _cracked_on_guard else recovery_time


func recovery_pose() -> String:
	return reel_animation if _cracked_on_guard else recovery_animation


func _is_wanted(distance_to_player: float) -> bool:
	return distance_to_player <= trigger_distance


func _on_start() -> void:
	_direction = _toward_player(Vector2.DOWN)
	_punch_direction = _direction
	_wind_up_progress = 0.0
	_punches_thrown = 0
	_cracked_on_guard = false
	follow_through = punch_interval * punch_count


func _on_wind_up(progress: float) -> void:
	_wind_up_progress = progress


func update(seconds_attacking: float) -> void:
	super.update(seconds_attacking)
	if is_winding_up() or _punches_thrown >= punch_count:
		return
	var punches_due := floori((seconds_attacking - current_wind_up) / punch_interval) + 1
	while _punches_thrown < mini(punches_due, punch_count):
		_punch()


## The first punch lands at the release; `update` throws the rest on time.
func _release() -> void:
	_punch()


func _punch() -> void:
	_punches_thrown += 1
	_seconds_since_punch = 0.0
	var max_turn := deg_to_rad(max_turn_degrees)
	var turn := clampf(_direction.angle_to(_toward_player(_direction)), -max_turn, max_turn)
	_punch_direction = _direction.rotated(turn)
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var to_player := player.global_position - boss.global_position
	var is_in_arc := absf(_punch_direction.angle_to(to_player)) <= deg_to_rad(half_arc_degrees)
	if to_player.length() > reach or not is_in_arc:
		return
	var was_guarding := PlayerGuard.is_guarding(player)
	var punch_damage := last_punch_damage if _punches_thrown == punch_count else damage
	if not PlayerHit.try_to_hurt(player, punch_damage, boss.global_position):
		return
	PlayerHit.shove(player, to_player.normalized() * push_speed, push_time)
	if was_guarding and not _cracked_on_guard:
		_crack_knuckles()


func _crack_knuckles() -> void:
	_cracked_on_guard = true
	DustPuff.spawn(dust_scene, boss.get_parent(), boss.global_position + _punch_direction * 14.0)
	if hit_flash != null:
		hit_flash.flash(ApolloPalette.GREY_LIGHT)


func _toward_player(fallback: Vector2) -> Vector2:
	var player := PlayerFinder.find(self)
	if player == null or player.global_position == boss.global_position:
		return fallback
	return boss.global_position.direction_to(player.global_position)


func _draw() -> void:
	var half_arc := deg_to_rad(half_arc_degrees)
	if is_winding_up() and _wind_up_progress > 0.0:
		_draw_wind_up(_direction.angle(), half_arc)
	elif _seconds_since_punch < STREAK_TIME:
		_draw_punch_streak()


func _draw_wind_up(facing: float, half_arc: float) -> void:
	var from := facing - half_arc
	var to := facing + half_arc
	TelegraphPainter.fill_wedge(self, Vector2.ZERO, reach, from, to, Color(TelegraphPainter.DANGER_COLOR, ZONE_ALPHA))
	var growing_alpha := lerpf(GROWING_FILL_ALPHA.x, GROWING_FILL_ALPHA.y, _wind_up_progress)
	TelegraphPainter.fill_wedge(self, Vector2.ZERO, reach * _wind_up_progress, from, to, Color(TelegraphPainter.DANGER_COLOR, growing_alpha))
	var pulse := TelegraphPainter.pulse(_wind_up_progress * current_wind_up)
	var outline := TelegraphPainter.outline_color(pulse, OUTLINE_ALPHA)
	draw_arc(Vector2.ZERO, reach, from, to, 16, outline, TelegraphPainter.OUTLINE_WIDTH)
	for side: float in [from, to]:
		var outward := Vector2.from_angle(side)
		draw_line(outward * 8.0, outward * reach, outline, TelegraphPainter.OUTLINE_WIDTH)


## A short white streak along the punch, fading fast.
func _draw_punch_streak() -> void:
	var fade := 1.0 - _seconds_since_punch / STREAK_TIME
	var side := _punch_direction.orthogonal() * (3.0 if _punches_thrown % 2 == 0 else -3.0)
	draw_line(side + _punch_direction * 12.0, side + _punch_direction * (reach - 2.0), Color(punch_color, fade), 2.0)
