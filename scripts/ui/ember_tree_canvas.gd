class_name EmberTreeCanvas
extends Node2D
## Draws the radial Ember Tree around Emberoo: rings, flame veins, embers and coals.
##
## Drawn in "tree space" with Emberoo at (0, 0); EmberTreeView zooms and pans this node.
## Skills and upgrades are diamond embers, stat picks are round coals (DESIGN.md).
## Learned nodes glow, learnable ones pulse, locked ones stay cold coal, and nodes on a
## ring that has not opened yet are fainter still, with a padlock.
## Learning sends fire along the vein, then the ember flares. The branch names can be
## pointed at too: the pointed-at branch's nodes and veins light up in its colour.

const Kind := EmberTreeNode.Kind

## Distance from Emberoo for each tier, in tree pixels. Tiers 0-2 = Stage 1, 3 = Stage 2, 4 = Stage 3.
const TIER_RADII: Array[float] = [92.0, 142.0, 192.0, 266.0, 336.0]
## Branch names sit in the gap between the Stage 1 and Stage 2 rings.
const BRANCH_LABEL_RADIUS := 238.0
const BRANCH_LABEL_SIZE := 18
## Room around a branch name that still counts as pointing at it, and that its hover pill fills.
const BRANCH_LABEL_PADDING := Vector2(8.0, 5.0)
## Capital letters are about this tall for each pixel of font size; used to centre words on a spot.
const CAP_HEIGHT_RATIO := 0.72
## Words written along a closed ring ("STAGE 2 · EVOLVE TO UNLOCK"), per stage.
const RING_CAPTION_SIZE := 12
const RING_CAPTIONS := {2: "STAGE 2  ·  EVOLVE TO UNLOCK", 3: "STAGE 3  ·  ULTIMATES"}
## Where each stage's caption sits, in degrees: in the upper gaps between branches, clear
## of the nodes. Stage 3 only uses the left gap, nudged up so it stays on screen at the
## opening zoom (the right-hand one would hide under the side panel).
const RING_CAPTION_ANGLES := {2: [-30.0, -150.0], 3: [-143.0]}
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
## Gap between a node and the ring drawn around it when it, or its branch, is pointed at.
const HIGHLIGHT_GAP := 6.0
const LOCK_BADGE_RADIUS := 8.0
const LEARN_POP_SCALE := 1.5
## How quickly hover and pop sizes ease back (higher = snappier).
const EASE_RATE := 14.0
const VEIN_FILL_SECONDS := 0.4
const VEIN_DRAIN_SECONDS := 0.25
const VEIN_SPARKS := 6
const VEIN_SPARK_SPEED := 0.5
const EMBEROO_SCALE := 4.0

var hovered_id: String = ""
## The branch whose name is pointed at, or "" for none.
var hovered_branch: String = ""

var _positions: Dictionary[String, Vector2] = {}
## [from_id, to_id] for every vein, inner end first.
var _veins: Array[PackedStringArray] = []
## "from>to" -> 0..1, how far fire has travelled along the vein.
var _vein_fill: Dictionary[String, float] = {}
var _hover_scale: Dictionary[String, float] = {}
var _shown_learned: Dictionary[String, bool] = {}
var _time: float = 0.0
var _label_font: Font
## Branch -> the pill drawn behind its name while pointed at (built once, in its colour).
var _label_pills: Dictionary[String, StyleBoxFlat] = {}


func _ready() -> void:
	_label_font = ThemeDB.fallback_font
	for branch: String in EmberTreeData.BRANCHES:
		_label_pills[branch] = _make_label_pill(_branch_color(branch))
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


## The branch whose name is under a point given in tree space, or "" if none.
func branch_at(tree_point: Vector2) -> String:
	for branch: String in EmberTreeData.BRANCHES:
		if branch_label_rect(branch).has_point(tree_point):
			return branch
	return ""


## Where a node sits in tree space: out along its branch, one ring per tier.
static func node_position(node: EmberTreeNode) -> Vector2:
	var angle := EmberTreeData.branch_angle(node.branch) + node.angle_offset
	return Vector2.from_angle(deg_to_rad(angle)) * TIER_RADII[node.tier]


