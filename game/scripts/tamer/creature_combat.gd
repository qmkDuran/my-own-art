class_name CreatureCombat
extends RefCounted
## Damage between creatures: the move's damage x the user's power x the element advantage (x1.3 when its element is
## strong against the target's, never a penalty) x buffs and debuffs x the ground (home terrain, high ground), those
## three together capped at +40% (tamer.json "combat.bonus_cap"), x the combo step x a staggered target's weakness x
## a little spread. Physical hits fill the gauge (yours, or the
## opponent's own); every hit fills the target's stagger bar (an advantage fills it faster). Then the weight of the
## hit: Lanternfall's impact, hit-stop and shake in the element's colours, the number, and "Strong hit!".

const SPREAD: float = 0.1
const LOW_LIFE: float = 0.25           ## your creature this hurt: the trainer calls out
const WORD_GAP: float = 0.6             ## one advantage word per target this often, so a flurry is not a wall of text

static var _last_word: Dictionary = {}


static func move_element(user: Creature, m: Dictionary) -> String:
	return String(m.get("element", user.element_id()))


## One hit of move `m` from `user` on `target`; `scale` for pulses and path hits. Returns the damage dealt.
static func hit(user: Creature, target: Combatant, m: Dictionary, dir: Vector2, scale: float = 1.0) -> float:
	var tc := target as Creature
	if tc == null or not is_instance_valid(tc) or tc.untouchable():
		return 0.0
	var el: String = move_element(user, m)
	var advantage: bool = TamerData.advantage(el, tc.element_id())
	var dmg: float = float(m["damage"]) * user.power() * scale * _mults(user, tc, m, advantage) * randf_range(1.0 - SPREAD, 1.0 + SPREAD)
	dmg = maxf(1.0, roundf(dmg * tc.effects.on_hit()))
	var share: float = dmg / maxf(tc.max_life_value(), 1.0)
	tc.receive_hit(dmg, dir, float(m.get("knock", 6.0)), float(m.get("stun", 0.0)), user)
	_feedback(tc, dmg, share, el, dir, bool(m.get("signature", false)))
	if advantage:
		_strong_word(tc)
	var was_staggered: bool = tc.stagger.is_staggered()
	_gauge_and_stagger(user, tc, m, dmg, advantage)
	if tc.stagger.is_staggered() and not was_staggered and user.side == Combatant.SIDE_TEAM:
		TamerGame.current.guide.done("stagger")
		TrainerShout.moment("staggered")
	if tc.side == Combatant.SIDE_TEAM and tc.alive() and tc.rec.life_frac() < LOW_LIFE:
		TrainerShout.moment("low")
	return dmg


## Element, ground and buffs together add at most the bonus cap (penalties are never capped); then the combo step
## and a staggered target's weakness.
static func _mults(user: Creature, tc: Creature, m: Dictionary, advantage: bool) -> float:
	var k: float = bonus(user, tc, advantage)
	if user.is_basic_move(m):
		k *= user.combo_scale
	return k * tc.stagger.damage_taken()


static func bonus(user: Creature, tc: Creature, advantage: bool) -> float:
	var k: float = float(TamerData.elements["advantage_mult"]) if advantage else 1.0
	k *= user.effects.mult("dealt") * TerrainRules.dealt_mult(user)
	k *= tc.effects.mult("taken") * TerrainRules.taken_mult(tc)
	return minf(k, 1.0 + float(TamerData.rule("combat.bonus_cap")))


## Physical hits fill the hitter's gauge (more on a staggered target); every hit fills the target's stagger bar.
static func _gauge_and_stagger(user: Creature, tc: Creature, m: Dictionary, dmg: float, advantage: bool) -> void:
	var G: Dictionary = TamerData.rule("combat.gauge")
	if String(m.get("type", "physical")) == "physical":
		var fill: float = float(G["per_physical_hit"]) * (float(G["on_staggered_mult"]) if tc.stagger.is_staggered() else 1.0)
		if user.side == Combatant.SIDE_TEAM:
			TamerGame.current.team.add_gauge(fill)
		else:
			user.gauge = minf(float(G["segments"]), user.gauge + fill)
	var k: float = float(m.get("stagger", 1.0))
	if advantage:
		k *= float(TamerData.rule("combat.stagger.advantage_mult"))
	tc.stagger.add(dmg * k)


static func _feedback(target: Creature, dmg: float, share: float, el: String, dir: Vector2, big: bool) -> void:
	FloatText.hit(target, dmg, big, false, TamerData.color(el, "light"))
	var at: Vector2 = target.global_position + Vector2(0, -target.hit_radius() * 1.2)
	Impact.hit(at, dir, share * (1.5 if big else 1.0), TamerData.color(el), big, not target.alive(), TamerData.sparks(el))
	Audio.sfx("impact", -6.0 + 4.0 * minf(share * 3.0, 1.0), randf_range(0.9, 1.15))
	Audio.sfx("hurt_beast", -10.0, randf_range(0.95, 1.2))


static func _strong_word(target: Creature) -> void:
	var id: int = target.get_instance_id()
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_last_word.get(id, -10.0)) < WORD_GAP:
		return
	_last_word[id] = now
	TamerFx.word(target.global_position, "Strong hit!", Pal.c("gold"))


## A creature swapped in (or stepping in after a knock-out) strikes as it lands: yours or the opponent's alike.
static func entry(c: Creature) -> void:
	var E: Dictionary = TamerData.rule("entry")
	var m: Dictionary = {"name": "Entry", "type": "special", "damage": float(E["damage"]), "stun": float(E["stun"]), "knock": 14.0,
		"stagger": float(TamerData.rule("combat.stagger.entry")) / float(E["damage"])}
	TamerFx.blast(c.global_position, float(E["radius"]), c.element_id(), true)
	TamerFx.word(c.global_position, "Go, %s!" % c.rec.display_name(), TamerData.color(c.element_id(), "light"), UiDraw.TITLE)
	Audio.sfx("slam", -6.0, 1.1)
	for f: Combatant in MoveKind.foes_in(c, c.global_position, float(E["radius"])):
		hit(c, f, m, (f.global_position - c.global_position).normalized())
