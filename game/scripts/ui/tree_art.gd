class_name TreeArt
extends RefCounted
## The look shared by the skill and passive trees: a deep framed backdrop with a vignette and slowly drifting
## embers (shifted a little with the mouse, for depth), connectors that glow and carry a travelling spark once
## both ends are allocated, node frames by kind (plain, notable with cut corners, keystone with a double gold
## frame and diamond tabs), a glow under the hovered node and a burst of sparks when a point goes in.

const BACK_TOP := Color(0.07, 0.05, 0.09, 0.96)
const BACK_LOW := Color(0.03, 0.025, 0.04, 0.96)
const VIGNETTE_STEPS: int = 10
const VIGNETTE_DEPTH: float = 46.0
const VIGNETTE_ALPHA: float = 0.07
const BAND: int = 12                     ## rows in the backdrop's top-to-bottom gradient
const MOTES: int = 26
const MOTE_SPEED: float = 7.0
const PARALLAX: float = 0.02             ## how far the embers lean with the mouse
const CORNER: float = 9.0
const LINE_DIM := Color(0.36, 0.3, 0.24, 0.55)
const LINE_LIT := Color(1.0, 0.68, 0.25)
const LINE_CORE := Color(1.0, 0.92, 0.7)
const SPARK_SPEED: float = 0.45          ## travelling sparks per second along a lit line
const FILL_ON := Color(0.22, 0.13, 0.05)
const FILL_OFF := Color(0.05, 0.045, 0.07)
const GLOW := Color(1.0, 0.62, 0.2)
const GLOW_RINGS: int = 4
const BURST: int = 16
const BURST_LIFE: float = 0.55
const BURST_SPEED: Vector2 = Vector2(40, 110)
const GRAVITY: float = 120.0
const VAL_GLYPH: Array = [["speed", "speed"], ["burn", "fire"], ["ignite", "fire"], ["crit", "crit"], ["moth", "moth"],
	["cost", "oil"], ["oil", "oil"], ["life", "life"], ["heal", "life"], ["armour", "armour"], ["ward", "armour"],
	["dark", "dark"], ["shroud", "dark"], ["damage", "damage"], ["pct", "damage"]]

var _sparks: Array = []                  ## [position, velocity, age]


## Frame kind for a node: keystones (flagged, or a single-point capstone of a tree), notables (a few points that
## change how something works) and minor nodes (stat steps).
static func kind_of(n: Dictionary) -> String:
	if n.get("keystone", false) or (int(n["max"]) == 1 and int(n["req"]) >= 8):
		return "keystone"
	return "notable" if int(n["max"]) <= 2 else "minor"


## Which nodes the tree draws lines between: a node's named parent if it has one, else every node one column away
## or less in the nearest row above it.
static func links(nodes: Array) -> Array:
	var out: Array = []
	for n: Dictionary in nodes:
		if n.has("parent"):
			for m: Dictionary in nodes:
				if m["id"] == n["parent"]:
					out.append([m, n])
			continue
		var above: int = _row_above(nodes, int(n["pos"][1]))
		for m: Dictionary in nodes:
			if int(m["pos"][1]) == above and absi(int(m["pos"][0]) - int(n["pos"][0])) <= 1:
				out.append([m, n])
	return out


static func _row_above(nodes: Array, row: int) -> int:
	var best: int = -1
	for m: Dictionary in nodes:
		var r: int = int(m["pos"][1])
		if r < row and r > best:
			best = r
	return best


## Glyph for a skill node, from the first of its values that names one (the light glyph if none does).
static func glyph_for(vals: Dictionary) -> String:
	for k: String in vals:
		for pair: Array in VAL_GLYPH:
			if k.contains(String(pair[0])):
				return String(pair[1])
	return "light"


func backdrop(ci: CanvasItem, r: Rect2, t: float) -> void:
	for i: int in BAND:
		var band := Rect2(r.position.x, r.position.y + r.size.y * i / BAND, r.size.x, ceilf(r.size.y / BAND))
		ci.draw_rect(band, BACK_TOP.lerp(BACK_LOW, float(i) / (BAND - 1)))
	_motes(ci, r, t)
	for i: int in VIGNETTE_STEPS:
		var inset: float = VIGNETTE_DEPTH * (1.0 - float(i) / VIGNETTE_STEPS)
		ci.draw_rect(r.grow(-inset), Color(0, 0, 0, VIGNETTE_ALPHA), false, VIGNETTE_DEPTH / VIGNETTE_STEPS)
	_frame(ci, r)


## Slow embers rising through the backdrop, nudged by the mouse so the tree seems to float above them.
func _motes(ci: CanvasItem, r: Rect2, t: float) -> void:
	var lean: Vector2 = (ci.get_local_mouse_position() - r.get_center()) * -PARALLAX
	for i: int in MOTES:
		var seed_x: float = fposmod(float(i) * 0.6180339, 1.0)
		var rise: float = fposmod(t * MOTE_SPEED * (0.6 + seed_x) + float(i) * 37.0, r.size.y)
		var p := Vector2(r.position.x + seed_x * r.size.x + sin(t * 0.7 + i) * 6.0, r.end.y - rise) + lean * (0.5 + seed_x)
		var a: float = 0.25 * sin(PI * rise / r.size.y)
		ci.draw_rect(Rect2(p, Vector2.ONE * (1.0 + float(i % 3 == 0))), Color(GLOW, a))


