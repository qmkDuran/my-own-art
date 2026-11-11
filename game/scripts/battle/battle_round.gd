class_name BattleRound
extends RefCounted
## One round of battle: your action (a move, a gentle act, an item, a swap or running), then the other side's,
## faster creature first for moves. Moves and gentle acts go through the timing ring. Handles fainting,
## experience, the next trainer creature, and a wild creature choosing to join.

var b: BattleScene
var moves: MoveRunner


func _init(scene: BattleScene) -> void:
	b = scene
	moves = MoveRunner.new(scene)


func play(action: Dictionary) -> void:
	match String(action["type"]):
		"run":
			await _run_away()
		"switch":
			await swap_to(int(action["index"]))
			await foe_turn()
		"item":
			await _use_item(String(action["item"]))
			await foe_turn()
		"gentle":
			await _gentle(String(action["how"]), String(action.get("item", "")))
			await foe_turn()
		"move":
			await _trade_moves(String(action["move"]))
	await _end_of_round()


func over() -> bool:
	return not b.result.is_empty()


func _trade_moves(move_id: String) -> void:
	if BattleRules.player_first(b.ally, b.foe):
		await _ally_move(move_id)
		await foe_turn()
	else:
		await foe_turn()
		if not over() and not b.ally.creature.is_fainted():
			await _ally_move(move_id)


func _ally_move(move_id: String) -> void:
	await moves.use(b.ally, b.foe, move_id, true)
	if b.foe.creature.is_fainted():
		await _foe_down()


func foe_turn() -> void:
	if over() or b.foe.creature.is_fainted():
		return
	var act: Dictionary = FoeAi.choose(b.foe, b.ally, Game.rng)
	match String(act["type"]):
		"watch":
			await b.messages.say("%s watches you curiously." % b.foe.creature.display_name())
		"doze":
			await b.messages.say("%s nods off for a moment..." % b.foe.creature.display_name())
		_:
			await moves.use(b.foe, b.ally, String(act["move"]), false)
			if b.ally.creature.is_fainted():
				await _ally_down()


func _end_of_round() -> void:
	if over():
		return
	if b.is_wild():
		b.foe.mood = TrustRules.roll_mood(b.foe.creature.species_id, Game.rng)
		b.foe_card.update_trust()
	b.messages.show_now("What will %s do?" % b.ally.creature.display_name())


func _run_away() -> void:
	await b.messages.say("You back away quietly. The wildkin watches you go.")
	b.result = {"outcome": "run"}


func _use_item(id: String) -> void:
	Game.bag.take(id)
	var healed: int = b.ally.creature.heal(int(Db.item(id)["amount"]))
	Audio.sfx("heal")
	b.view.sparkle(true)
	await b.messages.say("You used a %s. %s recovered %d HP." % [Db.item(id)["name"], b.ally.creature.display_name(), healed])
	await b.ally_card.update_hp()


func swap_to(index: int) -> void:
	await b.messages.say("Come back, %s!" % b.ally.creature.display_name())
	await b.view.withdraw(true)
	await b.send_ally(Game.party[index])


## Calm, play or a treat: the timing ring, then Trust grows by how well it matched the creature's mood.
func _gentle(how: String, treat: String) -> void:
	var name: String = b.foe.creature.display_name()
	var lines: Dictionary = {"calm": "You speak softly to %s..." % name, "play": "You wiggle your fingers and play with %s!" % name,
		"treat": "You hold out a %s..." % (Db.item(treat)["name"] if treat != "" else "")}
	await b.messages.say(String(lines[how]))
	if treat != "":
		Game.bag.take(treat)
	var grade: String = await b.ring.run(BattleLayout.ring_point(false), "gentle")
	var gain: int = TrustRules.gain(how, b.foe.mood, b.foe.creature.species_id, grade, treat)
	TrustRules.add(b.foe, gain)
	b.foe_card.update_trust()
	b.view.sparkle(false, true)
	Audio.sfx("trust")
	await b.messages.say(_reaction(how, treat, gain))
	if TrustRules.is_won(b.foe):
		await _join()


func _reaction(how: String, treat: String, gain: int) -> String:
	var name: String = b.foe.creature.display_name()
	if treat != "" and TrustRules.likes(b.foe.creature.species_id, treat):
		return "%s gobbles it up happily! It loves those." % name
	if gain >= TrustRules.MATCH_GAIN:
		return "%s loved that! Its trust in you grows." % name
	if b.foe.mood == "sleepy":
		return "%s is too drowsy to notice much." % name
	return "%s seems a little unsure... but it's warming up." % name


func _join() -> void:
	var c: Creature = b.foe.creature
	Audio.sfx("befriend")
	await b.view.hop(false)
	await b.messages.say("%s trusts you completely. It wants to come with you!" % c.display_name())
	Game.befriend(c)
	await _award_xp(Growth.befriend_reward(c))
	b.result = {"outcome": "befriended", "creature": c}


func _foe_down() -> void:
	await b.view.faint(false)
	var c: Creature = b.foe.creature
	if b.is_wild():
		await b.messages.say("%s is worn out and scurries off into the grass." % c.display_name())
	else:
		await b.messages.say("%s's %s is worn out!" % [b.trainer_name(), c.display_name()])
	await _award_xp(Growth.reward(c, not b.is_wild()))
	if b.is_wild() or not b.next_foe():
		b.result = {"outcome": "win"}
		return
	await b.send_foe()


func _award_xp(amount: int) -> void:
	var c: Creature = b.ally.creature
	await b.messages.say("%s gained %d experience." % [c.display_name(), amount])
	var notes: PackedStringArray = Growth.add_xp(c, amount)
	await b.ally_card.update_xp()
	b.ally_card.show_battler(b.ally)
	for n: String in notes:
		Audio.sfx("level")
		await b.messages.say(n)


func _ally_down() -> void:
	await b.view.faint(true)
	await b.messages.say("%s is worn out!" % b.ally.creature.display_name())
	if Game.able_count() == 0:
		await b.messages.say("You have no friends left who can battle...")
		b.result = {"outcome": "lose"}
		return
	var pick: Dictionary = await b.menus.pick_forced_switch()
	await b.send_ally(Game.party[int(pick["index"])])
