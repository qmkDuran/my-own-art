class_name Minimap
extends Control
## A local map, top-right: the explored ground around you at two pixels per cell (fog of war beyond), you as an
## arrow, enemies near you, waylamps (lit or not), unopened chests, people, and the objective (pinned to the edge
## when it lies beyond the map). Never covered by panels on the right.

const W: float = 150.0
const H: float = 96.0
const TOP: float = 20.0
const EDGE: float = 8.0
const REVEAL: int = 15
const ENEMY_RANGE: float = 700.0
const COLORS: Dictionary = {0: "", 1: "moss_lt", 2: "amber", 3: "glass_lt", 4: "earth_lt", 5: "pale", 6: "stone"}
const FOG := Color(0.05, 0.05, 0.08, 0.85)
const ARROW: float = 4.0
const ZOOM: float = 2.0

var g: Game
var _base: Image
var _shown: Image
var _tex: ImageTexture
var _seen: PackedByteArray
var _last_cell := Vector2i(-99, -99)


static func rect_for(vs: Vector2) -> Rect2:
	return Rect2(vs.x - EDGE - W, TOP, W, H)


func setup(game: Game) -> void:
	g = game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var z: ZoneLayout = g.layout
	_base = Image.create(z.cols, z.rows, false, Image.FORMAT_RGBA8)
	for y: int in z.rows:
		for x: int in z.cols:
			var name: String = COLORS[z.t(Vector2i(x, y))]
			_base.set_pixel(x, y, Pal.c(name, 0.9) if name != "" else Color(Pal.c("moss_dk"), 0.55))
	_shown = Image.create(z.cols, z.rows, false, Image.FORMAT_RGBA8)
	_shown.fill(FOG)
	_seen = PackedByteArray()
	_seen.resize(z.cols * z.rows)
	_tex = ImageTexture.create_from_image(_shown)


func reveal_all() -> void:
	_seen.fill(1)
	_shown.copy_from(_base)
	_tex.update(_shown)


func _process(_delta: float) -> void:
	var r: Rect2 = rect_for(get_viewport_rect().size)
	position = r.position
	size = r.size
	var c: Vector2i = g.layout.cell_of(g.player.global_position)
	if c.distance_to(_last_cell) >= 1.0:
		_last_cell = c
		_reveal(c)
	queue_redraw()


func _reveal(c: Vector2i) -> void:
	var z: ZoneLayout = g.layout
	var changed: bool = false
	for y: int in range(c.y - REVEAL, c.y + REVEAL + 1):
		for x: int in range(c.x - REVEAL, c.x + REVEAL + 1):
			var q := Vector2i(x, y)
			if z.inside(q) and _seen[z.idx(q)] == 0 and Vector2(q - c).length() <= REVEAL:
				_seen[z.idx(q)] = 1
				_shown.set_pixelv(q, _base.get_pixelv(q))
				changed = true
	if changed:
		_tex.update(_shown)


## Cell at the map's top-left corner (the map is centred on the Lamplighter).
func _origin() -> Vector2:
	return g.player.global_position / float(g.layout.cell) - size / ZOOM / 2.0


func _p(world: Vector2) -> Vector2:
	return (world / float(g.layout.cell) - _origin()) * ZOOM


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	UiDraw.box(self, r.grow(2.0), Color(0.02, 0.02, 0.04, 0.9))
	draw_rect(r, FOG)
	var src: Rect2 = Rect2(_origin(), size / ZOOM).intersection(Rect2(Vector2.ZERO, Vector2(g.layout.cols, g.layout.rows)))
	if src.size.x > 0.0 and src.size.y > 0.0:
		draw_texture_rect_region(_tex, Rect2((src.position - _origin()) * ZOOM, src.size * ZOOM), src)
	UiDraw.text(self, Vector2(0, -6), String(GameData.biome["name"]), UiDraw.GOLD, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, W)
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		_marker(n as Interactable)
	var me: Vector2 = g.player.global_position
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.global_position.distance_to(me) < ENEMY_RANGE or e.rank == "boss":
			var col: Color = Pal.c("violet_lt") if e.rank == "boss" else (Pal.c("flame") if e.rank != "normal" else Pal.c("rose"))
			if r_has(_p(e.global_position)):
				draw_rect(Rect2(_p(e.global_position) - Vector2(1, 1), Vector2(3, 3) if e.rank != "normal" else Vector2(2, 2)), col)
	var view: Vector2 = get_viewport_rect().size / g.camera.zoom
	draw_rect(Rect2(_p(g.camera.get_screen_center_position() - view / 2.0), view / float(g.layout.cell) * ZOOM), Color(1, 1, 1, 0.25), false, 1.0)
	_objective()
	_arrow(_p(me), g.player.aim)


## You: a small white arrow pointing where you face.
func _arrow(at: Vector2, dir: Vector2) -> void:
	var d: Vector2 = dir if dir != Vector2.ZERO else Vector2.DOWN
	var pts := PackedVector2Array([at + d * ARROW, at + d.rotated(2.5) * ARROW * 0.8, at + d.rotated(-2.5) * ARROW * 0.8])
	draw_colored_polygon(pts, Color.WHITE)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), UiDraw.INK, 1.0)


## Where the story wants you: a pulsing gold diamond.
func _objective() -> void:
	var t: Vector2 = Objectives.target(g)
	if t == Vector2.INF:
		return
	var c: Vector2 = _p(t).clamp(Vector2(4, 4), size - Vector2(4, 4))
	var k: float = 3.0 + sin(Time.get_ticks_msec() / 200.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k, 0), c + Vector2(0, k), c + Vector2(-k, 0)]), Pal.c("gold"))


func _marker(it: Interactable) -> void:
	var c: Vector2i = g.layout.cell_of(it.global_position)
	if not g.layout.inside(c) or _seen[g.layout.idx(c)] == 0:
		return
	var col: Color
	if it is Waylamp:
		col = Pal.c("gold") if (it as Waylamp).lit else Pal.c("mist")
	elif it is Chest:
		if (it as Chest).opened:
			return
		col = Pal.c("amber")
	elif it is Npc:
		col = Color("8fdc6a")
	else:
		return
	if r_has(_p(it.global_position)):
		draw_rect(Rect2(_p(it.global_position) - Vector2(2, 2), Vector2(4, 4)), col)


func r_has(p: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(p)
