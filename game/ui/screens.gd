class_name Screens
extends Control
## The full-screen panels around play: the loadout screen before a fight, pause (with the controls), and the win /
## lose text.

const CONTROLS: Array[Array] = [
	["WASD", "move (relative to the camera)"], ["Mouse", "look around"], ["Shift (hold)", "sneak: slow and quiet"],
	["Left / right click, Q, E", "your four moves (see the icons)"], ["Space", "dodge roll"],
	["Tab", "lock on to Thornback when you can see it"], ["Esc", "pause and free the mouse"], ["R", "restart"],
	["F3 / F9", "show the bot's mind / wipe what it learned about you"],
]
const DIM: Color = Color(0.02, 0.04, 0.03, 0.78)
const COLUMN_GAP: int = 28
const BLOCK_GAP: int = 18
const TIPS: String = ("Hide in bushes and tall grass: a hidden creature is invisible. Senses find the hidden.\n"
	+ "Strike before you are noticed for an ambush. Trees, rocks and logs stop shots.")

var main: Main
var _box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new()
	shade.color = DIM
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", BLOCK_GAP)
	centre.add_child(_box)


func show_phase(phase: MatchFlow.Phase) -> void:
	for child: Node in _box.get_children():
		child.queue_free()
	visible = phase != MatchFlow.Phase.PLAYING
	match phase:
		MatchFlow.Phase.INTRO:
			var loadout := LoadoutScreen.new()
			_box.add_child(loadout)
			loadout.setup(main)
		MatchFlow.Phase.PAUSED:
			_fill("PAUSED", "", "Esc or click to resume   ·   R to restart", true)
		MatchFlow.Phase.WON:
			_fill("YOU WIN", "Thornback is beaten.", "Press R to play again", false)
		MatchFlow.Phase.LOST:
			_fill("YOU LOSE", "Thornback got the better of you.", "Press R to try again", false)


func _fill(title: String, subtitle: String, prompt: String, with_controls: bool) -> void:
	_box.add_child(label(title, HudStyle.FONT_TITLE, HudStyle.INK))
	if subtitle != "":
		_box.add_child(label(subtitle, HudStyle.FONT_MEDIUM, HudStyle.INK_DIM))
	if with_controls:
		_box.add_child(_controls())
		_box.add_child(label(TIPS, HudStyle.FONT_SMALL, HudStyle.INK_DIM))
	_box.add_child(label(prompt, HudStyle.FONT_MEDIUM, HudStyle.AMBUSH_COLOR))


func _controls() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", COLUMN_GAP)
	for row: Array in CONTROLS:
		var key: Label = label(row[0], HudStyle.FONT_MEDIUM, HudStyle.AMBUSH_COLOR)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(key)
		var what: Label = label(row[1], HudStyle.FONT_MEDIUM, HudStyle.INK)
		what.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(what)
	return grid


static func label(words: String, font_size: int, color: Color) -> Label:
	var text := Label.new()
	text.text = words
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", font_size)
	text.add_theme_color_override("font_color", color)
	text.add_theme_color_override("font_outline_color", HudStyle.SHADOW)
	text.add_theme_constant_override("outline_size", HudStyle.OUTLINE)
	return text
