class_name FireTrail
extends Node2D
## A line of fires on the ground (Ember Hop's dodge trail): each patch flickers for
## `patch_lifetime` seconds, then gutters out. Enemies whose feet touch a burning patch
## start Burning (refreshed while they stand in it). When the hop stops laying fire, a
## ring of fire bursts out where it landed (EmberHopLanding).
##
## Drawn in code, pixel by pixel, on the world grid: fresh flames have a white-hot core,
## older ones cool to red and sink to their base. Sized for the ~46 px hero. Lay patches
## with `lay_patch_at`; the trail removes itself once its last patch has gone out.

## Each patch's flame, from its foot ('#' a pixel, '.' empty), centred on the foot's middle.
const PATCH_ROWS: Array[String] = [
	"...#...",
	"..##...",
	"..###..",
	".####..",
	".#####.",
	"#######",
	"#######",
]
## A patch's lowest rows, all an old patch keeps once it starts dying down.
const BASE_ROWS := 2
## Share of a patch's life after which it dies down to its base rows.
const DIE_DOWN_SHARE := 0.6
## Physics frames without a new patch after which the hop counts as landed.
const LANDED_AFTER_FRAMES := 2
## On the ground layer (z 0, drawn after it) and under the creatures (z 1).
const GROUND_Z_INDEX := 0
## Times per second the flames pick new colours.
const FLICKER_RATE := 12.0
## Group whose members the fire can burn (each needs a child node named "Health").
const TARGET_GROUP := "enemies"

var patch_lifetime: float = 1.5
var burn_damage: int = 1
var burn_duration: float = 2.0
var touch_radius: float = 6.0
var patch_spacing: float = 5.0

## Hottest to coolest: Emberoo's burst colours when this started (see EmberooFlameColors).
var _fire_colors: Array[Color] = EmberooFlameColors.burst_ramp()
## Where each patch is (global, on the pixel grid) and how long it has burned.
var _patch_positions := PackedVector2Array()
var _patch_ages := PackedFloat32Array()
var _elapsed: float = 0.0
## The flame's pixels (offsets from the foot) and how deep inside the flame each one is.
var _flame_pixels: Array[Vector2i] = []
var _flame_depths := PackedInt32Array()
## The last place and physics frame a patch was asked for; -1 once it has landed.
var _last_lay_position: Vector2 = Vector2.ZERO
var _last_lay_frame: int = -1


func _ready() -> void:
	# Flat on the ground, under the creatures that walk through it.
	z_index = GROUND_Z_INDEX
	global_position = Vector2.ZERO
	_build_flame()


## Adds a patch at `ground_position`, unless the last one is closer than `patch_spacing`.
func lay_patch_at(ground_position: Vector2) -> void:
	_last_lay_position = ground_position
	_last_lay_frame = Engine.get_physics_frames()
	var cell := ground_position.round()
	var count := _patch_positions.size()
	if count > 0 and _patch_positions[count - 1].distance_to(cell) < patch_spacing:
		return
	_patch_positions.append(cell)
	_patch_ages.append(0.0)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _last_lay_frame >= 0 and Engine.get_physics_frames() - _last_lay_frame >= LANDED_AFTER_FRAMES:
		_last_lay_frame = -1
		EmberHopLanding.spawn(get_parent(), _last_lay_position)
	for index in _patch_ages.size():
		_patch_ages[index] += delta
	if not _patch_ages.is_empty() and _patch_ages[_patch_ages.size() - 1] >= patch_lifetime:
		queue_free()
		return
	_burn_touching_targets()
	queue_redraw()


func _burn_touching_targets() -> void:
	for target: Node2D in get_tree().get_nodes_in_group(TARGET_GROUP):
		if _is_touching_fire(target.global_position):
			Burning.apply_to(Health.of(target), burn_damage, burn_duration)


func _is_touching_fire(feet: Vector2) -> bool:
	for index in _patch_positions.size():
		if _patch_ages[index] < patch_lifetime and _patch_positions[index].distance_squared_to(feet) <= touch_radius * touch_radius:
			return true
	return false


func _draw() -> void:
	var flicker_step := floori(_elapsed * FLICKER_RATE)
	var lowest_base_row := 1 - BASE_ROWS
	for index in _patch_positions.size():
		var age_share := _patch_ages[index] / patch_lifetime
		if age_share >= 1.0:
			continue
		var is_dying_down := age_share >= DIE_DOWN_SHARE
		for pixel_index in _flame_pixels.size():
			var pixel := _flame_pixels[pixel_index]
			# Older patches sink to their base rows.
			if is_dying_down and pixel.y < lowest_base_row:
				continue
			var noise := FxPixels.noise(index, pixel_index, flicker_step)
			# From age, flicker and depth: fresh cores are white-hot, old edges red.
			var core_heat := minf(1.0, _flame_depths[pixel_index] / 2.0)
			var heat_lost := clampf(age_share * 0.6 + noise * 0.4 + 0.3 - core_heat * 0.3, 0.0, 0.999)
			draw_rect(Rect2(_patch_positions[index] + Vector2(pixel), Vector2.ONE), FxPixels.ramp_color(_fire_colors, heat_lost))


## Reads PATCH_ROWS into pixel offsets from the flame's foot, with each pixel's depth.
func _build_flame() -> void:
	var shape := PixelShape.from_rows(PATCH_ROWS)
	var depths := PixelShape.depths(shape)
	var foot := Vector2i(floori(PATCH_ROWS[0].length() / 2.0), PATCH_ROWS.size() - 1)
	for pixel: Vector2i in shape:
		_flame_pixels.append(pixel - foot)
		_flame_depths.append(depths[pixel])
