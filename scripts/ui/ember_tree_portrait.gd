class_name EmberTreePortrait
extends Node2D
## Emberoo in the middle of the Ember Tree: his portrait for the current Awakening stage
## (art/ui/emberoo_portrait_stage<N>.png: stage 1 Emberoo, then stages 2 and 3), with a
## slow one-pixel breathing bob.
##
## Like the node icons (EmberTreeIcons) it is drawn at a whole number of screen pixels per
## art pixel whatever the tree's zoom, snapped to the screen's pixel grid, and centred by
## its drawn pixels (not its image box), so it stays crisp and sits in the medallion's middle.

const PORTRAITS: Array[Texture2D] = [
	preload("res://art/ui/emberoo_portrait_stage1.png"),
	preload("res://art/ui/emberoo_portrait_stage2.png"),
	preload("res://art/ui/emberoo_portrait_stage3.png"),
]
## Tree units one art pixel covers before it is rounded to whole screen pixels.
const ART_PIXEL_SIZE := 1.0
## Seconds for one breath: half of it he sits one art pixel higher.
const BREATH_SECONDS := 1.4

var _texture: Texture2D
## The middle of the portrait's drawn pixels, in art pixels.
var _drawn_middle: Vector2 = Vector2.ZERO
var _time: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_show_stage(Awakening.stage)
	# A method (not a lambda) so Godot drops the connection when the portrait is freed.
	Awakening.stage_changed.connect(_show_stage)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	var to_screen := get_viewport().get_final_transform() * get_screen_transform()
	var screen_per_unit := to_screen.get_scale().x
	var art_pixel_on_screen := maxf(1.0, roundf(ART_PIXEL_SIZE * screen_per_unit))
	var breath := Vector2(0, 1) if fmod(_time, BREATH_SECONDS) < BREATH_SECONDS / 2.0 else Vector2.ZERO
	var top_left_on_screen := (to_screen * Vector2.ZERO - (_drawn_middle + breath) * art_pixel_on_screen).round()
	var top_left := to_screen.affine_inverse() * top_left_on_screen
	var size_in_units := Vector2(_texture.get_size()) * art_pixel_on_screen / screen_per_unit
	draw_texture_rect(_texture, Rect2(top_left, size_in_units), false)


func _show_stage(stage: int) -> void:
	_texture = PORTRAITS[clampi(stage, 0, PORTRAITS.size() - 1)]
	var drawn := _texture.get_image().get_used_rect()
	_drawn_middle = Vector2(drawn.position) + Vector2(drawn.size) / 2.0
