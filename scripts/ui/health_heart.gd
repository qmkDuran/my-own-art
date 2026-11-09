class_name HealthHeart
extends Control
## The player's health as one big heart at the left of the skill bar, with the numbers inside it.
##
## The heart is a container of red: it drains from the top down as health is lost,
## with a brighter line on the surface of what's left (colours: HealthHeartColors).
## When hit it shakes and flashes pale, and the lost health lingers as a lighter "ghost"
## band that drains away after a moment. A status tick (e.g. poison) is quieter: no shake or
## flash, just the ghost band and the rim tinting the element's colour for a blink. Heals
## tint the rows gained green. At low health the heart beats, faster the lower it gets.

## Pixel map of the heart (29×23). 'x' = inside the heart.
const HEART_PIXELS := [
	".....xxxxxx.......xxxxxx.....",
	"...xxxxxxxxxx...xxxxxxxxxx...",
	"..xxxxxxxxxxxx.xxxxxxxxxxxx..",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	"..xxxxxxxxxxxxxxxxxxxxxxxxx..",
	"..xxxxxxxxxxxxxxxxxxxxxxxxx..",
	"...xxxxxxxxxxxxxxxxxxxxxxx...",
	"....xxxxxxxxxxxxxxxxxxxxx....",
	".....xxxxxxxxxxxxxxxxxxx.....",
	"......xxxxxxxxxxxxxxxxx......",
	".......xxxxxxxxxxxxxxx.......",
	".........xxxxxxxxxxx.........",
	"..........xxxxxxxxx..........",
	"............xxxxx............",
	"..............x..............",
]
const HEART_SIZE := Vector2i(29, 23)
## Top of the numbers, from the top of the heart.
const NUMBERS_TOP := 9
const HIT_SHAKE_SECONDS := 0.2
const HIT_FLASH_SECONDS := 0.08
const HEAL_TINT_SECONDS := 0.3
const TICK_TINT_SECONDS := 0.15
## Lost health stays as a ghost band this long, then drains away over GHOST_DRAIN_SECONDS.
const GHOST_HOLD_SECONDS := 0.4
const GHOST_DRAIN_SECONDS := 0.4
## At or below this share of health the heart beats: one beat every BEAT_PERIOD_SLOWEST
## seconds at the threshold, down to BEAT_PERIOD_FASTEST near zero.
const LOW_HEALTH_SHARE := 0.3
const BEAT_PERIOD_SLOWEST := 0.8
const BEAT_PERIOD_FASTEST := 0.45
const BEAT_SECONDS := 0.12

var _health: Health
var _colors := HealthHeartColors.new(PixelShape.from_rows(HEART_PIXELS))
var _hit_shake := HudMotion.new(HIT_SHAKE_SECONDS)
var _hit_flash := HudMotion.new(HIT_FLASH_SECONDS)
var _heal_tint := HudMotion.new(HEAL_TINT_SECONDS)
var _tick_tint := HudMotion.new(TICK_TINT_SECONDS)
var _ghost_hold := HudMotion.new(GHOST_HOLD_SECONDS)
## Health shown by the ghost band (drains down to the real health), and how fast it drains.
var _ghost_health: float = 0.0
var _ghost_drain_per_second: float = 0.0
var _last_health: int = 0
var _beat_time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Wait one frame so the player has been added to the level.
	await get_tree().process_frame
	_health = PlayerFinder.find_component(self, "Health") as Health
	if _health != null:
		_last_health = _health.current_health
		_ghost_health = _last_health
		_health.damaged.connect(func(_amount: int, _from: Vector2) -> void: _on_damaged())
		_health.healed.connect(func(_amount: int) -> void: _on_healed())
		_health.hit_taken.connect(_on_hit_taken)
	queue_redraw()


func _process(delta: float) -> void:
	if _health == null:
		return
	var is_moving := _hit_shake.advance(delta)
	is_moving = _hit_flash.advance(delta) or is_moving
	is_moving = _heal_tint.advance(delta) or is_moving
	is_moving = _tick_tint.advance(delta) or is_moving
	is_moving = _drain_ghost(delta) or is_moving
	is_moving = _advance_beat(delta) or is_moving
	if is_moving:
		queue_redraw()


func _on_damaged() -> void:
	_hit_shake.start()
	_hit_flash.start()
	_show_health_lost()


## Status ticks fire no `damaged` (hits are handled there), only `hit_taken`.
func _on_hit_taken(_amount: int, _is_critical: bool, damage_type: Health.DamageType) -> void:
	if damage_type == Health.DamageType.DIRECT:
		return
	_colors.tick_color = StatusColors.for_damage_type(damage_type)
	_tick_tint.start()
	_show_health_lost()


## The health just lost lingers as the ghost band.
func _show_health_lost() -> void:
	_ghost_health = maxf(_ghost_health, _last_health)
	_ghost_drain_per_second = 0.0
	_ghost_hold.start()
	_last_health = _health.current_health
	queue_redraw()


func _on_healed() -> void:
	if _health.current_health > _last_health:
		_colors.healed_from_share = _share_of(_last_health)
		_heal_tint.start()
	_ghost_health = maxf(_ghost_health, _health.current_health)
	_last_health = _health.current_health
	queue_redraw()


## Holds the ghost band, then drains it to the real health. Returns true while it changes.
func _drain_ghost(delta: float) -> bool:
	if _ghost_hold.advance(delta) or _ghost_health <= _health.current_health:
		return false
	if _ghost_drain_per_second <= 0.0:
		_ghost_drain_per_second = (_ghost_health - _health.current_health) / GHOST_DRAIN_SECONDS
	_ghost_health = maxf(_health.current_health, _ghost_health - _ghost_drain_per_second * delta)
	return true


## Keeps the low-health beat going. Returns true when the heart must redraw.
func _advance_beat(delta: float) -> bool:
	var share := _share_of(_health.current_health)
	var was_beating := _colors.is_beating
	if share > LOW_HEALTH_SHARE or share <= 0.0:
		_beat_time = 0.0
		_colors.is_beating = false
	else:
		_beat_time += delta
		var period := lerpf(BEAT_PERIOD_FASTEST, BEAT_PERIOD_SLOWEST, share / LOW_HEALTH_SHARE)
		_colors.is_beating = HudMotion.beat(_beat_time, period, BEAT_SECONDS)
	return _colors.is_beating != was_beating


func _draw() -> void:
	if _health == null:
		return
	var origin := _hit_shake.shake()
	_colors.share_left = _share_of(_health.current_health)
	_colors.ghost_share = _share_of(_ghost_health)
	_colors.is_hit_flashing = _hit_flash.is_running()
	_colors.is_tick_tinting = _tick_tint.is_running()
	if not _heal_tint.is_running():
		_colors.healed_from_share = -1.0
	PixelShape.draw_outlined_with_shadow(self, _colors.paint(), origin, ApolloPalette.OUTLINE)
	var numbers := "%d/%d" % [_health.current_health, _health.max_health]
	var left := floori((HEART_SIZE.x - PixelFont.width_of(numbers)) / 2.0)
	PixelFont.draw_text(self, numbers, origin + Vector2(left, NUMBERS_TOP), ApolloPalette.CREAM, ApolloPalette.OUTLINE)


func _share_of(health: float) -> float:
	return clampf(health / float(_health.max_health), 0.0, 1.0)
