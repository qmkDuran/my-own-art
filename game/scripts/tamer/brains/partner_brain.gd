class_name PartnerBrain
extends CreatureBrain
## Your creature on its own: it walks at your side (a little behind, never in your way: you do not collide), fights
## what you clicked, or else the nearest wild creature that is after you or close by, and comes back if the fight
## pulls it too far. It leaves dazed creatures alone (you befriend those) unless you point at one.

const RETARGET: float = 0.2
const STOP_NEAR: float = 0.4
const FAST: float = 1.0

var _t: float = 0.0
var _target: Combatant


func think(delta: float) -> Vector2:
	var tr: Trainer = TamerGame.current.trainer
	var P: Dictionary = TamerData.rule("partner")
	if c.global_position.distance_to(tr.global_position) > float(P["teleport_after"]):
		c.global_position = TamerGame.current.layout.free_spot_near(tr.global_position + Vector2(-20, 10), c.hit_radius())
	_t -= delta
	if _t <= 0.0:
		_t = RETARGET
		_target = _pick(tr, P)
	if _target != null and is_instance_valid(_target) and _target.alive():
		return fight(_target, delta, float(P["basic_range_slack"]), c.rec.speed())
	return _follow(tr, P, delta)


func _pick(tr: Trainer, P: Dictionary) -> Combatant:
	if tr.attack_target != null and is_instance_valid(tr.attack_target) and tr.attack_target.alive():
		return tr.attack_target
	if c.global_position.distance_to(tr.global_position) > float(P["leash"]):
		return null
	var best: Combatant = null
	var best_d: float = INF
	for f: Combatant in c.foes():
		var cr := f as Creature
		if cr != null and cr.dazed:
			continue
		var d_tr: float = f.global_position.distance_to(tr.global_position)
		var engaged: bool = cr != null and cr.brain is WildBrain and (cr.brain as WildBrain).after_team()
		if d_tr < float(P["guard_range"]) or (engaged and d_tr < float(P["assist_range"])):
			if d_tr < best_d:
				best_d = d_tr
				best = f
	return best


## A spot beside and a little behind the trainer; it hurries when far, eases in when near.
func _follow(tr: Trainer, P: Dictionary, delta: float) -> Vector2:
	var back: Vector2 = -tr.heading * float(P["follow"]) + tr.heading.orthogonal() * float(P["follow_side"])
	var spot: Vector2 = tr.global_position + back
	var d: float = c.global_position.distance_to(spot)
	if d < float(P["follow"]) * STOP_NEAR:
		return Vector2.ZERO
	var hurry: float = float(P["catch_up"]) if d > float(P["follow"]) * 2.0 else FAST
	return c.steer_to(spot, delta) * c.rec.speed() * hurry * clampf(d / float(P["follow"]), 0.3, 1.0)
