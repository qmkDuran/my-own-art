class_name Trainer
extends Node2D
## The player's trainer, who supports Emberoo through the spirit link (Trainer's Aid).
##
## This is the part every trainer body shares: TrainerAid finds the trainer through the
## "trainer" group and asks it to throw a healing tonic. The bodies are the UnseenTrainer
## (in the HUD during play: off screen, never drawn) and the parked WalkingTrainer (follows
## Emberoo in the world; kept for towns).

@export var tonic_scene: PackedScene


func _ready() -> void:
	add_to_group("trainer")


## Throws a healing tonic at the creature; `on_land` runs when it arrives.
func toss_tonic(at: Node2D, on_land: Callable) -> void:
	if tonic_scene == null:
		on_land.call()
		return
	var tonic: TonicToss = tonic_scene.instantiate()
	# Added to the creature's world, so the tonic flies among the world's sprites.
	at.get_parent().add_child(tonic)
	tonic.global_position = tonic_launch_point(at)
	tonic.fly_to(at, on_land)


## Where the tonic thrown at `_at` leaves the trainer's hands, in world coordinates.
func tonic_launch_point(_at: Node2D) -> Vector2:
	return global_position + Vector2(0, -14)
