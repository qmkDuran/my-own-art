class_name WaystoneGlow
extends Node2D
## The light in a waystone's flame glyph: while its Checkpoint is the last one reached, a warm
## halo breathes around the glyph and a few ember pixels drift up from it. Drawn additively,
## so it brightens the stone's pixels instead of covering them. Its origin is the glyph.

## Seconds to light up or go dark.
const FADE_SECONDS := 0.6
## Seconds per slow breath of the halo.
const BREATH_SECONDS := 2.2
## Halo radii, in pixels: the wide soft one and the bright core.
const HALO_RADIUS := 7.0
const CORE_RADIUS := 3.0
const HALO_ALPHA := 0.22
const CORE_ALPHA := 0.45
## Ember pixels in the air at once, how high they drift (pixels) and for how long (seconds).
const EMBER_COUNT := 3
const EMBER_RISE := 14.0
const EMBER_SECONDS := 1.6
## How far either side of the glyph the embers start, in pixels.
const EMBER_SPREAD := 3.0

var _brightness: float = 0.0
var _elapsed: float = 0.0
var _fade: Tween = null


func _ready() -> void:
	z_index = 1
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


## Lights the glyph (or lets it go dark), fading over FADE_SECONDS.
func set_lit(is_lit: bool) -> void:
	if _fade != null:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "_brightness", 1.0 if is_lit else 0.0, FADE_SECONDS)


func _process(delta: float) -> void:
	_elapsed += delta
	if _brightness > 0.0:
		queue_redraw()


func _draw() -> void:
	if _brightness <= 0.0:
		return
	var breath := 0.75 + 0.25 * sin(TAU * _elapsed / BREATH_SECONDS)
	draw_circle(Vector2.ZERO, HALO_RADIUS, Color(ApolloPalette.ORANGE_DARK, HALO_ALPHA * breath * _brightness))
	draw_circle(Vector2.ZERO, CORE_RADIUS, Color(ApolloPalette.GOLD, CORE_ALPHA * breath * _brightness))
	for ember_number in EMBER_COUNT:
		var progress := fmod(_elapsed / EMBER_SECONDS + float(ember_number) / EMBER_COUNT, 1.0)
		var sway := sin(progress * TAU + ember_number) * EMBER_SPREAD
		var spot := Vector2(sway, -EMBER_RISE * progress).round()
		var alpha := sin(PI * progress) * _brightness
		draw_rect(Rect2(spot, Vector2.ONE), Color(ApolloPalette.ORANGE, alpha))
