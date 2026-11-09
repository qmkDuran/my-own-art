class_name TopCentreStack
extends RefCounted
## The HUD's top-centre toasts (the discovery card and every BossDefeatedBanner: checkpoint,
## chip found, Glimmer Shard, Awakening, boss defeated) share one lane. A card that comes up
## while others are showing rests just below the lowest of them, so two never overlap.
##
## A card reserves its place when it starts showing and releases it as it starts to fade out.

## Gap between two stacked cards, in game pixels.
const GAP := 3.0
## How far a card drifts while fading in and out, in game pixels.
const DRIFT := 4.0
## Seconds a card rests in place, and takes to fade out.
const SHOW_SECONDS := 2.0
const FADE_OUT_SECONDS := 0.6

## Each showing card's resting rectangle on the HUD, in game pixels. Untyped keys on
## purpose: a card freed with its zone stays here until the next `reserve` drops it, and a
## freed object can't be read through a typed variable.
static var _places: Dictionary = {}


## Where `card` should rest (its top, in game pixels): `top_margin`, or below the lowest
## card already showing. Remembers the place until `release`.
static func reserve(card: Control, top_margin: float, card_size: Vector2) -> float:
	var top := top_margin
	for other: Variant in _places.keys():
		if not _is_showing(other):
			_places.erase(other)
		elif other != card:
			var place: Rect2 = _places[other]
			top = maxf(top, place.end.y + GAP)
	_places[card] = Rect2(Vector2(0.0, top), card_size)
	return top


static func release(card: Control) -> void:
	_places.erase(card)


## Shows `card` (sized already) centred in a lane `lane_width` wide: it fades in over
## `fade_in_seconds` while drifting down onto its resting place (`reserve`), rests, gives up
## its place and fades out drifting back up. Returns the tween (bound to `card`), for the
## caller to chain what follows; time scale is ignored if asked (e.g. during slow motion).
static func show_card(card: Control, lane_width: float, top_margin: float, fade_in_seconds: float, ignore_time_scale: bool = false) -> Tween:
	var card_size := HudCard.size_on_screen(card)
	card.position.x = roundf((lane_width - card_size.x) / 2.0)
	var resting_top := reserve(card, top_margin, card_size)
	card.position.y = resting_top - DRIFT
	card.modulate.a = 0.0
	card.visible = true
	var tween := card.create_tween().set_ignore_time_scale(ignore_time_scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel()
	tween.tween_property(card, "modulate:a", 1.0, fade_in_seconds)
	tween.tween_property(card, "position:y", resting_top, fade_in_seconds)
	tween.chain().tween_interval(SHOW_SECONDS)
	# A card on its way out gives up its place: the next one can take the top spot.
	tween.chain().tween_callback(release.bind(card))
	tween.chain().tween_property(card, "modulate:a", 0.0, FADE_OUT_SECONDS)
	tween.parallel().tween_property(card, "position:y", resting_top - DRIFT, FADE_OUT_SECONDS)
	return tween


static func _is_showing(card: Variant) -> bool:
	return is_instance_valid(card) and (card as Control).is_visible_in_tree()
