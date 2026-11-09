class_name Poisoned
extends DamageOverTime
## Poison (the Toxic element): a slow, mild damage over time, e.g. from a Toxlop's tongue
## lash. The target's sprite pulses green while it lasts.
##
## Attached at runtime by `Poisoned.apply_to`. Applying it again refreshes it to its full
## length (no stacking yet). Ash Guard blocks it (see StatusResistance).

## The child name a target's poison goes by, so a second dose finds the first.
const NODE_NAME := "Poisoned"

var _tint: StatusTint


func _init(seconds_between_ticks: float) -> void:
	super._init(seconds_between_ticks, Health.DamageType.POISON)


## Poisons the target with `target_health` for `duration` seconds, `damage_per_tick` every
## `seconds_between_ticks`, or refreshes the poison it already has. False when it didn't
## take (dead, or guarding).
static func apply_to(target_health: Health, damage_per_tick: int, seconds_between_ticks: float, duration: float) -> bool:
	var make := func() -> StatusEffect: return Poisoned.new(seconds_between_ticks)
	var poisoned := _find_or_add(target_health, NODE_NAME, make) as Poisoned
	if poisoned == null:
		return false
	poisoned.refresh(damage_per_tick, duration)
	return true


func _ready() -> void:
	_tint = StatusTint.new(target().get_node_or_null("Sprite") as CanvasItem, StatusColors.POISON)
	add_child(_tint)


func _end() -> void:
	if is_instance_valid(_tint):
		_tint.queue_free()
