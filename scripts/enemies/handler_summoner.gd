class_name HandlerSummoner
extends Node
## A Handler's summoning: when a new wave is due, how many bound creatures appear and where,
## and keeping count of the ones still alive. The Handler decides when to raise his rod;
## this says whether it's time and spawns the wave at the end of the gesture.
##
## Two caps keep long fights from snowballing: each Warden has at most `max_creatures` of his
## own out, and the whole zone at most ZONE_LIMIT summoned creatures, from every Warden together.

## Most summoned creatures alive in the zone at once.
const ZONE_LIMIT := 24

## The creature he summons.
@export var creature_scene: PackedScene
## Seconds between summons.
@export var summon_interval: float = 7.0
## He only summons again once this many of his creatures (or fewer) are left alive,
## so the player can clear most of a wave first.
@export var summon_when_alive_at_most: int = 1
## Seconds the summon gesture takes; creatures appear at the end (the summon animation's length).
@export var summon_duration: float = 0.6
## Creatures per summon.
@export var creatures_per_summon: int = 4
## Most of his creatures allowed alive at once.
@export var max_creatures: int = 5
## How far from him new creatures appear, in pixels (min, max).
@export var summon_radius: Vector2 = Vector2(14, 36)

var _seconds_until_summon: float = 0.0
## Untyped on purpose: it can briefly hold creatures that have already been freed.
var _summoned_creatures: Array = []
## Name, element and portrait of the creature he summons (read from the creature scene).
var _creature_info: Dictionary = {}
var _has_called_out: bool = false

@onready var handler: Node2D = get_parent()


func _ready() -> void:
	_read_creature_info()


## Sets how long until the next summon is due, e.g. the first one of the fight.
func wait_before_next_summon(seconds: float) -> void:
	_seconds_until_summon = seconds


## A fresh fight (e.g. after the player fell): the next summon waits `seconds` and comes with a shout again.
func start_over(seconds: float) -> void:
	wait_before_next_summon(seconds)
	_has_called_out = false


func count_down(delta: float) -> void:
	_seconds_until_summon -= delta


## Due, few enough of his creatures left, and room in the zone for more.
func is_time_to_summon() -> bool:
	if _seconds_until_summon > 0.0 or _creatures_alive() > summon_when_alive_at_most:
		return false
	return _room_left_in_zone() > 0


## His shout for the first summon of the fight, e.g. "Go, Toxlop!"; "" after that.
func battle_cry() -> String:
	if _has_called_out or _creature_info.is_empty():
		return ""
	_has_called_out = true
	return "Go, %s!" % _creature_info["name"]


## The gesture is done: the wave appears around him and the next summon starts counting down.
func finish_summon() -> void:
	_spawn_creatures()
	_seconds_until_summon = summon_interval


func _spawn_creatures() -> void:
	if creature_scene == null:
		return
	var room_left := mini(max_creatures - _creatures_alive(), _room_left_in_zone())
	for creature_number in mini(creatures_per_summon, room_left):
		var creature: Node2D = creature_scene.instantiate()
		creature.add_to_group(EnemyReactions.SUMMONED_GROUP)
		handler.get_parent().add_child(creature)
		creature.global_position = handler.global_position + _random_spot_nearby()
		# Summoned creatures come out already hunting the player.
		if creature.has_method("notice_player"):
			creature.notice_player()
		_summoned_creatures.append(creature)
	# The first time the player ever sees this species, the HUD announces it.
	if not _creature_info.is_empty():
		CreatureLog.discover(_creature_info)


func _random_spot_nearby() -> Vector2:
	var angle := randf() * TAU
	var distance := randf_range(summon_radius.x, summon_radius.y)
	return Vector2.from_angle(angle) * distance


## Counts summoned creatures that are still alive (dead ones are removed from the list).
func _creatures_alive() -> int:
	var still_alive: Array = []
	for creature in _summoned_creatures:
		if is_instance_valid(creature) and creature.is_in_group(EnemyReactions.ENEMIES_GROUP):
			still_alive.append(creature)
	_summoned_creatures = still_alive
	return _summoned_creatures.size()


func _room_left_in_zone() -> int:
	return ZONE_LIMIT - get_tree().get_node_count_in_group(EnemyReactions.SUMMONED_GROUP)


func _read_creature_info() -> void:
	if creature_scene == null:
		return
	var probe := creature_scene.instantiate()
	if probe.has_method("creature_info"):
		_creature_info = probe.creature_info()
	probe.free()
