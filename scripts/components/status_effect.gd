class_name StatusEffect
extends Node2D
## What every status effect has in common (Burning, Poisoned, Staggered, Buffeted): it sits
## on anything with a Health as a child named after the effect, so a second application
## finds the first; it lasts a short while, then frees itself (or when the target dies).
##
## Effects are attached at runtime by each effect's own `apply_to`, so no scene needs them.
## A Node2D only so its cue (embers, a tint) rides along with the target.
##
## No lock-downs (see DESIGN.md, "Enemy status effects"): an effect with `immunity_seconds`
## stays on the target that long after it ends, and while it does the target can't get it
## again. A target with a StatusResistance (the player) may also shrug an effect off or
## shorten it (e.g. Ash Guard, Unshakable).
##
## Each effect overrides:
##   is_active()            -> true while the effect is still working
##   seconds_left()         -> seconds until it ends (the HUD drains its timer with this)
##   full_length()          -> its whole length, as last applied
##   _advance(delta)        -> one physics frame while active (ticks, timers)
##   _end()                 -> once, when it stops working (its tint is already removed)
##   _on_target_died()      -> the target died with it on (e.g. a burn spreads)
##   consume()              -> ends it at once (a reaction or Signal Skill cashed it in)

## The child a target's StatusResistance goes by, if it has one.
const RESISTANCE_NODE := "StatusResistance"
## The target's sprite, which a tinting effect colours (see `_tint_target`).
const SPRITE_NODE := "Sprite"

## Seconds after the effect ends during which the target can't get it again.
var immunity_seconds: float = 0.0

var _health: Health
var _immunity_left: float = 0.0
var _has_ended: bool = false
## The pulsing colour on the target's sprite, if this effect shows one.
var _tint: StatusTint


## The target's `effect_name` effect, newly made by `make` if it has none yet. Null when it
## can't take it now: dead, resisting it (e.g. guarding) or still immune after the last one.
static func _find_or_add(target_health: Health, effect_name: String, make: Callable) -> StatusEffect:
	if target_health == null or target_health.is_dead():
		return null
	var target_node := target_health.get_parent()
	var resistance := target_node.get_node_or_null(RESISTANCE_NODE) as StatusResistance
	if resistance != null and resistance.resists(effect_name):
		return null
	var effect := target_node.get_node_or_null(effect_name) as StatusEffect
	if effect != null:
		return null if effect.is_immune() else effect
	effect = make.call()
	effect.name = effect_name
	effect._health = target_health
	target_node.add_child(effect)
	target_health.died.connect(effect._on_target_died)
	return effect


## `seconds` of the target's `effect_name` effect after its StatusResistance (e.g. Unshakable
## shortens a stagger); as given for targets without one.
static func _resisted_length(target_health: Health, effect_name: String, seconds: float) -> float:
	var resistance := target_health.get_parent().get_node_or_null(RESISTANCE_NODE) as StatusResistance
	return resistance.length_of(effect_name, seconds) if resistance != null else seconds


## True once the effect has ended but the target is still immune to it.
func is_immune() -> bool:
	return _has_ended and _immunity_left > 0.0


## The target this effect is on (e.g. the creature to tint or interrupt).
func target() -> Node:
	return get_parent()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_health) or _health.is_dead():
		_finish()
		return
	if is_active():
		_advance(delta)
		return
	if not _has_ended:
		_has_ended = true
		_immunity_left = immunity_seconds
		_remove_tint()
		_end()
	_immunity_left -= delta
	if _immunity_left <= 0.0:
		queue_free()


func _finish() -> void:
	if not _has_ended:
		_has_ended = true
		_remove_tint()
		_end()
	queue_free()


## Pulses the target's sprite toward `color` until the effect ends (a target without a
## sprite simply shows no tint).
func _tint_target(color: Color) -> void:
	_tint = StatusTint.new(target().get_node_or_null(SPRITE_NODE) as CanvasItem, color)
	add_child(_tint)


func _remove_tint() -> void:
	if is_instance_valid(_tint):
		_tint.queue_free()


# --- For each effect to fill in --------------------------------------------

func is_active() -> bool:
	return false


func seconds_left() -> float:
	return 0.0


func full_length() -> float:
	return 0.0


func _advance(_delta: float) -> void:
	pass


## Ends the effect right away (a reaction or Signal Skill cashed it in).
func consume() -> void:
	pass


func _end() -> void:
	pass


func _on_target_died() -> void:
	pass
