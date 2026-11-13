class_name InputSetup
## The control scheme, installed into the InputMap at start. Keys are physical positions, so WASD stays WASD on
## AZERTY and QWERTZ keyboards. Combat: left mouse fires the primary, right mouse (hold) charges the heavy, Q
## (hold to aim, release to throw) the lantern bomb, E the ward, R the super, Tab locks on, V blinks.

const KEYS: Dictionary = {
	"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT], "run": [KEY_SHIFT], "toggle_rain": [KEY_T], "free_mouse": [KEY_ESCAPE],
	"toggle_hints": [KEY_H], "ward": [KEY_E], "jump": [KEY_SPACE], "graphics": [KEY_G],
	"frame_cap": [KEY_F], "vsync": [KEY_F9], "fullscreen": [KEY_F11], "dash": [KEY_V], "fly": [KEY_F1],
	"fly_down": [KEY_CTRL, KEY_C], "perf_overlay": [KEY_F3], "render_driver": [KEY_F10],
	"bomb": [KEY_Q], "super": [KEY_R], "lock_on": [KEY_TAB],
}
const MOUSE: Dictionary = { "primary": MOUSE_BUTTON_LEFT, "heavy": MOUSE_BUTTON_RIGHT }


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
