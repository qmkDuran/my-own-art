class_name InputSetup
## The control scheme, installed into the InputMap at start. Keys are physical positions, so WASD stays WASD on
## AZERTY and QWERTZ keyboards.

const KEYS: Dictionary = {
	"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT], "dodge": [KEY_SPACE], "sneak": [KEY_SHIFT], "lock_on": [KEY_TAB],
	"trap": [KEY_F], "pause": [KEY_ESCAPE], "restart": [KEY_R], "start": [KEY_ENTER],
}
const MOUSE: Dictionary = { "bite": MOUSE_BUTTON_LEFT, "spit": MOUSE_BUTTON_RIGHT }


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
