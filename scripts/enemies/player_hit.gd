class_name PlayerHit
extends RefCounted
## An enemy attack landing on the player: the damage (unless they're mid-dodge, which makes
## them invulnerable) and the shove that throws them. Every enemy attack hits through this.
## A signature attack may add a status effect on top, on the player's `health_of` (e.g.
## Poisoned, Staggered, Buffeted; see DESIGN.md, "Enemy status effects").


## The player's Health (what hits and status effects land on), or null.
static func health_of(player: Node2D) -> Health:
	return Health.of(player)


## Hurts the player unless they're invulnerable (leaping through it). True when it landed.
static func try_to_hurt(player: Node2D, damage: int, source_position: Vector2) -> bool:
	var player_health := health_of(player)
	if player_health == null or player_health.is_invulnerable:
		return false
	player_health.take_damage(damage, source_position)
	return true


## Shoves the player (see Creature.push): they slide with this velocity for `seconds`.
static func shove(player: Node2D, push_velocity: Vector2, seconds: float) -> void:
	var creature := player as Creature
	if creature != null:
		creature.push(push_velocity, seconds)
