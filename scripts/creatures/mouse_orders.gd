class_name MouseOrders
extends Node
## Click-to-move and click-to-attack for the creature.
##
## Left-click on the ground walks there (hold to keep following the cursor);
## left-click on an enemy walks up to it and jabs (hold to keep jabbing).
## Shift + left-click stops and jabs in place instead (PlayerInput reports it as an attack).
## Steering with the arrow keys cancels mouse orders.
##
## This only remembers the orders and where they lead; the creature walks and jabs.

## How close to a clicked spot counts as "arrived", in pixels.
const ARRIVE_DISTANCE := 3.0

@export var player_input: PlayerInput
## Effect shown where you click to move (a small ring).
@export var click_marker_scene: PackedScene
## How close (feet to feet, pixels) the creature walks to a clicked enemy before jabbing.
## The jab connects up to MeleeAttack's reach + hit_radius away, so this stops a little
## inside that and jabs at once, instead of walking into the enemy first.
@export var attack_approach_distance: float = 20.0
## How close the cursor must be to an enemy's body centre for a click to target it, in pixels.
## The nearest enemy within this distance is picked, so near-misses still count.
@export var click_target_radius: float = 12.0

## Where a left-click told the creature to walk.
var _destination: Vector2 = Vector2.ZERO
var _has_destination: bool = false
## The enemy a left-click told the creature to attack (walk up to it, then jab).
var _attack_target: Node2D = null
## Whether the creature has already jabbed its attack target since it was clicked.
## Letting go of the button after that ends the order (so one click = one jab).
var _has_jabbed_attack_target: bool = false

@onready var creature: Node2D = get_parent()


## Reads this frame's clicks into orders. Call once per physics frame, before acting on them.
func update() -> void:
	if player_input.get_move_direction() != Vector2.ZERO or player_input.is_holding_stand_still():
		clear()
		return

	if player_input.just_clicked_to_move():
		var enemy := _enemy_under_cursor()
		if enemy != null:
			clear()
			_attack_target = enemy
			_has_jabbed_attack_target = false
		else:
			_walk_to(player_input.get_aim_point())
			_show_click_marker(_destination)
	elif player_input.is_holding_move_click() and _attack_target == null:
		_walk_to(player_input.get_aim_point())

	if _attack_target != null and not _is_valid_target(_attack_target):
		_attack_target = null
	# A single click is a single jab; holding the button keeps jabbing.
	if _has_jabbed_attack_target and not player_input.is_holding_move_click():
		_attack_target = null


## Forgets every order.
func clear() -> void:
	_has_destination = false
	_attack_target = null


## Forgets the spot to walk to (e.g. the creature started a jab), but keeps an attack order.
func stop_walking() -> void:
	_has_destination = false


func has_destination() -> bool:
	return _has_destination


func has_attack_target() -> bool:
	return _attack_target != null


func is_attack_target_in_reach() -> bool:
	return _attack_target != null and _is_in_reach_of(_attack_target)


## The direction to the attack target, or `fallback` when standing right on it.
func direction_to_attack_target(fallback: Vector2) -> Vector2:
	var to_enemy := _attack_target.global_position - creature.global_position
	return to_enemy.normalized() if to_enemy.length() > 0.1 else fallback


## The creature just jabbed its attack target (one click = one jab, unless the button is held).
func note_jabbed_attack_target() -> void:
	_has_jabbed_attack_target = true


## Where the orders lead: toward the attack target until in reach, or toward the clicked spot
## until arrived (which ends that order). Zero with nowhere to go. `fallback` is used when
## standing right on the target.
func move_direction(fallback: Vector2) -> Vector2:
	if _attack_target != null:
		return Vector2.ZERO if _is_in_reach_of(_attack_target) else direction_to_attack_target(fallback)
	if _has_destination:
		var to_destination := _destination - creature.global_position
		if to_destination.length() <= ARRIVE_DISTANCE:
			_has_destination = false
			return Vector2.ZERO
		return to_destination.normalized()
	return Vector2.ZERO


func _walk_to(point: Vector2) -> void:
	_attack_target = null
	_destination = point
	_has_destination = true


## The enemy whose body centre is nearest the cursor, if any is within click_target_radius.
func _enemy_under_cursor() -> Node2D:
	var cursor := player_input.get_aim_point()
	var nearest: Node2D = null
	var nearest_distance := click_target_radius
	for enemy: Node2D in get_tree().get_nodes_in_group(EnemyReactions.ENEMIES_GROUP):
		var distance := cursor.distance_to(enemy.global_position + Vector2(0, Creature.BODY_HEIGHT))
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _is_valid_target(enemy: Node2D) -> bool:
	return is_instance_valid(enemy) and enemy.is_in_group(EnemyReactions.ENEMIES_GROUP)


func _is_in_reach_of(enemy: Node2D) -> bool:
	return creature.global_position.distance_to(enemy.global_position) <= attack_approach_distance


## A small ring where you clicked, so you know the order was received.
func _show_click_marker(point: Vector2) -> void:
	if click_marker_scene == null:
		return
	Shockwave.spawn(click_marker_scene, creature.get_parent(), point, 6.0, 0.25, Color(ApolloPalette.CREAM, 0.8))
