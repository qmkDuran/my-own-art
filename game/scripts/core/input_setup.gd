class_name InputSetup
extends RefCounted
## The controls: arrows/WASD to move, Z/Space/Enter to accept (and to time presses), X/Esc/Backspace to cancel,
## Esc/Tab/M to open the menu. Registered from code so the project file stays small.

const ACTIONS: Dictionary = {
	"move_up": [KEY_UP, KEY_W], "move_down": [KEY_DOWN, KEY_S], "move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D], "accept": [KEY_Z, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER],
	"cancel": [KEY_X, KEY_ESCAPE, KEY_BACKSPACE], "menu": [KEY_ESCAPE, KEY_TAB, KEY_M],
}


static func register() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)
