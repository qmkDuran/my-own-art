extends Control
## First screen: the "work of fiction" note, then the main menu.

const HOLD_TIME := 5.0
const MENU_SCENE := "res://scenes/menu/main_menu.tscn"

const TEXT := "This is a work of fiction.\n\nIt is inspired by the Book of Revelation, but its characters, places,\norganizations and events are invented. Halvern Ridge is not a real town.\nAny resemblance to real people or businesses is coincidental.\n\nThe story touches on loss, panic and violence."

var _elapsed := 0.0
var _leaving := false


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("0a090e")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var label := UiStyle.label(TEXT, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)
	var hint := UiStyle.label("Press any key", 12, UiStyle.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 490)
	hint.size = Vector2(960, 20)
	add_child(hint)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= HOLD_TIME:
		_leave()


func _unhandled_input(event: InputEvent) -> void:
	if _elapsed > 0.6 and event.is_pressed() and not event.is_echo():
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
