class_name Arena
extends Node2D
## One battle arena, built from data/tamer/arenas.json at `origin` (away from the route): a square walled ArenaLayout,
## its view, a y-sorted stage for the creatures, and fog if it has any. The trainers watch from outside its left and
## right walls. Moves change it through affect() and grow_vine().

const TRAINER_OUT: float = 26.0         ## how far outside the wall the trainers stand
const ROCK_LIFE: float = 70.0

var id: String
var data: Dictionary
var layout: ArenaLayout
var view: ArenaView
var stage: Node2D
var fog: ArenaFog


func build(arena_id: String, at: Vector2) -> Arena:
	id = arena_id
	data = TamerData.arenas["arenas"][arena_id]
	var A: Dictionary = TamerData.arenas
	layout = ArenaLayout.new().build(int(A["cols"]), int(A["rows"]), int(A["cell"]), at)
	var life: Dictionary = data.get("life", {})
	for p: Array in data["paint"]:
		layout.paint(String(p[0]), p[1], float(life.get(String(p[0]), 0.0)))
	stage = Node2D.new()
	stage.y_sort_enabled = true
	view = ArenaView.new().setup(layout, String(data["style"]), stage)
	add_child(view)
	add_child(stage)
	if bool(data.get("fog", false)):
		fog = ArenaFog.new().setup(layout)
		add_child(fog)
	return self


func display_name() -> String:
	return String(data["name"])


func center() -> Vector2:
	return layout.rect_px().get_center()


func you_spot() -> Vector2:
	return layout.center_of(Vector2i(int(data["you"][0]), int(data["you"][1])))


func foe_spot() -> Vector2:
	return layout.center_of(Vector2i(int(data["foe"][0]), int(data["foe"][1])))


## Your trainer stands just outside the left wall, the opposing trainer outside the right one.
func trainer_spot(yours: bool) -> Vector2:
	var r: Rect2 = layout.rect_px()
	return Vector2(r.position.x - TRAINER_OUT if yours else r.end.x + TRAINER_OUT, r.get_center().y + layout.cell)


## A move hits the ground: Ember burns grass and vines into coals, Gale flattens grass and clears fog, Echo shatters
## rocks, and heavy hits wear down rocks, bridges and cracked floor.
func affect(at: Vector2, r: float, burns: bool, gale: bool, echo: bool, heavy: bool) -> void:
	var changed: bool = false
	var a: Vector2i = layout.cell_of(at - Vector2(r, r))
	var b: Vector2i = layout.cell_of(at + Vector2(r, r))
	for y: int in range(a.y, b.y + 1):
		for x: int in range(a.x, b.x + 1):
			var c := Vector2i(x, y)
			if layout.inside(c) and layout.center_of(c).distance_to(at) <= r + layout.cell * 0.5:
				changed = _affect_cell(c, burns, gale, echo, heavy) or changed
	if gale and fog != null:
		fog.clear_around(at, r * 2.0)
	if echo:
		for n: Node in get_tree().get_nodes_in_group("creatures"):
			if (n as Creature).global_position.distance_to(at) < r * 2.0:
				(n as Creature).reveal_t = float(TamerData.rule("terrain.reveal_time")) * 2.0
	if changed:
		view.refresh()


func _affect_cell(c: Vector2i, burns: bool, gale: bool, echo: bool, heavy: bool) -> bool:
	var f: int = layout.f(c)
	var T: Dictionary = TamerData.rule("terrain")
	if burns and (f == ArenaLayout.F.GRASS or f == ArenaLayout.F.VINE or f == ArenaLayout.F.FLAT):
		layout.set_temporary(c, ArenaLayout.F.COALS, float(T["coals_time"]))
		return true
	if gale and f == ArenaLayout.F.GRASS:
		layout.set_f(c, ArenaLayout.F.FLAT)
		return true
	if (heavy or echo) and [ArenaLayout.F.ROCK, ArenaLayout.F.BRIDGE, ArenaLayout.F.CRACKED, ArenaLayout.F.VINE].has(f):
		return _wear(c, f, ROCK_LIFE if echo else float(T["heavy_hit"]))
	return false


## Breakable things lose life; at zero a rock is rubble, a bridge falls into the channel, a cracked floor caves in.
func _wear(c: Vector2i, f: int, amount: float) -> bool:
	var i: int = layout.idx(c)
	layout.hp[i] -= amount
	if layout.hp[i] > 0.0:
		return false
	var into: int = ArenaLayout.F.NONE
	if f == ArenaLayout.F.BRIDGE or f == ArenaLayout.F.CRACKED:
		into = ArenaLayout.F.DEEP
	layout.timer[i] = 0.0
	layout.set_f(c, into)
	Fx.burst(TamerGame.current.fx_layer, layout.center_of(c), 16, Vector2(40, 140), 0.5, [Pal.c("stone_lt"), Pal.c("stone"), Pal.c("stone_dk", 0.0)], Vector2.UP)
	Audio.sfx("crack", -6.0)
	_drop_into(c, into)
	return true


## Whoever stood on a bridge or floor that gave way falls: damage, then out on the nearest solid ground.
func _drop_into(c: Vector2i, into: int) -> void:
	if into != ArenaLayout.F.DEEP:
		return
	for n: Node in get_tree().get_nodes_in_group("creatures"):
		var cr := n as Creature
		if layout.cell_of(cr.global_position) == c:
			cr.take_terrain_damage(float(TamerData.rule("terrain.fall_damage")) * 2.0, "Fell in!")
			cr.global_position = layout.free_spot_near(cr.global_position, cr.hit_radius())


func grow_vine(at: Vector2, seconds: float, life: float) -> void:
	var c: Vector2i = layout.cell_of(at)
	if not layout.inside(c) or layout.blocked[layout.idx(c)] == 1:
		return
	for n: Node in get_tree().get_nodes_in_group("creatures"):
		if layout.cell_of((n as Creature).global_position) == c:
			return                                       # never grows on top of anyone
	layout.set_temporary(c, ArenaLayout.F.VINE, seconds, life)
	view.refresh()
