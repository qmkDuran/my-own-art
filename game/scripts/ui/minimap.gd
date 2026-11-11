class_name Minimap
extends Control
## A local map, top-right: the explored ground around you at two pixels per cell (fog of war beyond), you as an
## arrow, enemies near you, waylamps (lit or not), unopened chests, people, and the objective (pinned to the edge
## when it lies beyond the map). Never covered by panels on the right. M swaps it for the whole-zone map; Tab lays a
## see-through map over the game itself, centred on you, that never takes the mouse (shift+scroll or the Esc menu
## sets how solid it is).

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
const LARGE_MARGIN: float = 40.0
const OVERLAY_ZOOM: float = 3.0      ## the overlay is a small map laid over the view, not a 1:1 trace
const OVERLAY_ALPHA: float = 0.6      ## default opacity of the Tab overlay
const OVERLAY_MIN: float = 0.15
const OVERLAY_MAX: float = 0.9
const OVERLAY_SCROLL: float = 0.05
const CLEAR := Color(0, 0, 0, 0)
const OVERLAY_FILL: float = 0.3      ## the overlay's ground wash, under its bright edges
const OVERLAY_EDGE := Color(0.72, 0.86, 1.0)   ## edges: a cool pale blue, readable on warm and cold ground
const OVERLAY_ARROW: float = 9.0

var g: Game
var _base: Image
var _shown: Image
var _tex: ImageTexture
var _lines_base: Image                 ## the overlay's look: bright edges of walkable ground, faint inside
var _lines: Image
var _lines_tex: ImageTexture
var _seen: PackedByteArray
var _last_cell := Vector2i(-99, -99)


static var large: bool = false        ## M: the map at its large size, centred
static var overlay: bool = false      ## Tab: the see-through map laid over the game


static func overlay_alpha() -> float:
	return float(GameData.setting("map_overlay", OVERLAY_ALPHA))


static func nudge_overlay(step: float) -> void:
	GameData.settings["map_overlay"] = clampf(overlay_alpha() + step, OVERLAY_MIN, OVERLAY_MAX)


static func rect_for(vs: Vector2) -> Rect2:
	if overlay and not large:                             # the overlay: the whole screen above the orbs
		return Rect2(Vector2.ZERO, vs - Vector2(0, Hud.ORB))
	if large:                                             # the zone map: most of the screen
		return Rect2(Vector2(LARGE_MARGIN, LARGE_MARGIN), vs - Vector2(LARGE_MARGIN * 2.0, LARGE_MARGIN * 2.0 + Hud.ORB))
	return Rect2(vs.x - EDGE - W, TOP, W, H)


## Pixels per cell: the minimap's fixed zoom, or, as the zone map, whatever fits the whole zone.
func _zoom() -> float:
	if overlay and not large:
		return OVERLAY_ZOOM
	if not large:
		return ZOOM
	return minf(size.x / g.layout.cols, size.y / g.layout.rows)


func toggle_large() -> void:
	large = not large
	Audio.sfx("ui_open", -8.0)


func toggle_overlay() -> void:
	overlay = not overlay
	large = false
	Audio.sfx("ui_click", -10.0)


## Shift+scroll while the overlay is up makes it more or less solid (the mouse is otherwise left to the game).
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if not overlay or large or mb == null or not mb.pressed or not mb.shift_pressed:
		return
	if mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		nudge_overlay(OVERLAY_SCROLL if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -OVERLAY_SCROLL)
		get_viewport().set_input_as_handled()


func setup(game: Game) -> void:
	g = game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var z: ZoneLayout = g.layout
	_base = Image.create(z.cols, z.rows, false, Image.FORMAT_RGBA8)
	for y: int in z.rows:
		for x: int in z.cols:
			var name: String = COLORS[z.t(Vector2i(x, y))]
			_base.set_pixel(x, y, Pal.c(name, 0.9) if name != "" else Color(Pal.c("moss_dk"), 0.55))
	_lines_base = _outline(z)
	_shown = Image.create(z.cols, z.rows, false, Image.FORMAT_RGBA8)
	_shown.fill(CLEAR)
	_lines = _shown.duplicate()
	_seen = PackedByteArray()
	_seen.resize(z.cols * z.rows)
	_tex = ImageTexture.create_from_image(_shown)
	_lines_tex = ImageTexture.create_from_image(_lines)


## Edges of the ground you can walk (where it meets wall, tree or water's edge) drawn bright; the ground itself a
## faint wash of its colour. Over the game this reads as a map without hiding what is under it.
func _outline(z: ZoneLayout) -> Image:
	var img := Image.create(z.cols, z.rows, false, Image.FORMAT_RGBA8)
	for y: int in z.rows:
		for x: int in z.cols:
			var name: String = COLORS[z.t(Vector2i(x, y))]
			if name == "":
				continue
			var edge: bool = false
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(1, 1), Vector2i(-1, 1),
					Vector2i(1, -1), Vector2i(-1, -1)]:
				var q := Vector2i(x, y) + d
				edge = edge or not z.inside(q) or COLORS[z.t(q)] == ""
			img.set_pixel(x, y, OVERLAY_EDGE if edge else Pal.c(name, OVERLAY_FILL))
	return img


