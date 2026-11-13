class_name ImpactBurst
extends Node3D
## Where a Lantern Flare lands: a soft light pop that lights the cobbles, an expanding ring on the ground (a soft
## ring shader, or the Blender swirl ring with a scrolling, dissolving glow), a burst of embers and a few curling
## smoke puffs (Godot sprites or Blender flipbooks), then an ember mark left on the stones. Frees itself.

const RING_SHADER: Shader = preload("res://shaders/vfx_ring.gdshader")
const SCROLL_SHADER: Shader = preload("res://shaders/vfx_scroll.gdshader")
const GROUND_LIFT: float = 0.04
const RING_ENERGY: float = 1.1
const SMOKE_DRIFT: float = 0.4
const EMBER_DRIFT: float = 0.6
const SPIN: float = 2.5
const FLASH_HEIGHT_SHARE: float = 0.2


func play(kit: VfxKit, spec: Dictionary, mark_spec: Dictionary, ground: Vector3) -> void:
	name = "ImpactBurst"
	var colour: Color = Tuning.color(spec["color"])
	var reach: float = spec["flash_range"]
	var flash: EffectLight = EffectLight.make(kit.quota, colour, float(spec["flash_energy"]), reach)
	if flash != null:
		add_child(flash)
		flash.position.y = reach * FLASH_HEIGHT_SHARE
		flash.fade_out(float(spec["flash_seconds"]))
	_ring(kit, spec, colour, ground)
	_bursts(kit, spec, colour)
	var mark := EmberMark.new()
	kit.place(mark, ground)
	mark.play(kit, mark_spec)
	get_tree().create_timer(float(spec["smoke_lifetime"]) * 2.0, false).timeout.connect(queue_free)


func _ring(kit: VfxKit, spec: Dictionary, colour: Color, ground: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var material := ShaderMaterial.new()
	material.set_shader_parameter("color", colour)
	material.set_shader_parameter("energy", RING_ENERGY)
	if kit.uses_blender():
		ring.mesh = kit.effect_mesh("swirl_ring")
		material.shader = SCROLL_SHADER
	else:
		var quad := PlaneMesh.new()
		quad.size = Vector2.ONE * 2.0
		ring.mesh = quad
		material.shader = RING_SHADER
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	ring.global_position = ground + Vector3.UP * GROUND_LIFT
	var size: float = spec["ring_size"]
	var seconds: float = spec["ring_seconds"]
	ring.scale = Vector3.ONE * size * 0.5
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3.ONE * size, seconds).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "rotation:y", SPIN, seconds)
	tween.tween_method(func(value: float) -> void: material.set_shader_parameter("progress", value), 0.0, 1.0, seconds)
	tween.chain().tween_callback(ring.queue_free)


func _bursts(kit: VfxKit, spec: Dictionary, colour: Color) -> void:
	var embers: int = kit.quota.count(int(spec["embers"]))
	var puffs: int = kit.quota.count(int(spec["smoke"]))
	var smoke_colour: Color = Tuning.color(spec["smoke_color"])
	if kit.uses_blender():
		var frames: Vector2i = kit.flipbook_frames()
		add_child(ParticleBursts.flipbook(kit.asset("ember_flipbook"), frames, 1, float(spec["flipbook_size"]),
			float(spec["flipbook_seconds"]), true, 0.0))
		add_child(ParticleBursts.flipbook(kit.asset("smoke_flipbook"), frames, puffs, float(spec["smoke_size"]),
			float(spec["smoke_lifetime"]), false, SMOKE_DRIFT))
		add_child(ParticleBursts.embers(embers / 2, colour, float(spec["ember_size"]), float(spec["ember_speed"]),
			float(spec["ember_lifetime"])))
		return
	add_child(ParticleBursts.embers(embers, colour, float(spec["ember_size"]), float(spec["ember_speed"]),
		float(spec["ember_lifetime"])))
	add_child(ParticleBursts.smoke(puffs, smoke_colour, float(spec["smoke_size"]), float(spec["smoke_lifetime"])))
