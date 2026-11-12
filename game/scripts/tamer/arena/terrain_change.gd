class_name TerrainChange
extends RefCounted
## How an arena's ground changes. Destroying terrain changes the fight, never ends it: it costs a move (only moves
## change it), it transforms instead of vanishing, and it stays local. Grass burns (and the fire creeps a few cells
## through grass, hurting anyone in it), then lies as ash and smoke that hide whoever is inside, then a burnt field
## that slows a little, and then regrows. Gale flattens grass (it regrows) and blows smoke away; Bloom regrows grass
## at once. A rock breaks into rubble that trips a dash, a bridge drops whoever is on it into the water, cracked
## floor caves into a pit. Walls, ledges and deep water never break. Every state has its own look and sound.

const F := ArenaLayout.F
const BURNABLE: Array[int] = [F.GRASS, F.FLAT, F.VINE]
const NEIGHBOURS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const ROCK_ECHO: float = 70.0           ## an Echo move shatters a rock in one go

var arena: Arena
var lay: ArenaLayout
var _spread_t: float = 0.0


func _init(a: Arena) -> void:
	arena = a
	lay = a.layout


static func T() -> Dictionary:
	return TamerData.rule("terrain")


static func state(name: String) -> Dictionary:
	return T()["states"][name]


## A move's effect on one cell; returns whether it changed.
func apply(c: Vector2i, m: Dictionary, heavy: bool) -> bool:
	var f: int = lay.f(c)
	if bool(m.get("burns", false)) and BURNABLE.has(f):
		ignite(c, 0)
		return true
	if bool(m.get("blooms", false)) and [F.BURNT, F.FLAT, F.ASH].has(f):
		lay.set_lasting(c, F.GRASS)
		return true
	if bool(m.get("gale", false)) and f == F.GRASS:
		_pass(c, F.FLAT, "flat", false)
		return true
	if bool(m.get("gale", false)) and f == F.ASH:
		_pass(c, F.BURNT, "burnt")
		return true
	if (heavy or bool(m.get("echo", false))) and [F.ROCK, F.BRIDGE, F.CRACKED, F.VINE].has(f):
		return _wear(c, f, ROCK_ECHO if bool(m.get("echo", false)) else float(T()["heavy_hit"]))
	return false


## Fire on a cell; `step` is how far it has crept from where it was lit.
func ignite(c: Vector2i, step: int) -> void:
	lay.set_temporary(c, F.COALS, float(state("coals")["time"]), float(step))
	_sound("coals", c)


func _pass(c: Vector2i, into: int, name: String, chained: bool = true) -> void:
	lay.set_temporary(c, into, float(state(name)["time"]), 0.0, chained)
	_sound(name, c)


## Every frame: passing states move on, and fire creeps into the grass next to it now and then.
func tick(delta: float) -> bool:
	var changed: bool = false
	for c: Vector2i in lay.tick(delta):
		_next(c)
		changed = true
	_spread_t -= delta
	if _spread_t <= 0.0:
		_spread_t = float(T()["spread_every"])
		changed = _spread() or changed
	return changed


## What a passing state becomes when it runs out: fire -> ash -> burnt field -> grass; flattened grass stands up.
func _next(c: Vector2i) -> void:
	var i: int = lay.idx(c)
	var was: int = int(lay.under[i])
	match lay.f(c):
		F.COALS:
			_pass(c, F.ASH, "ash")
		F.ASH:
			if was == F.GRASS or was == F.FLAT:
				_pass(c, F.BURNT, "burnt")
			else:
				lay.set_lasting(c, F.NONE)
		F.BURNT, F.FLAT:
			lay.set_lasting(c, F.GRASS)
		_:
			lay.set_lasting(c, was)


func _spread() -> bool:
	var lit: Array[Vector2i] = []
	for i: int in lay.feature.size():
		if int(lay.feature[i]) == F.COALS and int(lay.hp[i]) < int(T()["spread_steps"]):
			var c := Vector2i(i % lay.cols, i / lay.cols)
			for d: Vector2i in NEIGHBOURS:
				if (lay.f(c + d) == F.GRASS or lay.f(c + d) == F.FLAT) and randf() < float(T()["spread_chance"]):
					lit.append(c + d)
					lay.hp[lay.idx(c + d)] = lay.hp[i] + 1.0
	for c: Vector2i in lit:
		ignite(c, int(lay.hp[lay.idx(c)]))
	return not lit.is_empty()


## Breakable things lose life; at zero a rock is rubble, a bridge drops into the channel, a cracked floor caves in.
func _wear(c: Vector2i, f: int, amount: float) -> bool:
	var i: int = lay.idx(c)
	lay.hp[i] -= amount
	if lay.hp[i] > 0.0:
		return false
	match f:
		F.ROCK:
			lay.set_lasting(c, F.RUBBLE)
			_sound("rubble", c)
		F.BRIDGE:
			lay.set_lasting(c, F.DEEP)
			_sound("water", c)
			_fall(c, "Fell in!", true)
		F.CRACKED:
			lay.set_lasting(c, F.PIT)
			_sound("pit", c)
			_fall(c, "Fell in the pit!", false)
		_:
			lay.set_lasting(c, int(lay.under[i]))
	Fx.burst(TamerGame.current.fx_layer, lay.center_of(c), 16, Vector2(40, 140), 0.5, [Pal.c("stone_lt"), Pal.c("stone"), Pal.c("stone_dk", 0.0)], Vector2.UP)
	return true


## Whoever stood there falls: damage and a short stun (out of the water onto the nearest bank).
func _fall(c: Vector2i, word: String, out: bool) -> void:
	for n: Node in arena.get_tree().get_nodes_in_group("creatures"):
		var cr := n as Creature
		if lay.cell_of(cr.global_position) == c:
			cr.take_terrain_damage(float(T()["pit_damage"]), word)
			cr.stun_t = maxf(cr.stun_t, float(T()["fall_stun"]))
			if out:
				cr.global_position = lay.free_spot_near(cr.global_position, cr.hit_radius())


func _sound(name: String, c: Vector2i) -> void:
	var s: String = String(state(name).get("sound", ""))
	if s != "" and lay.center_of(c).distance_to(TamerGame.current.focus.global_position) < 2000.0:
		Audio.sfx(s, -10.0, randf_range(0.9, 1.1))
