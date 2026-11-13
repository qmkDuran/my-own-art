class_name PlayerController
extends Node
## Turns the keyboard into the player's wishes: WASD moves relative to the camera, Shift runs, V dashes, Space
## jumps.
## Esc frees the mouse, a click captures it again.

var _player: Player
var _camera: CameraRig
var enabled: bool = true


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


## Lets go of every key (the player stands still while fly mode or a test takes over).
func stop() -> void:
	_player.wish = Vector3.ZERO
	_player.running = false


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event.is_action_pressed("jump"):
		_player.jump()
	elif event.is_action_pressed("dash"):
		_player.dash()
	elif event.is_action_pressed("free_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
