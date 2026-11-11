class_name TamerData
extends RefCounted
## The trainer prototype's content, loaded once from res://data/tamer/*.json: elements and their matchups, species,
## moves, the rules (tamer.json) and the creature sprite layouts. Nothing about creatures lives in code.

const DIR: String = "res://data/tamer/"
const SUPER: int = 1
const NEUTRAL: int = 0
const RESISTED: int = -1

static var elements: Dictionary = {}
static var species_all: Dictionary = {}
static var moves: Dictionary = {}
static var rules: Dictionary = {}
static var sprites: Dictionary = {}


static func ensure() -> void:
	if not rules.is_empty():
		return
	GameData.ensure()
	elements = GameData.load_json("tamer/elements")
	species_all = GameData.load_json("tamer/species")
	moves = GameData.load_json("tamer/moves")["moves"]
	rules = GameData.load_json("tamer/tamer")
	sprites = GameData.load_json("tamer/creature_sprites")


static func species(id: String) -> Dictionary:
	return species_all["species"][id]


static func starters() -> Array:
	return species_all["starters"]


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


## SUPER when the attack's element is strong against the target's, RESISTED when the target's element beats it.
static func matchup(attack: String, target: String) -> int:
	var e: Dictionary = element(attack)
	if (e["strong"] as Array).has(target):
		return SUPER
	if (e["weak"] as Array).has(target):
		return RESISTED
	return NEUTRAL


static func element_mult(attack: String, target: String) -> float:
	match matchup(attack, target):
		SUPER:
			return float(elements["super_mult"])
		RESISTED:
			return float(elements["resist_mult"])
	return 1.0


static func rule(path: String) -> Variant:
	var at: Variant = rules
	for key: String in path.split("."):
		at = (at as Dictionary)[key]
	return at
