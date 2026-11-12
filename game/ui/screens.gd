class_name Screens
extends Control
## The full-screen panels around play: the start screen with the controls, pause, and the win / lose text.

const CONTROLS: Array[Array] = [
	["WASD", "move (relative to the camera)"], ["Mouse", "look around"], ["Shift (hold)", "sneak: slow and quiet"],
	["Left click", "Bite: wind-up, lunge, close range"], ["Right click", "Spit: slow glob, aim with the crosshair"],
	["Space", "dodge roll (cooldown)"], ["F", "set a snare (1 at a time, takes a second, noisy)"],
	["Tab", "lock on to Thornback when you can see it"], ["Esc", "pause and free the mouse"], ["R", "restart"],
	["F3 / F9", "show the bot's mind / wipe what it learned about you"],
]
const DIM: Color = Color(0.02, 0.04, 0.03, 0.78)
const COLUMN_GAP: int = 28
const BLOCK_GAP: int = 22
const TIPS: String = ("Hide in bushes and tall grass. Strike from hiding (or from behind) for an ambush.\n"
	+ "Trees, rocks and logs stop spit. Sneak to stay unheard. The ridge gives a little more range.")

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
			_fill("CREATURE WOODS", "Outsmart Thornback: stalk, hide, ambush, set snares.",
					"Click or press Enter to start", true)
			_box.add_child(_label(_difficulty_line(), HudStyle.FONT_SMALL, HudStyle.INK))
		MatchFlow.Phase.PAUSED:
			_fill("PAUSED", "", "Esc or click to resume   ·   R to restart", true)
			_box.add_child(_label(_difficulty_line(), HudStyle.FONT_SMALL, HudStyle.INK))
		MatchFlow.Phase.WON:
			_fill("YOU WIN", "Thornback is beaten.", "Press R to play again", false)
		MatchFlow.Phase.LOST:
			_fill("YOU LOSE", "Thornback got the better of you.", "Press R to try again", false)


func _fill(title: String, subtitle: String, prompt: String, with_controls: bool) -> void:
	_box.add_child(_label(title, HudStyle.FONT_TITLE, HudStyle.INK))
	if subtitle != "":
		_box.add_child(_label(subtitle, HudStyle.FONT_MEDIUM, HudStyle.INK_DIM))
	if with_controls:
		_box.add_child(_controls())
		_box.add_child(_label(TIPS, HudStyle.FONT_SMALL, HudStyle.INK_DIM))
	_box.add_child(_label(prompt, HudStyle.FONT_MEDIUM, HudStyle.AMBUSH_COLOR))


static func _difficulty_line() -> String:
	return "Difficulty: %s   (1 Easy  ·  2 Normal  ·  3 Hard: changes how Thornback thinks, never its stats)" \
			% Difficulty.level.capitalize()


func _controls() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", COLUMN_GAP)
	for row: Array in CONTROLS:
		var key: Label = _label(row[0], HudStyle.FONT_MEDIUM, HudStyle.AMBUSH_COLOR)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(key)
		var what: Label = _label(row[1], HudStyle.FONT_MEDIUM, HudStyle.INK)
		what.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(what)
	return grid


static func _label(words: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HudStyle.SHADOW)
	label.add_theme_constant_override("outline_size", HudStyle.OUTLINE)
	return label
