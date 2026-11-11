class_name InputSetup
extends RefCounted
## Input actions (mouse + keyboard). LMB: move / attack / take / use (hold to keep moving toward the cursor);
## hold Shift: stand still and attack or cast toward the cursor; RMB and Q W E R: skill slots; Space: Wickstep;
## 1: tonic; I inventory, C character, K skills, P passives, Alt labels, Esc menu.

const KEYS: Dictionary = {
	"slot_q": [KEY_Q], "slot_w": [KEY_W], "slot_e": [KEY_E], "slot_r": [KEY_R], "dash": [KEY_SPACE], "tonic": [KEY_1],
	"inventory": [KEY_I], "character": [KEY_C], "skills": [KEY_K], "passives": [KEY_P], "labels": [KEY_ALT],
	"menu": [KEY_ESCAPE], "stand": [KEY_SHIFT], "interact": [KEY_F],
}
const MOUSE: Dictionary = {"click": MOUSE_BUTTON_LEFT, "slot_rmb": MOUSE_BUTTON_RIGHT}
## Hotbar order: slot action -> label shown on the bar.
const SLOTS: Array[String] = ["lmb", "rmb", "q", "w", "e", "r"]
const SLOT_LABELS: Dictionary = {"lmb": "LMB", "rmb": "RMB", "q": "Q", "w": "W", "e": "E", "r": "R"}


static func ensure() -> void:
	if InputMap.has_action("click"):
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
