class_name MoveRunner
extends RefCounted
## Carries out one move: attacks go through the timing ring (your press when you attack, your block when you
## are attacked), then damage, element match and Trust reactions; heals and stat changes need no press.

var b: BattleScene


func _init(scene: BattleScene) -> void:
	b = scene


func use(user: Battler, target: Battler, move_id: String, ally: bool) -> void:
	var move: Dictionary = Db.move(move_id)
	if StatusRules.skips_turn(user, Game.rng):
		await b.messages.say(StatusRules.line("drowsy", "tick", _who(user, ally)))
		return
	await b.messages.say("%s used %s!" % [_who(user, ally), move["name"]])
	if move["kind"] == "attack" and StatusRules.misses(user, Game.rng):
		await b.messages.say(StatusRules.line("rattled", "tick", _who(user, ally)))
		return
	match String(move["kind"]):
		"attack":
			await _attack(user, target, move_id, ally)
		"heal":
			await _heal(user, move_id, ally)
		"buff":
			await _shift(user, String(move["stat"]), 1, ally)
		"debuff":
			await _shift(target, String(move["stat"]), -1, not ally)


func _who(user: Battler, ally: bool) -> String:
	if ally:
		return user.creature.display_name()
	return ("Wild %s" if b.is_wild() else "Foe %s") % user.creature.display_name()


func _attack(user: Battler, target: Battler, move_id: String, ally: bool) -> void:
	b.view.lunge(ally)
	var grade: String = await b.ring.run(BattleLayout.ring_point(not ally), "attack" if ally else "defend")
	await b.view.play_fx(String(Db.move(move_id)["element"]), ally)
	var timing: float = BattleRules.timing_mult(grade if ally else "miss", "miss" if ally else grade)
	if ally and grade != "miss":
		Bond.gain(user.creature, grade)
	var amount: int = BattleRules.damage(user, target, move_id, timing, Game.rng.randf())
	var before: float = target.hp_ratio()
	target.creature.take(amount)
	Audio.sfx("hit_strong" if grade == "perfect" else "hit")
	b.view.float_text(not ally, str(amount), "sun" if grade == "perfect" else "cream")
	await b.view.hurt(not ally)
	await _card(not ally).update_hp()
	var match_line: String = BattleRules.match_text(BattleRules.element_mult(String(Db.move(move_id)["element"]), target.creature))
	if match_line != "":
		await b.messages.say(match_line)
	if target.wild:
		await _trust_after_hit(target, before)
	await _maybe_inflict(move_id, target, not ally)


func _maybe_inflict(move_id: String, target: Battler, target_ally: bool) -> void:
	var id: String = StatusRules.roll_inflict(move_id, target, Game.rng)
	if id == "":
		return
	StatusRules.apply(target, id)
	_card(target_ally).show_status()
	Audio.sfx("debuff")
	await b.messages.say(StatusRules.line(id, "inflict", _who(target, target_ally)))


func _trust_after_hit(target: Battler, before: float) -> void:
	var delta: int = TrustRules.on_hit(target, before)
	if delta == 0:
		return
	TrustRules.add(target, delta)
	b.foe_card.update_trust()
	var name: String = target.creature.display_name()
	if delta > 0:
		b.view.react("hearts")
		await b.messages.say("%s seems to respect your strength." % name)
	else:
		b.view.react("sweat")
		await b.messages.say("%s is frightened! Its trust in you falls." % name)


func _heal(user: Battler, move_id: String, ally: bool) -> void:
	var healed: int = user.creature.heal(BattleRules.heal_amount(user.creature, move_id))
	Audio.sfx("heal")
	b.view.sparkle(ally)
	b.view.float_text(ally, "+%d" % healed, "leaf5")
	await _card(ally).update_hp()


func _shift(who: Battler, stat: String, by: int, ally: bool) -> void:
	var stat_name: String = "Attack" if stat == "atk" else "Defense"
	var name: String = who.creature.display_name()
	if who.shift_stage(stat, by):
		Audio.sfx("buff" if by > 0 else "debuff")
		b.view.sparkle(ally)
		await b.messages.say("%s's %s %s!" % [name, stat_name, "rose" if by > 0 else "fell"])
	else:
		await b.messages.say("%s's %s won't go any %s." % [name, stat_name, "higher" if by > 0 else "lower"])


func _card(ally: bool) -> CreatureCard:
	return b.ally_card if ally else b.foe_card
