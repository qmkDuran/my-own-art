class_name Blocks
## Box-shaped town pieces shared by the builders: a box that can be visible (with a material), solid (with a
## collider) or both, optionally turned to face along a direction, and a wall running between two ground points.
## Floors carry what they are made of, for footsteps.

const DEFAULT_SURFACE: String = "cobbles"
const PROBE_UP: float = 0.3
const PROBE_DOWN: float = 0.6


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


## Tags the floor bodies under a node with what they are made of (footsteps sound of it): cobbles, wood, grass.
static func mark_surface(holder: Node, surface: String) -> void:
	for body: Node in holder.find_children("*", "StaticBody3D", true, false):
		body.set_meta("surface", surface)
	if holder is StaticBody3D:
		holder.set_meta("surface", surface)


## The surface under a point (what a footstep there sounds of); cobbles when nothing says otherwise.
static func surface_at(world: World3D, at: Vector3) -> String:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * PROBE_UP, at + Vector3.DOWN * PROBE_DOWN,
		Layers.WORLD)
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return DEFAULT_SURFACE
	return String((hit["collider"] as Node).get_meta("surface", DEFAULT_SURFACE))


## A solid wall from a to b (ground points), visible with a material, an invisible collider with null.
static func wall_between(parent: Node3D, a: Vector3, b: Vector3, height: float, width: float,
		material: Material) -> void:
	var centre: Vector3 = (a + b) * 0.5 + Vector3.UP * height * 0.5
	var holder: Node3D = box(parent, centre, Vector3(width, height, a.distance_to(b) + width), material, true,
		a.direction_to(b))
	holder.get_child(holder.get_child_count() - 1).set_meta("invisible_wall", material == null)
