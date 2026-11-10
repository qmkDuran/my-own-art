extends Node2D
## Start screen: choose a scene. Command-line user args skip it:
## `-- --city`, `-- --throne`, `-- --earth`; add `--demo` for a scripted walk; `--earth-demo` walks out of the city gate.

const SCENES: Array = [
	["1   The holy city, New Jerusalem   (Revelation 21-22)", "res://main.tscn"],
	["2   The throne room of heaven   (Revelation 4-5)", "res://throne.tscn"],
	["3   The new earth   (Isaiah 11, 35, 65)", "res://earth.tscn"],
]
## First matching user arg wins -> scene index.
const SKIP_ARGS: Array = [["--throne", 1], ["--earth", 2], ["--earth-demo", 0], ["--district-demo", 0], ["--city", 0], ["--demo", 0]]
const BACKGROUND := Color(0.9937, 1.0, 0.8102)   # pale gold light (fbff86 blended 60% to white)
const SELECTED := Color("f9c22b")
const FIRST_ROW_Y: float = 250.0
const ROW_GAP: float = 40.0

var _choice: int = 0
var _labels: Array[Label] = []


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for skip: Array in SKIP_ARGS:
		if args.has(skip[0]):
			_go.call_deferred(int(skip[1]))
			return
	Audio.play_music("menu_music", -12.0)
	var bg := ColorRect.new()
	bg.color = BACKGROUND
	bg.size = Vector2(960, 540)
	add_child(bg)
	UiText.label(self, UiText.LARGE, 150.0, "Heaven")
	for i: int in SCENES.size():
		_labels.append(UiText.label(self, UiText.SMALL, FIRST_ROW_Y + i * ROW_GAP, SCENES[i][0]))
	UiText.label(self, UiText.SMALL, 400.0, "Up/Down + Enter, or press 1 / 2 / 3.   Esc in a scene returns here.")
	UiText.label(self, UiText.SMALL, 466.0, _notice_lines()).modulate.a = 0.85
	_refresh()


## The NIV permission notice (Biblica), required on the credits screen, broken into lines that fit.
func _notice_lines() -> String:
	return Scripture.notice().replace("NIV® Copyright", "NIV®\nCopyright").replace("Inc.™ Used", "Inc.™\nUsed")


func _refresh() -> void:
	for i: int in _labels.size():
		_labels[i].label_settings.font_color = SELECTED if i == _choice else Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_UP, KEY_W:
			_choice = maxi(0, _choice - 1)
			_refresh()
		KEY_DOWN, KEY_S:
			_choice = mini(SCENES.size() - 1, _choice + 1)
			_refresh()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_go(_choice)
		KEY_1, KEY_2, KEY_3:
			_go((event as InputEventKey).physical_keycode - KEY_1)


func _go(i: int) -> void:
	get_tree().change_scene_to_file(SCENES[i][1])
