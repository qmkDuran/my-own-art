class_name Bond
extends RefCounted
## Bond: how close a creature is to you. It grows from what you do together (battles, good timing, treats it
## likes, walking side by side) and unlocks its bond form.

const MAX_BOND: int = 100
const GAINS: Dictionary = {"battle": 6, "perfect": 2, "good": 1, "liked_treat": 10, "treat": 4, "walk": 1,
	"befriended": 20}
const STEPS_PER_WALK_POINT: int = 32


static func gain(c: Creature, reason: String) -> void:
	c.bond = mini(MAX_BOND, c.bond + int(GAINS[reason]))


## Counts a step taken while leading the party; every few steps adds a point of Bond.
static func walk_step(c: Creature) -> void:
	c.steps += 1
	if c.steps % STEPS_PER_WALK_POINT == 0:
		gain(c, "walk")


static func evolution_target(c: Creature) -> String:
	var evo: Dictionary = c.data().get("evolves", {})
	if evo.is_empty() or c.is_fainted():
		return ""
	if c.bond >= int(evo["bond"]) and c.level >= int(evo["level"]):
		return String(evo["into"])
	return ""


## Turns the creature into its bond form, keeping level, Bond and the share of HP it had.
static func evolve(c: Creature, into: String) -> void:
	var ratio: float = float(c.hp) / c.max_hp()
	c.species_id = into
	for m: String in Growth.moves_at(into, c.level):
		if not c.moves.has(m):
			c.moves.append(m)
	c.hp = maxi(1, int(round(c.max_hp() * ratio)))


static func label(value: int) -> String:
	if value >= 80:
		return "Inseparable"
	if value >= 60:
		return "Close friends"
	if value >= 30:
		return "Friendly"
	return "Getting to know you"
