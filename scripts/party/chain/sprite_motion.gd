class_name SpriteMotion
extends RefCounted
## Moves a creature's sprite (through its `offset`, so animators that set its position
## never fight it) for entrances and exits, in whole pixels only.

const SPRITE_NODE := "Sprite"
## A hop spends this share of its time rising, the rest falling.
const HOP_RISE_SHARE := 0.4


## Slides the sprite's offset from `from` to `to` over `seconds`.
static func slide(sprite: AnimatedSprite2D, from: Vector2, to: Vector2, seconds: float,
		transition: Tween.TransitionType = Tween.TRANS_QUAD, easing: Tween.EaseType = Tween.EASE_IN) -> Tween:
	sprite.offset = from.round()
	var tween := sprite.create_tween()
	tween.tween_method(func(at: Vector2) -> void: sprite.offset = at.round(), from, to, seconds) \
			.set_trans(transition).set_ease(easing)
	return tween


## A quick hop up and back down (e.g. an uppercut's follow-through).
static func hop(sprite: AnimatedSprite2D, height: float, seconds: float) -> void:
	var tween := slide(sprite, Vector2.ZERO, Vector2(0, -height), seconds * HOP_RISE_SHARE, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.tween_method(func(at: Vector2) -> void: sprite.offset = at.round(), Vector2(0, -height), Vector2.ZERO, seconds * (1.0 - HOP_RISE_SHARE)) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## The creature's sprite (null if it has none).
static func sprite_of(member: Node) -> AnimatedSprite2D:
	return member.get_node_or_null(SPRITE_NODE) as AnimatedSprite2D
