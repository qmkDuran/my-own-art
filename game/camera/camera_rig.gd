class_name CameraRig
extends Node3D
## Third-person orbit camera: follows the player over the shoulder, mouse look for yaw and pitch, and a spring
## arm that pulls in rather than clip through houses and walls.

var camera: Camera3D
var yaw: float = 0.0
var pitch: float = 0.0
var _follow: Node3D
var _pivot: Node3D
var _arm: SpringArm3D


func setup(follow: CollisionObject3D, start_yaw: float) -> void:
	_follow = follow
	name = "CameraRig"
	yaw = start_yaw
	pitch = Tuning.degrees("camera", "start_pitch_deg")
	_pivot = Node3D.new()
	add_child(_pivot)
	_arm = SpringArm3D.new()
	_arm.spring_length = Tuning.f("camera", "distance")
	_arm.collision_mask = Layers.WORLD
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


## Jump straight to the follow position (start, staged screenshots).
func snap() -> void:
	position = _anchor()
	_apply_rotation()


func flat_forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func flat_right() -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion: Vector2 = (event as InputEventMouseMotion).relative * Tuning.f("camera", "mouse_sensitivity")
	yaw -= motion.x
	var lowest: float = Tuning.degrees("camera", "pitch_min_deg")
	pitch = clampf(pitch - motion.y, lowest, Tuning.degrees("camera", "pitch_max_deg"))


func _physics_process(delta: float) -> void:
	position = position.lerp(_anchor(), clampf(Tuning.f("camera", "follow_sharpness") * delta, 0.0, 1.0))
	_apply_rotation()


func _apply_rotation() -> void:
	rotation.y = yaw
	_pivot.rotation.x = pitch


func _anchor() -> Vector3:
	return _follow.global_position + Vector3.UP * Tuning.f("camera", "height")
