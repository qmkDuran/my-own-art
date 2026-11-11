class_name SwarmBrain
extends EnemyBrain
## Gloams: close in, crouch for a moment (eyes go red), lunge and bite.

const LUNGE_TIME: float = 0.14


func _think(_delta: float) -> Vector2:
	var d: Dictionary = e.data
	match state:
		"windup":
			if t <= 0.0:
				state = "strike"
				t = LUNGE_TIME
			return Vector2.ZERO
		"strike":
			if t <= 0.0:
				melee(float(d["range"]))
				state = "chase"
				cd = float(d["cooldown"])
			return (aim - e.global_position).normalized() * float(d["lunge"]) / LUNGE_TIME
	if to_player().length() < HOLD_BACK and not may_engage():
		return circle_around(HOLD_BACK, e.speed)
	if to_player().length() < float(d["range"]) + 18.0 and cd <= 0.0:
		state = "windup"
		t = float(d["windup"]) / e.attack_speed()
		aim = player().global_position
		Audio.sfx("hiss", -14.0, randf_range(0.9, 1.2))
		return Vector2.ZERO
	return chase(player().global_position, e.speed)
