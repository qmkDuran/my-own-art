extends Node
## Balance bot: plays the slice's battles with a human-like mix of timing presses for each starter and a few
## seeds. It befriends species it has not met (choosing the gentle act that suits the mood, treats it likes),
## fights the rest, heals when low, then takes on both trainers and the grove. Prints a summary table.

const SEEDS: Array[int] = [1, 2, 3]
const STARTERS: Array[String] = ["mossfawn", "emberkit", "ripplet"]
const LANE_FIGHTS: int = 10
const GROVE_FIGHTS: int = 8
const LOW_HP: float = 0.35

var _world: Overworld
var _stats: Dictionary = {}


func _ready() -> void:
	Game.fast = true
	TimingRing.autopilot = TimingRing.MIXED
	await get_tree().process_frame
	for starter: String in STARTERS:
		for s: int in SEEDS:
			await _run(starter, s)
	print("BALANCE done")
	get_tree().quit()


func _run(starter: String, seed_value: int) -> void:
	Game.rng.seed = seed_value
	Game.new_game()
	Game.choose_starter(starter)
	Game.flags["met_gran"] = true
	_world = TestRunner.main().start_overworld()
	_stats = {"befriend_rounds": [], "befriended": 0, "fled": 0, "losses": 0, "trainers": 0, "evolved": ""}
	await _wild_series("bramble_lane", LANE_FIGHTS)
	for t: String in ["juni", "lio"]:
		_heal_up()
		var r: Dictionary = await _world.battles.trainer_battle(t)
		_stats["trainers"] += int(r.get("outcome", "") == "win")
	await _wild_series("wellspring_grove", GROVE_FIGHTS)
	_report(starter, seed_value)


func _wild_series(map: String, count: int) -> void:
	var enc: Dictionary = MapGrid.load_map(map).encounters
	for i: int in count:
		_heal_up()
		var foe: Creature = _world.battles.roll_wild(enc)
		var befriend: bool = Game.journal.status(foe.species_id) != "befriended"
		var rounds: Array[int] = [0]
		var hook: Callable = func() -> void:
			while _world.battles.current == null:
				await get_tree().process_frame
			_world.battles.current.menus.chooser = func(b: BattleScene) -> Dictionary:
				rounds[0] += 1
				return _decide(b, befriend)
		hook.call()
		var r: Dictionary = await _world.battles.wild_battle(foe)
		_tally(r, rounds[0])


func _tally(r: Dictionary, rounds: int) -> void:
	match String(r.get("outcome", "")):
		"befriended":
			_stats["befriended"] += 1
			_stats["befriend_rounds"].append(rounds)
		"lose":
			_stats["losses"] += 1


func _decide(b: BattleScene, befriend: bool) -> Dictionary:
	var me: Creature = b.ally.creature
	if b.ally.hp_ratio() < LOW_HP and Game.bag.count("mending_salve") > 0:
		return {"type": "item", "item": "mending_salve"}
	if befriend and b.is_wild():
		return _gentle(b)
	return {"type": "move", "move": _best_move(me, b.foe.creature)}


func _gentle(b: BattleScene) -> Dictionary:
	var liked: Array = b.foe.creature.data()["likes"]
	match b.foe.mood:
		"hungry":
			for t: String in liked:
				if Game.bag.count(t) > 0:
					return {"type": "gentle", "how": "treat", "item": t}
			return {"type": "gentle", "how": "calm"}
		"playful":
			return {"type": "gentle", "how": "play"}
	return {"type": "gentle", "how": "calm"}


func _best_move(me: Creature, foe: Creature) -> String:
	var best: String = me.moves[0]
	var score: float = -1.0
	for m: String in me.moves:
		var d: Dictionary = Db.move(m)
		if d["kind"] != "attack":
			continue
		var s: float = float(d["power"]) * BattleRules.element_mult(String(d["element"]), foe)
		if s > score:
			score = s
			best = m
	return best


func _heal_up() -> void:
	for c: Creature in Game.party:
		c.heal_full()


func _report(starter: String, seed_value: int) -> void:
	var rounds: Array = _stats["befriend_rounds"]
	var avg: float = 0.0 if rounds.is_empty() else float(rounds.reduce(func(a: int, x: int) -> int: return a + x, 0)) / rounds.size()
	var lead: Creature = Game.party[0]
	print("BALANCE %-9s seed %d | friends %d (avg %.1f rounds) | losses %d | trainers won %d/2 | lead %s Lv%d bond %d | heal stage %d" % [
		starter, seed_value, _stats["befriended"], avg, _stats["losses"], _stats["trainers"], lead.display_name(),
		lead.level, lead.bond, Game.heal_stage])
