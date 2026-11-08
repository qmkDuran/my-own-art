class_name HudMotion
extends RefCounted
## One short HUD motion (a shake, a bounce, a flash, a press): a countdown that gives
## whole-pixel offsets, so the HUD stays pixel-crisp. Each widget keeps one per motion and
## calls `advance` from _process; `beat` is the repeating pulse for things like a low-health heart.

## How long one left/right step of a shake lasts, in seconds.
const SHAKE_STEP_SECONDS := 0.05

## How long the motion lasts, in seconds.
var seconds: float
var _left: float = 0.0


func _init(motion_seconds: float) -> void:
	seconds = motion_seconds


func start() -> void:
	_left = seconds


func stop() -> void:
	_left = 0.0


func is_running() -> bool:
	return _left > 0.0


## Moves the motion on. Returns true while it ran this frame, including its last frame, so
## the caller redraws once more after it ends.
func advance(delta: float) -> bool:
	if _left <= 0.0:
		return false
	_left = maxf(0.0, _left - delta)
	return true


## How far through the motion it is: 0 at the start, 1 when done (or not running).
func progress() -> float:
	if _left <= 0.0:
		return 1.0
	return 1.0 - _left / seconds


## Whether the motion is still in its first `share` (e.g. 0.5 = the first half).
func is_in_first(share: float) -> bool:
	return is_running() and progress() < share


## Left-right jitter: `pixels` right, then left, then right... one step every SHAKE_STEP_SECONDS.
func shake(pixels: int = 1) -> Vector2:
	if not is_running():
		return Vector2.ZERO
	return Vector2(pixels if blink(SHAKE_STEP_SECONDS) else -pixels, 0)


## On, off, on... switching every `step_seconds` while the motion runs; false once it is done.
func blink(step_seconds: float) -> bool:
	return is_running() and int((seconds - _left) / step_seconds) % 2 == 0


## Up by `pixels` for the first half of the motion, then back.
func bounce(pixels: int = 1) -> Vector2:
	return Vector2(0, -pixels) if is_in_first(0.5) else Vector2.ZERO


## Down by `pixels` while the motion runs (a button being pressed).
func press(pixels: int = 1) -> Vector2:
	return Vector2(0, pixels) if is_running() else Vector2.ZERO


## A repeating beat: true for the first `on_seconds` of every `period` seconds of `time`.
static func beat(time: float, period: float, on_seconds: float) -> bool:
	return fmod(time, period) < on_seconds
