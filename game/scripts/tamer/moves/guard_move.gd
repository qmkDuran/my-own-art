class_name GuardMove
extends MoveKind
## A ward: the user soaks `absorb` damage for `duration` seconds; a bond ward also heals it and blasts the foes
## around it.

const WARD_R: float = 22.0


func cast(user: Creature, m: Dictionary, _at: Vector2) -> void:
	var el: String = element(user, m)
	var time: float = float(m["duration"])
	user.add_guard(float(m["absorb"]), time)
	TamerFx.ward(user, WARD_R, el, time)
	Audio.sfx("lamp_lit", -8.0, 1.3)
	user.rec.heal_points(float(m.get("heal", 0.0)))
	if float(m.get("radius", 0.0)) > 0.0:
		TamerFx.blast(user.global_position, float(m["radius"]), el, true)
		for f: Combatant in foes_in(user, user.global_position, float(m["radius"])):
			CreatureCombat.hit(user, f, m, (f.global_position - user.global_position).normalized())
