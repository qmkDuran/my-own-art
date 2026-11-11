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
	var more := SmokeMore.new(self)
	more.filter_and_stash()
	await more.act1_foes(h)
	await more.pass3(ShotHelper.new(g))
	more.forge()
	await SmokeCollide.new(self).run(ShotHelper.new(g))
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
	var r: Vector2 = p.skills.skill("wickbolt").shown_range(100.0)
	var lo: float = INF
	var hi: float = 0.0
	for i: int in 200:
		var base: float = p.skills.skill("wickbolt").roll(100.0) * p.stats.increased("attack")
		lo = minf(lo, roundf(base))
		hi = maxf(hi, roundf(base))
	expect(lo >= r.x - 1.0 and hi <= r.y + 1.0, "Wickbolt rolls stay in the tooltip range %d-%d" % [r.x, r.y])
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
	for id: String in ["wickbolt", "flare", "lantern_toss", "moth_swarm"]:
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
	expect(p.prog.is_specialised("wickbolt") and p.prog.spec_slots() >= 2, "Wickbolt takes a specialisation slot")
	h.spec("wickbolt", ["quick_wick", "long_flight", "long_flight", "sear", "kindling", "piercing"])
	expect(p.prog.node_rank("wickbolt", "piercing") == 1, "spending Wickbolt points opens Piercing Wick")
	var line: Array[Enemy] = h.pack_near(["gloam", "gloam"], Vector2(70, 0))
	for k: int in 2:
		line[k].global_position = p.global_position + Vector2(60 + k * 50, 0)
		line[k].life = 999.0
		line[k].max_life = 999.0
		line[k].stun_t = 3.0
	await frames(3)
	h.cast("wickbolt", line[1].global_position)
	await frames(60)
	expect(line[0].life < 999.0 and line[1].life < 999.0, "a piercing bolt hits both enemies in its line")
	expect((p.skills.skill("wickbolt") as Wickbolt).reach() > float(GameData.skill("wickbolt")["range"]), "Long Flight lengthens the bolt's range")
	for f: Enemy in line:
		f.queue_free()


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
	expect(g.zone_id == "tallow" and p.prog.level == level, "travel to Tallow keeps the character (level %d -> %d)" % [level, p.prog.level])
	expect(c.step_index("seven_heartbeats") == 4, "arriving home moves the quest on")
	var ott: Npc = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is Npc and (n as Npc).npc_id == "ottilie")[0]
	ott.use(g)
	while g.hud.messages.advance():
		pass
	expect(c.is_done("seven_heartbeats") and c.step_index("ember_road") == 0, "Ottilie sends you down the Ember Road")
	expect(ActorCheck.problems(g).is_empty(), "nobody stands inside a building in Tallow %s" % ActorCheck.problems(g))


## Eclipse, Noon and the keystones.
## The Ember Forge: every craft does what it says, spends Heat and a material, and stops when Heat is gone.
