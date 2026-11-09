class_name FireTrail
extends Node2D
## A line of small fires on the ground (Ember Hop's dodge trail): each patch flickers for
## `patch_lifetime` seconds, then gutters out. Enemies whose feet touch a burning patch
## start Burning (refreshed while they stand in it).
##
## Drawn in code, pixel by pixel, on the world grid. Lay patches with `lay_patch_at`; the
## trail removes itself once its last patch has gone out.

## Pixels each patch covers, around its centre (a small flame shape, taller than wide).
const PATCH_PIXELS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(2, 0),
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(0, -2),
]
## How many of PATCH_PIXELS (the base row) an old patch keeps once it starts dying down.
const BASE_ROW_PIXELS := 5
## Share of a patch's life after which it dies down to its base row.
const DIE_DOWN_SHARE := 0.6
## Times per second the flames pick new colours.
const FLICKER_RATE := 12.0
## Group whose members the fire can burn (each needs a child node named "Health").
const TARGET_GROUP := "enemies"

var patch_lifetime: float = 1.5
var burn_damage: int = 1
var burn_duration: float = 2.0
var touch_radius: float = 6.0
var patch_spacing: float = 5.0

## Where each patch is (global, on the pixel grid) and how long it has burned.
## Hottest to coolest: Emberoo's fire colours when this started (see EmberooFlameColors).
var _fire_colors: Array[Color] = EmberooFlameColors.fire_ramp()
var _patch_positions := PackedVector2Array()
var _patch_ages := PackedFloat32Array()
var _elapsed: float = 0.0


func _ready() -> void:
	# Flat on the ground, under the creatures that walk through it.
	z_index = -1
	global_position = Vector2.ZERO


## Adds a patch at `ground_position`, unless the last one is closer than `patch_spacing`.
func lay_patch_at(ground_position: Vector2) -> void:
	var cell := ground_position.round()
	var count := _patch_positions.size()
	if count > 0 and _patch_positions[count - 1].distance_to(cell) < patch_spacing:
		return
	_patch_positions.append(cell)
	_patch_ages.append(0.0)


func _physics_process(delta: float) -> void:
	_elapsed += delta
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
			Burning.apply_to(target.get_node_or_null("Health") as Health, burn_damage, burn_duration)


func _is_touching_fire(feet: Vector2) -> bool:
	for index in _patch_positions.size():
		if _patch_ages[index] < patch_lifetime and _patch_positions[index].distance_squared_to(feet) <= touch_radius * touch_radius:
			return true
	return false


func _draw() -> void:
	var flicker_step := floori(_elapsed * FLICKER_RATE)
	for index in _patch_positions.size():
		var age_share := _patch_ages[index] / patch_lifetime
		if age_share >= 1.0:
			continue
		# Older patches shrink to their base row and cool toward red.
		var shown_pixels := PATCH_PIXELS.size() if age_share < DIE_DOWN_SHARE else BASE_ROW_PIXELS
		for pixel_index in shown_pixels:
			var noise := float(absi(hash(Vector3i(index, pixel_index, flicker_step))) % 100) / 100.0
			# Half from age, half from flicker: fresh patches are gold and orange, old ones red.
			var heat_lost := clampf((age_share + noise) / 2.0, 0.0, 0.999)
			var color := _fire_colors[floori(heat_lost * _fire_colors.size())]
			draw_rect(Rect2(_patch_positions[index] + Vector2(PATCH_PIXELS[pixel_index]), Vector2.ONE), color)
