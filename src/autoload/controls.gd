extends Node
## Registers the input map in code so every binding lives in one readable place.
## Keyboard: WASD/arrows move, Shift run, E interact, J/left mouse attack, Space dodge, I/Tab inventory.
## Gamepad: left stick/d-pad move, LB run, A interact, X attack, B dodge, Y inventory.

const DEADZONE := 0.25


func _ready() -> void:
	_bind("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT)])
	_bind("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT)])
	_bind("move_up", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0), _button(JOY_BUTTON_DPAD_UP)])
	_bind("move_down", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN)])
	_bind("run", [_key(KEY_SHIFT), _button(JOY_BUTTON_LEFT_SHOULDER), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_bind("interact", [_key(KEY_E), _button(JOY_BUTTON_A)])
	_bind("attack", [_key(KEY_J), _mouse(MOUSE_BUTTON_LEFT), _button(JOY_BUTTON_X)])
	_bind("dodge", [_key(KEY_SPACE), _button(JOY_BUTTON_B)])
	_bind("inventory", [_key(KEY_I), _key(KEY_TAB), _button(JOY_BUTTON_Y)])
	_bind("pause", [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])


func _bind(action: StringName, events: Array[InputEvent]) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, DEADZONE)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


func _key(keycode: Key) -> InputEvent:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


func _mouse(button: MouseButton) -> InputEvent:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


func _button(button: JoyButton) -> InputEvent:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


func _axis(axis: JoyAxis, direction: float) -> InputEvent:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = direction
	return event