## A thin double frame with small diamonds at the corners.
func _frame(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r.grow(-2.0), Color(UiDraw.FRAME, 0.8), false, 1.0)
	ci.draw_rect(r.grow(-5.0), Color(UiDraw.FRAME, 0.35), false, 1.0)
	for c: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var at: Vector2 = c + (r.get_center() - c).sign() * 4.0
		diamond(ci, at, CORNER * 0.5, UiDraw.GOLD)


static func diamond(ci: CanvasItem, at: Vector2, k: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -k), at + Vector2(k, 0), at + Vector2(0, k), at + Vector2(-k, 0)]), col)


func connector(ci: CanvasItem, a: Vector2, b: Vector2, lit: bool, t: float) -> void:
	if not lit:
		ci.draw_line(a, b, LINE_DIM, 2.0)
		return
	ci.draw_line(a, b, Color(LINE_LIT, 0.25), 6.0)
	ci.draw_line(a, b, LINE_LIT, 2.0)
	ci.draw_line(a, b, LINE_CORE, 1.0)
	var k: float = fposmod(t * SPARK_SPEED + a.x * 0.013, 1.0)
	ci.draw_circle(a.lerp(b, k), 2.0, LINE_CORE)


## A node's frame: `kind` is "minor", "notable" or "keystone"; `on` once it has points; `open` if it can take one.
func node_frame(ci: CanvasItem, r: Rect2, kind: String, on: bool, open: bool, hover: bool, t: float) -> void:
	if hover or on:
		var pulse: float = 0.6 + 0.4 * sin(t * 4.0) if hover else 0.5
		for i: int in GLOW_RINGS:
			ci.draw_rect(r.grow(float(i + 1) * 1.5), Color(GLOW, 0.09 * pulse * (GLOW_RINGS - i)), false, 1.5)
	var edge: Color = UiDraw.FRAME_LIT if on else (UiDraw.FRAME if open else UiDraw.LOCKED)
	var poly: PackedVector2Array = _cut(r, CORNER * 0.6 if kind != "minor" else 0.0)
	ci.draw_colored_polygon(poly, FILL_ON if on else FILL_OFF)
	poly.append(poly[0])
	ci.draw_polyline(poly, edge, 1.0)
	if kind == "keystone":
		var inner: PackedVector2Array = _cut(r.grow(-3.0), CORNER * 0.4)
		inner.append(inner[0])
		ci.draw_polyline(inner, UiDraw.GOLD if open or on else UiDraw.LOCKED, 1.0)
		diamond(ci, Vector2(r.get_center().x, r.position.y), 3.5, UiDraw.GOLD if open or on else UiDraw.LOCKED)
		diamond(ci, Vector2(r.get_center().x, r.end.y), 3.5, UiDraw.GOLD if open or on else UiDraw.LOCKED)


## A rectangle with its corners cut off by `k` (k 0: the plain rectangle).
static func _cut(r: Rect2, k: float) -> PackedVector2Array:
	var p: Vector2 = r.position
	var e: Vector2 = r.end
	if k <= 0.0:
		return PackedVector2Array([p, Vector2(e.x, p.y), e, Vector2(p.x, e.y)])
	return PackedVector2Array([p + Vector2(k, 0), Vector2(e.x - k, p.y), Vector2(e.x, p.y + k), Vector2(e.x, e.y - k),
		e - Vector2(k, 0), Vector2(p.x + k, e.y), Vector2(p.x, e.y - k), p + Vector2(0, k)])


## A point went in: sparks fly out of the node.
func burst(at: Vector2) -> void:
	for i: int in BURST:
		var dir: Vector2 = Vector2.RIGHT.rotated(TAU * (float(i) + randf() * 0.6) / BURST)
		_sparks.append([at, dir * randf_range(BURST_SPEED.x, BURST_SPEED.y), 0.0])


func draw_sparks(ci: CanvasItem, delta: float) -> void:
	for s: Array in _sparks:
		s[2] = float(s[2]) + delta
		s[1] = (s[1] as Vector2) + Vector2(0, GRAVITY * delta)
		s[0] = (s[0] as Vector2) + (s[1] as Vector2) * delta
	_sparks = _sparks.filter(func(s: Array) -> bool: return float(s[2]) < BURST_LIFE)
	for s: Array in _sparks:
		var k: float = 1.0 - float(s[2]) / BURST_LIFE
		ci.draw_rect(Rect2(s[0] as Vector2 - Vector2.ONE, Vector2(2, 2)), Color(LINE_CORE.lerp(GLOW, 1.0 - k), k))
