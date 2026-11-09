class_name LinkRodFrame
extends Control
## The Link Rod screen's backdrop and bars, in the Ember Tree's style: a dark page over the
## paused game, the header (title on the left, scrap and hack costs on the right) and the
## footer with the controls.

const HEADER_HEIGHT := 52.0
const FOOTER_HEIGHT := 28.0
const SIDE_MARGIN := 16.0
const TITLE := "LINK ROD"
const SUBTITLE := "A stolen Warden rod, hacked to run chips for Emberoo"
const SCRAP_FORMAT := "Scrap  %d"
const COSTS_FORMAT := "Reveal %d  ∙  Reroll %d  ∙  Upgrade %d"
const FOOTER_HINT := "Click: select  ∙  Right-click a chip: in / out of the rod  ∙  C / Esc: close"

var _scrap_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := ColorRect.new()
	backdrop.color = LinkRodPalette.BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_header()
	_build_footer()


func refresh() -> void:
	_scrap_label.text = SCRAP_FORMAT % LinkRod.scrap


func _build_header() -> void:
	var bar := _add_bar(true)
	var title_block := _add_text_block(bar, true)
	title_block.add_child(UiLabel.make(EmberTreeFonts.LARGE_SIZE, EmberTreePalette.GOLD, TITLE))
	title_block.add_child(UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, SUBTITLE))
	var scrap_block := _add_text_block(bar, false)
	_scrap_label = UiLabel.make(EmberTreeFonts.LARGE_SIZE, EmberTreePalette.CREAM)
	_scrap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scrap_block.add_child(_scrap_label)
	var costs := COSTS_FORMAT % [
		ChipHacking.cost(ChipHacking.Hack.REVEAL), ChipHacking.cost(ChipHacking.Hack.REROLL), ChipHacking.cost(ChipHacking.Hack.UPGRADE)]
	var costs_label := UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, costs)
	costs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scrap_block.add_child(costs_label)


func _build_footer() -> void:
	var bar := _add_bar(false)
	var hint := UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, FOOTER_HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## A bar across the top or bottom with a thin warm line on the side facing the page.
func _add_bar(is_top: bool) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = EmberTreePalette.BAR
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if is_top else Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE)
	if is_top:
		bar.offset_bottom = HEADER_HEIGHT
	else:
		bar.offset_top = -FOOTER_HEIGHT
	var line := ColorRect.new()
	line.color = EmberTreePalette.DIVIDER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(line)
	line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if is_top else Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE)
	if is_top:
		line.offset_top = -1.0
	else:
		line.offset_bottom = 1.0
	return bar


## Two stacked lines, centred in the bar's height, against its left or right side.
func _add_text_block(bar: Control, is_left: bool) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.alignment = BoxContainer.ALIGNMENT_CENTER
	block.add_theme_constant_override("separation", 0)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(block)
	block.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE if is_left else Control.PRESET_RIGHT_WIDE, Control.PRESET_MODE_MINSIZE)
	block.grow_horizontal = Control.GROW_DIRECTION_END if is_left else Control.GROW_DIRECTION_BEGIN
	var shift := SIDE_MARGIN if is_left else -SIDE_MARGIN
	block.offset_left += shift
	block.offset_right += shift
	return block
