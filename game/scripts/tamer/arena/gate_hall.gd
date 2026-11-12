class_name GateHall
extends Node2D
## The Gate Hall, where the demo starts: a stone hall with a gate per arena along its back wall (walk through one and
## the battle starts there), a sign by each gate with what to try, a difficulty lever (Easy / Normal / Hard), an
## opponent switch (a wild 1v1 or a trainer 3v3), the team station (your 3 creatures, their level and moves), a
## Sync Lens upgrade stand, and the door to the route. F uses whatever you stand next to.

signal used(what: String)

const HALL_ORIGIN := Vector2(-6000, 2000)
const USE_RANGE: float = 44.0
const TIERS: Array[String] = ["easy", "normal", "hard"]

var g: TamerGame
var layout: ArenaLayout
var view: ArenaView
var stage: Node2D
var tier: int = 1
var trainer_battle: bool = false
var data: Dictionary
var _armed: bool = true                ## a gate works again once you have stepped away from it


func build(game: TamerGame) -> GateHall:
	g = game
	data = TamerData.arenas["hall"]
	layout = ArenaLayout.new().build(int(data["cols"]), int(data["rows"]), int(TamerData.arenas["cell"]), HALL_ORIGIN)
	for gt: Array in data["gates"]:
		layout.set_f(Vector2i(int(gt[1]), 0), ArenaLayout.F.NONE)
		layout.set_f(Vector2i(int(gt[1]) + 1, 0), ArenaLayout.F.NONE)
	var door: Array = data["route_door"]
	layout.set_f(Vector2i(int(door[0]) + 1, int(door[1])), ArenaLayout.F.NONE)
	stage = Node2D.new()
	stage.y_sort_enabled = true
	view = ArenaView.new().setup(layout, "hall", stage)
	add_child(view)
	add_child(stage)
	var deco := HallDecor.new().setup(self)
	stage.add_child(deco)
	return self


func spot(key: String) -> Vector2:
	var a: Array = data[key]
	return layout.center_of(Vector2i(int(a[0]), int(a[1])))


func gate_spot(i: int) -> Vector2:
	return layout.center_of(Vector2i(int(data["gates"][i][1]), 0)) + Vector2(layout.cell * 0.5, 0)


func tier_id() -> String:
	return TIERS[tier]


func door_spot() -> Vector2:
	return spot("route_door") + Vector2(layout.cell, 0)


func _process(_delta: float) -> void:
	if g.area != "hall" or g.transition.busy or g.battle.on:
		return
	var tr: Vector2 = g.trainer.global_position
	var near: float = USE_RANGE * 0.7
	for i: int in data["gates"].size():
		if tr.distance_to(gate_spot(i)) < near:
			if _armed:
				_armed = false
				_through_gate(String(data["gates"][i][0]))
			return
	if tr.distance_to(door_spot()) < near:
		if _armed:
			_armed = false
			g.go_route()
		return
	_armed = true


## Through a gate: a battle in that arena against the opponent the lever and switch say.
func _through_gate(arena_id: String) -> void:
	var level: int = g.team.current().level if g.team.current() != null else 5
	if trainer_battle:
		var t := OpponentTrainer.new().setup(TamerData.rule("battle.trainers.hall"), level, tier_id())
		g.battle.start_trainer(t, arena_id)
	else:
		var kinds: Array = TamerData.rule("battle.wild_species")
		g.battle.start_wild(CreatureRecord.make(String(kinds[randi() % kinds.size()]), level, true), arena_id, tier_id())


## F next to something: the lever, the switch, the team station or the lens stand.
func use_nearby() -> bool:
	var tr: Vector2 = g.trainer.global_position
	if tr.distance_to(spot("lever")) < USE_RANGE:
		tier = (tier + 1) % TIERS.size()
		g.hud.notice("Opponents: %s" % tier_id().capitalize())
	elif tr.distance_to(spot("switch")) < USE_RANGE:
		trainer_battle = not trainer_battle
		g.hud.notice("Opponent: %s" % ("a trainer, 3v3" if trainer_battle else "a wild creature, 1v1"))
	elif tr.distance_to(spot("station")) < USE_RANGE:
		g.hud.station.open()
	elif tr.distance_to(spot("lens")) < USE_RANGE:
		g.lens.tier = "plus" if g.lens.tier == "basic" else "basic"
		g.hud.notice("%s equipped" % TamerData.rule("sync.lenses." + g.lens.tier + ".name"))
	else:
		return false
	Audio.sfx("ui_click", -6.0)
	used.emit("hall")
	return true
