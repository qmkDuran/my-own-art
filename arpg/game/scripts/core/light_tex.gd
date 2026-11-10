class_name LightTex
extends RefCounted
## Soft radial textures for 2D lights and glows (cached by size).

static var _cache: Dictionary = {}


static func radial(size: int) -> GradientTexture2D:
	if _cache.has(size):
		return _cache[size]
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	_cache[size] = t
	return t
