class_name RaidEncounter
extends Encounter
## The arrival fight at the Hometown Outskirts (see Encounter): a Warden and his Toxlops raid
## the edge of town just as Emberoo lands. Once every raider and everything they summoned is
## down, a townsperson finds their voice ("You... you have a FREE Glimra?!") and the
## barricade into town opens.

## Seconds the townsperson's line stays up after the barricade starts to open.
const LINE_LINGER_SECONDS := 1.5

@export var raiders: Array[Node2D] = []
@export var townsperson: Npc
@export_multiline var victory_line: String = "You... you have a FREE Glimra?!"
## Real seconds after the last raider falls before the line.
@export var line_delay: float = 0.8


func _init() -> void:
	won_flag = StoryFlags.ARRIVAL_RAID_WON
	open_delay = 1.6


func _fighters() -> Array[Node2D]:
	return raiders


## The raiders' summons count too.
func _is_over() -> bool:
	return super._is_over() and get_tree().get_nodes_in_group(EnemyReactions.SUMMONED_GROUP).is_empty()


func _celebrate() -> void:
	await Wait.seconds(self, line_delay)
	if townsperson != null:
		townsperson.say(victory_line, open_delay + LINE_LINGER_SECONDS)
