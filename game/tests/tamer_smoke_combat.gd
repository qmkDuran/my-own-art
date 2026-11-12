class_name TamerSmokeCombat
extends RefCounted
## Part of --tamer-smoke: the combat. A special is a skillshot that can miss; a status move is channelled (no moving
## or dodging, a hit cancels it, longer is stronger); buffs and debuffs with their costs; elements only ever help;
## a home-terrain bonus; moves that change the arena; swaps cost gauge; and every AI tier fights.

var smoke: Node
var g: TamerGame


func _init(owner_test: Node) -> void:
	smoke = owner_test
	g = smoke.g


func run() -> void:
	await smoke.go_hall()
	var foe: Creature = await smoke.wild("maned_wolf", "meadow")
	foe.brain = null
	await _skillshot(foe)
	await _channel(foe)
	_effects(foe)
	_advantage()
	await _home(foe)
	await _terrain()
	_bonus_cap(foe)
	_equal_footing()
	await _swap()
	await smoke.leave()
	await _tiers()


## Two creatures on a clear line across the arena (no cover between).
func _line(foe: Creature) -> void:
	var a: Arena = g.battle.arena
	for y: int in range(2, a.layout.rows - 2):
		var from: Vector2 = a.layout.center_of(Vector2i(5, y))
		var to: Vector2 = from + Vector2(200, 0)
		var clear: bool = true
		for k: int in 21:
			clear = clear and not a.layout.blocks_shot(from.lerp(to, k / 20.0)) and a.layout.f_at(from.lerp(to, k / 20.0)) == ArenaLayout.F.NONE
		if clear:
			g.field.partner.global_position = from
			foe.global_position = to
			return


func _skillshot(foe: Creature) -> void:
	_line(foe)
	var p: Creature = g.field.partner
	var life: float = foe.rec.life
	g.team.gauge = 3.0
	g.input.cursor_override = p.global_position + Vector2(0, -260)
	smoke.expect(g.input.use("cinder_spit"), "a special goes off at the cursor")
	smoke.expect(absf(g.team.gauge - 2.0) < 0.01, "and costs its gauge")
	await smoke.seconds(1.6)
	smoke.expect(is_equal_approx(foe.rec.life, life), "a skillshot aimed away misses (no homing)")
	g.input.cursor_override = foe.global_position
	smoke.expect(g.input.use("cinder_spit"), "a second one, at the foe")
	await smoke.seconds(1.6)
	smoke.expect(foe.rec.life < life, "a skillshot on target hits")
	smoke.expect(g.guide.is_done("special"), "the guide counts the special")
	g.input.cursor_override = Vector2.INF


func _channel(foe: Creature) -> void:
	var p: Creature = g.field.partner
	await smoke.until(func() -> bool: return p.commit_t <= 0.0 and p.move_ready("growl"))
	smoke.expect(p.begin_channel("growl"), "holding a status move starts channelling it")
	var at: Vector2 = p.global_position
	(p.brain as ControlledBrain).goal = at + Vector2(0, 120)
	await smoke.seconds(0.5)
	smoke.expect(p.global_position.distance_to(at) < 2.0 and p.channel_id == "growl", "no moving while channelling")
	smoke.expect(not p.dodge(at + Vector2(100, 0), TamerData.rule("control.dodge")), "and no dodging")
	CreatureCombat.hit(foe, p, TamerData.move("wolf_nip"), Vector2.RIGHT)
	smoke.expect(p.channel_id == "", "a hit cancels the channel")
	(p.brain as ControlledBrain).goal = Vector2.INF
	await smoke.seconds(0.6)
	p.begin_channel("growl")
	await smoke.seconds(0.1)
	var weak: float = p.channel_strength()
	await smoke.seconds(1.6)
	var full: float = p.channel_strength()
	smoke.expect(full > weak and is_equal_approx(full, 1.0), "holding longer makes it stronger, up to a cap (%.2f -> %.2f)" % [weak, full])
	smoke.expect(p.release_channel(foe.global_position) and foe.effects.has("weakened"), "releasing it puts Weakened on the foe")
	smoke.expect(foe.effects.mult("dealt") < 0.75, "Weakened at full strength cuts its damage")


