class_name PixelLight
extends PointLight2D
## A pixel-art light: a round glow that falls off in a few hard bands instead of a
## smooth blur, so it sits well next to the sprites.
##
## The portal world is dark, and Glimra carry a living light, so most light comes
## from them. Three ways to use it:
##   - steady glow: leave fade_out_time at 0 (optionally with a slow flicker)
##   - one-shot flash on an event: set fade_out_time; it starts at its energy and fades out
##   - on demand: call flash() from code (e.g. a Warden's rod flaring when he summons),
##     or fade_out() to put it out
##
## Energy is the light's resting brightness; it's read once when the light appears.

## Radius of the glow, in world pixels.
@export var radius: int = 32
## Number of hard brightness steps from the centre to the edge.
@export var band_count: int = 4

@export_group("Flicker")
## How far the brightness wavers, as a share of its energy (0.05 = ±5%). 0 means steady.
@export var flicker_strength: float = 0.0
## Roughly how many wavers per second. Low values feel like a calm flame.
@export var flicker_speed: float = 1.0

@export_group("One-shot flash")
## If above zero, the light is a flash: it starts at its energy and fades to dark
## over this many seconds, then switches off.
@export var fade_out_time: float = 0.0

## Texture pixels per world pixel. The light is drawn smoothed, so a finer texture keeps
## the band edges crisp, while each world pixel still gets one flat brightness (pixel steps).
const TEXELS_PER_PIXEL := 4

## Banded textures are shared by every light with the same radius and band count.
static var _texture_cache: Dictionary = {}

var _resting_energy: float = 0.0
## Extra brightness from flash(), fading back to zero.
var _flash_energy: float = 0.0
var _flicker_time: float = 0.0
var _flash_tween: Tween


func _ready() -> void:
	texture = banded_texture(radius, band_count)
	texture_scale = 1.0 / TEXELS_PER_PIXEL
	_flicker_time = randf() * 100.0   # so lights placed together don't flicker in sync
	if fade_out_time > 0.0:
		var peak := energy
		_resting_energy = 0.0
		flash(peak, fade_out_time)
	else:
		_resting_energy = energy
	_update_energy()


func _process(delta: float) -> void:
	_flicker_time += delta * flicker_speed
	_update_energy()


## Brightens the light to peak_energy above its resting energy, then eases back over seconds.
func flash(peak_energy: float, seconds: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_energy = peak_energy
	_flash_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(self, "_flash_energy", 0.0, seconds)


## Dims the light to dark over seconds and leaves it off (e.g. when its owner dies).
func fade_out(seconds: float) -> void:
	var dimming := create_tween()
	dimming.tween_property(self, "_resting_energy", 0.0, seconds)
	dimming.parallel().tween_property(self, "_flash_energy", 0.0, seconds)


func _update_energy() -> void:
	energy = (_resting_energy + _flash_energy) * _flicker_factor()
	enabled = energy > 0.001


## Two slow waves at unrelated speeds, so the flicker never visibly repeats.
func _flicker_factor() -> float:
	if flicker_strength <= 0.0:
		return 1.0
	var waver := 0.6 * sin(_flicker_time * TAU) + 0.4 * sin(_flicker_time * TAU * 2.37 + 1.3)
	return 1.0 + flicker_strength * waver


## A white disc whose brightness drops in band_count hard steps: full in the middle,
## then fainter rings out to the edge. Each world pixel is one flat block of
## TEXELS_PER_PIXEL × TEXELS_PER_PIXEL texels, so the rings have pixel-art stair steps.
static func banded_texture(disc_radius: int, bands: int) -> ImageTexture:
	var key := Vector2i(disc_radius, bands)
	if _texture_cache.has(key):
		return _texture_cache[key]

	var size := disc_radius * 2
	var image := Image.create(size * TEXELS_PER_PIXEL, size * TEXELS_PER_PIXEL, false, Image.FORMAT_RGBA8)
	var centre := Vector2(disc_radius, disc_radius)
	for y in size:
		for x in size:
			var distance := (Vector2(x, y) + Vector2(0.5, 0.5)).distance_to(centre) / disc_radius
			var block := Rect2i(Vector2i(x, y) * TEXELS_PER_PIXEL, Vector2i.ONE * TEXELS_PER_PIXEL)
			image.fill_rect(block, Color(1, 1, 1, _band_brightness(distance, bands)))
	var banded := ImageTexture.create_from_image(image)
	_texture_cache[key] = banded
	return banded


## 1.0 in the inner band, stepping down evenly to 1/bands in the outer band, 0 outside the disc.
static func _band_brightness(distance: float, bands: int) -> float:
	if distance >= 1.0:
		return 0.0
	var band := floorf(distance * bands)          # 0 = innermost
	return (bands - band) / bands
