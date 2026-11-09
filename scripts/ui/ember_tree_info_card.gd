class_name EmberTreeInfoCard
extends PanelContainer
## The Ember Tree's info card: what the pointed-at node or branch is, or (with nothing
## pointed at) how the screen works, with a small legend.
##
## For a node: name, "BRANCH ∙ TYPE ∙ STAGE", one flavour line, then the exact effect in
## real numbers (see EmberTreeFactText), a frame where a skill's video clip will go, and
## where the node stands. Grows and shrinks to fit its text, at a fixed width.

const Kind := EmberTreeNode.Kind

const LINE_GAP := 6
const KIND_NAMES := {Kind.SKILL: "SKILL", Kind.UPGRADE: "UPGRADE", Kind.STAT: "STAT", Kind.ULTIMATE: "ULTIMATE"}
## Colour of the status line for each node state (see EmberTreeNodeState).
const STATE_COLORS := {
	EmberTreeNodeState.LEARNED: EmberTreePalette.GOLD, EmberTreeNodeState.AVAILABLE: EmberTreePalette.CREAM,
	EmberTreeNodeState.LOCKED: EmberTreePalette.GREY, EmberTreeNodeState.SEALED: EmberTreePalette.GREY,
}
## Kinds that are moves you see, so they get a frame for a video clip.
const KINDS_WITH_PREVIEW: Array[Kind] = [Kind.SKILL, Kind.ULTIMATE]

const OVERVIEW_TITLE := "How the tree works"
const OVERVIEW_TEXT := "Ignite embers to change how Emberoo fights. Each costs 1 skill point; you earn 1 per level.\nThe inner ring is Stage 1. The outer rings open when Emberoo Awakens (level %d and %d)." % [AwakeningStage.ONE_LEVEL, AwakeningStage.TWO_LEVEL]
const OVERVIEW_TAG := "POINT AT A BRANCH NAME OR AN EMBER"
## A small badge and a short note, for nodes whose effect is not built yet.
const COMING_SOON_BADGE := "COMING SOON"
const COMING_SOON_NOTE := "Numbers are the plan"

var _title: Label
var _tag: Label
var _description: Label
var _facts: RichTextLabel
var _preview_frame: Control
var _legend: EmberTreeLegend
var _coming_soon_row: HBoxContainer
var _status: Label


## `width` is the card's outer width; its text wraps to fit inside.
func _init(width: float) -> void:
	add_theme_stylebox_override("panel", EmberTreeWidgets.card_style())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size.x = width
	var text_width := width - EmberTreeWidgets.CARD_PADDING * 2
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", LINE_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_title = _add_label(column, EmberTreeFonts.LARGE_SIZE, EmberTreePalette.CREAM, text_width)
	_tag = _add_label(column, EmberTreeFonts.TEXT_SIZE, EmberTreePalette.ORANGE, text_width)
	column.add_child(EmberTreeWidgets.make_divider(text_width))
	_description = _add_label(column, EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, text_width)
	_facts = EmberTreeWidgets.make_rich_text(text_width)
	column.add_child(_facts)
	_preview_frame = EmberTreeWidgets.make_preview_frame(text_width)
	column.add_child(_preview_frame)
	_legend = EmberTreeLegend.new()
	column.add_child(_legend)
	_coming_soon_row = EmberTreeWidgets.make_badge_row(COMING_SOON_BADGE, COMING_SOON_NOTE)
	column.add_child(_coming_soon_row)
	_status = _add_label(column, EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, text_width)


## With nothing pointed at: what the tree is, where points come from, and a legend.
func fill_overview() -> void:
	_set_heading(OVERVIEW_TITLE, EmberTreePalette.CREAM, OVERVIEW_TAG)
	_description.text = OVERVIEW_TEXT
	_description.add_theme_color_override("font_color", EmberTreePalette.CREAM)
	_show_parts(false, false, true, false)
	_status.visible = false
	_fit_height()


## A branch: what it is about, how it plays, and how much of it is ignited.
func fill_branch(branch: String) -> void:
	var tag := "BRANCH  ∙  %s" % EmberTreeData.branch_theme(branch).to_upper()
	_set_heading(EmberTreeData.branch_title(branch), EmberTreePalette.BRANCH_COLORS[branch], tag)
	_description.text = EmberTreeData.branch_playstyle(branch)
	_description.add_theme_color_override("font_color", EmberTreePalette.CREAM)
	_show_parts(false, false, false, false)
	var has_ignited := EmberTreeStatusText.ignited_in_branch(branch) > 0
	_set_status(EmberTreeStatusText.for_branch(branch), EmberTreePalette.GOLD if has_ignited else EmberTreePalette.GREY)
	_fit_height()


## A node, with its exact effect worked out from `player` (may be null).
func fill_node(node: EmberTreeNode, player: Node) -> void:
	var tag := "%s  ∙  %s  ∙  STAGE %d" % [EmberTreeData.branch_title(node.branch).to_upper(), KIND_NAMES[node.kind], node.stage]
	_set_heading(node.title, EmberTreePalette.CREAM, tag)
	_description.text = node.description
	_description.add_theme_color_override("font_color", EmberTreePalette.GREY)
	_facts.text = EmberTreeFactText.for_node(node, player)
	_show_parts(_facts.text != "", KINDS_WITH_PREVIEW.has(node.kind), false, not node.has_working_effect())
	var state := EmberTreeNodeState.of(node)
	_set_status(EmberTreeStatusText.for_node(node, state), STATE_COLORS[state])
	_fit_height()


func _set_heading(title: String, title_color: Color, tag: String) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", title_color)
	_tag.text = tag


func _show_parts(facts: bool, preview: bool, legend: bool, coming_soon: bool) -> void:
	_facts.visible = facts
	_preview_frame.visible = preview
	_legend.visible = legend
	_coming_soon_row.visible = coming_soon


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
	_status.visible = true


## Shrinks the card to its new text, keeping its width.
func _fit_height() -> void:
	var width := size.x
	reset_size()
	size.x = width


func _add_label(column: VBoxContainer, font_size: int, color: Color, width: float) -> Label:
	var label := UiLabel.make(font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = width
	column.add_child(label)
	return label
