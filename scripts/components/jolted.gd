class_name Jolted
extends ImpairingEffect
## A jolt (the Spark element), e.g. from a Fizzbug's burst: the target's nerves buzz, so the
## next jab it throws while jolted comes out a beat late. Using that jab ends the jolt; then
## it can't be jolted again for a while (ImpairingEffect.IMMUNITY_SECONDS).
##
## Attached at runtime by `Jolted.apply_to`. MeleeAttack asks `Jolted.take_jab_delay(attacker)`
## when a jab starts. Its sprite takes a spark tint meanwhile. Ash Guard blocks it.

## The child name a target's jolt goes by.
const NODE_NAME := "Jolted"

var _jab_delay: float = 0.0
var _tint: StatusTint


## Jolts the target with `target_health` for `seconds`: its next jab in that time is late by
## `jab_delay` seconds. False when it didn't take (dead, guarding, jolted or still immune).
static func apply_to(target_health: Health, jab_delay: float, seconds: float) -> bool:
	var jolted := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Jolted.new()) as Jolted
	if jolted == null or jolted.is_active():
		return false
	jolted._jab_delay = jab_delay
	jolted.start(_resisted_length(target_health, NODE_NAME, seconds))
	return true


## Seconds the jab `attacker` is starting comes out late (0 when not jolted). Spends the jolt.
static func take_jab_delay(attacker: Node) -> float:
	var jolted := attacker.get_node_or_null(NODE_NAME) as Jolted
	if jolted == null or not jolted.is_active():
		return 0.0
	jolted.start(0.0)
	return jolted._jab_delay


func _ready() -> void:
	_tint = StatusTint.new(target().get_node_or_null("Sprite") as CanvasItem, StatusColors.JOLT)
	add_child(_tint)


func _end() -> void:
	if is_instance_valid(_tint):
		_tint.queue_free()
