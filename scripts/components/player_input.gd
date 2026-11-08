class_name PlayerInput
extends Node
## Reads the player's controls and turns them into intentions.
##
## Only this component knows about keys and gamepads. Everything else asks it
## "what does the player want?" so controls can change without touching gameplay.


func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
