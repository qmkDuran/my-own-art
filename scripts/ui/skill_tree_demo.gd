class_name SkillTreeDemo
extends Control
## A playable MOCKUP of the radial "Ember Tree" (see DESIGN.md), to judge the look and feel.
## Not wired to real gameplay. Run this scene on its own (F6).
##
## Controls: scroll to zoom, drag (any mouse button) to move around,
## hover an ember to read it, click a glowing ember to ignite it.
##
## Layers, back to front:
##   background + vignette -> very dark, so the fire glows
##   tree canvas           -> the tree itself; zooms and pans as one piece
##   header / footer bars  -> translucent, always on screen
##   tooltip               -> translucent card on the right; all text lives here, never on the tree

const UI_SIZE := Vector2i(640, 360)
## Space between the screen edge (or a bar) and content, in UI pixels.
const PAGE_MARGIN := 16.0
const HEADER_HEIGHT := 48.0
const FOOTER_HEIGHT := 30.0
## Header text is lifted this much so it looks centred (measured from screenshots).
const HEADER_TEXT_LIFT := 2.0
const RING_RADII := [100.0, 185.0, 270.0]
const NODE_RADIUS := {"skill": 24.0, "stat": 18.0, "ultimate": 28.0}
const ICON_PIXEL := {"skill": 3.0, "stat": 2.0, "ultimate": 3.0}
const CENTRE_RADIUS := 46.0

const MIN_ZOOM := 0.45
const MAX_ZOOM := 1.6
const START_ZOOM := 0.56
const START_CENTRE := Vector2(232, 210)
## Mouse travel (pixels) before a press counts as a drag instead of a click.
const DRAG_THRESHOLD := 4.0
const HOVER_SCALE := 1.15

const COLOR_BACKGROUND := Color(0.027, 0.031, 0.051)
const COLOR_OUTLINE := Color(0.02, 0.022, 0.04)
const COLOR_CREAM := Color(0.906, 0.835, 0.702)
const COLOR_GREY := Color(0.42, 0.5, 0.52)
const COLOR_DIM := Color(0.2, 0.25, 0.28)
const COLOR_COAL := Color(0.075, 0.09, 0.12)
const COLOR_ORANGE := Color(0.871, 0.62, 0.255)
const COLOR_RED := Color(0.812, 0.341, 0.235)
const COLOR_GOLD := Color(0.91, 0.757, 0.439)
const COLOR_DEEP := Color(0.36, 0.11, 0.17)
const COLOR_PANEL := Color(0.075, 0.05, 0.055, 0.8)
const COLOR_PANEL_EDGE := Color(0.871, 0.62, 0.255, 0.55)

## 8×8 pixel icons. They're centred by their drawn pixels, not the 8×8 box.
const ICONS := {
	"fist": ["..###...", ".#####..", "########", "########", "#######.", ".######.", ".#####..", "..###..."],
	"flame": ["...#....", "..##....", "..###...", ".####.#.", ".######.", "########", "########", ".######."],
	"up": ["...##...", "..####..", ".######.", "...##...", "...##...", ".######.", "########", "########"],
	"hop": ["......#.", ".....##.", "....###.", "...#..#.", "..#.....", ".#......", "##......", "#......."],
	"star": ["...##...", "...##...", "########", ".######.", "..####..", ".##..##.", "##....##", "#......#"],
	"heart": [".##.##..", "#######.", "#######.", "#######.", ".#####..", "..###...", "...#....", "........"],
	"spark": ["#..#..#.", ".#.#.#..", "..###...", "#######.", "..###...", ".#.#.#..", "#..#..#.", "........"],
	"shield": ["########", "#.####.#", "########", "########", ".######.", ".######.", "..####..", "...##..."],
}

