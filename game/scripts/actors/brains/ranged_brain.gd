class_name RangedBrain
extends EnemyBrain
## Mirror Moths: hold a distance, drift sideways, then flare their body and loose a shard of stolen light.

const STRAFE: float = 0.45

var _side: float = 1.0


func _think(_delta: float) -> Vector2:
	var d: Dictionary = e.data
	if state == "windup":
		if t <= 0.0:
			state = "chase"
			cd = float(d["cooldown"])
			shoot(player().global_position - e.global_position, float(d["shot_speed"]))
			Audio.sfx("shard", -9.0, randf_range(0.95, 1.1))
		return Vector2.ZERO
	var v: Vector2 = to_player()
	var dist: float = v.length()
	var clear: bool = Game.current.nav.line_free(e.global_position, player().global_position)
	if cd <= 0.0 and dist <= float(d["range"]) and clear:
		state = "windup"
		t = float(d["windup"]) / e.attack_speed()
		return Vector2.ZERO
	if dist > float(d["range"]) or not clear:
		return chase(player().global_position, e.speed)
	if randf() < 0.01:
		_side = -_side
	var strafe: Vector2 = v.normalized().orthogonal() * _side * e.speed * STRAFE
	if dist < float(d["keep"]):
		return -v.normalized() * e.speed + strafe
	return strafe
