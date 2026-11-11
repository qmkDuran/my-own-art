class_name Creature
extends RefCounted
## One creature you (or a trainer, or the wild) have: species, level, experience, current HP, known moves and
## the Bond it has built with you. Stats come from the species' bases through Stats.

var species_id: String = ""
var level: int = 1
var xp: int = 0
var hp: int = 1
var moves: PackedStringArray = []
var bond: int = 0
var steps: int = 0


static func create(id: String, lvl: int) -> Creature:
	var c := Creature.new()
	c.species_id = id
	c.level = lvl
	c.moves = Growth.moves_at(id, lvl)
	c.hp = c.max_hp()
	return c


func data() -> Dictionary:
	return Db.species[species_id]


func display_name() -> String:
	return String(data()["name"])


func element() -> String:
	return String(data()["element"])


func max_hp() -> int:
	return Stats.hp(int(data()["base"]["hp"]), level)


func stat(key: String) -> int:
	return Stats.other(int(data()["base"][key]), level)


func is_fainted() -> bool:
	return hp <= 0


func heal_full() -> void:
	hp = max_hp()


func heal(amount: int) -> int:
	var before: int = hp
	hp = mini(max_hp(), hp + amount)
	return hp - before


func take(amount: int) -> void:
	hp = maxi(0, hp - amount)


func to_dict() -> Dictionary:
	return {"species": species_id, "level": level, "xp": xp, "hp": hp, "moves": Array(moves), "bond": bond,
		"steps": steps}


static func from_dict(d: Dictionary) -> Creature:
	var c := Creature.new()
	c.species_id = String(d["species"])
	c.level = int(d["level"])
	c.xp = int(d["xp"])
	c.hp = int(d["hp"])
	c.moves = PackedStringArray(d["moves"])
	c.bond = int(d["bond"])
	c.steps = int(d.get("steps", 0))
	return c
