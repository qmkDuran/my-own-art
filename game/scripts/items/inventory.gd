class_name Inventory
extends RefCounted
## The bag (a grid of cells, one item each) and the ten equipment slots. Equipping swaps with what was worn;
## rings go to the free ring slot first. Items are plain dictionaries from LootGen.

signal changed

const BAG_COLS: int = 8
const BAG_ROWS: int = 5

var bag: Array = []                  ## BAG_COLS * BAG_ROWS entries; {} = empty
var equipped: Dictionary = {}


func _init() -> void:
	bag.resize(BAG_COLS * BAG_ROWS)
	bag.fill({})
	for s: String in GameData.items["equip_slots"]:
		equipped[s] = {}


func free_cell() -> int:
	for i: int in bag.size():
		if (bag[i] as Dictionary).is_empty():
			return i
	return -1


func add(it: Dictionary) -> bool:
	var i: int = free_cell()
	if i < 0:
		return false
	bag[i] = it
	changed.emit()
	return true


func bag_items() -> Array:
	return bag.filter(func(x: Dictionary) -> bool: return not x.is_empty())


## Which equipment slot an item goes to (the emptier ring slot for rings).
func target_slot(it: Dictionary) -> String:
	if it["slot"] == "ring":
		return "ring2" if not (equipped["ring1"] as Dictionary).is_empty() and (equipped["ring2"] as Dictionary).is_empty() else "ring1"
	return String(it["slot"])


func can_wear(it: Dictionary, level: int) -> bool:
	return int(it.get("req", 1)) <= level


func equip(cell: int, level: int) -> bool:
	var it: Dictionary = bag[cell]
	if it.is_empty() or not can_wear(it, level):
		return false
	var slot: String = target_slot(it)
	bag[cell] = equipped[slot]
	equipped[slot] = it
	changed.emit()
	return true


func unequip(slot: String) -> bool:
	var it: Dictionary = equipped[slot]
	var i: int = free_cell()
	if it.is_empty() or i < 0:
		return false
	bag[i] = it
	equipped[slot] = {}
	changed.emit()
	return true


func remove_at(cell: int) -> Dictionary:
	var it: Dictionary = bag[cell]
	bag[cell] = {}
	changed.emit()
	return it


func set_count(sid: String) -> int:
	var n: int = 0
	for s: String in equipped:
		if String((equipped[s] as Dictionary).get("set", "")) == sid:
			n += 1
	return n


func set_bonus_stats() -> Dictionary:
	var out: Dictionary = {}
	for sid: String in GameData.items["sets"]:
		var bonus: Dictionary = GameData.items["sets"][sid]["bonus"]
		for need: String in bonus:
			if set_count(sid) >= int(need):
				for k: String in bonus[need]:
					out[k] = float(out.get(k, 0.0)) + float(bonus[need][k])
	return out


func to_dict() -> Dictionary:
	return {"bag": bag, "equipped": equipped}


func from_dict(d: Dictionary) -> void:
	var b: Array = d.get("bag", [])
	for i: int in mini(b.size(), bag.size()):
		bag[i] = b[i]
	var e: Dictionary = d.get("equipped", {})
	for s: String in e:
		if equipped.has(s):
			equipped[s] = e[s]
	changed.emit()
