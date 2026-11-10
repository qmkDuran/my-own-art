class_name InputSetup
extends RefCounted
## Registers the input actions once. WASD/arrows move; the mouse aims. LMB strike (or click-to-move on open ground),
## RMB charge, skills on 1-4 (also Q E R F: W is a movement key), Space dodge, I inventory, P passive tree, Esc pause.

const KEYS: Dictionary = {
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"skill_1": [KEY_1, KEY_Q], "skill_2": [KEY_2, KEY_E], "skill_3": [KEY_3, KEY_R], "skill_4": [KEY_4, KEY_F],
	"dodge": [KEY_SPACE], "inventory": [KEY_I], "tree": [KEY_P], "pause": [KEY_ESCAPE],
}
const MOUSE: Dictionary = {"strike": MOUSE_BUTTON_LEFT, "charge": MOUSE_BUTTON_RIGHT}


static func ensure() -> void:
	if InputMap.has_action("strike"):
		return
	for action: String in KEYS:
		InputMap.add_action(action)
		for k: Key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	for action: String in MOUSE:
		InputMap.add_action(action)
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE[action]
		InputMap.action_add_event(action, mb)


static func move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
