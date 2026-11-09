class_name Burning
extends DamageOverTime
## A burn on any target with a Health (the player's fire on enemies): it hurts the target
## every second until it runs out.
##
## Attached at runtime by `Burning.apply_to` (e.g. from Searing Jab), so no enemy scene
## needs it. The ticking and refreshing live in DamageOverTime; this adds the ember cue
## (BurnEmbers) and tells the spreaders when a burning target dies.

## The child name a target's burn goes by, so a second burn finds the first.
const NODE_NAME := "Burning"
## Seconds between ticks: burn damage is "per second".
const TICK_INTERVAL := 1.0
## Nodes in this group are told when a target dies while burning, through
## `on_burning_target_died(target, damage_per_second, duration)` (e.g. Wildfire spreads it).
const SPREAD_GROUP := "burn_spreaders"


func _init() -> void:
	super._init(TICK_INTERVAL, Health.DamageType.BURN)


## Sets the target with `target_health` burning for `duration` seconds, `damage_per_second`
## each second, or refreshes the burn it already has. A dead target isn't set alight.
static func apply_to(target_health: Health, damage_per_second: int, duration: float) -> void:
	var burning := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Burning.new()) as Burning
	if burning != null:
		burning.refresh(damage_per_second, duration)


func _ready() -> void:
	super._ready()
	add_child(BurnEmbers.new())


func _on_target_died() -> void:
	if is_inside_tree():
		get_tree().call_group(SPREAD_GROUP, "on_burning_target_died", get_parent(), damage_per_tick, _duration)
