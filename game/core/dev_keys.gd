class_name DevKeys
extends Node
## Keys for playtesting that work any time: F3 shows the bot's mind, F9 wipes what it has learned about you.

var _overlay: DebugOverlay
var _brain: BotBrain


func setup(overlay: DebugOverlay, brain: BotBrain) -> void:
	_overlay = overlay
	_brain = brain
	name = "DevKeys"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_view"):
		_overlay.toggle()
	elif event.is_action_pressed("reset_memory"):
		_brain.model.reset()
		_brain.model.save()
		_brain.bark("Its memory of you is wiped.")
