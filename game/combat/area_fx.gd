class_name AreaFx
extends MeshInstance3D
## A flat ring that sweeps out to a move's radius and fades: shockwaves, spins, growls, echo pulses, pop-ups.

const RING_WIDTH: float = 0.25
const GROW_TIME: float = 0.35
const FADE_TIME: float = 0.4
const LIFT: float = 0.15
const RING_ALPHA: float = 0.7


static func spawn(parent: Node, at: Vector3, radius: float, color: Color) -> void:
	var fx := AreaFx.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 1.0 - RING_WIDTH / radius
	ring.outer_radius = 1.0
	fx.mesh = ring
	var material: StandardMaterial3D = WoodsMaterials.glow(color, RING_ALPHA)
	fx.material_override = material
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(fx)
	fx.global_position = at + Vector3.UP * LIFT
	fx.scale = Vector3.ONE * Ability.MIN_TIME
	var tween: Tween = fx.create_tween()
	tween.tween_property(fx, "scale", Vector3(radius, 1.0, radius), GROW_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, FADE_TIME)
	tween.tween_callback(fx.queue_free)
