class_name BossAura
extends EliteAura
## A boss's elite aura (only elites and bosses get one, see DESIGN.md "Visual hierarchy"):
## the elite's ground pulse and drifting pixels, larger and busier, the pixels blinking like
## a signal. Quiet, but it marks the boss as dangerous. Phase 2 makes it busier still
## (`intensify`). Sits behind the boss's sprite; BossDefeat hides it.

## Phase 2: this many times the pixels, and this much stronger (capped at fully opaque).
const PHASE_TWO_PIXEL_FACTOR := 2
const PHASE_TWO_ALPHA_FACTOR := 1.4

var _active_pixels: int = 0
## `max_alpha` before phase 2 strengthened it.
var _calm_max_alpha: float = 0.0


## A boss's defaults (a scene can still change them): bigger and slower than an elite's.
func _init() -> void:
	pulse_size = Vector2(16, 5)
	pulse_period = 2.4
	pixel_count = 5
	pixel_spread = 11.0
	pixel_rise = 18.0
	pixel_lifetime = 1.8
	max_alpha = 0.55
	ring_scale_low = 0.8
	ring_scale_swing = 0.3
	ring_alpha_low = 0.3
	ring_segments = 24
	pixel_start_height = 4.0
	pixels_blink = true


func _ready() -> void:
	_calm_max_alpha = max_alpha
	_active_pixels = pixel_count
	super._ready()


## Back to the phase-1 aura (the fight reset after the player fell).
func calm() -> void:
	_active_pixels = pixel_count
	max_alpha = _calm_max_alpha
	_pixels.resize(mini(_pixels.size(), _active_pixels))


## Phase 2: more data-pixels and a stronger pulse.
func intensify() -> void:
	_active_pixels = pixel_count * PHASE_TWO_PIXEL_FACTOR
	max_alpha = minf(1.0, max_alpha * PHASE_TWO_ALPHA_FACTOR)
	while _pixels.size() < _active_pixels:
		_add_pixel_at_random_age()