## The tree. ring: 0 = stage 1 (inner), 1 = stage 2, 2 = stage 3. kind: skill, stat or ultimate.
const NODES := [
	{"id": "jab", "ring": 0, "angle": -90, "kind": "skill", "icon": "fist", "name": "Jab", "tag": "BASIC", "text": "A fast flaming punch. Hold to keep jabbing."},
	{"id": "health", "ring": 0, "angle": -30, "kind": "stat", "icon": "heart", "name": "+2 Health", "tag": "STAT", "text": "Emberoo can take two more hits."},
	{"id": "searing", "ring": 0, "angle": 30, "kind": "skill", "icon": "flame", "name": "Searing Jab", "tag": "BASIC · CHOICE", "text": "Jabs spread burn to nearby enemies when they kill."},
	{"id": "burn", "ring": 0, "angle": 90, "kind": "stat", "icon": "flame", "name": "+10% Burn", "tag": "STAT", "text": "Burns deal 10% more damage."},
	{"id": "uppercut", "ring": 0, "angle": 150, "kind": "skill", "icon": "up", "name": "Flame Uppercut", "tag": "CORE · 3 HEAT", "text": "An uppercut that bursts into flame, hitting everything in a small arc."},
	{"id": "heat", "ring": 0, "angle": 210, "kind": "stat", "icon": "spark", "name": "+Heat Gain", "tag": "STAT", "text": "Landing hits builds Heat faster."},
	{"id": "hop", "ring": 1, "angle": -110, "kind": "skill", "icon": "hop", "name": "Ember Hop", "tag": "DEFENSIVE", "text": "Your dodge leaves a trail of fire."},
	{"id": "health2", "ring": 1, "angle": -60, "kind": "stat", "icon": "heart", "name": "+3 Health", "tag": "STAT", "text": "Emberoo can take three more hits."},
	{"id": "wildfire", "ring": 1, "angle": -10, "kind": "skill", "icon": "flame", "name": "Wildfire", "tag": "CORE · CHOICE", "text": "Burning enemies ignite their neighbours."},
	{"id": "heat2", "ring": 1, "angle": 40, "kind": "stat", "icon": "spark", "name": "+Max Heat", "tag": "STAT", "text": "Hold more Heat at once."},
	{"id": "guard", "ring": 1, "angle": 100, "kind": "skill", "icon": "shield", "name": "Ash Guard", "tag": "DEFENSIVE", "text": "Briefly harden into ash, taking less damage."},
	{"id": "burn2", "ring": 1, "angle": 160, "kind": "stat", "icon": "flame", "name": "+15% Burn", "tag": "STAT", "text": "Burns deal 15% more damage."},
	{"id": "meteor", "ring": 1, "angle": 220, "kind": "skill", "icon": "star", "name": "Meteor Fist", "tag": "CORE · CHOICE", "text": "Leap and crash down fist-first in a burst of fire."},
	{"id": "inferno", "ring": 2, "angle": -90, "kind": "ultimate", "icon": "star", "name": "Inferno Rush", "tag": "ULTIMATE", "text": "A flurry of blazing punches that ends in an explosion."},
	{"id": "rekindle", "ring": 2, "angle": 30, "kind": "ultimate", "icon": "star", "name": "Rekindle", "tag": "ULTIMATE", "text": "Once per fight, rise from defeat in a burst of flame."},
	{"id": "sun", "ring": 2, "angle": 150, "kind": "ultimate", "icon": "star", "name": "Blazing Sun", "tag": "ULTIMATE", "text": "Become a living sun, burning everything around you."},
]

## Which stage is unlocked (rings above this are locked, like a future evolution).
const UNLOCKED_RING := 0


## The tree is drawn on its own layer so it can zoom and pan as one piece.
class TreeCanvas:
	extends Node2D
	var demo: SkillTreeDemo

	func _draw() -> void:
		demo.draw_tree(self)


var _skill_points: int = 3
var _learned := {"jab": true, "health": true}
var _links: Array = []          # [from_id, to_id]
var _positions := {}            # id -> Vector2, in tree space (centre = 0,0)
var _hover_scale := {}          # id -> float, eased toward 1.0 or HOVER_SCALE
var _vein_fill := {}            # "from>to" -> 0..1, how far fire has travelled
var _icon_centres := {}         # icon name -> centre of its drawn pixels, in icon pixels
var _hovered_id: String = ""
var _time: float = 0.0