func reveal_all() -> void:
	_seen.fill(1)
	_shown.copy_from(_base)
	_lines.copy_from(_lines_base)
	_tex.update(_shown)
	_lines_tex.update(_lines)


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
				_lines.set_pixelv(q, _lines_base.get_pixelv(q))
				changed = true
	if changed:
		_tex.update(_shown)
		_lines_tex.update(_lines)


## Cell at the map's top-left corner (the map is centred on the Lamplighter).
func _origin() -> Vector2:
	if large:                                             # the whole zone, centred in the map
		return -(size / _zoom() - Vector2(g.layout.cols, g.layout.rows)) / 2.0
	return g.player.global_position / float(g.layout.cell) - size / _zoom() / 2.0


func _p(world: Vector2) -> Vector2:
	return (world / float(g.layout.cell) - _origin()) * _zoom()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var see_through: bool = overlay and not large
	if not see_through:
		UiDraw.box(self, r.grow(2.0), Color(0.02, 0.02, 0.04, 0.9))
		draw_rect(r, FOG)
	var src: Rect2 = Rect2(_origin(), size / _zoom()).intersection(Rect2(Vector2.ZERO, Vector2(g.layout.cols, g.layout.rows)))
	if src.size.x > 0.0 and src.size.y > 0.0:
		draw_texture_rect_region(_lines_tex if see_through else _tex, Rect2((src.position - _origin()) * _zoom(), src.size * _zoom()), src,
			Color(1, 1, 1, overlay_alpha()) if see_through else Color.WHITE)
	if see_through:
		_overlay_marks()
		return
	UiDraw.text(self, Vector2(0, -6), String(GameData.biome["name"]), UiDraw.GOLD, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, size.x)
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
	draw_rect(Rect2(_p(g.camera.get_screen_center_position() - view / 2.0), view / float(g.layout.cell) * _zoom()), Color(1, 1, 1, 0.25), false, 1.0)
	_objective()
	_arrow(_p(me), g.player.aim)


## Over the game the map keeps only what helps you steer: exits, waylamps, chests, people, the objective and you.
func _overlay_marks() -> void:
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		_marker(n as Interactable)
	_objective()
	var me: Vector2 = _p(g.player.global_position)
	draw_circle(me, OVERLAY_ARROW + 3.0, Color(Pal.c("gold"), 0.35))
	_arrow(me, g.player.aim, OVERLAY_ARROW)


## You: a small white arrow pointing where you face.
func _arrow(at: Vector2, dir: Vector2, size: float = ARROW) -> void:
	var d: Vector2 = dir if dir != Vector2.ZERO else Vector2.DOWN
	var pts := PackedVector2Array([at + d * size, at + d.rotated(2.5) * size * 0.8, at + d.rotated(-2.5) * size * 0.8])
	draw_colored_polygon(pts, Color.WHITE)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), UiDraw.INK, 1.0)


## Where the story wants you: a large pulsing gold diamond with a dark outline and a ring around it.
func _objective() -> void:
	var t: Vector2 = Objectives.target(g)
	if t == Vector2.INF:
		return
	var c: Vector2 = _p(t).clamp(Vector2(6, 6), size - Vector2(6, 6))
	var k: float = 5.0 + 1.5 * sin(Time.get_ticks_msec() / 200.0)
	var pts := PackedVector2Array([c + Vector2(0, -k), c + Vector2(k, 0), c + Vector2(0, k), c + Vector2(-k, 0)])
	draw_colored_polygon(pts, Pal.c("gold"))
	pts.append(pts[0])
	draw_polyline(pts, UiDraw.INK, 1.0)
	draw_arc(c, k + 3.0, 0.0, TAU, 16, Color(Pal.c("gold"), 0.5), 1.0)


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
	elif it is ZoneExit:
		_exit_marker(it as ZoneExit)
		return
	else:
		return
	if r_has(_p(it.global_position)):
		draw_rect(Rect2(_p(it.global_position) - Vector2(2, 2), Vector2(4, 4)), col)


## A way out: a bright door mark, gold when it leads toward the objective, with its destination on the zone map.
func _exit_marker(e: ZoneExit) -> void:
	var at: Vector2 = _p(e.global_position)
	if not r_has(at):
		return
	var toward: bool = Objectives.target(g).distance_to(e.global_position) < 1.0
	var col: Color = Pal.c("gold") if toward else Pal.c("pale")
	draw_rect(Rect2(at - Vector2(3, 4), Vector2(6, 8)), UiDraw.INK)
	draw_rect(Rect2(at - Vector2(2, 3), Vector2(4, 6)), col)
	if large:
		UiDraw.text(self, at + Vector2(-60, -8), String(GameData.zone(e.to)["name"]), col, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, 120.0)


func r_has(p: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(p)
