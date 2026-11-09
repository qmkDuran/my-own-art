class_name Health
extends Node
## Tracks how much damage something can take before it dies.
##
## Other components listen to its signals (flash on hit, die at zero)
## instead of Health knowing about them.
## Two kinds of harm: a hit (`take_damage`, fires `damaged`, so the target reacts: flash,
## knockback, interrupted) and a status-effect tick (`take_tick_damage`, e.g. Burning or
## Poisoned, which doesn't). Both fire `hit_taken`, so damage numbers and health bars see every point.

## What dealt the damage, so displays can tell them apart (e.g. orange burn numbers, green
## poison numbers; see StatusColors).
enum DamageType { DIRECT, BURN, POISON }

## A hit: the target should react to it (flash, knockback, interruption).
signal damaged(amount: int, source_position: Vector2)
## Fired for every hit and every tick, saying whether it was critical and what dealt it
## (e.g. for damage numbers).
signal hit_taken(amount: int, is_critical: bool, damage_type: DamageType)
signal died
signal healed(amount: int)
## A shielded hit was soaked up whole (e.g. by Mossdillo's Bark Ward).
signal shield_absorbed

@export var max_health: int = 3

## While true, damage is ignored (e.g. mid-dodge).
var is_invulnerable: bool = false
## Hits still to be soaked up whole by a shield (e.g. Bark Ward). Ticks get through.
var shield_hits: int = 0
## Share of each hit's damage actually taken: 1 = all, 0.5 = half (e.g. while Ash Guard is up).
## The leftover fraction carries to the next hit, so two 1-damage hits at half cost exactly 1.
var damage_taken_scale: float = 1.0
var _damage_fraction_carried: float = 0.0

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int, source_position: Vector2, is_critical: bool = false) -> void:
	if is_invulnerable or is_dead():
		return
	if shield_hits > 0 and amount > 0:
		shield_hits -= 1
		shield_absorbed.emit()
		return

	amount = _scaled_hit(amount)
	current_health = maxi(0, current_health - amount)
	# A fully soaked hit still counts as a hit (flash, guard counters), but shows no number.
	if amount > 0:
		hit_taken.emit(amount, is_critical, DamageType.DIRECT)
	damaged.emit(amount, source_position)
	if is_dead():
		died.emit()


## Damage from a status effect (e.g. a burn tick): it hurts and can kill, but fires no
## `damaged`, so there is no flash, knockback or interruption.
func take_tick_damage(amount: int, damage_type: DamageType) -> void:
	if is_invulnerable or is_dead():
		return
	current_health = maxi(0, current_health - amount)
	hit_taken.emit(amount, false, damage_type)
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
	# Displays that only redraw on heals (the HUD heart) still pick up the new numbers.
	healed.emit(0)


## The hit's damage after `damage_taken_scale`, carrying the leftover fraction forward.
func _scaled_hit(amount: int) -> int:
	if is_equal_approx(damage_taken_scale, 1.0):
		return amount
	var scaled := amount * damage_taken_scale + _damage_fraction_carried
	var taken := floori(scaled + 0.001)
	_damage_fraction_carried = maxf(0.0, scaled - taken)
	return taken


func is_dead() -> bool:
	return current_health <= 0
