class_name LightTex
extends RefCounted
## Generated textures for lights, glows and shadows. Every light falls off smoothly (no bands, no rings); the
## radius that matters is shown by the lantern's dashed ring, not by steps in the light.

const SHADOW_SIZE: float = 32.0
const POOL_POINTS: int = 24
const POOL_FLAT: float = 0.15

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


## The lantern's pool (radius = half the texture size; scale it to the light radius): a smooth falloff with no
## steps or contour rings: bright and flat near the heart, an even fade to nothing at the edge.
static func pool(size: int = 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	for k: int in range(1, POOL_POINTS):
		var t: float = float(k) / POOL_POINTS
		g.add_point(t, Color(1, 1, 1, 1.0 - smoothstep(POOL_FLAT, 1.0, t)))
	return _radial("pool%d" % size, g, size)


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


## A thin bright ring with soft edges (a shockwave); radius = half the texture size.
static func ring(size: int = 128) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.72, Color(1, 1, 1, 0))
	g.add_point(0.88, Color(1, 1, 1, 1))
	g.add_point(0.96, Color(1, 1, 1, 0.3))
	return _radial("ring%d" % size, g, size)
