extends Node
## --smoke: headless play of the core loop plus the core rules as tests. Starts the real game scene, then checks:
## stats math, damage and the Shrouded rule, the Light, every skill and some tree effects, passives and mastery,
## loot rolls, equipping, drop placement and label stacking, walking and taking items, chests/waylamps/notes/
## people, the Glazier and Nim, death and rising, and save/load. Prints SMOKE PASS or the failures.

var g: Game
var p: Player
var _fails: PackedStringArray = []
var _count: int = 0


func _ready() -> void:
	_run.call_deferred()


func expect(ok: bool, what: String) -> void:
	_count += 1
	if ok:
		print("SMOKE ok: ", what)
	else:
		print("SMOKE FAIL: ", what)
		_fails.append(what)


func frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	await frames(20)
	g = Game.current
	p = g.player
	var h := ShotHelper.new(g)
	h.clear_near(1200.0)
	await frames(2)
	expect(LayoutCheck.problems(g.layout).is_empty(), "the zone keeps every layout rule")
	expect(get_tree().get_nodes_in_group("enemies").size() >= 60, "packs spawned (%d enemies)" % get_tree().get_nodes_in_group("enemies").size())
	expect(ActorCheck.problems(g).is_empty(), "no body stands inside a prop at the start %s" % ActorCheck.problems(g))
	expect(ActorCheck.enemy_overlaps(g) == 0, "no two enemies spawn inside each other")
	_stats_math()
	await _damage_rules()
	await _light_rules()
	await _skills(h)
	_progression()
	_loot_rules()
	await _drops_and_labels()
	await _walk_and_take()
	await _interactables()
	await _boss(h)
	await _death()
	_save_load()
	_filter_and_stash()
	await _act1_foes(h)
	await _pass3(ShotHelper.new(g))
	await _campaign()
	print("SMOKE %s (%d checks, %d failed)" % ["PASS" if _fails.is_empty() else "FAIL", _count, _fails.size()])
	get_tree().quit(0 if _fails.is_empty() else 1)


func _stats_math() -> void:
	var P: Dictionary = GameData.player
	var want: float = roundf(float(P["life"]) + float(P["life_per_level"]) * (p.prog.level - 1))
	expect(is_equal_approx(p.stats.max_life(), want), "max life = base + per level (%d)" % roundi(want))
	var it: Dictionary = LootGen.make(5, "normal")
	it["slot"] = "neck"
	it["implicit"] = {"life": 20.0}
	it["affixes"] = []
	p.inv.add(it)
	p.inv.equip(p.inv.bag.find(it), 99)
	expect(is_equal_approx(p.stats.max_life(), want + 20.0), "a +20 life amulet adds exactly 20 life")
	p.inv.unequip("neck")


func _damage_rules() -> void:
	p.light.value = 50.0
	p.stats.total["crit_chance"] = -100.0
	var e: Enemy = g.spawner.spawn("glazier", p.global_position + Vector2(40, 0), "normal", [], 1)
	await frames(12)
	expect(not e.shrouded, "an enemy inside the lantern light is not Shrouded")
	var life0: float = e.life
	Combat.hit_enemy(e, 100.0, {"kind": "spell"})
	expect(is_equal_approx(life0 - e.life, roundf(100.0 * p.stats.increased("spell"))), "a lit hit deals base x increased (%d)" % roundi(life0 - e.life))
	e.global_position = p.global_position + Vector2(600, 0)
	p.light.value = float(GameData.light["min"])
	await frames(14)
	expect(e.shrouded, "an enemy outside every light is Shrouded")
	life0 = e.life
	Combat.hit_enemy(e, 100.0, {"kind": "spell"})
	var want: float = roundf(100.0 * p.stats.increased("spell") * float(GameData.light["shrouded_damage_taken_mult"]))
	expect(is_equal_approx(life0 - e.life, want), "a Shrouded enemy takes less (%d of 100)" % roundi(life0 - e.life))
	var r: Vector2 = p.skills.skill("sunlash").shown_range(100.0)
	var lo: float = INF
	var hi: float = 0.0
	for i: int in 200:
		var base: float = p.skills.skill("sunlash").roll(100.0) * p.stats.increased("attack")
		lo = minf(lo, roundf(base))
		hi = maxf(hi, roundf(base))
	expect(lo >= r.x - 1.0 and hi <= r.y + 1.0, "Sunlash rolls stay in the tooltip range %d-%d" % [r.x, r.y])
	p.stats.total.erase("crit_chance")
	e.queue_free()
	await frames(2)


