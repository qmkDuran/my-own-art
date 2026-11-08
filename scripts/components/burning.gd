class_name Burning
extends Node2D
## A burn on any target with a Health: it hurts the target every second until it runs out.
##
## Attached at runtime by `Burning.apply_to` (e.g. from Searing Jab), so no enemy scene
## needs it. Applying it again refreshes the burn to its full length (no stacking yet) but
## keeps the tick rhythm, so quick jabs never push the next tick back.
## Ticks use Health.take_tick_damage: no knockback, no hit flash, no interrupted attack,
## just an orange damage number. A Node2D only so its ember cue (BurnEmbers) rides along
## with the target; it frees itself when the burn ends or the target dies.

## The child name a target's burn goes by, so a second burn finds the first.
const NODE_NAME := "Burning"
## Seconds between ticks: burn damage is "per second".
const TICK_INTERVAL := 1.0
## Nodes in this group are told when a target dies while burning, through
## `on_burning_target_died(target, damage_per_second, duration)` (e.g. Wildfire spreads it).
const SPREAD_GROUP := "burn_spreaders"

## Damage each tick deals.
var damage_per_tick: int = 0

var _health: Health
## The burn's full length, in seconds, as last applied (what a spread burn gets).
var _duration: float = 0.0
var _ticks_left: int = 0
var _seconds_to_next_tick: float = TICK_INTERVAL


## Sets the target with `target_health` burning for `duration` seconds, `damage_per_second`
## each second, or refreshes the burn it already has. A dead target isn't set alight.
static func apply_to(target_health: Health, damage_per_second: int, duration: float) -> void:
	if target_health == null or target_health.is_dead():
		return
	var target := target_health.get_parent()
	var burning := target.get_node_or_null(NODE_NAME) as Burning
	if burning == null:
		burning = Burning.new()
		burning.name = NODE_NAME
		burning._health = target_health
		target.add_child(burning)
		target_health.died.connect(burning._on_target_died)
	burning.refresh(damage_per_second, duration)


## The burn's numbers, at full length again. A weaker re-application never weakens it.
func refresh(damage_per_second: int, duration: float) -> void:
	damage_per_tick = maxi(damage_per_tick, damage_per_second)
	_duration = maxf(_duration, duration)
	_ticks_left = maxi(_ticks_left, ceili(duration / TICK_INTERVAL - 0.001))


## Seconds until the burn goes out.
func seconds_left() -> float:
	return maxf(0.0, (_ticks_left - 1) * TICK_INTERVAL + _seconds_to_next_tick)


func _ready() -> void:
	add_child(BurnEmbers.new())


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_health) or _health.is_dead() or _ticks_left <= 0:
		queue_free()
		return
	_seconds_to_next_tick -= delta
	if _seconds_to_next_tick > 0.0:
		return
	_seconds_to_next_tick += TICK_INTERVAL
	_ticks_left -= 1
	_health.take_tick_damage(damage_per_tick, Health.DamageType.BURN)


func _on_target_died() -> void:
	if is_inside_tree():
		get_tree().call_group(SPREAD_GROUP, "on_burning_target_died", get_parent(), damage_per_tick, _duration)
