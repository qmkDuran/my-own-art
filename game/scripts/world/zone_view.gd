class_name ZoneView
extends Node2D
## Draws a ZoneLayout: the shader ground, bridges, Tallow's wall and gate, static props and trees (y-sorted with
## the actors in `world`), crystal glows, and one static body whose shapes are exactly the blocked cells and the
## prop footprints, so what you see is what stops you.

const GROUND_Z: int = -20
const BRIDGE_Z: int = -19
const CRYSTAL_LIGHT_RANGE: float = 80.0
const CRYSTAL_LIGHT_ENERGY: float = 0.55
const WALL_W: int = 96
const PATH_TEXEL: int = 8
const PATH_HALF: float = 40.0
const GATE_W: int = 128
## Kinds Game turns into Interactables (they draw themselves).
const INTERACTIVE: Array[String] = ["chest", "waylamp", "note", "cairn", "statue_fisher", "cocoon", "signpost", "npc"]

var z: ZoneLayout
var body: StaticBody2D


func build(layout: ZoneLayout, world: Node2D) -> void:
	z = layout
	_ground()
	_bridges()
	_wall(world)
	_props(world)
	_trees(world)
	_collision()


func _ground() -> void:
	var img := Image.create(z.cols, z.rows, false, Image.FORMAT_RGBA8)
	for y: int in z.rows:
		for x: int in z.cols:
			img.set_pixel(x, y, Color8(z.t(Vector2i(x, y)), z.stream[z.idx(Vector2i(x, y))] * 255, 0, 255))
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.centered = false
	s.scale = Vector2(z.cell, z.cell)
	s.z_index = GROUND_Z
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ground.gdshader")
	mat.set_shader_parameter("map_tex", s.texture)
	mat.set_shader_parameter("map_size", Vector2(z.cols, z.rows))
	mat.set_shader_parameter("cell", float(z.cell))
	mat.set_shader_parameter("stream_tex", _stream_tex())
	mat.set_shader_parameter("path_tex", _path_tex())
	mat.set_shader_parameter("path_scale", float(PATH_TEXEL))
	mat.set_shader_parameter("pond", Vector4(z.pond.x, z.pond.y, maxf(1.0, z.pond.z - z.cell * 0.5), maxf(1.0, z.pond.w - z.cell * 0.5)))
	mat.set_shader_parameter("circle", z.circle)
	for n: String in ["void", "ink", "moss_dk", "moss", "moss_lt", "earth_dk", "earth", "earth_lt", "stone_dk", "stone",
			"stone_lt", "glass_dp", "glass_dk", "glass", "glass_lt", "glint"]:
		mat.set_shader_parameter("c_" + n, Pal.c(n))
	s.material = mat
	add_child(s)


## The stream's centre per row (in cells) as a one-pixel-high float texture the shader interpolates.
func _stream_tex() -> ImageTexture:
	var img := Image.create(z.rows, 1, false, Image.FORMAT_RF)
	for y: int in z.rows:
		img.set_pixel(y, 0, Color(z.stream_center[y], 0, 0))
	return ImageTexture.create_from_image(img)


## Dirt paths drawn from their smoothed centre lines into a coarse mask (bilinear-sampled: smooth edges).
func _path_tex() -> ImageTexture:
	var k: int = z.cell / PATH_TEXEL
	var img := Image.create(z.cols * k, z.rows * k, false, Image.FORMAT_L8)
	var r: int = ceili(PATH_HALF / PATH_TEXEL)
	for line: PackedVector2Array in z.path_lines:
		for i: int in line.size() - 1:
			var steps: int = maxi(1, ceili(line[i].distance_to(line[i + 1]) / PATH_TEXEL))
			for s: int in steps + 1:
				var c: Vector2 = line[i].lerp(line[i + 1], float(s) / steps) / PATH_TEXEL
				img.fill_rect(Rect2i(Vector2i(c) - Vector2i(r, r) / 2, Vector2i(r, r)), Color.WHITE)
	return ImageTexture.create_from_image(img)


