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
	var player_input := _caster.get_node("PlayerInput") as PlayerInput
	var to_cursor := player_input.get_aim_point() - _caster.global_position
	var landing := _caster.global_position + to_cursor.limit_length(max_range)
	PoisonPuddle.spawn(_caster.get_parent(), _body_position(), landing, puddle_radius, puddle_seconds)
