class_name EmberHop
extends Node
## Ember Hop (Ember Tree, Flurry): once learned, every dodge leaves a trail of fire on the
## ground for `trail_duration` seconds. Enemies that touch it start Burning.
##
## Watches the Dodge (it has no signals) and lays a FireTrail along the leap. Its numbers fill
## the Ember Hop facts in the tree.

## Seconds each patch of the trail keeps burning after it is laid.
@export var trail_duration: float = 1.5
## Damage the burn deals each second, and how long it lasts.
@export var burn_damage: int = 1
@export var burn_duration: float = 2.0
## How close an enemy's feet must come to the trail to catch fire, in pixels.
@export var touch_radius: float = 6.0
## Distance between the trail's patches, in pixels.
@export var patch_spacing: float = 5.0
@export var dodge: Dodge

var _trail: FireTrail = null

@onready var _hopper: Node2D = get_parent()


## Whether Ember Hop is learned in the Ember Tree (this node's name is its skill action).
func is_unlocked() -> bool:
	return EmberTree.is_skill_unlocked(name)


func _physics_process(_delta: float) -> void:
	if not dodge.is_dodging:
		_trail = null
		return
	if _trail == null and is_unlocked():
		_start_trail()
	if is_instance_valid(_trail):
		_trail.lay_patch_at(_hopper.global_position)


func _start_trail() -> void:
	_trail = FireTrail.new()
	_trail.patch_lifetime = trail_duration
	_trail.burn_damage = burn_damage
	_trail.burn_duration = burn_duration
	_trail.touch_radius = touch_radius
	_trail.patch_spacing = patch_spacing
	# Added to the world, not the hopper, so the fire stays where it was laid.
	_hopper.get_parent().add_child(_trail)
