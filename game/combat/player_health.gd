class_name PlayerHealth
extends Node
## The lamplighter's health in a fight: takes hits (with a short grace after each, none while blinking, warded or
## rising into the super), recovers on its own after a few seconds without being hit, and says when it runs out.

signal changed(health: float, max_health: float)
signal hurt_taken(amount: float)
signal fainted

var health: float = 0.0
var max_health: float = 0.0
var invulnerable: bool = false
var _grace: float = 0.0
var _calm: float = 0.0
var _player: Player


func setup(player: Player) -> void:
	name = "PlayerHealth"
	_player = player
	reset()


func reset() -> void:
	max_health = Tuning.number("combat", "player", "health")
	health = max_health
	_grace = 0.0
	changed.emit(health, max_health)


## True when a hit now would land (not blinking, not in grace, not invulnerable).
func can_be_hurt() -> bool:
	return health > 0.0 and _grace <= 0.0 and not invulnerable and not _player.is_dashing()


func hurt(amount: float) -> bool:
	if not can_be_hurt():
		return false
	health = maxf(health - amount, 0.0)
	_grace = Tuning.number("combat", "player", "hurt_grace")
	_calm = Tuning.number("combat", "player", "regen_delay")
	changed.emit(health, max_health)
	hurt_taken.emit(amount)
	if health == 0.0:
		fainted.emit()
	return true


func _process(delta: float) -> void:
	_grace = maxf(_grace - delta, 0.0)
	_calm = maxf(_calm - delta, 0.0)
	if _calm == 0.0 and health > 0.0 and health < max_health:
		health = minf(health + Tuning.number("combat", "player", "regen_per_second") * delta, max_health)
		changed.emit(health, max_health)
