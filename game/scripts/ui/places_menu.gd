class_name PlacesMenu
extends CanvasLayer
## Fast travel (T / Tab): a small pixel-font list of places from res://data/places.json.
## Up/Down or number keys + Enter to go (through the usual fade to white), Esc / T / Tab to close.

signal chosen(place: Dictionary)

const PATH: String = "res://data/places.json"
const PANEL := Rect2(300, 150, 360, 220)
const ROW_GAP: float = 26.0
const SELECTED := Color("f9c22b")

var places: Array = []
var _labels: Array[Label] = []
var _choice: int = 0
var _panel: ColorRect


func _ready() -> void:
	layer = 10
	places = SceneData.load_json(PATH)["places"]
	_panel = ColorRect.new()
	_panel.color = Color(0.18, 0.13, 0.18, 0.82)
	_panel.position = PANEL.position
	_panel.size = PANEL.size
	add_child(_panel)
	UiText.label(self, UiText.SMALL, PANEL.position.y + 10.0, "Go to ...")
	for i: int in places.size():
		_labels.append(UiText.label(self, UiText.SMALL, PANEL.position.y + 40.0 + i * ROW_GAP, "%d  %s" % [i + 1, places[i]["name"]]))
	UiText.label(self, UiText.SMALL, PANEL.end.y - 24.0, "Enter: go    Esc: close").modulate.a = 0.75
	visible = false


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func _refresh() -> void:
	for i: int in _labels.size():
		_labels[i].label_settings.font_color = SELECTED if i == _choice else Color.WHITE


## Choose a destination by index (also used by the smoke test).
func choose(i: int) -> void:
	close()
	chosen.emit(places[i])


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	var key: Key = (event as InputEventKey).physical_keycode
	if key == KEY_ESCAPE or event.is_action("places"):
		close()
	elif key in [KEY_UP, KEY_W]:
		_choice = maxi(0, _choice - 1); _refresh()
	elif key in [KEY_DOWN, KEY_S]:
		_choice = mini(places.size() - 1, _choice + 1); _refresh()
	elif key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		choose(_choice)
	elif key >= KEY_1 and key < KEY_1 + places.size():
		choose(key - KEY_1)
