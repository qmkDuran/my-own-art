class_name EnemyBrain
extends RefCounted
## What an enemy decides each frame (one brain per role: SwarmerBrain, ShooterBrain, EliteBrain, BossBrain): where
## it wants to go (enemy.wish), what it looks at, and when it winds up and attacks. Every attack is telegraphed.


static func for_role(role: String) -> EnemyBrain:
	match role:
		"swarmer":
			return SwarmerBrain.new()
		"shooter":
			return ShooterBrain.new()
		"elite":
			return EliteBrain.new()
		_:
			return BossBrain.new()


func think(_enemy: Enemy, _delta: float) -> void:
	pass


## A multiplier on the enemy's walking speed (a lunge is faster, a stagger stops it).
func speed_scale(_enemy: Enemy) -> float:
	return 1.0


func on_hurt(_enemy: Enemy, _hit: Hit) -> void:
	pass


func on_shield_broken(_enemy: Enemy) -> void:
	pass


## The flat direction and distance from the enemy to the player.
static func to_player(enemy: Enemy) -> Vector3:
	var at: Vector3 = enemy.roster.player.global_position
	return Vector3(at.x - enemy.global_position.x, 0.0, at.z - enemy.global_position.z)


static func player_chest(enemy: Enemy) -> Vector3:
	return player_chest_of(enemy.roster.player)


static func player_chest_of(player: Node3D) -> Vector3:
	return player.global_position + Vector3.UP * Tuning.number("combat", "player", "chest_height")


## True when nothing in the world blocks the line from the enemy to the player's chest.
static func sees_player(enemy: Enemy) -> bool:
	var query := PhysicsRayQueryParameters3D.create(enemy.centre(), player_chest(enemy), Layers.WORLD)
	return enemy.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
