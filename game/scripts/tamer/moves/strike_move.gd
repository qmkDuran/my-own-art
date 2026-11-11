class_name StrikeMove
extends MoveKind
## A close blow: every foe inside an arc in front (toward the aim) is hit once; a crescent sweeps across it.

const HEIGHT: float = 10.0


func cast(user: Creature, m: Dictionary, at: Vector2) -> void:
	var dir: Vector2 = dir_to(user, at)
	var reach: float = float(m["range"])
	var half: float = deg_to_rad(float(m.get("arc", 120.0))) * 0.5
	TamerFx.slash(user.global_position + Vector2(0, -HEIGHT) + dir * 6.0, dir, reach, float(m.get("arc", 120.0)), element(user, m))
	Audio.sfx("hit", -8.0, randf_range(1.0, 1.2))
	for f: Combatant in foes_in(user, user.global_position, reach):
		var to: Vector2 = f.global_position - user.global_position
		if to.length() < f.hit_radius() + user.hit_radius() or absf(dir.angle_to(to)) <= half:
			CreatureCombat.hit(user, f, m, to.normalized())
