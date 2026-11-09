class_name PoisonPuddleToss
extends TimedAbility
## Toxlop's skill: spits a glob of toxic goo at the cursor (up to `max_range` away); it lands
## as a PoisonPuddle that keeps poisoning every enemy standing in it. Good for holding a
## doorway or softening a pack before swapping to a hitter.

## Farthest the glob flies, in pixels.
@export var max_range: float = 80.0
@export var puddle_seconds: float = 4.0
@export var puddle_radius: float = 16.0


func _land() -> void:
	var landing := _toward(_aim_point(), max_range)
	PoisonPuddle.spawn(_caster.get_parent(), _body_position(), landing, puddle_radius, puddle_seconds)


func guide_line() -> String:
	return "Spits goo up to %d px: a puddle (%d px wide, %d s) Poisons every enemy standing in it." % [max_range, puddle_radius * 2.0, puddle_seconds]


func set_up_status() -> String:
	return SetUp.POISONED
