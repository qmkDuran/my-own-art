extends Node
## --tamer-shots: review stills of the creature-trainer demo (needs a display; tools/tamer_shots.sh runs it under
## xvfb). --only=NAME picks one (SHOTS). Each is staged in the real demo (moved into place, then played for real)
## and saved as NAME_<w>x<h>.png in --out.

const SHOTS: Array[String] = ["hall", "station", "transition", "meadow", "riverbank", "forest", "ruins", "channel",
	"effects", "burn", "catch", "large", "trainer", "route", "evolution"]

var g: TamerGame
var _out: String


func _ready() -> void:
	_out = TestRunner.out_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _only() -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			return a.substr(7)
	return ""


func _run() -> void:
	await _wait(1.0)
	g = TamerGame.current
	g.guide.done("station")
	var names: Array[String] = SHOTS.duplicate()
	if _only() != "":
		names = [_only()]
	for n: String in names:
		await call("_shot_" + n)
	get_tree().quit()


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var res: Vector2i = DisplayServer.window_get_size()
	img.save_png("%s/%s_%dx%d.png" % [_out, name, res.x, res.y])
	print("SHOT ", name)


# ------------------------------------------------------------------ staging
## A wild battle in `arena_id`, through the transition; returns the foe (sturdy enough to last the still).
func _battle(kind: String, arena_id: String, tier: String = "normal") -> Creature:
	g.battle.start_wild(CreatureRecord.make(kind, g.team.current().level, true), arena_id, tier)
	while g.battle.foe == null or g.transition.busy:
		await _wait(0.05)
	var f: Creature = g.battle.foe
	f.rec.life = f.rec.max_life()
	return f


## Your creature walks toward `to` while the fight plays for `seconds`.
func _play(to: Vector2, seconds: float) -> void:
	(g.field.partner.brain as ControlledBrain).goal = to
	await _wait(seconds)


# ------------------------------------------------------------------ the stills
func _shot_hall() -> void:
	g.trainer.place(g.hall.spot("lever") + Vector2(40, 10))
	g.trainer.walk_to(g.hall.gate_spot(1) + Vector2(0, 70))
	await _wait(1.4)
	await _save("hall")


func _shot_station() -> void:
	g.trainer.place(g.hall.spot("station") + Vector2(0, 20))
	g.hall.use_nearby()
	g.hud.station.set_level(15)
	await _wait(0.3)
	await _save("station")
	g.hud.station.close()


## Half-way through the swirl into a battle.
func _shot_transition() -> void:
	g.trainer.place(g.hall.gate_spot(0) + Vector2(0, 40))
	await _wait(0.3)
	g.battle.start_wild(CreatureRecord.make("maned_wolf", 5, true), "meadow", "normal")
	await _wait(float(TamerData.rule("battle.transition")) * 0.6)
	await _save("transition")
	while g.transition.busy or g.battle.foe == null:
		await _wait(0.05)
	g.battle.end(true)
	while g.battle.on or g.transition.busy:
		await _wait(0.05)


func _arena_shot(id: String, kind: String, tier: String) -> void:
	var foe: Creature = await _battle(kind, id, tier)
	g.team.gauge = 3.0
	await _play(g.battle.arena.center(), 1.4)
	g.input.cursor_override = foe.global_position
	g.input.use(String(g.field.partner.rec.moves()[1]))
	await _wait(0.5)
	g.input.press_move(3)
	await _wait(0.2)
	await _save(id if g.hall.size_id == "medium" else id + "_large")
	g.input.release_move(3)
	g.input.cursor_override = Vector2.INF
	g.battle.end(true)
	while g.battle.on or g.transition.busy:
		await _wait(0.05)


func _shot_meadow() -> void:
	await _arena_shot("meadow", "maned_wolf", "normal")


func _shot_riverbank() -> void:
	await _arena_shot("riverbank", "tas_devil", "easy")


func _shot_forest() -> void:
	await _arena_shot("forest", "aye_aye", "normal")


func _shot_ruins() -> void:
	await _arena_shot("ruins", "tas_devil", "hard")


