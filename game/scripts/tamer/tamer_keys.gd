class_name TamerKeys
extends RefCounted
## The prototype's own keys, added beside Lanternfall's (InputSetup: click, Q W E R slots, Space dash, Shift, F).
## 1-3 swap creatures, 4-5 items, T the bond move, C the camp panel, A S D G the trainer's commands.

const KEYS: Dictionary = {
	"swap_1": [KEY_1], "swap_2": [KEY_2], "swap_3": [KEY_3], "item_berry": [KEY_4], "item_salts": [KEY_5],
	"bond_move": [KEY_T], "camp": [KEY_C],
	"cmd_cheer": [KEY_A], "cmd_focus": [KEY_S], "cmd_rally": [KEY_D], "cmd_mark": [KEY_G],
}
const SWAPS: Array[String] = ["swap_1", "swap_2", "swap_3"]
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