func _effects(foe: Creature) -> void:
	var p: Creature = g.field.partner
	var speed: float = p.speed()
	p.effects.add("hardened", 1.0)
	smoke.expect(p.speed() < speed and not p.dodge(p.global_position + Vector2(50, 0), TamerData.rule("control.dodge")),
		"Hardened has its cost: slower, and no dodging")
	var t: float = float(p.effects.list["hardened"]["t"])
	p.effects.on_hit()
	smoke.expect(float(p.effects.list["hardened"]["t"]) < t - 0.5, "a buff fades faster when hit")
	var dt: float = float(foe.effects.list["weakened"]["t"])
	foe.effects.on_hit()
	smoke.expect(is_equal_approx(float(foe.effects.list["weakened"]["t"]), dt), "a debuff just runs out")
	p.effects.add("sprint", 1.0)
	smoke.expect(not p.effects.has("hardened") and p.effects.has("sprint"), "one buff at a time: a new one replaces the old")
	smoke.expect(p.speed() > speed, "Sprint is faster")
	p.effects.tick(10.0)
	smoke.expect(p.effects.has("lethargy") and p.speed() < speed, "and leaves Lethargy behind")
	p.effects.remove("lethargy")


func _advantage() -> void:
	smoke.expect(is_equal_approx(TamerData.element_mult("ember", "glass"), 1.3), "an element advantage hits x1.3")
	var never_less: bool = true
	for a: String in TamerData.elements["elements"]:
		for b: String in TamerData.elements["elements"]:
			never_less = never_less and TamerData.element_mult(a, b) >= 1.0
	smoke.expect(never_less, "no element is ever resisted (advantage only)")


## The honey badger's home is burning ground: it hits harder there and doesn't burn; elsewhere it is never weaker.
func _home(foe: Creature) -> void:
	var p: Creature = g.field.partner
	var lay: ArenaLayout = g.battle.arena.layout
	smoke.expect(is_equal_approx(TerrainRules.dealt_mult(p), 1.0), "off its home terrain it is normal")
	lay.set_temporary(lay.cell_of(p.global_position), ArenaLayout.F.COALS, 5.0)
	lay.set_temporary(lay.cell_of(foe.global_position), ArenaLayout.F.COALS, 5.0)
	var life: float = p.rec.life
	var foe_life: float = foe.rec.life
	smoke.expect(TerrainRules.dealt_mult(p) > 1.2, "on burning ground the honey badger hits 25% harder")
	await smoke.seconds(1.0)
	smoke.expect(p.rec.life >= life and foe.rec.life < foe_life, "and doesn't burn there, while the wolf does")


## Moves change the arena, and destroyed terrain transforms instead of vanishing: grass burns, lies as ash and
## smoke (hiding whoever is in it), then a burnt field, then regrows; Gale flattens grass (it regrows); Bloom regrows
## at once; a rock breaks into rubble; fire creeps through grass and burns anyone in it.
func _terrain() -> void:
	var a: Arena = g.battle.arena
	var F := ArenaLayout.F
	var grass: Array[Vector2] = _cells(a, F.GRASS)
	var c: Vector2i = a.layout.cell_of(grass[0])
	a.affect(grass[0], 4.0, {"burns": true}, false)
	smoke.expect(a.layout.f(c) == F.COALS, "Ember sets tall grass burning")
	a.change.tick(float(TerrainChange.state("coals")["time"]) + 0.05)
	smoke.expect(a.layout.f(c) == F.ASH, "the fire leaves ash and smoke")
	var p: Creature = g.field.partner
	var was: Vector2 = p.global_position
	p.global_position = a.layout.center_of(c)
	smoke.expect(TerrainRules.hidden_from(p, g.battle.foe), "smoke hides whoever stands in it")
	p.global_position = was
	a.change.tick(float(TerrainChange.state("ash")["time"]) + 0.05)
	smoke.expect(a.layout.f(c) == F.BURNT and TerrainRules.feature_name(F.BURNT) == "burnt", "then a burnt field")
	a.change.tick(float(TerrainChange.state("burnt")["time"]) + 0.05)
	smoke.expect(a.layout.f(c) == F.GRASS, "and the grass regrows")
	var other: Vector2 = grass[grass.size() - 1]
	a.affect(other, 4.0, {"gale": true}, false)
	smoke.expect(a.layout.f_at(other) == F.FLAT, "Gale flattens grass")
	a.affect(other, 4.0, {"blooms": true}, false)
	smoke.expect(a.layout.f_at(other) == F.GRASS, "Bloom regrows it at once")
	var spot: Vector2 = p.global_position + Vector2(90, 0)
	MoveBook.cast(p, "vine_wall", spot)
	smoke.expect(a.layout.f_at(spot) == F.VINE and a.layout.blocks_shot(spot), "a Vine Wall grows cover that blocks shots")
	var rocks: Array[Vector2] = _cells(a, F.ROCK)
	for k: int in 6:
		a.affect(rocks[0], 4.0, {"echo": true}, true)
	smoke.expect(a.layout.f_at(rocks[0]) == F.RUBBLE, "a broken rock becomes rubble")
	await _spread(a)


