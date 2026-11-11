class_name Growth
extends RefCounted
## Levels and experience: the XP curve, XP rewards, levelling up and the moves a species knows at a level.

const XP_BASE: int = 20
const XP_PER_LEVEL: int = 12
const MAX_LEVEL: int = 30
const TRAINER_BONUS: float = 1.5
const BEFRIEND_SHARE: float = 0.75
const LEVEL_DIVISOR: float = 5.0


static func xp_to_next(level: int) -> int:
	return XP_BASE + level * XP_PER_LEVEL


static func reward(foe: Creature, trainer: bool) -> int:
	var base: float = float(foe.data()["xp"]) * foe.level / LEVEL_DIVISOR
	return int(base * (TRAINER_BONUS if trainer else 1.0))


static func befriend_reward(foe: Creature) -> int:
	return int(reward(foe, false) * BEFRIEND_SHARE)


static func moves_at(id: String, level: int) -> PackedStringArray:
	var out: PackedStringArray = []
	for entry: Array in Db.species[id]["learnset"]:
		if int(entry[0]) <= level:
			out.append(String(entry[1]))
	return out


## Adds XP; returns one message per level gained and per move learned.
static func add_xp(c: Creature, amount: int) -> PackedStringArray:
	var notes: PackedStringArray = []
	c.xp += amount
	while c.level < MAX_LEVEL and c.xp >= xp_to_next(c.level):
		c.xp -= xp_to_next(c.level)
		var old_max: int = c.max_hp()
		c.level += 1
		c.hp += c.max_hp() - old_max
		notes.append("%s grew to level %d!" % [c.display_name(), c.level])
		for m: String in moves_at(c.species_id, c.level):
			if not c.moves.has(m):
				c.moves.append(m)
				notes.append("%s learned %s!" % [c.display_name(), Db.move(m)["name"]])
	return notes
