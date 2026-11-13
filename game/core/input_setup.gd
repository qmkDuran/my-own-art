class_name InputSetup
## The control scheme, installed into the InputMap at start. Keys are physical positions, so WASD stays WASD on
## AZERTY and QWERTZ keyboards.

const KEYS: Dictionary = {
	"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT], "run": [KEY_SHIFT], "toggle_rain": [KEY_R], "free_mouse": [KEY_ESCAPE],
	"toggle_hints": [KEY_H], "interact": [KEY_E], "dodge": [KEY_SPACE],
}
const MOUSE: Dictionary = { "light_burst": MOUSE_BUTTON_LEFT }


static func install() -> void:
	for action: String in KEYS:
		_ensure(action)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	for action: String in MOUSE:
		_ensure(action)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE[action]
		InputMap.action_add_event(action, click)


static func _ensure(action: String) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
