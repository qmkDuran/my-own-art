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


func equipped_stats() -> Array:
	var out: Array = []
	for slot: String in equipped:
		out.append(equipped[slot]["stats"])
	return out


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
