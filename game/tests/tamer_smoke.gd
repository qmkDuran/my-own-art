extends Node
## --tamer-smoke: headless play of the creature-trainer demo. Starts the real scene in the Gate Hall, then checks
## the hall and team station, walking through a gate (the transition in and out, the walled arena, the trainer
## outside it, back to the exact spot, health carrying over on the route and the hall healing), the combat
## (TamerSmokeCombat: skillshots that can miss, channelling, buffs and debuffs, advantage-only elements, home
## terrain, terrain changes, swaps, every AI tier) and the world (TamerSmokeWorld: a 3v3 trainer win, the rival's
## Accept/Decline, temperaments, Sync Lens tiers, XP and evolution, shinies, losing). Prints TAMER PASS or FAIL.

var g: TamerGame
var _fails: PackedStringArray = []
var _count: int = 0


func _ready() -> void:
	_run.call_deferred()


func expect(ok: bool, what: String) -> void:
	_count += 1
	print("TAMER ok: " if ok else "TAMER FAIL: ", what)
	if not ok:
		_fails.append(what)


func frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func seconds(s: float) -> void:
	await frames(int(s * Engine.physics_ticks_per_second))


## Waits until `cond` holds (or `limit` seconds pass); returns whether it held.
func until(cond: Callable, limit: float = 5.0) -> bool:
	var n: int = int(limit * Engine.physics_ticks_per_second)
	for i: int in n:
		if cond.call():
			return true
		await get_tree().physics_frame
	return bool(cond.call())


func settled() -> bool:
	return not g.transition.busy


## A wild battle in `arena_id`, waited through the transition; returns the foe.
func wild(kind: String, arena_id: String, tier: String = "normal") -> Creature:
	g.team.rest()
	g.battle.start_wild(CreatureRecord.make(kind, g.team.current().level, true), arena_id, tier)
	await until(func() -> bool: return g.battle.arena != null and g.battle.foe != null and settled())
	await frames(5)
	return g.battle.foe


## Ends the current battle (as a win unless told otherwise) and waits until you are back.
func leave(won: bool = true) -> void:
	if g.battle.on:
		g.battle.end(won)
	await until(func() -> bool: return not g.battle.on and settled() and g.battle.arena == null)
	await frames(5)


func go_hall() -> void:
	if g.area != "hall":
		g.go_hall()
		await until(func() -> bool: return g.area == "hall" and settled())
	await frames(5)


func go_route() -> void:
	if g.area != "route":
		g.go_route()
		await until(func() -> bool: return g.area == "route" and settled())
	await frames(5)


func _run() -> void:
	if get_tree().current_scene == null or not get_tree().current_scene is TamerGame:
		get_tree().change_scene_to_file("res://scenes/tamer.tscn")
	await frames(20)
	g = TamerGame.current
	expect(g != null and LayoutCheck.problems(g.route_layout).is_empty(), "the route keeps every layout rule")
	await until(settled)
	_start()
	_station()
	await _gate()
	await _route_carry()
	await TamerSmokeCombat.new(self).run()
	await TamerSmokeWorld.new(self).run()
	print("TAMER %s (%d checks, %d failed)" % ["PASS" if _fails.is_empty() else "FAIL", _count, _fails.size()])
	get_tree().quit(0 if _fails.is_empty() else 1)


func _start() -> void:
	expect(g.area == "hall", "the demo starts in the Gate Hall")
	expect(g.team.members.size() == 3 and g.team.members.all(func(r: CreatureRecord) -> bool: return r.level == 5),
		"with the default team of three at level 5")
	expect(g.field.partner != null and g.field.partner.brain is PartnerBrain, "your creature follows you in the hall")
	expect(g.hall.data["gates"].size() == 4, "four gates: meadow, riverbank, forest, ruins")
	expect(TamerData.arenas["arenas"].values().all(func(a: Dictionary) -> bool: return (a["checklist"] as Array).size() >= 3),
		"every arena's sign lists things to try")


