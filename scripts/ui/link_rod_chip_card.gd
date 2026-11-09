class_name LinkRodChipCard
extends PanelContainer
## The Link Rod screen's right card: the selected chip. Its name and tier, each mod with its
## hacks (LinkRodModRow), then putting it in the rod (or taking it out) and salvaging it
## for scrap. With no chip selected it says how chips are found.

const NOTHING_SELECTED := "Pick a chip from storage."
const INFO_FORMAT := "Act %d chip  ∙  mods up to tier %d"
const IN_ROD := "In the rod: its revealed mods are working."
const IN_STORAGE := "In storage: put it in the rod to use it."
const EQUIP := "Put in rod"
const UNEQUIP := "Take out"
const NO_FREE_SLOT := "No free slot"
const SALVAGE_FORMAT := "Salvage  +%d scrap"

var _name_label: Label
var _info_label: Label
var _status_label: Label
var _mod_rows: Array[LinkRodModRow] = []
var _equip_button: Button
var _salvage_button: Button
var _chip: Chip


func _init(width: float) -> void:
	add_theme_stylebox_override("panel", EmberTreeWidgets.card_style())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = width
	var text_width := width - EmberTreeWidgets.CARD_PADDING * 2
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_name_label = UiLabel.make(EmberTreeFonts.LARGE_SIZE, LinkRodPalette.CHIP_LIGHT)
	column.add_child(_name_label)
	_info_label = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY)
	column.add_child(_info_label)
	_status_label = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.CREAM)
	column.add_child(_status_label)
	column.add_child(EmberTreeWidgets.make_divider(text_width))
	for index in Chip.MAX_MODS:
		var row := LinkRodModRow.new(text_width)
		column.add_child(row)
		_mod_rows.append(row)
	column.add_child(EmberTreeWidgets.make_divider(text_width))
	column.add_child(_make_action_row())


func show_chip(chip: Chip, sheet: ChipStatSheet) -> void:
	_chip = chip
	var has_chip := chip != null
	_name_label.text = chip.display_name() if has_chip else ""
	_info_label.text = INFO_FORMAT % [chip.tier, chip.max_mod_tier()] if has_chip else NOTHING_SELECTED
	_status_label.visible = has_chip
	_equip_button.visible = has_chip
	_salvage_button.visible = has_chip
	for index in _mod_rows.size():
		_mod_rows[index].visible = has_chip and index < chip.mods.size()
		if _mod_rows[index].visible:
			_mod_rows[index].show_mod(chip, index, sheet)
	if not has_chip:
		return
	var is_equipped := LinkRod.is_equipped(chip)
	_status_label.text = IN_ROD if is_equipped else IN_STORAGE
	_equip_button.text = UNEQUIP if is_equipped else (EQUIP if LinkRod.has_free_slot() else NO_FREE_SLOT)
	_equip_button.disabled = not is_equipped and not LinkRod.has_free_slot()
	_salvage_button.text = SALVAGE_FORMAT % chip.salvage_value()


func _make_action_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equip_button = LinkRodButtons.make_small_button(EQUIP)
	_equip_button.pressed.connect(_on_equip_pressed)
	row.add_child(_equip_button)
	_salvage_button = LinkRodButtons.make_small_button("")
	_salvage_button.pressed.connect(func() -> void: LinkRod.salvage(_chip))
	row.add_child(_salvage_button)
	return row


func _on_equip_pressed() -> void:
	if LinkRod.is_equipped(_chip):
		LinkRod.unequip(_chip)
	else:
		LinkRod.equip(_chip)
