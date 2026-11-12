class_name FlatMesh
## Turns a primitive mesh into a lumpy, flat-shaded low-poly mesh (rocks, canopies, bushes): each shared vertex is
## pushed in or out a little, then every triangle gets its own face normal,
## pointing away from the centre (primitives are centred on the origin).


const POSITION_KEY_SCALE: float = 1000.0


static func lumpy(source: PrimitiveMesh, rng: RandomNumberGenerator, lump: float) -> ArrayMesh:
	var arrays: Array = source.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var moved: Dictionary = {}
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in range(0, indices.size(), 3):
		var a: Vector3 = _jittered(vertices[indices[k]], moved, rng, lump)
		var b: Vector3 = _jittered(vertices[indices[k + 1]], moved, rng, lump)
		var c: Vector3 = _jittered(vertices[indices[k + 2]], moved, rng, lump)
		var face_normal: Vector3 = (c - a).cross(b - a).normalized()
		if face_normal.dot(a + b + c) < 0.0:
			face_normal = -face_normal
		for corner: Vector3 in [a, b, c]:
			tool.set_normal(face_normal)
			tool.add_vertex(corner)
	return tool.commit()


## The same position always gets the same push, so seams (poles, wrap) stay closed.
static func _jittered(v: Vector3, moved: Dictionary, rng: RandomNumberGenerator, lump: float) -> Vector3:
	var key: Vector3i = Vector3i((v * POSITION_KEY_SCALE).round())
	if not moved.has(key):
		moved[key] = v * (1.0 + rng.randf_range(-lump, lump))
	return moved[key]