## Fire creeps through grass and burns whoever stands in it.
func _spread(a: Arena) -> void:
	var foe: Creature = g.battle.foe
	var cells: Array[Vector2] = _cells(a, ArenaLayout.F.GRASS)
	var lit: Vector2i = a.layout.cell_of(cells[0])
	var next: Vector2i = lit + Vector2i(1, 0) if a.layout.f(lit + Vector2i(1, 0)) == ArenaLayout.F.GRASS else lit + Vector2i(0, 1)
	foe.global_position = a.layout.center_of(next)
	var life: float = foe.rec.life
	a.affect(a.layout.center_of(lit), 4.0, {"burns": true}, false)
	for k: int in 30:
		if a.layout.f(next) == ArenaLayout.F.COALS:
			break
		a.change._spread()
	await smoke.seconds(0.6)
	smoke.expect(a.layout.f(next) == ArenaLayout.F.COALS and foe.rec.life < life, "fire spreads to the grass next to it and burns whoever is there")


func _cells(a: Arena, f: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y: int in a.layout.rows:
		for x: int in a.layout.cols:
			if a.layout.f(Vector2i(x, y)) == f:
				out.append(a.layout.center_of(Vector2i(x, y)))
	return out


func _swap() -> void:
	g.team.gauge = 1.0
	smoke.expect(g.field.swap(1) and g.team.gauge < 0.01, "a swap in battle costs a gauge segment")
	await smoke.frames(3)
	g.team.gauge = 3.0
	smoke.expect(not g.field.swap(2) and g.field.swap_cooldown_left() > 0.0, "and has a cooldown")
	smoke.expect(g.field.partner.brain is ControlledBrain, "you control the one that came in")


## Each tier fights for a while without errors: it telegraphs, attacks and the fight goes on.
func _tiers() -> void:
	var plan: Dictionary = {"easy": "riverbank", "normal": "forest", "hard": "ruins"}
	for tier: String in plan:
		var foe: Creature = await smoke.wild("tas_devil", String(plan[tier]), tier)
		var b := foe.brain as FoeBrain
		smoke.expect(b != null and is_equal_approx(float(b.tier["react"]), float(TamerData.rule("ai_tiers." + tier + ".react"))),
			"%s: the foe plays at that tier" % tier)
		g.field.partner.global_position = g.battle.arena.layout.free_spot_near(foe.global_position - Vector2(140, 0), 24.0)
		var life: float = g.team.members.reduce(func(s: float, r: CreatureRecord) -> float: return s + r.life, 0.0)
		await smoke.until(func() -> bool: return g.team.members.reduce(func(s: float, r: CreatureRecord) -> float: return s + r.life, 0.0) < life, 12.0)
		var after: float = g.team.members.reduce(func(s: float, r: CreatureRecord) -> float: return s + r.life, 0.0)
		smoke.expect(after < life, "%s in the %s: it attacks you" % [tier, plan[tier]])
		await smoke.leave()



## Element + ground + buffs add at most +40% together.
func _bonus_cap(foe: Creature) -> void:
	var p: Creature = g.field.partner
	p.effects.add("berserk", 1.0)
	foe.effects.add("rattled", 1.0)
	var k: float = CreatureCombat.bonus(p, foe, true)
	smoke.expect(is_equal_approx(k, 1.0 + float(TamerData.rule("combat.bonus_cap"))), "the damage bonus is capped at +40%% (%.2f)" % k)
	p.effects.list.clear()
	foe.effects.list.clear()


## Equal footing: two of the same species at the same level have the same stats and deal the same damage to each
## other, yours or not.
func _equal_footing() -> void:
	var a := Creature.new().setup(CreatureRecord.make("maned_wolf", 7, false), Combatant.SIDE_TEAM)
	var b := Creature.new().setup(CreatureRecord.make("maned_wolf", 7, true), Combatant.SIDE_WILD)
	a.stagger = StaggerBar.new(a)
	b.stagger = StaggerBar.new(b)
	smoke.expect(is_equal_approx(a.rec.max_life(), b.rec.max_life()) and is_equal_approx(a.rec.power(), b.rec.power()),
		"a wild creature has exactly the stats of yours at the same level")
	var m: Dictionary = TamerData.move("gust_bite")
	smoke.expect(is_equal_approx(CreatureCombat._mults(a, b, m, false) * a.power(), CreatureCombat._mults(b, a, m, false) * b.power()),
		"the same hit is worth the same both ways")
	a.free()
	b.free()
