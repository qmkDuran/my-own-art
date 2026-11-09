extends Node
## Overclocked chip mod "Jabs hit a second enemy behind the first" (added by ChipEffects).
##
## When a jab lands, the punch carries on through: the nearest enemy a little further along
## the same line, behind the furthest one hit, takes the jab's damage too (crits included),
## with its own impact spark.

## How far past the furthest enemy hit the punch carries, in pixels.
const PIERCE_REACH := 24.0

var _struck_this_jab: Array[Health] = []

@onready var _melee: MeleeAttack = get_parent().get_node(MeleeAttack.NODE_NAME)
@onready var _attacker: Node2D = get_parent()


func _ready() -> void:
	_melee.target_hit.connect(_on_target_hit)


func _on_target_hit(target_health: Health) -> void:
	if _struck_this_jab.is_empty():
		_pierce.call_deferred()
	_struck_this_jab.append(target_health)


## Runs once after every target of the jab was reported.
func _pierce() -> void:
	var furthest := _furthest_struck()
	var direction := Vector2.ZERO
	var behind: Node2D = null
	if furthest != null:
		direction = (furthest.global_position - _attacker.global_position).normalized()
		behind = _nearest_behind(furthest, direction)
	_struck_this_jab.clear()
	if behind == null:
		return
	CritRoll.deal_damage(_attacker, Health.of(behind), _melee.damage)
	_spawn_spark(behind.global_position + Vector2(0, _melee.target_body_height), direction)


func _furthest_struck() -> Node2D:
	var furthest: Node2D = null
	for target_health in _struck_this_jab:
		if not is_instance_valid(target_health):
			continue
		var body := target_health.get_parent() as Node2D
		if furthest == null or _distance(body) > _distance(furthest):
			furthest = body
	return furthest


## The closest enemy within PIERCE_REACH past `first`, near the punch's line.
func _nearest_behind(first: Node2D, direction: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for target: Node2D in get_tree().get_nodes_in_group(_melee.target_group):
		var health := Health.of(target)
		if health == null or health.is_dead() or _struck_this_jab.has(health) or target == first:
			continue
		var offset := target.global_position - first.global_position
		var along := offset.dot(direction)
		var across := absf(offset.cross(direction))
		if along > 0.0 and along <= PIERCE_REACH and across <= _melee.hit_radius and along < best_distance:
			best = target
			best_distance = along
	return best


func _distance(body: Node2D) -> float:
	return body.global_position.distance_to(_attacker.global_position)


func _spawn_spark(at: Vector2, direction: Vector2) -> void:
	if _melee.impact_effect == null:
		return
	var spark: Node2D = _melee.impact_effect.instantiate()
	_attacker.get_parent().add_child(spark)
	spark.global_position = at
	spark.rotation = direction.angle()
