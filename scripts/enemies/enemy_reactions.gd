class_name EnemyReactions
extends RefCounted
## How every enemy reacts to being hit and to dying, so each enemy only says when.

## The group enemies are in while they can be hit and targeted.
const ENEMIES_GROUP := "enemies"


## The velocity a hit from `source_position` throws `body` away with.
static func knockback_velocity(body: Node2D, source_position: Vector2, speed: float) -> Vector2:
	return (body.global_position - source_position).normalized() * speed


## A knockback (or any slide) slowing down by `friction` pixels per second squared.
static func slowed_down(velocity: Vector2, friction: float, delta: float) -> Vector2:
	return velocity.move_toward(Vector2.ZERO, friction * delta)


## Takes a dead enemy out of play at once (it can no longer be hit, targeted or bumped
## into), fades its sprite out over `seconds` and then frees it.
static func fade_out_and_free(body: Node2D, sprite: CanvasItem, collision_shape: CollisionShape2D, seconds: float) -> void:
	body.remove_from_group(ENEMIES_GROUP)
	collision_shape.set_deferred("disabled", true)
	var fade := body.create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, seconds)
	fade.tween_callback(body.queue_free)
