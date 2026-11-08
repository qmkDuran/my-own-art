class_name CreatureInfo
extends RefCounted
## The facts the discovery card and the Creature Log show about a species.
##
## A species without a painted portrait yet also hands over its first idle frame
## ("sprite"), so the card can show the sprite scaled up instead of an empty frame.

## The animation whose first frame stands in for a missing portrait.
const STAND_IN_ANIMATION := "idle"


## { "species", "name", "element", "portrait", "sprite" }. `sprite` may be null (e.g. on a
## creature that isn't in the scene tree yet); then the info simply has no stand-in picture.
static func describe(
		species_id: String,
		display_name: String,
		element: String,
		portrait: Texture2D,
		sprite: AnimatedSprite2D
) -> Dictionary:
	return {
		"species": species_id,
		"name": display_name,
		"element": element,
		"portrait": portrait,
		"sprite": _first_idle_frame(sprite),
	}


static func _first_idle_frame(sprite: AnimatedSprite2D) -> Texture2D:
	if sprite == null or sprite.sprite_frames == null:
		return null
	if not sprite.sprite_frames.has_animation(STAND_IN_ANIMATION):
		return null
	return sprite.sprite_frames.get_frame_texture(STAND_IN_ANIMATION, 0)
