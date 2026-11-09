class_name LayeredTrainerSprite
extends Node2D
## The trainer drawn from the layered kit: body, bottom, shoes, top and hair,
## each its own AnimatedSprite2D with its own palette-swap material.
##
## Every layer plays the same animation ("idle" or "walk") at the same speed, so they
## stay in step. Call `apply_look` to change styles and colours at any time.

const SHEET_FOLDER := "res://art/trainer/kit"
const FRAME_SIZE := Vector2i(18, 28)
const IDLE_SECONDS_PER_FRAME := 1.0 / 3.0
const WALK_SECONDS_PER_FRAME := 1.0 / 8.0

## SpriteFrames already built, by layer sheet name (e.g. "hair_2"); shared by every trainer.
static var _frames_by_layer: Dictionary = {}

## The look to wear when the scene starts; the default look if left empty.
@export var look: TrainerLook

var _animation: StringName = &"idle"

@onready var _body: AnimatedSprite2D = $Body
@onready var _bottom: AnimatedSprite2D = $Bottom
@onready var _shoes: AnimatedSprite2D = $Shoes
@onready var _top: AnimatedSprite2D = $Top
@onready var _hair: AnimatedSprite2D = $Hair


func _ready() -> void:
	for layer in _layers():
		layer.material = PaletteSwap.make_material()
	apply_look(look if look != null else TrainerLook.new())


## Dresses the trainer: picks each layer's sheet and recolours it.
func apply_look(new_look: TrainerLook) -> void:
	look = new_look
	var grey_key := TrainerPresets.grey_key()
	_dress(_body, "body", TrainerPresets.skin_key(), _ramp(TrainerPresets.SKIN, look.skin_ramp))
	_dress(_bottom, "bottom_1", grey_key, _ramp(TrainerPresets.OUTFIT, look.bottom_ramp))
	_dress(_shoes, "shoes_1", grey_key, _ramp(TrainerPresets.OUTFIT, look.shoes_ramp))
	_dress(_top, "top_%d" % (look.top_style + 1), grey_key, _ramp(TrainerPresets.OUTFIT, look.top_ramp))
	_dress(_hair, "hair_%d" % (look.hair_style + 1), grey_key, _ramp(TrainerPresets.HAIR, look.hair_ramp))
	_keep_layers_in_step()


## Plays "idle" or "walk" on every layer together.
func play(animation: StringName) -> void:
	if animation == _animation:
		return
	_animation = animation
	for layer in _layers():
		layer.play(_animation)


## Mirrors every layer, for walking left.
func set_flipped(is_flipped: bool) -> void:
	for layer in _layers():
		layer.flip_h = is_flipped


func _layers() -> Array[AnimatedSprite2D]:
	return [_body, _bottom, _shoes, _top, _hair]


func _dress(layer: AnimatedSprite2D, layer_name: String, key: PackedColorArray, target: PackedColorArray) -> void:
	var frames := _frames_for(layer_name)
	if layer.sprite_frames != frames:
		layer.sprite_frames = frames
	PaletteSwap.set_swaps(layer.material as ShaderMaterial, key, target)


## Restarts any swapped layer on the body's current frame, so it doesn't fall out of step.
func _keep_layers_in_step() -> void:
	var frame := _body.frame
	var progress := _body.frame_progress
	for layer in _layers():
		layer.play(_animation)
		layer.set_frame_and_progress(frame, progress)


func _ramp(group: String, ramp_name: StringName) -> PackedColorArray:
	return TrainerPresets.ramp(group, ramp_name)


static func _frames_for(layer_name: String) -> SpriteFrames:
	if not _frames_by_layer.has(layer_name):
		_frames_by_layer[layer_name] = _build_frames(layer_name)
	return _frames_by_layer[layer_name]


static func _build_frames(layer_name: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, layer_name, "idle", IDLE_SECONDS_PER_FRAME)
	_add_animation(frames, layer_name, "walk", WALK_SECONDS_PER_FRAME)
	return frames


static func _add_animation(frames: SpriteFrames, layer_name: String, animation: String, seconds_per_frame: float) -> void:
	var sheet: Texture2D = load("%s/%s_%s_sheet.png" % [SHEET_FOLDER, layer_name, animation])
	SpriteSheetLoader.add_animation(frames, animation, sheet, [seconds_per_frame], true, FRAME_SIZE)
