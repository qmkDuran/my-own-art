class_name SlowingEffect
extends ImpairingEffect
## A status effect that slows the target's walking for a moment (Soaked, Chilled). Then the
## same slow can't land again for a while (ImpairingEffect.IMMUNITY_SECONDS). Different
## slows stack by multiplying.
##
## The target asks `SlowingEffect.speed_share_of(self)` for how much of its speed is left.
## Each slow tints the target's sprite in its element's colour while it lasts.

## Share of its speed the target keeps while slowed (0.8 = 20% slower).
var speed_share: float = 1.0

var _tint_color: Color
var _tint: StatusTint


func _init(kept_speed_share: float, tint_color: Color) -> void:
	super._init()
	speed_share = kept_speed_share
	_tint_color = tint_color


## Share of its walking speed `target` has left after every slow on it (1.0 = unslowed).
static func speed_share_of(target: Node) -> float:
	var share := 1.0
	for child in target.get_children():
		var slow := child as SlowingEffect
		if slow != null and slow.is_active():
			share *= slow.speed_share
	return share


## Slows the target for `seconds` with the effect `make` builds, under `effect_name`.
## False when it didn't take (dead, guarding, already slowed by it or still immune).
static func _apply(target_health: Health, effect_name: String, seconds: float, make: Callable) -> bool:
	var slow := _find_or_add(target_health, effect_name, make) as SlowingEffect
	if slow == null or slow.is_active():
		return false
	slow.start(_resisted_length(target_health, effect_name, seconds))
	return true


func _ready() -> void:
	_tint = StatusTint.new(target().get_node_or_null("Sprite") as CanvasItem, _tint_color)
	add_child(_tint)


func _end() -> void:
	if is_instance_valid(_tint):
		_tint.queue_free()
