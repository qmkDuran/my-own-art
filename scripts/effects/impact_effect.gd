class_name ImpactEffect
extends AnimatedSprite2D
## A one-shot visual effect: plays its sprite sheet once, then removes itself.
##
## Effects are drawn facing right; whoever spawns one rotates it toward the hit.

const FRAME_SIZE := Vector2i(16, 16)
const ANIMATION_NAME := "play"

@export var sheet: Texture2D
## Seconds each frame is shown, in order.
@export var frame_durations: Array[float] = [0.05, 0.06, 0.09, 0.14]


func _ready() -> void:
	sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	SpriteSheetLoader.add_animation(sprite_frames, ANIMATION_NAME, sheet, frame_durations, false, FRAME_SIZE)

	animation_finished.connect(queue_free)
	play(ANIMATION_NAME)
