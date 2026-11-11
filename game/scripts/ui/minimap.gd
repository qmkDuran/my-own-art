class_name Minimap
extends Control
## The zone at one pixel per cell, top-right, revealed as you explore (fog of war): you, the camera view, enemies
## near you, waylamps (lit or not), unopened chests, people, the boss. Never covered by panels on the right.

const W: float = 150.0
const H: float = 96.0
const TOP: float = 20.0
const EDGE: float = 8.0
const REVEAL: int = 9
const ENEMY_RANGE: float = 700.0
const COLORS: Dictionary = {0: "moss_dk", 1: "moss_lt", 2: "earth_lt", 3: "glass", 4: "earth", 5: "stone_lt", 6: "stone"}

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
			_base.set_pixel(x, y, Pal.c(COLORS[z.t(Vector2i(x, y))]))
	_shown = Image.create(z.cols, z.rows, false, Image.FORMAT_RGBA8)
	_shown.fill(Color(0, 0, 0, 0.0))
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


func _p(world: Vector2) -> Vector2:
	return world / float(g.layout.cell)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	UiDraw.box(self, r.grow(2.0), Color(0.02, 0.02, 0.04, 0.9))
	draw_texture_rect(_tex, r, false)
	UiDraw.text(self, Vector2(0, -6), String(GameData.biome["name"]), UiDraw.GOLD, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, W)
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		_marker(n as Interactable)
	var me: Vector2 = g.player.global_position
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.global_position.distance_to(me) < ENEMY_RANGE or e.rank == "boss":
			var col: Color = Pal.c("violet_lt") if e.rank == "boss" else (Pal.c("flame") if e.rank != "normal" else Pal.c("rose"))
			draw_rect(Rect2(_p(e.global_position) - Vector2(0.5, 0.5), Vector2(2, 2) if e.rank != "normal" else Vector2(1, 1)), col)
	var view: Vector2 = get_viewport_rect().size / g.camera.zoom
	draw_rect(Rect2(_p(g.camera.get_screen_center_position() - view / 2.0), view / float(g.layout.cell)), Color(1, 1, 1, 0.3), false, 1.0)
	draw_rect(Rect2(_p(me) - Vector2(1.5, 1.5), Vector2(3, 3)), Color.WHITE)


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
	draw_rect(Rect2(_p(it.global_position) - Vector2(1, 1), Vector2(3, 3)), col)
