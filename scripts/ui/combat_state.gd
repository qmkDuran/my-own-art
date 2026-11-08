class_name CombatState
extends Node
## Tells whether Emberoo is fighting, so the HUD trainer knows which way to face.
##
## Emberoo is "in combat" while an enemy is close, and for a few seconds after he last
## dealt or took damage (or used a skill). After that many seconds of calm, he's out of combat.
## A training dummy nearby doesn't count as a fight; hitting it does.

## An enemy closer than this to Emberoo (in pixels) means a fight is on.
const ENEMY_NEAR_DISTANCE := 110.0
## Seconds of calm before Emberoo counts as out of combat.
const CALM_SECONDS := 4.0

var _player: Node2D
## Starts calm, so the trainer faces the player when the level begins.
var _seconds_since_fighting: float = CALM_SECONDS


func _process(delta: float) -> void:
	_seconds_since_fighting += delta
	if not is_instance_valid(_player):
		_find_player()
	elif _is_enemy_near():
		note_fighting()


func is_in_combat() -> bool:
	return _seconds_since_fighting < CALM_SECONDS


## Something fight-like just happened (a hit, a skill): the calm countdown starts again.
func note_fighting() -> void:
	_seconds_since_fighting = 0.0


func _find_player() -> void:
	_player = PlayerFinder.find(self)
	if _player == null:
		return
	var health := _player.get_node_or_null("Health") as Health
	if health != null:
		health.damaged.connect(func(_amount: int, _from: Vector2) -> void: note_fighting())
	var melee := _player.get_node_or_null("MeleeAttack") as MeleeAttack
	if melee != null:
		melee.hits_landed.connect(func(_hit_count: int) -> void: note_fighting())


func _is_enemy_near() -> bool:
	for enemy in get_tree().get_nodes_in_group(EnemyReactions.ENEMIES_GROUP):
		var enemy_2d := enemy as Node2D
		if enemy_2d is TrainingDummy:
			continue
		if enemy_2d != null and enemy_2d.global_position.distance_to(_player.global_position) < ENEMY_NEAR_DISTANCE:
			return true
	return false
