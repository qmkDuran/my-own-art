class_name CameraRig
extends Node3D
## Third-person orbit camera: follows the player over the shoulder, mouse look for yaw and pitch, and a spring
## arm that pulls in rather than clip through houses and walls. In combat it tightens over the shoulder while
## aiming, turns to follow a locked-on enemy, kicks up a touch with each shot, and pulls far back for the Sunrise.

var camera: Camera3D
var yaw: float = 0.0
var pitch: float = 0.0
var _follow: Node3D
var _pivot: Node3D
var _arm: SpringArm3D
## Combat: aiming tightens the view; super_mix (0..1) pulls it back for the Sunrise; lock_target is followed.
var aiming: bool = false
var super_mix: float = 0.0
var lock_target: Node3D
var _aim: float = 0.0
var _recoil: float = 0.0


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


## A small upward kick (a shot's recoil) that settles back on its own.
func kick(amount: float) -> void:
	_recoil += amount


func _physics_process(delta: float) -> void:
	_aim = move_toward(_aim, 1.0 if aiming else 0.0, Tuning.number("combat", "camera", "blend_sharpness") * delta *
		0.5)
	_recoil = lerpf(_recoil, 0.0, clampf(Tuning.number("combat", "camera", "kick_return") * delta, 0.0, 1.0))
	_follow_lock(delta)
	_frame()
	position = position.lerp(_anchor(), clampf(Tuning.f("camera", "follow_sharpness") * delta, 0.0, 1.0))
	_apply_rotation()


## Distance, shoulder offset, height and field of view, blended between walking, aiming and the super.
func _frame() -> void:
	var aim: float = smoothstep(0.0, 1.0, _aim)
	var pull: float = smoothstep(0.0, 1.0, super_mix)
	_arm.spring_length = lerpf(lerpf(Tuning.f("camera", "distance"), Tuning.number("combat", "camera",
		"aim_distance"), aim), Tuning.number("combat", "camera", "super_distance"), pull)
	_arm.position.x = lerpf(Tuning.f("camera", "shoulder_offset"), Tuning.number("combat", "camera", "aim_shoulder"),
		aim) * (1.0 - pull)
	camera.fov = lerpf(lerpf(Tuning.f("camera", "fov"), Tuning.number("combat", "camera", "aim_fov"), aim),
		Tuning.number("combat", "camera", "super_fov"), pull)


func _follow_lock(delta: float) -> void:
	if lock_target == null or not is_instance_valid(lock_target):
		return
	var to: Vector3 = (lock_target as Enemy).centre() - _anchor()
	var turn: float = clampf(Tuning.number("combat", "aim", "lock_turn_sharpness") * delta, 0.0, 1.0)
	yaw = lerp_angle(yaw, atan2(-to.x, -to.z), turn)
	var goal_pitch: float = atan2(to.y, Vector2(to.x, to.z).length())
	pitch = lerpf(pitch, clampf(goal_pitch, Tuning.degrees("camera", "pitch_min_deg"), Tuning.degrees("camera",
		"pitch_max_deg")), turn)


func _apply_rotation() -> void:
	rotation.y = yaw
	_pivot.rotation.x = pitch + _recoil


func _anchor() -> Vector3:
	var height: float = lerpf(lerpf(Tuning.f("camera", "height"), Tuning.number("combat", "camera", "aim_height"),
		smoothstep(0.0, 1.0, _aim)), Tuning.number("combat", "camera", "super_height"), smoothstep(0.0, 1.0,
		super_mix))
	return _follow.global_position + Vector3.UP * height
