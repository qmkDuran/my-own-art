class_name AskDialog
extends Control
## A question with two answers, Accept and Decline (a trainer's "Want to battle?"). Nothing is forced: Decline (or
## Esc) just closes it. Shown above the creature card.

const W: float = 340.0
const H: float = 74.0
const BTN := Vector2(90, 20)

var text: String = ""
var _yes: Callable
var _no: Callable


func setup() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(W, H)
	_button("Accept", Vector2(W * 0.5 - BTN.x - 8.0, H - BTN.y - 10.0), accept)
	_button("Decline", Vector2(W * 0.5 + 8.0, H - BTN.y - 10.0), decline)


func ask(question: String, yes: Callable, no: Callable) -> void:
	text = question
	_yes = yes
	_no = no
	visible = true
	Audio.sfx("ui_open", -8.0)
	queue_redraw()


func accept() -> void:
	_answer(_yes)


func decline() -> void:
	_answer(_no)


func _answer(then: Callable) -> void:
	if not visible:
		return
	visible = false
	Audio.sfx("ui_click", -6.0)
	if then.is_valid():
		then.call()


func _button(label: String, at: Vector2, on_press: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.position = at
	b.size = BTN
	b.add_theme_font_size_override("font_size", UiDraw.SMALL)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_press)
	add_child(b)


func _draw() -> void:
	UiDraw.box(self, Rect2(Vector2.ZERO, size), Color(UiDraw.PANEL, 0.95), UiDraw.FRAME_LIT)
	var lines: PackedStringArray = UiDraw.wrap(self, text, W - 20.0, UiDraw.BODY)
	for i: int in lines.size():
		UiDraw.text(self, Vector2(0, 18.0 + i * 13.0), lines[i], UiDraw.TEXT, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, W)
