class_name TamerSmokeWorld
extends RefCounted
## Part of --tamer-smoke: the world around the fights. A 3v3 trainer battle won from the Gate Hall, the route
## rival's Accept/Decline, wild temperaments, the Sync Lens tiers, XP, levels and the evolution, shinies (F1 and
## the 1 in 4096 rate), and losing a battle.

var smoke: Node
var g: TamerGame


func _init(owner_test: Node) -> void:
	smoke = owner_test
	g = smoke.g


func run() -> void:
	await smoke.go_hall()
	await _trainer_battle()
	await _sync_tiers()
	_growth()
	await _shiny()
	await _rival()
	await _temperaments()
	await _lose()


func _trainer_battle() -> void:
	g.hall.opponent = "trainer"
	g.hall.tier = 2
	g.trainer.place(g.hall.gate_spot(3) + Vector2(0, 40))
	await smoke.frames(2)
	g.trainer.place(g.hall.gate_spot(3))
	await smoke.until(func() -> bool: return g.battle.foe != null and smoke.settled())
	var o: OpponentTrainer = g.battle.opponent
	smoke.expect(o != null and o.team.size() == 3 and g.battle.arena.id == "ruins", "the switch makes it a 3v3 trainer battle (ruins)")
	smoke.expect(g.battle.tier_id == "hard" and g.hud.panel_open() == false, "at the lever's difficulty (Hard)")
	var first: Creature = g.battle.foe
	first.brain = null
	first.rec.life = first.rec.max_life() * 0.25
	await smoke.seconds(1.2)
	smoke.expect(g.battle.foe == first, "with no gauge the opposing trainer can't swap (your rules)")
	first.gauge = 2.0
	await smoke.seconds(1.2)
	smoke.expect(g.battle.foe != first and g.battle.foe.gauge < 1.01, "with gauge it swaps a hurt creature out, paying a segment")
	var downs: int = 0
	for k: int in 10:
		if not g.battle.on:
			break
		var f: Creature = g.battle.foe
		if f != null and is_instance_valid(f) and not f.fainted_now:
			f.faint()
			downs += 1
		await smoke.seconds(1.4)
	await smoke.until(func() -> bool: return not g.battle.on and g.area == "hall" and smoke.settled())
	smoke.expect(downs >= 3 and o.remaining() == 0, "they send one at a time until all three are down (%d)" % downs)
	smoke.expect(g.area == "hall" and g.guide.is_done("win"), "a 3v3 win, back in the Gate Hall")
	g.hall.opponent = "wild"
	g.hall.tier = 1
	g.trainer.place(g.hall.spot("you"))
	await smoke.frames(3)


## Catching: weaken it (gold stars), F starts the scan from the edge; it struggles, and a hit on your creature
## breaks the scan (the stars stay, retry after a moment); then a clean scan syncs it and wins the battle. The basic
## lens only reads common creatures; the upgraded one is faster and reads rare ones.
func _sync_tiers() -> void:
	g.lens.tier = "basic"
	var foe: Creature = await smoke.wild("maned_wolf", "meadow")
	foe.set_dazed(true)
	g.field.partner.global_position = foe.global_position + Vector2(-70, 0)
	smoke.expect(g.lens.request() and g.lens.scanning_at(foe), "F on a weakened creature starts the scan")
	await smoke.until(func() -> bool: return not g.lens.scanning(), 4.0)
	smoke.expect(g.lens.retry_t > 0.0 and foe.dazed and g.battle.on, "it struggles: a hit on your creature breaks the scan, the stars stay")
	smoke.expect(not g.lens.request(), "and the lens needs a moment before a retry")
	await smoke.seconds(float(TamerData.rule("sync.retry")) + 0.1)
	_keep_away(foe)
	var slow: float = await _progress_after(foe, 0.6)
	g.lens.cancel()
	g.lens.tier = "plus"
	var fast: float = await _progress_after(foe, 0.6)
	smoke.expect(fast > slow * 1.5, "the upgraded lens scans faster (%.2f vs %.2f)" % [fast, slow])
	var before: int = g.team.members.size() + g.team.sanctuary.size()
	await smoke.until(func() -> bool: return not g.battle.on, 4.0)
	smoke.expect(g.team.members.size() + g.team.sanctuary.size() == before + 1, "a clean scan syncs it and wins the battle")
	await smoke.leave()
	g.lens.tier = "basic"
	var aye: Creature = await smoke.wild("aye_aye", "meadow")
	aye.set_dazed(true)
	smoke.expect(not g.lens.request(), "the basic Sync Lens can't read a rare aye-aye")
	g.lens.tier = "plus"
	smoke.expect(g.lens.request(), "the upgraded lens can")
	g.lens.cancel()
	g.lens.tier = "basic"
	await smoke.leave()


## Your creature out of the struggling creature's reach.
func _keep_away(foe: Creature) -> void:
	var r: Rect2 = g.battle.arena.layout.rect_px()
	var far: Vector2 = Vector2(r.position.x + 60.0 if foe.global_position.x > r.get_center().x else r.end.x - 60.0, r.position.y + 60.0)
	g.field.partner.global_position = g.battle.arena.layout.free_spot_near(far, 20.0)
	(g.field.partner.brain as ControlledBrain).goal = Vector2.INF


func _progress_after(foe: Creature, s: float) -> float:
	g.lens.request()
	await smoke.seconds(s)
	return g.lens.progress if g.lens.scanning_at(foe) else 1.0


