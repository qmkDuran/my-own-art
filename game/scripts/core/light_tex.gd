class_name LightTex
extends RefCounted
## Generated textures for lights, glows and shadows. The lantern light is banded (a few hard steps, like
## pixel-art light) so its edge reads clearly as the radius that matters.

const SHADOW_SIZE: float = 32.0
const BANDS: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(0.45, 0.82), Vector2(0.68, 0.6), Vector2(0.84, 0.36), Vector2(0.96, 0.14)]

static var _cache: Dictionary = {}


static func _radial(key: String, g: Gradient, size: int) -> GradientTexture2D:
	if _cache.has(key):
		return _cache[key]
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	_cache[key] = t
	return t


## Banded lantern light (radius = half the texture size; scale it to the light radius).
static func banded(size: int = 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.set_offset(0, BANDS[0].x)
	g.set_color(0, Color(1, 1, 1, BANDS[0].y))
	g.set_offset(1, 1.0)
	g.set_color(1, Color(1, 1, 1, 0))
	for k: int in range(1, BANDS.size()):
		g.add_point(BANDS[k].x, Color(1, 1, 1, BANDS[k].y))
	return _radial("banded%d" % size, g, size)


## Smooth glow for small lights and additive halos.
static func soft(size: int = 128) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.5))
	return _radial("soft%d" % size, g, size)


static func shadow() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.55))
	g.set_color(1, Color(0, 0, 0, 0))
	g.add_point(0.6, Color(0, 0, 0, 0.4))
	return _radial("shadow", g, int(SHADOW_SIZE))
