class_name MoveLibrary
## The move library (data/moves.json) and each species' learnset and default loadout (data/creatures.json). A level
## (Baby or Grown) limits which moves a creature can equip: a move's min_level must not exceed it.

const SLOTS: int = 4


static func spec(move_id: String) -> Dictionary:
	return Tuning.moves["moves"][move_id]


static func level_value(level: String) -> int:
	return int(Tuning.moves["levels"][level])


static func allowed(move_id: String, level: String) -> bool:
	return int(spec(move_id)["min_level"]) <= level_value(level)


## The moves a species can equip at a level, in learnset order.
static func learnable(species: String, level: String) -> Array[String]:
	var out: Array[String] = []
	for move_id: String in Tuning.creatures[species]["learnset"]:
		if allowed(move_id, level):
			out.append(move_id)
	return out


## The species' default four, with any move above the level swapped for the first allowed one of the same category.
static func default_loadout(species: String, level: String) -> Array[String]:
	var loadout: Array[String] = []
	for move_id: String in Tuning.creatures[species]["loadout"]:
		loadout.append(move_id if allowed(move_id, level) else _stand_in(species, level, move_id, loadout))
	return loadout


static func _stand_in(species: String, level: String, move_id: String, taken: Array[String]) -> String:
	for other: String in learnable(species, level):
		if spec(other)["category"] == spec(move_id)["category"] and not taken.has(other):
			return other
	return learnable(species, level)[0]
