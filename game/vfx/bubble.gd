class_name Bubble
extends MeshInstance3D
## A protective bubble (vfx_bubble shader): the player's warm ward or an elite's moonlit shield. It pops open,
## ripples from where something strikes it, shows cracks as it weakens, and fades away.

const SHADER: Shader = preload("res://shaders/vfx_bubble.gdshader")
const OPEN_SECONDS: float = 0.22
const OPEN_FROM: float = 0.2
const SEGMENTS: int = 32

var _material: ShaderMaterial
var _hit_age: float = 10.0


func setup(spec: Dictionary, radius: float) -> void:
	name = "Bubble"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = SEGMENTS
	sphere.rings = SEGMENTS / 2
	mesh = sphere
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("color", Tuning.color(spec["color"]))
	_material.set_shader_parameter("edge_color", Tuning.color(spec["edge"]))
	_material.set_shader_parameter("ripple_color", Tuning.color(spec["ripple_color"]))
	_material.set_shader_parameter("energy", float(spec["energy"]))
	_material.set_shader_parameter("hex_scale", float(spec["hex_scale"]))
	_material.set_shader_parameter("fresnel_power", float(spec["fresnel"]))
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scale = Vector3.ONE * OPEN_FROM
	create_tween().tween_property(self, "scale", Vector3.ONE, OPEN_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT)


## A ripple ringing out from a world point on the bubble.
func ripple(at: Vector3) -> void:
	_hit_age = 0.0
	_material.set_shader_parameter("hit_dir", global_basis.inverse() * (at - global_position))


func set_crack(amount: float) -> void:
	_material.set_shader_parameter("crack", amount)


func set_strength(amount: float) -> void:
	_material.set_shader_parameter("strength", amount)


func _process(delta: float) -> void:
	_hit_age += delta
	_material.set_shader_parameter("hit_age", _hit_age)
