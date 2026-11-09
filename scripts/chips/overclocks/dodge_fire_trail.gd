extends Node
## Overclocked chip mod "Dodge leaves a short fire trail" (added by ChipEffects): every
## dodge lays a FireTrail along the leap, like a short Ember Hop. With Ember Hop learned
## its own (longer) trail already does this, so this one stays quiet.

## Seconds each patch keeps burning (Ember Hop's is 1.5).
const TRAIL_SECONDS := 0.8
const BURN_DAMAGE := 1
const BURN_SECONDS := 1.0
const TOUCH_RADIUS := 6.0
const PATCH_SPACING := 5.0

var _trail: FireTrail = null

@onready var _hopper: Node2D = get_parent()
@onready var _dodge: Dodge = get_parent().get_node(Dodge.NODE_NAME)
@onready var _ember_hop: EmberHop = get_parent().get_node_or_null("EmberHop")


func _physics_process(_delta: float) -> void:
	if not _dodge.is_dodging:
		_trail = null
		return
	if _trail == null and not _ember_hop_is_learned():
		_start_trail()
	if is_instance_valid(_trail):
		_trail.lay_patch_at(_hopper.global_position)


func _ember_hop_is_learned() -> bool:
	return _ember_hop != null and _ember_hop.is_unlocked()


func _start_trail() -> void:
	_trail = FireTrail.new()
	_trail.patch_lifetime = TRAIL_SECONDS
	_trail.burn_damage = BURN_DAMAGE
	_trail.burn_duration = BURN_SECONDS
	_trail.touch_radius = TOUCH_RADIUS
	_trail.patch_spacing = PATCH_SPACING
	# Added to the world, not the hopper, so the fire stays where it was laid.
	_hopper.get_parent().add_child(_trail)
