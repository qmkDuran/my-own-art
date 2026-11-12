class_name TamerKeys
extends RefCounted
## The prototype's own keys, added beside Lanternfall's (InputSetup: click, Q W E R slots, Space dash, Shift, F).
## 1-6 swap creatures, Z and V items, T the bond move, C the camp panel, F1 (dev) spawns a shiny.

const KEYS: Dictionary = {
	"swap_1": [KEY_1], "swap_2": [KEY_2], "swap_3": [KEY_3], "swap_4": [KEY_4], "swap_5": [KEY_5], "swap_6": [KEY_6],
	"item_berry": [KEY_Z], "item_salts": [KEY_V],
	"bond_move": [KEY_T], "camp": [KEY_C],
	"dev_shiny": [KEY_F1], "retreat": [KEY_X],
}
const SWAPS: Array[String] = ["swap_1", "swap_2", "swap_3", "swap_4", "swap_5", "swap_6"]
const MOVE_SLOTS: Array[String] = ["slot_q", "slot_w", "slot_e", "slot_r"]
const MOVE_LABELS: Array[String] = ["Q", "W", "E", "R"]


static func ensure() -> void:
	InputSetup.ensure()
	if InputMap.has_action("swap_1"):
		return
	for action: String in KEYS:
		InputMap.add_action(action)
		for k: Key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
