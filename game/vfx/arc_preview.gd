class_name ArcPreview
extends Node3D
## While the bomb is held: a dotted teal arc from the lantern to where it will land (the dots drift along it), and a
## soft ring on the ground showing the blast's reach.

const DRIFT_SPEED: float = 1.5

var _dots: MultiMeshInstance3D
var _ring: MeshInstance3D
var _arc: BombArc
var _clock: float = 0.0


func setup(spec: Dictionary, count: int, radius: float) -> void:
	name = "ArcPreview"
	top_level = true
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = SphereMesh.new()
	(multi.mesh as SphereMesh).radius = float(spec["preview_dot"])
	(multi.mesh as SphereMesh).height = float(spec["preview_dot"]) * 2.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Tuning.color(spec["preview"]) * float(spec["preview_energy"])
	multi.mesh.surface_set_material(0, material)
	multi.instance_count = count
	_dots = MultiMeshInstance3D.new()
	_dots.multimesh = multi
	_dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_dots)
	_ring = RingMesh.make(Tuning.color(spec["preview"]) * float(spec["preview_energy"]))
	_ring.scale = Vector3(radius, RingMesh.LIFT, radius)
	add_child(_ring)


func show_arc(arc: BombArc) -> void:
	_arc = arc
	global_transform = Transform3D.IDENTITY
	_ring.global_position = arc.landing + Vector3.UP * RingMesh.LIFT


func _process(delta: float) -> void:
	_clock += delta * DRIFT_SPEED
	if _arc == null:
		return
	var count: int = _dots.multimesh.instance_count
	for index: int in count:
		var share: float = fmod((index + fmod(_clock, 1.0)) / count, 1.0)
		_dots.multimesh.set_instance_transform(index, Transform3D(Basis(), _arc.point_at(share * _arc.landing_time)))
