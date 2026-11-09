class_name FxBody
extends RefCounted
## Measures how tall a creature is drawn (its drawn pixels, not its image box), so effects
## that sit on a body (the Ash Guard wall at the gloves, burn embers rising off a target)
## fit whatever size it is: the 16 px Emberoo, the ~46 px one, a 24-32 px machine.

## The child every creature draws itself with.
const SPRITE_NODE := "Sprite"


## The height of `creature`'s drawn pixels in world pixels, or `fallback` if it has no sprite.
static func height_of(creature: Node, fallback: float) -> float:
	var sprite := creature.get_node_or_null(SPRITE_NODE) as Node2D
	var frame := _current_frame(sprite)
	if frame == null or frame.is_empty():
		return fallback
	var drawn := frame.get_used_rect()
	if drawn.size.y <= 0:
		return fallback
	return drawn.size.y * absf(sprite.scale.y)


## The image of the frame `sprite` shows right now, or null.
static func _current_frame(sprite: Node2D) -> Image:
	if sprite is AnimatedSprite2D:
		var animated := sprite as AnimatedSprite2D
		if animated.sprite_frames == null or not animated.sprite_frames.has_animation(animated.animation):
			return null
		var texture := animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
		return _image_of(texture)
	if sprite is Sprite2D:
		var still := sprite as Sprite2D
		var image := _image_of(still.texture)
		if image == null:
			return null
		var sheet := Rect2i(still.region_rect) if still.region_enabled else Rect2i(Vector2i.ZERO, image.get_size())
		var frame_size := sheet.size / Vector2i(still.hframes, still.vframes)
		return image.get_region(Rect2i(sheet.position + frame_size * still.frame_coords, frame_size))
	return null


static func _image_of(texture: Texture2D) -> Image:
	if texture == null:
		return null
	var image := texture.get_image()
	if image != null and image.is_compressed():
		image.decompress()
	return image
