class_name EmberTreeStatsPanel
extends PanelContainer
## The Ember Tree's stats card: Emberoo's stats right now, read live from the player
## (see EmberTreeStatSheet), so the player always sees exactly what they have.
##
## While an ember that can be ignited is pointed at, the stats it changes show the change
## in place, e.g. "60 → 72 px/s", with the new number in green.

const TITLE := "EMBEROO NOW"
const PREVIEW_PREFIX := "If you ignite "
const NO_PLAYER := "-"
const ROW_GAP := 2
## Space between a stat's name and its value.
const NAME_VALUE_GAP := 8

var _preview_note: Label
## Stat -> the label with its name, and the rich text with its value.
var _names: Dictionary[String, Label] = {}
var _values: Dictionary[String, RichTextLabel] = {}
## The node whose change is previewed, or "" for none.
var _preview_id: String = ""


## `width` is the card's outer width.
func _init(width: float) -> void:
	add_theme_stylebox_override("panel", EmberTreeWidgets.card_style(EmberTreePalette.PANEL, EmberTreePalette.PANEL_EDGE))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size.x = width
	var text_width := width - EmberTreeWidgets.CARD_PADDING * 2
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", ROW_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	column.add_child(UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.ORANGE, TITLE))
	column.add_child(EmberTreeWidgets.make_divider(text_width))
	for stat in EmberTreeStatSheet.ORDER:
		column.add_child(_make_row(stat))
	_preview_note = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.BETTER)
	_preview_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_note.custom_minimum_size.x = text_width
	column.add_child(_preview_note)


func _ready() -> void:
	# Deferred, so stat changes from EmberTreeEffects land before the numbers are read.
	EmberTree.changed.connect(refresh, CONNECT_DEFERRED)
	Progression.leveled_up.connect(func(_level: int) -> void: refresh())
	refresh()


## Previews what igniting this node would change, while it can be ignited.
## "" (or a node that can't be ignited) shows the stats as they are.
func preview_node(id: String) -> void:
	_preview_id = id
	refresh()


func refresh() -> void:
	var sheet := EmberTreeStatSheet.new(PlayerFinder.find(self))
	var preview := _previewed_changes(sheet)
	for stat in EmberTreeStatSheet.ORDER:
		var is_changing := preview.has(stat)
		_names[stat].add_theme_color_override("font_color", EmberTreePalette.CREAM if is_changing else EmberTreePalette.GREY)
		_values[stat].text = "[right]%s[/right]" % _value_bbcode(sheet, stat, preview)
	var node := EmberTreeData.find(_preview_id)
	_preview_note.text = PREVIEW_PREFIX + node.title if node != null and not preview.is_empty() else ""
	_preview_note.visible = _preview_note.text != ""
	var width := size.x
	reset_size()  # shrink to fit
	size.x = width


## Stat -> its {"before", "after"} for the previewed node; empty when nothing is
## previewed or the node can't be ignited (e.g. it just was).
func _previewed_changes(sheet: EmberTreeStatSheet) -> Dictionary[String, Dictionary]:
	var changes: Dictionary[String, Dictionary] = {}
	var node := EmberTreeData.find(_preview_id)
	if node == null or not EmberTree.can_learn(node.id):
		return changes
	for change in sheet.changes_from(node):
		changes[change["stat"]] = change
	return changes


func _value_bbcode(sheet: EmberTreeStatSheet, stat: String, preview: Dictionary[String, Dictionary]) -> String:
	if not sheet.has_player():
		return NO_PLAYER
	if preview.has(stat):
		var change: Dictionary = preview[stat]
		return EmberTreeFactText.change_bbcode(stat, change["before"], change["after"], EmberTreePalette.BETTER, false)
	return EmberTreeFactText.escape(sheet.shown_value(stat))


func _make_row(stat: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", NAME_VALUE_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, EmberTreeStatSheet.LABELS[stat])
	row.add_child(name_label)
	var value := EmberTreeWidgets.make_rich_text(0.0)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)
	_names[stat] = name_label
	_values[stat] = value
	return row
