class_name MoveKind
extends RefCounted
## One kind of creature move (strike, bolt, lunge, burst, guard). MoveBook keeps one of each and hands it the move's
## data; a new behaviour is a new subclass registered there. Helpers find who is in reach and clamp aims to range.


func cast(_user: Creature, _m: Dictionary, _at: Vector2) -> void:
	pass


## Living foes of `user` whose bodies touch the circle.
static func foes_in(user: Creature, center: Vector2, radius: float) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for f: Combatant in user.foes():
		if f.global_position.distance_to(center) <= radius + f.hit_radius():
			out.append(f)
	return out


## The aim point, no further than the move's range from the user.
static func clamp_aim(user: Creature, m: Dictionary, at: Vector2) -> Vector2:
	var reach: float = float(m.get("range", 0.0))
	var d: Vector2 = at - user.global_position
	return user.global_position + d.limit_length(reach) if reach > 0.0 else at


static func dir_to(user: Creature, at: Vector2) -> Vector2:
	var d: Vector2 = at - user.global_position
	return d.normalized() if d.length() > 1.0 else user.facing


static func element(user: Creature, m: Dictionary) -> String:
	return CreatureCombat.move_element(user, m)
