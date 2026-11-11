class_name Bag
extends RefCounted
## The bag: how many of each item you carry.

var counts: Dictionary = {}


func add(id: String, n: int = 1) -> void:
	counts[id] = count(id) + n


func take(id: String) -> bool:
	if count(id) <= 0:
		return false
	counts[id] = count(id) - 1
	if counts[id] == 0:
		counts.erase(id)
	return true


func count(id: String) -> int:
	return int(counts.get(id, 0))


## Item ids in the bag, in the order of data/items.json, optionally of one kind ("treat", "heal").
func ids(kind: String = "") -> PackedStringArray:
	var out: PackedStringArray = []
	for id: String in Db.items:
		if count(id) > 0 and (kind == "" or Db.item(id)["kind"] == kind):
			out.append(id)
	return out
