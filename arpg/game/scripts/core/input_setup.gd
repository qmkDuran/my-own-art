class_name InputSetup
extends RefCounted
## Input actions. Click-to-move is the primary scheme: hold LMB on the ground to walk toward the cursor, LMB on an
## enemy to go and strike it, hold Shift to stand still and strike/cast toward the cursor. RMB and Q W E R use the
## skills placed on those keys (1-4 as alternates for Q W E R); Space dash; C character, I inventory, K skills, P stars, Alt labels,
## Esc pause.
## Keyboard movement (WASD/arrows) is an option in data/settings.json (off by default).

const SKILL_KEYS: Array = [[KEY_Q, KEY_1], [KEY_W, KEY_2], [KEY_E, KEY_3], [KEY_R, KEY_4]]
const KEYS: Dictionary = {"dodge": [KEY_SPACE], "inventory": [KEY_I], "skills": [KEY_K], "tree": [KEY_P], "character": [KEY_C], "pause": [KEY_ESCAPE],
	"stand": [KEY_SHIFT]}
const MOVE_KEYS: Dictionary = {"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT]}
const MOUSE: Dictionary = {"click": MOUSE_BUTTON_LEFT, "charge": MOUSE_BUTTON_RIGHT}

static var keyboard_movement: bool = false


static func ensure() -> void:
	if InputMap.has_action("click"):
		return
	keyboard_movement = bool(GameData.settings.get("wasd_movement", false))
	var keys: Dictionary = KEYS.duplicate()
	for i: int in SKILL_KEYS.size():
		var ks: Array = SKILL_KEYS[i].duplicate()
		if keyboard_movement and KEY_W in ks:
			ks.erase(KEY_W)
		keys["skill_%d" % (i + 1)] = ks
	if keyboard_movement:
		keys.merge(MOVE_KEYS)
	for action: String in keys:
		InputMap.add_action(action)
		for k: Key in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	for action: String in MOUSE:
		InputMap.add_action(action)
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE[action]
		InputMap.action_add_event(action, mb)


static func move_vector() -> Vector2:
	if not keyboard_movement:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
