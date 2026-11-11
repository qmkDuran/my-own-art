extends Node
## Headless play of the core loop: new game and starter, walking, a wild battle with timing presses,
## befriending (Trust), a trainer win, the map healing, a bond form, buying, and save/load.

var _fails: PackedStringArray = []
var _world: Overworld


func _ready() -> void:
	Game.fast = true
	Game.rng.seed = 7
	TimingRing.autopilot = "perfect"
	await get_tree().process_frame
	await _run_all()
	print("SMOKE %s%s" % ["PASS" if _fails.is_empty() else "FAIL: ", ", ".join(_fails)])
	get_tree().quit(0 if _fails.is_empty() else 1)


func check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("SMOKE FAIL: ", what)


func _run_all() -> void:
	for step: String in ["_new_game", "_walk", "_timing_maths", "_wild_battle_with_timing", "_befriend",
			"_trainer_win", "_map_heals", "_bond_form", "_shop", "_save_and_load"]:
		print("SMOKE step ", step)
		await call(step)


func _new_game() -> void:
	Game.new_game()
	Game.choose_starter("mossfawn")
	check(Game.party.size() == 1 and Game.party[0].species_id == "mossfawn", "starter chosen")
	_world = TestRunner.main().start_overworld()
	check(_world.map.id == "fernhollow", "overworld starts in Fernhollow")


func _walk() -> void:
	var start: Vector2i = _world.player.cell
	await _world.try_step(Vector2i.DOWN)
	check(_world.player.cell == start + Vector2i.DOWN, "player walks a step")
	await _world.try_step(Vector2i.UP)


func _timing_maths() -> void:
	var a := Battler.of(Creature.create("emberkit", 5))
	var d := Battler.of(Creature.create("mossfawn", 5))
	var plain: int = BattleRules.damage(a, d, "ember_nip", BattleRules.timing_mult("miss", "miss"), 1.0)
	var perfect: int = BattleRules.damage(a, d, "ember_nip", BattleRules.timing_mult("perfect", "miss"), 1.0)
	var braced: int = BattleRules.damage(a, d, "ember_nip", BattleRules.timing_mult("miss", "perfect"), 1.0)
	check(perfect > plain and braced < plain, "timing: perfect strike hits harder, a perfect brace takes less")
	check(Db.element_mult("cinder", "bloom") > 1.0 and Db.element_mult("bloom", "cinder") < 1.0, "element chart")
	StatusRules.apply(d, "singed")
	check(StatusRules.chip(d) > 0 and d.status_turns == 3, "singed chips HP for three rounds")
	for i: int in 3:
		StatusRules.tick(d)
	check(d.status == "", "conditions wear off")
	check(TimingRing.grade_for(TimingRing.TARGET_R) == "perfect" and TimingRing.grade_for(0.0) == "miss", "ring grades")


func _wild_battle_with_timing() -> void:
	var foe := Creature.create("cobblemole", 3)
	var xp_before: int = Game.party[0].xp + Game.party[0].level * 1000
	var result: Dictionary = await _battle_with(foe, [{"type": "move", "move": "leafdart"}])
	check(result.get("outcome", "") == "win", "wild battle won with perfect presses (got %s)" % result.get("outcome", ""))
	check(Game.party[0].xp + Game.party[0].level * 1000 > xp_before, "experience gained")
	check(Game.journal.status("cobblemole") == "seen", "journal saw the wild creature")


## Starts a wild battle and keeps queueing the same actions until it ends.
func _battle_with(foe: Creature, actions: Array[Dictionary]) -> Dictionary:
	var call: Callable = func() -> Dictionary: return await _world.battles.wild_battle(foe)
	return await _drive(call, actions)


func _drive(start: Callable, actions: Array[Dictionary]) -> Dictionary:
	var feeder := func() -> void:
		while _world.battles.current == null:
			await get_tree().process_frame
		var scene: BattleScene = _world.battles.current
		while is_instance_valid(scene) and scene.result.is_empty():
			if scene.menus != null and scene.menus.queued.size() < 2:
				scene.menus.queued.append_array(actions)
			await get_tree().process_frame
	feeder.call()
	return await start.call()


func _befriend() -> void:
	Game.party[0].heal_full()
	var foe := Creature.create("thistlehog", 4)
	var gentle: Array[Dictionary] = [{"type": "gentle", "how": "calm"}, {"type": "gentle", "how": "treat", "item": "sunberry"}]
	Game.bag.add("sunberry", 10)
	var result: Dictionary = await _battle_with(foe, gentle)
	check(result.get("outcome", "") == "befriended", "wild creature befriended through Trust (got %s)" % result.get("outcome", ""))
	check(Game.party.size() == 2 and Game.journal.status("thistlehog") == "befriended", "new friend joined the team")
	check(Game.heal_stage == 1, "first friend heals the Vale to stage 1 (stage %d)" % Game.heal_stage)


func _trainer_win() -> void:
	for c: Creature in Game.party:
		Growth.add_xp(c, 400)
		c.heal_full()
	var call: Callable = func() -> Dictionary: return await _world.battles.trainer_battle("juni")
	var result: Dictionary = await _drive(call, [{"type": "move", "move": "leafdart"}])
	check(result.get("outcome", "") == "win", "trainer battle won (got %s)" % result.get("outcome", ""))


func _map_heals() -> void:
	var garden := Vector2i(9, 3)
	_world.load_map("fernhollow", Vector2i(13, 8), Vector2i.DOWN)
	var withered: Image = TerrainPainter.new().bake(_world.map, 0).get_image()
	var healed: Image = _world.terrain.texture.get_image()
	var px := Vector2i(garden.x * 16 + 8, garden.y * 16 + 8)
	check(withered.get_pixelv(px) != healed.get_pixelv(px), "Gran's garden looks different once healed")
	_world.load_map("wellspring_grove", Vector2i(11, 12), Vector2i.UP)
	check(not _world.map.walkable(Vector2i(11, 8), Game.heal_stage), "brambles block the Wellspring before stage 2")
	check(_world.map.walkable(Vector2i(11, 8), 2), "brambles give way at stage 2")


func _bond_form() -> void:
	var c: Creature = Game.party[0]
	c.bond = 60
	c.level = maxi(c.level, 7)
	check(Bond.evolution_target(c) == "grovehart", "Mossfawn is ready for its bond form")
	Bond.evolve(c, "grovehart")
	check(c.species_id == "grovehart" and c.hp > 0, "bond form applied")


func _shop() -> void:
	Game.coins = 100
	var before: int = Game.bag.count("spring_tonic")
	check(ShopPanel.buy("spring_tonic") and Game.bag.count("spring_tonic") == before + 1, "bought a tonic")


func _save_and_load() -> void:
	SaveSystem.save()
	var party: int = Game.party.size()
	var stage: int = Game.heal_stage
	Game.new_game()
	check(SaveSystem.load_game(), "save file loads")
	check(Game.party.size() == party and Game.heal_stage == stage and Game.party[0].species_id == "grovehart",
		"save keeps team, heal stage and bond form")
