@abstract
class_name PixelFire
extends Node2D
## A burst of fire drawn in code pixel by pixel (FireRing, FlameArc): every pixel it may cover
## is worked out once (`_add_cell`), then each frame the burst decides which of them burn and
## how hot (`_color_index_at`), cooling from white-hot through gold to deep red (blue-white
## to blue once Awakened; EmberooFlameColors' burst ramp) before it breaks up into
## flickering pixels. It opens with a frame or two of pure white, over a faint additive
## glow, and embers float up from it. Every pixel sits on the world grid, so it stays
## crisp. It removes itself when done.

## Embers: how they slow down (pixels per second squared), the pull upward, their size range.
const EMBER_DAMPING := Vector2(50.0, 80.0)
const EMBER_GRAVITY := Vector2(0, -25)
const EMBER_SCALE := Vector2(1.0, 2.0)
## Extra seconds before the burst frees itself, after its flames and embers are done.
const CLEAN_UP_MARGIN := 0.1
## Seconds the fire burns hotter when it bursts out (its hotter half white), and by how
## many colour steps.
const FLASH_SECONDS := 0.035
const FLASH_STEPS := 2
## How much each pixel's heat wobbles at random, so the flame reads as fire, not flat bands.
const HEAT_JITTER := 0.22
## Times per second the wobble changes.
const JITTER_RATE := 20.0
## The glow behind the fire: its radius as a share of the fire's size, and how bright.
const GLOW_SHARE := 0.85
const GLOW_STRENGTH := 0.22

## Seconds the fire is visible.
@export var duration: float = 0.25
@export var ember_count: int = 12
@export var ember_lifetime: float = 0.45

## Share of the fire's life after which it starts breaking up into pixels.
var break_up_start: float = 0.5

## Hottest to coolest: Emberoo's burst colours when this started (see EmberooFlameColors).
var _fire_colors: Array[Color] = EmberooFlameColors.burst_ramp()
## Each cell is one pixel the fire may cover: where it is, how far out (a share of the
## fire's size) and a fixed random value (when it breaks up).
var _cell_offsets: PackedVector2Array = PackedVector2Array()
var _cell_distances: PackedFloat32Array = PackedFloat32Array()
var _cell_noise: PackedFloat32Array = PackedFloat32Array()
var _elapsed: float = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var progress := _elapsed / duration
	if progress >= 1.0:
		return
	_prepare_frame(progress)
	var hotter_by := FLASH_STEPS if _elapsed < FLASH_SECONDS else 0
	for index in _cell_offsets.size():
		var color_index := _color_index_at(index, progress)
		if color_index >= 0:
			draw_rect(Rect2(_cell_offsets[index], Vector2.ONE), _fire_colors[maxi(0, color_index - hotter_by)])


## Lights the ground behind a fire `size` pixels across (its reach or radius).
func _add_glow(size: float) -> void:
	FxGlow.add_to(self, size * GLOW_SHARE, _fire_colors[2], GLOW_STRENGTH, duration)


## Frees the burst once its flames and embers are done.
func _free_when_done() -> void:
	var lifetime := maxf(duration, ember_lifetime) + CLEAN_UP_MARGIN
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


## Adds one pixel the fire may cover, `distance` out as a share of its size.
func _add_cell(offset: Vector2, distance: float) -> void:
	_cell_offsets.append(offset)
	_cell_distances.append(distance)
	_cell_noise.append(randf())


## True once the cell has flickered out as the fire breaks up.
func _has_broken_up(index: int, progress: float) -> bool:
	return progress > break_up_start and _cell_noise[index] < (progress - break_up_start) / (1.0 - break_up_start)


## The colour for a pixel that has lost `heat_lost` of its heat (0 hottest, 1 or more coolest).
func _color_index_for_heat_lost(heat_lost: float) -> int:
	return clampi(floori(heat_lost * _fire_colors.size()), 0, _fire_colors.size() - 1)


## Like _color_index_for_heat_lost, with the cell's heat wobbling a little over time.
func _flickering_color_index(index: int, heat_lost: float) -> int:
	var wobble := FxPixels.noise(index, floori(_elapsed * JITTER_RATE), 7) - 0.5
	return _color_index_for_heat_lost(heat_lost + wobble * HEAT_JITTER)


## The fire's embers, with what every burst's embers share; the caller aims and places them.
func _make_embers() -> CPUParticles2D:
	var embers := CPUParticles2D.new()
	embers.one_shot = true
	embers.amount = ember_count
	embers.lifetime = ember_lifetime
	embers.local_coords = false
	embers.damping_min = EMBER_DAMPING.x
	embers.damping_max = EMBER_DAMPING.y
	embers.gravity = EMBER_GRAVITY
	embers.scale_amount_min = EMBER_SCALE.x
	embers.scale_amount_max = EMBER_SCALE.y
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([_fire_colors[1], _fire_colors[2], _fire_colors[4], Color(_fire_colors[5], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	embers.color_ramp = ramp
	return embers


## Works out what this frame's pixels share (e.g. how far out the flame front is now).
@abstract func _prepare_frame(progress: float) -> void


## The fire colour of one pixel right now, or -1 when that pixel is not burning.
@abstract func _color_index_at(index: int, progress: float) -> int
