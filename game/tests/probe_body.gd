class_name ProbeBody
extends CharacterBody3D
## A stand-in for the player in the collision tests: the same capsule, collision mask, gravity and run speed, but
## no model, so hundreds can run at once. It walks towards a goal (or in a heading) and can tell if it has ended up
## inside the town's geometry.

const INSET: float = 0.06

var goal: Vector3 = Vector3.INF
var heading: Vector3 = Vector3.ZERO
var speed: float = 0.0
var _capsule: CapsuleShape3D


func _init() -> void:
	collision_layer = 0
	collision_mask = Layers.WORLD
	floor_snap_length = Tuning.f("player", "capsule_radius")
	_capsule = CapsuleShape3D.new()
	_capsule.radius = Tuning.f("player", "capsule_radius")
	_capsule.height = Tuning.f("player", "capsule_height")
	var shape := CollisionShape3D.new()
	shape.shape = _capsule
	shape.position.y = _capsule.height * 0.5
	add_child(shape)
	speed = Tuning.f("player", "run_speed")


func _physics_process(delta: float) -> void:
	var direction: Vector3 = heading
	if goal != Vector3.INF:
		direction = Vector3(goal.x - global_position.x, 0.0, goal.z - global_position.z)
		direction = direction.normalized() if direction.length() > speed * delta else Vector3.ZERO
	var fall: float = 0.0 if is_on_floor() else velocity.y - Tuning.f("player", "gravity") * delta
	velocity = direction * speed + Vector3.UP * fall
	move_and_slide()


## True when a slightly slimmer copy of the capsule overlaps any wall, house, prop or floor.
func is_inside_geometry() -> bool:
	var slim := CapsuleShape3D.new()
	slim.radius = _capsule.radius - INSET
	slim.height = _capsule.height - INSET * 4.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = slim
	query.collision_mask = Layers.WORLD
	query.transform = Transform3D(Basis(), global_position + Vector3.UP * (_capsule.height * 0.5 + INSET))
	var hits: Array[Dictionary] = get_world_3d().direct_space_state.intersect_shape(query, 1)
	if not hits.is_empty():
		var collider: Node = hits[0]["collider"]
		set_meta("inside", "%s/%s" % [collider.get_parent().name, collider.name])
	return not hits.is_empty()
