class_name AbilityTargets
extends RefCounted
## Finding and shoving the enemies a team creature's ability reaches, so each ability only
## says its shape (a circle, a cone, a line). Measured feet to feet, like the jab; damage
## goes through ElementStrike.

const ENEMIES_GROUP := "enemies"
const HEALTH_NODE := "Health"
## What an enemy that can be shoved calls its shove (see Enemy.knock_back).
const KNOCK_BACK_METHOD := "knock_back"
## An enemy closer than this to the shove's origin is pushed straight down.
const MIN_PUSH_LENGTH := 0.1
## An enemy closer than this to a cone's origin is hit whatever the cone's direction.
const CONE_POINT_BLANK := 4.0


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
		if to_enemy.length() < CONE_POINT_BLANK or absf(direction.angle_to(to_enemy)) <= half_cone:
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


## The one of `candidates` whose feet are closest to `spot` (null when there are none).
static func nearest_to(spot: Vector2, candidates: Array[Health]) -> Health:
	var nearest: Health = null
	var nearest_distance := INF
	for candidate in candidates:
		var distance := (candidate.get_parent() as Node2D).global_position.distance_to(spot)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


## `target_health` alone, for the calls that take a list of targets.
static func single(target_health: Health) -> Array[Health]:
	var one: Array[Health] = [target_health]
	return one


## Throws each target away from `from` at `speed` (enemies that know how to be knocked back).
static func knock_back_all(targets: Array[Health], from: Vector2, speed: float) -> void:
	for target_health in targets:
		var enemy := target_health.get_parent() as Node2D
		if enemy == null:
			continue
		var away := enemy.global_position - from
		var direction := away.normalized() if away.length() > MIN_PUSH_LENGTH else Vector2.DOWN
		knock_back(enemy, direction * speed)


## Shoves `enemy` with `push_velocity`, if it knows how to be knocked back.
static func knock_back(enemy: Node2D, push_velocity: Vector2) -> void:
	if enemy.has_method(KNOCK_BACK_METHOD):
		enemy.call(KNOCK_BACK_METHOD, push_velocity)


static func _add_health_of(enemy: Node2D, found: Array[Health]) -> void:
	var enemy_health := enemy.get_node_or_null(HEALTH_NODE) as Health
	if enemy_health != null and not enemy_health.is_dead():
		found.append(enemy_health)
