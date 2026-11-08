class_name EmberTreeSidePanel
extends Control
## The Ember Tree's side column: what the pointed-at thing is, and the skill points.
##
## All of the tree's words live here, beside the tree, so text never covers a node.
## Top card shows one of three things: the pointed-at node, the pointed-at branch, or
## (with nothing pointed at) how the screen works, with a small legend.
## Bottom card: points, where they come from, and the free Reset.

signal reset_pressed

const Kind := EmberTreeNode.Kind

const CARD_PADDING := 12
const CARD_CORNER := 4
const LINE_GAP := 5
## Pulls wrapped lines a little closer than the font's default, so text takes less height.
const WRAPPED_LINE_SPACING := -1
## The info card slides in from this far right when it changes, instead of popping.
const SLIDE_DISTANCE := 8.0
const SLIDE_SECONDS := 0.16

const KIND_NAMES := {Kind.SKILL: "SKILL", Kind.UPGRADE: "UPGRADE", Kind.STAT: "STAT", Kind.ULTIMATE: "ULTIMATE"}
## Colour of the status line for each node state (see EmberTreeCanvas.state_of).
const STATE_COLORS := {"learned": EmberTreePalette.GOLD, "available": EmberTreePalette.CREAM, "locked": EmberTreePalette.GREY, "sealed": EmberTreePalette.GREY}

const OVERVIEW_TITLE := "How the tree works"
const OVERVIEW_TEXT := "Ignite embers to change how Emberoo fights. Each costs 1 skill point, and you earn 1 skill point per level.\nThe inner ring is Stage 1. The outer rings unlock when Emberoo evolves."
const OVERVIEW_TAG := "POINT AT A BRANCH NAME OR AN EMBER"
const COMING_SOON_BADGE := "COMING SOON"
const COMING_SOON_NOTE := "Effect not in the game yet"
const POINTS_SOURCE := "+1 per level"
const BRANCH_KEY_PREFIX := "branch:"

var _info_card: PanelContainer
var _title: Label
var _tag: Label
var _description: Label
var _legend: EmberTreeLegend
var _coming_soon_row: HBoxContainer
var _status: Label
var _points_value: Label
var _reset_button: Button
## What the info card shows: a node id, "branch:<branch>", or "" for the overview.
## Starts as something no hover can be, so the first show always slides in.
var _shown_key: String = "-"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_info_card()
	_build_points_card()
	EmberTree.changed.connect(_refresh)
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
		_fill_branch(_shown_key.trim_prefix(BRANCH_KEY_PREFIX))
	elif EmberTreeData.find(_shown_key) != null:
		_fill_node(EmberTreeData.find(_shown_key))
	else:
		_fill_overview()
	_info_card.reset_size()  # shrink to fit the new text
	_info_card.size.x = size.x
	_refresh_points()


# --- Building -------------------------------------------------------------------

func _build_info_card() -> void:
	_info_card = _make_card()
	_info_card.size.x = size.x
	add_child(_info_card)
	var column := _make_column(_info_card)
	_title = _add_label(column, 15, EmberTreePalette.CREAM)
	_tag = _add_label(column, 9, EmberTreePalette.ORANGE)
	_add_divider(column)
	_description = _add_label(column, 10, EmberTreePalette.CREAM)
	_legend = EmberTreeLegend.new()
	column.add_child(_legend)
	_coming_soon_row = _make_coming_soon_row()
	column.add_child(_coming_soon_row)
	_status = _add_label(column, 10, EmberTreePalette.GREY)


## A small "COMING SOON" badge and a short note, for nodes whose effect is not built yet.
func _make_coming_soon_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := PanelContainer.new()
	var badge_style := _card_style(EmberTreePalette.EMBER_DARK, Color(EmberTreePalette.ORANGE, 0.7))
	badge_style.shadow_size = 0
	badge_style.set_corner_radius_all(3)
	badge_style.content_margin_left = 5
	badge_style.content_margin_right = 5
	badge_style.content_margin_top = 1
	badge_style.content_margin_bottom = 1
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_text := _make_label(8, EmberTreePalette.ORANGE)
	badge_text.text = COMING_SOON_BADGE
	badge.add_child(badge_text)
	row.add_child(badge)
	var note := _make_label(9, EmberTreePalette.GREY)
	note.text = COMING_SOON_NOTE
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(note)
	return row


func _build_points_card() -> void:
	var card := _make_card()
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_KEEP_WIDTH)
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(card)
	# One row (points on the left, Reset on the right) keeps this card short,
	# leaving the info card above it room for long descriptions.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var points_column := VBoxContainer.new()
	points_column.add_theme_constant_override("separation", -2)
	points_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(points_column)
	var points_line := HBoxContainer.new()
	points_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	points_column.add_child(points_line)
	var caption := _make_label(9, EmberTreePalette.GREY)
	caption.text = "SKILL POINTS"
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_line.add_child(caption)
	_points_value = _make_label(16, EmberTreePalette.GOLD)
	_points_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_line.add_child(_points_value)
	var source := _make_label(9, EmberTreePalette.ORANGE)
	source.text = POINTS_SOURCE
	points_column.add_child(source)
	_reset_button = _make_button("Reset  ·  free")
	_reset_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_reset_button.pressed.connect(reset_pressed.emit)
	row.add_child(_reset_button)


# --- Filling in -------------------------------------------------------------------