func _station() -> void:
	var st: TeamStation = g.hud.station
	g.trainer.place(g.hall.spot("station") + Vector2(0, 20))
	expect(g.hall.use_nearby() and st.visible, "F at the team station opens it")
	for id: String in st.picks.duplicate():
		st.toggle_pick(id)
	for id: String in ["maned_wolf", "aye_aye", "tas_devil", "pangolin"]:
		st.toggle_pick(id)
	expect(st.picks.size() == 3, "only three can be picked")
	st.set_level(15)
	var rec: CreatureRecord = st.record("maned_wolf")
	var before: String = rec.growth.active[3]
	st.cycle_move(rec, 3)
	expect(rec.growth.active[3] != before and rec.growth.learned().has(rec.growth.active[3]), "a slot cycles to another learned move")
	expect(rec.growth.learned().has("howl"), "level 15 unlocks moves (Howl at 12)")
	st.close()
	expect(g.team.members.map(func(r: CreatureRecord) -> String: return r.species_id) == ["maned_wolf", "aye_aye", "tas_devil"],
		"closing the station makes the picks your team")
	expect(g.team.current().level == 15 and g.field.partner.rec == g.team.members[0], "at level 15, the first one out")
	expect(g.guide.is_done("station"), "the guide counts the station")
	st.choose(TamerData.rule("hall.default_team"), 5)
	expect(g.team.current().species_id == "honey_badger" and g.team.current().level == 5, "the default team is back")


func _gate() -> void:
	var back: Vector2 = g.hall.gate_spot(0) + Vector2(0, 40)
	g.trainer.place(back)
	await frames(2)
	g.trainer.place(g.hall.gate_spot(0))
	await frames(3)
	expect(g.transition.busy, "walking through the meadow gate starts the swirl transition")
	await until(func() -> bool: return g.area == "arena" and settled())
	var a: Arena = g.battle.arena
	expect(a != null and a.id == "meadow" and g.battle.on, "and the battle is on in the meadow arena")
	expect(not a.layout.rect_px().has_point(g.trainer.global_position), "the trainer watches from outside the arena")
	var p: Creature = g.field.partner
	expect(p != null and p.brain is ControlledBrain and a.layout.rect_px().has_point(p.global_position), "you control your creature inside it")
	expect(g.battle.foe != null and g.battle.foe.brain is FoeBrain, "a wild opponent is sent out")
	g.battle.foe.brain = null
	(p.brain as ControlledBrain).goal = a.layout.rect_px().position - Vector2(300, 0)
	g.battle.foe.rec.life *= 0.5
	await seconds(2.5)
	expect(a.layout.rect_px().has_point(p.global_position), "the arena walls hold")
	p.rec.life = p.rec.max_life() * 0.4
	await leave()
	expect(g.area == "hall" and g.trainer.global_position.distance_to(g.hall.gate_spot(0)) < 4.0,
		"after the battle the transition brings you back to the exact spot")
	expect(g.team.members.all(func(r: CreatureRecord) -> bool: return r.life >= r.max_life()), "the Gate Hall heals the team")
	g.trainer.place(back)
	await seconds(1.2)


## On the route, health carries over between battles.
func _route_carry() -> void:
	await go_route()
	expect(g.area == "route" and g.field.partner != null, "the door leads to the route")
	var spot: Vector2 = g.trainer.global_position
	g.team.current().life = g.team.current().max_life() * 0.5
	var c: Creature = g.spawner.spawn("maned_wolf", g.route_layout.free_spot_near(spot + Vector2(200, 0), 14.0), 4)
	g.encounter(c)
	await until(func() -> bool: return g.area == "arena" and settled())
	expect(g.battle.on and absf(g.field.partner.rec.life_frac() - 0.5) < 0.05, "a route battle starts with the health you had")
	await leave()
	expect(g.area == "route" and g.trainer.global_position.distance_to(spot) < 4.0, "and ends back on the route where you were")
	expect(g.team.current().life_frac() < 0.9, "without healing you")
	expect(not is_instance_valid(c), "the beaten creature is gone from the route")
