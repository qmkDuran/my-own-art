class_name ShooterBrain
extends EnemyBrain
## Keeps its distance (between keep_near and keep_far), drifting side to side, and every few seconds, when it can
## see the player, charges a glowing shot (a telegraph of about 0.75 s, with a warning chime) and fires it at where
## the player is: slow enough to dodge, and a ward stops it.

const STRAFE_SHARE: float = 0.7
const CHARGING_PACE: float = 0.25
const FIRST_SHOT_SHARE: float = 0.5
const STRAFE_JITTER: Vector2 = Vector2(0.7, 1.3)

var _fire_in: float = -1.0
var _charge: float = -1.0
var _strafe: float = 1.0
var _strafe_timer: float = 0.0


func think(enemy: Enemy, delta: float) -> void:
	if _fire_in < 0.0:
		_fire_in = float(enemy.spec["fire_every"]) * FIRST_SHOT_SHARE * randf_range(1.0, 2.0)
	var to: Vector3 = to_player(enemy)
	enemy.look_at_point = enemy.roster.player.global_position
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = float(enemy.spec["strafe_seconds"]) * randf_range(STRAFE_JITTER.x, STRAFE_JITTER.y)
		_strafe = -_strafe
	var radial: float = 0.0
	if to.length() < float(enemy.spec["keep_near"]):
		radial = -1.0
	elif to.length() > float(enemy.spec["keep_far"]):
		radial = 1.0
	var side: Vector3 = to.normalized().cross(Vector3.UP) * _strafe * STRAFE_SHARE
	enemy.wish = (to.normalized() * radial + side).limit_length(1.0)
	if _charge >= 0.0:
		_charging(enemy, delta)
		return
	_fire_in -= delta
	if _fire_in <= 0.0 and to.length() < float(enemy.spec["keep_far"]) * 2.0 and sees_player(enemy):
		_charge = float(enemy.spec["telegraph"])
		enemy.look().charge(_charge)
		enemy.roster.warn(enemy)


func _charging(enemy: Enemy, delta: float) -> void:
	enemy.wish *= CHARGING_PACE
	_charge -= delta
	if _charge > 0.0:
		return
	_charge = -1.0
	_fire_in = float(enemy.spec["fire_every"]) + randf() * float(enemy.spec["fire_jitter"])
	var from: Vector3 = enemy.look().muzzle()
	EnemyShot.fire(enemy.roster, from, from.direction_to(player_chest(enemy)), float(enemy.spec["shot_speed"]),
		float(enemy.spec["shot_damage"]), float(enemy.spec["shot_radius"]), float(enemy.spec["telegraph"]))
