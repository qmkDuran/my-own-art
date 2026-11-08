class_name EmberTreeCanvas
extends Node2D
## Draws the radial Ember Tree around Emberoo: rings, flame veins, embers and coals.
##
## Drawn in "tree space" with Emberoo at (0, 0); EmberTreeView zooms and pans this node.
## Skills and upgrades are diamond embers, stat picks are round coals (DESIGN.md).
## Learned nodes glow, learnable ones pulse, locked ones stay cold coal.
## Learning sends fire along the vein, then the ember flares.

const Kind := EmberTreeNode.Kind

## Distance from Emberoo for each tier, in tree pixels. Tiers 0-2 = Stage 1, 3 = Stage 2, 4 = Stage 3.
const TIER_RADII: Array[float] = [92.0, 142.0, 192.0, 266.0, 336.0]
## Branch names sit in the gap between the Stage 1 and Stage 2 rings.
const BRANCH_LABEL_RADIUS := 229.0
const BRANCH_LABEL_SIZE := 18
const CENTRE_RADIUS := 46.0
const CENTRE_ID := "centre"
const NODE_RADIUS := {Kind.SKILL: 24.0, Kind.UPGRADE: 21.0, Kind.STAT: 18.0, Kind.ULTIMATE: 28.0}
## Size of one icon pixel; smaller frames get finer icons so they still fit.
const ICON_PIXEL := {Kind.SKILL: 3.0, Kind.UPGRADE: 2.5, Kind.STAT: 2.0, Kind.ULTIMATE: 3.0}
## Dark rim drawn outside every node so it stands off the veins behind it.
const OUTLINE_WIDTH := 3.0
const EDGE_WIDTH := 2.5
## Extra pixels around a node that still count as pointing at it.
const HIT_MARGIN := 2.0

const HOVER_SCALE := 1.15
const LEARN_POP_SCALE := 1.5
## How quickly hover and pop sizes ease back (higher = snappier).
const EASE_RATE := 14.0
const VEIN_FILL_SECONDS := 0.4
const VEIN_DRAIN_SECONDS := 0.25
const VEIN_SPARKS := 6
const VEIN_SPARK_SPEED := 0.5
const EMBEROO_SCALE := 4.0

var hovered_id: String = ""

var _positions: Dictionary[String, Vector2] = {}
## [from_id, to_id] for every vein, inner end first.
var _veins: Array[PackedStringArray] = []
## "from>to" -> 0..1, how far fire has travelled along the vein.
var _vein_fill: Dictionary[String, float] = {}
var _hover_scale: Dictionary[String, float] = {}
var _shown_learned: Dictionary[String, bool] = {}
var _time: float = 0.0
var _label_font: Font


func _ready() -> void:
	_label_font = ThemeDB.fallback_font
	_place_nodes()
	_build_veins()
	_add_emberoo()
	_add_drifting_embers()
	_sync_with_learned(false)
	EmberTree.changed.connect(_sync_with_learned.bind(true))
	Progression.skill_points_changed.connect(func(_points: int) -> void: queue_redraw())


func _process(delta: float) -> void:
	_time += delta
	var ease_amount := 1.0 - exp(-EASE_RATE * delta)
	for id in _hover_scale:
		var target := HOVER_SCALE if id == hovered_id else 1.0
		_hover_scale[id] = lerpf(_hover_scale[id], target, ease_amount)
	queue_redraw()


## The node under a point given in tree space, or "" if none.
func node_at(tree_point: Vector2) -> String:
	for node in EmberTreeData.all_nodes():
		if tree_point.distance_to(_positions[node.id]) <= NODE_RADIUS[node.kind] + HIT_MARGIN:
			return node.id
	return ""


# --- Setup ------------------------------------------------------------------

func _place_nodes() -> void:
	_positions[CENTRE_ID] = Vector2.ZERO
	for node in EmberTreeData.all_nodes():
		var angle := EmberTreeData.branch_angle(node.branch) + node.angle_offset
		_positions[node.id] = Vector2.from_angle(deg_to_rad(angle)) * TIER_RADII[node.tier]
		_hover_scale[node.id] = 1.0


func _build_veins() -> void:
	for node in EmberTreeData.all_nodes():
		var sources: PackedStringArray = node.requires if not node.requires.is_empty() else PackedStringArray([CENTRE_ID])
		for source in sources:
			_veins.append(PackedStringArray([source, node.id]))


