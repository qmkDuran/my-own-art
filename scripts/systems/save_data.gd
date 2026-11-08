class_name SaveData
extends RefCounted
## Safe readers for a save file's values. JSON has no types beyond numbers, strings,
## arrays and objects (and every number comes back as a float), and a save may be old,
## hand-edited or damaged, so each reader falls back to a default instead of crashing.

## Ceiling for saved counts that have no natural maximum (keeps a damaged file's huge numbers out).
const NO_LIMIT := 1_000_000


## A whole number from `data[key]`, clamped to `minimum`..`maximum`; `fallback` if missing or not a number.
static func read_int(data: Dictionary, key: String, fallback: int, minimum: int, maximum: int) -> int:
	var value: Variant = data.get(key)
	if not (value is int or value is float):
		return fallback
	return clampi(int(value), minimum, maximum)


## The strings in the array `data[key]`, skipping anything that isn't a string; empty if missing.
static func read_strings(data: Dictionary, key: String) -> Array[String]:
	var strings: Array[String] = []
	var value: Variant = data.get(key)
	if not value is Array:
		return strings
	for item: Variant in value:
		if item is String:
			strings.append(item)
	return strings


## The object `data[key]`, or an empty one if missing or not an object.
static func read_section(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key)
	return value if value is Dictionary else {}
