class_name FlagStore
extends RefCounted
## Story flags: named values (usually booleans) that drive conditions and dialogue branches.

signal changed(flag: String, value: Variant)

var _values: Dictionary = {}


func set_flag(flag: String, value: Variant = true) -> void:
	if _values.get(flag) == value:
		return
	_values[flag] = value
	changed.emit(flag, value)


func clear(flag: String) -> void:
	if not _values.has(flag):
		return
	_values.erase(flag)
	changed.emit(flag, null)


func is_set(flag: String) -> bool:
	var value: Variant = _values.get(flag)
	if value is bool:
		return value
	if value is int or value is float:
		return value != 0
	if value is String:
		return not (value as String).is_empty()
	return false


func get_value(flag: String, fallback: Variant = null) -> Variant:
	return _values.get(flag, fallback)


func to_dict() -> Dictionary:
	return _values.duplicate(true)


func load_dict(values: Dictionary) -> void:
	_values = values.duplicate(true)
	changed.emit("", null)
