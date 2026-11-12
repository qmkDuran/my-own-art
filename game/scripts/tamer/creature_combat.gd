class_name CreatureCombat
extends RefCounted
## Damage between creatures: the move's damage x the user's power x the element matchup x the trainer's help (Cheer,
## the bond aura, Mark, a Focus crit) x a little spread, then the weight of the hit (Lanternfall's impact, hit-stop and shake, in the element's colours),
## the number, the "Super effective!" or "Resisted" word, and bond for your creature.

const SPREAD: float = 0.1
const WORD_GAP: float = 0.6             ## one matchup word per target this often, so a flurry is not a wall of text
const TRAINER_HIT := Color("e8505a")

static var _last_word: Dictionary = {}


static func move_element(user: Creature, m: Dictionary) -> String:
	return String(m.get("element", user.element_id()))


## One hit of move `m` from `user` on `target`; `scale` for pulses and path hits. Returns the damage dealt.
static func hit(user: Creature, target: Combatant, m: Dictionary, dir: Vector2, scale: float = 1.0) -> float:
	if target == null or not is_instance_valid(target) or target.untouchable():
		return 0.0
	var el: String = move_element(user, m)
	var mult: float = TamerData.element_mult(el, target.element_id()) if target.element_id() != "" else 1.0
	var crit: bool = user.critical()
	var dmg: float = float(m["damage"]) * user.power() * mult * scale * user.outgoing_mult(target) * randf_range(1.0 - SPREAD, 1.0 + SPREAD)
	if crit:
		dmg *= user.focus_crit
	dmg = maxf(1.0, roundf(dmg))
	var share: float = dmg / maxf(target.max_life_value(), 1.0)
	target.receive_hit(dmg, dir, float(m.get("knock", 6.0)), float(m.get("stun", 0.0)), user)
	_feedback(target, dmg, share, el, dir, bool(m.get("bond", false)) or crit)
	if target.element_id() != "":
		_matchup_word(target, TamerData.matchup(el, target.element_id()))
	if user.side == Combatant.SIDE_TEAM and user.rec != null:
		user.rec.add_bond(float(TamerData.rule("bond.per_hit")))
	return dmg


static func _feedback(target: Combatant, dmg: float, share: float, el: String, dir: Vector2, bond: bool) -> void:
	var trainer: bool = target.element_id() == ""
	FloatText.hit(target, dmg, bond, false, TRAINER_HIT if trainer else TamerData.color(el, "light"))
	var at: Vector2 = target.global_position + Vector2(0, -target.hit_radius() * 1.2)
	var killed: bool = not target.alive()
	Impact.hit(at, dir, share * (1.5 if bond else 1.0), TamerData.color(el), bond, killed, TamerData.sparks(el))
	Audio.sfx("impact", -6.0 + 4.0 * minf(share * 3.0, 1.0), randf_range(0.9, 1.15))
	Audio.sfx("hurt" if trainer else "hurt_beast", -10.0, randf_range(0.95, 1.2))


static func _matchup_word(target: Combatant, matchup: int) -> void:
	if matchup == TamerData.NEUTRAL:
		return
	var id: int = target.get_instance_id()
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_last_word.get(id, -10.0)) < WORD_GAP:
		return
	_last_word[id] = now
	if matchup == TamerData.SUPER:
		TamerFx.word(target.global_position, "Super effective!", Pal.c("gold"))
	else:
		TamerFx.word(target.global_position, "Resisted", Pal.c("pale"))
