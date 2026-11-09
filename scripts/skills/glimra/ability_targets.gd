class_name AbilityTargets
extends RefCounted
## Finding and shoving the enemies a team creature's ability reaches, so each ability only
## says its shape (a circle, a cone, a line). Measured feet to feet, like the jab; damage
## goes through CritRoll.

const ENEMIES_GROUP := "enemies"


## The Health of every enemy whose feet are within `radius` of `centre`.
static func within(asker: Node, centre: Vector2, radius: float) -> Array[Health]:
	var found: Array[Health] = []
	for enemy: Node2D in asker.get_tree().get_nodes_in_group(ENEMIES_GROUP):
		if enemy.global_position.distance_to(centre) <= radius:
			_add_health_of(enemy, found)
	return found


## The Health of every enemy in a cone from `origin` toward `direction`.
static func in_cone(asker: Node, origin: Vector2, direction: Vector2, reach: float, cone_degrees: float) -> Array[Health]:
	var found: Array[Health] = []
	var half_cone := deg_to_rad(cone_degrees) / 2.0
	for enemy: Node2D in asker.get_tree().get_nodes_in_group(ENEMIES_GROUP):
		var to_enemy := enemy.global_position - origin
		if to_enemy.length() > reach:
			continue
		if to_enemy.length() < 4.0 or absf(direction.angle_to(to_enemy)) <= half_cone:
			_add_health_of(enemy, found)
	return found


## The Health of every enemy whose feet are within `radius` of the line from `start` to `end`.
static func along(asker: Node, start: Vector2, end: Vector2, radius: float) -> Array[Health]:
	var found: Array[Health] = []
	for enemy: Node2D in asker.get_tree().get_nodes_in_group(ENEMIES_GROUP):
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		if closest.distance_to(enemy.global_position) <= radius:
			_add_health_of(enemy, found)
	return found


## Damages each target (rolling the attacker's crits).
static func hurt_all(attacker: Node2D, targets: Array[Health], damage: int) -> void:
	for target_health in targets:
		CritRoll.deal_damage(attacker, target_health, damage)


## Throws each target away from `from` at `speed` (enemies that know how to be knocked back).
static func knock_back_all(targets: Array[Health], from: Vector2, speed: float) -> void:
	for target_health in targets:
		var enemy := target_health.get_parent() as Node2D
		if enemy == null or not enemy.has_method("knock_back"):
			continue
		var away := enemy.global_position - from
		away = away.normalized() if away.length() > 0.1 else Vector2.DOWN
		enemy.call("knock_back", away * speed)


static func _add_health_of(enemy: Node2D, found: Array[Health]) -> void:
	var enemy_health := enemy.get_node_or_null("Health") as Health
	if enemy_health != null and not enemy_health.is_dead():
		found.append(enemy_health)
