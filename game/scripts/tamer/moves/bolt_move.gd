class_name BoltMove
extends MoveKind
## Projectiles toward the aim: `count` of them fanned over `spread` degrees (360: a ring), each a CreatureBolt.

const MUZZLE: float = 12.0


func cast(user: Creature, m: Dictionary, at: Vector2, _strength: float = 1.0) -> void:
	var dir: Vector2 = dir_to(user, at)
	var n: int = int(m.get("count", 1))
	var spread: float = deg_to_rad(float(m.get("spread", 0.0)))
	var ring: bool = spread >= TAU - 0.01
	for k: int in n:
		var off: float = 0.0
		if ring:
			off = TAU * k / n
		elif n > 1:
			off = lerpf(-spread * 0.5, spread * 0.5, float(k) / (n - 1))
		CreatureBolt.fire(user, m, user.global_position + dir * MUZZLE, dir.rotated(off))
	Audio.sfx("bolt", -9.0, randf_range(1.1, 1.3))
