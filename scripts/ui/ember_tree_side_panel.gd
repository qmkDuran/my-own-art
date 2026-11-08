class_name EmberTreeSidePanel
extends Control
## The Ember Tree's right-hand column: the info card about the pointed-at thing, and the
## skill points card at the bottom.
##
## All of the tree's words live in the side columns, so text never covers a node.
## Bottom card: points, where they come from, and the free Reset.

signal reset_pressed

## The info card slides in from this far right when it changes, instead of popping.
const SLIDE_DISTANCE := 8.0
const SLIDE_SECONDS := 0.16
const POINTS_SOURCE := "+1 per level"
const BRANCH_KEY_PREFIX := "branch:"

var _info_card: EmberTreeInfoCard
var _points_value: Label
var _reset_button: Button
## What the info card shows: a node id, "branch:<branch>", or "" for the overview.
## Starts as something no hover can be, so the first show always slides in.
var _shown_key: String = "-"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_card = EmberTreeInfoCard.new(size.x)
	add_child(_info_card)
	_build_points_card()
	# Deferred, so stat changes from EmberTreeEffects land before the numbers are read.
	EmberTree.changed.connect(_refresh, CONNECT_DEFERRED)
	Progression.skill_points_changed.connect(func(_points: int) -> void: _refresh())
	show_node("")


## Shows what a node does, or the overview when `id` is "".
func show_node(id: String) -> void:
	_show(id)


## Shows what a branch is about and how much of it is ignited.
func show_branch(branch: String) -> void:
	_show(BRANCH_KEY_PREFIX + branch)


func _show(key: String) -> void:
	var is_new := key != _shown_key
	_shown_key = key
	_refresh()
	if is_new:
		_slide_in()


func _refresh() -> void:
	if _shown_key.begins_with(BRANCH_KEY_PREFIX):
		_info_card.fill_branch(_shown_key.trim_prefix(BRANCH_KEY_PREFIX))
	elif EmberTreeData.find(_shown_key) != null:
		_info_card.fill_node(EmberTreeData.find(_shown_key), PlayerFinder.find(self))
	else:
		_info_card.fill_overview()
	_points_value.text = str(Progression.skill_points)
	_reset_button.disabled = EmberTree.learned_ids().is_empty()


func _build_points_card() -> void:
	var card := EmberTreeWidgets.make_card()
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_KEEP_WIDTH)
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(card)
	# One row (points on the left, Reset on the right) keeps this card short,
	# leaving the info card above it room for long descriptions.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var points_column := VBoxContainer.new()
	points_column.add_theme_constant_override("separation", 0)
	points_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(points_column)
	var points_line := HBoxContainer.new()
	points_line.add_theme_constant_override("separation", 8)
	points_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	points_column.add_child(points_line)
	var caption := UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, "SKILL POINTS")
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_line.add_child(caption)
	_points_value = UiLabel.make(EmberTreeFonts.LARGE_SIZE, EmberTreePalette.GOLD)
	_points_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_line.add_child(_points_value)
	points_column.add_child(UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.ORANGE, POINTS_SOURCE))
	_reset_button = EmberTreeWidgets.make_button("Reset  ∙  free")
	_reset_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_reset_button.pressed.connect(reset_pressed.emit)
	row.add_child(_reset_button)


func _slide_in() -> void:
	_info_card.modulate.a = 0.0
	_info_card.position.x = SLIDE_DISTANCE
	var slide := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(_info_card, "modulate:a", 1.0, SLIDE_SECONDS)
	slide.tween_property(_info_card, "position:x", 0.0, SLIDE_SECONDS)
