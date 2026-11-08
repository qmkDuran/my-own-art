class_name AttackWarning
extends Line2D
## A faint line showing where an attack is about to strike, so the player can react.
##
## It grows from the attacker out to full length while the attack winds up.

## Where the line starts, relative to the attacker's feet (e.g. the toad's mouth).
@export var start_offset: Vector2 = Vector2(0, -5)


func _ready() -> void:
	hide_warning()


## progress: 0.0 = just started winding up, 1.0 = about to strike.
func show_warning(direction: Vector2, length: float, progress: float) -> void:
	visible = true
	var end := start_offset + direction.normalized() * length * clampf(progress, 0.0, 1.0)
	points = PackedVector2Array([start_offset, end])


func hide_warning() -> void:
	visible = false
	clear_points()
