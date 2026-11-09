class_name TopCentreStack
extends RefCounted
## The HUD's top-centre toasts (the discovery card and every BossDefeatedBanner: checkpoint,
## chip found, Glimmer Shard, Awakening, boss defeated) share one lane. A card that comes up
## while others are showing rests just below the lowest of them, so two never overlap.
##
## A card reserves its place when it starts showing and releases it as it starts to fade out.

## Gap between two stacked cards, in game pixels.
const GAP := 3.0

## Each showing card's resting rectangle on the HUD, in game pixels.
static var _places: Dictionary[Control, Rect2] = {}


## Where `card` should rest (its top, in game pixels): `top_margin`, or below the lowest
## card already showing. Remembers the place until `release`.
static func reserve(card: Control, top_margin: float, card_size: Vector2) -> float:
	var top := top_margin
	for other: Control in _places.keys():
		if not is_instance_valid(other) or not other.is_visible_in_tree():
			_places.erase(other)
		elif other != card:
			top = maxf(top, _places[other].end.y + GAP)
	_places[card] = Rect2(Vector2(0.0, top), card_size)
	return top


static func release(card: Control) -> void:
	_places.erase(card)
