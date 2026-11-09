class_name LinkRodScreen
extends PausingScreen
## The Link Rod screen (see DESIGN.md, "Loot: hacked chips"). C opens it; C or Escape closes.
## C does nothing until the Tinkerer in Hometown has hacked the rod (StoryFlags.LINK_ROD_GIVEN);
## the test arena, which never saves, always has it.
##
## A PausingScreen, in the Ember Tree's style: three columns between the header and
## footer bars: the rod and what it gives (left), the chips in storage (middle) and the
## selected chip with its mods and hacks (right). Everything it changes goes through the
## LinkRod autoload, and every change redraws the screen.

const PAGE_MARGIN := 12.0
const LEFT_WIDTH := 300.0
const MIDDLE_WIDTH := 268.0
const RIGHT_WIDTH := 344.0

var _frame: LinkRodFrame
var _rod_card: LinkRodRodCard
var _summary: LinkRodSummary
var _chip_list: LinkRodChipList
var _chip_card: LinkRodChipCard
## The selected chip's serial, or 0 for none.
var _selected_serial: int = 0


func _ready() -> void:
	super._ready()
	_frame = LinkRodFrame.new()
	_root.add_child(_frame)
	_build_columns()
	# Deferred, so ChipEffects has changed Emberoo before the numbers are read.
	LinkRod.changed.connect(_refresh, CONNECT_DEFERRED)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("link_rod"):
		if not is_open and not is_rod_in_hand():
			return
		toggle()
	elif is_open and event.is_action_pressed("ui_cancel"):
		close()
	elif is_open and event.is_action_pressed("skill_tree"):
		pass  # one screen at a time: the Ember Tree waits until this closes
	else:
		return
	get_viewport().set_input_as_handled()


## True once the Tinkerer has handed over the Link Rod (always in the test arena).
static func is_rod_in_hand() -> bool:
	return StoryFlags.has(StoryFlags.LINK_ROD_GIVEN) or not SaveGame.enabled


## Opens over the game; not over another paused screen (the Ember Tree, a death screen).
func _can_open() -> bool:
	return not get_tree().paused


func _on_open() -> void:
	if LinkRod.find_chip(_selected_serial) == null and not LinkRod.chips().is_empty():
		_selected_serial = LinkRod.chips()[0].serial
	_refresh()


func select_chip(serial: int) -> void:
	_selected_serial = serial
	_refresh()


func _refresh() -> void:
	if not is_open:
		return
	var sheet := ChipStatSheet.new(PlayerFinder.find(self))
	var selected := LinkRod.find_chip(_selected_serial)
	if selected == null:
		_selected_serial = 0
	_frame.refresh()
	_rod_card.refresh(_selected_serial)
	_summary.refresh(sheet)
	_chip_list.refresh(_selected_serial)
	_chip_card.show_chip(selected, sheet)


func _build_columns() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", int(PAGE_MARGIN))
	# The columns have fixed widths: on a wider UI canvas (1280×720 at 1440p) they stay centred.
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(columns)
	columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columns.offset_left = PAGE_MARGIN
	columns.offset_right = -PAGE_MARGIN
	columns.offset_top = LinkRodFrame.HEADER_HEIGHT + PAGE_MARGIN
	columns.offset_bottom = -(LinkRodFrame.FOOTER_HEIGHT + PAGE_MARGIN)
	var left := _add_column(columns, LEFT_WIDTH)
	_rod_card = LinkRodRodCard.new(LEFT_WIDTH)
	_rod_card.chip_selected.connect(select_chip)
	left.add_child(_rod_card)
	_summary = LinkRodSummary.new(LEFT_WIDTH)
	left.add_child(_summary)
	var content_height := ui_size().y - columns.offset_top + columns.offset_bottom
	_chip_list = LinkRodChipList.new(MIDDLE_WIDTH, content_height)
	_chip_list.chip_selected.connect(select_chip)
	_chip_list.equip_toggled.connect(_toggle_equip)
	columns.add_child(_chip_list)
	var right := _add_column(columns, RIGHT_WIDTH)
	_chip_card = LinkRodChipCard.new(RIGHT_WIDTH)
	right.add_child(_chip_card)


func _add_column(columns: HBoxContainer, width: float) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = width
	column.add_theme_constant_override("separation", int(PAGE_MARGIN))
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(column)
	return column


func _toggle_equip(serial: int) -> void:
	var chip := LinkRod.find_chip(serial)
	_selected_serial = serial
	if LinkRod.is_equipped(chip):
		LinkRod.unequip(chip)
	elif not LinkRod.equip(chip):
		_refresh()  # no free slot: at least show the chip
