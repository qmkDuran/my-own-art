class_name InputSetup
extends RefCounted
## Registers the game's input actions once: WASD/arrows to move, Shift (or pad B) to run, E to talk or worship,
## T/Tab for the places menu, wheel / +/- / Z to zoom.

const ACTIONS: Dictionary = {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	"talk": [KEY_E], "worship": [KEY_E], "run": [KEY_SHIFT], "places": [KEY_T, KEY_TAB],
	"zoom_in": [KEY_EQUAL, KEY_KP_ADD], "zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT], "zoom_cycle": [KEY_Z],
}
const WHEEL: Dictionary = {"zoom_in": MOUSE_BUTTON_WHEEL_UP, "zoom_out": MOUSE_BUTTON_WHEEL_DOWN}
const PAD: Dictionary = {"run": JOY_BUTTON_B, "talk": JOY_BUTTON_A, "worship": JOY_BUTTON_A, "places": JOY_BUTTON_Y}


static func ensure() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		if PAD.has(action):
			var pad := InputEventJoypadButton.new()
			pad.button_index = PAD[action]
			InputMap.action_add_event(action, pad)
		if WHEEL.has(action):
			var wheel := InputEventMouseButton.new()
			wheel.button_index = WHEEL[action]
			InputMap.action_add_event(action, wheel)


static func is_escape(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode == KEY_ESCAPE
