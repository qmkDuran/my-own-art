class_name PlayerController
extends Node
## Turns the keyboard into the player's wishes: WASD moves relative to the camera, Shift runs (a quick tap of it
## dashes), Space jumps.
## Esc frees the mouse, a click captures it again.

var _player: Player
var _camera: CameraRig
const MS_PER_SECOND: float = 1000.0

var enabled: bool = true
var _run_pressed_at: int = 0


func setup(player: Player, camera: CameraRig) -> void:
	name = "PlayerController"
	_player = player
	_camera = camera


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	_player.wish = _camera.flat_right() * input.x + _camera.flat_forward() * input.y
	_player.running = Input.is_action_pressed("run")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_player.jump()
	elif event.is_action_pressed("run"):
		_run_pressed_at = Time.get_ticks_msec()
	elif event.is_action_released("run") and Time.get_ticks_msec() - _run_pressed_at < Tuning.f("agility",
			"tap_seconds") * MS_PER_SECOND:
		_player.dash()
	elif event.is_action_pressed("free_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
