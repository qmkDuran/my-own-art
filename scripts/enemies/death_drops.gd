class_name DeathDrops
extends Node2D
## What a machine leaves behind when it dies, besides its light (see LightDrop) and its blast
## (MachineDeath): sometimes a berry (which refills one Trainer's Aid charge). The machine
## calls `drop` when it dies.
## A Node2D so it sits on the machine's feet: the berry appears at this node's position.

## A berry it sometimes drops (refills one Trainer's Aid charge).
@export var berry_scene: PackedScene
## Chance (0 to 1) of dropping a berry on death.
@export var berry_drop_chance: float = 0.25


func drop() -> void:
	if berry_scene == null or randf() > berry_drop_chance:
		return
	var berry: Node2D = berry_scene.instantiate()
	_world().add_child.call_deferred(berry)
	berry.set_deferred("global_position", global_position)


## The level the machine lives in, so drops stay behind when the machine is freed.
func _world() -> Node:
	return get_parent().get_parent()
