class_name GameState
extends Node
## The running game (autoload `Game`): your party, bag, journal, coins, story flags, where you stand, and the
## world's heal stage. Systems read and change state through here; it announces changes with signals.

signal heal_stage_changed(stage: int)

const MAX_PARTY: int = 6
const START_COINS: int = 150
const START_LEVEL: int = 5
const START_BAG: Dictionary = {"sunberry": 3, "smoky_nut": 2, "sweet_kelp": 2, "mending_salve": 3}
const START_MAP: String = "fernhollow"
const START_CELL: Vector2i = Vector2i(13, 8)

var party: Array[Creature] = []
var bag: Bag = Bag.new()
var journal: Journal = Journal.new()
var flags: Dictionary = {}
var coins: int = START_COINS
## Wildkin that chose to join you (the starter is not counted): drives the healing of the Vale.
var wild_friends: int = 0
var map_id: String = START_MAP
var cell: Vector2i = START_CELL
var facing: Vector2i = Vector2i.DOWN
var heal_stage: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Tests and screenshot runs set this: messages skip their typing and waits shrink to a frame.
var fast: bool = false


func new_game() -> void:
	party.clear()
	bag = Bag.new()
	for id: String in START_BAG:
		bag.add(id, int(START_BAG[id]))
	journal = Journal.new()
	flags = {}
	coins = START_COINS
	wild_friends = 0
	map_id = START_MAP
	cell = START_CELL
	facing = Vector2i.DOWN
	heal_stage = 0


func choose_starter(id: String) -> void:
	var c := Creature.create(id, START_LEVEL)
	c.bond = Bond.GAINS["befriended"]
	party.append(c)
	journal.befriend(id)
	flags["has_starter"] = true


func lead() -> Creature:
	for c: Creature in party:
		if not c.is_fainted():
			return c
	return party[0] if not party.is_empty() else null


func able_count() -> int:
	return party.filter(func(c: Creature) -> bool: return not c.is_fainted()).size()


## A wild creature chose to join: it enters the party (if there is room) and the journal.
func befriend(c: Creature) -> void:
	journal.befriend(c.species_id)
	wild_friends += 1
	Bond.gain(c, "befriended")
	if party.size() < MAX_PARTY:
		party.append(c)
	refresh_heal_stage()


func set_flag(name: String) -> void:
	flags[name] = true
	refresh_heal_stage()


func heal_party() -> void:
	for c: Creature in party:
		c.heal_full()


## Re-derives the heal stage; announces it when it grows.
func refresh_heal_stage() -> void:
	var stage: int = Restoration.stage_for(wild_friends, flags)
	if stage > heal_stage:
		heal_stage = stage
		for s: int in range(1, stage + 1):
			flags["stage_%d" % s] = true
		heal_stage_changed.emit(stage)


func wait(seconds: float) -> void:
	await get_tree().create_timer(0.01 if fast else seconds).timeout
