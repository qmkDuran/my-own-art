class_name PlayerInput
extends Node
## Reads the player's controls and turns them into intentions.
##
## Only this component knows about keys and gamepads. Everything else asks it
## "what does the player want?" so controls can change without touching gameplay.


func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Holding the button keeps attacking, like an ARPG basic attack.
func wants_to_attack() -> bool:
	return Input.is_action_pressed("attack")


func wants_to_dodge() -> bool:
	return Input.is_action_just_pressed("dodge")


## Where the mouse cursor is in the game world. Attacks aim here.
func get_aim_point() -> Vector2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