func _light_rules() -> void:
	p.light.value = 60.0
	p.light.on_hit(0.2, 0.0)
	expect(p.light.value < 60.0, "a hit dims the lantern (60 -> %.1f)" % p.light.value)
	var v: float = p.light.value
	p.light.on_kill("rare")
	expect(p.light.value > v, "an elite kill feeds it")
	p.light.value = float(GameData.light["min"])
	var r0: float = p.light.target_radius()
	await get_tree().create_timer(1.0).timeout
	expect(p.light.value > float(GameData.light["min"]), "a guttering lantern recovers by itself")
	p.light.value = 100.0
	expect(p.light.target_radius() > r0 * 2.0, "radius grows with Light (%d -> %d)" % [roundi(r0), roundi(p.light.target_radius())])
	expect(p.light.state() == "blazing", "full Light is Blazing")
	p.light.value = 60.0


func _skills(h: ShotHelper) -> void:
	h.level_up(4)
	for id: String in ["sunlash", "flare", "lantern_toss", "moth_swarm"]:
		var foes: Array[Enemy] = h.pack_near(["gloam"], Vector2(50, 10))
		foes[0].max_life = 9999.0
		foes[0].life = 9999.0
		await frames(3)
		expect(h.cast(id, foes[0].global_position), "%s can be used" % id)
		await frames(90)
		expect(foes[0].life < 9999.0, "%s hurts an enemy" % id)
		(p.skills.skill("lantern_toss") as LanternToss).recall()
		foes[0].queue_free()
		await frames(40)
	expect(p.prog.is_specialised("sunlash") and p.prog.spec_slots() >= 2, "Sunlash takes a specialisation slot")
	h.spec("sunlash", ["quick_wrist", "long_cord", "long_cord", "sear", "kindling", "backhand"])
	expect(p.prog.node_rank("sunlash", "backhand") == 1, "spending Sunlash points opens Backhand")
	var behind: Array[Enemy] = h.pack_near(["gloam"], Vector2(-45, 0))
	behind[0].life = 999.0
	behind[0].max_life = 999.0
	await frames(3)
	h.cast("sunlash", p.global_position + Vector2(60, 0))
	await frames(4)
	expect(behind[0].life < 999.0, "Backhand also hits the enemy behind")
	expect((p.skills.skill("sunlash") as Sunlash).reach(false) > float(GameData.skill("sunlash")["range"]), "Long Cord lengthens the lash")
	behind[0].queue_free()


func _progression() -> void:
	var pr: Progression = p.prog
	expect(pr.passive_points() == pr.level - 1, "one passive point per level")
	expect(pr.add_passive("wick") and pr.passives["wick"] == 1, "a base-tree node takes a point")
	expect(not pr.add_passive("kindler"), "a 5-point node is locked before 5 points")
	expect(not pr.choose_mastery("beacon"), "no mastery before level %d" % int(GameData.player["mastery_level"]))
	ShotHelper.new(g).level_up(int(GameData.player["mastery_level"]))
	expect(pr.choose_mastery("duskwalker"), "the mastery is chosen at its level")
	expect(p.stats.v("damage_vs_shrouded_pct") >= 25.0, "the mastery bonus applies")
	expect(pr.remove_passive("wick"), "a point can be refunded")


func _loot_rules() -> void:
	var ok: bool = true
	var seen: Dictionary = {}
	for i: int in 400:
		var it: Dictionary = LootGen.make(randi_range(1, 12), LootGen.roll_rarity("rare"))
		seen[it["rarity"]] = true
		ok = ok and _item_legal(it)
	expect(ok, "400 items roll with legal affix counts, tiers and values")
	expect(seen.size() >= 4, "rarities seen: %s" % ", ".join(PackedStringArray(seen.keys())))


func _item_legal(it: Dictionary) -> bool:
	var n: int = (it["affixes"] as Array).size()
	var pre: int = (it["affixes"] as Array).filter(func(a: Dictionary) -> bool: return a["type"] == "prefix").size()
	var ok: bool = String(it["name"]) != "" and pre <= 2 and n - pre <= 2
	if it["rarity"] == "magic":
		ok = ok and n >= 1 and n <= 2
	if it["rarity"] == "rare":
		ok = ok and n >= 3 and n <= 4
	for a: Dictionary in it["affixes"]:
		var tr: Array = LootGen.affix_tier_range(String(a["id"]), int(a["tier"]))
		ok = ok and float(a["value"]) >= float(tr[0]) - 0.05 and float(a["value"]) <= float(tr[1]) + 0.05
	return ok


