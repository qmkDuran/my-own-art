class_name Health
extends Node
## Hit points with damage, healing, death and short invulnerability after a hit.

signal changed(current: int, maximum: int)
signal damaged(amount: int, source: Node2D)
signal died

var maximum := 10
var current := 10
var invulnerable := false


func setup(max_value: int, start_value: int = -1) -> void:
	maximum = max_value
	current = max_value if start_value < 0 else clampi(start_value, 0, max_value)


func is_dead() -> bool:
	return current <= 0


func ratio() -> float:
	return float(current) / float(maxi(maximum, 1))


func take_damage(amount: int, source: Node2D = null) -> void:
	if invulnerable or is_dead():
		return
	current = maxi(current - amount, 0)
	changed.emit(current, maximum)
	damaged.emit(amount, source)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	if is_dead():
		return
	current = mini(current + amount, maximum)
	changed.emit(current, maximum)
