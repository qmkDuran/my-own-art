class_name Poise
extends Node2D
## An enemy's poise: how much more punishment it takes before it Breaks (see Broken). Every
## landed hit drains some; at zero the enemy is knocked down (Broken) for `BREAK_SECONDS`,
## then its poise refills. Left alone for `REFILL_DELAY` seconds, poise refills on its own.
## Super-armoured enemies (mid-charge, mid-slam) don't lose poise: no opening there.
##
## Made on the first hit by `Poise.drain`, so no enemy scene needs it. Draws a thin white
## bar under the enemy's health bar (or over its head) once it has taken poise damage.

const NODE_NAME := "Poise"
const MIN_POISE := 3
const MAX_POISE := 12
## Extra poise on top of the enemy's max health.
const POISE_PER_HEALTH := 1
const BASE_POISE := 3
const REFILL_DELAY := 2.5
const BREAK_SECONDS := 2.2
const BAR_WIDTH := 14.0
const BAR_GAP_UNDER_HEALTH := 4.0
const BAR_HEIGHT_WITHOUT_HEALTH := -20.0

var max_poise: int = MIN_POISE
var current_poise: int = MIN_POISE

var _health: Health
var _seconds_since_hit: float = 0.0


## Drains `amount` poise from the enemy with `target_health`. True if that Broke it.
static func drain(target_health: Health, amount: int) -> bool:
	if target_health == null or target_health.is_dead() or amount <= 0:
		return false
	var target := target_health.get_parent()
	if target.has_method("is_super_armoured") and target.call("is_super_armoured"):
		return false
	if SetUp.has(target, SetUp.BROKEN):
		return false
	var poise := target.get_node_or_null(NODE_NAME) as Poise
	if poise == null:
		poise = Poise.new()
		poise.name = NODE_NAME
		poise._health = target_health
		poise.max_poise = clampi(BASE_POISE + target_health.max_health * POISE_PER_HEALTH, MIN_POISE, MAX_POISE)
		poise.current_poise = poise.max_poise
		target.add_child(poise)
	return poise._take(amount)


func _ready() -> void:
	z_index = 2
	var health_bar := get_parent().get_node_or_null("FloatingHealthBar") as Node2D
	position = health_bar.position + Vector2(0, BAR_GAP_UNDER_HEALTH) if health_bar != null else Vector2(0, BAR_HEIGHT_WITHOUT_HEALTH)


func _physics_process(delta: float) -> void:
	_seconds_since_hit += delta
	var is_broken := SetUp.has(get_parent(), SetUp.BROKEN)
	if _seconds_since_hit >= REFILL_DELAY and not is_broken and current_poise < max_poise:
		current_poise = max_poise
	visible = is_instance_valid(_health) and not _health.is_dead() and (current_poise < max_poise or is_broken)
	queue_redraw()


func _take(amount: int) -> bool:
	_seconds_since_hit = 0.0
	current_poise = maxi(0, current_poise - amount)
	if current_poise > 0:
		return false
	current_poise = max_poise
	return Broken.apply_to(_health, BREAK_SECONDS)


func _draw() -> void:
	var outer := Rect2(Vector2(-BAR_WIDTH / 2.0 - 1.0, 0), Vector2(BAR_WIDTH + 2.0, 3))
	draw_rect(outer, ApolloPalette.OUTLINE)
	var is_broken := SetUp.has(get_parent(), SetUp.BROKEN)
	var share := 0.0 if is_broken else float(current_poise) / float(max_poise)
	var fill := ApolloPalette.GOLD if is_broken else ApolloPalette.WHITE
	var width := BAR_WIDTH if is_broken else roundf(BAR_WIDTH * share)
	draw_rect(Rect2(Vector2(-BAR_WIDTH / 2.0, 1), Vector2(width, 1)), fill)
