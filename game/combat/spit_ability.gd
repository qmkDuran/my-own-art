class_name SpitAbility
extends Ability
## Spit: a wind-up (head rears, a green glow gathers in the mouth), then a slow glob flies toward the aim point. It
## can miss and is stopped by trees, rocks and logs. Shooting downhill from high ground reaches a little further.

var ambush: bool = false


func _init(owner: Creature) -> void:
	super(owner, Tuning.f("spit", "windup"), 0.0, Tuning.f("spit", "recovery"), Tuning.f("spit", "cooldown"))


## How far a glob aimed at this point may travel (modest bonus when the shooter stands well above it).
func reach_toward(aim: Vector3) -> float:
	var reach: float = Tuning.f("spit", "range")
	if creature.mouth_position().y - aim.y >= Tuning.f("spit", "high_ground_min_drop"):
		reach *= Tuning.f("spit", "high_ground_range_factor")
	return reach


func _on_start() -> void:
	ambush = creature.ambush_ready()
	creature.announce_attack()


func _on_release() -> void:
	var from: Vector3 = creature.mouth_position()
	var aim: Vector3 = creature.aim_point
	var glob := SpitProjectile.new()
	glob.setup(creature, from, (aim - from).normalized(), reach_toward(aim), ambush)
	creature.get_parent().add_child(glob)
