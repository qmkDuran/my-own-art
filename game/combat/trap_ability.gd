class_name TrapAbility
extends Ability
## Snare: kneel for about a second (noisy, standing still) to set one hidden snare at your feet. Only one snare at a
## time; setting a new one removes the old. Anyone who saw or heard it being set knows where it is.

const PLACE_AHEAD: float = 0.7

var place_spot: Vector3 = Vector3.ZERO
var snare: SnareTrap


func _init(owner: Creature) -> void:
	super(owner, Tuning.f("trap", "place_time"), 0.0, 0.0, Tuning.f("trap", "cooldown"))


func _on_start() -> void:
	place_spot = creature.global_position + creature.forward() * PLACE_AHEAD
	creature.stealth.reveal()
	NoiseBus.emit_noise(creature, place_spot, Tuning.f("trap", "noise_radius"), "trap")


func _on_release() -> void:
	if is_instance_valid(snare):
		snare.queue_free()
	snare = SnareTrap.new()
	snare.setup(creature, place_spot)
	creature.get_parent().add_child(snare)
