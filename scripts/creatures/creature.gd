class_name Creature
extends CharacterBody2D
## A creature the player controls through the spirit link.
##
## This script only coordinates. Each job lives in its own child component:
##   PlayerInput -> what the player wants
##   Movement    -> how fast to move
##   Facing      -> which way to look
##   Sprite      -> what to show

## Below this speed (pixels per second) the creature counts as standing still.
const STANDING_STILL_SPEED := 1.0

@onready var player_input: PlayerInput = $PlayerInput
@onready var movement: Movement = $Movement
@onready var facing: Facing = $Facing
@onready var animator: CreatureAnimator = $Sprite


func _physics_process(delta: float) -> void:
	var move_direction := player_input.get_move_direction()

	velocity = movement.calculate_velocity(velocity, move_direction, delta)
	move_and_slide()

	facing.look_toward(move_direction)
	animator.show_animation(_current_action(), facing)


func _current_action() -> String:
	if _is_moving():
		return "hop"
	return "idle"


func _is_moving() -> bool:
	return velocity.length() > STANDING_STILL_SPEED
