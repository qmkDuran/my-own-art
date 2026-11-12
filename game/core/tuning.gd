extends Node
## Autoload "Tuning": every feel number, the woods layout and the creature looks, loaded once from data/*.json so
## the game is tuned in data, not code. Read numbers with Tuning.f("bite", "damage").

const TUNING_PATH: String = "res://data/tuning.json"
const WOODS_PATH: String = "res://data/woods.json"
const CREATURES_PATH: String = "res://data/creatures.json"

var woods: Dictionary = {}
var creatures: Dictionary = {}
var _tuning: Dictionary = {}


func _init() -> void:
	_tuning = _load_json(TUNING_PATH)
	woods = _load_json(WOODS_PATH)
	creatures = _load_json(CREATURES_PATH)


## One tuning number; a missing key is a data bug, so it fails loudly.
func f(section: String, key: String) -> float:
	var table: Dictionary = _tuning[section]
	assert(table.has(key), "tuning.json has no %s.%s" % [section, key])
	return float(table[key])


func i(section: String, key: String) -> int:
	return int(f(section, key))


func degrees(section: String, key: String) -> float:
	return deg_to_rad(f(section, key))


func color(rgb: Array) -> Color:
	var alpha: float = float(rgb[3]) if rgb.size() > 3 else 1.0
	return Color(float(rgb[0]), float(rgb[1]), float(rgb[2]), alpha)


func palette(name: String) -> Color:
	return color(woods["palette"][name])


func vec2(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


static func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "could not read " + path)
	return parsed
