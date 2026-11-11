class_name LeaperBrain
extends EnemyBrain
## Splinter Hounds: run you down; at middle distance they crouch, a lane lights up on the ground, and they leap
## along it, biting whatever is there when they land. Close up they snap.

const RECOVER: float = 0.45

var _bit: bool = false


func _think(_delta: float) -> Vector2:
	var d: Dictionary = e.data
	match state:
		"windup":
			if t <= 0.0:
				state = "strike"
				_bit = false
				t = e.global_position.distance_to(aim) / float(d["leap_speed"])
				Audio.sfx("leap", -10.0)
			return Vector2.ZERO
		"strike":
			if not _bit and melee(float(d["range"]) * 0.5):
				_bit = true
			if t <= 0.0:
				state = "recover"
				t = RECOVER
				cd = float(d["cooldown"])
			return (aim - e.global_position).normalized() * float(d["leap_speed"])
		"recover":
			if t <= 0.0:
				state = "chase"
			return Vector2.ZERO
	return _hunt(d)


func _hunt(d: Dictionary) -> Vector2:
	var dist: float = to_player().length()
	if cd <= 0.0 and dist > float(d["leap_min"]) and dist < float(d["leap_max"]) and may_engage() \
			and Game.current.nav.line_free(e.global_position, player().global_position):
		state = "windup"
		t = float(d["windup"]) / e.attack_speed()
		aim = player().global_position + to_player().normalized() * 20.0
		Telegraph.line(Game.current.fx_layer, e.global_position, aim, t)
		return Vector2.ZERO
	if cd <= 0.0 and dist < float(d["range"]) + player().radius + e.radius:
		melee(float(d["range"]))
		cd = float(d["cooldown"]) * 0.6
	return chase(player().global_position, e.speed)
