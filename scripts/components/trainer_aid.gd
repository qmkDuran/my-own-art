class_name TrainerAid
extends Node
## Trainer's Aid: the trainer throws a healing tonic (Q). Limited charges,
## refilled by picking up berries that enemies sometimes drop.

signal charges_changed(charges: int, max_charges: int)

@export var max_charges: int = 3
## Health restored by one tonic.
@export var heal_amount: int = 4
## Seconds before Aid can be used again.
@export var cooldown: float = 0.8

var charges: int = 3
var _cooldown_left: float = 0.0
var _is_in_flight: bool = false

@onready var creature: Node2D = get_parent()


func _ready() -> void:
	charges = max_charges


func _process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)


func has_room() -> bool:
	return charges < max_charges


func add_charge() -> void:
	charges = mini(max_charges, charges + 1)
	charges_changed.emit(charges, max_charges)


func use() -> void:
	if charges <= 0 or _cooldown_left > 0.0 or _is_in_flight:
		return
	var health: Health = creature.get_node("Health")
	if health.current_health >= health.max_health:
		return  # don't waste a charge at full health
	charges -= 1
	_cooldown_left = cooldown
	charges_changed.emit(charges, max_charges)
	var trainer := get_tree().get_first_node_in_group("trainer") as Trainer
	var heal := func() -> void:
		_is_in_flight = false
		health.heal(heal_amount)
	_is_in_flight = true
	if trainer != null:
		trainer.toss_tonic(creature, heal)
	else:
		heal.call()
