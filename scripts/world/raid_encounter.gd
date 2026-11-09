class_name RaidEncounter
extends Node
## The arrival fight at the Hometown Outskirts: a Warden and his Toxlops raid the edge of
## town just as Emberoo lands. Once every raider (and everything they summoned) is down, a
## townsperson finds their voice ("You... you have a FREE Glimra?!") and the barricade into
## town opens. Won once, it stays won (StoryFlags): coming back finds the road open and quiet.

## Seconds between checks for raiders still standing.
const CHECK_SECONDS := 0.25

@export var raiders: Array[Node2D] = []
@export var won_flag: String = StoryFlags.ARRIVAL_RAID_WON
@export var barricade: Barricade
@export var townsperson: Npc
@export_multiline var victory_line: String = "You... you have a FREE Glimra?!"
## Real seconds after the last raider falls before the line, and after the line before the barricade opens.
@export var line_delay: float = 0.8
@export var open_delay: float = 1.6

var _check_left: float = CHECK_SECONDS
var _is_won: bool = false


func _ready() -> void:
	if StoryFlags.has(won_flag):
		_is_won = true
		for raider in raiders:
			if is_instance_valid(raider):
				raider.queue_free()
		if barricade != null:
			barricade.open(true)


func _process(delta: float) -> void:
	if _is_won:
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_SECONDS
	if _is_raid_over():
		_win()


func _is_raid_over() -> bool:
	for raider in raiders:
		if is_instance_valid(raider) and raider.is_in_group(EnemyReactions.ENEMIES_GROUP):
			return false
	return get_tree().get_nodes_in_group(EnemyReactions.SUMMONED_GROUP).is_empty()


func _win() -> void:
	_is_won = true
	StoryFlags.set_flag(won_flag)
	await get_tree().create_timer(line_delay).timeout
	if townsperson != null:
		townsperson.say(victory_line, open_delay + 1.5)
	await get_tree().create_timer(open_delay).timeout
	if barricade != null:
		barricade.open()
