class_name ParticleKit
## Shared building blocks for the town's particles: a glowing billboard quad, a lit (only visible in lamplight)
## mote, and a fade-in/fade-out colour ramp.

const FADE_IN: float = 0.2
const FADE_OUT: float = 0.8


## A camera-facing quad that glows on its own (fireflies, sparks).
static func glow_quad(size: float, color: Color, energy: float) -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color * energy
	material.albedo_texture = soft_dot()
	return _quad(size, material)


## A camera-facing quad lit by the scene, so it only shows where a lamp shines (dust in lamplight).
static func lit_mote(size: float, color: Color) -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.albedo_texture = soft_dot()
	material.roughness = 1.0
	return _quad(size, material)


## Transparent at birth and death, full in between.
static func fade_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(FADE_IN, Color.WHITE)
	gradient.add_point(FADE_OUT, Color.WHITE)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


## A round, soft-edged dot texture.
static func soft_dot() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


static func _quad(size: float, material: Material) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = material
	return quad