var _canvas: TreeCanvas
var _target_zoom: float = START_ZOOM
var _target_offset: Vector2 = START_CENTRE
var _press_position: Vector2 = Vector2.ZERO
var _is_pressing: bool = false
var _is_dragging: bool = false

var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_tag: Label
var _tooltip_text: Label
var _tooltip_status: Label
var _points_label: Label


func _ready() -> void:
	_use_crisp_ui_resolution()
	_add_glow()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

	_measure_icons()
	_place_nodes()
	_build_links()
	for link in _links:
		var both_learned: bool = _learned.has(link[0]) and _learned.has(link[1])
		_vein_fill[_vein_key(link[0], link[1])] = 1.0 if both_learned else 0.0

	_build_tree_canvas()
	_build_vignette()
	_build_header()
	_build_footer()
	_build_tooltip()
	_show_tooltip_for("")


# --- Setup ----------------------------------------------------------------

## The game world renders at 320×180; this UI uses 640×360 so text stays crisp (the hybrid approach).
func _use_crisp_ui_resolution() -> void:
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_size = UI_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


## Soft bloom on bright pixels: the cheapest way to look "expensive".
func _add_glow() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CANVAS
	environment.glow_enabled = true
	environment.glow_intensity = 1.0
	environment.glow_bloom = 0.12
	environment.glow_hdr_threshold = 0.7
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)


## Finds the middle of each icon's drawn pixels, so lopsided icons still look centred.
func _measure_icons() -> void:
	for icon_name in ICONS:
		var rows: Array = ICONS[icon_name]
		var low := Vector2(8, 8)
		var high := Vector2(-1, -1)
		for y in rows.size():
			for x in 8:
				if rows[y][x] == "#":
					low = low.min(Vector2(x, y))
					high = high.max(Vector2(x, y))
		_icon_centres[icon_name] = (low + high + Vector2.ONE) / 2.0


func _place_nodes() -> void:
	_positions["centre"] = Vector2.ZERO
	for node in NODES:
		var radius: float = RING_RADII[node["ring"]]
		_positions[node["id"]] = Vector2.from_angle(deg_to_rad(node["angle"])) * radius
		_hover_scale[node["id"]] = 1.0


## Veins: centre → first skill; neighbours around the first ring; each outer node → nearest inner node.
func _build_links() -> void:
	_links.append(["centre", "jab"])
	for ring in RING_RADII.size():
		var ring_nodes := _ids_on_ring(ring)
		if ring == 0:
			for index in ring_nodes.size():
				_links.append([ring_nodes[index], ring_nodes[(index + 1) % ring_nodes.size()]])
		else:
			for id in ring_nodes:
				_links.append([_nearest_on_ring(id, ring - 1), id])


func _build_tree_canvas() -> void:
	_canvas = TreeCanvas.new()
	_canvas.demo = self
	_canvas.position = START_CENTRE
	_canvas.scale = Vector2.ONE * START_ZOOM
	add_child(_canvas)

	# Emberoo's live idle animation in the middle of the tree.
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = SpriteFrames.new()
	sprite.sprite_frames.remove_animation("default")
	var sheet: Texture2D = load("res://art/emberoo/emberoo_front_idle_sheet.png")
	SpriteSheetLoader.add_animation(sprite.sprite_frames, "idle", sheet, [0.3, 0.2, 0.3, 0.2], true, Vector2i(16, 16))
	sprite.scale = Vector2(4, 4)
	_canvas.add_child(sprite)
	sprite.play("idle")

	# Slow embers drifting upward around the tree.
	var embers := CPUParticles2D.new()
	embers.amount = 60
	embers.lifetime = 5.0
	embers.preprocess = 5.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 300.0
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.gravity = Vector2(0, -8)
	embers.initial_velocity_min = 3.0
	embers.initial_velocity_max = 12.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.0
	embers.color_ramp = _fade_ramp([COLOR_GOLD, COLOR_ORANGE, COLOR_RED])
	_canvas.add_child(embers)


## Darkens the screen edges so the eye goes to the middle and the fire glows.
func _build_vignette() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.15), Color(0, 0, 0, 0.75)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	var vignette := TextureRect.new()
	vignette.texture = texture
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


