class_name GustShot
extends TimedAbility
## Zephoot's basic attack: puffs a fast gust orb toward the cursor (a WindShot) that hurts
## and nudges the first enemy it meets. The ranged member of the team: keep your distance.

## How far in front of its feet the orb appears, in pixels.
const MUZZLE_DISTANCE := 4.0

@export var shot_scene: PackedScene


func _land() -> void:
	var shot := shot_scene.instantiate() as WindShot
	_caster.get_parent().add_child(shot)
	shot.global_position = _caster.global_position + _aim_direction * MUZZLE_DISTANCE
	shot.launch(_aim_direction)


func guide_line() -> String:
	var shot := shot_scene.instantiate() as WindShot
	var line := "Fires a fast gust orb at the cursor: %d dmg and a nudge to the first enemy it meets." % shot.damage
	shot.free()
	return line
