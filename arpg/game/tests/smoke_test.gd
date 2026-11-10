extends Node
## Headless smoke test (autoload "SmokeTest", dormant unless --smoke): loads the zone and checks the core loop:
## demons spawn, a strike kills, loot drops and is picked up, equipping changes stats, skills run, points spend,
## a prayer is answered, and nothing errors.

var _fails: PackedStringArray = []


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--smoke"):
		_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	if ok:
		print("SMOKE ok: ", what)
	else:
		_fails.append(what)


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _run() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
	await _frames(30)
	var g := get_tree().current_scene as Game
	var m: Michael = g.michael
	_expect(get_tree().get_nodes_in_group("demons").size() >= 15, "packs spawned (%d demons)" % get_tree().get_nodes_in_group("demons").size())
	var d: Demon = g.spawner.spawn("swarmer", m.global_position + Vector2(30, 0))
	await _frames(2)
	var xp0: float = m.prog.xp
	for i: int in 8:
		if not is_instance_valid(d) or d.dead:
			break
		m.strike(d.global_position)
		await _frames(30)
	_expect(d == null or not is_instance_valid(d) or d.dead, "sword strikes slay an imp")
	_expect(m.prog.xp > xp0 or m.prog.level > 1, "experience gained")
	var item: Dictionary = LootGen.make(5, 1.0, "rare")
	_expect(item["stats"].size() >= 4 and item["name"] != "", "rare item rolled: " + String(item["name"]))
	GroundItem.spawn(g.world, m.global_position + Vector2(4, 0), item)
	await _frames(5)
	_expect(m.inv.bag.has(item), "walking over an item picks it up")
	var life0: float = m.stats.v("life")
	var armour0: float = m.stats.v("armour")
	m.inv.equip(m.inv.bag.find(item))
	_expect(m.inv.equipped.has(m.inv.target_slot(item)) or m.inv.equipped.values().has(item), "equipped " + String(item["slot"]))
	_expect(m.stats.v("life") != life0 or m.stats.v("armour") != armour0 or item["slot"] in ["sword", "ring", "amulet", "feet", "shield"],
		"equipping changes the numbers")
	m.prog.add_xp(2000.0)
	_expect(m.prog.level > 3 and m.prog.skill_points() > 0, "levels and skill points (level %d)" % m.prog.level)
	while m.prog.mastery < 8 and m.prog.add_mastery():
		pass
	for s: String in ["rebuke", "shield", "trumpet", "radiance"]:
		m.prog.add_rank(s)
	_expect(m.prog.tier_open(2) and m.prog.rank("trumpet") == 1, "mastery opens the tiers")
	var used: int = 0
	for s: String in ["rebuke", "shield", "trumpet", "descent", "radiance"]:
		m.glory = m.stats.v("glory")
		await _frames(25)
		if m.skills.use(s, m.global_position + Vector2(60, 0)):
			used += 1
	_expect(used == 5, "all five skills used (%d)" % used)
	var stars0: int = m.prog.star_points()
	_expect(m.prog.take_star("vigil") and m.prog.star_points() == stars0 - 1, "a star is taken")
	var p: Dictionary = g.objective.points[0]
	m.position = p["at"]
	await _frames(10)
	_expect(int(p["state"]) == PrayerObjective.STATE_DEFENDING, "reaching a prayer brings a wave")
	for w: Variant in p["wave"]:
		if is_instance_valid(w):
			(w as Demon).hurt(99999.0, m.global_position, 0.0, false)
	await _frames(10)
	_expect(int(p["state"]) == PrayerObjective.STATE_ANSWERED and m.prog.bonus_stars == 1, "the prayer is answered (+1 star)")
	if _fails.is_empty():
		print("SMOKE PASS")
		get_tree().quit(0)
	else:
		for f: String in _fails:
			print("SMOKE FAIL: ", f)
		get_tree().quit(1)
