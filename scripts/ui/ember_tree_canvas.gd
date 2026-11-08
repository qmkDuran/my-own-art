class_name EmberTreeCanvas
extends Node2D
## Draws the radial Ember Tree around Emberoo: rings, flame veins, embers and coals.
##
## Drawn in "tree space" with Emberoo at (0, 0) (see EmberTreeLayout); EmberTreeView zooms
## and pans this node. Skills and upgrades are diamond embers, stat picks are round coals
## (DESIGN.md). Learned nodes glow, learnable ones pulse, locked ones stay cold coal, and
## nodes on a ring that has not opened yet are fainter still, with a padlock.
## Learning sends fire along the vein, then the ember flares. The branch names can be
## pointed at too: the pointed-at branch's nodes and veins light up in its colour.
## The nodes and the words are drawn by EmberTreeNodePainter and EmberTreeLabelPainter.

const CENTRE_ID := EmberTreeLayout.CENTRE_ID
## Extra pixels around a node that still count as pointing at it.
const HIT_MARGIN := 2.0
const LEARN_POP_SCALE := 1.5
## How quickly hover and pop sizes ease back (higher = snappier).
const EASE_RATE := 14.0
const VEIN_FILL_SECONDS := 0.4
const VEIN_DRAIN_SECONDS := 0.25
const VEIN_SPARKS := 6
const VEIN_SPARK_SPEED := 0.5
const EMBEROO_SCALE := 4.0
const EMBEROO_IDLE_SHEET := "res://art/emberoo/emberoo_front_idle_sheet.png"

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
var _label_painter: EmberTreeLabelPainter


func _ready() -> void:
	_label_painter = EmberTreeLabelPainter.new()
	_place_nodes()
	_build_veins()
	_add_emberoo()
	add_child(EmberTreeParticles.make_drifting_embers(EmberTreeLayout.TIER_RADII[-1]))
	_sync_with_learned(false)
	EmberTree.changed.connect(_sync_with_learned.bind(true))
	Progression.skill_points_changed.connect(func(_points: int) -> void: queue_redraw())


func _process(delta: float) -> void:
	_time += delta
	var ease_amount := 1.0 - exp(-EASE_RATE * delta)
	for id in _hover_scale:
		var target := EmberTreeLayout.HOVER_SCALE if id == hovered_id else 1.0
		_hover_scale[id] = lerpf(_hover_scale[id], target, ease_amount)
	queue_redraw()


## The node under a point given in tree space, or "" if none.
func node_at(tree_point: Vector2) -> String:
	for node in EmberTreeData.all_nodes():
		if tree_point.distance_to(_positions[node.id]) <= EmberTreeLayout.NODE_RADIUS[node.kind] + HIT_MARGIN:
			return node.id
	return ""


## The branch whose name is under a point given in tree space, or "" if none.
func branch_at(tree_point: Vector2) -> String:
	for branch: String in EmberTreeData.BRANCHES:
		if EmberTreeLayout.branch_label_rect(branch).has_point(tree_point):
			return branch
	return ""


# --- Setup ------------------------------------------------------------------

func _place_nodes() -> void:
	_positions[CENTRE_ID] = Vector2.ZERO
	for node in EmberTreeData.all_nodes():
		_positions[node.id] = EmberTreeLayout.node_position(node)
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
	var sheet: Texture2D = load(EMBEROO_IDLE_SHEET)
	SpriteSheetLoader.add_animation(sprite.sprite_frames, "idle", sheet, settings["frame_durations"], true, CreatureAnimator.FRAME_SIZE)
	sprite.scale = Vector2.ONE * EMBEROO_SCALE
	add_child(sprite)
	sprite.play("idle")


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
	var burst := EmberTreeParticles.make_ignite_burst(point)
	add_child(burst)
	burst.emitting = true


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	_draw_rings()
	for vein in _veins:
		_draw_vein(vein)
	_label_painter.draw_ring_captions(self)
	_label_painter.draw_branch_labels(self, hovered_branch)
	_draw_centre()
	for node in EmberTreeData.all_nodes():
		EmberTreeNodePainter.draw_node(self, node, _positions[node.id], _hover_scale[node.id], _time, _highlight_for(node.id))


## One ring per tier: solid and warm where the stage is open, dashed and cold where it isn't.
func _draw_rings() -> void:
	var radii := EmberTreeLayout.TIER_RADII
	for tier in radii.size():
		var radius := radii[tier]
		if EmberTree.is_stage_open(EmberTreeLayout.stage_of_tier(tier)):
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
		draw_line(from, to, Color(_hovered_branch_color(), 0.3), 8.0)
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


func _draw_centre() -> void:
	var radius := EmberTreeLayout.CENTRE_RADIUS
	draw_circle(Vector2.ZERO, radius, EmberTreePalette.BACKGROUND)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, EmberTreePalette.RED, 2.5)
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_arc(Vector2.ZERO, radius + 6.0 + pulse * 3.0, 0.0, TAU, 96, Color(EmberTreePalette.ORANGE, 0.2 + 0.2 * pulse), 1.5)


# --- Helpers -------------------------------------------------------------------

## The ring colour around a node: cream while it is pointed at, its branch's colour while
## its branch name is, and fully see-through otherwise.
func _highlight_for(id: String) -> Color:
	if id == hovered_id:
		return Color(EmberTreePalette.CREAM, 0.5)
	if _is_in_hovered_branch(id):
		return Color(_hovered_branch_color(), 0.6)
	return Color.TRANSPARENT


func _is_in_hovered_branch(id: String) -> bool:
	if hovered_branch == "":
		return false
	var node := EmberTreeData.find(id)
	return node != null and node.branch == hovered_branch


func _hovered_branch_color() -> Color:
	return EmberTreePalette.BRANCH_COLORS[hovered_branch]


func _is_lit(id: String) -> bool:
	return id == CENTRE_ID or EmberTree.is_learned(id)


func _vein_key(vein: PackedStringArray) -> String:
	return "%s>%s" % [vein[0], vein[1]]
