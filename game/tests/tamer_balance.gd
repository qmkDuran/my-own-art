extends Node
## --tamer-balance: headless fights for tuning. Your creature is played by the AI at Normal (the bot) against a wild
## opponent at a tier, both level 10, one creature each, at most FIGHT_TIME seconds. Every ordered pair of the six
## species fights in every arena at every tier in --tiers (default normal,hard). --shard=K/N runs every Nth fight
## (tools/tamer_balance.sh runs shards in parallel and tools/balance_report.py turns the rows into tables);
## --kinds=a,b plays only those species on your side; --rounds=N plays every fight N times. Prints
## one "BALANCE_ROW {json}" line per fight, then BALANCE DONE.

const LEVEL: int = 10
const FIGHT_TIME: float = 40.0
const BOT_TIER: String = "normal"

var g: TamerGame


func _ready() -> void:
	Engine.physics_ticks_per_second = 30
	_run.call_deferred()


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _until(cond: Callable, limit: float) -> float:
	var t: float = 0.0
	while t < limit and not cond.call():
		await get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	return t


func _arg(name: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
	return fallback


## Every fight this shard plays: [your kind, foe kind, arena, tier].
func _plan() -> Array:
	var shard: PackedStringArray = _arg("shard", "0/1").split("/")
	var k: int = int(shard[0])
	var n: int = int(shard[1])
	var out: Array = []
	var i: int = 0
	var only: String = _arg("kinds", "")
	for tier: String in _arg("tiers", "normal,hard").split(","):
		for arena: String in TamerData.arenas["arenas"]:
			for a: String in TamerData.species_all["species"]:
				for b: String in TamerData.species_all["species"]:
					if a != b and (only == "" or only.split(",").has(a)):
						for r: int in int(_arg("rounds", "1")):
							if i % n == k:
								out.append([a, b, arena, tier])
							i += 1
	return out


func _run() -> void:
	if get_tree().current_scene == null or not get_tree().current_scene is TamerGame:
		get_tree().change_scene_to_file("res://scenes/tamer.tscn")
	await _frames(20)
	g = TamerGame.current
	await _until(func() -> bool: return not g.transition.busy, 5.0)
	var plan: Array = _plan()
	for f: Array in plan:
		await _fight(String(f[0]), String(f[1]), String(f[2]), String(f[3]))
	print("BALANCE DONE (%d fights)" % plan.size())
	get_tree().quit(0)


func _fight(kind: String, foe_kind: String, arena: String, tier: String) -> void:
	g.hud.station.choose([kind], LEVEL)
	g.team.rest()
	g.battle.start_wild(CreatureRecord.make(foe_kind, LEVEL, true), arena, tier)
	await _until(func() -> bool: return g.battle.foe != null and not g.transition.busy, 5.0)
	var foe: Creature = g.battle.foe
	foe.catchable = false                                   # a fight to the end: no weakened stop
	g.field.partner.brain = FoeBrain.new(g.field.partner, BOT_TIER)
	var t: float = await _until(func() -> bool: return not g.battle.on or not is_instance_valid(foe) or foe.fainted_now, FIGHT_TIME)
	var won: bool = not is_instance_valid(foe) or foe.fainted_now
	var lost: bool = not won and not g.battle.on
	var row: Dictionary = {"you": kind, "foe": foe_kind, "arena": arena, "tier": tier, "time": snappedf(t, 0.1),
		"result": "win" if won else ("loss" if lost else "draw"),
		"you_life": snappedf(g.team.members[0].life_frac() if not lost else 0.0, 0.01),
		"foe_life": snappedf(0.0 if won else foe.rec.life_frac(), 0.01)}
	print("BALANCE_ROW " + JSON.stringify(row))
	if g.battle.on:
		g.battle.end(won)
	await _until(func() -> bool: return not g.battle.on and not g.transition.busy and g.battle.arena == null, 5.0)
	await _frames(3)