## Emberoo's live idle animation in the middle of the tree.
func _add_emberoo() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = SpriteFrames.new()
	sprite.sprite_frames.remove_animation("default")
	var settings: Dictionary = CreatureAnimator.ANIMATION_SETTINGS["idle"]
	var sheet: Texture2D = load("res://art/emberoo/emberoo_front_idle_sheet.png")
	SpriteSheetLoader.add_animation(sprite.sprite_frames, "idle", sheet, settings["frame_durations"], true, CreatureAnimator.FRAME_SIZE)
	sprite.scale = Vector2.ONE * EMBEROO_SCALE
	add_child(sprite)
	sprite.play("idle")


## Slow embers drifting upward around the tree.
func _add_drifting_embers() -> void:
	var embers := CPUParticles2D.new()
	embers.amount = 60
	embers.lifetime = 5.0
	embers.preprocess = 5.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = TIER_RADII[-1]
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.gravity = Vector2(0, -8)
	embers.initial_velocity_min = 3.0
	embers.initial_velocity_max = 12.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.0
	embers.color_ramp = _fade_ramp(EmberTreePalette.GOLD, EmberTreePalette.ORANGE, EmberTreePalette.RED)
	add_child(embers)


# --- Reacting to learning -----------------------------------------------------

## Brings veins and glows in line with what EmberTree says is learned.
## When `animate` is false (opening the screen), everything snaps into place.
func _sync_with_learned(animate: bool) -> void:
	for vein in _veins:
		var key := _vein_key(vein)
		var target := 1.0 if _is_lit(vein[0]) and _is_lit(vein[1]) else 0.0
		var current: float = _vein_fill.get(key, 0.0)
		if not animate:
			_vein_fill[key] = target
		elif not is_equal_approx(current, target):
			_tween_vein(key, current, target)
	for node in EmberTreeData.all_nodes():
		var learned_now := EmberTree.is_learned(node.id)
		if animate and learned_now and not _shown_learned.has(node.id):
			_hover_scale[node.id] = LEARN_POP_SCALE
			get_tree().create_timer(VEIN_FILL_SECONDS).timeout.connect(_burst_at.bind(_positions[node.id]))
		if learned_now:
			_shown_learned[node.id] = true
		else:
			_shown_learned.erase(node.id)


func _tween_vein(key: String, from: float, to: float) -> void:
	var seconds := VEIN_FILL_SECONDS if to > from else VEIN_DRAIN_SECONDS
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float) -> void: _vein_fill[key] = value, from, to, seconds)


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
	burst.color_ramp = _fade_ramp(EmberTreePalette.CREAM, EmberTreePalette.ORANGE, EmberTreePalette.RED)
	burst.finished.connect(burst.queue_free)
	add_child(burst)
	burst.emitting = true


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	_draw_rings()
	for vein in _veins:
		_draw_vein(vein)
	_draw_branch_labels()
	_draw_centre()
	for node in EmberTreeData.all_nodes():
		_draw_node(node)


## One ring per tier: solid and warm where the stage is open, dashed and cold where it isn't.
func _draw_rings() -> void:
	for tier in TIER_RADII.size():
		var radius := TIER_RADII[tier]
		if EmberTree.is_stage_open(_stage_of_tier(tier)):
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, Color(EmberTreePalette.RED, 0.25), 1.5)
			continue
		var dashes := 64
		for dash in dashes:
			var start := TAU * dash / dashes
			draw_arc(Vector2.ZERO, radius, start, start + TAU / dashes * 0.45, 4, Color(EmberTreePalette.DIM, 0.7), 1.5)


func _draw_vein(vein: PackedStringArray) -> void:
	var from := _positions[vein[0]]
	var to := _positions[vein[1]]
	draw_line(from, to, EmberTreePalette.COAL, 3.0)
	var fill: float = _vein_fill.get(_vein_key(vein), 0.0)
	if fill <= 0.0:
		return
	var burning_end := from.lerp(to, fill)
	draw_line(from, burning_end, Color(EmberTreePalette.RED, 0.7), 6.0)
	draw_line(from, burning_end, EmberTreePalette.GOLD, 2.0)
	# Sparks travel along the burning part.
	for spark in VEIN_SPARKS:
		var along := fmod(_time * VEIN_SPARK_SPEED + float(spark) / VEIN_SPARKS, 1.0) * fill
		var point := from.lerp(to, along)
		draw_rect(Rect2(point.round() - Vector2(1.5, 1.5), Vector2(3, 3)), EmberTreePalette.CREAM)


