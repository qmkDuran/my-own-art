class_name Dissolve
extends RefCounted
## Dissolves a model into light: every mesh under it gets the dissolve shader (its own texture eaten away by
## noise, with a warm glowing edge) and the dissolve runs from 0 to 1 over a time, then a callback runs.

const SHADER: Shader = preload("res://shaders/vfx_dissolve.gdshader")
const TEXTURE_KEY: String = "albedo_tex"


static func run(model: Node3D, spec: Dictionary, done: Callable) -> void:
	var materials: Array[ShaderMaterial] = []
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter(TEXTURE_KEY, _texture_of(mesh))
		material.set_shader_parameter("edge_color", Tuning.color(spec["edge_color"]))
		material.set_shader_parameter("edge_width", float(spec["edge_width"]))
		material.set_shader_parameter("edge_energy", float(spec["edge_energy"]))
		mesh.material_override = material
		materials.append(material)
	var tween: Tween = model.create_tween()
	tween.tween_method(func(value: float) -> void:
		for material: ShaderMaterial in materials:
			material.set_shader_parameter("progress", value), 0.0, 1.0, float(spec["seconds"]))
	tween.tween_callback(done)


static func _texture_of(mesh: MeshInstance3D) -> Texture2D:
	var material: Material = mesh.get_surface_override_material(0)
	if material == null:
		material = mesh.mesh.surface_get_material(0)
	if material is ShaderMaterial:
		return (material as ShaderMaterial).get_shader_parameter(TEXTURE_KEY)
	if material is BaseMaterial3D:
		return (material as BaseMaterial3D).albedo_texture
	return null
