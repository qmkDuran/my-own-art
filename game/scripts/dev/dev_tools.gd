class_name DevTools
extends Node
## The playtest tools in a game (only when Dev is enabled): F1 the dev menu, F8 a feedback note, the session log
## and the debug overlay.

var g: Game
var _menu := DevMenu.new()
var _feedback := FeedbackBox.new()


func setup(game: Game) -> void:
	g = game
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu)
	_menu.setup(g)
	add_child(_feedback)
	_feedback.setup(g)
	var log := SessionLog.new()
	add_child(log)
	log.setup(g)
	g.world.add_child(DevOverlay.new())


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_F1 and not _feedback.is_open():
		_menu.toggle()
		get_viewport().set_input_as_handled()
	elif k.keycode == KEY_F8 and not _feedback.is_open():
		_feedback.open()
		get_viewport().set_input_as_handled()
	elif k.keycode == KEY_ESCAPE and _feedback.is_open():
		_feedback.close()
		get_viewport().set_input_as_handled()
