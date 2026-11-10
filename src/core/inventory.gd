class_name Inventory
extends RefCounted
## Item counts (insertion ordered) plus the equipped weapon. Item definitions live in data/items.json.

signal changed

var equipped_weapon := ""
var _counts: Dictionary = {}


func add(item_id: String, amount: int = 1) -> void:
	_counts[item_id] = count(item_id) + amount
	changed.emit()


func remove(item_id: String, amount: int = 1) -> bool:
	if count(item_id) < amount:
		return false
	_counts[item_id] = count(item_id) - amount
	if _counts[item_id] <= 0:
		_counts.erase(item_id)
		if equipped_weapon == item_id:
			equipped_weapon = ""
	changed.emit()
	return true


func count(item_id: String) -> int:
	return int(_counts.get(item_id, 0))


func has_item(item_id: String) -> bool:
	return count(item_id) > 0


func item_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in _counts.keys():
		ids.append(String(key))
	return ids


func equip(item_id: String) -> void:
	equipped_weapon = item_id if has_item(item_id) else ""
	changed.emit()


func clear() -> void:
	_counts.clear()
	equipped_weapon = ""
	changed.emit()


func to_dict() -> Dictionary:
	return {"counts": _counts.duplicate(), "equipped": equipped_weapon}


func load_dict(data: Dictionary) -> void:
	_counts.clear()
	var counts: Dictionary = data.get("counts", {})
	for key: Variant in counts.keys():
		_counts[String(key)] = int(counts[key])
	equipped_weapon = String(data.get("equipped", ""))
	changed.emit()