## The box around a branch's name in tree space, padding included (what hovering hits).
static func branch_label_rect(branch: String) -> Rect2:
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(_branch_label_text(branch), HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE).x
	var text_size := Vector2(text_width, BRANCH_LABEL_SIZE * CAP_HEIGHT_RATIO)
	var middle := _branch_label_middle(branch)
	return Rect2(middle - text_size / 2.0, text_size).grow_individual(
		BRANCH_LABEL_PADDING.x, BRANCH_LABEL_PADDING.y, BRANCH_LABEL_PADDING.x, BRANCH_LABEL_PADDING.y)


## What must be on screen when the tree opens: every Stage 1 node (at hover size) and
## every branch name. Later rings may spill past the edges.
static func opening_bounds() -> Rect2:
	var bounds := Rect2(-Vector2.ONE * CENTRE_RADIUS, Vector2.ONE * CENTRE_RADIUS * 2.0)
	for node in EmberTreeData.all_nodes():
		if node.stage == EmberTree.FIRST_STAGE:
			var reach: float = NODE_RADIUS[node.kind] * HOVER_SCALE + OUTLINE_WIDTH
			bounds = bounds.merge(Rect2(node_position(node) - Vector2.ONE * reach, Vector2.ONE * reach * 2.0))
	for branch: String in EmberTreeData.BRANCHES:
		bounds = bounds.merge(branch_label_rect(branch))
	return bounds


static func _branch_label_text(branch: String) -> String:
	return EmberTreeData.branch_title(branch).to_upper()


static func _branch_label_middle(branch: String) -> Vector2:
	return Vector2.from_angle(deg_to_rad(EmberTreeData.branch_angle(branch))) * BRANCH_LABEL_RADIUS


# --- Setup ------------------------------------------------------------------

func _place_nodes() -> void:
	_positions[CENTRE_ID] = Vector2.ZERO
	for node in EmberTreeData.all_nodes():
		_positions[node.id] = node_position(node)
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
	_draw_ring_captions()
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
	if _is_in_hovered_branch(vein[1]):
		draw_line(from, to, Color(_branch_color(hovered_branch), 0.3), 8.0)
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


## Says what each closed ring is, in small letters that follow the ring's curve.
func _draw_ring_captions() -> void:
	for tier in TIER_RADII.size():
		var stage := _stage_of_tier(tier)
		if EmberTree.is_stage_open(stage) or not RING_CAPTIONS.has(stage) or _stage_of_tier(tier - 1) == stage:
			continue
		for angle: float in RING_CAPTION_ANGLES[stage]:
			_draw_text_along_ring(RING_CAPTIONS[stage], TIER_RADII[tier], deg_to_rad(angle), EmberTreePalette.GREY)


## Writes `text` centred on the ring at `middle_angle`, reading clockwise, one letter at a time.
func _draw_text_along_ring(text: String, radius: float, middle_angle: float, color: Color) -> void:
	var width := _label_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, RING_CAPTION_SIZE).x
	var travelled := -width / 2.0
	var half_cap := RING_CAPTION_SIZE * CAP_HEIGHT_RATIO / 2.0
	for letter_index in text.length():
		var letter := text.unicode_at(letter_index)
		var letter_width := _label_font.get_char_size(letter, RING_CAPTION_SIZE).x
		var angle := middle_angle + (travelled + letter_width / 2.0) / radius
		draw_set_transform(Vector2.from_angle(angle) * radius, angle + PI / 2.0)
		var baseline := Vector2(-letter_width / 2.0, half_cap)
		draw_char_outline(_label_font, baseline, String.chr(letter), RING_CAPTION_SIZE, 4, EmberTreePalette.BACKGROUND)
		draw_char(_label_font, baseline, String.chr(letter), RING_CAPTION_SIZE, color)
		travelled += letter_width
	draw_set_transform(Vector2.ZERO)


## Branch names look like something to point at: a faint underline at rest, and a lit pill
## in the branch's colour while pointed at.
func _draw_branch_labels() -> void:
	for branch: String in EmberTreeData.BRANCHES:
		var text := _branch_label_text(branch)
		var color := _branch_color(branch)
		var is_hovered := branch == hovered_branch
		var box := branch_label_rect(branch)
		if is_hovered:
			draw_style_box(_label_pills[branch], box)
		var text_width := _label_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE).x
		var middle := _branch_label_middle(branch)
		var baseline := middle + Vector2(-text_width / 2.0, BRANCH_LABEL_SIZE * CAP_HEIGHT_RATIO / 2.0)
		draw_string_outline(_label_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE, 6, EmberTreePalette.BACKGROUND)
		draw_string(_label_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE, color if is_hovered else Color(color, 0.85))
		if not is_hovered:  # the pill takes over from the underline
			var underline_y := baseline.y + 4.0
			draw_line(Vector2(middle.x - text_width / 2.0, underline_y), Vector2(middle.x + text_width / 2.0, underline_y), Color(color, 0.35), 1.5)


