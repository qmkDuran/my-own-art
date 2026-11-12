class_name ArenaView
extends Node2D
## Draws an ArenaLayout: the ground cell by cell in the arena's style (grass, water, mud, ledge, coals...), the
## standing things as sprites y-sorted with the creatures (tall grass, rocks, trees or pillars, vines), the stone
## wall around it, and one static body that matches what blocks movement. refresh() redraws after a change.

const GROUND_Z: int = -20
const TUFTS: int = 2
const WALL_H: float = 10.0

var a: ArenaLayout
var style: String = "meadow"
var stage: Node2D                       ## the y-sorted root standing sprites go in
var body: StaticBody2D
var _standing: Array[Node2D] = []
var _t: float = 0.0


func setup(layout: ArenaLayout, arena_style: String, root: Node2D) -> ArenaView:
	a = layout
	style = arena_style
	stage = root
	z_index = GROUND_Z
	z_as_relative = false
	body = StaticBody2D.new()
	body.collision_layer = Combatant.WORLD_MASK
	add_child(body)
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
	if a.tick(delta):
		refresh()
	else:
		queue_redraw()                                     # water shimmers, coals glow


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
	match f:
		ArenaLayout.F.SHALLOW, ArenaLayout.F.DEEP:
			var shine: float = sin(_t * 2.0 + c.x * 0.7 + c.y * 1.3)
			draw_rect(Rect2(r.position + Vector2(6 + shine * 3.0, 10), Vector2(10, 2)), Pal.c("sea_lt", 0.6))
		ArenaLayout.F.COALS:
			draw_rect(Rect2(r.position + Vector2(8, 8), Vector2(3, 3)), Pal.c("flame") if int(_t * 4.0 + c.x) % 2 == 0 else Pal.c("gold"))
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
