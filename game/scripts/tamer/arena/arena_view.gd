class_name ArenaView
extends Node2D
## Draws an ArenaLayout: the ground cell by cell in the arena's style (grass, water, mud, ledge...) with each
## changed state distinct (flickering flames, ash, a black burnt field, rubble, a pit, cracks), the standing things
## as sprites y-sorted with the creatures (tall grass, rocks, trees or pillars, vines), smoke over ash drawn above
## everyone (it hides them), the stone wall around it, and one static body that matches what blocks movement.
## refresh() rebuilds after a change.

const GROUND_Z: int = -20
const TUFTS: int = 2
const WALL_H: float = 10.0
const SMOKE_Z: int = 40
const FLAMES: int = 3
const PUFFS: int = 3

var a: ArenaLayout
var style: String = "meadow"
var stage: Node2D                       ## the y-sorted root standing sprites go in
var body: StaticBody2D
var _standing: Array[Node2D] = []
var _t: float = 0.0
var _smoke := Node2D.new()


func setup(layout: ArenaLayout, arena_style: String, root: Node2D) -> ArenaView:
	a = layout
	style = arena_style
	stage = root
	z_index = GROUND_Z
	z_as_relative = false
	body = StaticBody2D.new()
	body.collision_layer = Combatant.WORLD_MASK
	add_child(body)
	_smoke.z_index = SMOKE_Z
	_smoke.z_as_relative = false
	_smoke.draw.connect(_draw_smoke)
	add_child(_smoke)
	refresh()
	return self


func refresh() -> void:
	for n: Node2D in _standing:
		n.queue_free()
	_standing.clear()
	for y: int in a.rows:
		for x: int in a.cols:
			_stand(Vector2i(x, y))
	_collision()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()                                         # water shimmers, flames flicker, smoke drifts
	_smoke.queue_redraw()


## Sprites for what stands up (y-sorted with the creatures).
func _stand(c: Vector2i) -> void:
	var at: Vector2 = a.center_of(c) + Vector2(0, a.cell * 0.4)
	match a.f(c):
		ArenaLayout.F.GRASS:
			for k: int in TUFTS:
				_sprite(PropSprite.make("tall_grass", (c.x + c.y + k) % 3), at + Vector2((k - 0.5) * 14.0, -k * 8.0))
		ArenaLayout.F.ROCK:
			_sprite(PropSprite.make("rock_a"), at)
		ArenaLayout.F.TREE:
			if style == "ruins":
				_sprite(_pillar(), at)
			else:
				_sprite(PropSprite.make("tree_leafy_b"), at)
		ArenaLayout.F.THORNS:
			_sprite(PropSprite.make("tall_grass", 2), at).modulate = Pal.c("rust")


func _sprite(s: Node2D, at: Vector2) -> Node2D:
	s.position = at
	stage.add_child(s)
	_standing.append(s)
	return s


func _pillar() -> Node2D:
	var n := Node2D.new()
	n.draw.connect(func() -> void:
		n.draw_rect(Rect2(-12, -56, 24, 56), Pal.c("stone"))
		n.draw_rect(Rect2(-12, -56, 6, 56), Pal.c("stone_lt"))
		n.draw_rect(Rect2(-14, -60, 28, 6), Pal.c("stone_lt"))
		n.draw_rect(Rect2(-12, -56, 24, 56), Pal.c("void"), false, 1.0))
	return n


func _collision() -> void:
	for ch: Node in body.get_children():
		ch.queue_free()
	for y: int in a.rows:
		for x: int in a.cols:
			var c := Vector2i(x, y)
			if a.blocked[a.idx(c)] == 1:
				var cs := CollisionShape2D.new()
				var r := RectangleShape2D.new()
				r.size = Vector2(a.cell, a.cell)
				cs.shape = r
				cs.position = a.center_of(c)
				body.add_child(cs)


func _draw() -> void:
	for y: int in a.rows:
		for x: int in a.cols:
			_ground(Vector2i(x, y))


