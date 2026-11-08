class_name EmberTreeSidePanel
extends Control
## The Ember Tree's side column: what the pointed-at node does, and the skill points.
##
## All of the tree's words live here, beside the tree, so text never covers a node.
## Top card: the hovered node (or an overview). Bottom card: points and the free Reset.

signal reset_pressed

const Kind := EmberTreeNode.Kind

const CARD_PADDING := 12
const CARD_CORNER := 4
const LINE_GAP := 5
## The info card slides in from this far right when it changes, instead of popping.
const SLIDE_DISTANCE := 8.0
const SLIDE_SECONDS := 0.16

const KIND_NAMES := {Kind.SKILL: "SKILL", Kind.UPGRADE: "UPGRADE", Kind.STAT: "STAT", Kind.ULTIMATE: "ULTIMATE"}

const OVERVIEW_TITLE := "The Ember Tree"
const OVERVIEW_TAG := "EMBEROO'S SKILLS"
const OVERVIEW_TEXT := "Inferno burns, Flurry chains fast punches, Bruiser takes the hits. Mix them freely.\nDiamonds are skills, circles are stats. The dashed rings open as Emberoo evolves."
const COMING_SOON_TEXT := "Effect coming soon: learned, but not active yet."

var _info_card: PanelContainer
var _title: Label
var _tag: Label
var _description: Label
var _coming_soon: Label
var _status: Label
var _points_value: Label
var _reset_button: Button
var _shown_id: String = "-"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_info_card()
	_build_points_card()
	EmberTree.changed.connect(_refresh)
	Progression.skill_points_changed.connect(func(_points: int) -> void: _refresh())
	show_node("")


## Shows what a node does, or the overview when `id` is "".
func show_node(id: String) -> void:
	var is_new := id != _shown_id
	_shown_id = id
	_fill_info(id)
	_refresh_points()
	if is_new:
		_slide_in()


func _refresh() -> void:
	_fill_info(_shown_id)
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
	_coming_soon = _add_label(column, 9, EmberTreePalette.ORANGE)
	_status = _add_label(column, 10, EmberTreePalette.GREY)


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
	var caption := _make_label(9, EmberTreePalette.GREY)
	caption.text = "SKILL POINTS"
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(caption)
	_points_value = _make_label(16, EmberTreePalette.GOLD)
	_points_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_points_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_points_value)
	_reset_button = _make_button("Reset  ·  free")
	_reset_button.pressed.connect(reset_pressed.emit)
	row.add_child(_reset_button)


# --- Filling in -------------------------------------------------------------------

func _fill_info(id: String) -> void:
	var node := EmberTreeData.find(id)
	if node == null:
		_title.text = OVERVIEW_TITLE
		_tag.text = OVERVIEW_TAG
		_description.text = OVERVIEW_TEXT
		_coming_soon.visible = false
		_status.visible = false
	else:
		_title.text = node.title
		_tag.text = "%s  ·  %s  ·  STAGE %d" % [EmberTreeData.branch_title(node.branch).to_upper(), KIND_NAMES[node.kind], node.stage]
		_description.text = node.description
		_coming_soon.text = COMING_SOON_TEXT
		_coming_soon.visible = not node.has_working_effect()
		_status.text = _status_text(node)
		_status.add_theme_color_override("font_color", EmberTreePalette.GOLD if EmberTree.is_learned(id) else EmberTreePalette.GREY)
		_status.visible = true
	_info_card.reset_size()  # shrink to fit the new text
	_info_card.size.x = size.x


func _status_text(node: EmberTreeNode) -> String:
	if EmberTree.is_learned(node.id):
		if EmberTree.can_unlearn(node.id):
			return "Ignited  ·  right-click to put out (free)"
		return "Ignited  ·  put out the embers beyond it first"
	if EmberTree.can_learn(node.id):
		return "Click to ignite  ·  1 skill point"
	if not EmberTree.is_stage_open(node.stage):
		return "Opens at the Stage %d evolution" % node.stage
	if EmberTree.is_reachable(node.id):
		return "No skill points left  ·  earn 1 each level"
	return "Ignite an ember that leads here first"


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
