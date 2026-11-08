class_name DeathDrops
extends Node2D
## What a bound creature leaves behind when it dies, besides its light (see LightDrop):
## an optional burst effect (e.g. a toad's toxic goo), and sometimes a berry (which refills
## one Trainer's Aid charge). The creature calls `drop` when it dies.
## A Node2D so it sits on the creature's feet: everything appears at this node's position.

## The burst shown when it dies (e.g. the toad's toxic splat); none if left empty.
@export var death_splat_scene: PackedScene
## A berry it sometimes drops (refills one Trainer's Aid charge).
@export var berry_scene: PackedScene
## Chance (0 to 1) of dropping a berry on death.
@export var berry_drop_chance: float = 0.25


func drop() -> void:
	_spawn_death_splat()
	_maybe_drop_berry()


func _spawn_death_splat() -> void:
	if death_splat_scene == null:
		return
	var splat: ToxicSplat = death_splat_scene.instantiate()
	_world().add_child(splat)
	splat.global_position = global_position
	splat.play()


func _maybe_drop_berry() -> void:
	if berry_scene == null or randf() > berry_drop_chance:
		return
	var berry: Node2D = berry_scene.instantiate()
	_world().add_child.call_deferred(berry)
	berry.set_deferred("global_position", global_position)


## The level the creature lives in, so drops stay behind when the creature is freed.
func _world() -> Node:
	return get_parent().get_parent()
