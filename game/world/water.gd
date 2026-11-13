class_name Water
## The pond and the stream that feeds it: a calm translucent surface sitting in the carved basin and along the
## ravine floor. Wading through it slows you; Submerge hides you under it; water puts fire out.

const RIBBON_STEP: float = 1.0
const DISC_SEGMENTS: int = 32
const SHINE: float = 0.08


static func build(parent: Node3D, woods: Woods) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Tuning.palette("water")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = SHINE
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pond: Dictionary = Tuning.woods["pond"]
	var centre: Vector2 = Tuning.vec2(pond["pos"])
	var disc := CylinderMesh.new()
	disc.top_radius = float(pond["radius"])
	disc.bottom_radius = float(pond["radius"])
	disc.height = SHINE
	disc.radial_segments = DISC_SEGMENTS
	var surface := MeshInstance3D.new()
	surface.name = "Pond"
	surface.mesh = disc
	surface.material_override = material
	surface.position = woods.ground_at(centre) + Vector3.UP * float(pond["depth"])
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(surface)
	parent.add_child(_stream(woods, material))


static func _stream(woods: Woods, material: Material) -> MeshInstance3D:
	var stream: Dictionary = Tuning.woods["stream"]
	var half: float = float(stream["width"]) * 0.5
	var depth: float = float(stream["depth"])
	var points: Array = stream["points"]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in points.size() - 1:
		var a: Vector2 = Tuning.vec2(points[k])
		var b: Vector2 = Tuning.vec2(points[k + 1])
		var side: Vector2 = (b - a).normalized().orthogonal() * half
		var steps: int = maxi(1, int(a.distance_to(b) / RIBBON_STEP))
		for step: int in steps:
			var p0: Vector2 = a.lerp(b, float(step) / steps)
			var p1: Vector2 = a.lerp(b, float(step + 1) / steps)
			var quad: Array[Vector3] = [_at(woods, p0 - side, depth), _at(woods, p0 + side, depth),
				_at(woods, p1 + side, depth), _at(woods, p1 - side, depth)]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				tool.add_vertex(quad[corner])
	tool.generate_normals()
	var view := MeshInstance3D.new()
	view.name = "Stream"
	view.mesh = tool.commit()
	view.material_override = material
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return view


## The water surface over a point of the stream: the lower of the two banks' ground plus the depth.
static func _at(woods: Woods, p: Vector2, depth: float) -> Vector3:
	return Vector3(p.x, woods.shape.height(p.x, p.y) + depth, p.y)
