class_name FlameWisp
extends Node3D
## The look of a flying Lantern Flare: a soft teardrop flame that wobbles and flickers as it flies, a trail (a
## fading ribbon, or the Blender spiral ribbon with a scrolling glow), embers shed along the path and a small
## moving light.
## When the bolt lands, the trail and embers are left behind to fade out on their own.

const SCROLL_SHADER: Shader = preload("res://shaders/vfx_scroll.gdshader")
const FLAME_SHADER: Shader = preload("res://shaders/vfx_flame.gdshader")
const HALO_SHARE: float = 0.6
const RIBBON_ENERGY: float = 0.8
const LINGER: float = 0.6
const WOBBLE_RATIO: float = 1.3
const WOBBLE_FLAT: float = 0.6

var _spec: Dictionary
var _core: Node3D
var _ribbon: MeshInstance3D
var _trail: RibbonTrail
var _embers: GPUParticles3D
var _clock: float = 0.0


func setup(kit: VfxKit, spec: Dictionary, direction: Vector3) -> void:
	name = "FlameWisp"
	_spec = spec
	var colour: Color = Tuning.color(spec["color"])
	basis = Basis.looking_at(direction, Vector3.UP)
	_core = _flame(float(spec["core_size"]), float(spec["energy"]))
	add_child(_core)
	_core.add_child(SoftGlow.make(colour, float(spec["core_size"]) * HALO_SHARE, float(spec["energy"])))
	if kit.quota.trails:
		_add_trail(kit, colour, direction)
	_embers = _ember_trail(kit, colour)
	add_child(_embers)
	var glow: float = spec["light_energy"]
	var light: EffectLight = EffectLight.make(kit.quota, colour, glow, float(spec["light_range"]))
	if light != null:
		add_child(light)


func _process(delta: float) -> void:
	_clock += delta
	var wobble: float = float(_spec["wobble"])
	var speed: float = float(_spec["wobble_speed"])
	var lift: float = cos(_clock * speed * WOBBLE_RATIO) * wobble * WOBBLE_FLAT
	_core.position = Vector3(sin(_clock * speed) * wobble, lift, 0.0)
	if _ribbon != null:
		_ribbon.rotation.y = _clock * float(_spec["ribbon_spin"])


## Leaves the trail and embers in the world to fade out (the bolt itself is about to go).
func leave_behind() -> void:
	for part: Node3D in [_trail, _embers]:
		if part == null:
			continue
		var at: Transform3D = part.global_transform
		part.reparent(get_tree().current_scene)
		part.global_transform = at
		if part is GPUParticles3D:
			(part as GPUParticles3D).emitting = false
		get_tree().create_timer(LINGER, false).timeout.connect(part.queue_free)


func _add_trail(kit: VfxKit, colour: Color, direction: Vector3) -> void:
	if kit.uses_blender():
		_ribbon = MeshInstance3D.new()
		_ribbon.mesh = kit.effect_mesh("spiral_ribbon")
		var material := ShaderMaterial.new()
		material.shader = SCROLL_SHADER
		material.set_shader_parameter("color", colour)
		material.set_shader_parameter("energy", RIBBON_ENERGY)
		_ribbon.material_override = material
		_ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var holder := Node3D.new()
		add_child(holder)
		holder.basis = Basis(Vector3.RIGHT, PI * 0.5)
		holder.scale = Vector3.ONE * float(_spec["ribbon_length"])
		holder.add_child(_ribbon)
		return
	_trail = RibbonTrail.new()
	_trail.setup(self, colour, float(_spec["trail_width"]), int(_spec["trail_points"]))
	add_child(_trail)


## The teardrop flame: a sphere the flame shader draws out into a flickering tail (the node faces its flight).
func _flame(size: float, energy: float) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = size * 0.5
	sphere.height = size
	var material := ShaderMaterial.new()
	material.shader = FLAME_SHADER
	material.set_shader_parameter("energy", energy)
	sphere.material = material
	var flame := MeshInstance3D.new()
	flame.mesh = sphere
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return flame


func _ember_trail(kit: VfxKit, colour: Color) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = ParticleBursts.ALL_DIRECTIONS_DEG
	process.initial_velocity_max = float(_spec["wobble_speed"]) * float(_spec["wobble"])
	process.gravity = Vector3.UP * 0.5
	process.color_ramp = ParticleKit.fade_ramp()
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = ParticleKit.glow_quad(float(_spec["ember_size"]), colour, 1.0)
	particles.lifetime = float(_spec["ember_lifetime"])
	particles.amount = kit.quota.count(int(float(_spec["embers_per_second"]) * particles.lifetime))
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles
