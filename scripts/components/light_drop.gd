class_name LightDrop
extends Node
## Frees the Glimra light trapped in a bound creature (or a Warden's stolen stock)
## when it dies: a burst of light motes that fly to the player as XP.

@export var mote_scene: PackedScene
## How many motes burst out.
@export var mote_count: int = 3
## XP each mote is worth.
@export var xp_per_mote: int = 1
## Where on the body the motes burst from (relative to the feet).
@export var burst_offset: Vector2 = Vector2(0, -6)

@onready var owner_body: Node2D = get_parent()


func _ready() -> void:
	var health: Health = owner_body.get_node("Health")
	health.died.connect(_burst)


func _burst() -> void:
	if mote_scene == null:
		return
	for mote_number in mote_count:
		var mote: LightMote = mote_scene.instantiate()
		mote.xp_value = xp_per_mote
		owner_body.get_parent().add_child.call_deferred(mote)
		mote.set_deferred("global_position", owner_body.global_position + burst_offset)
