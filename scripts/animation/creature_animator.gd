class_name CreatureAnimator
extends AnimatedSprite2D
## Plays the right animation for what the creature is doing and where it's looking.
##
## Animations are loaded from sprite sheets (see SpriteSheetLoader) when `use_sheets` is
## called: HeroFormSwitch does that for each evolution form, whose frames are bigger.
## If an animation hasn't been drawn yet, it falls back to a stand-in sheet or an idle,
## so the game never breaks.

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

## Seconds each frame is shown, in order. An action may name a "stand_in_sheet": the sheet
## used for views where its own isn't drawn (with the action's own timings).
## Keep "jab" in sync with MeleeAttack's timings on the creature: the hit lands
## (hit_delay) as frame 1 (fist out, held for frames 1-2) starts, and attack_duration is the total.
## Keep "dodge" as long as Dodge.dodge_duration (crouch, bound, landing).
const ANIMATION_SETTINGS := {
	"idle": { "frame_durations": [0.30, 0.20, 0.30, 0.20], "loops": true },
	"hop": { "frame_durations": [0.09, 0.16, 0.11, 0.11], "loops": true },
	"jab": { "frame_durations": [0.10, 0.06, 0.10, 0.14], "loops": false },
	"jab2": { "frame_durations": [0.10, 0.06, 0.10, 0.14], "loops": false, "stand_in_sheet": "jab" },
	"dodge": { "frame_durations": [0.07, 0.15, 0.11], "loops": false },
	# Flame Uppercut: crouch, rise, fist overhead (the burst, held two frames), recover.
	# Keep in sync with FlameUppercut's wind_up (frames 0-1) and duration (the total).
	"uppercut": { "frame_durations": [0.12, 0.05, 0.10, 0.08, 0.10], "loops": false, "stand_in_sheet": "jab" },
	# A closed-eyes copy of every idle frame, so a blink never interrupts the breathing.
	"blink": { "frame_durations": [0.30, 0.20, 0.30, 0.20], "loops": true },
	# Spinning Hook: the jab's frames, held one at a time by SpinTurn (never played through).
	"spin": { "sheet": "jab", "frame_durations": [0.12, 0.07, 0.11, 0.14], "loops": false },
	# Ash Guard: the jab's first frame (gloves up, cocked), held for as long as the guard lasts.
	"guard": { "sheet": "jab", "frame_durations": [60.0], "loops": false },
}

## Pairs of actions drawn frame-for-frame alike. Switching between them keeps
## the current frame, so the swap is invisible apart from what changed (the eyes).
const FRAME_MATCHED_ACTIONS := [["idle", "blink"]]

## If an animation isn't drawn yet, use a similar one instead of dropping to idle.
const STAND_IN_FOR_ACTION := {
	"blink": "idle",
}

## Shortest and longest wait between blinks while idle, in seconds.
const BLINK_INTERVAL_RANGE := Vector2(2.0, 5.0)
## How long the eyes stay shut, in seconds.
const BLINK_LENGTH := 0.12
## The action posed by SpinTurn instead of following the creature's facing.
const SPIN_ACTION := "spin"

## Used to find this creature's sprite sheets, e.g. "emberoo".
@export var creature_name: String = "emberoo"

## Frames already built, by sheet folder and creature, so switching forms back and forth is instant.
static var _built_frames: Dictionary[String, SpriteFrames] = {}

## Where the sprite sits when the creature is on the ground.
var _ground_offset: Vector2
var _seconds_until_blink: float = 0.0
var _blink_seconds_left: float = 0.0
var _spin_turn := SpinTurn.new()
var _is_spinning: bool = false


func _ready() -> void:
	_ground_offset = position
	_schedule_next_blink()


## Shows the sheets in `sheet_folder` (square frames `frame_size` pixels wide), drawn
## `offset_y` pixels up from the creature's feet (centred frames), keeping the action and
## view on screen.
func use_sheets(sheet_folder: String, frame_size: int, offset_y: float) -> void:
	var shown_animation := animation
	var frames_key := "%s/%s" % [sheet_folder, creature_name]
	if not _built_frames.has(frames_key):
		_built_frames[frames_key] = SpriteSheetLoader.build_sprite_frames(
			sheet_folder,
			creature_name,
			VIEW_FOR_DIRECTION.values(),
			ANIMATION_SETTINGS,
			Vector2i(frame_size, frame_size)
		)
	sprite_frames = _built_frames[frames_key]
	centered = true
	offset = Vector2(0, offset_y)
	if sprite_frames.has_animation(shown_animation):
		play(shown_animation)


## Raises the sprite off the ground, in pixels. The shadow stays put, which sells the jump.
func lift(height: float) -> void:
	position = _ground_offset + Vector2(0, -roundf(height))


## Like show_animation, but always starts from the first frame,
## e.g. so back-to-back jabs each play in full. A spin starts its turn from the front.
func replay_animation(action: String, facing: Facing) -> void:
	if action == SPIN_ACTION:
		_spin_turn.restart()
	show_animation(action, facing)
	if _is_spinning:
		return
	frame = 0
	frame_progress = 0.0
	play()


func _process(delta: float) -> void:
	_update_blink_timers(delta)
	_spin_turn.advance(delta)


## The view (e.g. "front", "side") shown for the given facing; mid-spin, the spin's view.
func view_for(facing: Facing) -> String:
	return _spin_turn.view() if _is_spinning else VIEW_FOR_DIRECTION[facing.direction]


func show_animation(action: String, facing: Facing) -> void:
	_is_spinning = action == SPIN_ACTION
	if _is_spinning:
		_spin_turn.pose(self, SPIN_ACTION)
		return
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
	for pair: Array in FRAME_MATCHED_ACTIONS:
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
