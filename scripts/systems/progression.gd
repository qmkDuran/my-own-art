extends Node
## The player's level, XP and skill points (registered as the "Progression" autoload).
##
## Light motes add XP. Each level-up gives a small automatic stat boost (handled by
## whoever listens to `leveled_up`, e.g. the creature) and 1 skill point for the Ember Tree.
## The player starts with STARTING_SKILL_POINTS, so the first skill is picked right away.
## Kept in an autoload so it survives the level restarting.

signal xp_changed(xp: int, xp_to_next: int)
signal leveled_up(new_level: int)
signal skill_points_changed(points: int)

## XP needed for level 2; later levels need more (see xp_to_next).
const BASE_XP := 10
## How steeply the XP needed grows per level.
const GROWTH := 1.45
const MAX_LEVEL := 30
## Points to spend at level 1: one, for a tier-0 "build starter" (Searing Jab, Spinning Hook
## or Ash Guard). See DESIGN.md, "Build system".
const STARTING_SKILL_POINTS := 1

var level: int = 1
var xp: int = 0
var skill_points: int = STARTING_SKILL_POINTS


## XP needed to go from the current level to the next.
func xp_to_next() -> int:
	return int(round(BASE_XP * pow(level, GROWTH)))


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
	add_skill_points(1)


## Gives extra points outside levelling (e.g. DebugControls' F3).
func add_skill_points(amount: int) -> void:
	skill_points += amount
	skill_points_changed.emit(skill_points)