func _make_label_pill(color: Color) -> StyleBoxFlat:
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(EmberTreePalette.EMBER_DARK, 0.9)
	pill.border_color = Color(color, 0.7)
	pill.set_border_width_all(2)
	pill.set_corner_radius_all(6)
	return pill


func _draw_centre() -> void:
	draw_circle(Vector2.ZERO, CENTRE_RADIUS, EmberTreePalette.BACKGROUND)
	draw_arc(Vector2.ZERO, CENTRE_RADIUS, 0.0, TAU, 96, EmberTreePalette.RED, 2.5)
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_arc(Vector2.ZERO, CENTRE_RADIUS + 6.0 + pulse * 3.0, 0.0, TAU, 96, Color(EmberTreePalette.ORANGE, 0.2 + 0.2 * pulse), 1.5)


func _draw_node(node: EmberTreeNode) -> void:
	var centre := _positions[node.id]
	var hover: float = _hover_scale[node.id]
	var state := state_of(node)
	var radius: float = NODE_RADIUS[node.kind] * hover

	if state == "learned":
		_draw_halo(centre, radius)
	if node.id == hovered_id:
		_draw_outline_shape(node.kind, centre, radius + HIGHLIGHT_GAP, Color(EmberTreePalette.CREAM, 0.5))
	elif _is_in_hovered_branch(node.id):
		_draw_outline_shape(node.kind, centre, radius + HIGHLIGHT_GAP, Color(_branch_color(hovered_branch), 0.6))

	var fill: Color = EmberTreePalette.NODE_FILL[state]
	var edge: Color = EmberTreePalette.NODE_EDGE[state]
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

	EmberTreeIcons.draw(self, node.icon, centre, ICON_PIXEL[node.kind] * hover, EmberTreePalette.NODE_ICON[state])
	if state == "sealed":
		_draw_lock_badge(centre + Vector2.ONE * radius * 0.6)


## A small padlock on a node whose ring opens only when Emberoo evolves.
func _draw_lock_badge(centre: Vector2) -> void:
	draw_circle(centre, LOCK_BADGE_RADIUS + 2.0, EmberTreePalette.OUTLINE)
	draw_circle(centre, LOCK_BADGE_RADIUS, EmberTreePalette.COAL)
	draw_arc(centre, LOCK_BADGE_RADIUS, 0.0, TAU, 24, EmberTreePalette.DIM, 1.5)
	EmberTreeIcons.draw(self, "lock", centre, 1.5, EmberTreePalette.GREY)


## A thin ring around a node in its own shape: a circle for stats, a diamond for the rest.
func _draw_outline_shape(kind: Kind, centre: Vector2, radius: float, color: Color) -> void:
	if kind == Kind.STAT:
		draw_arc(centre, radius, 0.0, TAU, 48, color, 2.0)
	else:
		_draw_diamond(centre, radius * 1.1, color, false)


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

## "learned", "available" (can be ignited now), "locked" (needs a node or a point first)
## or "sealed" (its ring opens only when Emberoo evolves).
static func state_of(node: EmberTreeNode) -> String:
	if EmberTree.is_learned(node.id):
		return "learned"
	if EmberTree.can_learn(node.id):
		return "available"
	if not EmberTree.is_stage_open(node.stage):
		return "sealed"
	return "locked"


func _is_in_hovered_branch(id: String) -> bool:
	if hovered_branch == "":
		return false
	var node := EmberTreeData.find(id)
	return node != null and node.branch == hovered_branch


func _branch_color(branch: String) -> Color:
	return EmberTreePalette.BRANCH_COLORS[branch]


func _is_lit(id: String) -> bool:
	return id == CENTRE_ID or EmberTree.is_learned(id)


## The evolution stage a tier belongs to (0 for a tier before the first, so it never matches).
func _stage_of_tier(tier: int) -> int:
	if tier < 0:
		return 0
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
