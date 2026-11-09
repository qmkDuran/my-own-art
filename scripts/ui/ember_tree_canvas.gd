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
## The veins, nodes and words are drawn by EmberTreeVeins, EmberTreeNodePainter and
## EmberTreeLabelPainter. Back to front: rings, veins, words, Emberoo, every glow, every
## node, and last the pointed-at node, so its highlight is never under a neighbour.

const CENTRE_ID := EmberTreeLayout.CENTRE_ID
## Extra pixels around a node that still count as pointing at it.
const HIT_MARGIN := 2.0
const LEARN_POP_SCALE := 1.5
## How quickly hover and pop sizes ease back (higher = snappier).
const EASE_RATE := 14.0
const EMBEROO_SCALE := 4.0
const EMBEROO_IDLE_SHEET := "res://art/emberoo/emberoo_front_idle_sheet.png"

var hovered_id: String = ""
## The branch whose name is pointed at, or "" for none.
var hovered_branch: String = ""

var _positions: Dictionary[String, Vector2] = {}
var _veins: EmberTreeVeins
var _hover_scale: Dictionary[String, float] = {}
var _shown_learned: Dictionary[String, bool] = {}
var _time: float = 0.0
var _label_painter: EmberTreeLabelPainter
## Emberoo in the middle of the tree, recoloured when his Awakening stage changes.
var _emberoo_sprite: AnimatedSprite2D


func _ready() -> void:
	_label_painter = EmberTreeLabelPainter.new()
	_place_nodes()
	_veins = EmberTreeVeins.new(_positions)
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


## Emberoo's live idle animation in the middle of the tree, in his Awakened look.
func _add_emberoo() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = SpriteFrames.new()
	sprite.sprite_frames.remove_animation("default")
	var settings: Dictionary = CreatureAnimator.ANIMATION_SETTINGS["idle"]
	var sheet: Texture2D = load(EMBEROO_IDLE_SHEET)
	SpriteSheetLoader.add_animation(sprite.sprite_frames, "idle", sheet, settings["frame_durations"], true, CreatureAnimator.FRAME_SIZE)
	sprite.scale = Vector2.ONE * EMBEROO_SCALE
	EmberooFlameMarker.mark_frames(sprite.sprite_frames)
	AwakeningPalette.apply(sprite, Awakening.stage)
	_emberoo_sprite = sprite
	# A method (not a lambda) so Godot drops the connection when this canvas is freed.
	Awakening.stage_changed.connect(_on_awakening_stage_changed)
	add_child(sprite)
	sprite.play("idle")


# --- Reacting to learning -----------------------------------------------------

## Brings veins and glows in line with what EmberTree says is learned.
## When `animate` is false (opening the screen), everything snaps into place.
func _sync_with_learned(animate: bool) -> void:
	_veins.sync(self, animate)
	for node in EmberTreeData.all_nodes():
		var learned_now := EmberTree.is_learned(node.id)
		if animate and learned_now and not _shown_learned.has(node.id):
			_hover_scale[node.id] = LEARN_POP_SCALE
			get_tree().create_timer(EmberTreeVeins.FILL_SECONDS).timeout.connect(_burst_at.bind(_positions[node.id]))
		if learned_now:
			_shown_learned[node.id] = true
		else:
			_shown_learned.erase(node.id)


func _burst_at(point: Vector2) -> void:
	var burst := EmberTreeParticles.make_ignite_burst(point)
	add_child(burst)
	burst.emitting = true


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	_draw_rings()
	var branch_glow: Color = EmberTreePalette.BRANCH_COLORS.get(hovered_branch, Color.TRANSPARENT)
	_veins.draw(self, _time, hovered_branch, branch_glow)
	_label_painter.draw_ring_captions(self)
	_label_painter.draw_branch_labels(self, hovered_branch)
	_draw_centre()
	for node in EmberTreeData.all_nodes():
		if EmberTree.is_learned(node.id):
			EmberTreeNodePainter.draw_halo(self, node, _positions[node.id], _hover_scale[node.id], _time)
	for node in EmberTreeData.all_nodes():
		if node.id != hovered_id:
			_draw_node(node)
	if EmberTreeData.find(hovered_id) != null:
		_draw_node(EmberTreeData.find(hovered_id))


func _draw_node(node: EmberTreeNode) -> void:
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


func _on_awakening_stage_changed(stage: int) -> void:
	if is_instance_valid(_emberoo_sprite):
		AwakeningPalette.apply(_emberoo_sprite, stage)
