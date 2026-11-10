class_name SpriteFactory
extends RefCounted
## Small helpers for the sprites every scene builds (top-left anchored, feet-anchored, additive light).


static func additive() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


## A sprite drawn from its top-left corner.
static func sprite(parent: Node, path: String, pos: Vector2, z: int = 0, add_blend: bool = false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path) as Texture2D
	s.centered = false
	s.position = pos
	s.z_index = z
	if add_blend:
		s.material = additive()
	parent.add_child(s)
	return s


## A sprite whose origin is its feet (bottom centre of one frame), for y-sorted worlds.
static func grounded(parent: Node, path: String, feet: Vector2, hframes: int = 1) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path) as Texture2D
	s.hframes = hframes
	s.centered = false
	var w: float = s.texture.get_width() / float(hframes)
	s.offset = Vector2(-w / 2.0, -s.texture.get_height())
	s.position = feet
	parent.add_child(s)
	return s


## An additive light centred on `pos`, scaled down from a large glow texture.
static func glow(parent: Node, path: String, pos: Vector2, scale: Vector2, z: int, offset: Vector2 = Vector2.ZERO) -> Sprite2D:
	var s := sprite(parent, path, pos, z, true)
	s.centered = true
	s.offset = offset
	s.scale = scale
	return s


## Lowest opaque row (+1) of the first frame of a sprite strip: where the feet are.
static func content_bottom(tex: Texture2D, frame_w: int) -> int:
	var img: Image = tex.get_image()
	for y: int in range(img.get_height() - 1, -1, -1):
		for x: int in frame_w:
			if img.get_pixel(x, y).a > 0.5:
				return y + 1
	return img.get_height()
