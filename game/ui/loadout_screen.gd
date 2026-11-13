class_name LoadoutScreen
extends VBoxContainer
## Before the fight: pick Ember's four moves from what it has learned, the level both creatures fight at (Baby has
## fewer moves to choose from), and the difficulty. Click a slot, then a move. Thornback's four follow the same rules.
## Start with the button or Enter.

const SLOT_KEYS: Array[String] = ["LMB", "RMB", "Q", "E"]
const LIST_COLUMNS: int = 5
const BUTTON_SIZE: Vector2 = Vector2(176, 34)
const SLOT_SIZE: Vector2 = Vector2(230, 40)
const DETAIL_WIDTH: float = 900.0
const GAP: int = 8
const SELECTED: Color = Color(1.0, 0.84, 0.3)
const START_SIZE: Vector2 = Vector2(345, 40)

var _main: Main
var _slot: int = 0
var _detail: Label


func setup(match_root: Main) -> void:
	_main = match_root
	add_theme_constant_override("separation", GAP * 2)
	_rebuild()


func _rebuild() -> void:
	for child: Node in get_children():
		child.queue_free()
	add_child(Screens.label("CREATURE WOODS", HudStyle.FONT_TITLE, HudStyle.INK))
	add_child(_choice_row("Level", ["baby", "grown"], Loadouts.level, _on_level))
	add_child(_choice_row("Difficulty", Difficulty.LEVELS, Difficulty.level, _on_difficulty))
	add_child(Screens.label("Ember's moves: click a slot, then a move", HudStyle.FONT_MEDIUM, HudStyle.INK_DIM))
	add_child(_slots())
	add_child(_move_list())
	_detail = Screens.label(_describe(Loadouts.for_player()[_slot]), HudStyle.FONT_SMALL, HudStyle.INK)
	_detail.custom_minimum_size.x = DETAIL_WIDTH
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_detail)
	var names: Array = Loadouts.for_bot().map(func(id: String) -> String: return MoveLibrary.spec(id)["name"])
	add_child(Screens.label("Thornback takes: " + ", ".join(names), HudStyle.FONT_SMALL, HudStyle.INK_DIM))
	var start := _button("Start the fight  (Enter)", START_SIZE)
	start.pressed.connect(_main.flow.play)
	add_child(_centred(start))


func _choice_row(title: String, options: Array, current: String, picked: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", GAP)
	row.add_child(Screens.label(title + ":", HudStyle.FONT_MEDIUM, HudStyle.INK))
	for option: String in options:
		var button := _button(option.capitalize(), BUTTON_SIZE)
		if option == current:
			button.add_theme_color_override("font_color", SELECTED)
		button.pressed.connect(picked.bind(option))
		row.add_child(button)
	return row


func _slots() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", GAP)
	var loadout: Array[String] = Loadouts.for_player()
	for slot: int in loadout.size():
		var button := _button("%s  %s" % [SLOT_KEYS[slot], MoveLibrary.spec(loadout[slot])["name"]], SLOT_SIZE)
		if slot == _slot:
			button.add_theme_color_override("font_color", SELECTED)
		button.pressed.connect(_on_slot.bind(slot))
		row.add_child(button)
	return row


func _move_list() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = LIST_COLUMNS
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	for move_id: String in Tuning.creatures["player"]["learnset"]:
		var spec: Dictionary = MoveLibrary.spec(move_id)
		var button := _button("%s · %s" % [spec["name"], spec["category"]], BUTTON_SIZE)
		button.disabled = not MoveLibrary.allowed(move_id, Loadouts.level)
		if Loadouts.for_player().has(move_id):
			button.add_theme_color_override("font_color", SELECTED)
		button.pressed.connect(_on_move.bind(move_id))
		button.mouse_entered.connect(func() -> void: _detail.text = _describe(move_id))
		grid.add_child(button)
	return _centred_grid(grid)


static func _describe(move_id: String) -> String:
	var spec: Dictionary = MoveLibrary.spec(move_id)
	var level: String = "Grown only" if int(spec["min_level"]) > MoveLibrary.level_value("baby") else "Baby and Grown"
	return "%s (%s, %s): %s  Cost: %s  Counter: %s" % [spec["name"], spec["category"], level, spec["description"],
		spec["cost"], spec["tit_for_tat"]]


func _on_slot(slot: int) -> void:
	_slot = slot
	_rebuild()


func _on_move(move_id: String) -> void:
	Loadouts.assign(_slot, move_id)
	_main.apply_loadouts()
	_rebuild()


func _on_level(level: String) -> void:
	Loadouts.set_level(level)
	_main.apply_loadouts()
	_rebuild()


func _on_difficulty(level: String) -> void:
	Difficulty.level = level
	_rebuild()


func _button(words: String, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = words
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", HudStyle.FONT_SMALL)
	return button


static func _centred(control: Control) -> CenterContainer:
	var box := CenterContainer.new()
	box.add_child(control)
	return box


static func _centred_grid(grid: GridContainer) -> GridContainer:
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return grid
