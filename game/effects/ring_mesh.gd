class_name RingMesh
## A flat glowing ring lying on the ground (the relight progress ring, the bell chime's pulse).

const LIFT: float = 0.05
const INNER_SHARE: float = 0.85
const ENERGY: float = 1.2


static func make(colour: Color) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = INNER_SHARE
	torus.outer_radius = 1.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = colour * ENERGY
	torus.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = torus
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.scale = Vector3(1.0, LIFT, 1.0)
	return mesh
