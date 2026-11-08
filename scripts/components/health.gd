class_name Health
extends Node
## Tracks how much damage something can take before it dies.
##
## Other components listen to its signals (flash on hit, die at zero)
## instead of Health knowing about them.

signal damaged(amount: int, source_position: Vector2)
signal died
signal healed(amount: int)
signal max_health_changed(new_max_health: int)

@export var max_health: int = 3

## While true, damage is ignored (e.g. mid-dodge).
var is_invulnerable: bool = false

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int, source_position: Vector2) -> void:
	if is_invulnerable or is_dead():
		return

	current_health = maxi(0, current_health - amount)
	damaged.emit(amount, source_position)
	if is_dead():
		died.emit()


func heal(amount: int) -> void:
	if is_dead():
		return
	current_health = mini(max_health, current_health + amount)
	healed.emit(amount)


## Raises (or, with a negative amount, lowers) max health, e.g. from an Ember Tree stat.
## A raise also fills the new room, so the extra hits count straight away; a drop never kills.
func change_max_health(amount: int) -> void:
	max_health = maxi(1, max_health + amount)
	current_health = clampi(current_health + maxi(0, amount), 1, max_health)
	max_health_changed.emit(max_health)
	# Displays that only redraw on heals (the HUD heart) still pick up the new numbers.
	healed.emit(0)


func is_dead() -> bool:
	return current_health <= 0
