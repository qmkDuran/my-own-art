class_name SmokeMore
extends RefCounted
## The smoke test's later checks (pass 2-4 systems): loot filter and stash, Act 1 foes, Eclipse, Noon, the other
## skills, keystones, and the Ember Forge. Runs inside the smoke test (same game, same expect()).

var t: Node
var g: Game
var p: Player


func _init(runner: Node) -> void:
	t = runner
	g = runner.get("g")
	p = runner.get("p")


func expect(ok: bool, what: String) -> void:
	t.call("expect", ok, what)


func frames(n: int) -> void:
	for i: int in n:
		await t.get_tree().physics_frame


## Forged items may hold any count (a rare can be quenched to two), but every affix stays inside its tier.
func _forged_legal(it: Dictionary) -> bool:
	for a: Dictionary in it["affixes"]:
		var tr: Array = LootGen.affix_tier_range(String(a["id"]), int(a["tier"]))
		if float(a["value"]) < float(tr[0]) - 0.05 or float(a["value"]) > float(tr[1]) + 0.05 or int(a["tier"]) > Forge.MAX_TIER:
			return false
	return true


func filter_and_stash() -> void:
	LootFilter.toggle_rarity("normal")
	var plain: Dictionary = LootGen.make(3, "normal")
	expect(not LootFilter.shows(plain) and LootFilter.shows(LootGen.make(3, "rare")), "the loot filter hides plain items, keeps rares")
	LootFilter.toggle_rarity("normal")
	var it: Dictionary = LootGen.make(3, "magic")
	expect(g.ui.stash.store(it) and Session.stash.has(it), "an item goes into Fenn's lockers")


func act1_foes(h: ShotHelper) -> void:
	h.clear_near(100000.0)
	await frames(2)
	p.global_position = g.layout.free_spot_near(p.global_position, p.radius)
	await t.get_tree().create_timer(Player.INVULN_AFTER_RISE).timeout
	var life0: float = p.life
	var husk: Enemy = h.pack_near(["husk"], Vector2(30, 0))[0]
	await frames(2)
	Combat.hit_enemy(husk, 99999.0)
	await t.get_tree().create_timer(1.0).timeout
	expect(p.life < life0, "a Husk bursts when it falls and burns whoever stands too close")
	p.walk_to(p.global_position + Vector2(200, 0))
	var free_speed: float = p._follow_path().length()
	p.slow(0.5, 1.0)
	expect(p._follow_path().length() < free_speed * 0.6, "silk slows the Lamplighter")
	p.stop()
	var hz: HungerZone = HungerZone.make(g.world, p.global_position, 100.0)
	var lv: float = p.light.value
	await t.get_tree().create_timer(0.5).timeout
	expect(p.light.value < lv, "a hunger nest drinks the lantern's Light")
	hz.queue_free()
	var m: Enemy = g.spawner.spawn("matron", p.global_position + Vector2(200, 0), "boss", [], 12)
	m.wake()
	await t.get_tree().create_timer(6.0).timeout
	expect(is_instance_valid(m) and not m.dead, "the Moth Matron fights for six seconds without errors")
	m.queue_free()
	await later_bosses(h)
	await fourth_loaf()


func later_bosses(h: ShotHelper) -> void:
	var bw: Enemy = g.spawner.spawn("bellwright", p.global_position + Vector2(0, -160), "boss", [], 20)
	bw.wake()
	var rings: int = 0
	for k: int in 40:
		await t.get_tree().create_timer(0.1).timeout
		rings = maxi(rings, g.fx_layer.get_children().filter(func(n: Node) -> bool: return n is RingWave).size())
	expect(rings > 0, "the Bellwright tolls: rings roll out (%d)" % rings)
	bw.queue_free()
	var rep: Enemy = h.pack_near(["repeater"], Vector2(80, 0))[0]
	await frames(2)
	var home: Vector2 = rep.home
	rep.life = rep.max_life * 0.3
	rep.global_position += Vector2(60, 0)
	rep.rewind()
	expect(is_equal_approx(rep.life, rep.max_life) and rep.global_position == home, "the Tuesday loop puts the living back, whole")
	rep.queue_free()
	var mayor: Enemy = g.spawner.spawn("mayor", p.global_position + Vector2(200, 0), "boss", [], 26)
	mayor.wake()
	await t.get_tree().create_timer(6.0).timeout
	expect(is_instance_valid(mayor) and not mayor.dead, "the Mayor of Tuesday fights for six seconds without errors")
	mayor.queue_free()


