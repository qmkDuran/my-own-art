class_name StarPop
extends MeshInstance3D
## The crisp "pop" shape of an impact: a flat six-pointed star facing the camera, bright-but-coloured in the
## middle (warm amber) running out to orange tips, that snaps open and fades in a fraction of a second, over a
## soft halo. A clean stylised shape rather than a bigger glow. Frees itself.

const POINTS: int = 6
const INNER_SHARE: float = 0.32
const OPEN_FROM: float = 0.25
const TIP_ALPHA: float = 0.0
const HALO_SHARE: float = 0.5


func play(colour: Color, tip_colour: Color, size: float, seconds: float, energy: float) -> void:
	name = "StarPop"
	mesh = _star(colour * energy, Color(tip_colour.r, tip_colour.g, tip_colour.b, TIP_ALPHA) * energy)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(SoftGlow.make(colour, size * HALO_SHARE, energy))
	scale = Vector3.ONE * size * OPEN_FROM
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector3.ONE * size, seconds).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT)
	tween.tween_property(self, "rotation:z", PI / POINTS, seconds)
	tween.tween_property(material, "albedo_color", Color(1, 1, 1, 0), seconds).set_delay(seconds * 0.5)
	tween.chain().tween_callback(queue_free)


func _star(core: Color, tip: Color) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	for index: int in POINTS * 2:
		var here: float = TAU * index / (POINTS * 2)
		var next: float = TAU * (index + 1) / (POINTS * 2)
		var here_r: float = 1.0 if index % 2 == 0 else INNER_SHARE
		var next_r: float = 1.0 if (index + 1) % 2 == 0 else INNER_SHARE
		vertices.append_array([Vector3.ZERO, Vector3(cos(here), sin(here), 0) * here_r,
			Vector3(cos(next), sin(next), 0) * next_r])
		colours.append_array([core, tip if here_r == 1.0 else core.lerp(tip, INNER_SHARE),
			tip if next_r == 1.0 else core.lerp(tip, INNER_SHARE)])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colours
	var star := ArrayMesh.new()
	star.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return star
