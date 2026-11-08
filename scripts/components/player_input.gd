class_name PlayerInput
extends Node
## Reads the player's controls and turns them into intentions.
##
## Controls: left mouse = move to the cursor (or attack the enemy you click on),
## right mouse = attack in place toward the cursor, Space = dodge, F = Trainer's Aid (heal),
## Q/W/E/R = skill slots 1-4. The arrow keys also move, for players who prefer it
## (not WASD: W is a skill key).
##
## Only this component knows about keys and gamepads. Everything else asks it
## "what does the player want?" so controls can change without touching gameplay.


func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Attack in place toward the cursor (right mouse). Holding keeps attacking.
func wants_to_attack() -> bool:
	return Input.is_action_pressed("attack")


## Left mouse: walk toward the cursor, or attack the enemy under it.
func just_clicked_to_move() -> bool:
	return Input.is_action_just_pressed("move_to_cursor")


func is_holding_move_click() -> bool:
	return Input.is_action_pressed("move_to_cursor")


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
