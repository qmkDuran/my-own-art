class_name LinkRodSummary
extends PanelContainer
## The Link Rod screen's bottom-left card: what the chips in the rod give Emberoo right now,
## one line per stat as "without chips → now" (e.g. "Max Health 10 → 12"), then any
## overclocked effects. Locked mods aren't counted: they don't work yet.

const TITLE := "THE ROD GIVES EMBEROO"
const NOTHING_YET := "Nothing yet: put a chip in the rod\nand reveal its mods."

var _lines: RichTextLabel


func _init(width: float) -> void:
	add_theme_stylebox_override("panel", EmberTreeWidgets.card_style())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = width
	var text_width := width - EmberTreeWidgets.CARD_PADDING * 2
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	column.add_child(UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.ORANGE, TITLE))
	column.add_child(EmberTreeWidgets.make_divider(text_width))
	_lines = EmberTreeWidgets.make_rich_text(text_width)
	column.add_child(_lines)


func refresh(sheet: ChipStatSheet) -> void:
	var totals := ChipEffects.equipped_totals()
	var lines := PackedStringArray()
	for mod_id: String in ChipStatSheet.STATS:
		if totals.has(mod_id) and sheet.has_player():
			var change := sheet.change_text(mod_id, totals[mod_id], true)
			lines.append(LinkRodText.stat_change_bbcode(change, ChipStatSheet.label(mod_id), EmberTreePalette.GOLD))
	for mod_id: String in ChipEffects.OVERCLOCK_NODES:
		if totals.has(mod_id):
			lines.append(EmberTreeFactText.colored(ChipModTable.text(mod_id, ChipModTable.OVERCLOCK_TIER), LinkRodPalette.OVERCLOCK))
	_lines.text = "\n".join(lines) if not lines.is_empty() else EmberTreeFactText.colored(NOTHING_YET, EmberTreePalette.GREY)
