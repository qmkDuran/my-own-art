extends Node
## Read-only game data loaded from res://data/*.json (items, enemies, speakers, heroes, tiles, lights, art).

const DATA_DIR := "res://data/"

var items: Dictionary = {}
var enemies: Dictionary = {}
var speakers: Dictionary = {}
var heroes: Dictionary = {}
var tiles: Dictionary = {}
var lights: Dictionary = {}
var art: Dictionary = {}

var _zone_cache: Dictionary = {}


func _ready() -> void:
	items = load_json(DATA_DIR + "items.json")
	enemies = load_json(DATA_DIR + "enemies.json")
	speakers = load_json(DATA_DIR + "speakers.json")
	heroes = load_json(DATA_DIR + "heroes.json")
	tiles = load_json(DATA_DIR + "tiles.json")
	lights = load_json(DATA_DIR + "lights.json")
	art = load_json(DATA_DIR + "art.json")


func item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func zone(zone_id: String) -> Dictionary:
	if not _zone_cache.has(zone_id):
		_zone_cache[zone_id] = load_json(DATA_DIR + "zones/%s.json" % zone_id)
	return _zone_cache[zone_id]


func zone_ids() -> Array[String]:
	var ids: Array[String] = []
	for file: String in DirAccess.get_files_at(DATA_DIR + "zones"):
		if file.ends_with(".json"):
			ids.append(file.get_basename())
	return ids


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Data file missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("Data file is not a JSON object: %s" % path)
	return {}