## The Fourth Loaf: a side quest that only moves when the town's clocks strike; the loop breaks after the Mayor.
func fourth_loaf() -> void:
	var c: Campaign = Session.campaign
	var loop := TuesdayLoop.new()
	t.add_child(loop)
	loop.setup(g)
	c.start("fourth_loaf")
	loop.t = TuesdayLoop.LOOP
	await frames(2)
	expect(c.step_index("fourth_loaf") == 1, "Wren's quest waits for the clocks, then asks you to warn her")
	c.notify("talk", "wren")
	loop.t = TuesdayLoop.LOOP
	await frames(2)
	c.notify("talk", "wren")
	expect(c.is_done("fourth_loaf"), "after a second strike Wren remembers: The Fourth Loaf is done")
	c.rewards.clear()                                   # later checks count on the character's level staying put
	expect(loop.clock_text().begins_with("Tuesday"), "while the Mayor stands, it is always Tuesday")
	g.loop = loop
	loop.t = TuesdayLoop.LOOP * 0.9
	var late: String = String(Dialogue.pick("tibb", c, [])["lines"][0][1])
	loop.t = TuesdayLoop.LOOP * 0.1
	var early: String = String(Dialogue.pick("tibb", c, [])["lines"][0][1])
	expect(late != early and late.contains("six hundred"), "townsfolk talk by the hour: Tibb is nearly at 612 before four")
	var before: Dictionary = c.quests.get("one_tuesday", {}).duplicate()
	c.place("one_tuesday", 5)
	expect(loop.clock_text().begins_with("Wednesday"), "with the Mayor down the town reaches Wednesday")
	if before.is_empty():                               # leave the main story where the rest of the test expects it
		c.quests.erase("one_tuesday")
	else:
		c.quests["one_tuesday"] = before
	g.loop = null
	loop.queue_free()


func pass3(h: ShotHelper) -> void:
	h.clear_near(100000.0)
	h.level_up(12)
	expect(p.prog.skills.has("eclipse") and p.prog.skills.has("noon"), "Eclipse (level 6) and Noon (level 10) are learned")
	var foes: Array[Enemy] = h.pack_near(["gloam", "hound"], Vector2(50, 0))
	for f: Enemy in foes:
		f.max_life = 99999.0
		f.life = 99999.0
	await frames(3)
	expect(h.cast("eclipse", p.global_position), "Eclipse can be used")
	await frames(20)
	expect(foes.all(func(f: Enemy) -> bool: return f.shrouded), "during Eclipse every enemy is Shrouded, even in your light")
	expect(p.light.light_radius() < 120.0, "Eclipse shutters the lantern")
	expect(h.cast("noon", p.global_position), "Noon can be used")
	await frames(10)
	expect(foes.all(func(f: Enemy) -> bool: return f.life < 99999.0), "Noon burns every enemy on screen")
	for f: Enemy in foes:
		f.queue_free()
	await more_skills(h)
	keystones()


func more_skills(h: ShotHelper) -> void:
	h.level_up(12)
	p.prog.skills["cinder_rain"]["nodes"]["guided"] = 1             # cinders seek the one target (random spots may miss)
	for id: String in ["kindle", "tether", "glass_ward", "cinder_rain", "wick_trap", "lull"]:
		var foe: Enemy = h.pack_near(["hound"], Vector2(60, 0))[0]
		foe.max_life = 99999.0
		foe.life = 99999.0
		foe.stun_t = 3.0                                       # a still target: these tests are about the skill, not aim
		await frames(3)
		expect(h.cast(id, foe.global_position), "%s can be used" % id)
		if id == "kindle":
			h.cast("wickbolt", foe.global_position)
		await t.get_tree().create_timer(2.2).timeout
		var hurt: bool = foe.life < 99999.0 or (id == "glass_ward" and (p.skills.skill("glass_ward") as GlassWard).up())
		expect(hurt, "%s works (%s)" % [id, "the ward is up" if id == "glass_ward" else "the enemy was hurt"])
		foe.queue_free()


func keystones() -> void:
	p.prog.passives["ks_lighthouse"] = 1
	p.refresh_stats()
	var lv: float = p.light.value
	p.light.on_hit(0.5, 0.0)
	expect(is_equal_approx(p.light.value, lv), "Lighthouse Keeper: hits never dim the lantern")
	p.prog.passives.erase("ks_lighthouse")
	p.prog.passives["ks_wick_bone"] = 1
	p.refresh_stats()
	p.oil = p.stats.max_oil()
	var oil0: float = p.oil
	p.take_hit(20.0, p.global_position, 0.0)
	expect(p.oil < oil0, "Wick and Bone: part of a hit is paid in Oil")
	p.prog.passives.erase("ks_wick_bone")
	p.refresh_stats()


func forge() -> void:
	var it: Dictionary = LootGen.make(10, "normal")
	var mats: Dictionary = {"kindle": 9, "temper": 9, "quench": 9, "anneal": 9}
	var heat0: int = int(it["heat"])
	expect(Forge.craft(it, "kindle", -1, mats) > 0 and it["rarity"] == "magic" and (it["affixes"] as Array).size() == 1,
		"Kindle adds an affix and makes a normal item magic")
	expect(int(it["heat"]) < heat0 and int(mats["kindle"]) == 8, "a craft spends Heat and one material")
	Forge.craft(it, "kindle", -1, mats)
	Forge.craft(it, "kindle", -1, mats)
	expect(it["rarity"] == "rare", "three affixes make it rare")
	var t0: int = int(it["affixes"][0]["tier"])
	Forge.craft(it, "temper", 0, mats)
	expect(int(it["affixes"][0]["tier"]) == t0 + 1 or int(it["heat"]) == 0, "Temper raises a tier")
	var n: int = (it["affixes"] as Array).size()
	Forge.craft(it, "quench", 0, mats)
	expect((it["affixes"] as Array).size() == n - 1 or int(it["heat"]) == 0, "Quench removes an affix")
	it["heat"] = 0
	expect(Forge.block(it, "anneal", -1, mats) != "", "a cold item can't be forged")
	expect(Forge.block(LootGen.make_unique("long_night", 5), "kindle", -1, mats) != "", "uniques can't be forged")
	expect(_forged_legal(it), "a forged item keeps legal affix tiers and values")
