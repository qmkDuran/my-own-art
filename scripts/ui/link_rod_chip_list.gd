class_name LinkRodChipList
extends PanelContainer
## The Link Rod screen's middle card: every chip in storage, one row each (no grid), newest
## at the bottom. Click a row to select the chip; right-click to put it in the rod or take
## it out. Chips in the rod are marked "IN ROD".

signal chip_selected(serial: int)
signal equip_toggled(serial: int)

const TITLE_FORMAT := "STORAGE  %d / %d"
const EMPTY_NOTE := "No chips yet. Wardens drop them\n(about 1 in 4), the Captain always."
const IN_ROD := "IN ROD  "
## Canvas pixels kept clear around the rows for their drop shadows (PixelPanelStyle.unit).
const ROW_SHADOW_ROOM := 2
const CHIP_ICON := preload("res://art/pickups/hacked_chip.png")

var _title: Label
var _empty_note: Label
var _rows: VBoxContainer


func _init(width: float, height: float) -> void:
	add_theme_stylebox_override("panel", EmberTreeWidgets.card_style())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(width, height)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_title = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.ORANGE)
	column.add_child(_title)
	column.add_child(EmberTreeWidgets.make_divider(width - EmberTreeWidgets.CARD_PADDING * 2))
	_empty_note = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, EMPTY_NOTE)
	column.add_child(_empty_note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	EmberTreeWidgets.style_scroll_bar(scroll.get_v_scroll_bar())
	column.add_child(scroll)
	# Room between the rows and the scroll bar, and below the last row, for the rows' shadows.
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_right", ROW_SHADOW_ROOM * 2)
	inset.add_theme_constant_override("margin_bottom", ROW_SHADOW_ROOM)
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(inset)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inset.add_child(_rows)


func refresh(selected_serial: int) -> void:
	_title.text = TITLE_FORMAT % [LinkRod.chips().size(), LinkRod.MAX_CHIPS]
	_empty_note.visible = LinkRod.chips().is_empty()
	for row in _rows.get_children():
		row.queue_free()
	for chip in LinkRod.chips():
		_rows.add_child(_make_row(chip, chip.serial == selected_serial))


func _make_row(chip: Chip, is_selected: bool) -> Button:
	var button := LinkRodButtons.make_row_button()
	button.icon = CHIP_ICON
	button.text = (IN_ROD if LinkRod.is_equipped(chip) else "") + LinkRodText.chip_summary(chip)
	if LinkRod.is_equipped(chip):
		button.add_theme_color_override("font_color", LinkRodPalette.CHIP_LIGHT)
	LinkRodButtons.mark_selected(button, is_selected)
	button.pressed.connect(func() -> void: chip_selected.emit(chip.serial))
	button.gui_input.connect(_on_row_input.bind(chip.serial))
	return button


func _on_row_input(event: InputEvent, serial: int) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		equip_toggled.emit(serial)