## Plank tiles over every bridge cell: rails on the north and south edges, deck between.
func _bridges() -> void:
	for y: int in z.rows:
		for x: int in z.cols:
			var c := Vector2i(x, y)
			if z.t(c) != ZoneLayout.T.BRIDGE:
				continue
			var part: String = "bridge_deck"
			if z.t(c + Vector2i.UP) != ZoneLayout.T.BRIDGE:
				part = "bridge_north"
			elif z.t(c + Vector2i.DOWN) != ZoneLayout.T.BRIDGE:
				part = "bridge_south"
			var s := Sprite2D.new()
			s.texture = PropSprite.tex("res://art/props/%s.png" % part)
			s.centered = false
			s.position = Vector2(x * z.cell, y * z.cell)
			s.z_index = BRIDGE_Z
			add_child(s)


## The wall's face runs along the bottom of the wall rows; the gate stands where the road leaves the city.
func _wall(world: Node2D) -> void:
	var base_y: float = z.wall_rows * z.cell
	var gate_x: float = z.gate_col * z.cell
	var gate := PropSprite.make("gate")
	gate.position = Vector2(gate_x + GATE_W / 2.0, base_y)
	world.add_child(gate)
	for span: Vector2 in [Vector2(0, gate_x), Vector2(gate_x + GATE_W, z.wall_cols * z.cell)]:
		var x: float = span.x
		while x < span.y:
			var w: float = minf(WALL_W, span.y - x)
			var s := PropSprite.make("wall")
			s.region_enabled = true
			s.region_rect = Rect2(0, 0, w, float(GameData.props["wall"]["size"][1]))
			s.position = Vector2(x + w / 2.0, base_y)
			world.add_child(s)
			x += w


func _props(world: Node2D) -> void:
	for p: Dictionary in z.props:
		if INTERACTIVE.has(p["kind"]) or not GameData.props.has(p["kind"]):
			continue
		var s := PropSprite.make(p["kind"])
		s.position = p["pos"]
		s.flip_h = int(p["pos"].x) % 3 == 0 and not ["hut", "tower"].has(p["kind"])
		if (p["foot"] as Rect2).size.x > 0.0:
			s.add_child(PropSprite.shadow((p["foot"] as Rect2).size.x * 1.2))
		world.add_child(s)
		if String(GameData.props[p["kind"]]["light"]) != "":
			_glow_light(s, Pal.c(GameData.props[p["kind"]]["light"]))


func _glow_light(s: Node2D, col: Color) -> void:
	var l := PointLight2D.new()
	l.texture = LightTex.soft(128)
	l.texture_scale = CRYSTAL_LIGHT_RANGE / 64.0
	l.color = col
	l.energy = CRYSTAL_LIGHT_ENERGY
	l.position = Vector2(0, -12)
	s.add_child(l)


func _trees(world: Node2D) -> void:
	var fade := TreeFade.new()
	add_child(fade)
	for t: Dictionary in z.trees:
		var s := PropSprite.make(t["kind"])
		s.position = t["pos"]
		s.flip_h = int(t["pos"].x + t["pos"].y) % 2 == 0
		var g: Sprite2D = s.get_node_or_null("Glow") as Sprite2D
		if g != null:
			g.flip_h = s.flip_h
		world.add_child(s)
		fade.add(s)


## One static body: blocked terrain merged into rectangles (row runs stacked downward) plus every footprint.
func _collision() -> void:
	body = StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	for r: Rect2i in _merged_blocked():
		_rect_shape(Rect2(Vector2(r.position * z.cell), Vector2(r.size * z.cell)))
	for f: Rect2 in z.footprints():
		_rect_shape(f)


func _rect_shape(r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = r.get_center()
	body.add_child(cs)


func _merged_blocked() -> Array[Rect2i]:
	var open: Dictionary = {}           # Vector2i(x0, x1) run -> Rect2i growing downward
	var out: Array[Rect2i] = []
	for y: int in z.rows:
		var runs: Array[Vector2i] = []
		var x: int = 0
		while x < z.cols:
			if z.walkable_terrain(Vector2i(x, y)):
				x += 1
				continue
			var x0: int = x
			while x < z.cols and not z.walkable_terrain(Vector2i(x, y)):
				x += 1
			runs.append(Vector2i(x0, x))
		var next: Dictionary = {}
		for run: Vector2i in runs:
			if open.has(run):
				var r: Rect2i = open[run]
				r.size.y += 1
				next[run] = r
				open.erase(run)
			else:
				next[run] = Rect2i(run.x, y, run.y - run.x, 1)
		for run: Vector2i in open:
			out.append(open[run])
		open = next
	for run: Vector2i in open:
		out.append(open[run])
	return out
