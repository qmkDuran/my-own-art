class_name SwarmerBrain
extends EnemyBrain
## Small, fast, in packs: rushes the player, and up close winds up (a quick crouch, 0.35 s) and lunges. A lunge
## that reaches the player bites once; then it backs off for a moment before the next.

enum Step { CHASE, WINDUP, LUNGE, REST }

const CROUCH: float = 0.3
const LUNGE_HOP: float = 0.35
const REST_PACE: float = 0.35

var _step: Step = Step.CHASE
var _timer: float = 0.0
var _cooldown: float = 0.0
var _direction: Vector3 = Vector3.ZERO
var _bit: bool = false


func think(enemy: Enemy, delta: float) -> void:
	_timer -= delta
	_cooldown -= delta
	var to: Vector3 = to_player(enemy)
	enemy.look_at_point = enemy.roster.player.global_position
	enemy.pose_squash = 0.0
	enemy.pose_lift = 0.0
	match _step:
		Step.CHASE:
			enemy.wish = to.normalized()
			if to.length() < float(enemy.spec["lunge_range"]) and _cooldown <= 0.0:
				_begin(Step.WINDUP, float(enemy.spec["lunge_windup"]))
				enemy.look().windup(_timer)
		Step.WINDUP:
			enemy.wish = Vector3.ZERO
			enemy.pose_squash = CROUCH * (1.0 - _timer / float(enemy.spec["lunge_windup"]))
			if _timer <= 0.0:
				_direction = to.normalized()
				_bit = false
				_begin(Step.LUNGE, float(enemy.spec["lunge_seconds"]))
		Step.LUNGE:
			_lunge(enemy)
		Step.REST:
			enemy.wish = -to.normalized() * REST_PACE
			if _timer <= 0.0:
				_step = Step.CHASE


func _begin(step: Step, seconds: float) -> void:
	_step = step
	_timer = seconds


func _lunge(enemy: Enemy) -> void:
	enemy.wish = _direction
	enemy.look_at_point = enemy.global_position + _direction
	enemy.pose_lift = sin(PI * (1.0 - _timer / float(enemy.spec["lunge_seconds"]))) * LUNGE_HOP
	var reach: float = enemy.radius + Tuning.number("combat", "player", "body_radius")
	if not _bit and enemy.centre().distance_to(player_chest(enemy)) < reach + enemy.radius:
		_bit = true
		enemy.roster.strike(enemy, float(enemy.spec["damage"]), float(enemy.spec["lunge_windup"]))
	if _timer <= 0.0:
		_cooldown = float(enemy.spec["lunge_cooldown"])
		_begin(Step.REST, float(enemy.spec["lunge_cooldown"]) * 0.5)


func speed_scale(enemy: Enemy) -> float:
	return float(enemy.spec["lunge_speed"]) / float(enemy.spec["speed"]) if _step == Step.LUNGE else 1.0
