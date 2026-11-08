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
## Looking left reuses the right-facing views, flipped.
const VIEW_FOR_DIRECTION := {
	Facing.Direction.DOWN: "front",
	Facing.Direction.DOWN_SIDE: "frontdiag",
	Facing.Direction.SIDE: "side",
	Facing.Direction.UP_SIDE: "backdiag",
	Facing.Direction.UP: "back",
}

## If a view isn't drawn yet (e.g. a new diagonal), use the closest one that is.
const STAND_IN_FOR_VIEW := {
	"frontdiag": "side",
	"backdiag": "side",
}

## Seconds each frame is shown, in order.
## Keep "jab" in sync with MeleeAttack's timings on the creature.
const ANIMATION_SETTINGS := {
	"idle": { "frame_durations": [0.30, 0.20, 0.30, 0.20], "loops": true },
	"hop": { "frame_durations": [0.09, 0.16, 0.11, 0.11], "loops": true },
	"jab": { "frame_durations": [0.12, 0.07, 0.11, 0.14], "loops": false },
	"jab2": { "frame_durations": [0.12, 0.07, 0.11, 0.14], "loops": false },
	"dodge": { "frame_durations": [0.07, 0.15, 0.11], "loops": false },
	# A closed-eyes copy of every idle frame, so a blink never interrupts the breathing.
	"blink": { "frame_durations": [0.30, 0.20, 0.30, 0.20], "loops": true },
}

## Pairs of actions drawn frame-for-frame alike. Switching between them keeps
## the current frame, so the swap is invisible apart from what changed (the eyes).
const FRAME_MATCHED_ACTIONS := [["idle", "blink"]]

## If an animation isn't drawn yet, use a similar one instead of dropping to idle.
const STAND_IN_FOR_ACTION := {
	"jab2": "jab",
	"blink": "idle",
}

## Shortest and longest wait between blinks while idle, in seconds.
const BLINK_INTERVAL_RANGE := Vector2(2.0, 5.0)
## How long the eyes stay shut, in seconds.
const BLINK_LENGTH := 0.12

## Used to find this creature's sprite sheets, e.g. "emberoo".
@export var creature_name: String = "emberoo"
@export_dir var sprite_sheet_folder: String = "res://art/emberoo"


## Where the sprite sits when the creature is on the ground.
var _ground_offset: Vector2
var _seconds_until_blink: float = 0.0
var _blink_seconds_left: float = 0.0


func _ready() -> void:
	_ground_offset = position
	_schedule_next_blink()
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


func _process(delta: float) -> void:
	_update_blink_timers(delta)


## The view (e.g. "front", "side") that matches the given facing.
func view_for(facing: Facing) -> String:
	return VIEW_FOR_DIRECTION[facing.direction]


func show_animation(action: String, facing: Facing) -> void:
	if action == "idle" and _is_blinking():
		action = "blink"

	var view: String = VIEW_FOR_DIRECTION[facing.direction]
	flip_h = facing.is_looking_left and facing.direction != Facing.Direction.DOWN and facing.direction != Facing.Direction.UP

	var animation_to_play := _first_drawn_animation([
		SpriteSheetLoader.animation_name_for(action, view),
		SpriteSheetLoader.animation_name_for(STAND_IN_FOR_ACTION.get(action, action), view),
		SpriteSheetLoader.animation_name_for(action, STAND_IN_FOR_VIEW.get(view, view)),
		SpriteSheetLoader.animation_name_for(STAND_IN_FOR_ACTION.get(action, action), STAND_IN_FOR_VIEW.get(view, view)),
		SpriteSheetLoader.animation_name_for(FALLBACK_ACTION, view),
		SpriteSheetLoader.animation_name_for(FALLBACK_ACTION, FALLBACK_VIEW),
	])

	if animation_to_play == "" or animation == animation_to_play:
		return

	if _are_frame_matched(animation, animation_to_play):
		_swap_keeping_frame(animation_to_play)
	else:
		play(animation_to_play)


func _swap_keeping_frame(animation_name: String) -> void:
	var current_frame := frame
	var current_progress := frame_progress
	play(animation_name)
	set_frame_and_progress(current_frame, current_progress)


func _are_frame_matched(from_animation: String, to_animation: String) -> bool:
	for pair in FRAME_MATCHED_ACTIONS:
		var from_matches := from_animation.begins_with(pair[0] + "_") or from_animation.begins_with(pair[1] + "_")
		var to_matches := to_animation.begins_with(pair[0] + "_") or to_animation.begins_with(pair[1] + "_")
		if from_matches and to_matches and _view_of(from_animation) == _view_of(to_animation):
			return true
	return false


## The view part of an animation name, e.g. "side" from "idle_side".
func _view_of(animation_name: String) -> String:
	return animation_name.get_slice("_", animation_name.get_slice_count("_") - 1)


## Blinks only show while idle, so the timer runs all the time
## and a blink that lands mid-action simply isn't seen.
func _update_blink_timers(delta: float) -> void:
	if _is_blinking():
		_blink_seconds_left -= delta
		return

	_seconds_until_blink -= delta
	if _seconds_until_blink <= 0.0:
		_blink_seconds_left = BLINK_LENGTH
		_schedule_next_blink()


func _is_blinking() -> bool:
	return _blink_seconds_left > 0.0


func _schedule_next_blink() -> void:
	_seconds_until_blink = randf_range(BLINK_INTERVAL_RANGE.x, BLINK_INTERVAL_RANGE.y)


func _first_drawn_animation(candidates: Array[String]) -> String:
	for candidate in candidates:
		if sprite_frames.has_animation(candidate):
			return candidate
	return ""
