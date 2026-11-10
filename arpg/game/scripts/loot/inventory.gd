class_name Inventory
extends RefCounted
## A bag of items (grid cells, one item each) and the equipped armour of God.

signal changed

const CELLS: int = 32

var bag: Array[Dictionary] = []
var equipped: Dictionary = {}          # equip slot -> item


func add(item: Dictionary) -> bool:
	if bag.size() >= CELLS:
		return false
	bag.append(item)
	changed.emit()
	return true


## The equip slot an item goes to (a second ring fills the free ring slot).
func target_slot(item: Dictionary) -> String:
	var slot: String = item["slot"]
	if slot == "ring" and equipped.has("ring") and not equipped.has("ring2"):
		return "ring2"
	return slot


func equip(index: int) -> void:
	var item: Dictionary = bag[index]
	var slot: String = target_slot(item)
	bag.remove_at(index)
	if equipped.has(slot):
		bag.append(equipped[slot])
	equipped[slot] = item
	changed.emit()


func unequip(slot: String) -> void:
	if equipped.has(slot) and bag.size() < CELLS:
		bag.append(equipped[slot])
		equipped.erase(slot)
		changed.emit()


func to_dict() -> Dictionary:
	return {"bag": bag.map(_pack), "equipped": equipped.keys().map(func(k: String) -> Array: return [k, _pack(equipped[k])])}


func from_dict(d: Dictionary) -> void:
	bag.clear()
	for it: Dictionary in d["bag"]:
		bag.append(_unpack(it))
	equipped.clear()
	for e: Array in d["equipped"]:
		equipped[e[0]] = _unpack(e[1])
	changed.emit()


static func _pack(it: Dictionary) -> Dictionary:
	var c: Dictionary = it.duplicate()
	c["icon"] = [it["icon"].x, it["icon"].y]
	return c


static func _unpack(it: Dictionary) -> Dictionary:
	var c: Dictionary = it.duplicate()
	c["icon"] = Vector2i(int(it["icon"][0]), int(it["icon"][1]))
	return c


func equipped_stats() -> Array:
	var out: Array = []
	for slot: String in equipped:
		out.append(equipped[slot]["stats"])
	return out


## Is a unique with this effect worn?
func has_proc(id: String) -> bool:
	for slot: String in equipped:
		if String(equipped[slot].get("proc", "")) == id:
			return true
	return false


## Index in the bag of the best upgrade for any slot, or -1.
func best_upgrade() -> int:
	var best: int = -1
	var gain: float = 0.0
	for i: int in bag.size():
		var slot: String = target_slot(bag[i])
		var cur: float = LootGen.score(equipped[slot]) if equipped.has(slot) else 0.0
		var g: float = LootGen.score(bag[i]) - cur
		if g > gain:
			gain = g
			best = i
	return best
