class_name Blocks
## Box-shaped town pieces shared by the builders: a box that can be visible (with a material), solid (with a
## collider) or both, optionally turned to face along a direction, and a wall running between two ground points.


## A box centred at centre; with a facing, its length (z) runs along that direction.
static func box(parent: Node3D, centre: Vector3, size: Vector3, material: Material, collide: bool,
		facing: Vector3 = Vector3.ZERO) -> Node3D:
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = centre
	var flat := Vector3(facing.x, 0.0, facing.z)
	if flat.length_squared() > 0.0:
		holder.basis = Basis.looking_at(flat.normalized(), Vector3.UP)
	if material != null:
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = material
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		holder.add_child(instance)
	if collide:
		holder.add_child(solid(size))
	return holder


## A static body with one box shape of the given size, centred on its origin.
static func solid(size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	return body


## A solid wall from a to b (ground points), visible with a material, an invisible collider with null.
static func wall_between(parent: Node3D, a: Vector3, b: Vector3, height: float, width: float,
		material: Material) -> void:
	var centre: Vector3 = (a + b) * 0.5 + Vector3.UP * height * 0.5
	box(parent, centre, Vector3(width, height, a.distance_to(b) + width), material, true, a.direction_to(b))
