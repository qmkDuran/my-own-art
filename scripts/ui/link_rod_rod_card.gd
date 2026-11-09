class_name LinkRodRodCard
extends PanelContainer
## The Link Rod screen's top-left card: the rod with its lit sockets, then one line per slot
## (the chip in it, an empty slot, or a slot still to be found). Clicking a filled slot
## selects its chip.

signal chip_selected(serial: int)

const TITLE := "THE LINK ROD"
const SLOTS_FORMAT := "%d of %d slots open"
const EMPTY_SLOT := "%d   empty"
const FILLED_SLOT := "%d   %s"
const LOCKED_SLOT := "%d   locked: find a Glimmer Shard"

var _slots_note: Label
var _slot_buttons: Array[Button] = []


func _init(width: float) -> void:
	add_theme_stylebox_override("panel", EmberTreeWidgets.card_style(EmberTreePalette.PANEL, EmberTreePalette.PANEL_EDGE))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = width
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	column.add_child(UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.ORANGE, TITLE))
	_slots_note = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY)
	column.add_child(_slots_note)
	column.add_child(LinkRodIcon.new())
	for slot_index in LinkRod.MAX_SLOTS:
		var button := LinkRodButtons.make_row_button()
		button.pressed.connect(_on_slot_pressed.bind(slot_index))
		column.add_child(button)
		_slot_buttons.append(button)


func refresh(selected_serial: int) -> void:
	_slots_note.text = SLOTS_FORMAT % [LinkRod.slot_count(), LinkRod.MAX_SLOTS]
	for slot_index in _slot_buttons.size():
		var button := _slot_buttons[slot_index]
		var chip := LinkRod.chip_in_slot(slot_index)
		var is_open := slot_index < LinkRod.slot_count()
		button.disabled = chip == null
		if chip != null:
			button.text = FILLED_SLOT % [slot_index + 1, LinkRodText.chip_summary(chip)]
		else:
			button.text = (EMPTY_SLOT if is_open else LOCKED_SLOT) % (slot_index + 1)
		LinkRodButtons.mark_selected(button, chip != null and chip.serial == selected_serial)


func _on_slot_pressed(slot_index: int) -> void:
	var chip := LinkRod.chip_in_slot(slot_index)
	if chip != null:
		chip_selected.emit(chip.serial)
