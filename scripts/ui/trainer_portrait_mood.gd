class_name TrainerPortraitMood
extends RefCounted
## Picks the trainer portrait's expression, and when it blinks.
##
## Priority: shout (a skill or a tonic toss) > cheer (level up) > worried (low health)
## > calm (out of combat) > neutral. Neutral, calm and worried blink now and then.

const SHOUT_SECONDS := 0.4
const TOSS_SECONDS := 0.4
const CHEER_SECONDS := 1.5
## At or below this share of health the trainer looks worried (the heart's low-health beat).
const WORRIED_HEALTH_SHARE := HealthHeart.LOW_HEALTH_SHARE
## A blink lasts BLINK_SECONDS and comes every BLINK_GAP_MIN..BLINK_GAP_MAX seconds.
const BLINK_SECONDS := 0.12
const BLINK_GAP_MIN := 2.5
const BLINK_GAP_MAX := 5.0

var _shout := HudMotion.new(SHOUT_SECONDS)
var _toss := HudMotion.new(TOSS_SECONDS)
var _cheer := HudMotion.new(CHEER_SECONDS)
var _blink := HudMotion.new(BLINK_SECONDS)
var _next_blink_in: float = BLINK_GAP_MAX


func shout() -> void:
	_shout.start()


func toss() -> void:
	_toss.start()


func cheer() -> void:
	_cheer.start()


## Moves the timers on. Returns true when the expression may have changed.
func advance(delta: float) -> bool:
	var is_changing := _shout.advance(delta)
	is_changing = _toss.advance(delta) or is_changing
	is_changing = _cheer.advance(delta) or is_changing
	is_changing = _blink.advance(delta) or is_changing
	_next_blink_in -= delta
	if _next_blink_in <= 0.0:
		_next_blink_in = randf_range(BLINK_GAP_MIN, BLINK_GAP_MAX)
		_blink.start()
		is_changing = true
	return is_changing


## The animation name to show, from the health share and whether a fight is on.
func expression(health_share: float, is_in_combat: bool) -> StringName:
	if _shout.is_running():
		return &"shout"
	if _toss.is_running():
		return &"toss"
	if _cheer.is_running():
		return &"cheer"
	if health_share <= WORRIED_HEALTH_SHARE:
		return &"worried"
	return &"neutral" if is_in_combat else &"calm"


func is_blinking() -> bool:
	return _blink.is_running()
