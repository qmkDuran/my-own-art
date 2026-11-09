class_name EnemyPassThrough
extends RefCounted
## Lets a creature move through enemies for a moment (swimming underground, rolling through
## a pack), then puts collisions back exactly as they were.

var _body: PhysicsBody2D
var _ignored: Array[PhysicsBody2D] = []


func start(body: PhysicsBody2D) -> void:
	stop()
	_body = body
	for enemy in body.get_tree().get_nodes_in_group(AbilityTargets.ENEMIES_GROUP):
		if enemy is PhysicsBody2D:
			body.add_collision_exception_with(enemy)
			_ignored.append(enemy as PhysicsBody2D)


func stop() -> void:
	for enemy in _ignored:
		if is_instance_valid(enemy) and is_instance_valid(_body):
			_body.remove_collision_exception_with(enemy)
	_ignored.clear()
