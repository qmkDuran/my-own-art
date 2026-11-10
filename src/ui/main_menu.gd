extends Control
## Title screen: New Game (hero picker: male/female, skin tone, hairstyle), Continue (if a save
## exists), Quit. The picker previews the hero and Mom with the chosen skin tone, since the
## family shares it (palette swap, see SkinPalette).

var new_game_button: Button
var continue_button: Button
var quit_button: Button
var start_button: Button
var gender_buttons: Dictionary = {}     # gender -> Button
var tone_buttons: Array[Button] = []
var hair_buttons: Array[Button] = []

var _gender := "female"
var _tone := 2
var _hair := ""
var _main: VBoxContainer
var _picker: Control
var _hair_row: HBoxContainer
var _preview_root: Node2D
var _summary: Label


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("0c0b12")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_add_title()
	_build_main()
	_build_picker()
	_show_main()
	AudioManager.play_music("title")
	AudioManager.set_ambience(["wind_loop"])


# --- Public (also used by the test driver) ---------------------------------------

func open_picker() -> void:
	_main.visible = false
	_picker.visible = true
	_select_gender(_gender)
	start_button.grab_focus.call_deferred()


func choose(gender: String, tone: int, hair: String) -> void:
	_select_gender(gender)
	_select_tone(tone)
	_select_hair(hair)


func start() -> void:
	_disable_all()
	AudioManager.play_sfx("ui_confirm")
	Router.start_new_game(_gender, _tone, _hair)


# --- Main column -------------------------------------------------------------------

func _add_title() -> void:
	var title := UiStyle.label("PROJECT R", 48, UiStyle.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 70)
	title.size = Vector2(960, 60)
	add_child(title)
	var subtitle := UiStyle.label("R E V E L A T I O N", 16, UiStyle.ACCENT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 132)
	subtitle.size = Vector2(960, 24)
	add_child(subtitle)


func _build_main() -> void:
	_main = VBoxContainer.new()
	_main.position = Vector2(0, 220)
	_main.size = Vector2(960, 200)
	_main.add_theme_constant_override("separation", 10)
	add_child(_main)
	new_game_button = _button(_main, "New Game", open_picker)
	continue_button = _button(_main, "Continue", _on_continue)
	quit_button = _button(_main, "Quit", Router.quit_game)
	continue_button.disabled = not GameState.has_save()
	for button: Button in [new_game_button, continue_button, quit_button]:
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _show_main() -> void:
	_main.visible = true
	_picker.visible = false
	new_game_button.grab_focus.call_deferred()


func _on_continue() -> void:
	_disable_all()
	AudioManager.play_sfx("ui_confirm")
	Router.continue_game()


# --- Hero picker ---------------------------------------------------------------------

func _build_picker() -> void:
	_picker = Control.new()
	_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_picker)
	var panel := Panel.new()
	panel.position = Vector2(150, 170)
	panel.size = Vector2(660, 340)
	panel.add_theme_stylebox_override("panel", UiStyle.panel())
	_picker.add_child(panel)
	var column := VBoxContainer.new()
	column.position = Vector2(20, 14)
	column.size = Vector2(330, 310)
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(UiStyle.label("Who are you?", 18, UiStyle.ACCENT))
	var gender_row := _row(column, "Body")
	for gender: String in ["male", "female"]:
		var hero: Dictionary = DB.heroes.get(gender, {})
		gender_buttons[gender] = _small_button(gender_row, String(hero.get("label", gender.capitalize())), _select_gender.bind(gender))
	var tone_row := _row(column, "Skin")
	var tones := GameState.skin_tones()
	for i in tones.size():
		tone_buttons.append(_swatch(tone_row, Color.from_string(String((tones[i] as Dictionary).get("color", "#c89070")), Color.WHITE), i))
	_hair_row = _row(column, "Hair")
	_summary = UiStyle.label("", 13, UiStyle.DIM)
	column.add_child(_summary)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	start_button = _small_button(actions, "Begin", start)
	start_button.custom_minimum_size = Vector2(120, 34)
	_small_button(actions, "Back", _show_main).custom_minimum_size = Vector2(90, 34)
	_preview_root = Node2D.new()
	_preview_root.position = Vector2(370, 30)
	panel.add_child(_preview_root)
	panel.add_child(_preview_caption("You", Vector2(400, 250)))
	panel.add_child(_preview_caption("Mom", Vector2(500, 250)))


