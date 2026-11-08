extends Node
## The player's level, XP and skill points (registered as the "Progression" autoload).
##
## Light motes add XP. Each level-up gives a small automatic stat boost (handled by
## whoever listens to `leveled_up`, e.g. the creature) and 1 skill point for the Ember Tree.
## The player starts at level 0 with no points: the first pack of toads brings level 1 and
## the first point, spent on a tier-0 "build starter" (see DESIGN.md, "Build system").
## Kept in an autoload so it survives the level restarting.

signal xp_changed(xp: int, xp_to_next: int)
signal leveled_up(new_level: int)
signal skill_points_changed(points: int)

## The XP curve: going from level L to L + 1 costs round(BASE_XP * (L + 1) ^ GROWTH).
##
## Ruins Edge (the first zone, ~4-5 min) holds about 380 XP for a player who kills most
## enemies: 30 placed toads (3 XP each, 90), 7 Wardens (16 each, 112), ~42 toads the
## Wardens summon (~6 each, 126) and ~50 from the new Zephoots and Gruntites. Its first
## pack (3 toads in Mossy Steps) gives 9 XP, so level 1 (8 XP) comes in the first minute.
##
##   Level:      1   2   3    4    5    6    7    8     9    10    11    12    13    14    15
##   Step XP:    8  24  46   74  105  141  180  223   269   318   371   426   485   546   609
##   Total XP:   8  32  78  152  257  398  578  801  1070  1388  1759  2185  2670  3216  3825
##   Level 30: 22,244 total (1,847 for that step).  Level 50: 82,539 total (4,183 for that step).
##
## So: level 1 after the first pack, then about one level a minute in Ruins Edge (level 4
## after Conduit Hall, level 5 in the Final Arena), each a little slower. Act 1 at a similar
## XP rate (~30 min of fighting, ~2,300 XP) ends around level 11-12. Later acts reach
## level ~45-50 by the end only if enemy XP grows about x1.6-1.7 per act (e.g. scaled
## with the zone's level), so each level keeps taking a similar number of kills.
const BASE_XP := 8
const GROWTH := 1.6
const MAX_LEVEL := 50

var level: int = 0
var xp: int = 0
var skill_points: int = 0
## Points given outside levelling (DebugControls' F3), kept so a loaded save can work out
## every point the player owns: one per level plus these.
var bonus_skill_points: int = 0


## XP needed to go from the current level to the next.
func xp_to_next() -> int:
	return roundi(BASE_XP * pow(level + 1, GROWTH))


func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	xp += amount
	while level < MAX_LEVEL and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		skill_points += 1
		leveled_up.emit(level)
		skill_points_changed.emit(skill_points)
	xp_changed.emit(xp, xp_to_next())


## Spends a skill point (e.g. igniting a node in the Ember Tree). Returns false if none left.
func spend_skill_point() -> bool:
	if skill_points <= 0:
		return false
	skill_points -= 1
	skill_points_changed.emit(skill_points)
	return true


## Gives a point back (free respec).
func refund_skill_point() -> void:
	skill_points += 1
	skill_points_changed.emit(skill_points)


## Gives extra points outside levelling (e.g. DebugControls' F3).
func add_skill_points(amount: int) -> void:
	bonus_skill_points += amount
	skill_points += amount
	skill_points_changed.emit(skill_points)


## Every skill point the player owns, spent or not.
func earned_skill_points() -> int:
	return level + bonus_skill_points


## What SaveGame writes. Spent points aren't stored: they follow from the learned nodes.
func to_save_data() -> Dictionary:
	return {"level": level, "xp": xp, "bonus_skill_points": bonus_skill_points}


## Restores a save (an empty one means a fresh start). Every point comes back unspent;
## EmberTree's load_save_data spends them again on the learned nodes, so load this first.
func load_save_data(data: Dictionary) -> void:
	level = SaveData.read_int(data, "level", 0, 0, MAX_LEVEL)
	xp = SaveData.read_int(data, "xp", 0, 0, maxi(0, xp_to_next() - 1))
	bonus_skill_points = SaveData.read_int(data, "bonus_skill_points", 0, 0, SaveData.NO_LIMIT)
	skill_points = earned_skill_points()
	xp_changed.emit(xp, xp_to_next())
	skill_points_changed.emit(skill_points)
