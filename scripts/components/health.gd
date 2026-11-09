class_name Health
extends Node
## Tracks how much damage something can take before it dies.
##
## Other components listen to its signals (flash on hit, die at zero)
## instead of Health knowing about them.
## Two kinds of harm: a hit (`take_damage`, fires `damaged`, so the target reacts: flash,
## knockback, interrupted) and a status-effect tick (`take_tick_damage`, e.g. Burning or
## Poisoned, which doesn't). Both fire `hit_taken`, so damage numbers and health bars see every point.
## HitShields on it (a Brinelob's shell, a Rimoth's frost shell) may turn a hit away or soak it first.

## What dealt the damage, so displays can tell them apart (e.g. orange burn numbers, green
## poison numbers; see StatusColors).
enum DamageType { DIRECT, BURN, POISON }
## How a hit is delivered, for HitShields that only stop some hits: a plain strike (a jab),
## a sweep that comes round a guard (the Spinning Hook, a Fizzbug's burst ring), or fire (Flame Uppercut; burn ticks
## count as fire too).
enum HitKind { STRIKE, SWEEP, FIRE }

## A hit: the target should react to it (flash, knockback, interruption).
signal damaged(amount: int, source_position: Vector2)
## Fired for every hit and every tick, saying whether it was critical and what dealt it
## (e.g. for damage numbers).
signal hit_taken(amount: int, is_critical: bool, damage_type: DamageType)
signal died
signal healed(amount: int)
## A HitShield turned a hit away whole (e.g. a Brinelob's shell): no damage, no reaction.
signal deflected(source_position: Vector2)

@export var max_health: int = 3

## While true, damage is ignored (e.g. mid-dodge).
var is_invulnerable: bool = false
## Share of each hit's damage actually taken: 1 = all, 0.5 = half (e.g. while Ash Guard is up).
## The leftover fraction carries to the next hit, so two 1-damage hits at half cost exactly 1.
var damage_taken_scale: float = 1.0
var _damage_fraction_carried: float = 0.0
## Shields between hits and this health, asked in order (see HitShield; they add themselves).
var shields: Array[HitShield] = []

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int, source_position: Vector2, is_critical: bool = false, kind: HitKind = HitKind.STRIKE) -> void:
	if is_invulnerable or is_dead():
		return
	for shield in shields:
		if shield.deflects(source_position, kind):
			deflected.emit(source_position)
			return

	amount = _scaled_hit(_soaked(amount, kind))
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
	amount = _soaked(amount, HitKind.FIRE if damage_type == DamageType.BURN else HitKind.STRIKE)
	if amount <= 0:
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


## Back to full health, even from dead (e.g. the player getting back up at a checkpoint,
## or an enemy returning to its spawn after the player falls).
func revive() -> void:
	var missing := max_health - current_health
	current_health = max_health
	_damage_fraction_carried = 0.0
	healed.emit(missing)


## Raises (or, with a negative amount, lowers) max health, e.g. from an Ember Tree stat.
## A raise also fills the new room, so the extra hits count straight away; a drop never kills.
func change_max_health(amount: int) -> void:
	max_health = maxi(1, max_health + amount)
	current_health = clampi(current_health + maxi(0, amount), 1, max_health)
	# Displays that only redraw on heals (the HUD heart) still pick up the new numbers.
	healed.emit(0)


## What's left of `amount` after every shield has soaked what it can.
func _soaked(amount: int, kind: HitKind) -> int:
	for shield in shields.duplicate():
		amount = shield.soak(amount, kind)
	return amount


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