func _drops_and_labels() -> void:
	var old: Array = get_tree().get_nodes_in_group("ground_items")
	p.stop()
	g.spawner.drop_items(p.global_position, 12, "chest", 3)
	await frames(40)
	var items: Array = get_tree().get_nodes_in_group("ground_items").filter(func(n: Node) -> bool: return not old.has(n))
	var bad: int = 0
	for n: Node in items:
		var gi := n as GroundItem
		if not g.layout.point_free(gi.global_position, LootDrop.ITEM_RADIUS) or gi.global_position.distance_to(p.global_position) < LootDrop.CLEAR_OF_PLAYER - 1.0:
			bad += 1
	expect(items.size() >= 12 and bad == 0, "12 drops land on open ground, none under the player (%d bad)" % bad)
	expect(LabelStack.overlaps(get_tree()) == 0, "no item names overlap")


func _walk_and_take() -> void:
	var gi := get_tree().get_nodes_in_group("ground_items")[0] as GroundItem
	var item: Dictionary = gi.item
	g.input.cursor_override = gi.label_rect().get_center()
	await frames(2)
	g.input.press()
	g.input.lmb_held = false
	await frames(120)
	g.input.cursor_override = Vector2.INF
	expect(p.inv.bag.has(item), "clicking an item's name walks there and takes it")
	var from: Vector2 = p.global_position
	p.walk_to(g.layout.center_of(g.layout.clearing_of_role("hut")["center"]))
	await frames(60)
	expect(p.global_position.distance_to(from) > 60.0, "click-to-move follows a path through the forest")
	p.stop()


func _interactables() -> void:
	var chest: Chest = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is Chest)[0]
	var before: int = get_tree().get_nodes_in_group("ground_items").size()
	chest.use(g)
	await frames(6)
	expect(chest.opened and get_tree().get_nodes_in_group("ground_items").size() > before, "a chest opens and drops loot")
	var lamp: Waylamp = g.lamps.filter(func(l: Waylamp) -> bool: return not l.lit)[0]
	p.global_position = lamp.stand_point()
	await frames(2)
	lamp.use(g)
	lamp.progress = 0.97
	await get_tree().create_timer(1.0).timeout
	expect(lamp.lit, "relighting a waylamp completes")
	var note: LoreObject = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is LoreObject and (n as LoreObject).note_id != "")[0]
	note.use(g)
	expect(g.hud.messages.modal(), "a lore note opens")
	g.hud.messages.advance()
	var npc: Npc = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is Npc)[0]
	npc.use(g)
	expect(g.hud.messages.modal(), "talking to %s opens dialogue" % npc.npc_id)
	while g.hud.messages.advance():
		pass


func _boss(h: ShotHelper) -> void:
	h.clear_near(100000.0)
	await frames(2)
	h.place_player(g.layout.circle_center() + Vector2(0, 80))
	g.start_boss()
	await frames(30)
	expect(is_instance_valid(g.spawner.boss), "the Glazier rises in the stone ring")
	expect(ActorCheck.problems(g).is_empty(), "nobody stands inside a standing stone %s" % ActorCheck.problems(g))
	await frames(40)
	expect(ActorCheck.hidden(g).is_empty(), "no tall prop hides anyone's feet without fading %s" % ActorCheck.hidden(g))
	g.spawner.boss.life = 1.0
	Combat.hit_enemy(g.spawner.boss, 50.0)
	await frames(30)
	expect(g.flags.has("boss_down") and g.cocoon.broken, "the Glazier breaks and so does the glass")
	var nim: Array = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is Npc and (n as Npc).npc_id == "nim")
	expect(nim.size() == 1, "Nim steps out")


func _death() -> void:
	p.life = 1.0
	p.take_hit(50.0, p.global_position, 0.0)
	expect(p.dead, "the Lamplighter can fall")
	await get_tree().create_timer(2.0).timeout
	expect(not p.dead and p.global_position.distance_to(p.respawn_at) < 2.0, "and wakes at the last lit waylamp")


func _save_load() -> void:
	var back: Dictionary = JSON.parse_string(JSON.stringify(SaveGame.snapshot(g)))
	var level: int = p.prog.level
	var bag: int = p.inv.bag_items().size()
	p.prog.level = 1
	p.inv.bag.fill({})
	SaveGame.apply_character(g, back["character"])
	expect(p.prog.level == level and p.inv.bag_items().size() == bag, "save and load restore level %d and %d bag items" % [level, bag])
	expect(p.prog.mastery == "duskwalker", "save keeps the mastery")


