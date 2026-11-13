class_name RibbonTrail
extends MeshInstance3D
## A soft ribbon trail behind a moving thing (pure Godot): remembers the last few positions and draws a strip
## facing the camera that tapers and fades from the head to the tail; once left behind, it shrinks away.

const HEAD_STRENGTH: float = 0.6

var _target: Node3D
var _points: Array[Vector3] = []
var _max_points: int = 0
var _width: float = 0.0
var _colour: Color
var _mesh := ImmediateMesh.new()


func setup(target: Node3D, colour: Color, width: float, points: int) -> void:
	name = "RibbonTrail"
	top_level = true
	_target = target
	_colour = colour
	_width = width
	_max_points = points
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material


func _process(_delta: float) -> void:
	if is_instance_valid(_target) and _target.is_inside_tree() and _target.get_parent() != null:
		_points.push_front(_target.global_position)
	elif not _points.is_empty():
		_points.pop_back()
	if _points.size() > _max_points:
		_points.pop_back()
	global_transform = Transform3D.IDENTITY
	_draw()


func _draw() -> void:
	_mesh.clear_surfaces()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if _points.size() < 2 or camera == null:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for index: int in _points.size():
		var share: float = float(index) / (_points.size() - 1)
		var along: Vector3 = _points[maxi(index - 1, 0)] - _points[mini(index + 1, _points.size() - 1)]
		var facing: Vector3 = camera.global_position - _points[index]
		var side: Vector3 = along.cross(facing).normalized() * _width * 0.5 * (1.0 - share)
		var colour: Color = _colour * HEAD_STRENGTH * (1.0 - share) * (1.0 - share)
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(_points[index] + side)
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(_points[index] - side)
	_mesh.surface_end()
