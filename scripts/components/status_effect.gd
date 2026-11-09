class_name StatusEffect
extends Node2D
## What every status effect has in common (Burning, Poisoned, Staggered, Buffeted, Rooted,
## Soaked, Chilled, Jolted): it sits
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
##   _end()                 -> once, when it stops working
##   _on_target_died()      -> the target died with it on (e.g. a burn spreads)
##   _tint_color()          -> the colour its target's sprite pulses toward while it lasts
##                             (StatusTint); fully transparent (the default) for no tint

## The child a target's StatusResistance goes by, if it has one.
const RESISTANCE_NODE := "StatusResistance"
## The child a target's sprite goes by (the one a tint colours).
const SPRITE_NODE := "Sprite"

## Seconds after the effect ends during which the target can't get it again.
var immunity_seconds: float = 0.0

var _health: Health
var _immunity_left: float = 0.0
var _has_ended: bool = false
var _tint: StatusTint


## The target's `effect_name` effect, newly made by `make` if it has none yet. Null when it
## can't take it now: dead, resisting it (e.g. guarding) or still immune after the last one.
static func _find_or_add(target_health: Health, effect_name: String, make: Callable) -> StatusEffect:
	if target_health == null or target_health.is_dead():
		return null
	var holder := target_health.get_parent()
	var resistance := holder.get_node_or_null(RESISTANCE_NODE) as StatusResistance
	if resistance != null and resistance.resists(effect_name):
		return null
	var effect := holder.get_node_or_null(effect_name) as StatusEffect
	if effect != null:
		return null if effect.is_immune() else effect
	effect = make.call()
	effect.name = effect_name
	effect._health = target_health
	holder.add_child(effect)
	target_health.died.connect(effect._on_target_died)
	return effect


## `seconds` of the target's `effect_name` effect after its StatusResistance (e.g. Unshakable
## shortens a stagger); as given for targets without one.
static func _resisted_length(target_health: Health, effect_name: String, seconds: float) -> float:
	var resistance := target_health.get_parent().get_node_or_null(RESISTANCE_NODE) as StatusResistance
	return resistance.length_of(effect_name, seconds) if resistance != null else seconds


## Ends every status effect on `holder` at once, immunities included (e.g. a respawn).
static func clear_from(holder: Node) -> void:
	for child in holder.get_children():
		if child is StatusEffect:
			(child as StatusEffect)._finish()


## True once the effect has ended but the target is still immune to it.
func is_immune() -> bool:
	return _has_ended and _immunity_left > 0.0


## The target this effect is on (e.g. the creature to tint or interrupt).
func get_target() -> Node:
	return get_parent()


func _ready() -> void:
	var tint_color := _tint_color()
	if tint_color.a > 0.0:
		_tint = StatusTint.new(get_target().get_node_or_null(SPRITE_NODE) as CanvasItem, tint_color)
		add_child(_tint)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_health) or _health.is_dead():
		_finish()
		return
	if is_active():
		_advance(delta)
		return
	if not _has_ended:
		_stop_working()
		_immunity_left = immunity_seconds
	_immunity_left -= delta
	if _immunity_left <= 0.0:
		queue_free()


func _finish() -> void:
	if not _has_ended:
		_stop_working()
	queue_free()


func _stop_working() -> void:
	_has_ended = true
	if is_instance_valid(_tint):
		_tint.queue_free()
	_end()


# --- For each effect to fill in --------------------------------------------

func is_active() -> bool:
	return false


func seconds_left() -> float:
	return 0.0


func full_length() -> float:
	return 0.0


func _advance(_delta: float) -> void:
	pass


func _end() -> void:
	pass


func _on_target_died() -> void:
	pass


func _tint_color() -> Color:
	return Color.TRANSPARENT