func _draw_branch_labels() -> void:
	for branch: String in EmberTreeData.BRANCHES:
		var text := EmberTreeData.branch_title(branch).to_upper()
		var direction := Vector2.from_angle(deg_to_rad(EmberTreeData.branch_angle(branch)))
		var text_size := _label_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE)
		# Baseline sits below the text's middle by half the ascent, so the word centres on its spot.
		var middle := direction * BRANCH_LABEL_RADIUS
		var baseline := middle + Vector2(-text_size.x / 2.0, _label_font.get_ascent(BRANCH_LABEL_SIZE) / 2.0 - 1.0)
		var color: Color = EmberTreePalette.BRANCH_COLORS[branch]
		draw_string_outline(_label_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE, 6, EmberTreePalette.BACKGROUND)
		draw_string(_label_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE, Color(color, 0.9))


func _draw_centre() -> void:
	draw_circle(Vector2.ZERO, CENTRE_RADIUS, EmberTreePalette.BACKGROUND)
	draw_arc(Vector2.ZERO, CENTRE_RADIUS, 0.0, TAU, 96, EmberTreePalette.RED, 2.5)
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_arc(Vector2.ZERO, CENTRE_RADIUS + 6.0 + pulse * 3.0, 0.0, TAU, 96, Color(EmberTreePalette.ORANGE, 0.2 + 0.2 * pulse), 1.5)


func _draw_node(node: EmberTreeNode) -> void:
	var centre := _positions[node.id]
	var hover: float = _hover_scale[node.id]
	var state := _state_of(node.id)
	var radius: float = NODE_RADIUS[node.kind] * hover

	if state == "learned":
		_draw_halo(centre, radius)

	var fill: Color = {"learned": EmberTreePalette.DEEP, "available": EmberTreePalette.EMBER_DARK, "locked": EmberTreePalette.COAL}[state]
	var edge: Color = {"learned": EmberTreePalette.GOLD, "available": EmberTreePalette.CREAM, "locked": EmberTreePalette.DIM}[state]
	if state == "available":
		edge = Color(edge, 0.55 + 0.45 * sin(_time * 4.0))  # gentle pulse: "you can take this"

	if node.kind == Kind.STAT:
		draw_circle(centre, radius + OUTLINE_WIDTH, EmberTreePalette.OUTLINE)
		draw_circle(centre, radius, fill)
		draw_arc(centre, radius, 0.0, TAU, 48, edge, EDGE_WIDTH)
	else:
		_draw_diamond(centre, radius + OUTLINE_WIDTH, EmberTreePalette.OUTLINE, true)
		_draw_diamond(centre, radius, fill, true)
		_draw_diamond(centre, radius, edge, false)
		if node.kind == Kind.ULTIMATE:
			_draw_diamond(centre, radius - OUTLINE_WIDTH * 2.0, Color(edge, 0.5), false)

	var icon_color: Color = {"learned": EmberTreePalette.GOLD, "available": EmberTreePalette.CREAM, "locked": EmberTreePalette.DIM}[state]
	EmberTreeIcons.draw(self, node.icon, centre, ICON_PIXEL[node.kind] * hover, icon_color)


func _draw_halo(centre: Vector2, radius: float) -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 5.0 + centre.x)
	for halo: Array in [[18.0, 0.07], [11.0, 0.12], [5.0, 0.2]]:
		draw_circle(centre, radius + halo[0], Color(EmberTreePalette.ORANGE, halo[1] * flicker))


func _draw_diamond(centre: Vector2, radius: float, color: Color, filled: bool) -> void:
	var points := PackedVector2Array([
		centre + Vector2(0, -radius), centre + Vector2(radius, 0),
		centre + Vector2(0, radius), centre + Vector2(-radius, 0),
	])
	if filled:
		draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		draw_polyline(points, color, EDGE_WIDTH)


# --- Helpers -------------------------------------------------------------------

func _state_of(id: String) -> String:
	if EmberTree.is_learned(id):
		return "learned"
	if EmberTree.can_learn(id):
		return "available"
	return "locked"


func _is_lit(id: String) -> bool:
	return id == CENTRE_ID or EmberTree.is_learned(id)


func _stage_of_tier(tier: int) -> int:
	for node in EmberTreeData.all_nodes():
		if node.tier == tier:
			return node.stage
	return EmberTree.FIRST_STAGE


func _vein_key(vein: PackedStringArray) -> String:
	return "%s>%s" % [vein[0], vein[1]]


func _fade_ramp(start: Color, middle: Color, end: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([start, middle, Color(end, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	return ramp
