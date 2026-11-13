class_name SuperMeter
extends RefCounted
## The Sunrise super's charge: it fills with the damage the player deals (data/combat.json super.cost is a full
## meter) and is spent all at once.

signal changed(share: float)

var charge: float = 0.0


func add(damage: float) -> void:
	charge = minf(charge + damage, cost())
	changed.emit(share())


func is_full() -> bool:
	return charge >= cost()


func spend() -> void:
	charge = 0.0
	changed.emit(0.0)


func share() -> float:
	return charge / cost()


static func cost() -> float:
	return Tuning.number("combat", "super", "cost")