## Holding a status move: the honey badger channels Growl (the wind-up glow and the strength building).
func _shot_channel() -> void:
	var foe: Creature = await _battle("maned_wolf", "meadow", "easy")
	await _play(g.battle.arena.center() - Vector2(60, 0), 1.0)
	foe.brain = null
	g.input.cursor_override = foe.global_position
	g.input.press_move(2)
	await _wait(0.9)
	await _save("channel")
	g.input.release_move(2)
	g.input.cursor_override = Vector2.INF
	g.battle.end(true)
	while g.battle.on or g.transition.busy:
		await _wait(0.05)


## Buffs and debuffs on both creatures, with their timers.
func _shot_effects() -> void:
	var foe: Creature = await _battle("tas_devil", "meadow", "normal")
	await _play(g.battle.arena.center() - Vector2(40, 0), 1.0)
	foe.effects.add("weakened", 1.0)
	foe.effects.add("berserk", 0.7)
	g.field.partner.effects.add("sprint", 1.0)
	g.field.partner.effects.add("rattled", 0.6)
	await _wait(1.2)
	await _save("effects")
	g.battle.end(true)
	while g.battle.on or g.transition.busy:
		await _wait(0.05)


## A trainer's 3v3: their creatures as balls at the top, the trainer outside the right wall.
func _shot_trainer() -> void:
	var o := OpponentTrainer.new().setup(TamerData.rule("battle.trainers.hall"), 5, "normal")
	g.battle.start_trainer(o, "ruins")
	while g.battle.foe == null or g.transition.busy:
		await _wait(0.05)
	o.team[2].life = 0.0
	await _play(g.battle.arena.center(), 2.0)
	await _save("trainer")
	g.battle.end(true)
	while g.battle.on or g.transition.busy:
		await _wait(0.05)


func _shot_route() -> void:
	g.go_route()
	while g.area != "route" or g.transition.busy:
		await _wait(0.05)
	var at: Vector2 = g.trainer.global_position
	g.spawner.clear_near(at, 500.0)
	var c: Creature = g.spawner.spawn("tas_devil", g.route_layout.free_spot_near(at + Vector2(150, -30), 14.0), 5)
	(c.brain as RouteBrain).temperament = "aggressive"
	c.brain = null
	g.trainer.walk_to(at + Vector2(60, 10))
	await _wait(1.0)
	await _save("route")


func _shot_evolution() -> void:
	var rec: CreatureRecord = g.team.current()
	rec.growth.set_level(15)
	rec.growth.add_xp(CreatureGrowth.xp_to_next(15))
	await _wait(1.3)
	await _save("evolution")


func _leave() -> void:
	g.battle.end(true)
	while g.battle.on or g.transition.busy:
		await _wait(0.05)


## Burning to ash: one patch burning with flames, the one beside it already ash and smoke.
func _shot_burn() -> void:
	var foe: Creature = await _battle("maned_wolf", "meadow", "easy")
	foe.brain = null
	var a: Arena = g.battle.arena
	var patch := Vector2i(4, 3)
	a.affect(a.layout.center_of(patch), 40.0, {"burns": true}, false)
	a.change.tick(float(TerrainChange.state("coals")["time"]) + 0.05)
	a.affect(a.layout.center_of(patch + Vector2i(3, 0)), 30.0, {"burns": true}, false)
	a.view.refresh()
	await _play(a.layout.center_of(patch + Vector2i(1, 3)), 0.8)
	await _save("burn")
	await _leave()


## The catch: the beam from the trainer at the edge, the scan ring filling, the creature lunging (its tell).
func _shot_catch() -> void:
	var foe: Creature = await _battle("maned_wolf", "meadow", "easy")
	foe.set_dazed(true)
	await _play(foe.global_position + Vector2(-120, 0), 1.0)
	g.lens.request()
	await _wait(0.95)
	await _save("catch")
	g.lens.cancel()
	await _leave()


## A large arena: the camera pulls back to fit it.
func _shot_large() -> void:
	g.hall.size_id = "large"
	await _arena_shot("riverbank", "tas_devil", "normal")
	g.hall.size_id = "medium"
