extends Node
## --tamer-balance: every creature x arena x difficulty, fought headless by a bot (your side played by the AI at
## Normal) against the AI at that tier, both level 10, one creature each, at most FIGHT_TIME seconds. The opponent
## rotates through the other five species, so element matchups even out over a creature's twelve fights. Writes a
## table (win rate, average time, average life left) into TAMER_NOTES.md between the balance markers and flags
## outliers. Prints BALANCE DONE.

const LEVEL: int = 10
const FIGHT_TIME: float = 40.0
const BOT_TIER: String = "normal"
const TIERS: Array[String] = ["easy", "normal", "hard"]
const START := "<!-- balance:start -->"
const END := "<!-- balance:end -->"
const HIGH: float = 0.8                 ## a creature winning more than this at Normal is an outlier
const LOW: float = 0.2
const SLOW: float = 30.0                ## an arena whose fights average longer than this is an outlier

var g: TamerGame
var rows: Array = []                    ## [species, arena, tier, result, time, life left]


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


func _run() -> void:
	if get_tree().current_scene == null or not get_tree().current_scene is TamerGame:
		get_tree().change_scene_to_file("res://scenes/tamer.tscn")
	await _frames(20)
	g = TamerGame.current
	await _until(func() -> bool: return not g.transition.busy, 5.0)
	var kinds: Array = TamerData.species_all["species"].keys()
	var arenas: Array = TamerData.arenas["arenas"].keys()
	for i: int in kinds.size():
		for a: int in arenas.size():
			for t: int in TIERS.size():
				var other: int = (i + 1 + (a * TIERS.size() + t) % (kinds.size() - 1)) % kinds.size()
				await _fight(String(kinds[i]), String(kinds[other]), String(arenas[a]), TIERS[t])
	_write()
	print("BALANCE DONE (%d fights)" % rows.size())
	get_tree().quit(0)


## One fight: your `kind` (played by the bot) against a wild `foe_kind` at `tier`.
func _fight(kind: String, foe_kind: String, arena: String, tier: String) -> void:
	g.hud.station.choose([kind], LEVEL)
	g.team.rest()
	var rec := CreatureRecord.make(foe_kind, LEVEL, true)
	g.battle.start_wild(rec, arena, tier)
	await _until(func() -> bool: return g.battle.foe != null and not g.transition.busy, 5.0)
	var foe: Creature = g.battle.foe
	foe.catchable = false                                   # a fight to the end: no weakened stop
	g.field.partner.brain = FoeBrain.new(g.field.partner, BOT_TIER)
	var t: float = await _until(func() -> bool: return not g.battle.on or not is_instance_valid(foe) or foe.fainted_now, FIGHT_TIME)
	var won: bool = not is_instance_valid(foe) or foe.fainted_now
	var lost: bool = not won and not g.battle.on
	var life: float = g.team.members[0].life_frac() if not lost else 0.0
	rows.append([kind, arena, tier, "win" if won else ("loss" if lost else "draw"), t, life])
	print("BALANCE %s vs %s, %s, %s: %s in %.0f s, %d%% life left" % [kind, foe_kind, arena, tier, rows[-1][3], t, roundi(life * 100.0)])
	if g.battle.on:
		g.battle.end(won)
	await _until(func() -> bool: return not g.battle.on and not g.transition.busy and g.battle.arena == null, 5.0)
	await _frames(3)


func _stats(filter: Callable) -> Array:
	var n: int = 0
	var wins: int = 0
	var time: float = 0.0
	var life: float = 0.0
	for r: Array in rows:
		if filter.call(r):
			n += 1
			wins += 1 if r[3] == "win" else 0
			time += float(r[4])
			life += float(r[5])
	return [n, float(wins) / maxf(n, 1), time / maxf(n, 1), life / maxf(n, 1)]


func _cell(st: Array) -> String:
	return "%d%% / %.0f s / %d%%" % [roundi(float(st[1]) * 100.0), float(st[2]), roundi(float(st[3]) * 100.0)]


func _write() -> void:
	var out: PackedStringArray = [START, "", "Bot (your side, AI at Normal) vs the AI at each tier, level %d, 1v1, %d s cap, every arena, opponents rotating through the other species." % [LEVEL, int(FIGHT_TIME)],
		"Cells: win rate / average time / average life left.", "", "| Creature | Easy | Normal | Hard |", "|---|---|---|---|"]
	var flags: PackedStringArray = []
	for kind: String in TamerData.species_all["species"]:
		var cells: PackedStringArray = []
		for tier: String in TIERS:
			cells.append(_cell(_stats(func(r: Array) -> bool: return r[0] == kind and r[2] == tier)))
		out.append("| %s | %s |" % [TamerData.species(kind)["name"], " | ".join(cells)])
		var normal: Array = _stats(func(r: Array) -> bool: return r[0] == kind and r[2] == "normal")
		if float(normal[1]) > HIGH or float(normal[1]) < LOW:
			flags.append("%s wins %d%% at Normal" % [TamerData.species(kind)["name"], roundi(float(normal[1]) * 100.0)])
	out.append_array(["", "| Arena | Easy | Normal | Hard |", "|---|---|---|---|"])
	for arena: String in TamerData.arenas["arenas"]:
		var cells: PackedStringArray = []
		for tier: String in TIERS:
			cells.append(_cell(_stats(func(r: Array) -> bool: return r[1] == arena and r[2] == tier)))
		out.append("| %s | %s |" % [arena.capitalize(), " | ".join(cells)])
		var all: Array = _stats(func(r: Array) -> bool: return r[1] == arena)
		if float(all[2]) > SLOW:
			flags.append("%s fights average %.0f s" % [arena.capitalize(), float(all[2])])
	out.append("")
	out.append("Outliers: " + ("none" if flags.is_empty() else "; ".join(flags)) + ".")
	out.append_array(["", END])
	var path: String = ProjectSettings.globalize_path("res://") + "../TAMER_NOTES.md"
	var text: String = FileAccess.get_file_as_string(path)
	var a: int = text.find(START)
	var b: int = text.find(END)
	text = (text.substr(0, a) + "\n".join(out) + text.substr(b + END.length())) if a >= 0 and b > a else text + "\n## Balance (tools: --tamer-balance)\n" + "\n".join(out) + "\n"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	print("\n".join(out))
