class_name FlyCamera
extends Camera3D
## Fly mode (F1): a free spectator camera like Minecraft's creative flight. WASD flies where you look, Space rises,
## Ctrl or C sinks, Shift is faster, the mouse looks around; it passes through everything. Turning it off returns
## to the player's own camera exactly where they were (the player waits, frozen, while you fly).

signal toggled(flying: bool)

var flying: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _player_camera: Camera3D
var _controller: PlayerController


func setup(player_camera: Camera3D, controller: PlayerController) -> void:
	name = "FlyCamera"
	_player_camera = player_camera
	_controller = controller
	fov = player_camera.fov
	process_mode = Node.PROCESS_MODE_ALWAYS


func toggle() -> void:
	flying = not flying
	_controller.enabled = not flying
	_controller.stop()
	if flying:
		global_transform = _player_camera.global_transform
		_yaw = global_rotation.y
		_pitch = global_rotation.x
		current = true
	else:
		_player_camera.current = true
	toggled.emit(flying)


func _unhandled_input(event: InputEvent) -> void:
	if not flying or not event is InputEventMouseMotion or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion: Vector2 = (event as InputEventMouseMotion).relative * Tuning.f("camera", "mouse_sensitivity")
	_yaw -= motion.x
	_pitch = clampf(_pitch - motion.y, -PI * 0.5, PI * 0.5)


func _process(delta: float) -> void:
	if not flying:
		return
	rotation = Vector3(_pitch, _yaw, 0.0)
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var lift: float = Input.get_action_strength("jump") - Input.get_action_strength("fly_down")
	var move: Vector3 = global_basis.x * input.x - global_basis.z * input.y + Vector3.UP * lift
	var speed: float = Tuning.f("fly", "fast_speed" if Input.is_action_pressed("run") else "speed")
	global_position += move.limit_length(1.0) * speed * delta