func _ground(c: Vector2i) -> void:
	var r: Rect2 = a.cell_rect(c)
	var base: Color = ArenaPalette.ground(style, (c.x * 7 + c.y * 13) % 5 == 0)
	draw_rect(r, base)
	var f: int = a.f(c)
	var col: Color = ArenaPalette.feature(f, style)
	if col.a > 0.0:
		draw_rect(r, col)
	if _changed(r, c, f):
		return
	match f:
		ArenaLayout.F.SHALLOW, ArenaLayout.F.DEEP:
			var shine: float = sin(_t * 2.0 + c.x * 0.7 + c.y * 1.3)
			draw_rect(Rect2(r.position + Vector2(6 + shine * 3.0, 10), Vector2(10, 2)), Pal.c("sea_lt", 0.6))
		ArenaLayout.F.LEDGE:
			if a.f(c + Vector2i(0, 1)) != ArenaLayout.F.LEDGE:
				draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 6)), Pal.c("stone_dk"))
		ArenaLayout.F.WALL:
			draw_rect(Rect2(r.position - Vector2(0, WALL_H), Vector2(r.size.x, r.size.y)), Pal.c("stone_lt"))
			draw_rect(Rect2(r.position - Vector2(0, WALL_H), Vector2(r.size.x, r.size.y)), Pal.c("void"), false, 1.0)
		ArenaLayout.F.RAMP:
			for k: int in 3:
				draw_line(r.position + Vector2(2, 8 + k * 8), r.position + Vector2(r.size.x - 2, 8 + k * 8), Pal.c("stone_dk"), 2.0)
		ArenaLayout.F.CRACKED:
			draw_line(r.position + Vector2(4, 6), r.position + Vector2(20, 24), Pal.c("void"), 1.0)
			draw_line(r.position + Vector2(20, 24), r.position + Vector2(28, 14), Pal.c("void"), 1.0)
		ArenaLayout.F.BRIDGE:
			for k: int in 4:
				draw_line(r.position + Vector2(0, 4 + k * 8), r.position + Vector2(r.size.x, 4 + k * 8), Pal.c("earth_dk"), 1.0)
		ArenaLayout.F.VINE:
			draw_rect(r.grow(-2.0), Pal.c("leaf_dk"))
			draw_line(r.position + Vector2(6, 2), r.position + Vector2(10, 30), Pal.c("leaf_lt"), 2.0)
			draw_line(r.position + Vector2(22, 2), r.position + Vector2(18, 30), Pal.c("leaf_lt"), 2.0)


## The states destroyed terrain passes through, each its own look: flames, ash, burnt ground, rubble, a pit.
func _changed(r: Rect2, c: Vector2i, f: int) -> bool:
	match f:
		ArenaLayout.F.COALS:
			_flames(r, c)
		ArenaLayout.F.BURNT, ArenaLayout.F.ASH:
			for k: int in 3:
				draw_rect(Rect2(r.position + Vector2(5 + k * 9, 8 + (k * 11) % 16), Vector2(2, 2)), Pal.c("ember_dk"))
		ArenaLayout.F.RUBBLE:
			for k: int in 4:
				var p: Vector2 = r.position + Vector2(5 + (k * 13) % 22, 6 + (k * 7) % 20)
				draw_rect(Rect2(p, Vector2(6, 4)), Pal.c("stone_lt"))
				draw_rect(Rect2(p + Vector2(0, 3), Vector2(6, 1)), Pal.c("stone_dk"))
		ArenaLayout.F.PIT:
			draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Pal.c("stone_dk"))
			draw_rect(Rect2(r.position + Vector2(3, 6), r.size - Vector2(6, 9)), Pal.c("ink"))
		_:
			return false
	return true


## Burning grass: tongues of flame that flicker, over glowing ground.
func _flames(r: Rect2, c: Vector2i) -> void:
	draw_rect(r.grow(-3.0), Pal.c("ember", 0.5))
	for k: int in FLAMES:
		var x: float = r.position.x + 6.0 + k * 9.0
		var h: float = 10.0 + 6.0 * sin(_t * 11.0 + c.x * 1.7 + c.y * 2.3 + k * 2.1)
		var base: float = r.end.y - 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, base), Vector2(x + 4, base), Vector2(x, base - h)]), Pal.c("flame"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 2, base), Vector2(x + 2, base), Vector2(x, base - h * 0.6)]), Pal.c("sun"))


## Smoke over ash, above everyone: whoever stands in it can't be seen.
func _draw_smoke() -> void:
	for y: int in a.rows:
		for x: int in a.cols:
			var c := Vector2i(x, y)
			if a.f(c) != ArenaLayout.F.ASH:
				continue
			var at: Vector2 = a.center_of(c)
			for k: int in PUFFS:
				var drift: float = fmod(_t * 8.0 + k * 11.0 + x * 5.0, 30.0)
				_smoke.draw_circle(at + Vector2(sin(_t + k * 2.0 + y) * 6.0, -drift), 12.0 - drift * 0.15, Pal.c("mist", 0.55))
