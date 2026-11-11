class_name TitleScreen
extends Control
## The title: the half-withered vale, the three young wildkin, the game's name, and New Game / Continue.

signal chosen(option: String)

const LOGO_Y: int = 16
const MENU_W: int = 92

var _menu: MenuList


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view: Vector2 = get_viewport_rect().size
	var bg := TextureRect.new()
	bg.texture = load("res://art/scenes/title.png")
	bg.position = ((view - Vector2(320, 180)) / 2).floor()
	add_child(bg)
	_logo(view)
	_starters(view)
	_build_menu(view)
	Audio.music("title")


func _logo(view: Vector2) -> void:
	var title := UiKit.label("MONSTER TAMER", "cream")
	title.add_theme_font_override("font", UiKit.small_font())
	title.add_theme_font_size_override("font_size", UiKit.SMALL_SIZE * 2)
	title.add_theme_color_override("font_outline_color", UiKit.c("ink"))
	title.add_theme_constant_override("outline_size", 4)
	title.position = Vector2((view.x - UiKit.text_width("MONSTER TAMER", true) * 2) / 2, LOGO_Y)
	add_child(title)
	var sub := UiKit.label("A tale of the Wending Vale", "ink2")
	sub.position = Vector2((view.x - UiKit.text_width(sub.text)) / 2, LOGO_Y + 22)
	add_child(sub)


func _starters(view: Vector2) -> void:
	var ids: Array[String] = ["emberkit", "mossfawn", "ripplet"]
	for i: int in ids.size():
		var t := TextureRect.new()
		t.texture = UiKit.creature_tex(ids[i], "front")
		t.position = Vector2(view.x / 2 - 120 + i * 80, view.y - 84)
		add_child(t)


func _build_menu(view: Vector2) -> void:
	var options: PackedStringArray = ["New Game", "Continue"] if SaveSystem.has_save() else ["New Game"]
	var panel := UiKit.panel(Rect2((view.x - MENU_W) / 2, LOGO_Y + 42, MENU_W, options.size() * MenuList.ROW_H + 8))
	add_child(panel)
	_menu = MenuList.new()
	panel.add_child(_menu)
	_menu.setup(options, 1, MENU_W - 12)
	_menu.position = Vector2(6, 3)
	_menu.cancellable = false
	_wait_choice(options)


func _wait_choice(options: PackedStringArray) -> void:
	var i: int = await _menu.pick()
	chosen.emit("new" if options[i] == "New Game" else "continue")
