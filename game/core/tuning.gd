extends Node
## Autoload "Tuning": every feel number, the town layout, the lighting look and the asset list, loaded once from
## data/*.json so the town is tuned in data, not code. Tuning.f("player", "walk_speed") reads data/tuning.json;
## Tuning.look_f("moon", "energy") reads data/lighting.json; Tuning.doc("town") returns a whole file.

const DATA_DIR: String = "res://data/"
const FILES: Array[String] = ["tuning", "lighting", "assets", "town", "npcs", "audio", "defence", "skills", "graphics",
	"perf", "vfx"]

var _docs: Dictionary = {}


func _init() -> void:
	for file: String in FILES:
		_docs[file] = _load_json(DATA_DIR + file + ".json")


## A whole data file (layout lists, asset tables).
func doc(file: String) -> Dictionary:
	return _docs[file]


## One number from data/tuning.json; a missing key is a data bug, so it fails loudly.
func f(section: String, key: String) -> float:
	return _number("tuning", section, key)


func i(section: String, key: String) -> int:
	return int(f(section, key))


func degrees(section: String, key: String) -> float:
	return deg_to_rad(f(section, key))


## One number from data/lighting.json.
func look_f(section: String, key: String) -> float:
	return _number("lighting", section, key)


func i_look(section: String, key: String) -> int:
	return int(look_f(section, key))


## One colour from data/lighting.json.
func look_color(section: String, key: String) -> Color:
	return color(_docs["lighting"][section][key])


## One number from any data file.
func number(file: String, section: String, key: String) -> float:
	return _number(file, section, key)


static func color(rgb: Array) -> Color:
	var alpha: float = float(rgb[3]) if rgb.size() > 3 else 1.0
	return Color(float(rgb[0]), float(rgb[1]), float(rgb[2]), alpha)


static func vec3(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


## A ground position from an [x, z] pair (y = 0) or an [x, y, z] triple.
static func point(values: Array) -> Vector3:
	if values.size() == 2:
		return Vector3(float(values[0]), 0.0, float(values[1]))
	return vec3(values)


func _number(file: String, section: String, key: String) -> float:
	var table: Dictionary = _docs[file][section]
	assert(table.has(key), "%s.json has no %s.%s" % [file, section, key])
	return float(table[key])


static func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "could not read " + path)
	return parsed
