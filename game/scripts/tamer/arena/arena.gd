class_name Arena
extends Node2D
## One battle arena, built from data/tamer/arenas.json at `origin` (away from the route) in a size (medium or large:
## the layout is scaled to fit): a square walled ArenaLayout, its view, a y-sorted stage for the creatures, and fog
## if it has any. The trainers watch from outside its left and right walls. Moves change it through affect() and
## grow_vine() (TerrainChange).

const TRAINER_OUT: float = 26.0         ## how far outside the wall the trainers stand

var id: String
var data: Dictionary
var layout: ArenaLayout
var view: ArenaView
var stage: Node2D
var fog: ArenaFog
var change: TerrainChange
var _scale := Vector2.ONE               ## this size over the size the arena was drawn for


func build(arena_id: String, at: Vector2, size_id: String = "medium") -> Arena:
	id = arena_id
	data = TamerData.arenas["arenas"][arena_id]
	var A: Dictionary = TamerData.arenas
	var sz: Array = A["sizes"][size_id]
	_scale = Vector2(float(sz[0]) / float(A["cols"]), float(sz[1]) / float(A["rows"]))
	layout = ArenaLayout.new().build(int(sz[0]), int(sz[1]), int(A["cell"]), at)
	var life: Dictionary = data.get("life", {})
	for p: Array in data["paint"]:
		layout.paint(String(p[0]), _scaled(p[1]), float(life.get(String(p[0]), 0.0)))
	change = TerrainChange.new(self)
	stage = Node2D.new()
	stage.y_sort_enabled = true
	view = ArenaView.new().setup(layout, String(data["style"]), stage)
	add_child(view)
	add_child(stage)
	if bool(data.get("fog", false)):
		fog = ArenaFog.new().setup(layout)
		add_child(fog)
	return self


## A painted rectangle [x, y, w, h] in this size's cells (features keep at least one cell).
func _scaled(r: Array) -> Array:
	return [roundi(float(r[0]) * _scale.x), roundi(float(r[1]) * _scale.y),
		maxi(1, roundi(float(r[2]) * _scale.x)), maxi(1, roundi(float(r[3]) * _scale.y))]


func _cell(spot: Array) -> Vector2i:
	return Vector2i(roundi(float(spot[0]) * _scale.x), roundi(float(spot[1]) * _scale.y))


func display_name() -> String:
	return String(data["name"])


func center() -> Vector2:
	return layout.rect_px().get_center()


func you_spot() -> Vector2:
	return layout.center_of(_cell(data["you"]))


func foe_spot() -> Vector2:
	return layout.center_of(_cell(data["foe"]))


## Your trainer stands just outside the left wall, the opposing trainer outside the right one.
func trainer_spot(yours: bool) -> Vector2:
	var r: Rect2 = layout.rect_px()
	return Vector2(r.position.x - TRAINER_OUT if yours else r.end.x + TRAINER_OUT, r.get_center().y + layout.cell)


func _process(delta: float) -> void:
	if change.tick(delta):
		view.refresh()


## A move lands on the ground at `at` (radius `r`): a local patch changes by its element and weight (TerrainChange);
## Gale also blows fog away and Echo shows who was hiding.
func affect(at: Vector2, r: float, m: Dictionary, heavy: bool) -> void:
	var changed: bool = false
	var a: Vector2i = layout.cell_of(at - Vector2(r, r))
	var b: Vector2i = layout.cell_of(at + Vector2(r, r))
	for y: int in range(a.y, b.y + 1):
		for x: int in range(a.x, b.x + 1):
			var c := Vector2i(x, y)
			if layout.inside(c) and layout.center_of(c).distance_to(at) <= r + layout.cell * 0.5:
				changed = change.apply(c, m, heavy) or changed
	if bool(m.get("gale", false)) and fog != null:
		fog.clear_around(at, r * 2.0)
	if bool(m.get("echo", false)):
		for n: Node in get_tree().get_nodes_in_group("creatures"):
			if (n as Creature).global_position.distance_to(at) < r * 2.0:
				(n as Creature).reveal_t = float(TamerData.rule("terrain.reveal_time")) * 2.0
	if changed:
		view.refresh()


func grow_vine(at: Vector2, seconds: float, life: float) -> void:
	var c: Vector2i = layout.cell_of(at)
	if not layout.inside(c) or layout.blocked[layout.idx(c)] == 1:
		return
	for n: Node in get_tree().get_nodes_in_group("creatures"):
		if layout.cell_of((n as Creature).global_position) == c:
			return                                       # never grows on top of anyone
	layout.set_temporary(c, ArenaLayout.F.VINE, seconds, life)
	view.refresh()
