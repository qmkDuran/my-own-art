class_name EnemyReactions
extends RefCounted
## How every enemy reacts to being hit and to dying, so each enemy only says when.

## The group enemies are in while they can be hit and targeted.
const ENEMIES_GROUP := "enemies"
## The group summoned creatures are in while they're alive (see HandlerSummoner's zone limit).
const SUMMONED_GROUP := "summoned"


## The velocity a hit from `source_position` throws `body` away with.
static func knockback_velocity(body: Node2D, source_position: Vector2, speed: float) -> Vector2:
	return (body.global_position - source_position).normalized() * speed


## Closer than this to the attacker, a throw goes in its fallback direction instead.
const SAME_SPOT_DISTANCE := 0.1


## True when `target` can be thrown by a big hit (it has a `knock_back(velocity)` method:
## every Enemy, and the training dummy, which leans instead).
static func can_be_thrown(target: Node) -> bool:
	return target.has_method("knock_back")


## Throws `target` with `push_velocity`, if it can be thrown.
static func throw(target: Node, push_velocity: Vector2) -> void:
	if can_be_thrown(target):
		target.call("knock_back", push_velocity)


## Throws `target` straight away from `from` at `speed` (toward `fallback_direction` when
## it's right on top of `from`), if it can be thrown.
static func throw_away_from(target: Node2D, from: Vector2, speed: float, fallback_direction: Vector2) -> void:
	var away := target.global_position - from
	if away.length() < SAME_SPOT_DISTANCE:
		away = fallback_direction
	throw(target, away.normalized() * speed)


## A knockback (or any slide) slowing down by `friction` pixels per second squared.
static func slowed_down(velocity: Vector2, friction: float, delta: float) -> Vector2:
	return velocity.move_toward(Vector2.ZERO, friction * delta)


## Takes a dead enemy out of play at once (it can no longer be hit, targeted or bumped
## into), fades its sprite out over `seconds` and then frees it.
static func fade_out_and_free(body: Node2D, sprite: CanvasItem, collision_shape: CollisionShape2D, seconds: float) -> void:
	body.remove_from_group(ENEMIES_GROUP)
	body.remove_from_group(SUMMONED_GROUP)
	collision_shape.set_deferred("disabled", true)
	var fade := body.create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, seconds)
	fade.tween_callback(body.queue_free)
