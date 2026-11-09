@abstract
class_name Encounter
extends Node
## A fight the world remembers (the arrival raid, a zone's crew mini-event): once everyone in
## it is down, it is won: a story flag keeps it won, the encounter celebrates in its own way
## (`_celebrate`) and after a moment the Barricade it guarded opens. Won once, it stays won:
## a later visit finds the fighters gone and the barricade open.
##
## Whether the fight is over is checked a few times a second (fighters can also be summoned
## mid-fight, so there's no single signal to wait for).

## Seconds between checks for fighters still standing.
const CHECK_SECONDS := 0.25

## Set when the encounter is won (StoryFlags); while it's set the fighters are gone.
@export var won_flag: String = ""
@export var barricade: Barricade
## Real seconds after the celebration before the barricade opens.
@export var open_delay: float = 1.2

var _check_left: float = CHECK_SECONDS
var _is_won: bool = false


func _ready() -> void:
	if won_flag == "" or not StoryFlags.has(won_flag):
		return
	_is_won = true
	for fighter in _fighters():
		if is_instance_valid(fighter):
			fighter.queue_free()
	if barricade != null:
		barricade.open(true)


func _process(delta: float) -> void:
	if _is_won:
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_SECONDS
	if _is_over():
		_win()


## The enemies placed in the zone for this encounter.
@abstract func _fighters() -> Array[Node2D]


## The encounter's own moment when it's won (a line, a banner), before the barricade's delay.
@abstract func _celebrate() -> void


## True once none of the fighters can still fight.
func _is_over() -> bool:
	for fighter in _fighters():
		if is_instance_valid(fighter) and fighter.is_in_group(EnemyReactions.ENEMIES_GROUP):
			return false
	return true


func _win() -> void:
	_is_won = true
	StoryFlags.set_flag(won_flag)
	@warning_ignore("redundant_await")  # some celebrations take their time
	await _celebrate()
	await Wait.seconds(self, open_delay)
	if barricade != null:
		barricade.open()