func _select_gender(gender: String) -> void:
	_gender = gender
	for key: String in gender_buttons.keys():
		_mark(gender_buttons[key], key == gender)
	_rebuild_hair_buttons()
	_select_hair(GameState.default_hair(gender) if GameState.hair_art_for(gender, _hair).is_empty() else _hair)


func _select_tone(index: int) -> void:
	_tone = index
	for i in tone_buttons.size():
		_mark(tone_buttons[i], i == index)
	_refresh_preview()


func _select_hair(style: String) -> void:
	_hair = style
	var options := GameState.hair_options(_gender)
	for i in hair_buttons.size():
		_mark(hair_buttons[i], String((options[i] as Dictionary).get("id", "")) == style)
	_refresh_preview()


func _rebuild_hair_buttons() -> void:
	for button: Button in hair_buttons:
		_hair_row.remove_child(button)
		button.queue_free()
	hair_buttons.clear()
	for option: Variant in GameState.hair_options(_gender):
		var data: Dictionary = option
		hair_buttons.append(_small_button(_hair_row, String(data.get("name", "")), _select_hair.bind(String(data.get("id", "")))))


## Shows the hero (body + hair) and Mom with the chosen tone, plus Mom's portrait.
func _refresh_preview() -> void:
	for child: Node in _preview_root.get_children():
		_preview_root.remove_child(child)
		child.queue_free()
	GameState.skin_tone = _tone   # preview materials read the tone from GameState
	var hero := CharacterVisual.new()
	_preview_root.add_child(hero)
	hero.setup(String((DB.heroes.get(_gender, {}) as Dictionary).get("body", "")))
	hero.add_layer(GameState.hair_art_for(_gender, _hair))
	hero.position = Vector2(46, 210)
	hero.scale = Vector2(3, 3)
	hero.moving = true
	var mom := CharacterVisual.new()
	_preview_root.add_child(mom)
	mom.setup("mom")
	mom.position = Vector2(146, 210)
	mom.scale = Vector2(3, 3)
	var portrait := Sprite2D.new()
	portrait.texture = Art.texture("portrait_mom")
	portrait.material = Art.material_for("portrait_mom")
	portrait.centered = false
	portrait.position = Vector2(196, 6)
	portrait.scale = Vector2(0.5, 0.5)
	_preview_root.add_child(portrait)
	var tone: Dictionary = GameState.skin_tones()[_tone]
	_summary.text = "%s, %s, %s hair" % [_gender.capitalize(), String(tone.get("name", "")), _hair.capitalize()]


# --- Widgets -----------------------------------------------------------------------

func _row(column: VBoxContainer, caption: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := UiStyle.label(caption, 14, UiStyle.DIM)
	label.custom_minimum_size = Vector2(44, 0)
	row.add_child(label)
	column.add_child(row)
	return row


func _small_button(row: Container, text: String, action: Callable) -> Button:
	var button := UiStyle.button(text)
	button.custom_minimum_size = Vector2(80, 30)
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(action)
	row.add_child(button)
	return button


func _swatch(row: HBoxContainer, color: Color, index: int) -> Button:
	var button := _small_button(row, "", _select_tone.bind(index))
	button.custom_minimum_size = Vector2(36, 30)
	var chip := ColorRect.new()
	chip.color = color
	chip.position = Vector2(6, 6)
	chip.size = Vector2(24, 18)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(chip)
	return button


func _mark(button: Button, selected: bool) -> void:
	button.add_theme_color_override("font_color", UiStyle.ACCENT if selected else UiStyle.INK)
	button.add_theme_stylebox_override("normal", UiStyle.panel(Color(0.08, 0.07, 0.1, 0.9), UiStyle.ACCENT if selected else UiStyle.BORDER))


func _preview_caption(text: String, at: Vector2) -> Label:
	var label := UiStyle.label(text, 12, UiStyle.DIM)
	label.position = at
	return label


func _button(column: VBoxContainer, text: String, action: Callable) -> Button:
	var button := UiStyle.button(text)
	button.pressed.connect(action)
	column.add_child(button)
	return button


func _disable_all() -> void:
	for button: Button in [new_game_button, continue_button, quit_button, start_button]:
		button.disabled = true
