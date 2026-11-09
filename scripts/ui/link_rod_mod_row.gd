class_name LinkRodModRow
extends VBoxContainer
## One mod on the Link Rod screen's chip card: what it does and its tier, its exact numbers
## on Emberoo (before → after), what an upgrade would change, and the three hack buttons
## with their scrap costs (e.g. "Reveal 5"). A button that can't be used now is greyed out and says why.

const BUTTON_FORMAT := "%s %d"

var _text: RichTextLabel
var _buttons: Dictionary[ChipHacking.Hack, Button] = {}
var _chip: Chip
var _mod_index: int = 0


func _init(width: float) -> void:
	add_theme_constant_override("separation", 3)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text = EmberTreeWidgets.make_rich_text(width)
	add_child(_text)
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	button_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(button_row)
	for hack: ChipHacking.Hack in ChipHacking.COSTS:
		var button := LinkRodButtons.make_small_button(BUTTON_FORMAT % [ChipHacking.LABELS[hack], ChipHacking.cost(hack)])
		button.pressed.connect(func() -> void: LinkRod.hack(_chip, _mod_index, hack))
		button_row.add_child(button)
		_buttons[hack] = button


func show_mod(chip: Chip, mod_index: int, sheet: ChipStatSheet) -> void:
	_chip = chip
	_mod_index = mod_index
	var mod := chip.mods[mod_index]
	var is_equipped := LinkRod.is_equipped(chip)
	var lines := PackedStringArray([LinkRodText.mod_title_bbcode(mod)])
	if not mod.is_revealed:
		lines.append(EmberTreeFactText.colored(LinkRodText.LOCKED_NOTE, EmberTreePalette.GREY))
	var change := LinkRodText.mod_change_bbcode(sheet, mod, is_equipped)
	if change != "":
		lines.append(change)
	if LinkRod.hack_refusal(chip, mod_index, ChipHacking.Hack.UPGRADE) in ["", ChipHacking.NOT_ENOUGH_SCRAP]:
		lines.append(LinkRodText.upgrade_bbcode(sheet, mod, is_equipped))
	_text.text = "\n".join(lines)
	for hack: ChipHacking.Hack in _buttons:
		var refusal := LinkRod.hack_refusal(chip, mod_index, hack)
		_buttons[hack].disabled = refusal != ""
		_buttons[hack].tooltip_text = refusal
