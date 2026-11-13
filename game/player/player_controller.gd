class_name PlayerController
extends Node
## Turns keyboard and mouse into the player creature's intent: WASD relative to the camera (strafing around the
## target when locked on), Shift to sneak, the four equipped moves on left click, right click, Q and E, Space to
## roll, Tab to lock on.

var _player: Creature
var _rig: CameraRig
var _lock_on: LockOn


func setup(player: Creature, rig: CameraRig, lock_on: LockOn) -> void:
	_player = player
	_rig = rig
	_lock_on = lock_on
	name = "PlayerController"


func _physics_process(_delta: float) -> void:
	if _player.is_dead():
		_player.move_intent = Vector3.ZERO
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	_player.move_intent = _rig.flat_right() * input.x + _rig.flat_forward() * input.y
	_player.sneaking = Input.is_action_pressed("sneak")
	_player.aim_point = _aim_point()
	_player.has_look_target = _lock_on.target_locked()
	if _player.has_look_target:
		_player.look_target = _lock_on.target.global_position
	_read_actions()


func _read_actions() -> void:
	if Input.is_action_just_pressed("lock_on"):
		_lock_on.toggle()
	for slot: int in MoveLibrary.SLOTS:
		if Input.is_action_just_pressed("move_%d" % (slot + 1)):
			_player.try_move(slot)
	if Input.is_action_just_pressed("dodge"):
		_player.try_roll()


## The crosshair point (or the locked target); never a point behind the player, so moves always go forward.
func _aim_point() -> Vector3:
	var aim: Vector3 = _rig.aim_point()
	if (aim - _player.global_position).dot(_rig.flat_forward()) <= 0.0:
		aim = _player.chest_position() + _rig.flat_forward() * Tuning.f("camera", "aim_distance")
	return aim
