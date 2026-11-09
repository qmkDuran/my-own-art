class_name Trainer
extends Node2D
## The player's trainer, who supports Emberoo through the spirit link (Trainer's Aid).
##
## This is the part every trainer body shares: TrainerAid finds the trainer through the
## "trainer" group and asks it to throw a healing tonic. The bodies are the TrainerPortrait
## (a portrait frame in the HUD) and the parked WalkingTrainer (follows Emberoo in the world).

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
	tonic.global_position = tonic_launch_point()
	tonic.fly_to(at, on_land)


## Where the tonic leaves the trainer's hands, in world coordinates.
func tonic_launch_point() -> Vector2:
	return global_position + Vector2(0, -14)
