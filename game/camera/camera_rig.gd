class_name CameraRig
extends Node3D
## Third-person orbit camera: follows the player over the right shoulder, mouse look for yaw and pitch, a spring
## arm that pulls in rather than clip through trees, rocks or canopies, and a lock-on mode that keeps the target
## framed. Also answers where the crosshair is aiming.

var camera: Camera3D
var yaw: float = 0.0
var pitch: float = 0.0
var lock_target: Creature
var _follow: Creature
var _pivot: Node3D
var _arm: SpringArm3D


func setup(follow: Creature) -> void:
	_follow = follow
	name = "CameraRig"
	yaw = follow.yaw
	pitch = Tuning.degrees("camera", "start_pitch_deg")
	_pivot = Node3D.new()
	add_child(_pivot)
	_arm = SpringArm3D.new()
	_arm.spring_length = Tuning.f("camera", "distance")
	_arm.collision_mask = Layers.CAMERA_BLOCKERS
	_arm.margin = Tuning.f("camera", "collision_margin")
	var ball := SphereShape3D.new()
	ball.radius = Tuning.f("camera", "collision_margin")
	_arm.shape = ball
	_arm.position.x = Tuning.f("camera", "shoulder_offset")
	_arm.add_excluded_object(follow.get_rid())
	_pivot.add_child(_arm)
	camera = Camera3D.new()
	camera.fov = Tuning.f("camera", "fov")
	camera.current = true
	_arm.add_child(camera)
	snap()


## Jump straight to the follow position (start, restart, staged screenshots).
func snap() -> void:
	position = _anchor()
	_apply_rotation()


func flat_forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func flat_right() -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))


## Where a spit would go: the lock-on target, else whatever the crosshair points at.
func aim_point() -> Vector3:
	if lock_target != null:
		return lock_target.chest_position()
	var from: Vector3 = camera.global_position
	var to: Vector3 = from - camera.global_basis.z * Tuning.f("camera", "aim_distance")
	var query := PhysicsRayQueryParameters3D.create(from, to, Layers.PROJECTILE_HITS, [_follow.get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit["position"] if not hit.is_empty() else to


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion: Vector2 = (event as InputEventMouseMotion).relative * Tuning.f("camera", "mouse_sensitivity")
	if lock_target == null:
		yaw -= motion.x
	var lowest: float = Tuning.degrees("camera", "pitch_min_deg")
	pitch = clampf(pitch - motion.y, lowest, Tuning.degrees("camera", "pitch_max_deg"))


func _physics_process(delta: float) -> void:
	position = position.lerp(_anchor(), clampf(Tuning.f("camera", "follow_sharpness") * delta, 0.0, 1.0))
	if lock_target != null:
		_frame_target(delta)
	_apply_rotation()


func _frame_target(delta: float) -> void:
	var to_target: Vector3 = lock_target.global_position - _follow.global_position
	var goal_yaw: float = atan2(-to_target.x, -to_target.z)
	var blend: float = clampf(Tuning.f("camera", "lock_turn_sharpness") * delta, 0.0, 1.0)
	yaw = lerp_angle(yaw, goal_yaw, blend)
	pitch = lerpf(pitch, Tuning.degrees("camera", "lock_pitch_deg"), blend)


func _apply_rotation() -> void:
	rotation.y = yaw
	_pivot.rotation.x = pitch


func _anchor() -> Vector3:
	return _follow.global_position + Vector3.UP * Tuning.f("camera", "height")
