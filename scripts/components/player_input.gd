class_name PlayerInput
extends Node
## Reads the player's controls and turns them into intentions.
##
## Controls: left mouse = move to the cursor (or attack the enemy you click on),
## right mouse = attack in place toward the cursor, Shift + left mouse = attack in place too
## (like Path of Exile's "stand still" key), Space = dodge, F = Trainer's Aid (heal),
## Q/W/E/R = skill slots 1-4. The arrow keys also move, for players who prefer it
## (not WASD: W is a skill key).
##
## Only this component knows about keys and gamepads. Everything else asks it
## "what does the player want?" so controls can change without touching gameplay.

## How long an attack press is remembered while the creature is still busy, in seconds.
## A tap during a jab's recovery then starts the next jab the moment the current one ends.
@export var attack_buffer_time: float = 0.15

## Seconds left before a remembered attack press is forgotten (0 = nothing remembered).
var _attack_buffer_left: float = 0.0


func _ready() -> void:
	# Read the controls before the creature acts on them, so a press is
	# remembered (or used up) in the same physics frame it happens.
	process_physics_priority = -1


func _physics_process(delta: float) -> void:
	if _just_pressed_attack_in_place():
		_attack_buffer_left = attack_buffer_time
	else:
		_attack_buffer_left = maxf(0.0, _attack_buffer_left - delta)


func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Attack in place toward the cursor: right mouse, or Shift + left mouse.
## Holding keeps attacking; a tap while busy is remembered for a moment.
func wants_to_attack() -> bool:
	return Input.is_action_pressed("attack") or is_attacking_in_place_with_move_click() \
			or _attack_buffer_left > 0.0


## Forgets a remembered attack press, e.g. because a jab just used it.
func consume_attack_buffer() -> void:
	_attack_buffer_left = 0.0


## Shift + left mouse held: punch on the spot instead of walking.
func is_attacking_in_place_with_move_click() -> bool:
	return _is_holding_attack_in_place_modifier() and Input.is_action_pressed("move_to_cursor")


## Left mouse (without Shift): walk toward the cursor, or attack the enemy under it.
func just_clicked_to_move() -> bool:
	return Input.is_action_just_pressed("move_to_cursor") and not _is_holding_attack_in_place_modifier()


func is_holding_move_click() -> bool:
	return Input.is_action_pressed("move_to_cursor") and not _is_holding_attack_in_place_modifier()


## Shift: stand still. Pressing it stops a walk order on the spot (like PoE).
func is_holding_stand_still() -> bool:
	return _is_holding_attack_in_place_modifier()


func _is_holding_attack_in_place_modifier() -> bool:
	return Input.is_action_pressed("attack_in_place_modifier")


func _just_pressed_attack_in_place() -> bool:
	if Input.is_action_just_pressed("attack"):
		return true
	return _is_holding_attack_in_place_modifier() and Input.is_action_just_pressed("move_to_cursor")


## F: the trainer throws a healing tonic.
func wants_trainer_aid() -> bool:
	return Input.is_action_just_pressed("trainer_aid")


## Q, W, E or R: use the skill in slot 0, 1, 2 or 3.
func wants_skill(slot_index: int) -> bool:
	return Input.is_action_just_pressed("skill_%d" % (slot_index + 1))


func wants_to_dodge() -> bool:
	return Input.is_action_just_pressed("dodge")


## Where the mouse cursor is in the game world. Attacks aim here.
func get_aim_point() -> Vector2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