func _build_header() -> void:
	var bar := _make_panel(Color(0.035, 0.03, 0.04, 0.72), Color(0, 0, 0, 0), 0)
	bar.position = Vector2(0, 0)
	bar.size = Vector2(UI_SIZE.x, HEADER_HEIGHT)
	add_child(bar)
	_add_line(Vector2(0, HEADER_HEIGHT), Vector2(UI_SIZE.x, HEADER_HEIGHT), Color(COLOR_ORANGE, 0.25))
	# Title and subtitle as one block, centred vertically in the header.
	var title_block := VBoxContainer.new()
	title_block.alignment = BoxContainer.ALIGNMENT_CENTER
	title_block.add_theme_constant_override("separation", 0)
	# The font leaves extra room above capitals, so lift the text slightly to look centred.
	title_block.position = Vector2(PAGE_MARGIN, -HEADER_TEXT_LIFT)
	title_block.size = Vector2(240, HEADER_HEIGHT)
	title_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_block)
	for line in [["EMBEROO", 16, COLOR_GOLD], ["The Ember Tree", 10, COLOR_GREY]]:
		var label := _make_label(line[1], line[2])
		label.text = line[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_block.add_child(label)
	_points_label = _add_label("", Vector2(UI_SIZE.x - 240 - PAGE_MARGIN, -HEADER_TEXT_LIFT), Vector2(240, HEADER_HEIGHT), 11, COLOR_CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	_update_points_label()


func _build_footer() -> void:
	var bar := _make_panel(Color(0.035, 0.03, 0.04, 0.72), Color(0, 0, 0, 0), 0)
	var top := UI_SIZE.y - FOOTER_HEIGHT
	bar.position = Vector2(0, top)
	bar.size = Vector2(UI_SIZE.x, FOOTER_HEIGHT)
	add_child(bar)
	_add_line(Vector2(0, top), Vector2(UI_SIZE.x, top), Color(COLOR_ORANGE, 0.2))
	# Labels fill the bar's full height and centre their text in it.
	_add_label("Inner ring: Stage 1   ·   Middle: Stage 2   ·   Outer: Stage 3", Vector2(PAGE_MARGIN, top), Vector2(320, FOOTER_HEIGHT), 9, COLOR_GREY, HORIZONTAL_ALIGNMENT_LEFT)
	_add_label("Scroll to zoom  ·  Drag to move", Vector2(UI_SIZE.x - 300 - PAGE_MARGIN, top), Vector2(300, FOOTER_HEIGHT), 9, COLOR_GREY, HORIZONTAL_ALIGNMENT_RIGHT)


func _build_tooltip() -> void:
	_tooltip = _make_panel(COLOR_PANEL, COLOR_PANEL_EDGE, 4)
	_tooltip.position = Vector2(UI_SIZE.x - 220 - PAGE_MARGIN, HEADER_HEIGHT + PAGE_MARGIN)
	_tooltip.custom_minimum_size = Vector2(220, 0)
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_tooltip.add_child(column)
	_tooltip_name = _make_label(15, COLOR_CREAM)
	_tooltip_tag = _make_label(9, COLOR_ORANGE)
	var divider := ColorRect.new()
	divider.color = Color(COLOR_ORANGE, 0.3)
	divider.custom_minimum_size = Vector2(196, 1)
	_tooltip_text = _make_label(11, COLOR_CREAM)
	_tooltip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_status = _make_label(10, COLOR_GREY)
	_tooltip_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for item in [_tooltip_name, _tooltip_tag, divider, _tooltip_text, _tooltip_status]:
		item.custom_minimum_size.x = 196
		column.add_child(item)


# --- Every frame ----------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	var ease_amount := 1.0 - exp(-14.0 * delta)
	for id in _hover_scale:
		var target := HOVER_SCALE if id == _hovered_id else 1.0
		_hover_scale[id] = lerpf(_hover_scale[id], target, ease_amount)
	# Smooth zoom and pan toward their targets.
	var zoom := lerpf(_canvas.scale.x, _target_zoom, ease_amount)
	_canvas.scale = Vector2.ONE * zoom
	_canvas.position = _canvas.position.lerp(_target_offset, ease_amount)
	_canvas.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_around(event.position, 1.15)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_around(event.position, 1.0 / 1.15)
	elif event.pressed:
		_is_pressing = true
		_is_dragging = false
		_press_position = event.position
	else:
		var was_click := _is_pressing and not _is_dragging
		_is_pressing = false
		_is_dragging = false
		if was_click and event.button_index == MOUSE_BUTTON_LEFT:
			var id := _node_under(event.position)
			if id != "" and _is_available(id):
				_ignite(id)


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_pressing and event.position.distance_to(_press_position) > DRAG_THRESHOLD:
		_is_dragging = true
	if _is_dragging:
		_target_offset += event.relative
		_canvas.position += event.relative
		return
	var id := _node_under(event.position)
	if id != _hovered_id:
		_hovered_id = id
		_show_tooltip_for(id)


## Zooms in or out while keeping the point under the cursor where it is.
func _zoom_around(screen_point: Vector2, factor: float) -> void:
	var new_zoom := clampf(_target_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	var applied := new_zoom / _target_zoom
	_target_offset = screen_point - (screen_point - _target_offset) * applied
	_target_zoom = new_zoom


# --- Drawing ---------------------------------------------------------------

## The very dark backdrop, behind everything else.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)


# --- Drawing the tree (called by TreeCanvas, in tree space) ----------------

func draw_tree(canvas: Node2D) -> void:
	_draw_rings(canvas)
	for link in _links:
		_draw_vein(canvas, link[0], link[1])
	_draw_centre(canvas)
	for node in NODES:
		_draw_node(canvas, node)


func _draw_rings(canvas: Node2D) -> void:
	for ring in RING_RADII.size():
		var radius: float = RING_RADII[ring]
		if ring <= UNLOCKED_RING:
			canvas.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, Color(COLOR_RED, 0.35), 2.0)
		else:
			var dashes := 64
			for dash in dashes:
				var start := TAU * dash / dashes
				canvas.draw_arc(Vector2.ZERO, radius, start, start + TAU / dashes * 0.45, 4, Color(COLOR_DIM, 0.7), 1.5)


func _draw_vein(canvas: Node2D, from_id: String, to_id: String) -> void:
	var from: Vector2 = _positions[from_id]
	var to: Vector2 = _positions[to_id]
	canvas.draw_line(from, to, COLOR_COAL, 3.0)
	var fill: float = _vein_fill.get(_vein_key(from_id, to_id), 0.0)
	if fill <= 0.0:
		return
	var burning_end := from.lerp(to, fill)
	canvas.draw_line(from, burning_end, Color(COLOR_RED, 0.7), 6.0)
	canvas.draw_line(from, burning_end, COLOR_GOLD, 2.0)
	# Sparks travel along the burning part.
	for spark in 6:
		var along := fmod(_time * 0.5 + spark / 6.0, 1.0) * fill
		var point := from.lerp(to, along)
		canvas.draw_rect(Rect2(point.round() - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1.0, 0.92, 0.65))


func _draw_centre(canvas: Node2D) -> void:
	canvas.draw_circle(Vector2.ZERO, CENTRE_RADIUS, Color(0.06, 0.045, 0.07))
	canvas.draw_arc(Vector2.ZERO, CENTRE_RADIUS, 0.0, TAU, 96, COLOR_RED, 2.5)
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	canvas.draw_arc(Vector2.ZERO, CENTRE_RADIUS + 6.0 + pulse * 3.0, 0.0, TAU, 96, Color(COLOR_ORANGE, 0.2 + 0.2 * pulse), 1.5)


func _draw_node(canvas: Node2D, node: Dictionary) -> void:
	var id: String = node["id"]
	var centre: Vector2 = _positions[id]
	var hover: float = _hover_scale[id]
	var state := _state_of(id)
	var radius: float = NODE_RADIUS[node["kind"]] * hover

	if state == "learned":
		var flicker := 0.85 + 0.15 * sin(_time * 5.0 + centre.x)
		for halo in [[radius + 18.0, 0.07], [radius + 11.0, 0.12], [radius + 5.0, 0.2]]:
			canvas.draw_circle(centre, halo[0], Color(COLOR_ORANGE, halo[1] * flicker))

	var fill: Color = {"learned": COLOR_DEEP, "available": Color(0.12, 0.085, 0.12), "locked": COLOR_COAL}[state]
	var edge: Color = {"learned": COLOR_GOLD, "available": COLOR_CREAM, "locked": COLOR_DIM}[state]
	if state == "available":
		edge = Color(edge, 0.55 + 0.45 * sin(_time * 4.0))  # gentle pulse: "you can take this"

	if node["kind"] == "stat":
		canvas.draw_circle(centre, radius + 3.0, COLOR_OUTLINE)
		canvas.draw_circle(centre, radius, fill)
		canvas.draw_arc(centre, radius, 0.0, TAU, 48, edge, 2.5)
	else:
		_draw_diamond(canvas, centre, radius + 3.0, COLOR_OUTLINE, true)
		_draw_diamond(canvas, centre, radius, fill, true)
		_draw_diamond(canvas, centre, radius, edge, false)

	var icon_color: Color = {"learned": COLOR_GOLD, "available": COLOR_CREAM, "locked": COLOR_DIM}[state]
	_draw_icon(canvas, node["icon"], centre, ICON_PIXEL[node["kind"]] * hover, icon_color)


func _draw_diamond(canvas: Node2D, centre: Vector2, radius: float, color: Color, filled: bool) -> void:
	var points := PackedVector2Array([
		centre + Vector2(0, -radius), centre + Vector2(radius, 0),
		centre + Vector2(0, radius), centre + Vector2(-radius, 0),
	])
	if filled:
		canvas.draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		canvas.draw_polyline(points, color, 2.5)


## Draws an 8×8 icon so the middle of its drawn pixels sits exactly on the node's centre.
func _draw_icon(canvas: Node2D, icon_name: String, centre: Vector2, pixel: float, color: Color) -> void:
	var rows: Array = ICONS[icon_name]
	var top_left: Vector2 = centre - _icon_centres[icon_name] * pixel
	for y in rows.size():
		for x in 8:
			if rows[y][x] == "#":
				canvas.draw_rect(Rect2(top_left + Vector2(x, y) * pixel, Vector2(pixel, pixel)), color)


# --- Learning a node ------------------------------------------------------

func _ignite(id: String) -> void:
	_skill_points -= 1
	_learned[id] = true
	_update_points_label()
	_show_tooltip_for(id)

	# Fire travels from a learned neighbour along the vein, then the ember flares.
	var source := _learned_neighbour_of(id, id)
	var key := _vein_key(source, id) if _vein_fill.has(_vein_key(source, id)) else _vein_key(id, source)
	var travel := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	travel.tween_method(func(value: float) -> void: _vein_fill[key] = value, 0.0, 1.0, 0.4)
	travel.tween_callback(_burst_at.bind(_positions[id]))
	_hover_scale[id] = 1.5  # a pop that eases back


func _burst_at(point: Vector2) -> void:
	var burst := CPUParticles2D.new()
	burst.position = point
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 24
	burst.lifetime = 0.7
	burst.spread = 180.0
	burst.initial_velocity_min = 50.0
	burst.initial_velocity_max = 120.0
	burst.gravity = Vector2(0, 80)
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 4.0
	burst.color_ramp = _fade_ramp([Color(1, 0.95, 0.7), COLOR_ORANGE, COLOR_RED])
	_canvas.add_child(burst)
	burst.emitting = true
	get_tree().create_timer(1.2).timeout.connect(burst.queue_free)


# --- Tooltip --------------------------------------------------------------

func _show_tooltip_for(id: String) -> void:
	if id == "":
		_tooltip_name.text = "The Ember Tree"
		_tooltip_tag.text = "EMBEROO'S SKILLS"
		_tooltip_text.text = "Learned embers burn. Glowing ones can be ignited. The grey rings open as Emberoo evolves."
		_tooltip_status.text = ""
		_tooltip_status.visible = false
	else:
		var node := _node_data(id)
		_tooltip_name.text = node["name"]
		_tooltip_tag.text = node["tag"]
		_tooltip_text.text = node["text"]
		_tooltip_status.text = _status_text(id)
		_tooltip_status.add_theme_color_override("font_color", _status_color(id))
		_tooltip_status.visible = true
	_tooltip.reset_size()  # shrink to fit the new text

	# Slide in and fade, instead of popping.
	var resting_x := UI_SIZE.x - 220.0 - PAGE_MARGIN
	_tooltip.modulate.a = 0.0
	_tooltip.position.x = resting_x + 8.0
	var slide := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(_tooltip, "modulate:a", 1.0, 0.16)
	slide.tween_property(_tooltip, "position:x", resting_x, 0.16)


func _status_text(id: String) -> String:
	match _state_of(id):
		"learned":
			return "Ignited"
		"available":
			return "Click to ignite  ·  1 point" if _skill_points > 0 else "No skill points left"
		_:
			var ring: int = _node_data(id)["ring"]
			if ring > UNLOCKED_RING:
				return "Unlocks at Stage %d evolution" % (ring + 1)
			return "Ignite a neighbouring ember first"


func _status_color(id: String) -> Color:
	return {"learned": COLOR_GOLD, "available": COLOR_CREAM, "locked": COLOR_GREY}[_state_of(id)]


func _update_points_label() -> void:
	_points_label.text = "Level 7   ·   Skill points  %d" % _skill_points


# --- Rules ----------------------------------------------------------------

func _state_of(id: String) -> String:
	if _learned.has(id):
		return "learned"
	if _is_available(id):
		return "available"
	return "locked"


func _is_available(id: String) -> bool:
	if _learned.has(id) or _skill_points <= 0:
		return false
	if _node_data(id)["ring"] > UNLOCKED_RING:
		return false
	return _learned_neighbour_of(id, "") != ""


## A learned node linked to this one (ignoring `except_id`), or "" if none.
func _learned_neighbour_of(id: String, except_id: String) -> String:
	for link in _links:
		for side in [0, 1]:
			var other: String = link[1 - side]
			if link[side] == id and other != except_id and (_learned.has(other) or other == "centre"):
				return other
	return ""


# --- Helpers --------------------------------------------------------------

## Finds the node under a point given in screen (UI) coordinates.
func _node_under(screen_point: Vector2) -> String:
	var tree_point := _canvas.transform.affine_inverse() * screen_point
	for node in NODES:
		if tree_point.distance_to(_positions[node["id"]]) <= NODE_RADIUS[node["kind"]] + 2.0:
			return node["id"]
	return ""


func _node_data(id: String) -> Dictionary:
	for node in NODES:
		if node["id"] == id:
			return node
	return {}


func _ids_on_ring(ring: int) -> Array:
	var ids := []
	for node in NODES:
		if node["ring"] == ring:
			ids.append(node["id"])
	return ids


func _nearest_on_ring(id: String, ring: int) -> String:
	var best := ""
	var best_distance := INF
	for other in _ids_on_ring(ring):
		var distance: float = (_positions[id] as Vector2).distance_to(_positions[other])
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


func _vein_key(from_id: String, to_id: String) -> String:
	return "%s>%s" % [from_id, to_id]


func _fade_ramp(colors: Array) -> Gradient:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([colors[0], colors[1], Color(colors[2], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	return ramp


func _make_panel(background: Color, border: Color, corner_radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(corner_radius)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.35 if corner_radius > 0 else 0.0)
	style.shadow_size = 6 if corner_radius > 0 else 0
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _add_label(text: String, at: Vector2, box: Vector2, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := _make_label(font_size, color)
	label.text = text
	label.position = at
	label.size = box
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	add_child(label)
	return label


func _add_line(from: Vector2, to: Vector2, color: Color) -> void:
	var line := ColorRect.new()
	line.color = color
	line.position = from
	line.size = Vector2(to.x - from.x, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
