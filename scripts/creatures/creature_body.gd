class_name CreatureBody
extends RefCounted
## Where a creature's body is drawn above its feet, so anything aimed at it (a sludge hose, a
## rail beam, a gust orb, a chill beam, a click) goes for the body you see, whatever its size:
## the player's evolution form (Creature.body_height), an enemy's `body_height` and
## `body_half_width` (Enemy, TrainingDummy). Hits are still measured on the ground, feet to feet.
##
## Heights are measured from the feet (negative is up).

## For a body that says nothing about its size: about the middle of a small creature.
const DEFAULT_HEIGHT := -6.0
const DEFAULT_HALF_WIDTH := 8.0
## The properties an enemy (or anything else that can be targeted) says its size with.
const HEIGHT_PROPERTY := &"body_height"
const HALF_WIDTH_PROPERTY := &"body_half_width"


## Height of the middle of `body` above its feet.
static func height_of(body: Node2D) -> float:
	if body is Creature:
		return (body as Creature).body_height()
	return _number_or(body, HEIGHT_PROPERTY, DEFAULT_HEIGHT)


## The middle of `body`, in world coordinates.
static func middle_of(body: Node2D) -> Vector2:
	return body.global_position + Vector2(0, height_of(body))


## About half the width of `body`'s drawn sprite.
static func half_width_of(body: Node2D) -> float:
	return _number_or(body, HALF_WIDTH_PROPERTY, DEFAULT_HALF_WIDTH)


## How far `point` is from `body`'s drawn shape, as a share of its size (an oval from its feet
## to the top of its head, `margin` pixels bigger all round): 1 or less is on the body.
static func share_of_size_away(body: Node2D, point: Vector2, margin: float) -> float:
	var offset := point - middle_of(body)
	var half_height := absf(height_of(body)) + margin
	var half_width := half_width_of(body) + margin
	return Vector2(offset.x / half_width, offset.y / half_height).length()


static func _number_or(body: Node2D, property: StringName, fallback: float) -> float:
	var value: Variant = body.get(property)
	return float(value) if value is float or value is int else fallback