## With nothing pointed at: what the tree is, where points come from, a legend, and a
## nudge to point at things.
func _fill_overview() -> void:
	_set_title(OVERVIEW_TITLE, EmberTreePalette.CREAM)
	_tag.text = OVERVIEW_TAG
	_tag.visible = true
	_description.text = OVERVIEW_TEXT
	_legend.visible = true
	_coming_soon_row.visible = false
	_status.visible = false


## A branch: what it is about in a few words, how it plays, and how much is ignited.
func _fill_branch(branch: String) -> void:
	_set_title(EmberTreeData.branch_title(branch), EmberTreePalette.BRANCH_COLORS[branch])
	_tag.text = "BRANCH  ·  %s" % EmberTreeData.branch_theme(branch).to_upper()
	_tag.visible = true
	_description.text = EmberTreeData.branch_playstyle(branch)
	_legend.visible = false
	_coming_soon_row.visible = false
	var ignited := 0
	var open := 0
	var sealed := 0
	for node in EmberTreeData.nodes_in_branch(branch):
		if EmberTree.is_learned(node.id):
			ignited += 1
		if EmberTree.is_stage_open(node.stage):
			open += 1
		else:
			sealed += 1
	var status := "%d of %d ignited" % [ignited, open]
	if sealed > 0:
		status += "  ·  %d more after evolving" % sealed
	_set_status(status, EmberTreePalette.GOLD if ignited > 0 else EmberTreePalette.GREY)


## A node: name, "BRANCH · TYPE · STAGE", what it does, then where it stands.
func _fill_node(node: EmberTreeNode) -> void:
	_set_title(node.title, EmberTreePalette.CREAM)
	_tag.text = "%s  ·  %s  ·  STAGE %d" % [EmberTreeData.branch_title(node.branch).to_upper(), KIND_NAMES[node.kind], node.stage]
	_tag.visible = true
	_description.text = node.description
	_legend.visible = false
	_coming_soon_row.visible = not node.has_working_effect()
	var state := EmberTreeCanvas.state_of(node)
	_set_status(_status_text(node, state), STATE_COLORS[state])


func _set_title(text: String, color: Color) -> void:
	_title.text = text
	_title.add_theme_color_override("font_color", color)


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
	_status.visible = true


## One line on where the node stands: Ignited, Can ignite, Not enough points,
## Needs: <node>, or Locked until evolution.
func _status_text(node: EmberTreeNode, state: String) -> String:
	match state:
		"learned":
			if EmberTree.can_unlearn(node.id):
				return "Ignited  ·  right-click to put out (free)"
			return "Ignited  ·  put out the embers beyond it first"
		"available":
			return "Can ignite  ·  click to spend 1 skill point"
		"sealed":
			return "Locked  ·  unlocks when Emberoo evolves (Stage %d)" % node.stage
	if EmberTree.is_reachable(node.id):
		return "Not enough points  ·  earn 1 each level"
	return "Needs: %s" % _required_titles(node)


## The names of the nodes that lead to this one, e.g. "Meteor Fist or Heat Sink".
func _required_titles(node: EmberTreeNode) -> String:
	var titles := PackedStringArray()
	for required_id in node.requires:
		titles.append(EmberTreeData.find(required_id).title)
	return " or ".join(titles)


func _refresh_points() -> void:
	_points_value.text = str(Progression.skill_points)
	_reset_button.disabled = EmberTree.learned_ids().is_empty()


func _slide_in() -> void:
	_info_card.modulate.a = 0.0
	_info_card.position.x = SLIDE_DISTANCE
	var slide := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(_info_card, "modulate:a", 1.0, SLIDE_SECONDS)
	slide.tween_property(_info_card, "position:x", 0.0, SLIDE_SECONDS)


# --- Small builders -----------------------------------------------------------------

func _make_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style(EmberTreePalette.PANEL, EmberTreePalette.PANEL_EDGE))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


func _make_column(card: PanelContainer) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", LINE_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	return column


func _add_label(column: VBoxContainer, font_size: int, color: Color) -> Label:
	var label := _make_label(font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", WRAPPED_LINE_SPACING)
	label.custom_minimum_size.x = size.x - CARD_PADDING * 2
	column.add_child(label)
	return label


func _add_divider(column: VBoxContainer) -> void:
	var divider := ColorRect.new()
	divider.color = Color(EmberTreePalette.ORANGE, 0.3)
	divider.custom_minimum_size = Vector2(size.x - CARD_PADDING * 2, 1)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	# No keyboard focus: Tab toggles the tree and must not move focus to the button instead.
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", EmberTreePalette.CREAM)
	button.add_theme_color_override("font_hover_color", EmberTreePalette.GOLD)
	button.add_theme_color_override("font_pressed_color", EmberTreePalette.GOLD)
	button.add_theme_color_override("font_disabled_color", EmberTreePalette.DIM)
	button.add_theme_stylebox_override("normal", _button_style(EmberTreePalette.EMBER_DARK, Color(EmberTreePalette.ORANGE, 0.5)))
	button.add_theme_stylebox_override("hover", _button_style(EmberTreePalette.DEEP, EmberTreePalette.GOLD))
	button.add_theme_stylebox_override("pressed", _button_style(EmberTreePalette.DEEP, EmberTreePalette.GOLD))
	button.add_theme_stylebox_override("disabled", _button_style(EmberTreePalette.COAL, Color(EmberTreePalette.DIM, 0.6)))
	return button


func _card_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(CARD_CORNER)
	style.set_content_margin_all(CARD_PADDING)
	style.shadow_color = Color(EmberTreePalette.BACKGROUND, 0.35)
	style.shadow_size = 6
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := _card_style(background, border)
	style.shadow_size = 0
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
