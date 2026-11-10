class_name GameData
extends RefCounted
## All game content, loaded once from res://data/*.json (Scripture placeholders resolved by SceneData).

static var enemies: Dictionary = {}
static var skills: Dictionary = {}
static var items: Dictionary = {}
static var hosts: Dictionary = {}
static var zone: Dictionary = {}


static func ensure() -> void:
	if not zone.is_empty():
		return
	enemies = SceneData.load_json("res://data/enemies.json")
	skills = SceneData.load_json("res://data/skills.json")
	items = SceneData.load_json("res://data/items.json")
	hosts = SceneData.load_json("res://data/hosts.json")
	zone = SceneData.load_json("res://data/zone.json")


static func skill(id: String) -> Dictionary:
	return skills["skills"][id]


static func rarity_color(rarity: String) -> Color:
	return Color(String(items["rarities"][rarity]["color"]))
