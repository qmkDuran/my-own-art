class_name EliteBrain
extends EnemyBrain
## The shielded elite: plods towards the player and, up close, raises its pitchfork for a ground slam (a circle
## telegraph of about 0.85 s, then a shockwave). Its moonlit shield soaks up the primary but cracks fast under the
## heavy and the bomb; when it breaks, the elite staggers and its body can be hurt.

const CROUCH: float = 0.18
const WOBBLE: float = 0.12
const WOBBLE_SPEED: float = 12.0

var _cooldown: float = 0.0
var _stagger: float = 0.0
var _slam: Telegraph
var _clock: float = 0.0


func think(enemy: Enemy, delta: float) -> void:
	_clock += delta
	_cooldown -= delta
	_stagger = maxf(_stagger - delta, 0.0)
	enemy.pose_squash = 0.0
	if _stagger > 0.0:
		enemy.wish = Vector3.ZERO
		enemy.pose_squash = sin(_clock * WOBBLE_SPEED) * WOBBLE
		return
	var to: Vector3 = to_player(enemy)
	enemy.look_at_point = enemy.roster.player.global_position
	if is_instance_valid(_slam):
		enemy.wish = Vector3.ZERO
		enemy.pose_squash = CROUCH * _slam.progress
		return
	enemy.wish = to.normalized()
	if to.length() < float(enemy.spec["slam_range"]) and _cooldown <= 0.0:
		_cooldown = float(enemy.spec["slam_cooldown"])
		_slam = Telegraph.circle(enemy.roster, enemy.global_position, float(enemy.spec["slam_radius"]),
			float(enemy.spec["telegraph"]), float(enemy.spec["damage"]))
		_slam.resolved.connect(func(_hit_player: bool) -> void: enemy.roster.cue("slam", enemy.global_position))


func speed_scale(_enemy: Enemy) -> float:
	return 0.0 if _stagger > 0.0 else 1.0


func on_shield_broken(enemy: Enemy) -> void:
	_stagger = float(enemy.spec["stagger_seconds"])
	if is_instance_valid(_slam):
		_slam.cancel()
