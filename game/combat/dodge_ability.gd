class_name DodgeAbility
extends Ability
## Dodge roll: a quick dash with a full-body roll; the roller cannot be hurt while rolling. Long-ish cooldown, so
## it is a decision, not a spam button.


func _init(owner: Creature) -> void:
	super(owner, 0.0, Tuning.f("dodge", "duration"), Tuning.f("dodge", "recovery"), Tuning.f("dodge", "cooldown"))


func protects() -> bool:
	return phase == Phase.ACTIVE


func _on_release() -> void:
	var direction: Vector3 = creature.dodge_direction()
	var speed: float = Tuning.f("dodge", "distance") / Tuning.f("dodge", "duration")
	creature.dash(direction * speed, Tuning.f("dodge", "duration"))
	NoiseBus.emit_noise(creature, creature.global_position, Tuning.f("noise", "dodge_radius"), "dodge")
