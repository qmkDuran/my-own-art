class_name ParticleBursts
## One-shot particle bursts for effects, in a pure-Godot flavour (soft round sprites with a colour ramp) and a
## flipbook flavour (Blender-rendered sheets played over each particle's life). Each burst frees itself.

const ALL_DIRECTIONS_DEG: float = 180.0
const FREE_AFTER: float = 2.0
const NARROW: float = 0.25
const SMOKE_RISE: Vector2 = Vector2(0.3, 0.6)
const SMOKE_START_SCALE: float = 0.4
const COOLED: Color = Color(0.6, 0.2, 0.1, 0.0)


## Soft embers flying out (additive, so cooling embers fade to nothing).
static func embers(count: int, colour: Color, size: float, speed: float, lifetime: float) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = ALL_DIRECTIONS_DEG
	process.initial_velocity_min = speed * 0.5
	process.initial_velocity_max = speed
	process.damping_min = speed
	process.damping_max = speed * 2.0
	process.gravity = Vector3.UP * 0.5
	process.color_ramp = _cooling(colour)
	return _burst(process, ParticleKit.glow_quad(size, colour, 1.0), count, lifetime)


## A few soft smoke puffs that swell and drift up.
static func smoke(count: int, colour: Color, size: float, lifetime: float) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = ALL_DIRECTIONS_DEG * NARROW
	process.initial_velocity_min = size * SMOKE_RISE.x
	process.initial_velocity_max = size * SMOKE_RISE.y
	process.gravity = Vector3.ZERO
	process.scale_min = 0.5
	process.scale_max = 1.0
	var grow := CurveTexture.new()
	grow.curve = Curve.new()
	grow.curve.add_point(Vector2(0, SMOKE_START_SCALE))
	grow.curve.add_point(Vector2(1, 1))
	process.scale_curve = grow
	process.color_ramp = ParticleKit.fade_ramp()
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = colour
	material.albedo_texture = ParticleKit.soft_dot()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	quad.material = material
	return _burst(process, quad, count, lifetime)


## A flipbook sheet played once per particle; additive for fire, alpha for smoke.
static func flipbook(sheet: Texture2D, frames: Vector2i, count: int, size: float, lifetime: float, additive: bool,
		drift: float, tint: Color = Color.WHITE) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.anim_speed_min = 1.0
	process.anim_speed_max = 1.0
	process.direction = Vector3.UP
	process.spread = ALL_DIRECTIONS_DEG * NARROW
	process.initial_velocity_max = drift
	process.gravity = Vector3.ZERO
	process.angle_max = ALL_DIRECTIONS_DEG * 2.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.particles_anim_h_frames = frames.x
	material.particles_anim_v_frames = frames.y
	material.particles_anim_loop = false
	material.albedo_texture = sheet
	material.albedo_color = tint
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	quad.material = material
	return _burst(process, quad, count, lifetime)


static func _burst(process: ParticleProcessMaterial, mesh: Mesh, count: int, lifetime: float) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.amount = count
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.emitting = true
	particles.ready.connect(func() -> void:
		particles.get_tree().create_timer(lifetime + FREE_AFTER, false).timeout.connect(particles.queue_free))
	return particles


static func _cooling(colour: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, colour)
	gradient.set_color(1, colour * COOLED)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture
