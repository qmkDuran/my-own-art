class_name CreatureAnimator
extends AnimatedSprite2D
## Plays the right animation for what the creature is doing and where it's looking.
##
## Animations are loaded from sprite sheets when the game starts (see SpriteSheetLoader).
## If an animation hasn't been drawn yet, it falls back to an idle so the game never breaks.

const FRAME_SIZE := Vector2i(16, 16)
const FALLBACK_ACTION := "idle"
const FALLBACK_VIEW := "side"

## Which sprite-sheet view is used for each facing direction.
## Looking left reuses the side view, flipped.
const VIEW_FOR_DIRECTION := {
	Facing.Direction.DOWN: "front",
	Facing.Direction.UP: "back",
	Facing.Direction.SIDE: "side",
}

## Seconds each frame is shown, in order.
## Keep "jab" in sync with MeleeAttack's timings on the creature.
const ANIMATION_SETTINGS := {
	"idle": { "frame_durations": [0.30, 0.20, 0.30, 0.20], "loops": true },
	"hop": { "frame_durations": [0.09, 0.16, 0.11, 0.11], "loops": true },
	"jab": { "frame_durations": [0.12, 0.07, 0.11, 0.14], "loops": false },
	"dodge": { "frame_durations": [0.07, 0.15, 0.11], "loops": false },
}

## Used to find this creature's sprite sheets, e.g. "emberoo".
@export var creature_name: String = "emberoo"
@export_dir var sprite_sheet_folder: String = "res://art/emberoo"


## Where the sprite sits when the creature is on the ground.
var _ground_offset: Vector2


func _ready() -> void:
	_ground_offset = position
	sprite_frames = SpriteSheetLoader.build_sprite_frames(
		sprite_sheet_folder,
		creature_name,
		VIEW_FOR_DIRECTION.values(),
		ANIMATION_SETTINGS,
		FRAME_SIZE
	)


## Raises the sprite off the ground, in pixels. The shadow stays put, which sells the jump.
func lift(height: float) -> void:
	position = _ground_offset + Vector2(0, -roundf(height))


## Like show_animation, but always starts from the first frame,
## e.g. so back-to-back jabs each play in full.
func replay_animation(action: String, facing: Facing) -> void:
	show_animation(action, facing)
	frame = 0
	frame_progress = 0.0
	play()


func show_animation(action: String, facing: Facing) -> void:
	var view: String = VIEW_FOR_DIRECTION[facing.direction]
	flip_h = facing.direction == Facing.Direction.SIDE and facing.is_looking_left

	var animation_to_play := _first_drawn_animation([
		SpriteSheetLoader.animation_name_for(action, view),
		SpriteSheetLoader.animation_name_for(FALLBACK_ACTION, view),
		SpriteSheetLoader.animation_name_for(FALLBACK_ACTION, FALLBACK_VIEW),
	])

	if animation_to_play != "" and animation != animation_to_play:
		play(animation_to_play)


func _first_drawn_animation(candidates: Array[String]) -> String:
	for candidate in candidates:
		if sprite_frames.has_animation(candidate):
			return candidate
	return ""
