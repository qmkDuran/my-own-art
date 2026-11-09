class_name CrewEncounter
extends Node
## A zone's mini-event: a crew of enemies at work on something (e.g. Wardens cutting a frozen
## Glimra out of the ice). Once every crew member is down, the encounter is won: the boss
## banner announces "<CREW NAME> DEFEATED", a story flag keeps it won, and after a moment the
## Barricade they guarded opens (the ice cracks, a pocket opens up). Creatures the crew
## summoned keep fighting, but don't hold the win back.
## Won once, it stays won: a later visit finds the crew gone and the barricade open.

## Seconds between checks for crew members still standing.
const CHECK_SECONDS := 0.25

@export var crew: Array[Node2D] = []
## Set when the crew falls (StoryFlags); while it's set the crew is gone and the way is open.
@export var won_flag: String = ""
## The name in the banner, e.g. "Ice Cutters" ("" = no banner).
@export var crew_name: String = ""
@export var barricade: Barricade
## Real seconds after the last crew member falls before the barricade opens.
@export var open_delay: float = 1.2

var _check_left: float = CHECK_SECONDS
var _is_won: bool = false


func _ready() -> void:
	if won_flag != "" and StoryFlags.has(won_flag):
		_is_won = true
		for member in crew:
			if is_instance_valid(member):
				member.queue_free()
		if barricade != null:
			barricade.open(true)


func _process(delta: float) -> void:
	if _is_won:
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_SECONDS
	if _is_crew_down():
		_win()


func _is_crew_down() -> bool:
	for member in crew:
		if is_instance_valid(member) and member.is_in_group(EnemyReactions.ENEMIES_GROUP):
			return false
	return true


func _win() -> void:
	_is_won = true
	StoryFlags.set_flag(won_flag)
	if crew_name != "":
		BossHealthBar.announce_defeat(self, crew_name)
	await get_tree().create_timer(open_delay).timeout
	if barricade != null:
		barricade.open()
