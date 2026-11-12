class_name TamerData
extends RefCounted
## The trainer prototype's content, loaded once from res://data/tamer/*.json: elements and their matchups, species,
## moves, the rules (tamer.json) and the creature sprite layouts. Nothing about creatures lives in code.

const DIR: String = "res://data/tamer/"

static var elements: Dictionary = {}
static var species_all: Dictionary = {}
static var moves: Dictionary = {}
static var rules: Dictionary = {}
static var sprites: Dictionary = {}
static var effects: Dictionary = {}
static var arenas: Dictionary = {}
static var styles: Dictionary = {}
static var pieces: Dictionary = {}


static func ensure() -> void:
	if not rules.is_empty():
		return
	GameData.ensure()
	elements = GameData.load_json("tamer/elements")
	species_all = GameData.load_json("tamer/species")
	moves = GameData.load_json("tamer/moves")["moves"]
	rules = GameData.load_json("tamer/tamer")
	sprites = GameData.load_json("tamer/creature_sprites")
	effects = GameData.load_json("tamer/effects")
	styles = GameData.load_json("tamer/styles")
	pieces = GameData.load_json("tamer/pieces")
	arenas = GameData.load_json("tamer/arenas")


static func species(id: String) -> Dictionary:
	return species_all["species"][id]


static func move(id: String) -> Dictionary:
	return moves[id]


static func element(id: String) -> Dictionary:
	return elements["elements"][id]


## A palette colour of an element: "core" (bright), "light" or "dark".
static func color(element_id: String, which: String = "core", alpha: float = 1.0) -> Color:
	return Pal.c(String(element(element_id)[which]), alpha)


## Light, mid and fading colours for an element's sparks.
static func sparks(element_id: String) -> Array[Color]:
	return [color(element_id, "light"), color(element_id, "core"), color(element_id, "dark", 0.0)]


## Does an attack of this element have the advantage over the target's element? (There are no weaknesses: the
## other way round is simply neutral.)
static func advantage(attack: String, target: String) -> bool:
	return target != "" and (element(attack)["strong"] as Array).has(target)


static func element_mult(attack: String, target: String) -> float:
	return float(elements["advantage_mult"]) if advantage(attack, target) else 1.0


static func rule(path: String) -> Variant:
	var at: Variant = rules
	for key: String in path.split("."):
		at = (at as Dictionary)[key]
	return at
