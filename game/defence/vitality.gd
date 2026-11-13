class_name Vitality
extends Node
## The lamplighter's health in a night: takes hits (with a short grace time after each, and none while dashing),
## heals, slowly recovers beside a lit lamp, and says when it runs out.

signal changed(health: float, max_health: float)
signal fainted

const BODY_RADIUS: float = 0.35

var health: float = 0.0
var max_health: float = 0.0
var _grace: float = 0.0
var _player: Player
var _lamps: LampKeeper


func setup(player: Player, lamps: LampKeeper) -> void:
	name = "Vitality"
	_player = player
	_lamps = lamps
	reset(Tuning.number("defence", "player", "health"))


func reset(full: float) -> void:
	max_health = full
	health = full
	_grace = 0.0
	changed.emit(health, max_health)


func raise_max(amount: float) -> void:
	max_health += amount
	heal(amount)


func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	changed.emit(health, max_health)


func hurt(amount: float) -> void:
	if _grace > 0.0 or health <= 0.0 or _player.is_dashing():
		return
	health = maxf(health - amount, 0.0)
	_grace = Tuning.number("defence", "player", "invulnerable_seconds")
	changed.emit(health, max_health)
	if health == 0.0:
		fainted.emit()


func _process(delta: float) -> void:
	_grace = maxf(_grace - delta, 0.0)
	var comfort: float = Tuning.number("defence", "player", "lamp_comfort_radius")
	if health > 0.0 and health < max_health and _lamps.near_lit(_player.global_position, comfort):
		heal(Tuning.number("defence", "player", "regen_near_lamp") * delta)