func _filter_and_stash() -> void:
	LootFilter.toggle_rarity("normal")
	var plain: Dictionary = LootGen.make(3, "normal")
	expect(not LootFilter.shows(plain) and LootFilter.shows(LootGen.make(3, "rare")), "the loot filter hides plain items, keeps rares")
	LootFilter.toggle_rarity("normal")
	var it: Dictionary = LootGen.make(3, "magic")
	expect(g.ui.stash.store(it) and Session.stash.has(it), "an item goes into Fenn's lockers")


func _act1_foes(h: ShotHelper) -> void:
	h.clear_near(100000.0)
	await frames(2)
	p.global_position = g.layout.free_spot_near(p.global_position, p.radius)
	await get_tree().create_timer(Player.INVULN_AFTER_RISE).timeout
	var life0: float = p.life
	var husk: Enemy = h.pack_near(["husk"], Vector2(30, 0))[0]
	await frames(2)
	Combat.hit_enemy(husk, 99999.0)
	await get_tree().create_timer(1.0).timeout
	expect(p.life < life0, "a Husk bursts when it falls and burns whoever stands too close")
	p.walk_to(p.global_position + Vector2(200, 0))
	var free_speed: float = p._follow_path().length()
	p.slow(0.5, 1.0)
	expect(p._follow_path().length() < free_speed * 0.6, "silk slows the Lamplighter")
	p.stop()
	var hz: HungerZone = HungerZone.make(g.world, p.global_position, 100.0)
	var lv: float = p.light.value
	await get_tree().create_timer(0.5).timeout
	expect(p.light.value < lv, "a hunger nest drinks the lantern's Light")
	hz.queue_free()
	var m: Enemy = g.spawner.spawn("matron", p.global_position + Vector2(200, 0), "boss", [], 12)
	m.wake()
	await get_tree().create_timer(6.0).timeout
	expect(is_instance_valid(m) and not m.dead, "the Moth Matron fights for six seconds without errors")
	m.queue_free()


## Quests and dialogue across zones: Nim's quest moves on, the travel keeps the character, Ottilie starts the road.
func _campaign() -> void:
	var c: Campaign = Session.campaign
	expect(c.past("seven_heartbeats", 1), "breaking the Glazier moves Seven Heartbeats on")
	var nim: Npc = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is Npc and (n as Npc).npc_id == "nim")[0]
	nim.use(g)
	while g.hud.messages.advance():
		pass
	expect(c.step_index("seven_heartbeats") == 3, "talking to Nim: now bring her home")
	var level: int = p.prog.level
	Session.travel(g, "tallow")
	await frames(30)
	g = Game.current
	p = g.player
	expect(g.zone_id == "tallow" and p.prog.level == level, "travel to Tallow keeps the character (level %d)" % level)
	expect(c.step_index("seven_heartbeats") == 4, "arriving home moves the quest on")
	var ott: Npc = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is Npc and (n as Npc).npc_id == "ottilie")[0]
	ott.use(g)
	while g.hud.messages.advance():
		pass
	expect(c.is_done("seven_heartbeats") and c.step_index("ember_road") == 0, "Ottilie sends you down the Ember Road")
	expect(ActorCheck.problems(g).is_empty(), "nobody stands inside a building in Tallow %s" % ActorCheck.problems(g))


## Eclipse, Noon and the keystones.
func _pass3(h: ShotHelper) -> void:
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
	await _more_skills(h)
	_keystones()


func _more_skills(h: ShotHelper) -> void:
	h.level_up(12)
	for id: String in ["kindle", "hook", "glass_ward", "cinder_rain", "wick_trap", "lull"]:
		var foe: Enemy = h.pack_near(["hound"], Vector2(60, 0))[0]
		foe.max_life = 99999.0
		foe.life = 99999.0
		await frames(3)
		expect(h.cast(id, foe.global_position), "%s can be used" % id)
		if id == "kindle":
			h.cast("sunlash", foe.global_position)
		await get_tree().create_timer(2.2).timeout
		var hurt: bool = foe.life < 99999.0 or (id == "glass_ward" and (p.skills.skill("glass_ward") as GlassWard).up())
		expect(hurt, "%s works (%s)" % [id, "the ward is up" if id == "glass_ward" else "the enemy was hurt"])
		foe.queue_free()


func _keystones() -> void:
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
