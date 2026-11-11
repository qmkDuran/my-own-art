extends Node
## The content database: reads every data/*.json once (creatures, moves, elements, items, dialogue, trainers,
## restoration stages, palette, maps) and answers lookups. Content lives in data, never in code.

const DATA_DIR: String = "res://data/"
const MAP_DIR: String = "res://data/maps/"

var species: Dictionary = {}
var moves: Dictionary = {}
var items: Dictionary = {}
var elements: Dictionary = {}
var dialogue: Dictionary = {}
var trainers: Dictionary = {}
var restoration: Dictionary = {}
var palette: Dictionary = {}
var legend: Dictionary = {}
var people: Dictionary = {}
var statuses: Dictionary = {}
var _maps: Dictionary = {}


func _ready() -> void:
	species = read_json("creatures.json")
	moves = read_json("moves.json")
	items = read_json("items.json")
	elements = read_json("elements.json")
	dialogue = read_json("dialogue.json")
	trainers = read_json("trainers.json")
	restoration = read_json("restoration.json")
	palette = read_json("palette.json")
	legend = read_json("legend.json")
	people = read_json("people.json")
	statuses = read_json("statuses.json")


func read_json(rel: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(DATA_DIR + rel)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "bad json: " + rel)
	return parsed as Dictionary


func color(name: String) -> Color:
	return Color(String(palette.get(name, "#ff00ff")))


func map_data(id: String) -> Dictionary:
	if not _maps.has(id):
		_maps[id] = read_json("maps/%s.json" % id)
	return _maps[id]


func map_ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for f: String in DirAccess.get_files_at(MAP_DIR):
		if f.ends_with(".json"):
			out.append(f.get_basename())
	return out


func move(id: String) -> Dictionary:
	return moves[id]


func item(id: String) -> Dictionary:
	return items[id]


func element_name(id: String) -> String:
	return String(elements["names"][id])


func element_color(id: String) -> Color:
	return color(String(elements["colours"][id]))


## Damage multiplier of an attacking element against a defending one (x1.5 strong, x0.67 weak, else 1).
func element_mult(attack: String, defend: String) -> float:
	if Array(elements["strong"][attack]).has(defend):
		return float(elements["strong_mult"])
	if Array(elements["strong"][defend]).has(attack):
		return float(elements["weak_mult"])
	return 1.0


## The lines of a dialogue entry; the first `when` branch whose flag is set wins.
func lines(id: String, flags: Dictionary) -> PackedStringArray:
	var entry: Dictionary = dialogue.get(id, {"lines": ["..."]})
	for branch: Dictionary in entry.get("when", []):
		if flags.get(String(branch["flag"]), false):
			return PackedStringArray(branch["lines"])
	return PackedStringArray(entry["lines"])
