class_name GameData
extends RefCounted
## All game content, loaded once from res://data/*.json. Nothing about content lives in code: names, numbers,
## trees, items, enemies, biome rules and words are data.

const DIR: String = "res://data/"

static var settings: Dictionary = {}
static var light: Dictionary = {}
static var player: Dictionary = {}
static var stats: Dictionary = {}
static var skills: Dictionary = {}
static var passives: Dictionary = {}
static var items: Dictionary = {}
static var enemies: Dictionary = {}
static var biome: Dictionary = {}
static var story: Dictionary = {}
static var props: Dictionary = {}
static var sprites: Dictionary = {}
static var zones: Dictionary = {}
static var quests: Dictionary = {}
static var dialogue: Dictionary = {}
static var crafting: Dictionary = {}
static var zone_id: String = ""         ## the zone being played (biome holds its rules)


static func ensure() -> void:
	if not light.is_empty():
		return
	settings = load_json("settings")
	light = load_json("light")
	player = load_json("player")
	stats = load_json("stats")
	skills = load_json("skills")
	passives = load_json("passives")
	items = load_json("items")
	enemies = load_json("enemies")
	zones = load_json("zones")
	quests = load_json("quests")
	dialogue = load_json("dialogue")
	crafting = load_json("crafting")
	use_zone(String(zones["start"]))
	story = load_json("story")
	props = load_json("props")
	sprites = load_json("sprites")


static func load_json(name: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(DIR + name + ".json")
	var d: Variant = JSON.parse_string(text)
	assert(d is Dictionary, "bad json: " + name)
	return d


## Makes `id` the current zone: its biome rules become GameData.biome.
static func use_zone(id: String) -> void:
	zone_id = id
	biome = load_json("biomes/" + String(zone(id)["biome"]))


static func zone(id: String) -> Dictionary:
	return zones["zones"][id]


static func skill(id: String) -> Dictionary:
	return skills[id]


static func enemy(kind: String) -> Dictionary:
	return enemies["kinds"][kind]


static func rarity_color(rarity: String) -> Color:
	return Color(String(items["rarity_colors"][rarity]))


static func stat_name(key: String) -> String:
	return String(stats.get(key, {}).get("name", key))


## "+12% Increased Sunfire Damage" / "+30 Maximum Life" / "-20% Increased Light Radius".
static func stat_line(key: String, value: float) -> String:
	var pct: bool = String(stats.get(key, {}).get("fmt", "flat")) == "pct"
	var num: String = fmt_num(absf(value))
	return "%s%s%s %s" % ["-" if value < 0.0 else "+", num, "%" if pct else "", stat_name(key)]


static func fmt_num(v: float) -> String:
	return str(int(roundf(v))) if absf(v - roundf(v)) < 0.05 else "%.1f" % v


static func setting(key: String, fallback: Variant) -> Variant:
	return settings.get(key, fallback)
