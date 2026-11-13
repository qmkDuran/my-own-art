class_name TraceFx
extends MeshInstance3D
## The honest trace of a hidden mover: a puff of dust over a burrower, a bubble over a swimmer. Rises and fades.

const SIZE: float = 0.35
const RISE: float = 0.8
const LIFE: float = 1.2
const DUST: Color = Color(0.55, 0.42, 0.28, 0.75)
const BUBBLE: Color = Color(0.8, 0.95, 1.0, 0.7)


static func spawn(parent: Node, at: Vector3, dust: bool) -> void:
	var fx := TraceFx.new()
	var ball := SphereMesh.new()
	ball.radius = SIZE * (1.0 if dust else 0.5)
	ball.height = ball.radius * 2.0
	fx.mesh = ball
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = DUST if dust else BUBBLE
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fx.material_override = material
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(fx)
	fx.global_position = at
	fx.add_to_group("traces")
	var tween: Tween = fx.create_tween().set_parallel(true)
	tween.tween_property(fx, "position:y", at.y + RISE, LIFE)
	tween.tween_property(material, "albedo_color:a", 0.0, LIFE)
	tween.chain().tween_callback(fx.queue_free)
