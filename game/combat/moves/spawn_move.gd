class_name SpawnMove
extends Move
## Moves that change the woods: Smoke Puff (a cloud to hide in), Bramble Wall (a wall that blocks movement, sight and
## spit) and Sprout Cover (a fresh tall-grass patch). Each lasts a while, then fades.

const WALL_AHEAD: float = 1.6


func _on_release() -> void:
	var size: float = number("size")
	var lifetime: float = number("lifetime")
	match String(spec["spawn"]):
		"smoke":
			creature.woods.spawn_smoke(creature.global_position, size, lifetime)
		"wall":
			creature.woods.spawn_wall(creature.global_position + creature.forward() * WALL_AHEAD, creature.forward(),
					size, lifetime)
		"grass":
			creature.woods.spawn_grass(creature.global_position, size, lifetime)
