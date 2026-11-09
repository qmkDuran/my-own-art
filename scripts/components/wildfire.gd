class_name Wildfire
extends Node
## Wildfire (Ember Tree, Inferno; a Flame Uppercut upgrade): an enemy that dies while
## burning passes its burn, at full length, to the nearest living enemy within `radius`
## pixels. An ember streak shows the jump. Chains on if that one dies burning too.
##
## Burning tells every node in its spread group when a burning target dies, so this node
## only decides where the fire goes. Its numbers fill the Wildfire facts in the tree.

## The Wildfire node's id (Ember Tree, Inferno).
const WILDFIRE_ID := "wildfire"

## How far the fire can jump, from the dead enemy's feet to the next one's, in pixels.
@export var radius: float = 48.0
## Group whose members can catch the fire (each needs a child node named "Health").
@export var target_group: String = "enemies"
## Height of the streak above the feet, roughly the body's middle (negative is up).
@export var streak_height: float = -6.0


func _ready() -> void:
	add_to_group(Burning.SPREAD_GROUP)


func is_learned() -> bool:
	return EmberTree.is_learned(WILDFIRE_ID)


## Called by Burning (through its spread group) when `dead_target` dies burning.
func on_burning_target_died(dead_target: Node, damage_per_second: int, duration: float) -> void:
	if not is_learned() or not (dead_target is Node2D):
		return
	var from := (dead_target as Node2D).global_position
	var next_target := _nearest_living_target(from, dead_target)
	if next_target == null:
		return
	Burning.apply_to(Health.of(next_target), damage_per_second, duration)
	_spawn_streak(dead_target.get_parent(), from, next_target.global_position)


func _nearest_living_target(from: Vector2, dead_target: Node) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := radius
	for target: Node2D in get_tree().get_nodes_in_group(target_group):
		if target == dead_target:
			continue
		var target_health := Health.of(target)
		if target_health == null or target_health.is_dead():
			continue
		var distance := from.distance_to(target.global_position)
		if distance <= nearest_distance:
			nearest = target
			nearest_distance = distance
	return nearest


func _spawn_streak(world: Node, from: Vector2, to: Vector2) -> void:
	if world == null:
		return
	var streak := EmberStreak.new()
	world.add_child(streak)
	var lift := Vector2(0, streak_height)
	streak.play(from + lift, to + lift)