func _growth() -> void:
	var r := CreatureRecord.make("honey_badger", 1, false)
	r.growth.set_level(15)
	var life: float = r.max_life()
	smoke.expect(not r.growth.evolved_form, "a level-15 honey badger has not evolved")
	r.growth.add_xp(CreatureGrowth.xp_to_next(15) + 1.0)
	smoke.expect(r.level == 16 and r.growth.evolved_form and r.display_name() == "Ratel Warden", "at 16 it evolves into the Ratel Warden")
	smoke.expect(r.max_life() > life * 1.2, "a stronger form")
	smoke.expect(not r.growth.learned().has("honey_rage"), "the signature move waits for level 25")
	r.growth.set_level(25)
	smoke.expect(r.growth.learned().has("honey_rage"), "it comes at 25, the same for everyone")
	r.growth.set_level(5)
	smoke.expect(not r.growth.evolved_form and r.growth.learned().size() == 4, "back at level 5: unevolved, four moves known")
	var rec: CreatureRecord = g.team.current()
	var before: float = rec.growth.xp + rec.level * 1000.0
	rec.growth.add_xp(float(TamerData.rule("progression.win_xp")))
	smoke.expect(rec.growth.xp + rec.level * 1000.0 > before, "a win's XP counts toward the next level")


func _shiny() -> void:
	smoke.expect(TamerData.species("maned_wolf")["shiny_chance"] == 1.0 / 4096.0, "shinies are 1 in 4096")
	g.dev_shiny()
	await smoke.until(func() -> bool: return g.battle.foe != null and smoke.settled())
	smoke.expect(g.battle.on and g.battle.foe.rec.shiny, "F1 in the Gate Hall sends a shiny into the meadow")
	await smoke.leave()


func _rival() -> void:
	await smoke.go_route()
	var r: RivalTrainer = g.rivals[0]
	g.trainer.place(g.route_layout.free_spot_near(r.global_position + Vector2(-60, 0), 8.0))
	await smoke.seconds(0.3)
	smoke.expect(g.hud.question.visible, "the rival asks \"Want to battle?\"")
	g.hud.question.decline()
	await smoke.seconds(0.5)
	smoke.expect(not g.battle.on and not g.hud.question.visible, "Decline: no battle")
	g.trainer.place(g.route_layout.free_spot_near(r.global_position + Vector2(-400, 0), 8.0))
	await smoke.seconds(0.2)
	g.trainer.place(g.route_layout.free_spot_near(r.global_position + Vector2(-60, 0), 8.0))
	await smoke.seconds(0.3)
	smoke.expect(g.hud.question.visible, "walk away and back and they ask again")
	g.hud.question.accept()
	await smoke.until(func() -> bool: return g.battle.foe != null and smoke.settled())
	smoke.expect(g.battle.on and g.battle.opponent != null and g.battle.opponent.data["name"] == r.data["name"], "Accept: a trainer battle")
	await smoke.leave()


func _route_creature(kind: String, temperament: String, offset: Vector2) -> Creature:
	g.spawner.clear_near(g.trainer.global_position, 600.0)
	var at: Vector2 = Vector2.INF
	for k: int in 8:
		var p: Vector2 = g.trainer.global_position + offset.rotated(TAU * k / 8.0)
		if g.route_layout.point_free(p, 14.0):
			at = p
			break
	var c: Creature = g.spawner.spawn(kind, at, 4)
	(c.brain as RouteBrain).temperament = temperament
	return c


func _temperaments() -> void:
	g.trainer.place(g.route_layout.free_spot_near(g.route_layout.start + Vector2(0, 80), 8.0))
	var shy: Creature = _route_creature("aye_aye", "shy", Vector2(90, 0))
	var d0: float = shy.global_position.distance_to(g.trainer.global_position)
	await smoke.seconds(1.0)
	smoke.expect(shy.global_position.distance_to(g.trainer.global_position) > d0 + 20.0 and not g.battle.on, "a shy one flees")
	var ter: Creature = _route_creature("tas_devil", "territorial", Vector2(110, 0))
	await smoke.seconds(0.5)
	smoke.expect((ter.brain as RouteBrain).warning() and not g.battle.on, "a territorial one warns when you come close")
	g.trainer.place(g.route_layout.free_spot_near(ter.global_position + Vector2(-400, 0), 8.0))
	await smoke.seconds(float(TamerData.rule("temperament.calm_after")) + 0.5)
	smoke.expect(not (ter.brain as RouteBrain).warning(), "and calms down once you back off")
	var agg: Creature = _route_creature("maned_wolf", "aggressive", Vector2(160, 0))
	await smoke.until(func() -> bool: return g.battle.on, 6.0)
	smoke.expect(g.battle.on and g.battle.route_creature == agg, "an aggressive one chases you into a battle")
	await smoke.until(smoke.settled)
	await smoke.leave()


## Every creature down: the battle is lost; on the route you are taken back to camp, healed, a little poorer.
func _lose() -> void:
	g.team.add_material("wind_tuft", 3)
	var tufts: int = g.team.count("wind_tuft")
	var foe: Creature = await smoke.wild("tas_devil", "meadow")
	foe.brain = null
	for k: int in 4:
		var p: Creature = g.field.partner
		if p != null and is_instance_valid(p) and p.alive():
			p.faint()
		await smoke.seconds(1.2)
	await smoke.until(func() -> bool: return not g.battle.on and g.area == "route" and smoke.settled(), 6.0)
	smoke.expect(g.area == "route" and g.trainer.global_position.distance_to(g.camp_point()) < 160.0, "losing takes you back to camp")
	smoke.expect(g.team.members.all(func(r: CreatureRecord) -> bool: return not r.knocked_out()), "with the team healed")
	smoke.expect(g.team.count("wind_tuft") == tufts - 1, "and one of each material lost")
