class_name EmberTreeFrame
extends Control
## The Ember Tree screen's frame, laid over the tree: a vignette that darkens the edges,
## the header bar (name on the left, level and XP on the right) and the footer bar with
## the controls. Anchored to the screen's edges, so it fits any screen size.

const HEADER_HEIGHT := 52.0
const FOOTER_HEIGHT := 28.0
## Space between the screen edge and the header's and footer's words.
const SIDE_MARGIN := 16.0
const FOOTER_HINT := "Click: ignite   ∙   Right-click: put out   ∙   Scroll: zoom   ∙   Drag: move   ∙   K / Esc: close"

var _level_label: Label
var _xp_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_vignette()
	_build_header()
	_build_footer()


## Shows the level, and how far it is to the next one (which brings a skill point).
func refresh_level() -> void:
	_level_label.text = "Level %d" % Progression.level
	if Progression.level >= Progression.MAX_LEVEL:
		_xp_label.text = "Max level"
	else:
		_xp_label.text = "%d / %d XP  ∙  next skill point at Level %d" % [Progression.xp, Progression.xp_to_next(), Progression.level + 1]


## Darkens the screen edges so the eye goes to the middle and the fire glows.
func _build_vignette() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(EmberTreePalette.BACKGROUND, 0.0), Color(EmberTreePalette.BACKGROUND, 0.15), Color(EmberTreePalette.BACKGROUND, 0.75)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	var vignette := TextureRect.new()
	vignette.texture = texture
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_header() -> void:
	var bar := _add_bar(Control.PRESET_TOP_WIDE, HEADER_HEIGHT, Control.PRESET_BOTTOM_WIDE)
	var title_block := _add_text_block(bar, Control.PRESET_LEFT_WIDE)
	title_block.add_child(UiLabel.make(EmberTreeFonts.LARGE_SIZE, EmberTreePalette.GOLD, "EMBEROO"))
	title_block.add_child(UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, "The Ember Tree"))
	var level_block := _add_text_block(bar, Control.PRESET_RIGHT_WIDE)
	_level_label = UiLabel.make(EmberTreeFonts.LARGE_SIZE, EmberTreePalette.CREAM)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_block.add_child(_level_label)
	_xp_label = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_block.add_child(_xp_label)


func _build_footer() -> void:
	var bar := _add_bar(Control.PRESET_BOTTOM_WIDE, FOOTER_HEIGHT, Control.PRESET_TOP_WIDE)
	var hint := UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, FOOTER_HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.clip_text = true
	bar.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## A translucent bar across the screen at `edge` (a top- or bottom-wide preset), with a
## thin warm line along the side that faces the tree (`line_edge`).
func _add_bar(edge: Control.LayoutPreset, height: float, line_edge: Control.LayoutPreset) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = EmberTreePalette.BAR
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	bar.set_anchors_and_offsets_preset(edge, Control.PRESET_MODE_MINSIZE)
	if edge == Control.PRESET_TOP_WIDE:
		bar.offset_bottom = height
	else:
		bar.offset_top = -height
	var line := ColorRect.new()
	line.color = Color(EmberTreePalette.ORANGE, 0.25)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(line)
	line.set_anchors_and_offsets_preset(line_edge, Control.PRESET_MODE_MINSIZE)
	if line_edge == Control.PRESET_BOTTOM_WIDE:
		line.offset_top = -1.0
	else:
		line.offset_bottom = 1.0
	return bar


## Two stacked lines, centred in the bar's height, against one of its sides.
func _add_text_block(bar: Control, side: Control.LayoutPreset) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.alignment = BoxContainer.ALIGNMENT_CENTER
	block.add_theme_constant_override("separation", 0)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(block)
	block.set_anchors_and_offsets_preset(side, Control.PRESET_MODE_MINSIZE)
	block.grow_horizontal = Control.GROW_DIRECTION_END if side == Control.PRESET_LEFT_WIDE else Control.GROW_DIRECTION_BEGIN
	block.offset_left += SIDE_MARGIN if side == Control.PRESET_LEFT_WIDE else -SIDE_MARGIN
	block.offset_right += SIDE_MARGIN if side == Control.PRESET_LEFT_WIDE else -SIDE_MARGIN
	return block
