class_name PausePanel
extends Control
## Esc: the game pauses; controls, the premise and the Biblica notice.

const LINES: PackedStringArray = [
	"Hold the left button to walk toward the cursor; click an enemy to strike it.   Shift: stand and strike.",
	"Right button: Descent.   Q W E R (or 1-4): skills.   Space: dodge.   I inventory   K skills   P stars.",
	"Walk over items to pick them up, or click their names.",
]


func setup() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color(0, 0, 0, 0.7))
	UiDraw.text(self, Vector2(0, 110), "Paused", UiDraw.GOLD, 32, HORIZONTAL_ALIGNMENT_CENTER, 960.0)
	for i: int in LINES.size():
		UiDraw.text(self, Vector2(0, 170 + 18 * i), LINES[i], Color.WHITE, 16, HORIZONTAL_ALIGNMENT_CENTER, 960.0)
	var v: PackedStringArray = UiDraw.verse_lines("struggle", 90)
	for i: int in v.size():
		UiDraw.text(self, Vector2(0, 260 + 16 * i), v[i], Color("dcd3c0"), 16, HORIZONTAL_ALIGNMENT_CENTER, 960.0)
	var n: String = Scripture.notice()
	var words: PackedStringArray = n.split(" ")
	var half: int = words.size() / 2
	UiDraw.text(self, Vector2(0, 470), " ".join(words.slice(0, half)), UiDraw.DIM, 16, HORIZONTAL_ALIGNMENT_CENTER, 960.0)
	UiDraw.text(self, Vector2(0, 486), " ".join(words.slice(half)), UiDraw.DIM, 16, HORIZONTAL_ALIGNMENT_CENTER, 960.0)
	UiDraw.text(self, Vector2(0, 380), "Esc: resume", Color.WHITE, 16, HORIZONTAL_ALIGNMENT_CENTER, 960.0)
